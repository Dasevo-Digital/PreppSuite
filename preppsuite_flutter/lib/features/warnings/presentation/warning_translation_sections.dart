import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show Bidi;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/warning_translations.dart';

/// What the app calls [warning] in its own language (#357).
String warningTitle(Warning warning, AppLocalizations l10n) =>
    warning.titleIn(l10n.localeName, allClear: l10n.warningAllClearTitle);

/// The name of [language] as a reader looks for it: in itself, and
/// Leichte Sprache in the app's words.
String warningLanguageName(AppLocalizations l10n, String language) =>
    language == 'de-ls'
    ? l10n.warningEasyGerman
    : warningLanguageEndonyms[language] ?? language;

/// The app's own words in [language], where it has them: German for
/// Leichte Sprache, null for a language the app does not speak.
AppLocalizations? warningLocalizationsFor(String language) {
  final code = language == 'de-ls' ? 'de' : language.split('-').first;
  final spoken = AppLocalizations.supportedLocales.any(
    (locale) => locale.languageCode == code,
  );
  return spoken ? lookupAppLocalizations(Locale(code)) : null;
}

/// The line above a message that ends its warning (#367).
///
/// Some publishers leave the old instructions in an all-clear: Husum's,
/// on 11 November 2026, still said to avoid the area and close the
/// windows. Under the German headline "Entwarnung" says so; under a
/// translation, nothing did.
class WarningAllClearNote extends StatelessWidget {
  const WarningAllClearNote({super.key, required this.words});

  final AppLocalizations words;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.task_alt, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            words.warningAllClearNote,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// A warning's words in one more language, under a heading that says
/// which and that it is the official one (#357).
///
/// [allClear] adds the note that the message ends the warning, in that
/// language, where the app speaks it (English, Spanish). For the others
/// there is no official word and the app does not make one up; the note in
/// the app's own language stands above the section.
class WarningTranslationSection extends StatelessWidget {
  const WarningTranslationSection({
    super.key,
    required this.language,
    required this.text,
    required this.l10n,
    this.allClear = false,
  });

  final String language;
  final WarningTranslation text;
  final AppLocalizations l10n;
  final bool allClear;

  /// The note in this section's language, where the app speaks it and it
  /// is not the app's own: that one stands above already.
  AppLocalizations? get _ownWords {
    final words = warningLocalizationsFor(language);
    return words == null || words.localeName == l10n.localeName ? null : words;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = text.heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.translate, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.warningOfficialTranslation(
                  warningLanguageName(l10n, language),
                ),
                style: theme.textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if ((allClear ? _ownWords : null) case final words?) ...[
          WarningAllClearNote(words: words),
          const SizedBox(height: 6),
        ],
        // Arabic runs right to left, whatever the app's own direction.
        Directionality(
          textDirection: isRightToLeft(language)
              ? TextDirection.rtl
              : TextDirection.ltr,
          // Only what this language says: what it left German is above.
          child: WarningTextBody(
            headline: heading,
            description: text.description,
            instruction: text.instruction,
          ),
        ),
      ],
    );
  }
}

/// The German as the BBK sent it, folded away beneath a translation: it is
/// the text that counts, and what to show somebody who asks.
class WarningGermanOriginal extends StatelessWidget {
  const WarningGermanOriginal({
    super.key,
    required this.text,
    required this.l10n,
  });

  final WarningText text;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 12),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    leading: const Icon(Icons.article_outlined),
    title: Text(l10n.warningGermanOriginal),
    children: [
      WarningTextBody(
        headline: text.headline,
        description: text.description,
        instruction: text.instruction,
      ),
    ],
  );
}

/// Headline, description and what to do.
///
/// Each part runs in its own direction. A paragraph in German or with a
/// place name inside the Arabic would otherwise be laid out right to left,
/// and its full stop stood at its start.
class WarningTextBody extends StatelessWidget {
  const WarningTextBody({
    super.key,
    this.headline,
    this.description,
    this.instruction,
  });

  final String? headline;
  final String? description;
  final String? instruction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = [
      if (headline case final text?) (text, theme.textTheme.titleMedium),
      if (description case final text?) (text, theme.textTheme.bodyLarge),
      if (instruction case final text?) (text, theme.textTheme.bodyLarge),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        for (final (text, style) in parts)
          Text(text, style: style, textDirection: warningTextDirection(text)),
      ],
    );
  }
}

/// The direction [text] is written in, by its words rather than the
/// screen's.
TextDirection warningTextDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;
