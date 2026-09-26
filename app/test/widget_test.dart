// Flutter smoke test for the vnaddr FFI bindings (phase0/03).
//
// What is tested here:
//   - `VnaddrCore.expectedAbiVersion` is the Dart-side constant (== 1).
//     This is a pure Dart check and requires no native library to be loaded,
//     so it runs safely on CI machines that have no libvnaddr.so installed.
//
// What is NOT tested here:
//   - `VnaddrCore.instance()` — that call opens the native .so / process image
//     via dart:ffi and would fail on CI runners that have no compiled Rust
//     core.  The full FFI round-trip (ping() == 42) is a manual / on-device
//     verification step documented in the root README.  Add it to an
//     integration_test/ target once a device farm is available (phase1 or
//     later).

import 'package:flutter_test/flutter_test.dart';
import 'package:vn_address_widget/vnaddr_ffi.dart';

void main() {
  group('VnaddrCore Dart-level constants', () {
    test('expectedAbiVersion is 1', () {
      // The constant mirrors `ABI_VERSION` in core/src/lib.rs (ADR 0002 §10).
      // If this ever changes on the Rust side the constant here must be bumped
      // in lock-step — a test failure here is an intentional guard.
      expect(VnaddrCore.expectedAbiVersion, equals(1));
    });
  });
}
