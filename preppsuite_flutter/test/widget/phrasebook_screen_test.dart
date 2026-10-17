import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/phrasebook/presentation/phrasebook_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Locale locale = const Locale('de'),
    Size size = const Size(400, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PhrasebookScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('a German reader starts with English beside German', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsOneWidget);
    expect(find.text("I don't speak your language."), findsOneWidget);
    expect(
      find.textContaining('nicht von Muttersprachlern geprüft'),
      findsOneWidget,
    );
  });

  testWidgets('a Spanish reader starts with German', (tester) async {
    await pump(tester, locale: const Locale('es'));
    expect(find.text('No hablo su idioma.'), findsOneWidget);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsOneWidget);
  });

  testWidgets('Arabic is set right to left', (tester) async {
    await pump(tester);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    // The menu scrolls; the last entries are built only once reached.
    final arabicEntry = find.text('العربية', skipOffstage: false).last;
    await tester.ensureVisible(arabicEntry);
    await tester.pumpAndSettle();
    await tester.tap(arabicEntry);
    await tester.pumpAndSettle();

    final arabic = tester.widget<Text>(find.text('لا أتكلم لغتك.'));
    expect(arabic.textDirection, TextDirection.rtl);
  });

  testWidgets('search finds a sentence by either language', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'krankenwagen');
    await tester.pump();

    expect(find.text('Bitte rufen Sie einen Krankenwagen.'), findsOneWidget);
    expect(find.text('Please call an ambulance.'), findsOneWidget);
    expect(find.text('Ich spreche Ihre Sprache nicht.'), findsNothing);

    await tester.enterText(find.byType(TextField), 'xyzzy');
    await tester.pump();
    expect(find.text('Kein Satz gefunden.'), findsOneWidget);
  });

  testWidgets('a sentence is shown large, and closed again', (tester) async {
    await pump(tester);
    await tester.scrollUntilVisible(
      find.text('Hilfe!'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hilfe!'));
    await tester.pumpAndSettle();

    final large = tester.widget<Text>(find.text('Help!').last);
    expect(large.style?.fontSize, greaterThan(30));
    await tester.tap(find.byTooltip('Schließen'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('at twice the text size nothing overflows', (tester) async {
    useLargeText(tester);
    await pump(tester, size: const Size(360, 640));
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester);
    await expectAccessible(tester);
  });
}
