import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../knowledge/application/article_viewer_choice.dart';

/// Where an article opens, on the two platforms that have a choice.
///
/// Linux and Windows reach no embedded engine, so an article has always
/// gone into a window of the system's own. That window shows more of the
/// article and it is still the default — but it is a second window on the
/// taskbar, it needs a component the system may not have, and it ignores
/// the app's own text size. The reader the app draws itself has the
/// opposite trade, and which of the two is wanted is not something this
/// app can work out.
///
/// Shown on no other platform: everywhere else the embedded panel is both
/// the best option and the only one, and a choice between one thing is
/// not a choice.
class ArticleViewerCard extends StatefulWidget {
  const ArticleViewerCard({
    super.key,
    required this.l10n,
    this.store = const ArticleViewerChoiceStore(),
  });

  final AppLocalizations l10n;
  final ArticleViewerChoiceStore store;

  @override
  State<ArticleViewerCard> createState() => _ArticleViewerCardState();
}

class _ArticleViewerCardState extends State<ArticleViewerCard> {
  ArticleViewerChoice? _choice;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final choice = await widget.store.load();
    if (mounted) setState(() => _choice = choice);
  }

  Future<void> _choose(ArticleViewerChoice choice) async {
    setState(() => _choice = choice);
    await widget.store.save(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final choice = _choice;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.articleViewerChoiceWhy),
            const SizedBox(height: 8),
            if (choice == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              // A radio list rather than the segmented button the theme
              // picker uses: each option needs its reason beside it, and
              // a segment has room for two words.
              RadioGroup<ArticleViewerChoice>(
                groupValue: choice,
                onChanged: (picked) {
                  if (picked != null) _choose(picked);
                },
                child: Column(
                  children: [
                    RadioListTile<ArticleViewerChoice>(
                      value: ArticleViewerChoice.systemWindow,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.articleViewerChoiceWindow),
                      subtitle: Text(l10n.articleViewerChoiceWindowWhy),
                      isThreeLine: true,
                    ),
                    RadioListTile<ArticleViewerChoice>(
                      value: ArticleViewerChoice.builtIn,
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.articleViewerChoiceBuiltIn),
                      subtitle: Text(l10n.articleViewerChoiceBuiltInWhy),
                      isThreeLine: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // So that nobody reads the choice as "and otherwise
              // nothing": the fallback holds either way, and that is the
              // whole reason the built-in reader exists.
              Text(
                l10n.articleViewerChoiceFallbackNote,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
