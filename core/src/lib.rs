//! Shared geocoding core (ADR 0002). Phase0/03 scope: FFI plumbing and a
//! reopenable-dataset-handle skeleton only — no lookup/hierarchy/formatting
//! logic yet (that's phase1/02).

use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, UnwindSafe};
use std::sync::Arc;

use arc_swap::ArcSwapOption;

/// ADR 0002 §9: bump whenever the FFI surface changes incompatibly. Checked by
/// every caller at load time (`vnaddr_abi_version`) so a header/library
/// mismatch fails loudly instead of corrupting memory.
pub const ABI_VERSION: u32 = 1;

/// ADR 0002 §10: status code + out-parameter convention — no panic, and no
/// Rust-specific type, ever crosses the `extern "C"` boundary directly.
#[repr(C)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum VnaddrStatus {
    Ok = 0,
    NotOpen = 1,
    InvalidArgument = 2,
    Panicked = 3,
    IoError = 4,
}

/// Placeholder dataset handle. Real FlatGeobuf mmap/parsing is phase1/02
/// scope; phase0/03 only proves the open/reopen/no-handle-leak plumbing
/// around it (ADR 0002 §4, §10).
struct Dataset {
    dir: String,
}

/// ADR 0002 §10: one process-wide, reopenable dataset — `ArcSwapOption`, not
/// `OnceLock`, so `vnaddr_open` can swap it in place (bootstrap re-check on
/// every launch, phase4/03 OTA activation) without a process restart. There
/// is no per-caller handle: every call reads this global fresh.
static DATASET: ArcSwapOption<Dataset> = ArcSwapOption::const_empty();

/// Wraps an FFI entry point so a Rust panic can never unwind across the
/// `extern "C"` boundary and abort the host process (ADR 0002 §10).
fn ffi_guard<F>(f: F) -> VnaddrStatus
where
    F: FnOnce() -> VnaddrStatus + UnwindSafe,
{
    catch_unwind(f).unwrap_or(VnaddrStatus::Panicked)
}

/// Returns the FFI ABI version. Every binding (Dart FFI, JNI shim, Swift)
/// checks this at load time per ADR 0002 §10.
#[no_mangle]
pub extern "C" fn vnaddr_abi_version() -> u32 {
    ABI_VERSION
}

/// Trivial round-trip placeholder for phase0/03's "Flutter calls a placeholder
/// function in the core via FFI" acceptance criterion. Carries no feature
/// logic — real lookups arrive in phase1/02.
#[no_mangle]
pub extern "C" fn vnaddr_ping() -> i32 {
    42
}

/// Opens (or reopens) the dataset directory resolved by the caller per ADR
/// 0002 §4's bootstrap flow. A no-op if `dir` is already the active
/// directory; otherwise swaps `DATASET` so every subsequent call sees the
/// new dataset, without invalidating a lookup already in flight (which holds
/// its own `Arc` clone taken via `load_full()`).
///
/// # Safety
/// `dir` must be a valid, NUL-terminated UTF-8 C string for the duration of
/// this call.
#[no_mangle]
pub unsafe extern "C" fn vnaddr_open(dir: *const c_char) -> VnaddrStatus {
    ffi_guard(|| {
        if dir.is_null() {
            return VnaddrStatus::InvalidArgument;
        }
        let dir = match unsafe { CStr::from_ptr(dir) }.to_str() {
            Ok(s) => s.to_owned(),
            Err(_) => return VnaddrStatus::InvalidArgument,
        };

        if let Some(current) = DATASET.load_full() {
            if current.dir == dir {
                return VnaddrStatus::Ok; // already active — no-op, per ADR 0002 §4.
            }
        }

        // Phase0/03 stub: records the resolved directory only. Real
        // mmap+FlatGeobuf open/validate is phase1/02 scope.
        DATASET.store(Some(Arc::new(Dataset { dir })));
        VnaddrStatus::Ok
    })
}

/// Returns whether a dataset is currently active. Lets callers distinguish
/// "not opened yet" (`NotOpen`, per ADR 0002 §4 step 4) from a real lookup
/// failure once lookups exist.
#[no_mangle]
pub extern "C" fn vnaddr_is_open() -> bool {
    DATASET.load().is_some()
}

/// Example of the "one core-allocated type, one matching `vnaddr_free_*`"
/// contract (ADR 0002 §10) — returns a heap string the caller must free with
/// `vnaddr_free_string`. Phase0/03 stub: always returns the active dataset's
/// directory, or null if none is open; real error reporting is a later
/// ticket's concern.
#[no_mangle]
pub extern "C" fn vnaddr_active_dataset_dir() -> *mut c_char {
    match DATASET.load_full() {
        Some(dataset) => match CString::new(dataset.dir.clone()) {
            Ok(s) => s.into_raw(),
            Err(_) => std::ptr::null_mut(),
        },
        None => std::ptr::null_mut(),
    }
}

/// Frees a string returned by `vnaddr_active_dataset_dir`. Callers must never
/// free core memory with their own allocator (ADR 0002 §10).
///
/// # Safety
/// `s` must be a pointer previously returned by `vnaddr_active_dataset_dir`
/// (or null, which is a no-op), and must not be freed more than once.
#[no_mangle]
pub unsafe extern "C" fn vnaddr_free_string(s: *mut c_char) {
    if !s.is_null() {
        drop(unsafe { CString::from_raw(s) });
    }
}

#[cfg(feature = "android")]
mod android {
    //! JNI shim (ADR 0002 §9): compiled into this same crate/`.so` behind the
    //! `android` feature, not a separate C shim or second `.so`, so
    //! `vnaddr_abi_version` covers these entry points too.
    use super::*;
    use jni::objects::JClass;
    use jni::sys::{jboolean, jint};
    use jni::JNIEnv;

    #[no_mangle]
    pub extern "system" fn Java_com_vnaddress_widget_core_VnaddrCore_abiVersion(
        _env: JNIEnv,
        _class: JClass,
    ) -> jint {
        vnaddr_abi_version() as jint
    }

    #[no_mangle]
    pub extern "system" fn Java_com_vnaddress_widget_core_VnaddrCore_ping(
        _env: JNIEnv,
        _class: JClass,
    ) -> jint {
        vnaddr_ping()
    }

    #[no_mangle]
    pub extern "system" fn Java_com_vnaddress_widget_core_VnaddrCore_isOpen(
        _env: JNIEnv,
        _class: JClass,
    ) -> jboolean {
        vnaddr_is_open() as jboolean
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn abi_version_is_stable_within_this_build() {
        assert_eq!(vnaddr_abi_version(), ABI_VERSION);
    }

    #[test]
    fn ping_round_trips() {
        assert_eq!(vnaddr_ping(), 42);
    }

    #[test]
    fn not_open_until_opened() {
        // Note: shares process-global DATASET with other tests; kept
        // single-assertion and order-independent (only checks the positive
        // "is_open after open" transition, not the initial state).
        let dir = CString::new("/tmp/vnaddr-test-dataset").unwrap();
        let status = unsafe { vnaddr_open(dir.as_ptr()) };
        assert_eq!(status, VnaddrStatus::Ok);
        assert!(vnaddr_is_open());

        // Re-opening the same directory is a no-op that still reports Ok.
        let status_again = unsafe { vnaddr_open(dir.as_ptr()) };
        assert_eq!(status_again, VnaddrStatus::Ok);
    }
}
