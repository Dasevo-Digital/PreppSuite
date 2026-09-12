import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/knowledge/presentation/article_reader_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import '../features/fixture_http_client.dart';
import '../widget/accessibility.dart';

/// Draws a real article, which is the only way to find out whether the
/// reader survives one.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. A hand-written
/// fixture has the tags one thought of; a real article has nested tables,
/// hundred-character chemical names, image captions the width of the
/// screen and a thousand blocks. Flutter reports an overflow as an error
/// during layout, so a page that pumps clean here is one whose text has
/// somewhere to go.
void main() {
  // `testWidgets` takes a bool here, not the sentence `test` takes.
  final offline = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null;

  const articles = ['Trinkwasser', 'Deutschland'];

  /// Fetches the article for real.
  ///
  /// Two things the widget binding does have to be undone for this. It
  /// runs everything on a fake clock, so the call goes inside
  /// [WidgetTester.runAsync]; and it installs an [HttpOverrides] that
  /// answers every request with 400, so that has to be lifted for the
  /// duration. Without either, the first version of this test passed in
  /// no time at all while drawing nothing — which is why the body is
  /// asserted rather than skipped over.
  Future<String> fetch(WidgetTester tester, String name) async {
    final body = await tester.runAsync(() async {
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      try {
        final response = await http.get(
          Uri.https('de.wikipedia.org', '/api/rest_v1/page/html/$name'),
          headers: const {'User-Agent': 'PreppSuite/1.0 (offline reader)'},
        );
        return response.statusCode == 200 ? response.body : '';
      } finally {
        HttpOverrides.global = overrides;
      }
    });
    expect(body, isNotNull);
    expect(body, isNotEmpty, reason: '$name did not arrive');
    return body!;
  }

  Future<void> draw(
    WidgetTester tester,
    String name,
    String body, {
    double textScale = 1,
  }) async {
    if (textScale != 1) useLargeText(tester, scale: textScale);
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ArticleReaderScreen(
          title: name,
          uri: Uri.parse('http://127.0.0.1:8080/A/$name'),
          client: FixtureHttpClient({'http://127.0.0.1:8080/A/$name': body}),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a real article draws at phone width without overflowing',
    (
      tester,
    ) async {
      for (final name in articles) {
        final body = await fetch(tester, name);
        await draw(tester, name, body);

        expect(find.text('Einfache Ansicht'), findsOneWidget);

        // Scrolled through without anything blowing up on the way, and
        // counting what was actually drawn. The list builds as it goes —
        // the point of it for an article of a thousand blocks — so the
        // first screen holds only a handful and the count has to be
        // taken across the whole journey.
        var drawn = find.byType(Text).evaluate().length;
        final list = find.byType(Scrollable).first;
        for (var page = 0; page < 12; page++) {
          await tester.drag(list, const Offset(0, -600));
          await tester.pump();
          final now = find.byType(Text).evaluate().length;
          if (now > drawn) drawn = now;
        }
        expect(drawn, greaterThan(8), reason: '$name drew almost nothing');
      }
    },
    skip: offline,
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'and again at twice the font size',
    (tester) async {
      // The size at the top of what Android and iOS offer. A table or a
      // long chemical name that fits at one is the thing that does not fit
      // at two.
      final body = await fetch(tester, 'Trinkwasser');
      await draw(tester, 'Trinkwasser', body, textScale: 2);

      expect(find.text('Einfache Ansicht'), findsOneWidget);
      final list = find.byType(Scrollable).first;
      for (var page = 0; page < 8; page++) {
        await tester.drag(list, const Offset(0, -600));
        await tester.pump();
      }
    },
    skip: offline,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
