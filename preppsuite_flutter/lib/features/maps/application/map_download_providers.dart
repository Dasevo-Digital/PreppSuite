import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../downloads/application/download_folder.dart';
import 'map_area_download.dart';
import 'map_source_store.dart';
import 'offline_map_providers.dart';
import 'tile_source.dart';

class MapDownloadState {
  const MapDownloadState({
    this.progress,
    this.error,
    this.finishedPath,
    this.running = false,
  });

  final MapDownloadProgress? progress;
  final Object? error;

  /// Set once the archive is built and has been taken into use.
  final String? finishedPath;

  final bool running;

  bool get isIdle => !running && error == null && finishedPath == null;
}

/// Builds an offline map for a chosen area.
class MapDownloadController extends Notifier<MapDownloadState> {
  StreamSubscription<MapDownloadProgress>? _subscription;

  @override
  MapDownloadState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const MapDownloadState();
  }

  Future<void> start({required MapArea area, required String label}) async {
    if (state.running) return;

    state = const MapDownloadState(running: true);

    final MapTileProvider provider;
    final VectorTileSource source;
    final Directory folder;
    final String target;

    try {
      const store = MapSourceStore();
      provider = await store.provider();
      source = await TileSourceClient().load(
        provider,
        apiKey: await store.apiKey(),
      );

      folder = await const DownloadFolder().current();
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .substring(0, 16);
      target =
          '${folder.path}${Platform.pathSeparator}'
          'preppsuite-map-z${area.maxZoom}-$stamp.pmtiles';
    } on Object catch (error) {
      state = MapDownloadState(error: error);
      return;
    }

    _subscription = MapAreaDownloader()
        .download(
          area: area,
          source: source,
          targetPath: target,
          workingDirectory: folder,
        )
        .listen(
          (progress) => state = MapDownloadState(
            progress: progress,
            running: true,
          ),
          onError: (Object error) {
            state = MapDownloadState(error: error);
          },
          onDone: () async {
            if (state.error != null) return;
            // Taking it into use is the point of building it; the map
            // switches to the new archive without a further step.
            await ref
                .read(offlineMapProvider.notifier)
                .useArchive(location: target, label: label);
            state = MapDownloadState(
              progress: state.progress,
              finishedPath: target,
            );
          },
        );
  }

  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    state = const MapDownloadState();
  }

  void dismiss() {
    if (state.running) return;
    state = const MapDownloadState();
  }
}

final mapDownloadProvider =
    NotifierProvider<MapDownloadController, MapDownloadState>(
      MapDownloadController.new,
    );

/// The provider new downloads use, and its key.
final mapSourceProvider = FutureProvider((ref) async {
  const store = MapSourceStore();
  return (provider: await store.provider(), apiKey: await store.apiKey());
});
