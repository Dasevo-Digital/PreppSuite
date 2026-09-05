import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/offline_map_providers.dart';
import '../application/pmtiles_tile_provider.dart';

/// The map itself, from a local archive when there is one and from
/// OpenStreetMap's tile servers otherwise.
///
/// The fallback is the point: an offline map is a large download that most
/// people will not have made, and a preparedness app whose map is blank
/// until they do would be worse than one that simply needs a connection.
class BaseMapLayer extends ConsumerWidget {
  const BaseMapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = ref.watch(offlineMapProvider).value?.archive;

    if (archive != null) {
      return VectorTileLayer(
        theme: ref.watch(mapThemeProvider),
        // The source name is the one the built-in style refers to; the
        // archive it reads from is local, which is the whole difference.
        tileProviders: TileProviders({
          'openmaptiles': PmTilesVectorTileProvider(archive),
        }),
      );
    }

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'de.status403.preppsuite',
    );
  }
}

/// Credit for whichever map is actually being shown.
///
/// Both sources ask for it in their terms, and they are not the same
/// sentence: the offline map adds OpenMapTiles, whose schema and style the
/// renderer uses.
class BaseMapAttribution extends ConsumerWidget {
  const BaseMapAttribution({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(offlineMapProvider).value?.isReady ?? false;

    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(
          offline ? l10n.mapAttributionOffline : l10n.shelterAttribution,
        ),
      ],
    );
  }
}
