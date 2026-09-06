import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../downloads/application/byte_size.dart';
import '../application/map_area_download.dart';
import '../application/map_download_providers.dart';
import '../application/map_source_store.dart';
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

  double _zoom = 13;

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
    _controller.dispose();
    super.dispose();
  }

  static const _minDetail = 8.0;
  static const _maxDetail = 14.0;

  void _updateArea() {
    final bounds = _controller.camera.visibleBounds;

    MapArea areaAt(int detail) => MapArea(
      minLongitude: bounds.west,
      minLatitude: bounds.south,
      maxLongitude: bounds.east,
      maxLatitude: bounds.north,
      maxZoom: detail,
    );

    if (!_zoomChosen) {
      // The deepest level this area still fits in, so the screen opens
      // on something that can actually be downloaded.
      var suggestion = _minDetail;
      for (var detail = _maxDetail; detail >= _minDetail; detail--) {
        if (areaAt(detail.round()).tileCount <= MapAreaDownloader.tileLimit) {
          suggestion = detail;
          break;
        }
      }
      _zoom = suggestion;
    }

    setState(() => _area = areaAt(_zoom.round()));
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
                onPositionChanged: (_, _) => _updateArea(),
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

    return [
      Text(l10n.mapDownloadIntro, style: theme.textTheme.bodySmall),
      const SizedBox(height: 8),
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
      Text(l10n.mapDownloadZoomHint, style: theme.textTheme.bodySmall),
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
