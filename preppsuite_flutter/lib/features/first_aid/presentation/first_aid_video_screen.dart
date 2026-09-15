import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/first_aid_providers.dart';
import '../application/first_aid_video_pack.dart';

/// Whether this platform can play a clip inside the app.
///
/// `video_player` reaches Android, iOS and macOS. Linux and Windows have
/// no implementation, and the file goes to the system's own player there
/// instead — the same split the article reader makes between an embedded
/// WebView and a window of its own, and for the same reason: bundling a
/// second media stack to avoid it would cost more than the feature is
/// worth.
bool get playsVideoInApp {
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) return true;
  return false;
}

/// Whether handing the file to the system is worth offering.
bool get _opensInSystemPlayer =>
    Platform.isMacOS || Platform.isLinux || Platform.isWindows;

/// One clip out of a downloaded pack.
class FirstAidVideoScreen extends ConsumerStatefulWidget {
  const FirstAidVideoScreen({super.key, required this.video});

  final FirstAidVideo video;

  @override
  ConsumerState<FirstAidVideoScreen> createState() =>
      _FirstAidVideoScreenState();
}

class _FirstAidVideoScreenState extends ConsumerState<FirstAidVideoScreen> {
  VideoPlayerController? _controller;
  Object? _error;
  File? _file;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void dispose() {
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _open() async {
    try {
      final library = await ref.read(firstAidLibraryProvider.future);
      final file = library.fileFor(widget.video);
      if (!await file.exists()) {
        throw const FileSystemException('missing');
      }
      if (!mounted) return;
      setState(() => _file = file);
      if (!playsVideoInApp) return;

      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
      await controller.play();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final controller = _controller;
    final file = _file;

    return Scaffold(
      appBar: AppBar(title: Text(widget.video.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          if (_error != null)
            Text(l10n.firstAidVideoMissing, style: theme.textTheme.titleMedium)
          else if (controller != null)
            Column(
              children: [
                AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: VideoPlayer(controller),
                ),
                VideoProgressIndicator(controller, allowScrubbing: true),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      iconSize: 32,
                      onPressed: () => setState(
                        () => controller.value.isPlaying
                            ? controller.pause()
                            : controller.play(),
                      ),
                      icon: Icon(
                        controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton.filledTonal(
                      iconSize: 32,
                      tooltip: l10n.firstAidVideoRestart,
                      onPressed: () async {
                        await controller.seekTo(Duration.zero);
                        await controller.play();
                        if (mounted) setState(() {});
                      },
                      icon: const Icon(Icons.replay),
                    ),
                  ],
                ),
              ],
            )
          else if (file != null && !playsVideoInApp)
            // Nothing is drawn here on Linux and Windows: the button
            // below is the whole screen, and a black rectangle that will
            // never show a picture would only look broken.
            Text(l10n.firstAidVideoSystemPlayer)
          else
            const Center(child: CircularProgressIndicator()),
          // Desktop only. A file:// URL is what a desktop hands to its
          // own player, and what Android refuses outright -- it wants a
          // content:// URI through a FileProvider, and there is nothing
          // to gain by building one when the clip already plays in the
          // page above.
          if (file != null && _opensInSystemPlayer) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => launchUrl(file.uri),
              icon: const Icon(Icons.open_in_new),
              label: Text(l10n.firstAidVideoOpenExternal),
            ),
          ],
          const SizedBox(height: 24),
          // The credit and the licence are shown, not buried: most free
          // licences require attribution, and a viewer judges what they
          // are watching by who made it.
          if (widget.video.credit.isNotEmpty)
            Text(widget.video.credit, style: theme.textTheme.bodySmall),
          if (widget.video.licence.isNotEmpty)
            Text(widget.video.licence, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(l10n.firstAidVideoNotACourse, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
