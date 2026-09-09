import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'base_map_layer.dart';

/// Stable labels for major cities that must remain identifiable in an
/// offline extract. Vector-tile label collision is renderer-dependent and
/// previously dropped Braunschweig completely at regional zoom levels.
class OfflineCityLabels extends ConsumerWidget {
  const OfflineCityLabels({super.key});

  static const _cities = <({String name, LatLng point, double minZoom})>[
    (name: 'Braunschweig', point: LatLng(52.2689, 10.5268), minZoom: 6.0),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!usesOfflineMap(ref)) return const SizedBox.shrink();
    final zoom = MapCamera.of(context).zoom;
    final colors = Theme.of(context).colorScheme;
    return MarkerLayer(
      markers: [
        for (final city in _cities)
          if (zoom >= city.minZoom)
            Marker(
              point: city.point,
              width: 150,
              height: 34,
              child: IgnorePointer(
                child: Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: .82),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      child: Text(
                        city.name,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
