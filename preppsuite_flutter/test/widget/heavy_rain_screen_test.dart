import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/heavy_rain_hazard.dart';
import 'package:preppsuite_flutter/features/warnings/application/river_flood.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/heavy_rain_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The heavy rain screen shows the BKG's legend and nothing beyond it, and
/// says so plainly where the map has no data (#115).
void main() {
  Future<void> show(
    WidgetTester tester,
    HeavyRainHazard? kept, {
    Size size = const Size(400, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
    expect(find.text('Wassertiefe: 10 bis 30 cm'), findsOne);
    expect(find.text('Wassertiefe: 50 bis 100 cm'), findsOne);
    // What the two come to, first, in the deeper one's words.
    expect(find.text('Im schlimmeren Fall 50 bis 100 cm Wasser.'), findsOne);
    expect(find.text('Fließgeschwindigkeit: 0,2 bis 0,5 m/s'), findsOneWidget);
    expect(find.textContaining('Kanalisation und Versickerung'), findsOne);
  });

  testWidgets('the river map shows its three floods', (tester) async {
    await show(
      tester,
      HeavyRainHazard(
        latitude: 52.378,
        longitude: 9.7,
        placeName: 'Hannover',
        stateName: 'Niedersachsen',
        checkedAt: DateTime(2026, 10, 7),
        covered: true,
        river: const RiverFloodResult(
          covered: true,
          classes: {
            RiverFloodScenario.frequent: 0,
            RiverFloodScenario.hundred: 4,
            RiverFloodScenario.extreme: 5,
          },
        ),
      ),
    );
    expect(find.text('Hochwasser an Flüssen'), findsOneWidget);
    expect(find.text('Häufiges Hochwasser (HQhäufig)'), findsOneWidget);
    expect(find.text('laut Karte nicht überflutet'), findsOneWidget);
    expect(find.text('2 bis 4 m Wasser'), findsOneWidget);
    expect(
      find.text('Im schlimmsten Fall: mehr als 4 m Wasser.'),
      findsOneWidget,
    );
    expect(find.textContaining('NLWKN'), findsOneWidget);
  });

  testWidgets('the national map: a missing flood is "no map", not dry', (
    tester,
  ) async {
    await show(
      tester,
      HeavyRainHazard(
        latitude: 49.233,
        longitude: 6.993,
        placeName: 'Saarbrücken',
        stateName: 'Saarland',
        checkedAt: DateTime(2026, 10, 9),
        covered: true,
        river: const RiverFloodResult(
          covered: true,
          stateCode: 'SL',
          national: true,
          classes: {
            RiverFloodScenario.hundred: floodDepthUnknown,
            RiverFloodScenario.extreme: 5,
          },
        ),
      ),
    );
    expect(find.text('keine Karte für dieses Szenario'), findsOneWidget);
    expect(find.textContaining('nicht überflutet'), findsNothing);
    expect(find.text('überflutet, Tiefe nicht angegeben'), findsOneWidget);
    expect(
      find.textContaining('Bundesanstalt für Gewässerkunde'),
      findsOneWidget,
    );
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

  HeavyRainHazard dryHere({RiverFloodResult? river}) => HeavyRainHazard(
    latitude: 52.27,
    longitude: 10.52,
    placeName: 'Musterweg 1, Braunschweig',
    stateName: 'Niedersachsen',
    checkedAt: DateTime(2026, 10, 20),
    covered: true,
    results: const {
      HeavyRainScenario.exceptional: HeavyRainScenarioResult(
        maxDepthCm: 4,
        maxVelocity: 0.1,
      ),
      HeavyRainScenario.extreme: HeavyRainScenarioResult(
        maxDepthCm: 8,
        maxVelocity: 0.1,
      ),
    },
    river:
        river ??
        const RiverFloodResult(
          covered: true,
          classes: {
            RiverFloodScenario.frequent: 0,
            RiverFloodScenario.hundred: 0,
            RiverFloodScenario.extreme: 0,
          },
        ),
  );

  testWidgets('a dry place says so first, and shows no empty boxes', (
    tester,
  ) async {
    await show(tester, dryHere());
    expect(find.text('In beiden Fällen kaum Wasser: unter 10 cm.'), findsOne);
    expect(find.text('In keinem der drei Fälle überflutet.'), findsOne);
    // Five scenarios, five empty drops -- not squares that read as
    // unticked checkboxes.
    expect(find.byIcon(Icons.water_drop_outlined), findsNWidgets(5));
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('a flood not mapped here is no "dry" for the river', (
    tester,
  ) async {
    await show(
      tester,
      dryHere(
        river: const RiverFloodResult(
          covered: true,
          national: true,
          classes: {
            RiverFloodScenario.hundred: 0,
            RiverFloodScenario.extreme: 0,
          },
        ),
      ),
    );
    expect(find.text('In keinem der drei Fälle überflutet.'), findsNothing);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
  });

  testWidgets(
    'on a wide window it reads from the top, the cards side by side',
    (
      tester,
    ) async {
      // The columns used to be dealt in turn: the rarer rain at the top
      // left under the address, the other at the top right, the buttons to
      // ask again between the cards and the small print.
      await show(tester, dryHere(), size: const Size(1300, 900));
      double top(String text) => tester.getTopLeft(find.text(text)).dy;
      double left(String text) => tester.getTopLeft(find.text(text)).dx;

      final address = top(
        'Musterweg 1, Braunschweig, abgefragt am 20. Okt. 2026',
      );
      expect(top('Adresse eingeben'), greaterThan(address));
      expect(top('Starkregen'), greaterThan(top('Adresse eingeben')));
      expect(top('Hochwasser an Flüssen'), top('Starkregen'));
      expect(left('Hochwasser an Flüssen'), greaterThan(left('Starkregen')));

      // Both rain scenarios in one card, the more frequent first.
      final exceptional = find.text('Außergewöhnlicher Starkregen');
      final extreme = find.text('Extremer Starkregen');
      final card = find.ancestor(of: exceptional, matching: find.byType(Card));
      expect(find.descendant(of: card, matching: extreme), findsOneWidget);
      expect(
        top('Extremer Starkregen'),
        greaterThan(top('Außergewöhnlicher Starkregen')),
      );
      expect(
        top(
          'Für die Abfrage gehen die Koordinaten an den Kartendienst des BKG, '
          'für das Bundesland eine auf etwa einen Kilometer gerundete Position '
          'an OpenStreetMap.',
        ),
        greaterThan(top('Extremer Starkregen')),
      );
    },
  );
}
