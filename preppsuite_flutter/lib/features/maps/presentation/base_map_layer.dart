import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/map_source_preference.dart';
import '../application/offline_map_providers.dart';
import '../application/pmtiles_tile_provider.dart';

/// The map itself, from a local archive when there is one and from
/// OpenStreetMap's tile servers otherwise.
///
/// The fallback is the point: an offline map is a large download that most
/// people will not have made, and a preparedness app whose map is blank
/// until they do would be worse than one that simply needs a connection.
///
/// The user can also send it to the network with an archive open, which
/// is what [mapSourceProvider] carries: an extract ends at the edge of
/// what was downloaded, and looking past that edge should not mean
/// forgetting the archive to do it.
class BaseMapLayer extends ConsumerWidget {
  const BaseMapLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final archive = usesOfflineMap(ref)
        ? ref.watch(offlineMapProvider).value?.archive
        : null;

    if (archive != null) {
      return VectorTileLayer(
        theme: ref.watch(mapThemeProvider),
        // The source name is the one the built-in style refers to; the
        // archive it reads from is local, which is the whole difference.
        tileProviders: TileProviders({
          'openmaptiles': PmTilesVectorTileProvider(archive),
        }),
        // Measured on a real 1.5 GB German extract: a tile is 60-400 KB
        // around zoom 10-14 and 0.5-1.5 MB below zoom 5, where one tile
        // carries a continent. The default 10 MB of raw tiles holds about
        // a dozen of the small ones and fewer than ten of the large, so
        // panning one window width throws away everything just left
        // behind — and every tile coming back has to be read and parsed
        // again. That is what makes an offline map feel like dragging a
        // picture around.
        memoryTileCacheMaxSize: 48 * 1024 * 1024,
        // The parsed tiles, which are the expensive ones. A desktop
        // window at 512-pixel tiles holds a dozen to twenty at once; the
        // default of 20 means the cache is full before anything has been
        // panned at all.
        memoryTileDataCacheMaxSize: 80,
        // Show a coarser tile rather than nothing while the right one is
        // still being read — and where there is no right one at all. A
        // staggered download deliberately stops at a shallower zoom
        // outside the chosen region, and 3 is the most the library allows.
        maximumTileSubstitutionDifference: 3,
        concurrency: _renderConcurrency,
      );
    }

    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'de.status403.preppsuite',
    );
  }
}

/// How many isolates render tiles.
///
/// The library's default is 4, and that is what a screenful takes seven
/// seconds to fill on. Measured from the tile cache's own timestamps:
/// about three finished tiles a second at the busiest, while a window at
/// low zoom wants twenty — which is why the map arrived in visible
/// instalments rather than at once.
///
/// The work is parsing and drawing, both of which the isolates do in
/// parallel, so the machine's own width is the right measure. Half the
/// cores, never fewer than the default and never more than eight: past
/// that the tiles are not the bottleneck any more and each isolate still
/// costs memory. A phone reports few enough cores to land on the default
/// by itself.
int get _renderConcurrency => (Platform.numberOfProcessors ~/ 2).clamp(4, 8);

/// Whether the map is currently drawing from the archive.
///
/// One reading of the two providers, in one place: the layer needs it to
/// pick a source, the attribution to name it, and the map screen to say
/// so — and all three saying something different would be worse than any
/// one of them being wrong.
bool usesOfflineMap(WidgetRef ref) {
  if (ref.watch(mapSourceProvider) == MapSourcePreference.online) return false;
  return ref.watch(offlineMapProvider).value?.isReady ?? false;
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
    final offline = usesOfflineMap(ref);

    return RichAttributionWidget(
      attributions: [
        TextSourceAttribution(
          offline ? l10n.mapAttributionOffline : l10n.shelterAttribution,
        ),
      ],
    );
  }
}
