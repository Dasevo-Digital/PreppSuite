import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/first_aid_guides.dart';
import 'first_aid_guide_screen.dart';
import 'first_aid_videos_screen.dart';
import 'knowledge_check_screen.dart';
import '../../../core/phone_call.dart';

/// The list of instructions.
///
/// Reachable without a download, without a network and without any
/// setting having been made — that is the whole reason this is its own
/// feature and not a corner of the knowledge section. The knowledge
/// section is an encyclopedia behind a multi-gigabyte archive; somebody
/// kneeling beside a casualty has not downloaded it.
///
/// Sorted by urgency rather than alphabetically, and the emergency number
/// sits above the list, always, on every one of these screens.
class FirstAidScreen extends ConsumerStatefulWidget {
  const FirstAidScreen({super.key});

  @override
  ConsumerState<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends ConsumerState<FirstAidScreen> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final matches = searchFirstAidGuides(l10n.localeName, _query);
    final searching = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.firstAidTitle),
        actions: [
          IconButton(
            tooltip: l10n.firstAidVideoPackTitle,
            icon: const Icon(Icons.video_library_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const FirstAidVideosScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const EmergencyCallBar(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.firstAidSearchHint,
                border: const OutlineInputBorder(),
                suffixIcon: searching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.firstAidSearchEmpty,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      if (searching)
                        for (final guide in matches) _GuideTile(guide: guide)
                      else ...[
                        // Above the guides, because reading one again is
                        // not how anybody finds out what they have
                        // forgotten.
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.quiz_outlined),
                            title: Text(l10n.knowledgeCheckTitle),
                            subtitle: Text(l10n.knowledgeCheckIntro),
                            trailing: const Icon(Icons.chevron_right),
                            isThreeLine: true,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const KnowledgeCheckScreen(),
                              ),
                            ),
                          ),
                        ),
                        for (final group in FirstAidGroup.values) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                            child: Text(
                              _groupName(l10n, group),
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          for (final guide in matches)
                            if (guide.group == group) _GuideTile(guide: guide),
                        ],
                      ],
                      const SizedBox(height: 16),
                      Text(
                        l10n.firstAidDisclaimer,
                        style: theme.textTheme.bodySmall,
                      ),
                      // At the foot, not at the head. It is a note about
                      // where these texts come from and when they were
                      // last checked against the guidelines -- worth
                      // saying, and worth nothing at all to somebody who
                      // opened this screen because there is a person on
                      // the floor. Its one action opens a website, which
                      // is the one thing that will not work on the day it
                      // matters. The same note is in Settings under the
                      // versions, which is where somebody goes to ask it.
                      if (!searching)
                        Card(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: ListTile(
                            leading: const Icon(Icons.fact_check_outlined),
                            title: Text(l10n.firstAidContentVersionTitle),
                            subtitle: Text(l10n.firstAidContentVersionBody),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => launchUrl(
                              Uri.parse(
                                'https://www.erc.edu/science-research/'
                                'guidelines/guidelines-2025/'
                                'guidelines-2025-english',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _groupName(AppLocalizations l10n, FirstAidGroup group) {
    return switch (group) {
      FirstAidGroup.basics => l10n.firstAidGroupBasics,
      FirstAidGroup.lifeThreatening => l10n.firstAidGroupLifeThreatening,
      FirstAidGroup.injury => l10n.firstAidGroupInjury,
      FirstAidGroup.illness => l10n.firstAidGroupIllness,
      FirstAidGroup.environment => l10n.firstAidGroupEnvironment,
      FirstAidGroup.mentalDistress => l10n.firstAidGroupMental,
    };
  }
}

/// The 112 button that sits at the top of every first aid screen.
///
/// Repeated on each of them on purpose. Somebody three screens deep
/// reading about anaphylaxis must not have to find their way back out to
/// make the call.
class EmergencyCallBar extends StatelessWidget {
  const EmergencyCallBar({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: () => callNumber(context, '112'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.call, color: scheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.firstAidCallNow,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({required this.guide});

  final FirstAidGuide guide;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          guide.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(guide.when),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FirstAidGuideScreen(guideId: guide.id),
          ),
        ),
      ),
    );
  }
}
