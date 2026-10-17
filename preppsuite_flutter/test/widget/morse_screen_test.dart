import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/morse/presentation/morse_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MorseScreen(),
      ),
    );
    await tester.pump();
  }

  testWidgets('text becomes Morse as it is typed', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'SOS hilfe');
    await tester.pump();

    expect(find.text('••• ——— ••• / •••• •• •—•• ••—• •'), findsOneWidget);
  });

  testWidgets('what has no signal is said', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'Preis 5 €');
    await tester.pump();

    expect(find.text('Ohne Morsezeichen, ausgelassen: €'), findsOneWidget);
  });

  testWidgets('switching direction turns the answer into the question', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'ok');
    await tester.pump();
    await tester.tap(find.text('Morse → Text'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '——— —•—');
    expect(find.text('OK'), findsOneWidget);
  });

  testWidgets('a reply is read back, unknown signals marked', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Morse → Text'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '.- ......- -...');
    await tester.pump();

    expect(find.text('A□B'), findsOneWidget);
    expect(find.text('Unbekannte Zeichen (□): ......-'), findsOneWidget);
  });

  testWidgets('the chart has every group and names its source', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    await tester.tap(find.text('Tafel'));
    await tester.pumpAndSettle();

    expect(find.text('Buchstaben'), findsOneWidget);
    expect(find.bySemanticsLabel('A: kurz lang'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('ITU-R M.1677-1'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Landessprachliche Zeichen'), findsOneWidget);
    expect(find.text('Betriebszeichen'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('the screen sends the message as light, and stops', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'E');
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Als Lichtsignal senden'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Als Lichtsignal senden'));
    await tester.pump(const Duration(milliseconds: 100));

    // The timing itself is the rhythm's and tested there; the lamp runs
    // on a real stopwatch, which a widget test's clock does not move.
    // What is checked here is that it starts, says where it is, and stops.
    expect(
      tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == Colors.white || d.color == Colors.black),
      isNotEmpty,
    );
    expect(find.text('Zeichen 1 von 1'), findsOneWidget);
    expect(
      find.text('Tafel'),
      findsNothing,
      reason: 'the lamp takes the screen',
    );

    await tester.tap(find.text('Stopp'));
    await tester.pump();
    expect(find.text('Als Lichtsignal senden'), findsOneWidget);
  });

  testWidgets('at twice the text size nothing overflows', (tester) async {
    useLargeText(tester);
    await pump(tester, size: const Size(360, 640));
    await tester.enterText(find.byType(TextField), 'Treffpunkt Rathaus');
    await tester.pump();
    await tester.tap(find.text('Tafel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('is accessible', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'SOS');
    await tester.pump();
    await expectAccessible(tester);
    await tester.tap(find.text('Tafel'));
    await tester.pumpAndSettle();
    await expectAccessible(tester);
  });
}
