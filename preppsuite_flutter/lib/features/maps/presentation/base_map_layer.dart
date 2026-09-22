import 'dart:async';
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

  /// How long a map that is no longer being looked at keeps its renderer.
  ///
  /// It used to be dropped the moment the tab lost focus, which made
  /// every return to the map a cold start: the parsed-tile cache went
  /// with it, and the whole screenful had to be read, decoded and
  /// rasterised again. Measured on a 1.9 GB country extract, opening the
  /// archive is 3 ms and the first tile 8 ms — but reading and decoding a
  /// screenful of 48 tiles is 117 ms of work that was being repeated for
  /// nothing every time somebody checked the shopping list and came back.
  ///
  /// A minute rather than forever, because there are two map
  /// destinations and their caches are 48 MiB each on desktop. Somebody
  /// switching tabs gets the map back instantly; somebody who has moved
  /// on gets the memory back. Memory pressure ends it early.
  static const releaseGrace = Duration(seconds: 60);

  @override
  ConsumerState<BaseMapLayer> createState() => _BaseMapLayerState();
}

class _BaseMapLayerState extends ConsumerState<BaseMapLayer> {
  late final MemoryPressureListener _memory;
  int _cacheGeneration = 0;
  bool _lowMemory = false;

  /// Whether the renderer has actually been let go.
  bool _released = false;
  Timer? _release;

  /// Whether this map is the one on screen. Kept as a field so the
  /// memory-pressure callback can act on it without a build context.
  bool _active = true;

  @override
  void initState() {
    super.initState();
    _memory = MemoryPressureListener(() {
      if (!mounted) return;
      setState(() {
        _lowMemory = true;
        _cacheGeneration++;
        // Pressure ends the grace period outright. Holding a cache for a
        // map nobody is looking at is exactly what there is no room for.
        if (!_active) {
          _release?.cancel();
          _release = null;
          _released = true;
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // FeatureActivity is an inherited widget, so this runs on every
    // change of it — which is what starts and stops the grace period.
    _active = FeatureActivity.of(context);
    if (_active) {
      _release?.cancel();
      _release = null;
      if (_released) setState(() => _released = false);
      return;
    }

    if (_released || _release != null) return;
    _release = Timer(BaseMapLayer.releaseGrace, () {
      if (mounted) setState(() => _released = true);
    });
  }

  @override
  void dispose() {
    _release?.cancel();
    _memory.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Still read, and still the thing that decides — a released renderer
    // stays released until this says the map is being looked at again.
    final active = FeatureActivity.of(context);
    if (!active && _released) return const SizedBox.shrink();
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
        // A map keeps its renderer while it is on screen and for
        // [BaseMapLayer.releaseGrace] after. Pressure recreates it with a smaller
        // budget, or drops it outright where it is not on screen; the map
        // camera remains in its parent either way.
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
      // A tile server that refuses leaves an empty square and says
      // nothing. On a map that is mostly there, that reads as a bug in
      // the app rather than as a connection that did not hold — and
      // whoever sees it goes looking in the wrong place.
      errorTileCallback: (_, _, _) => onlineTileFailures.report(),
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

/// When a tile last failed to arrive from the network.
///
/// A counter and not a state: there is no "it is fine again" event to
/// listen for, so what can honestly be said is "this was still happening
/// a moment ago". The map layer is deep inside a [FlutterMap], and the
/// sentence belongs outside it, which is why this is a listenable of its
/// own rather than something handed down.
class OnlineTileFailures extends ChangeNotifier {
  DateTime? _last;

  /// How long after the last failure the notice is still worth showing.
  ///
  /// Long enough to survive a screenful of tiles arriving one by one,
  /// short enough that a connection which has come back stops being
  /// accused of something it is no longer doing.
  static const window = Duration(seconds: 20);

  bool get recent {
    final last = _last;
    return last != null && DateTime.now().difference(last) < window;
  }

  void report() {
    final previous = _last;
    _last = DateTime.now();
    // Only when it is news. A failing screenful is dozens of these a
    // second, and every one of them would rebuild the notice.
    if (previous == null || DateTime.now().difference(previous) > window) {
      notifyListeners();
    }
  }

  /// Forgets what happened — used when the map changes source, where
  /// the old source's troubles are no longer the question.
  void clear() {
    if (_last == null) return;
    _last = null;
    notifyListeners();
  }
}

final onlineTileFailures = OnlineTileFailures();
