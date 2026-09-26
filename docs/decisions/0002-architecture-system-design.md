# ADR 0002: Core architecture & system design

**Status:** Accepted — `tech-lead` and `ui-reviewer` approved (see Approvals below); final one-sentence fix confirmed 2026-09-23.
**Date:** 2026-09-23
**Version:** 1.4
**Ticket:** [phase0/02-architecture-system-design](../../ticket/phase0/02-architecture-system-design.md)
**Depends on:** [ADR 0001](0001-admin-hierarchy-data-source.md)

## Context

`plans/map_proposal.html` proposed Flutter end-to-end with GEOS-via-FFI and a fully-in-RAM R-tree. That doesn't work as written: Flutter has no home-screen-widget runtime (Android/iOS widgets must be native — Glance/Kotlin and WidgetKit/Swift), and a fully-in-RAM R-tree risks exceeding iOS's ~30MB widget-extension memory ceiling. The proposal also self-contradicted on load strategy (RAM-resident vs. lazy-by-viewport).

## Decision

### 1. Framework split per component

| Component | Language/framework |
|---|---|
| App UI (4 screens + map) | Flutter (presentation only) |
| Shared geocoding core | **Rust**, one codebase, built once per target triple |
| Android widget host | Kotlin + Glance, links core via JNI shim (same process as app) |
| iOS widget host | Swift + WidgetKit, links core via a C header / XCFramework (separate extension process) |

The shared Rust core owns **all** logic: boundary lookup, hierarchy resolution, near-boundary confidence radius, address formatting, dataset install/verify. Flutter, the Android widget, and the iOS widget are thin presentation layers over the same core — no logic is duplicated or reimplemented per platform.

**Rejected alternatives:**
- *Fully native (no Flutter)* — 2x UI implementation cost for the 4 app screens, no offsetting benefit since the widgets are native regardless.
- *Kotlin Multiplatform for the shared core* — viable fallback only if the team is Kotlin-first; no mature FlatGeobuf/JTS-equivalent for KMP today, so Rust is currently the safer bet. (User ratified Rust; KMP remains the documented fallback if staffing later requires it.)
- *React Native* — same "widgets must be native" problem as Flutter, with no upside over it.

### 1a. Repo layout (fixes ambiguity flagged by `tech-lead`)

A Flutter app already owns its own `android/` and `ios/` host projects — the widgets must live *inside* those, not as siblings, or the "same process" (Android) and "embedded in Runner" (iOS) claims in §4 break on day one:

```
core/                       Rust crate — the shared geocoding core
  src/
  include/                  cbindgen-generated C header

app/                        Flutter app (single Flutter project)
  lib/                      Dart UI, 4 screens + map
  android/                  the ONE Android application (applicationId, single APK)
    app/                    :app module — Flutter host + widget glue
    widget/                 :widget module (com.android.library, NOT its own application —
                             a second com.android.application here would produce a second
                             APK and break "same process"), depended on by :app via
                             implementation(project(":widget")), included via settings.gradle
  ios/
    Runner.xcodeproj        the ONE iOS app target
    Runner/                 Flutter host
    Widget/                 WidgetKit extension target, embedded in Runner.app,
                             shares an App Group with Runner
```

This is **not** "add-to-app" (a native app embedding a Flutter module) — it's a single Flutter project whose generated `android/` and `ios/` platform folders are extended with a widget module/target. If add-to-app is ever preferred instead, that is a distinct decision with its own engine-management cost and must be a separate ADR, not an implicit scaffolding choice.

### 2. Lookup engine

Point-in-polygon runs **once**, against the finest level (Xã — per [ADR 0001](0001-admin-hierarchy-data-source.md)), and reads Tỉnh/Huyện names+codes from that one feature's own properties (`GID_1/NAME_1`, `GID_2/NAME_2`, verified present on every Xã feature in `references/gadm41_VNM_3.json`). This is not three independent per-level lookups — which would let mismatched sources disagree at boundary slivers — because there is only one source and one lookup.

`code` in any lookup result means the **GADM GID** (e.g. `GID_3: "VNM.1.1.1_1"`) — GADM's own `CC_3` field (an official government code) is `"NA"` for all 11,163 features in the dataset, so no official numeric code exists yet at this level. See [ADR 0001](0001-admin-hierarchy-data-source.md) for the related name-quality issue.

### 3. Storage / format — resolves the RAM-vs-lazy contradiction

**FlatGeobuf, mmap'd, read lazily.** Nothing is ever fully loaded into RAM. FlatGeobuf's built-in packed Hilbert R-tree index lives in the file itself and is queried directly via mmap, so no separate SQLite/SpatiaLite/GEOS engine is needed on-device.

- Rejected: **SQLite/SpatiaLite** — an extra DB engine + larger on-disk/in-memory footprint for capability FlatGeobuf's own spatial index already provides.
- Rejected: **GEOS** — point-in-polygon for this dataset (simple/multi-polygons, no complex topology ops) is implemented directly in the Rust core with a standard ray-casting/winding algorithm; pulling in GEOS's full geometry-engine footprint isn't justified for that one operation.
- The historical "lazy load on zoom" language in the original proposal (map_proposal.html:1356) referred to **map tile rendering**, not boundary lookup, and does not apply here — it's dropped from this design.

**Target memory ceiling for the widget process: ≤20MB**, broken down as an estimate to be measured, not asserted, once scaffolding exists:

| Component | Est. contribution | Measure how |
|---|---|---|
| WidgetKit/SwiftUI extension baseline (empty widget) | ~8–10MB | Xcode Memory Graph on a placeholder-only widget |
| Linked core binary (code pages, not mmap'd data) | ~2–4MB | `size` on the linked XCFramework slice |
| FlatGeobuf index nodes touched per lookup | <1MB | mmap'd, OS-reclaimable — count pages touched, not resident set |
| Worst-case candidate features decoded (largest Xã + its <100m neighbours) | ~1–2MB | Rust core instrumentation, worst-case polygon vertex count |
| `last_result.json` snapshot | negligible | file size |

mmap'd pages are shared/reclaimable by the OS and are **not** counted as resident app heap, which is why this budget targets well under iOS's ~30MB widget-extension ceiling — but the estimate above is unverified until an on-device benchmark exists (out of scope for this ADR, per the ticket; tracked as a phase0/03 follow-up).

### 4. App ↔ widget data sharing

The boundary file lives in one location both the app and widget process can read:
- Android: app-private `filesDir` (same process family — see §1a, the widget module ships in the same APK/process as the app).
- iOS: shared **App Group container** (app and widget extension are separate processes).

Both access it via mmap directly — **no live shared SQLite connection across processes** (avoids iOS's `0xdead10cc`-class suspension crash on a held DB lock across process suspend).

The app writes a small, atomically-updated `widget/last_result.json` snapshot (plain JSON file — **not** mmap'd; it's small enough to read whole) after each lookup; widgets read that snapshot by default rather than independently re-running GPS/geocode. Whether a widget ever needs its own independent lookup is decided per §7 below, not left open.

**Invariants for safe cross-process mmap access** (previously unstated — required so an install/OTA write can never race a reader):
- Dataset files are **immutable once written**. Installing a new version writes to a **new versioned path** (`dataset/v{N}/…`), never overwrites an existing one in place.
- The "active dataset" pointer switches via **atomic rename** of a pointer file/symlink, never by mutating the dataset bytes a reader may have mapped.
- All readers (app, both widgets) map the dataset **`PROT_READ`-only** — no writer ever holds a mapping.
- iOS App Group files use **`NSFileProtectionCompleteUntilFirstUserAuthentication`** data-protection class, so a background widget refresh after device unlock-since-boot can still read them (a stricter class can make reads fail while the device is locked).
- Nothing in the iOS App Group container ever holds an open file **lock** across process suspension — the local-history store ([phase3/02-lookup-history](../../ticket/phase3/02-lookup-history.md), if it uses a lock-holding store) stays in **app-private** storage, not the App Group, to avoid the `0xdead10cc` crash class.

**Dataset bootstrap (how the file gets onto the device, and stays current across app updates — previously unstated):**
1. The dataset ships as a native platform asset, not a Flutter asset: Android `assets/` (optionally `androidResources { noCompress += "fgb" }` in `build.gradle.kts` — this is a minor extraction-cost optimization, not required for correctness, since the file is always copied out to `filesDir` before being mmap'd, never mapped directly from inside the APK); iOS bundled directly in the `Runner` app bundle.
2. On **every** app/widget process start — not just first install — the host reads the bundled dataset's version (a build-time constant, or the FlatGeobuf header `metadata` from step 5 below) and compares it against the version **the active pointer currently names** (not "the highest `dataset/v{N}/` directory that happens to exist" — a directory alone doesn't mean the copy into it completed). If the bundled version is newer, the copy is **crash-safe**: copy into a scratch `dataset/.staging-v{bundled}/`, `fsync` it, atomically rename it to `dataset/v{bundled}/` (making its existence mean "complete"), then swap the active pointer per the invariants above. On startup, any leftover `dataset/.staging-*` directory from a killed prior copy is deleted and the copy retried. If `dataset/v{bundled}/` **already exists** (a kill between the staging rename and the pointer swap), it is complete by construction — it only ever appears via that atomic rename — so the copy step is skipped and the flow goes straight to the pointer swap; a missing or unreadable pointer counts as version 0, which also covers first install. This is what makes an **app update** (not just first install) deliver a newer bundled dataset — e.g. [ADR 0001](0001-admin-hierarchy-data-source.md)'s GSO name-restoration fix shipping in a later release — instead of the existing on-device copy silently shadowing it forever, and what makes an interrupted first-install copy self-heal on the next launch instead of leaving the app with no usable dataset. Owner: Android's `Application.onCreate` (runs for both an app-launched and a Glance-widget-triggered process start); iOS's `Runner` Swift app-launch path. [phase4/03](../../ticket/phase4/03-ota-dataset-update.md)'s "active version" and this step's "active pointer" are the same concept — one definition of "active," not two.
3. iOS: native (Swift) code resolves the App Group container path and passes it to the Flutter/Dart side over a method channel, since Dart's `path_provider` cannot resolve an App Group path itself.
4. The core exposes an explicit open/refresh entry point, `vnaddr_open(dir: *const c_char) -> VnaddrStatus` (see §10 — there is no per-caller handle; `open` swaps the one process-wide active dataset), taking the resolved directory — the core never guesses a path. Calling it again with a newer directory (per step 2) swaps the active dataset in place, without a process restart; calling it again with the already-active directory is a no-op. Calling `lookup()`/`format_address()` before the first successful `open()` returns a `NotOpen` status, not a crash.
5. [ADR 0001](0001-admin-hierarchy-data-source.md)'s `admin_epoch` and [phase4/03](../../ticket/phase4/03-ota-dataset-update.md)'s `schema_version` live in the FlatGeobuf file's own header `metadata` field — not a separate sidecar manifest — so a single file is always self-describing.

### 5. Near-boundary confidence radius

Computed in the **shared Rust core** (distance from the GPS point to the nearest polygon edge, alongside the point-in-polygon test itself), so the <100m "show both adjacent units" behavior (map_proposal.html:1349) is identical across app and both widgets — not reimplemented per platform. What shape the core emits for this case (primary result vs. primary+secondary) and how either widget size renders it is an open UX question — see the "Open questions — widget/screen UX" section below.

### 6. Minimum supported OS versions (proposed defaults — pending org confirmation)

- **Android: API 26 (Android 8.0)+** — modern Glance/widget-host baseline with broad device coverage.
- **iOS: 16+** as the general floor. **Interactive widget elements (e.g. a tap-to-copy button inside the widget) require iOS 17+** — this pushes the effective floor for that one feature above the rest of the app. On iOS 16 the large widget's layout **omits the copy affordance entirely** (not just a no-op tap) and falls back to "tap widget → open app", matching the small widget's behavior — see the open-questions section.
- These are **proposed defaults, not a ratified org policy** — flagged for confirmation by whoever owns device/OS-support policy before phase1 locks them in.

### 7. Widget-to-core API and background-location permission

Both widget targets **link the core from phase0/03 onward**, regardless of which mode is active — linkage is cheap and keeps both modes available without a later rework. Per the original proposal (`plans/map_proposal.html:1278-1293`), **widgets are M2 scope entirely — there is no M1 widget.** The two modes below are both within M2, not "M1 vs M2":

- **M2a — snapshot-only (ships first, within M2):** widgets call the core only for parsing/formatting the `widget/last_result.json` snapshot the app already wrote; they never call `lookup()` themselves. **No location permission of any kind is required** — the widget process never touches GPS.
- **M2b — GPS auto-update:** the widget calls the core's `lookup(lat, lng)` directly against the mmap'd dataset in its own process, on a schedule with no app in the foreground (Android `WorkManager`, iOS WidgetKit timeline reload). **This requires Android's `ACCESS_BACKGROUND_LOCATION`** (a no-visible-activity refresh cannot use foreground-only location) — that permission request needs the org's device-policy sign-off before M2b is built. **Not decided here**, tracked in [phase2/04-location-permission-flow](../../ticket/phase2/04-location-permission-flow.md). Shipping M2a only (declining M2b) is an explicit, allowed scope reduction against the original proposal — not silently assumed equivalent to it.
- Note for whoever resolves phase2/04: iOS can grant a widget "While Using" location access via `NSWidgetWantsLocation` without full background-location permission — Android and iOS may end up on different permission models for the same M2b feature; verify current platform behavior before implementing.

### 8. Offline basemap (M3 map picker) — explicitly deferred

Not decided here. Online map tiles would break "fully offline," and bundling VN vector tiles may hit the same size/memory budget concerns as the boundary dataset. Flagged for the M3 ticket to resolve, not silently assumed either way.

### 9. Core build artifact & FFI ABI (previously unspecified — blocks phase0/03 AC2 without this)

**Single binding stack, single `extern "C"` surface** — not two separate generators (e.g. `flutter_rust_bridge` for Dart *and* `uniffi` for Kotlin) producing two independent native libraries in the same Android process, which would silently duplicate the dataset handle/cache/allocator per binding.

- Crate config: `crate-type = ["cdylib", "staticlib"]`. C header generated by `cbindgen` into `core/include/vnaddr.h`, consumed by Dart FFI (`dart:ffi`), the Android JNI shim, and Swift alike.
- **Android:** one `libvnaddr.so` per ABI (`arm64-v8a`, `x86_64` for emulator only — see ABI note below), built with `cargo-ndk` into the single location `app/android/app/src/main/jniLibs/<abi>/` (the `:app` module only — `libvnaddr.so` must **not** also be placed under `:widget`'s jniLibs, or Gradle's merge fails on a duplicate-file conflict). Both Dart FFI (via `DynamicLibrary.open`) and the JNI shim load the **same** `.so` — one loaded instance per process, not two.
  - **JNI shim:** implemented as Rust code using the [`jni`](https://docs.rs/jni) crate, compiled into the **same** `libvnaddr.so` behind an `android` cargo feature — not a separate C/C++ shim or a second `.so`. This keeps exactly one native library per process, and means `vnaddr_abi_version()` (§10) covers the JNI entry points too.
  - **`:widget` module type:** `com.android.library`, depended on by `:app` (`implementation(project(":widget"))`) — not its own `com.android.application` (see §1a).
  - **Supported ABIs:** `arm64-v8a` and `x86_64` only. `app/android/app/build.gradle.kts` sets `ndk { abiFilters += listOf("arm64-v8a", "x86_64") }` so a 32-bit-only device (still reachable under the API 26 floor in §6, since Flutter's own engine binaries include `armeabi-v7a` by default) is **refused at install time**, rather than crashing on first launch when `libvnaddr.so` isn't found for its ABI. `armeabi-v7a` builds of the core are out of scope.
  - **Android 16KB page size:** native libraries must be 16KB-page-aligned to load on Android 15+ devices using 16KB pages. Build with NDK r28+ or pass `-C link-arg=-Wl,-z,max-page-size=16384`. phase0/03's CI build step verifies LOAD segment alignment (`llvm-readelf -l`, expect `0x4000`), not just "it compiles."
- **iOS:** `VnAddr.xcframework` (`ios-arm64` + `ios-arm64_x86_64-simulator` slices), **statically linked into both `Runner` and `Widget`** targets, with core symbols retained via **both** `-force_load` (or an exported-symbols list) **and** `STRIP_STYLE = non-global` on both targets — Xcode's default Release "Strip Style: All Symbols" removes the exported `vnaddr_*` symbols even with `-force_load` alone, which only prevents link-time dead-stripping, not archive-time stripping. Dart resolves these statically-linked symbols via `DynamicLibrary.process()` (not `.open()`, which is the Android-only path above).
- phase0/03's CI verifies this with a **static check, not a runtime smoke test**, on iOS: `xcodebuild archive CODE_SIGNING_ALLOWED=NO`, then `nm -gU` on the archived `Runner` binary must list every `_vnaddr_*` export. (Flutter doesn't support Release/Profile mode on the iOS *simulator*, and CI has no physical device, so a runtime Release smoke call isn't possible on iOS — this static check catches the same symbol-stripping failure mode instead.) A **runtime** Release-configuration FFI smoke call applies to **Android only**, where the x86_64 emulator does support Release builds. The `Widget` extension itself calls the core directly from Swift at link time and needs neither check.

### 10. FFI safety contract (previously unspecified)

Three separate bindings (Dart FFI, JNI, Swift/C) share one Rust core process-wide — the contract has to be explicit or a panic or data race in the core takes down the host app, not just a lookup call:

- Every exported function wraps its body in `catch_unwind` (crate stays `panic = "unwind"`) and returns a status code plus an out-parameter — a Rust panic must never cross the `extern "C"` boundary and abort the host process.
- Global state (the currently-active dataset) is `Send + Sync` and **reopenable**: a single process-wide `ArcSwapOption<Dataset>` (`arc-swap` crate), **not** a `OnceLock` — a `OnceLock` can only be set once per process lifetime, which would make §4's per-launch bootstrap swap and [phase4/03](../../ticket/phase4/03-ota-dataset-update.md)'s OTA activation impossible without a process restart. There is **no per-caller handle**: `vnaddr_open` (§4) swaps this one global in place via `store()`; every `lookup()`/`format_address()` call reads the current dataset via `load_full()`, taking its own `Arc` clone for the duration of that one call, so a concurrent `open()` swap never invalidates a call already in progress — the caller never holds a dataset reference across calls. `ArcSwapOption` (not `ArcSwap`) so "not yet opened" is a real, representable state, matching §4's `NotOpen` status rather than requiring a dummy initial dataset. Any mutable cache is behind a `Mutex` — required because a Dart background isolate and a Glance coroutine can call into the same Android process concurrently — and a poisoned lock (from a caught panic) is recovered with `lock().unwrap_or_else(|e| e.into_inner())` rather than propagating the poison to every later call.
- Every core-allocated type has exactly one matching `vnaddr_free_*` function; callers never free core memory with their own allocator.
- Results cross the boundary as `#[repr(C)]` plain structs or serialized bytes — no Rust-specific types leak across.
- A `vnaddr_abi_version()` check runs at load time on every platform, so a header/library mismatch fails loudly at startup instead of corrupting memory.

## Diagram

Split into build-time and runtime, since the original single diagram conflated a one-time data-prep step with what actually happens on-device (and mislabeled the snapshot file as mmap'd):

**Build time** (once, off-device — [phase1/01](../../ticket/phase1/01-boundary-dataset-build.md)):
```
gadm41_VNM_3.json (GADM v4.1, ADR 0001)  ─┐
                                            ├─▶ phase1/01 converter ──▶ boundaries.fgb
GSO pre-2025 list (name restoration,      ─┘     (name-restoration join +      (FlatGeobuf, packed R-tree,
 ADR 0001 "Data quality caveat")                  FlatGeobuf encode)            admin_epoch in header metadata)
```

**Runtime** (on-device):
```
 Input sources                    Shared Rust core                     Consumers
 ─────────────                    ─────────────────                    ─────────
 GPS fix         ─┐                                                  ┌─▶ Flutter app (4 screens+map)
 Manual lat/lng     ├──▶ lookup(lat,lng) / │                          │   same process, writes
 Map tap            │    format_address() │                          │   widget/last_result.json
                    │                     │  mmap PROT_READ          │
                    ▼                     ▼  ◀── boundaries.fgb ─────┤
              ┌─────────────────────────────────┐  (filesDir /       │
              │        Shared Rust core          │   App Group)      │
              │  point-in-polygon, hierarchy      │                  ├─▶ Android widget (Glance)
              │  resolution, confidence radius,   │                  │   same process, reads
              │  address formatting, dataset       │                  │   widget/last_result.json
              │  open/reopen (vnaddr_open), etc.   │                  │   (M2a: snapshot only;
              └─────────────────────────────────┘                    │    M2b: own lookup() call,
                    ▲               ▲                                │    see §7)
                    │ Dart FFI      │ JNI shim / C header             │
                    │               │                                └─▶ iOS widget (WidgetKit)
              (linked into all three targets per §9 —                    separate ext. process,
               app, Android widget module, iOS Widget extension)          reads widget/last_result.json
                                                                            (M2a/M2b as above)
```

## Open questions — widget/screen UX (flagged by `ui-reviewer`, 2026-09-23)

Identical computation across surfaces (§5) does not by itself guarantee any surface can *display* the result — the following are explicitly unresolved and routed to whichever phase1 ticket designs widget/screen UI, following the same pattern already used above for min-OS-version and background-permission:

- **Near-boundary "show both adjacent units" widget content contract.** The Rust core computing a primary+secondary result (§5) doesn't specify what shape it emits for that case, or how either widget size renders two ward names in space the mockups (`plans/map_proposal.html:678-705`) built for one. Needs a defined data contract and a widget-content design, not just a shared computation.
- **iOS 16 tap-to-copy degradation is now specified as a distinct layout** (§6) — carried here as a reminder to whoever designs the widget UI, since the mockups (`plans/map_proposal.html:725-726`) still only show the iOS 17+ variant.
- **Widget staleness indicator.** §4's snapshot-based sharing (no live re-lookup) makes stale widget content structurally more likely, echoing a risk the original proposal (`plans/map_proposal.html:1342`) already flagged with a "last updated" mitigation that isn't carried forward here. `widget/last_result.json` should include a timestamp, and a staleness indicator is a required widget UI element to design — or the decision to drop it should be explicit, not silent.
- **First-run / no-snapshot widget state.** Before the app has run once, `widget/last_result.json` doesn't exist yet. Neither this ADR nor the mockups define what the widget shows in that case.
- **Small-widget field-set contradiction inherited from the proposal, unresolved.** `plans/map_proposal.html:680` (2×2 mockup shows all 3 levels condensed) contradicts `:720` (widget spec table says small widget shows only Tỉnh+Huyện). This ADR delegates widget content to the presentation layer without resolving it — must be reconciled before phase1 widget UI work starts.

None of these block [phase0/03-repo-scaffolding](../../ticket/phase0/03-repo-scaffolding.md), whose acceptance criteria are structural only (build/link plumbing, placeholder content, no feature logic) — but they must not be silently forgotten by the time phase1 widget/screen tickets are written.

## Acceptance status (against ticket/phase0/02's acceptance criteria)

| AC | Topic | Status |
|---|---|---|
| Framework per component | §1 | Met |
| RAM vs lazy load + memory target | §3 | Met — target with a measurable breakdown, pending on-device benchmark |
| Storage format | §3 | Met |
| Sharing without duplicating the dataset | §4 | Met — bootstrap flow, mmap invariants, and repo layout (§1a) now explicit |
| Confidence-radius owner | §5 | Met |
| System diagram | Diagram section | Met — split build-time/runtime, correct data flow and inputs |
| Minimum OS versions | §6 | Met (proposed defaults, pending org confirmation) |
| Background-location permission | §7 | Met — explicit M2a/M2b split (widgets are M2-only, not M1), M2b's Android `ACCESS_BACKGROUND_LOCATION` need stated outright, sign-off routed to phase2/04 |
| Review approval | Approvals below | `ui-reviewer`: needs changes (v1.0) → resolved via open-questions section, v1.1. `tech-lead`: needs changes (v1.0) → v1.1 fixes; needs changes again (v1.1, round 2) → v1.2 fixes below. Re-review pending. |

## Approvals

| Reviewer | Date | Verdict | Notes |
|---|---|---|---|
| `tech-lead` | 2026-09-23 | needs changes (v1.0) → addressed in v1.1 | Repo layout, core artifact/ABI, widget-core API contradiction, mmap invariants, dataset bootstrap, FFI safety contract, 16KB page alignment, memory budget breakdown, address-name/code issue (→ ADR 0001), diagram accuracy, premature "Accepted" status. |
| `tech-lead` (round 2) | 2026-09-23 | needs changes (v1.1) → addressed in v1.2 | (1) Bootstrap ran once, never delivered app-update datasets → now runs every launch with a version compare (§4). (2) `OnceLock` can't be reopened → replaced with `ArcSwap`/`RwLock`, `vnaddr_open` takes an out-param, poisoned-lock recovery (§10). (3) iOS Release FFI check was infeasible/incomplete (`-force_load` alone doesn't survive archive stripping, no iOS Release simulator) → `STRIP_STYLE=non-global` added, replaced with a static `nm -gU` archive check; runtime smoke test moved to Android-only (§9). (4) JNI shim had no stated implementation/module type/jniLibs path → pinned to the `jni` crate in the same `.so`, `:widget` as a library module, one jniLibs path (§9, §1a). (5) §7 mislabeled snapshot-only as "M1" when widgets are M2-only, and didn't state the Android background-location permission outright → renamed M2a/M2b, permission named explicitly (§7). (6) No `armeabi-v7a`/`abiFilters` handling under the API 26 floor → explicit ABI restriction + install-time refusal (§9). (7) Diagram/phase1/01 omitted the GSO name-restoration step ADR 0001 requires → added to the build-time diagram and to [phase1/01](../../ticket/phase1/01-boundary-dataset-build.md)'s acceptance criteria. (8) "Manual address" implied forward geocoding, out of scope → relabeled "Manual lat/lng entry" (diagram). |
| `tech-lead` (round 3) | 2026-09-23 | needs changes (v1.2, 2 blocking items) → addressed in v1.3 | (1) Bootstrap's "highest installed dataset/v{N}" test counted a directory as installed even if the copy into it was interrupted, so a killed first-install copy could never self-heal → fixed with a `.staging-v{N}` → fsync → atomic-rename sequence, comparing against what the *active pointer* names (not directory existence), with stale staging dirs cleaned up and retried at startup; reconciled with phase4/03's "active version" wording (§4 step 2). (2) `vnaddr_open` returned a `VnaddrHandle` with undefined semantics, risking a widget process holding a stale per-caller handle across an OTA swap → removed the handle entirely: one process-wide `ArcSwapOption<Dataset>`, `open()` swaps it via `store()`, every `lookup()`/`format_address()` reads it fresh via `load_full()` with its own short-lived `Arc` clone, calls before the first `open()` return `NotOpen` (§4 step 4, §10). Two non-blocking wording fixes also applied: [phase2/04](../../ticket/phase2/04-location-permission-flow.md) no longer asks for an "architect call" §7 already answered; ADR 0001's caveat now names all of `NAME_1`/`NAME_2`/`NAME_3`/`TYPE_3` as stripped, not just `NAME_2`. Reviewer noted neither blocking item touches phase0/03's scope and it's low-risk to scaffold before this lands — lightweight confirmation of just these two paragraphs requested, not a full re-review. |
| `tech-lead` (v1.3 narrow check) | 2026-09-23 | needs changes (1 sentence) → addressed in v1.4 | The `.staging-v{N}` fix didn't cover a kill between the staging rename and the pointer swap (an existing-but-not-yet-pointed-to `dataset/v{bundled}/`), which would fail every retry (`rename` onto a non-empty dir). Fixed: existence of `dataset/v{bundled}/` is now treated as "complete by construction," skipping straight to the pointer swap; missing/unreadable pointer = version 0 (§4 step 2). Reviewer confirmed: **approved, no further review round needed.** |
| `ui-reviewer` | 2026-09-23 | needs changes (v1.0) → addressed in v1.1 | Five widget/screen UX gaps, all resolved as tracked open questions (see above), none blocking scaffolding. |

**Status: Accepted.**

## Consequences

This fixes the component split for [phase0/03-repo-scaffolding](../../ticket/phase0/03-repo-scaffolding.md): a `core/` Rust crate, a Flutter `app/` whose generated `android/` and `ios/` platform projects are extended with a widget module/target as laid out in §1a — not standalone sibling native apps. Nothing else is invented at scaffolding time.
