import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/phrasebook.dart';

/// The phrasebook (#181): pick the other person's language, find the
/// sentence, and hold it up.
///
/// Each sentence shows the app's language small above the other language
/// large, because the large line is the one that is shown and the small
/// one is how the person holding the phone knows what they are showing.
class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  final _search = TextEditingController();
  PhraseLanguage? _target;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final from = PhraseLanguage.forLocale(l10n.localeName);
    // English for a German reader and German for everyone else: the one a
    // helper here most likely shares with somebody.
    final to =
        _target ??
        (from == PhraseLanguage.de ? PhraseLanguage.en : PhraseLanguage.de);
    final query = _search.text;
    final found = searchPhrases(query, from: from, to: to);

    Widget card(Phrase phrase) => _PhraseCard(
      source: phrase[from],
      target: phrase[to],
      targetRtl: to.isRtl,
      onShow: () => _show(context, phrase[to], phrase[from], to.isRtl),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.phrasebookTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<PhraseLanguage>(
            isExpanded: true,
            initialValue: to,
            decoration: InputDecoration(
              labelText: l10n.phrasebookTarget,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final language in PhraseLanguage.values)
                if (language != from)
                  DropdownMenuItem(
                    value: language,
                    child: Text(language.endonym),
                  ),
            ],
            onChanged: (language) => setState(() => _target = language),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: l10n.phrasebookSearch,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          if (!reviewedPhraseLanguages.contains(to)) ...[
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: theme.colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.phrasebookUnreviewed,
                        style: TextStyle(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (query.trim().isNotEmpty) ...[
            if (found.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.phrasebookNoMatch,
                  textAlign: TextAlign.center,
                ),
              ),
            for (final phrase in found) card(phrase),
          ] else
            for (final group in PhraseGroup.values) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                child: Text(
                  _groupTitle(l10n, group),
                  style: theme.textTheme.titleMedium,
                ),
              ),
              for (final phrase in phrasesIn(group)) card(phrase),
            ],
        ],
      ),
    );
  }

  /// The sentence alone, as large as the screen allows, to be held up.
  Future<void> _show(
    BuildContext context,
    String target,
    String source,
    bool rtl,
  ) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      target,
                      textAlign: TextAlign.center,
                      textDirection: rtl ? TextDirection.rtl : null,
                      style: theme.textTheme.displaySmall,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      source,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _groupTitle(AppLocalizations l10n, PhraseGroup group) =>
      switch (group) {
        PhraseGroup.basics => l10n.phrasebookGroupBasics,
        PhraseGroup.emergency => l10n.phrasebookGroupEmergency,
        PhraseGroup.health => l10n.phrasebookGroupHealth,
        PhraseGroup.shelter => l10n.phrasebookGroupShelter,
        PhraseGroup.people => l10n.phrasebookGroupPeople,
        PhraseGroup.answers => l10n.phrasebookGroupAnswers,
      };
}

class _PhraseCard extends StatelessWidget {
  const _PhraseCard({
    required this.source,
    required this.target,
    required this.targetRtl,
    required this.onShow,
  });

  final String source;
  final String target;
  final bool targetRtl;
  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onShow,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      source,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Right to left where the language is: Arabic and
                    // Persian set left-aligned read as broken.
                    Text(
                      target,
                      textDirection: targetRtl
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      style: theme.textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: l10n.phrasebookShow,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.open_in_full),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
