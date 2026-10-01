import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/kids_comic.dart';
import 'kids_comic_chapter_screen.dart';
import 'kids_comic_parts.dart';
import 'kids_comic_rules_screen.dart';

/// The comic's cover and its table of contents.
///
/// Everything here is bundled with the app: no network, no download, no
/// setting. It is meant for the evening a child asks what a siren means,
/// which is not an evening to find out that the content needs a
/// connection.
class KidsComicScreen extends StatelessWidget {
  const KidsComicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comic = kidsComic(l10n.localeName);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(comic.title)),
      body: ComicReadable(
        children: [
          ComicPicture(
            asset: kidsComicAsset(kidsComicCover),
            description: comic.coverDescription,
            aspectRatio: 300 / 220,
          ),
          const SizedBox(height: 16),
          Text(comic.subtitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(comic.intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 16),
          for (final (index, chapter) in comic.chapters.indexed)
            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(chapter.title),
                subtitle: Text(chapter.lede),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => KidsComicChapterScreen(index: index),
                  ),
                ),
              ),
            ),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.checklist)),
              title: Text(l10n.comicRulesTitle),
              subtitle: Text(l10n.comicRulesHint),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const KidsComicRulesScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(l10n.comicParentsTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(comic.parentsIntro),
          const SizedBox(height: 8),
          for (final tip in comic.parentsTips)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2, right: 8),
                    child: Icon(Icons.circle, size: 8),
                  ),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(comic.source, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
