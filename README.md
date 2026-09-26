# VN Address Widget

Offline Vietnam administrative-address lookup — an app plus Android/iOS
home-screen widgets. Given a GPS point or lat/lng, resolves Tỉnh/Huyện/Xã
(the pre-July-2025 3-level hierarchy) entirely on-device, no network.

## Foundational decisions (read first)

- [ADR 0001 — administrative hierarchy epoch & boundary data source](docs/decisions/0001-admin-hierarchy-data-source.md): old 3-level hierarchy, GADM v4.1 alone, interim pending post-2025-reform data.
- [ADR 0002 — core architecture & system design](docs/decisions/0002-architecture-system-design.md): Flutter UI + a single shared Rust core (FFI/JNI/C-header) + FlatGeobuf mmap. **This is the basis for the repo structure below** — read it before touching build files.

Both are Accepted, reviewed by `tech-lead` and `ui-reviewer`. See [ticket/phase0/](ticket/phase0/) for the tickets they satisfy.

## Repo structure

```
core/         Rust crate — the shared geocoding core (ADR 0002 §1a)
app/          Flutter app (single Flutter project)
  lib/        Dart UI
  android/    the one Android application; :widget is a library module inside it
  ios/        Runner + Widget extension (Xcode project itself: see app/ios/README.md)
docs/         Architecture decision records
ticket/       Phase-by-phase ticket backlog
references/   Source data (e.g. GADM GeoJSON) — not code
```

This mirrors ADR 0002 §1a exactly — the widgets live *inside* the Flutter app's
platform folders, not as sibling projects, so "same process" (Android) and
"embedded in Runner" (iOS) hold.

## Building locally

**None of these toolchains are installed in the environment this scaffolding
was written in** (verified: no `rustc`, `cargo`, `flutter`, or `adb`) — the
files below are written to match ADR 0002 exactly, but have not been
built or run. Treat a first build on a real machine as the actual
verification step for phase0/03's acceptance criteria.

### Shared core (`core/`)

```bash
cd core
cargo build          # host build + regenerates include/vnaddr.h via build.rs
cargo test
```

Android target (`libvnaddr.so` per ABI, into `app/android/app/src/main/jniLibs/`):

```bash
cargo install cargo-ndk
rustup target add aarch64-linux-android x86_64-linux-android
cd core
cargo ndk -t arm64-v8a -t x86_64 -o ../app/android/app/src/main/jniLibs build --release
```

iOS target (`VnAddr.xcframework`) — must be done on a Mac:

```bash
cd core
rustup target add aarch64-apple-ios aarch64-apple-ios-sim
cargo build --release --target aarch64-apple-ios
cargo build --release --target aarch64-apple-ios-sim
xcodebuild -create-xcframework \
  -library target/aarch64-apple-ios/release/libvnaddr.a -headers include \
  -library target/aarch64-apple-ios-sim/release/libvnaddr.a -headers include \
  -output VnAddr.xcframework
```

### Flutter app (`app/`)

```bash
cd app
flutter pub get
flutter run          # launches on a connected Android device/emulator
```

Requires `core/`'s Android build above to have populated `jniLibs/` first, or
the FFI smoke call in `lib/main.dart` will fail at runtime with a clear error
(not a crash — see `vnaddr_ffi.dart`).

### Android widget module

Built as part of the Flutter app's Android build (`flutter build apk` /
`flutter run`) — `:widget` is a Gradle library module the `:app` module
depends on, not a separate app. See [ADR 0002 §1a/§9](docs/decisions/0002-architecture-system-design.md).

`app/android/` ships `gradle/wrapper/gradle-wrapper.properties` (pins Gradle
8.7) but not the `gradlew`/`gradlew.bat` wrapper scripts or `gradle-wrapper.jar`
themselves — run `gradle wrapper` once inside `app/android/` (with any local
Gradle install) to generate them, or open the project in Android Studio,
which does this automatically. Also copy `local.properties.example` to
`local.properties` and fill in real SDK paths first.

### iOS widget module

**The Xcode project does not exist yet.** This scaffolding was written on
Windows with no Xcode available — see [app/ios/README.md](app/ios/README.md)
for the exact manual steps (on a Mac) to generate `Runner.xcodeproj`, add the
`Widget` extension target, and wire in the files already provided under
`app/ios/Runner/` and `app/ios/Widget/`.

## CI

[.github/workflows/ci.yml](.github/workflows/ci.yml) runs one job per
component (`rust-core`, `flutter-app`, `android-widget`, `ios-widget`) with
independent pass/fail visibility, per phase0/03's acceptance criteria. The
`ios-widget` job is expected to fail until the manual Xcode setup above has
been done once and committed. CI provider (GitHub Actions) was chosen as a
default — the org's actual CI conventions were an open question in the
ticket, unset at scaffolding time.

## Scope of this scaffolding (phase0/03)

Per [ticket/phase0/03-repo-scaffolding](ticket/phase0/03-repo-scaffolding.md):
build/link plumbing and placeholder content only. No real geocoding logic,
dataset bundling, or finished UI/widgets — those start at
[phase1/01](ticket/phase1/01-boundary-dataset-build.md).
