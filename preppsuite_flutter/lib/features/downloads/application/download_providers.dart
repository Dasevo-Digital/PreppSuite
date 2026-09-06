import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'archive_downloader.dart';
import 'download_folder.dart';

/// One archive to fetch.
class ArchiveDownloadRequest {
  const ArchiveDownloadRequest({
    required this.url,
    required this.fileName,
    required this.label,
    this.estimatedLength,
  });

  final Uri url;

  /// What the file is called on disk.
  final String fileName;

  /// What to call it in the interface, and what the feature stores as the
  /// archive's label once it is taken into use.
  final String label;

  /// Roughly how big, for the confirmation dialog and the progress bar.
  /// Catalogues round this up, so nothing is ever checked against it.
  final int? estimatedLength;
}

/// The one download in flight, if any.
///
/// One at a time on purpose: these files are measured in gigabytes, and
/// two of them at once means two that finish late instead of one that
/// finishes.
class ArchiveDownloadState {
  const ArchiveDownloadState({
    this.request,
    this.progress,
    this.error,
    this.finishedPath,
  });

  final ArchiveDownloadRequest? request;
  final DownloadProgress? progress;
  final Object? error;

  /// Set once the file is whole and in place.
  final String? finishedPath;

  bool get isRunning =>
      request != null && finishedPath == null && error == null;
}

class ArchiveDownloadController extends Notifier<ArchiveDownloadState> {
  StreamSubscription<DownloadProgress>? _subscription;

  @override
  ArchiveDownloadState build() {
    ref.onDispose(() => _subscription?.cancel());
    return const ArchiveDownloadState();
  }

  /// Fetches [request] and hands the finished file to [onFinished].
  ///
  /// The callback rather than a direct call into a feature's controller:
  /// a map and an encyclopedia are downloaded the same way and stored in
  /// different places, and this has no business knowing which.
  Future<void> start(
    ArchiveDownloadRequest request, {
    required Future<void> Function(String path, String label) onFinished,
  }) async {
    if (state.isRunning) return;

    state = ArchiveDownloadState(request: request);

    final folder = await const DownloadFolder().current();
    final target = '${folder.path}${Platform.pathSeparator}${request.fileName}';

    // A file that is already here is not worth fetching again. It only
    // got its final name after the downloader checked it against the
    // length the server stated, so its presence is the guarantee.
    final existing = File(target);
    if (await existing.exists()) {
      state = ArchiveDownloadState(request: request, finishedPath: target);
      await onFinished(target, request.label);
      return;
    }

    await _subscription?.cancel();
    _subscription = ArchiveDownloader()
        .download(
          url: request.url,
          targetPath: target,
          estimatedLength: request.estimatedLength,
        )
        .listen(
          (progress) => state = ArchiveDownloadState(
            request: request,
            progress: progress,
          ),
          onError: (Object error) {
            state = ArchiveDownloadState(request: request, error: error);
          },
          onDone: () async {
            // An error already ended this download; onDone still runs.
            if (state.error != null) return;
            state = ArchiveDownloadState(
              request: request,
              progress: state.progress,
              finishedPath: target,
            );
            await onFinished(target, request.label);
          },
        );
  }

  /// Stops the transfer. What has arrived stays on disk and the next
  /// attempt picks it up there.
  Future<void> cancel() async {
    await _subscription?.cancel();
    _subscription = null;
    state = const ArchiveDownloadState();
  }

  /// Clears a finished or failed download so the banner goes away.
  void dismiss() {
    if (state.isRunning) return;
    state = const ArchiveDownloadState();
  }
}

final archiveDownloadProvider =
    NotifierProvider<ArchiveDownloadController, ArchiveDownloadState>(
      ArchiveDownloadController.new,
    );

/// The folder downloads land in, for the settings screen to show.
final downloadFolderProvider = FutureProvider<Directory>(
  (ref) => const DownloadFolder().current(),
);
