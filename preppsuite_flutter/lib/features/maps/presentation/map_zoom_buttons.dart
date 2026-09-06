import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Plain zoom controls for the corner of a map.
///
/// Scrolling to zoom works with a trackpad and with a wheel, but not with
/// every pointing device — an Apple mouse reports its surface as a
/// gesture device, and what reaches the map is not always a scroll. These
/// buttons work with anything that can be clicked, which is the point.
class MapZoomButtons extends StatelessWidget {
  const MapZoomButtons({
    super.key,
    required this.controller,
    this.alignment = Alignment.topRight,
  });

  final MapController controller;
  final Alignment alignment;

  static const _step = 1.0;

  void _by(double amount) {
    final camera = controller.camera;
    final zoom = (camera.zoom + amount).clamp(
      camera.minZoom ?? 0.0,
      camera.maxZoom ?? 20.0,
    );
    controller.move(camera.center, zoom);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Compact on purpose: the control sits over the map in whatever
    // height is left for it, and a short map — a small window, a phone in
    // landscape — must not make it overflow its own corner.
    Widget button(IconData icon, String tooltip, double amount) => IconButton(
      icon: Icon(icon, size: 20),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 38, height: 34),
      onPressed: () => _by(amount),
    );

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Card(
          margin: EdgeInsets.zero,
          color: theme.colorScheme.surface.withValues(alpha: 0.92),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              button(Icons.add, l10n.mapZoomIn, _step),
              Divider(
                height: 1,
                thickness: 1,
                indent: 6,
                endIndent: 6,
                color: theme.colorScheme.outlineVariant,
              ),
              button(Icons.remove, l10n.mapZoomOut, -_step),
            ],
          ),
        ),
      ),
    );
  }
}
