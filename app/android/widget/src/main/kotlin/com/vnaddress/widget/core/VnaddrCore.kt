package com.vnaddress.widget.core

/**
 * JNI wrapper around the shared Rust core's `android` feature (ADR 0002 §9):
 * the native methods below are implemented directly in `libvnaddr.so`'s
 * `#[cfg(feature = "android")] mod android` (see core/src/lib.rs) via the
 * `jni` crate — not a separate C/C++ shim or a second `.so`. One native
 * library is loaded per process, shared with the Dart FFI path in the app
 * module.
 */
object VnaddrCore {
    init {
        System.loadLibrary("vnaddr")
    }

    /** Must match `core::ABI_VERSION` in core/src/lib.rs (ADR 0002 §10). */
    const val EXPECTED_ABI_VERSION = 1

    external fun abiVersion(): Int

    /** Placeholder round-trip call proving the JNI path links (phase0/03). */
    external fun ping(): Int

    external fun isOpen(): Boolean

    /** Throws if the loaded native library's ABI doesn't match this build. */
    fun checkAbiOrThrow() {
        val actual = abiVersion()
        check(actual == EXPECTED_ABI_VERSION) {
            "vnaddr core ABI mismatch: widget expects $EXPECTED_ABI_VERSION, library reports $actual"
        }
    }
}
