import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/morse/presentation/morse_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

void main() {
  /// The key's clock, moved by hand.
  var now = Duration.zero;

  Future<void> pump(
    WidgetTester tester, {
    Size size = const Size(400, 800),
  }) async {
    now = Duration.zero;
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MorseScreen(keyClock: () => now),
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

  testWidgets('presses on the key become a message (#191)', (tester) async {
    await pump(tester, size: const Size(400, 1200));
    await tester.tap(find.text('Morse → Text'));
    await tester.pump();

    final key = find.text('Morsetaste');
    Future<void> press(int milliseconds, {int after = 200}) async {
      now += Duration(milliseconds: after);
      final gesture = await tester.startGesture(tester.getCenter(key));
      now += Duration(milliseconds: milliseconds);
      await gesture.up();
      await tester.pump();
    }

    // S, a letter gap, O, a letter gap, S: 200 ms a dot.
    for (final length in [200, 200, 200]) {
      await press(length);
    }
    await press(600, after: 600);
    await press(600);
    await press(600);
    await press(200, after: 600);
    await press(200);
    await press(200);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '... --- ...');
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('quick dots with a mouse select nothing on the key (#191)', (
    tester,
  ) async {
    // Every screen of the app lies in a selection area (#39). To it, two
    // quick clicks are a double click, and it marked the key's word.
    SelectedContent? selected;
    tester.view.physicalSize = const Size(400, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SelectionArea(
          onSelectionChanged: (content) => selected = content,
          child: MorseScreen(keyClock: () => now),
        ),
      ),
    );
    await tester.tap(find.text('Morse → Text'));
    await tester.pump();

    final key = tester.getCenter(find.text('Morsetaste'));
    for (var i = 0; i < 3; i++) {
      final click = await tester.startGesture(
        key,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump(const Duration(milliseconds: 60));
      await click.up();
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pumpAndSettle();

    expect(selected?.plainText ?? '', isEmpty);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '...');
  });

  testWidgets('the space bar keys as well, and the result is read', (
    tester,
  ) async {
    await pump(tester, size: const Size(400, 1200));
    await tester.tap(find.text('Morse → Text'));
    await tester.pump();
    // Focus the key by pressing it once, then start again.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Morsetaste')),
    );
    await gesture.up();
    await tester.tap(find.text('Neu beginnen'));
    await tester.pump();

    Future<void> space(int milliseconds, {int after = 200}) async {
      now += Duration(milliseconds: after);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      now += Duration(milliseconds: milliseconds);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();
    }

    // S, a letter gap, O, a letter gap, S.
    for (final length in [200, 200, 200]) {
      await space(length);
    }
    await space(600, after: 600);
    await space(600);
    await space(600);
    await space(200, after: 600);
    await space(200);
    await space(200);

    expect(find.text('SOS'), findsOneWidget);
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
