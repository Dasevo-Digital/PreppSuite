import 'package:flutter/material.dart';

import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/camera_unavailable.dart';
import '../../../core/feel.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Pushes a camera preview and pops with the first detected barcode's raw
/// value, or `null` if the user backs out without scanning anything.
///
/// The hint and the lamp are not decoration. On a phone lying on a table
/// — and in the place where a stock actually lives, a cellar shelf — the
/// preview is a black rectangle, and a black rectangle with nothing on it
/// looks exactly like a screen that failed to start. One sentence says
/// what the screen wants, and the lamp gives the reader a way to change
/// what it sees.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _controller = MobileScannerController();
  bool _handled = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        actions: [
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, child) {
              // A phone without a lamp, or one that has not said yet
              // whether it has one, gets no button rather than a dead
              // one.
              final torch = state.torchState;
              if (torch != TorchState.on && torch != TorchState.off) {
                return const SizedBox.shrink();
              }
              final on = torch == TorchState.on;
              return IconButton(
                tooltip: on ? l10n.scannerTorchOff : l10n.scannerTorchOn,
                icon: Icon(on ? Icons.flashlight_on : Icons.flashlight_off),
                onPressed: _controller.toggleTorch,
              );
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => CameraUnavailable(
              error: error,
              alternative: l10n.cameraAlternativeBarcode,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    l10n.scannerHint,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
