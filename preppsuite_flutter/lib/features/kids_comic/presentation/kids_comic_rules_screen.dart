import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/kids_comic.dart';
import 'kids_comic_parts.dart';

/// Every chapter's rules on one sheet, and the two numbers.
class KidsComicRulesScreen extends StatelessWidget {
  const KidsComicRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comic = kidsComic(l10n.localeName);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comicRulesTitle)),
      body: ComicReadable(
        children: [
          Text(l10n.comicNumbersTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final entry in comic.numbers)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SelectableText(
                          entry.number,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            entry.label,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final chapter in comic.chapters)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.rulesTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    for (final rule in chapter.rules)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 20,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rule)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
