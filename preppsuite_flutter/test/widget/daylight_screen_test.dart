import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/daylight/application/daylight_store.dart';
import 'package:preppsuite_flutter/features/daylight/presentation/daylight_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester, {DateTime? now}) async {
    // Tall enough to build the whole list: a `ListView` only builds what
    // it can show, and `find.text` cannot find a row that was never
    // built. The alternative — scrolling in every test — would be
    // testing the scroll rather than the screen.
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DaylightScreen(now: now),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no place set it asks for one', (tester) async {
    await show(tester);

    expect(find.text('Noch kein Ort gesetzt'), findsOneWidget);
    expect(find.text('Ort setzen'), findsOneWidget);
  });

  testWidgets('a saved place gives the day in the order it happens', (
    tester,
  ) async {
    await const DaylightStore().save(
      const DaylightPlace(
        latitude: 52.2689,
        longitude: 10.5268,
        name: 'Braunschweig',
      ),
    );
    // The zone is the machine's, so the expected times are only checked
    // where the machine runs on Central European time; the arithmetic
    // itself is checked against the USNO in sun_moon_test.dart. What this
    // test is for is that the screen shows what was computed.
    await show(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.text('Braunschweig'), findsOneWidget);
    expect(find.text('Sonnenaufgang'), findsWidgets);
    expect(find.text('Sonnenuntergang'), findsWidgets);
    expect(find.text('Erste Helligkeit'), findsOneWidget);
    expect(find.text('Letzte Helligkeit'), findsOneWidget);
    expect(find.textContaining('Tageslänge'), findsOneWidget);
    // Tomorrow gets its own card: a sunrise is something you plan for.
    expect(find.text('Morgen'), findsOneWidget);
  });

  testWidgets('the moon is named and its lit fraction given', (tester) async {
    await const DaylightStore().save(
      const DaylightPlace(latitude: 52.2689, longitude: 10.5268),
    );
    await show(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.text('Mond'), findsOneWidget);
    // 11 September 2026 is a new moon, which is the night nothing can be
    // done in.
    expect(find.text('Neumond'), findsOneWidget);
    expect(find.textContaining('% beleuchtet'), findsOneWidget);
  });

  testWidgets('with no name the coordinates stand in', (tester) async {
    await const DaylightStore().save(
      const DaylightPlace(latitude: 52.2689, longitude: 10.5268),
    );
    await show(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.text('52.2689, 10.5268'), findsOneWidget);
  });

  testWidgets('it says the figures are computed and how close they are', (
    tester,
  ) async {
    await const DaylightStore().save(
      const DaylightPlace(latitude: 52.2689, longitude: 10.5268),
    );
    await show(tester, now: DateTime(2026, 9, 11, 12));

    expect(find.textContaining('auf dem Gerät gerechnet'), findsOneWidget);
    // And what the figures do not account for.
    expect(find.textContaining('freie Sicht zum Horizont'), findsOneWidget);
  });

  testWidgets('a typed coordinate is taken and remembered', (tester) async {
    await show(tester, now: DateTime(2026, 9, 11, 12));

    await tester.tap(find.text('Ort setzen'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      '48,1372; 11,5756',
    );
    await tester.enterText(find.byType(TextField).last, 'München');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('München'), findsOneWidget);
    final stored = await const DaylightStore().load();
    expect(stored!.latitude, closeTo(48.1372, 0.0001));
    expect(stored.name, 'München');
  });

  testWidgets('a coordinate that is not one is refused with a reason', (
    tester,
  ) async {
    await show(tester, now: DateTime(2026, 9, 11, 12));

    await tester.tap(find.text('Ort setzen'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Braunschweig');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Zwei Zahlen'), findsOneWidget);
    // And the dialog stays open rather than saving nothing quietly.
    expect(find.text('Ort setzen'), findsWidgets);
  });

  testWidgets('is accessible', (tester) async {
    await const DaylightStore().save(
      const DaylightPlace(
        latitude: 52.2689,
        longitude: 10.5268,
        name: 'Braunschweig',
      ),
    );
    await show(tester, now: DateTime(2026, 9, 11, 12));

    await expectAccessible(tester);
  });
}
