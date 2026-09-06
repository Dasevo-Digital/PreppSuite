import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../application/map_area_download.dart';
import '../application/map_download_providers.dart';
import '../application/map_source_store.dart';
import '../application/place_search.dart';
import '../application/tile_source.dart';
import 'base_map_layer.dart';

/// Picks an area on the map and builds an offline archive of it.
///
/// The area is the visible viewport rather than a list of regions: what
/// somebody needs offline is where they are, and no list of administrative
/// boundaries would name it.
class MapDownloadScreen extends ConsumerStatefulWidget {
  const MapDownloadScreen({super.key});

  @override
  ConsumerState<MapDownloadScreen> createState() => _MapDownloadScreenState();
}

class _MapDownloadScreenState extends ConsumerState<MapDownloadScreen> {
  final _controller = MapController();

  final _searchController = TextEditingController();

  double _zoom = 13;

  /// The place the area comes from, if one was searched for.
  ///
  /// A named place is a box of its own, not whatever happens to be on
  /// screen — which is the point: "Niedersachsen" is an area somebody can
  /// mean, and the visible rectangle around it is not.
  PlaceResult? _place;

  List<PlaceResult>? _results;
  bool _searching = false;
  Object? _searchError;

  /// Until the slider is touched, the detail level follows the map.
  ///
  /// Opening on the whole country with the slider at 13 would mean six
  /// figures of tiles and a download button that is disabled before
  /// anyone has done anything — a screen that starts by saying no. Once
  /// a level has been chosen deliberately it stays chosen, even if that
  /// makes the area too large: that message is then an answer to
  /// something the user did.
  bool _zoomChosen = false;

  MapArea? _area;

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  static const _minDetail = 8.0;
  static const _maxDetail = 14.0;

  void _updateArea() {
    final place = _place;
    final bounds = _controller.camera.visibleBounds;

    MapArea areaAt(int detail) =>
        place?.areaAt(detail) ??
        MapArea(
          minLongitude: bounds.west,
          minLatitude: bounds.south,
          maxLongitude: bounds.east,
          maxLatitude: bounds.north,
          maxZoom: detail,
        );

    if (!_zoomChosen) {
      // The deepest level this area still fits in, so the screen opens —
      // and a searched place lands — on something downloadable.
      _zoom =
          (deepestDetailWithin(
                    areaAt(_maxDetail.round()),
                    lowest: _minDetail.round(),
                    highest: _maxDetail.round(),
                  ) ??
                  _minDetail.round())
              .toDouble();
    }

    setState(() => _area = areaAt(_zoom.round()));
  }

  Future<void> _search(AppLocalizations l10n) async {
    setState(() {
      _searching = true;
      _searchError = null;
      _results = null;
    });

    try {
      final results = await PlaceSearchClient().search(
        _searchController.text,
        language: Localizations.localeOf(context).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _results = results;
        _searching = false;
      });
      if (results.isNotEmpty) await _offerResults(results, l10n);
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _searchError = error;
        _searching = false;
      });
    }
  }

  Future<void> _offerResults(
    List<PlaceResult> results,
    AppLocalizations l10n,
  ) async {
    final chosen = await showModalBottomSheet<PlaceResult>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final result in results)
              ListTile(
                title: Text(result.name),
                subtitle: Text(
                  result.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  '${result.areaAt(_maxDetail.round()).tileCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onTap: () => Navigator.of(context).pop(result),
              ),
          ],
        ),
      ),
    );
    if (chosen == null || !mounted) return;
    _usePlace(chosen);
  }

  void _usePlace(PlaceResult place) {
    _place = place;
    // The level was chosen for the last area; this one gets its own.
    _zoomChosen = false;

    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          LatLng(place.minLatitude, place.minLongitude),
          LatLng(place.maxLatitude, place.maxLongitude),
        ),
        padding: const EdgeInsets.all(24),
      ),
    );
    _updateArea();
  }

  Future<void> _start(AppLocalizations l10n) async {
    final area = _area;
    if (area == null) return;

    await ref
        .read(mapDownloadProvider.notifier)
        .start(area: area, label: l10n.mapDownloadLabel('${area.maxZoom}'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final download = ref.watch(mapDownloadProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.mapDownloadTitle)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: const LatLng(51.16, 10.45),
                initialZoom: 6,
                onMapReady: _updateArea,
                onPositionChanged: (_, hasGesture) {
                  // Moving the map by hand means the area is whatever is
                  // on screen again; moving it to fit a searched place
                  // does not, which is what `hasGesture` separates.
                  if (hasGesture) _place = null;
                  _updateArea();
                },
              ),
              children: [
                const BaseMapLayer(),
                BaseMapAttribution(l10n: l10n),
              ],
            ),
          ),
          Material(
            elevation: 8,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (download.running)
                      _Running(l10n: l10n, state: download)
                    else if (download.finishedPath != null)
                      _Finished(l10n: l10n)
                    else if (download.error != null)
                      _Failed(l10n: l10n, error: download.error!)
                    else
                      ..._chooser(l10n, theme),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _chooser(AppLocalizations l10n, ThemeData theme) {
    final area = _area;
    final tiles = area?.tileCount ?? 0;
    final tooLarge = tiles > MapAreaDownloader.tileLimit;

    final place = _place;
    final deepest = area == null
        ? null
        : deepestDetailWithin(
            area,
            lowest: _minDetail.round(),
            highest: _maxDetail.round(),
          );

    return [
      TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          labelText: l10n.mapDownloadSearchHint,
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: _searching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _search(l10n),
                ),
        ),
        onSubmitted: (_) => _search(l10n),
      ),
      if (_searchError != null) ...[
        const SizedBox(height: 4),
        Text(
          l10n.mapDownloadSearchFailed(_searchError.toString()),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ] else if (_results != null && _results!.isEmpty) ...[
        const SizedBox(height: 4),
        Text(l10n.mapDownloadSearchNoResults, style: theme.textTheme.bodySmall),
      ],
      const SizedBox(height: 8),
      Row(
        children: [
          Icon(
            place == null ? Icons.crop_free : Icons.place_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              place == null
                  ? l10n.mapDownloadAreaViewport
                  : l10n.mapDownloadAreaPlace(place.name, place.kind),
              style: theme.textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      const _SourcePicker(),
      const SizedBox(height: 8),
      Row(
        children: [
          Text(l10n.mapDownloadZoomLabel, style: theme.textTheme.labelLarge),
          Expanded(
            child: Slider(
              value: _zoom,
              min: _minDetail,
              max: _maxDetail,
              divisions: (_maxDetail - _minDetail).round(),
              label: '${_zoom.round()}',
              onChanged: (value) {
                setState(() {
                  _zoom = value;
                  _zoomChosen = true;
                });
                _updateArea();
              },
            ),
          ),
          Text('${_zoom.round()}', style: theme.textTheme.labelLarge),
        ],
      ),
      Text(
        _zoomChosen ? l10n.mapDownloadZoomHint : l10n.mapDownloadDetailAuto,
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      Text(
        tooLarge
            ? l10n.mapDownloadTooLarge('$tiles')
            // Rough on purpose: a tile of a city centre is many times the
            // size of one of a field, and neither is known before it is
            // fetched.
            : l10n.mapDownloadTileCount(
                '$tiles',
                formatByteSize(tiles * 45000),
              ),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: tooLarge ? theme.colorScheme.error : null,
        ),
      ),
      // Says where the ceiling is, not only that one was hit: the levels
      // differ by a factor of four, so "too many" on its own is no
      // guidance at all.
      if (area != null && deepest == null && place != null) ...[
        const SizedBox(height: 4),
        Text(
          l10n.mapDownloadPlaceTooLarge(place.name),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ] else if (area != null &&
          deepest != null &&
          deepest < _maxDetail.round()) ...[
        const SizedBox(height: 4),
        Text(
          l10n.mapDownloadDeepestPossible(
            '${area.withDetail(_maxDetail.round()).tileCount}',
            '$deepest',
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 4),
      Text(l10n.mapDownloadPolite, style: theme.textTheme.bodySmall),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: tooLarge || tiles == 0 ? null : () => _start(l10n),
        icon: const Icon(Icons.download_outlined),
        label: Text(l10n.mapDownloadAction),
      ),
    ];
  }
}

class _Running extends ConsumerWidget {
  const _Running({required this.l10n, required this.state});

  final AppLocalizations l10n;
  final MapDownloadState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = state.progress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mapDownloadRunning(
            '${progress?.done ?? 0}',
            '${progress?.total ?? 0}',
            formatByteSize(progress?.bytes ?? 0),
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress?.fraction),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.read(mapDownloadProvider.notifier).cancel(),
          child: Text(l10n.downloadCancelAction),
        ),
      ],
    );
  }
}

class _Finished extends ConsumerWidget {
  const _Finished({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.mapDownloadFinished),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: () {
            ref.read(mapDownloadProvider.notifier).dismiss();
            Navigator.of(context).pop();
          },
          child: Text(l10n.downloadDismissAction),
        ),
      ],
    );
  }
}

class _Failed extends ConsumerWidget {
  const _Failed({required this.l10n, required this.error});

  final AppLocalizations l10n;
  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.mapDownloadFailed(error.toString()),
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => ref.read(mapDownloadProvider.notifier).dismiss(),
          child: Text(l10n.downloadRetryAction),
        ),
      ],
    );
  }
}

/// Which provider the tiles come from, and the key for the one that needs
/// one.
class _SourcePicker extends ConsumerStatefulWidget {
  const _SourcePicker();

  @override
  ConsumerState<_SourcePicker> createState() => _SourcePickerState();
}

class _SourcePickerState extends ConsumerState<_SourcePicker> {
  final _keyController = TextEditingController();
  bool _keyLoaded = false;

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final source = ref.watch(mapSourceProvider);
    if (source is! AsyncData) return const SizedBox.shrink();

    final provider = source.requireValue.provider;
    if (!_keyLoaded) {
      _keyController.text = source.requireValue.apiKey ?? '';
      _keyLoaded = true;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<MapTileProvider>(
          key: ValueKey(provider),
          initialValue: provider,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.mapDownloadSourceLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(
              value: MapTileProvider.openFreeMap,
              child: Text(l10n.mapDownloadSourceOpenFreeMap),
            ),
            DropdownMenuItem(
              value: MapTileProvider.mapTiler,
              child: Text(l10n.mapDownloadSourceMapTiler),
            ),
          ],
          onChanged: (value) async {
            if (value == null) return;
            await const MapSourceStore().useProvider(value);
            ref.invalidate(mapSourceProvider);
          },
        ),
        if (provider == MapTileProvider.mapTiler) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            decoration: InputDecoration(
              labelText: l10n.mapDownloadApiKeyLabel,
              helperText: l10n.mapDownloadApiKeyHint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (value) async {
              await const MapSourceStore().saveApiKey(value);
              ref.invalidate(mapSourceProvider);
            },
          ),
        ],
      ],
    );
  }
}
