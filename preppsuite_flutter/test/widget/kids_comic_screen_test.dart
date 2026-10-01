import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_de.dart';
import 'package:preppsuite_flutter/features/kids_comic/application/kids_comic_en.dart';
import 'package:preppsuite_flutter/features/kids_comic/presentation/kids_comic_chapter_screen.dart';
import 'package:preppsuite_flutter/features/kids_comic/presentation/kids_comic_rules_screen.dart';
import 'package:preppsuite_flutter/features/kids_comic/presentation/kids_comic_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The comic on screen: a cover with its chapters, one chapter after the
/// other, and the sheet of rules at the end.
void main() {
  Future<void> show(
    WidgetTester tester,
    Widget home, {
    Size size = const Size(420, 2600),
    Locale locale = const Locale('de'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the cover lists every chapter and the rules', (tester) async {
    await show(tester, const KidsComicScreen());

    for (final chapter in kidsComicDe.chapters) {
      expect(find.text(chapter.title), findsOneWidget);
    }
    expect(find.text('Zum Merken'), findsOneWidget);
    expect(find.text('Für Eltern und Erziehende'), findsOneWidget);
  });

  testWidgets('a chapter shows its words and leads on to the next', (
    tester,
  ) async {
    await show(tester, const KidsComicChapterScreen(index: 4));

    expect(find.text('Es piept und riecht nach Rauch'), findsOneWidget);
    expect(find.textContaining('Wir gehen niemals zurück'), findsOneWidget);
    expect(
      find.text('Weiter: ${kidsComicDe.chapters[5].title}'),
      findsOneWidget,
    );
  });

  testWidgets('the last chapter leads on to the rules', (tester) async {
    await show(tester, const KidsComicChapterScreen(index: 5));

    final next = find.text('Weiter: Zum Merken');
    await tester.scrollUntilVisible(next, 400);
    await tester.tap(next);
    await tester.pumpAndSettle();

    expect(find.text('Notrufnummern'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
  });

  testWidgets('on a wide window two panels share a row', (tester) async {
    // Read across, then down — the way a comic is read.
    await show(
      tester,
      const KidsComicChapterScreen(index: 1),
      size: const Size(1280, 2600),
    );

    final first = tester.getTopLeft(
      find.bySemanticsLabel(
        kidsComicDe.chapters[1].panels[0].description,
      ),
    );
    final second = tester.getTopLeft(
      find.bySemanticsLabel(
        kidsComicDe.chapters[1].panels[1].description,
      ),
    );
    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('it is in English on an English locale', (tester) async {
    await show(
      tester,
      const KidsComicChapterScreen(index: 0),
      locale: const Locale('en'),
    );

    expect(find.text(kidsComicEn.chapters[0].title), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
  });

  testWidgets('a chapter meets the accessibility guidelines', (tester) async {
    await show(tester, const KidsComicChapterScreen(index: 2));
    await expectAccessible(tester);
  });

  testWidgets('the rules meet the accessibility guidelines', (tester) async {
    await show(tester, const KidsComicRulesScreen());
    await expectAccessible(tester);
  });
}
