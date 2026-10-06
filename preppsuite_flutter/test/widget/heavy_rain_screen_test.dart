import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/heavy_rain_hazard.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/heavy_rain_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The heavy rain screen shows the BKG's legend and nothing beyond it, and
/// says so plainly where the map has no data (#115).
void main() {
  Future<void> show(WidgetTester tester, HeavyRainHazard? kept) async {
    SharedPreferences.setMockInitialValues({});
    if (kept != null) await const HeavyRainStore().save(kept);
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HeavyRainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('nothing checked yet offers both ways to a place', (
    tester,
  ) async {
    await show(tester, null);
    expect(find.text('Meinen Standort verwenden'), findsOneWidget);
    expect(find.text('Adresse eingeben'), findsOneWidget);
    expect(find.textContaining('dl-de/by-2-0'), findsOneWidget);
  });

  testWidgets('a kept answer is shown in the legend classes', (tester) async {
    await show(
      tester,
      HeavyRainHazard(
        latitude: 52.2689,
        longitude: 10.5268,
        placeName: 'Braunschweig',
        checkedAt: DateTime(2026, 10, 6),
        covered: true,
        results: const {
          HeavyRainScenario.exceptional: HeavyRainScenarioResult(
            maxDepthCm: 21,
            maxVelocity: 0.2,
          ),
          HeavyRainScenario.extreme: HeavyRainScenarioResult(
            maxDepthCm: 52,
            maxVelocity: 0.15,
          ),
        },
      ),
    );
    expect(find.textContaining('Braunschweig'), findsOneWidget);
    expect(
      find.text('Wassertiefe im Umkreis von 25 m: 10 bis 30 cm'),
      findsOne,
    );
    expect(
      find.text('Wassertiefe im Umkreis von 25 m: 50 bis 100 cm'),
      findsOne,
    );
    expect(find.text('Fließgeschwindigkeit: 0,2 bis 0,5 m/s'), findsOneWidget);
    expect(find.textContaining('Kanalisation und Versickerung'), findsOne);
  });

  testWidgets('a state without data is not called dry', (tester) async {
    await show(
      tester,
      HeavyRainHazard(
        latitude: 48.137,
        longitude: 11.575,
        stateName: 'Bayern',
        checkedAt: DateTime(2026, 10, 6),
        covered: false,
      ),
    );
    expect(find.textContaining('Für Bayern enthält'), findsOneWidget);
    expect(find.textContaining('Wassertiefe'), findsNothing);
  });
}
