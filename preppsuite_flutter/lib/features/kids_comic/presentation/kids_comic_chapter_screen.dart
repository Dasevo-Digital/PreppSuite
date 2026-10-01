import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/kids_comic.dart';
import 'kids_comic_parts.dart';
import 'kids_comic_rules_screen.dart';

/// One chapter, panel after panel, and the way on to the next.
class KidsComicChapterScreen extends StatelessWidget {
  const KidsComicChapterScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comic = kidsComic(l10n.localeName);
    final chapter = comic.chapters[index];
    final next = index + 1 < comic.chapters.length
        ? comic.chapters[index + 1]
        : null;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comicChapterNumber(index + 1))),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Two panels to a row once there is room for two, which is how
          // a comic is read: across, then down. AdaptiveColumns deals its
          // blocks into columns, which would have the story run down the
          // left half first.
          final twoUp = constraints.maxWidth >= 860;
          final rows = <List<ComicPanel>>[];
          for (final panel in chapter.panels) {
            if (!twoUp || panel.wide) {
              rows.add([panel]);
            } else if (rows.isNotEmpty &&
                rows.last.length == 1 &&
                !rows.last.single.wide) {
              rows.last.add(panel);
            } else {
              rows.add([panel]);
            }
          }

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: twoUp ? 1100 : 640),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    chapter.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Text(
                        chapter.lede,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: row.length == 1
                          ? ComicPanelView(
                              panel: row.single,
                              speakers: comic.speakers,
                            )
                          : IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  for (final (i, panel) in row.indexed) ...[
                                    if (i > 0) const SizedBox(width: 16),
                                    Expanded(
                                      child: ComicPanelView(
                                        panel: panel,
                                        speakers: comic.speakers,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                    ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => next == null
                              ? const KidsComicRulesScreen()
                              : KidsComicChapterScreen(index: index + 1),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(
                        l10n.comicNext(next?.title ?? l10n.comicRulesTitle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
