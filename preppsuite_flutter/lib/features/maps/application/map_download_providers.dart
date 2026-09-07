import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform_storage.dart';
import '../../downloads/application/download_folder.dart';
import 'map_area_download.dart';
import 'map_download_plan.dart';
import 'map_download_session.dart';
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

/// The unfinished download waiting to be picked up, if there is one.
///
/// A country is over an hour of tiles, so the normal end of a download is
/// the app being closed, not the archive being finished.
final unfinishedDownloadProvider =
    FutureProvider<({MapDownloadSession session, int stored})?>((ref) async {
      const store = MapDownloadSessionStore();
      final folder = await const DownloadFolder().current();

      final session = await store.read(folder);
      if (session == null) return null;
      return (session: session, stored: await store.storedTileCount(folder));
    });

/// Builds an offline map for a chosen area.
class MapDownloadController extends Notifier<MapDownloadState> {
  StreamSubscription<MapDownloadProgress>? _subscription;

  @override
  MapDownloadState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const MapDownloadState();
  }

  /// Begins a new download, discarding anything half-finished.
  Future<void> start({
    required MapDownloadPlan plan,
    required String label,
  }) async {
    if (state.running) return;

    final folder = await const DownloadFolder().current();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 16);

    await _run(
      session: MapDownloadSession(
        plan: plan,
        targetPath:
            '${folder.path}${Platform.pathSeparator}'
            'preppsuite-map-z${plan.maxZoom}-$stamp.pmtiles',
        label: label,
        startedAt: DateTime.now(),
      ),
      folder: folder,
      resume: false,
    );
  }

  /// Picks up the download a previous run left behind.
  Future<void> resumeSession(MapDownloadSession session) async {
    if (state.running) return;
    await _run(
      session: session,
      folder: await const DownloadFolder().current(),
      resume: true,
    );
  }

  /// Throws the half-finished download away.
  Future<void> discard() async {
    if (state.running) return;
    final folder = await const DownloadFolder().current();
    await const MapDownloadSessionStore().clear(folder);
    ref.invalidate(unfinishedDownloadProvider);
    state = const MapDownloadState();
  }

  Future<void> _run({
    required MapDownloadSession session,
    required Directory folder,
    required bool resume,
  }) async {
    state = const MapDownloadState(running: true);

    final plan = session.plan;
    final target = session.targetPath;
    final VectorTileSource source;

    try {
      const store = MapSourceStore();
      source = await TileSourceClient().load(
        await store.provider(),
        apiKey: await store.apiKey(),
      );

      // Written before the first tile, so a download interrupted at any
      // point after this can be found again.
      await const MapDownloadSessionStore().write(folder, session);
      ref.invalidate(unfinishedDownloadProvider);
    } on Object catch (error) {
      state = MapDownloadState(error: error);
      return;
    }

    _subscription = MapAreaDownloader()
        .download(
          plan: plan,
          source: source,
          targetPath: target,
          workingDirectory: folder,
          resume: resume,
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

            // The archive exists, so nothing is left to resume.
            await const MapDownloadSessionStore().clear(folder);
            ref.invalidate(unfinishedDownloadProvider);

            // Taking it into use is the point of building it; the map
            // switches to the new archive without a further step.
            //
            // What gets remembered is a handle where the platform has
            // them, not the path. The path works for the rest of this
            // run — the download folder's scope is open — and is unusable
            // on the next launch, which is how a finished download turned
            // into one the user had to go and find again by hand.
            final remembered = await rememberStoragePath(
              target,
              label: session.label,
            );
            await ref
                .read(offlineMapProvider.notifier)
                .useArchive(
                  location: remembered?.value ?? target,
                  label: session.label,
                );
            state = MapDownloadState(
              progress: state.progress,
              finishedPath: target,
            );
          },
        );
  }

  /// Stops the transfer. What arrived stays on disk, session and all, so
  /// the next attempt picks it up instead of starting the hour again.
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    ref.invalidate(unfinishedDownloadProvider);
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
