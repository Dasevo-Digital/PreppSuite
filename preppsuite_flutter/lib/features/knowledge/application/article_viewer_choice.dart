import 'package:shared_preferences/shared_preferences.dart';

import 'article_viewer.dart';

/// How the reader wants articles shown, where there is a choice.
///
/// There is one on Linux and Windows and nowhere else: those two open the
/// article in a window of the operating system's own, and some people
/// would rather stay inside the app. Everywhere else the embedded panel
/// is both the best and the only option, and offering a choice would be
/// offering a worse one.
enum ArticleViewerChoice {
  /// The system's engine in a window of its own — what the app has always
  /// done, and what a full browser buys: scripts, typeset formulas, the
  /// article's own layout.
  systemWindow,

  /// Drawn by the app. Less of the article, but inside the app, with its
  /// text size and its colours, and without a second window on the
  /// taskbar.
  builtIn,
}

/// Whether this platform has anything to choose between.
bool get offersArticleViewerChoice => articleViewer == ArticleViewer.window;

/// Remembers the choice.
class ArticleViewerChoiceStore {
  const ArticleViewerChoiceStore();

  static const _key = 'articleViewerChoice';

  /// The window by default, because it shows more of the article. The
  /// built-in reader stays what it was built as — a fallback — and
  /// becomes a preference only for somebody who says so.
  Future<ArticleViewerChoice> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_key);
    for (final choice in ArticleViewerChoice.values) {
      if (choice.name == stored) return choice;
    }
    return ArticleViewerChoice.systemWindow;
  }

  Future<void> save(ArticleViewerChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, choice.name);
  }
}
