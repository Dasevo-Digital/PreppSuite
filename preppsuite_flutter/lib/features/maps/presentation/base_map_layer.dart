import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/feature_activity.dart';
import '../../../core/memory_pressure_listener.dart';
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
class BaseMapLayer extends ConsumerStatefulWidget {
  const BaseMapLayer({super.key});
  @override
  ConsumerState<BaseMapLayer> createState() => _BaseMapLayerState();
}

class _BaseMapLayerState extends ConsumerState<BaseMapLayer> {
  late final MemoryPressureListener _memory;
  int _cacheGeneration = 0;
  bool _lowMemory = false;
  @override
  void initState() {
    super.initState();
    _memory = MemoryPressureListener(() {
      if (mounted) {
        setState(() {
          _lowMemory = true;
          _cacheGeneration++;
        });
      }
    });
  }

  @override
  void dispose() {
    _memory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureActivity.of(context)) return const SizedBox.shrink();
    final mobile = Platform.isAndroid || Platform.isIOS;
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
        key: ValueKey(_cacheGeneration),
        // Only the visible map keeps a renderer. Pressure recreates it
        // with a smaller budget; the map camera remains in its parent.
        memoryTileCacheMaxSize:
            (_lowMemory
                ? 8
                : mobile
                ? 16
                : 48) *
            1024 *
            1024,
        memoryTileDataCacheMaxSize: _lowMemory
            ? 16
            : mobile
            ? 32
            : 80,
        // Show a coarser tile rather than nothing while the right one is
        // still being read — and where there is no right one at all. A
        // staggered download deliberately stops at a shallower zoom
        // outside the chosen region, and 3 is the most the library allows.
        maximumTileSubstitutionDifference: 3,
        concurrency: _lowMemory
            ? 1
            : mobile
            ? 2
            : _renderConcurrency,
      );
    }

    return TileLayer(
      key: ValueKey(_cacheGeneration),
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'de.status403.preppsuite',
    );
  }
}

/// Desktop render workers use half the available cores, bounded at 4–8.
/// Mobile uses two workers; after memory pressure all platforms use one.
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
