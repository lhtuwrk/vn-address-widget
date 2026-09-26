// Phase0/03 scaffolding entry point: proves the Flutter -> Rust core FFI
// path (ADR 0002) links and round-trips. Real screens are phase1/03+.

import 'package:flutter/material.dart';

import 'vnaddr_ffi.dart';

void main() {
  runApp(const VnAddressWidgetApp());
}

class VnAddressWidgetApp extends StatelessWidget {
  const VnAddressWidgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VN Address Widget',
      home: const _CoreFfiSmokeTestScreen(),
    );
  }
}

/// Placeholder screen: calls the shared core over FFI and shows the result,
/// so a build/run on device or emulator demonstrates the link (phase0/03
/// acceptance criterion), not just that it compiles.
class _CoreFfiSmokeTestScreen extends StatefulWidget {
  const _CoreFfiSmokeTestScreen();

  @override
  State<_CoreFfiSmokeTestScreen> createState() =>
      _CoreFfiSmokeTestScreenState();
}

class _CoreFfiSmokeTestScreenState extends State<_CoreFfiSmokeTestScreen> {
  String _status = 'Calling shared core...';

  @override
  void initState() {
    super.initState();
    _callCore();
  }

  void _callCore() {
    try {
      final core = VnaddrCore.instance();
      final pingResult = core.ping();
      setState(() {
        _status = 'core linked — abi v${core.abiVersion()}, '
            'ping() = $pingResult';
      });
    } catch (e) {
      setState(() {
        _status = 'core FFI call failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('VN Address Widget — scaffolding')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_status, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
