import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/camera_unavailable.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/neighbour_offer_code.dart';

/// Films a neighbour's offer and hands it back (#152).
///
/// Pops with the first code that is an offer. Anything else in view -- a
/// link on a poster, a household transfer, a parcel label -- is ignored
/// rather than reported, because the camera sees it before the person
/// holding it has even aimed. Only an offer from a newer app is said out
/// loud, once: that one is the right code and cannot be read.
class NeighbourOfferScanScreen extends StatefulWidget {
  const NeighbourOfferScanScreen({super.key});

  @override
  State<NeighbourOfferScanScreen> createState() =>
      _NeighbourOfferScanScreenState();
}

class _NeighbourOfferScanScreenState extends State<NeighbourOfferScanScreen> {
  final _scanner = MobileScannerController(formats: [BarcodeFormat.qrCode]);
  var _done = false;
  var _toldTooNew = false;

  @override
  void dispose() {
    // Ours to make, ours to close: a controller handed to [MobileScanner]
    // is not disposed by it.
    unawaited(_scanner.dispose());
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;
      switch (NeighbourOfferCode.decode(value)) {
        case ReadNeighbourOffer(:final offer):
          _done = true;
          Navigator.of(context).pop(offer);
          return;
        case NeighbourOfferTooNew():
          if (_toldTooNew) continue;
          _toldTooNew = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.neighbourhoodTooNew),
            ),
          );
        case NotANeighbourOffer():
          continue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.neighbourhoodScan)),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
              errorBuilder: (context, error) => CameraUnavailable(
                error: error,
                alternative: l10n.neighbourhoodScanAlternative,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              l10n.neighbourhoodScanHint,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
