import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/settings_arrival.dart';
import 'package:preppsuite_flutter/features/energy/presentation/outage_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The blackout clock travels with the household: started on one device,
/// it runs on all of them, and ended on one, it is over everywhere. A
/// screen left open must follow that, and must not start a clock that
/// another device has stopped (#258).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String hoursAgo(int hours) =>
      DateTime.now().toUtc().subtract(Duration(hours: hours)).toIso8601String();

  Future<SharedPreferences> show(
    WidgetTester tester,
    Map<String, Object> stored,
  ) async {
    SharedPreferences.setMockInitialValues(stored);
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OutageScreen(),
      ),
    );
    await tester.pumpAndSettle();
    // The screen ticks every 30 seconds; it has to be gone at the end.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    return SharedPreferences.getInstance();
  }

  testWidgets('a blackout ended elsewhere stays ended when the freezer '
      'answer changes here', (tester) async {
    final prefs = await show(tester, {'outageStartedAt': hoursAgo(1)});
    expect(find.text('Der Strom ist jetzt weg'), findsNothing);

    // The power came back and the laptop stopped the clock.
    await prefs.remove('outageStartedAt');
    announceSettingsArrival();
    await tester.pumpAndSettle();
    expect(find.text('Der Strom ist jetzt weg'), findsOneWidget);

    await tester.tap(find.text('Halb voll oder weniger'));
    await tester.pumpAndSettle();

    expect(prefs.getString('outageStartedAt'), isNull);
    expect(prefs.getBool('outageFreezerFull'), isFalse);
  });

  testWidgets('even when the arrival was missed', (tester) async {
    final prefs = await show(tester, {'outageStartedAt': hoursAgo(1)});

    // Ended elsewhere, and this screen was not told.
    await prefs.remove('outageStartedAt');
    await tester.tap(find.text('Halb voll oder weniger'));
    await tester.pumpAndSettle();

    expect(prefs.getString('outageStartedAt'), isNull);
    expect(find.text('Der Strom ist jetzt weg'), findsOneWidget);
  });

  testWidgets('a blackout started elsewhere shows up here', (tester) async {
    final prefs = await show(tester, const {});
    expect(find.text('Der Strom ist jetzt weg'), findsOneWidget);

    await prefs.setString('outageStartedAt', hoursAgo(2));
    announceSettingsArrival();
    await tester.pumpAndSettle();

    expect(find.text('Der Strom ist jetzt weg'), findsNothing);
  });

  testWidgets('starting here keeps the earlier start from elsewhere', (
    tester,
  ) async {
    final prefs = await show(tester, const {});
    final earlier = hoursAgo(3);
    await prefs.setString('outageStartedAt', earlier);

    await tester.tap(find.text('Der Strom ist jetzt weg'));
    await tester.pumpAndSettle();

    expect(prefs.getString('outageStartedAt'), earlier);
  });
}
