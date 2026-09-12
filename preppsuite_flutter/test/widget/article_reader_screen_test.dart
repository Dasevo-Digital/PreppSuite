import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/knowledge/presentation/article_reader_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import '../features/fixture_http_client.dart';
import 'accessibility.dart';

/// The loopback server in front of the open archive, standing in.
///
/// Keyed by the whole address, the way the archive's own server answers.
http.Client serving(Map<String, String> pages) => FixtureHttpClient({
  for (final page in pages.entries)
    'http://127.0.0.1:8080${page.key}': page.value,
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final uri = Uri.parse('http://127.0.0.1:8080/A/Trinkwasser');

  Future<void> show(
    WidgetTester tester, {
    required http.Client client,
    Uri? at,
  }) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ArticleReaderScreen(
          title: 'Trinkwasser',
          uri: at ?? uri,
          client: client,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an article is readable without any engine', (tester) async {
    await show(
      tester,
      client: serving({
        '/A/Trinkwasser':
            '<html><head><title>Trinkwasser</title></head><body>'
            '<h2>Gewinnung</h2>'
            '<p>Trinkwasser wird aus Grundwasser gewonnen.</p>'
            '<ul><li>Brunnen</li><li>Quellen</li></ul>'
            '</body></html>',
      }),
    );

    expect(find.text('Gewinnung'), findsOneWidget);
    expect(
      find.textContaining('Trinkwasser wird aus Grundwasser'),
      findsOneWidget,
    );
    expect(find.textContaining('Brunnen'), findsOneWidget);
  });

  testWidgets('it says what it is and what it is not', (tester) async {
    await show(
      tester,
      client: serving({'/A/Trinkwasser': '<p>Text</p>'}),
    );

    // Said at the top rather than discovered by noticing a missing
    // formula: this is deliberately less than a browser.
    expect(find.text('Einfache Ansicht'), findsOneWidget);
    expect(find.textContaining('Skripte, Formelsatz'), findsOneWidget);
  });

  testWidgets('the page names itself once it has been read', (tester) async {
    await show(
      tester,
      client: serving({
        '/A/Trinkwasser':
            '<html><head><title>Trinkwasser – Wikipedia</title></head>'
            '<body><p>x</p></body></html>',
      }),
    );

    expect(find.text('Trinkwasser – Wikipedia'), findsOneWidget);
  });

  testWidgets('a link inside the archive opens the next article', (
    tester,
  ) async {
    final client = serving({
      '/A/Trinkwasser': '<p>siehe <a href="Grundwasser">Grundwasser</a></p>',
      '/A/Grundwasser': '<p>Grundwasser ist unterirdisch.</p>',
    });
    await show(tester, client: client);

    // On the word itself, not on the middle of the paragraph: the link
    // is a run inside a sentence, and tapping the widget's centre lands
    // on whatever happens to be there.
    await tester.tapOnText(find.textRange.ofSubstring('Grundwasser'));
    await tester.pumpAndSettle();

    expect(find.textContaining('unterirdisch'), findsOneWidget);
    // And Back goes back, because it is a route and not a replacement.
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('a page that does not answer says so instead of staying blank', (
    tester,
  ) async {
    await show(tester, client: serving(const {}));

    expect(
      find.text('Der Artikel konnte nicht gelesen werden.'),
      findsOneWidget,
    );
  });

  testWidgets('a page with no text says that, which is a different thing', (
    tester,
  ) async {
    await show(
      tester,
      client: serving({'/A/Trinkwasser': '<html><body></body></html>'}),
    );

    expect(
      find.text('Diese Seite enthält keinen lesbaren Text.'),
      findsOneWidget,
    );
  });

  testWidgets('a table comes through as a table', (tester) async {
    await show(
      tester,
      client: serving({
        '/A/Trinkwasser':
            '<table>'
            '<tr><th>Stoff</th><th>Grenzwert</th></tr>'
            '<tr><td>Blei</td><td>0,010 mg/l</td></tr>'
            '</table>',
      }),
    );

    expect(find.byType(Table), findsOneWidget);
    expect(find.textContaining('Blei'), findsOneWidget);
    expect(find.textContaining('0,010 mg/l'), findsOneWidget);
  });

  testWidgets('a missing picture does not take the article with it', (
    tester,
  ) async {
    await show(
      tester,
      client: serving({
        '/A/Trinkwasser':
            '<p>Vorher</p>'
            '<img src="../I/fehlt.png" alt="Eine Quelle">'
            '<p>Nachher</p>',
      }),
    );

    // A no-picture archive carries the markup without the file. Both
    // paragraphs have to survive it.
    expect(find.textContaining('Vorher'), findsOneWidget);
    expect(find.textContaining('Nachher'), findsOneWidget);
  });

  testWidgets('the text can be selected, because a reference gets copied', (
    tester,
  ) async {
    await show(
      tester,
      client: serving({'/A/Trinkwasser': '<p>Zwei Liter am Tag.</p>'}),
    );

    // Across the whole article, not per paragraph — and without eating
    // the taps that follow links.
    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('is accessible', (tester) async {
    await show(
      tester,
      client: serving({
        '/A/Trinkwasser':
            '<h2>Gewinnung</h2>'
            '<p>Trinkwasser wird aus <a href="Grundwasser">Grundwasser</a> '
            'gewonnen.</p>'
            '<ul><li>Brunnen</li></ul>',
      }),
    );

    await expectAccessible(tester);
  });
}
