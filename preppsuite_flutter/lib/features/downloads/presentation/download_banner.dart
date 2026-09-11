import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/progress_text.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/byte_size.dart';
import '../application/download_providers.dart';
import '../application/download_rate.dart';

/// The state of the one download in flight, wherever the user happens to
/// be looking.
///
/// A download of tens of gigabytes outlives the screen it was started
/// from, so this is shown by both the map and the encyclopedia rather
/// than living on the page that began it.
class DownloadBanner extends ConsumerWidget {
  const DownloadBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final state = ref.watch(archiveDownloadProvider);

    final request = state.request;
    if (request == null) return const SizedBox.shrink();

    if (state.error != null) {
      return _Frame(
        announce: true,
        colour: theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.downloadFailedLabel(state.error.toString()),
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(archiveDownloadProvider.notifier).dismiss(),
              child: Text(l10n.downloadDismissAction),
            ),
          ],
        ),
      );
    }

    if (state.finishedPath != null) {
      // Three states, not two: still opening, open, and downloaded but
      // refused. The last one used to read like the second.
      final problem = state.takeUpProblem;
      return _Frame(
        announce: true,
        colour: problem == null
            ? theme.colorScheme.secondaryContainer
            : theme.colorScheme.errorContainer,
        child: Row(
          children: [
            Expanded(
              child: Text(
                problem == null
                    ? l10n.downloadFinishedLabel(request.label)
                    : l10n.downloadNotOpenedLabel(request.label, problem),
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(archiveDownloadProvider.notifier).dismiss(),
              child: Text(l10n.downloadDismissAction),
            ),
          ],
        ),
      );
    }

    final progress = state.progress;
    final fraction = progress?.fraction;

    // What is worth knowing while a 52 GB archive comes down, in the
    // order somebody wants it: how far along, how fast, and when it will
    // be usable. The size pair alone answered only the first, and
    // answered it in arithmetic.
    final details = <String>[
      // First, because while this is true the rest is about a transfer
      // that is not currently moving.
      if (progress?.resuming ?? false) l10n.downloadResumingLabel,
      if (fraction != null) l10n.progressPercent((fraction * 100).round()),
      if (progress != null && progress.total != null)
        l10n.downloadOfSize(
          formatByteSize(progress.received),
          formatByteSize(progress.total!),
        ),
      if (!(progress?.resuming ?? false)) ...[
        ?state.rate?.formatted,
        ?_remaining(l10n, state.rate?.remaining),
      ],
    ];

    return _Frame(
      colour: theme.colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.downloadRunningLabel(request.label),
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(archiveDownloadProvider.notifier).cancel(),
                child: Text(l10n.downloadCancelAction),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // A determinate bar needs a total, and a mirror behind a
          // redirect does not always give one.
          LinearProgressIndicator(
            value: fraction,
            semanticsValue: percentValue(l10n, fraction),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(details.join(' · '), style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.colour,
    required this.child,
    this.announce = false,
  });

  final Color colour;
  final Widget child;

  /// Read out as soon as it appears, without the user going to look.
  ///
  /// Only for the two frames that end a download. The running frame is
  /// rebuilt on every chunk, and a live region on that would talk over
  /// everything else for as long as the download lasts — which for a
  /// 52 GB archive is most of an afternoon.
  final bool announce;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: announce,
      container: announce,
      child: Container(
        width: double.infinity,
        color: colour,
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: child,
      ),
    );
  }
}

/// A remaining time in the unit the wait is actually felt in.
///
/// Nobody waiting on a 52 GB archive needs seconds, and nobody waiting
/// on its last minute needs hours.
String? _remaining(AppLocalizations l10n, Duration? remaining) {
  if (remaining == null) return null;

  final parts = splitRemaining(remaining);
  if (parts.hours != null) {
    return l10n.downloadRemainingHours(parts.hours!, parts.minutes!);
  }
  if (parts.minutes != null) {
    return l10n.downloadRemainingMinutes(parts.minutes!);
  }
  return l10n.downloadRemainingSeconds(parts.seconds!);
}
