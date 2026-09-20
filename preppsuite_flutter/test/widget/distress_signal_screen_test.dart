import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/distress_signal_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The screen as a lamp.
///
/// What matters here is that the three rhythms are offered by name, that
/// the pause is explained rather than looking like a fault, and that the
/// cost is stated before somebody spends their battery on it.
void main() {
  Future<void> show(WidgetTester tester, {String locale = 'de'}) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const DistressSignalScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all three rhythms are offered, the answer included', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('Alpines Notsignal'), findsOneWidget);
    // The answer matters as much as the call: it is what tells somebody
    // signalling that they have been seen.
    expect(find.text('Antwort auf ein Notsignal'), findsOneWidget);
  });

  testWidgets('the pause is explained as part of the signal', (tester) async {
    await show(tester);

    expect(
      find.textContaining('dann eine Minute nichts'),
      findsOneWidget,
    );
  });

  testWidgets('what it costs is said before it is switched on', (tester) async {
    await show(tester);

    expect(find.textContaining('Akku'), findsOneWidget);
  });

  testWidgets('it runs, counts the signals, and stops again', (tester) async {
    await show(tester);

    await tester.tap(find.text('Signal starten').last);
    await tester.pump(const Duration(milliseconds: 100));

    // SOS is the default, and its first element is lit at once.
    expect(find.textContaining('von 9'), findsOneWidget);
    expect(find.text('Anhalten'), findsOneWidget);

    await tester.tap(find.text('Anhalten'));
    await tester.pump();
    expect(find.text('Signal starten'), findsWidgets);
  });

  testWidgets('English gets the English screen', (tester) async {
    await show(tester, locale: 'en');
    expect(find.text('Distress signal'), findsOneWidget);
    expect(find.text('Alpine distress signal'), findsOneWidget);
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
