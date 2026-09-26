// Dart FFI bindings to the shared Rust core (ADR 0002 §1, §9).
//
// Loading strategy per ADR 0002 §9:
//   - Android: the core is a dynamically-loaded `libvnaddr.so` -> DynamicLibrary.open.
//   - iOS: the core is statically linked into Runner -> DynamicLibrary.process()
//     (symbols resolved from the already-loaded process image, not a separate .so).
//
// Phase0/03 scope: only the placeholder round-trip (`vnaddr_ping`) and the ABI
// version check are wired up here, to prove the FFI path itself works. Real
// lookup/open bindings arrive with phase1/02.

import 'dart:ffi';
import 'dart:io' show Platform;

typedef _VnaddrAbiVersionNative = Uint32 Function();
typedef _VnaddrAbiVersionDart = int Function();

typedef _VnaddrPingNative = Int32 Function();
typedef _VnaddrPingDart = int Function();

/// Must match `core::ABI_VERSION` in `core/src/lib.rs` (ADR 0002 §10).
const int expectedAbiVersion = 1;

class VnaddrCoreMismatchException implements Exception {
  final int expected;
  final int actual;
  VnaddrCoreMismatchException(this.expected, this.actual);

  @override
  String toString() =>
      'vnaddr core ABI mismatch: app expects $expected, library reports $actual';
}

/// Thin wrapper around the shared core's placeholder FFI surface.
/// See `core/src/lib.rs` for the Rust side and `core/include/vnaddr.h` for
/// the C surface this binds against.
class VnaddrCore {
  VnaddrCore._(this._abiVersion, this._ping);

  final _VnaddrAbiVersionDart _abiVersion;
  final _VnaddrPingDart _ping;

  static VnaddrCore? _instance;

  /// Loads the core (per-platform strategy above) and checks its ABI version.
  /// Throws [VnaddrCoreMismatchException] on a header/library mismatch
  /// (ADR 0002 §10) rather than proceeding with undefined behavior.
  static VnaddrCore instance() {
    final existing = _instance;
    if (existing != null) return existing;

    final DynamicLibrary lib = Platform.isAndroid
        ? DynamicLibrary.open('libvnaddr.so')
        : DynamicLibrary.process();

    final abiVersion =
        lib.lookupFunction<_VnaddrAbiVersionNative, _VnaddrAbiVersionDart>(
      'vnaddr_abi_version',
    );
    final ping = lib.lookupFunction<_VnaddrPingNative, _VnaddrPingDart>(
      'vnaddr_ping',
    );

    final actual = abiVersion();
    if (actual != expectedAbiVersion) {
      throw VnaddrCoreMismatchException(expectedAbiVersion, actual);
    }

    final core = VnaddrCore._(abiVersion, ping);
    _instance = core;
    return core;
  }

  int abiVersion() => _abiVersion();

  /// Placeholder round-trip call — proves the FFI path works end to end
  /// (phase0/03 acceptance criterion). Always returns 42.
  int ping() => _ping();
}
