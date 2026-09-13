import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/presentation/emergency_information_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// The reference screen for an emergency: numbers, radio bands, and now
/// what a siren actually means.
///
/// Siren signals belong on paper-grade reference rather than behind a
/// warning feed: they sound exactly when the phone may be the thing that
/// stopped working, and somebody standing at a window trying to remember
/// whether a steady tone is good or bad has no time to search.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(500, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const EmergencyInformationScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('all three signals are named with what they mean', (
    tester,
  ) async {
    await show(tester);

    expect(find.text('Sirenensignale'), findsOneWidget);
    expect(find.textContaining('Heulton'), findsOneWidget);
    expect(find.textContaining('Dauerton'), findsOneWidget);
    expect(find.textContaining('unterbrochener Ton'), findsOneWidget);
  });

  testWidgets('the warning signal says what to do, not just what it is', (
    tester,
  ) async {
    // A tone described and left unexplained is worse than no entry: it
    // reads as complete.
    await show(tester);

    expect(find.textContaining('Radio einschalten'), findsOneWidget);
    expect(find.textContaining('Fenster'), findsWidgets);
  });

  testWidgets('the fire alert is marked as not meant for the public', (
    tester,
  ) async {
    // The one people hear most often and read as a warning. Leaving it
    // off the list would leave that misreading in place.
    await show(tester);

    expect(find.textContaining('nicht der Bevölkerung'), findsOneWidget);
  });

  testWidgets('the list does not claim to be the same everywhere', (
    tester,
  ) async {
    // It is a nationwide recommendation and not a rule; a municipality
    // can use its sirens differently. Stating it flatly would be the app
    // overreaching its source.
    await show(tester);

    expect(find.textContaining('nicht überall gleich'), findsOneWidget);
    expect(find.textContaining('Gemeinde'), findsWidgets);
  });

  testWidgets('a saved contact can be corrected afterwards', (tester) async {
    // Until 1.8.1 the only way to fix a mistyped number was to delete the
    // contact and enter it again, on the screen that exists for the
    // moment when there is no time for that.
    SharedPreferences.setMockInitialValues({
      'nearbyEmergencyContacts':
          '[{"id":"c1","name":"Nachbarin Ella","phone":"0531 111111",'
          '"address":"Hauptstrasse 4","coordinates":""}]',
    });
    await show(tester);

    // The contacts sit at the bottom of a long ListView, so they are not
    // built until they are scrolled to.
    await tester.scrollUntilVisible(find.text('Nachbarin Ella'), 400);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kontakt bearbeiten'));
    await tester.pumpAndSettle();

    // The dialog comes up filled in -- editing starts from what is there.
    expect(
      tester.widget<TextField>(find.byType(TextField).at(1)).controller!.text,
      '0531 111111',
    );

    await tester.enterText(find.byType(TextField).at(1), '0531 222222');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('0531 222222'), findsOneWidget);
    expect(find.textContaining('0531 111111'), findsNothing);

    // Changed, not added.
    expect(find.text('Nachbarin Ella'), findsOneWidget);

    final stored = (await SharedPreferences.getInstance()).getString(
      'nearbyEmergencyContacts',
    )!;
    expect(stored, contains('0531 222222'));
    expect(
      stored,
      contains('"id":"c1"'),
      reason: 'same contact, not a new one',
    );
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
