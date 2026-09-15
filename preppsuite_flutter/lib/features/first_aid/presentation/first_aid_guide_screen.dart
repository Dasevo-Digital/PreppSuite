import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/adaptive_columns.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/first_aid_guides.dart';
import '../application/first_aid_providers.dart';
import '../application/first_aid_video_pack.dart';
import 'compression_pacer_screen.dart';
import 'first_aid_drawings.dart';
import 'first_aid_screen.dart' show EmergencyCallBar;
import 'first_aid_video_screen.dart';
import 'first_aid_videos_screen.dart';

/// One instruction, top to bottom.
///
/// The order on the page is the order somebody needs it in: the call, the
/// picture, the numbers worth having in front of you, then the steps.
/// The things not to do come after the steps and are visually separate —
/// mixed into the list, a "never" reads as a "do" to somebody skimming,
/// and skimming is what happens here.
class FirstAidGuideScreen extends ConsumerWidget {
  const FirstAidGuideScreen({super.key, required this.guideId});

  final String guideId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final guide = firstAidGuide(l10n.localeName, guideId);

    if (guide == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.firstAidTitle)),
        body: Center(child: Text(l10n.firstAidSearchEmpty)),
      );
    }

    final videos =
        ref.watch(installedFirstAidPackProvider).value?.forGuide(guide.id) ??
        const <FirstAidVideo>[];

    return Scaffold(
      appBar: AppBar(title: Text(guide.title)),
      body: Column(
        children: [
          const EmergencyCallBar(),
          Expanded(
            child: AdaptiveColumns(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              blocks: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guide.when, style: theme.textTheme.titleMedium),
                    if (guide.callFirst) ...[
                      const SizedBox(height: 12),
                      _CallFirstBanner(l10n: l10n),
                    ],
                    if (guide.drawing case final drawing?) ...[
                      const SizedBox(height: 16),
                      FirstAidDrawingView(drawing: drawing),
                    ],
                  ],
                ),
                if (guide.facts.isNotEmpty) _Facts(guide: guide, l10n: l10n),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.firstAidSteps, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    for (var i = 0; i < guide.steps.length; i++)
                      _StepTile(number: i + 1, step: guide.steps[i]),
                    if (guide.hasPacer) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CompressionPacerScreen(
                                // The child guide counts to fifteen.
                                compressionsPerCycle: guide.id == 'cpr-child'
                                    ? 15
                                    : 30,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.graphic_eq),
                          label: Text(l10n.firstAidOpenPacer),
                        ),
                      ),
                    ],
                  ],
                ),
                if (guide.cautions.isNotEmpty)
                  _Cautions(guide: guide, l10n: l10n),
                _Videos(guide: guide, videos: videos, l10n: l10n),
                Text(
                  l10n.firstAidSource(guide.source),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallFirstBanner extends StatelessWidget {
  const _CallFirstBanner({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.priority_high, color: scheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.firstAidCallFirst,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.number, required this.step});

  final int number;
  final FirstAidStep step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A fixed-width badge rather than a ListView's leading, so the
          // step text of every row starts on the same vertical line even
          // when a number goes from one digit to two.
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.text, style: theme.textTheme.titleMedium),
                if (step.detail case final detail?) ...[
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.guide, required this.l10n});

  final FirstAidGuide guide;
  final AppLocalizations l10n;

  /// A value that is only digits, spaces and the usual punctuation is a
  /// telephone number, and worth making tappable. Everything else — a
  /// depth, a rate — is just text.
  static final _dialable = RegExp(r'^[0-9][0-9 /+()-]{2,}$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            for (final fact in guide.facts)
              ListTile(
                dense: true,
                title: Text(fact.label),
                trailing: Text(
                  fact.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: _dialable.hasMatch(fact.value)
                    ? () => launchUrl(
                        Uri(
                          scheme: 'tel',
                          path: fact.value.replaceAll(RegExp(r'[^0-9+]'), ''),
                        ),
                      )
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _Cautions extends StatelessWidget {
  const _Cautions({required this.guide, required this.l10n});

  final FirstAidGuide guide;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.firstAidCautions, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        for (final caution in guide.cautions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.do_not_disturb_on_outlined, color: scheme.error),
                const SizedBox(width: 12),
                Expanded(child: Text(caution)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Videos extends StatelessWidget {
  const _Videos({
    required this.guide,
    required this.videos,
    required this.l10n,
  });

  final FirstAidGuide guide;
  final List<FirstAidVideo> videos;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.firstAidVideos, style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (videos.isEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.video_library_outlined),
            title: Text(l10n.firstAidVideosNone),
            subtitle: Text(l10n.firstAidVideoManage),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FirstAidVideosScreen(),
              ),
            ),
          )
        else
          for (final video in videos)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: Text(video.title),
                subtitle: Text(
                  [
                    if (video.credit.isNotEmpty) video.credit,
                    if (video.licence.isNotEmpty) video.licence,
                  ].join(' · '),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FirstAidVideoScreen(video: video),
                  ),
                ),
              ),
            ),
      ],
    );
  }
}
