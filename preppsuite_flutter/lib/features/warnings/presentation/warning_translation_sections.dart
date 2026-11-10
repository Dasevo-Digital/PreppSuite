import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/warning_translations.dart';

/// The name of [language] as a reader looks for it: in itself, and
/// Leichte Sprache in the app's words.
String warningLanguageName(AppLocalizations l10n, String language) =>
    language == 'de-ls'
    ? l10n.warningEasyGerman
    : warningLanguageEndonyms[language] ?? language;

/// A warning's words in one more language, under a heading that says
/// which and that it is the official one (#357).
class WarningTranslationSection extends StatelessWidget {
  const WarningTranslationSection({
    super.key,
    required this.language,
    required this.text,
    required this.l10n,
  });

  final String language;
  final WarningText text;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        // Arabic runs right to left, whatever the app's own direction.
        Directionality(
          textDirection: isRightToLeft(language)
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: WarningTextBody(text: text),
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
    children: [WarningTextBody(text: text)],
  );
}

/// Headline, description and what to do.
class WarningTextBody extends StatelessWidget {
  const WarningTextBody({super.key, required this.text});

  final WarningText text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text.headline, style: theme.textTheme.titleMedium),
        if (text.description case final description?) ...[
          const SizedBox(height: 6),
          Text(description, style: theme.textTheme.bodyLarge),
        ],
        if (text.instruction case final instruction?) ...[
          const SizedBox(height: 6),
          Text(instruction, style: theme.textTheme.bodyLarge),
        ],
      ],
    );
  }
}
