import 'package:flutter/material.dart';

import '../../../core/feel.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Pushes a camera preview and pops with the first detected barcode's raw
/// value, or `null` if the user backs out without scanning anything.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null || value.isEmpty) return;

    _handled = true;
    // The one moment in the app where nobody is looking at the screen:
    // the phone is held against a packet and the answer is the screen
    // going away.
    Feel.arrived();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: MobileScanner(onDetect: _onDetect),
    );
  }
}
