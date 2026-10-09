import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../downloads/application/archive_downloader.dart';
import '../../downloads/application/download_folder.dart';
import 'first_aid_video_pack.dart';
import '../../../core/http_client.dart';

/// Where the video pack folder is on this device.
final firstAidLibraryProvider = FutureProvider<FirstAidVideoLibrary>((
  ref,
) async {
  final downloads = await const DownloadFolder().current();
  return FirstAidVideoLibrary(FirstAidVideoLibrary.inside(downloads));
});

/// What is installed: the manifest, and which of its files actually
/// arrived.
class InstalledFirstAidPack {
  const InstalledFirstAidPack({
    required this.pack,
    required this.present,
    required this.bytesOnDisk,
  });

  /// Null when no pack has been installed at all.
  final FirstAidVideoPack? pack;

  /// The ids of the videos whose files are on the disk.
  final Set<String> present;

  final int bytesOnDisk;

  bool has(FirstAidVideo video) => present.contains(video.id);

  /// The installed videos for one guide — what the guide screen offers.
  List<FirstAidVideo> forGuide(String guideId) => [
    for (final video in pack?.forGuide(guideId) ?? const <FirstAidVideo>[])
      if (has(video)) video,
  ];

  static const none = InstalledFirstAidPack(
    pack: null,
    present: {},
    bytesOnDisk: 0,
  );
}

final installedFirstAidPackProvider = FutureProvider<InstalledFirstAidPack>((
  ref,
) async {
  final library = await ref.watch(firstAidLibraryProvider.future);
  final pack = await library.installed();
  if (pack == null) return InstalledFirstAidPack.none;
  final present = await library.present(pack);
  return InstalledFirstAidPack(
    pack: pack,
    present: {for (final video in present) video.id},
    bytesOnDisk: await library.bytesOnDisk(),
  );
});

/// The address a pack description is fetched from.
///
/// Empty by default, and deliberately so. Hard-coding an address the
/// project has not published yet would put a 404 in front of every
/// household and make a working feature look broken. The screen explains
/// both ways in; the one that needs no address — a zip from a memory
/// stick — is the one that works in the situation this app is for.
class FirstAidPackUrlStore {
  const FirstAidPackUrlStore();

  static const _key = 'firstAidPackUrl';

  Future<String> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? '';
  }

  Future<void> write(String url) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_key);
    } else {
      await prefs.setString(_key, trimmed);
    }
  }
}

final firstAidPackUrlProvider = FutureProvider<String>(
  (ref) => const FirstAidPackUrlStore().read(),
);

/// How far the pack download has got.
class FirstAidDownloadState {
  const FirstAidDownloadState({
    this.current,
    this.progress,
    this.done = 0,
    this.total = 0,
    this.problems = const [],
    this.finished = false,
  });

  /// The clip being fetched right now.
  final FirstAidVideo? current;
  final DownloadProgress? progress;

  /// How many of [total] are through.
  final int done;
  final int total;

  /// One sentence per clip that did not make it. The rest of the pack is
  /// installed anyway — a household that gets eight of ten videos is
  /// better off than one that gets none because one mirror was down.
  final List<String> problems;

  final bool finished;

  bool get isRunning => total > 0 && !finished;

  static const idle = FirstAidDownloadState();
}

/// Fetches a pack, one clip after another.
///
/// Sequential on purpose. These are the same kind of files the archive
/// downloader was written for, only smaller, and four at once on a phone
/// tethered to a hotspot means four that finish late instead of one that
/// finishes.
class FirstAidDownloadController extends Notifier<FirstAidDownloadState> {
  StreamSubscription<DownloadProgress>? _subscription;
  var _cancelled = false;

  @override
  FirstAidDownloadState build() {
    ref.onDispose(() => _subscription?.cancel());
    return FirstAidDownloadState.idle;
  }

  /// Reads a manifest from [url].
  ///
  /// Throws [FormatException] with a readable sentence, which is what the
  /// screen shows. A captive portal answering with its own login page is
  /// the ordinary case here, not an exotic one.
  Future<FirstAidVideoPack> fetchManifest(
    Uri url, {
    http.Client? client,
  }) async {
    final http.Response response;
    final own = client == null;
    final httpClient = client ?? TimeoutClient();
    try {
      response = await httpClient.get(url);
    } on Object {
      throw const FormatException('The address could not be reached.');
    } finally {
      if (own) httpClient.close();
    }
    if (response.statusCode != 200) {
      throw FormatException(
        'The server answered ${response.statusCode}.',
      );
    }
    return FirstAidVideoPack.parse(response.body, from: url);
  }

  /// Downloads [videos] of [pack] into the library.
  ///
  /// The manifest is written first. A pack whose files are still arriving
  /// is a pack all the same, and writing the manifest last would mean a
  /// download interrupted at 90 % left nothing behind at all.
  Future<void> install(
    FirstAidVideoPack pack,
    List<FirstAidVideo> videos,
  ) async {
    if (state.isRunning || videos.isEmpty) return;
    _cancelled = false;

    final library = await ref.read(firstAidLibraryProvider.future);
    await library.writeManifest(pack);

    state = FirstAidDownloadState(total: videos.length);

    final problems = <String>[];
    var done = 0;

    for (final video in videos) {
      if (_cancelled) break;

      final url = pack.resolve(video);
      if (url == null) {
        problems.add('${video.title}: the pack gives no address.');
        continue;
      }

      state = FirstAidDownloadState(
        current: video,
        done: done,
        total: videos.length,
        problems: problems,
      );

      try {
        await _fetch(url, library.fileFor(video).path, video);
        final problem = await library.verify(video);
        if (problem != null) {
          problems.add('${video.title}: $problem');
        } else {
          done++;
        }
      } on Object catch (error) {
        problems.add('${video.title}: $error');
      }
    }

    state = FirstAidDownloadState(
      done: done,
      total: videos.length,
      problems: problems,
      finished: true,
    );
    ref.invalidate(installedFirstAidPackProvider);
  }

  Future<void> _fetch(Uri url, String target, FirstAidVideo video) {
    final completer = Completer<void>();
    _subscription?.cancel();
    _subscription = ArchiveDownloader()
        .download(
          url: url,
          targetPath: target,
          estimatedLength: video.bytes,
        )
        .listen(
          (progress) {
            state = FirstAidDownloadState(
              current: video,
              progress: progress,
              done: state.done,
              total: state.total,
              problems: state.problems,
            );
          },
          onError: completer.completeError,
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: true,
        );
    return completer.future;
  }

  /// Stops after the clip in flight. What has arrived stays.
  Future<void> cancel() async {
    _cancelled = true;
    await _subscription?.cancel();
    _subscription = null;
    state = FirstAidDownloadState(
      done: state.done,
      total: state.total,
      problems: state.problems,
      finished: true,
    );
    ref.invalidate(installedFirstAidPackProvider);
  }

  void dismiss() {
    if (state.isRunning) return;
    state = FirstAidDownloadState.idle;
  }
}

final firstAidDownloadProvider =
    NotifierProvider<FirstAidDownloadController, FirstAidDownloadState>(
      FirstAidDownloadController.new,
    );
