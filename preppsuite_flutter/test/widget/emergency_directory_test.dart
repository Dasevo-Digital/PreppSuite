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

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the screen survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
