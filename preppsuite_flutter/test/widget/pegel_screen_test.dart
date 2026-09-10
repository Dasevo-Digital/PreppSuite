import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_client.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/pegel_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Watching a gauge.
///
/// The values are the Rhine at Cologne as published: mean 297 cm, mean
/// flood 725, highest ever 1069. They are what turns a bare number into
/// something a household can act on, and the screen is not allowed to
/// show the number without them.
void main() {
  const levelFixture = '''
{
  "shortname": "W", "unit": "cm",
  "currentMeasurement": {"timestamp": "2026-09-10T18:15:00+02:00",
    "value": 66.0},
  "characteristicValues": [
    {"shortname": "MNW", "unit": "cm", "value": 114.0},
    {"shortname": "MW", "unit": "cm", "value": 297.0},
    {"shortname": "MHW", "unit": "cm", "value": 725.0},
    {"shortname": "HHW", "unit": "cm", "value": 1069.0},
    {"shortname": "NNW", "unit": "cm", "value": 69.0},
    {"shortname": "GlW", "unit": "cm", "value": 139.0}
  ]
}''';

  const stationsFixture = '''
[
  {"uuid": "koeln", "shortname": "KÖLN", "km": 688.0,
   "water": {"shortname": "RHEIN"}},
  {"uuid": "andernach", "shortname": "ANDERNACH", "km": 613.8,
   "water": {"shortname": "RHEIN"}},
  {"uuid": "hamburg", "shortname": "ST.PAULI", "km": 623.0,
   "water": {"shortname": "ELBE"}}
]''';

  http.Response respond(String body, int status) => http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json;charset=UTF-8'},
  );

  /// A rising series: 48 cm over the last day.
  String series() {
    final start = DateTime.utc(2026, 9, 8, 16, 15);
    final samples = <String>[];
    for (var i = 0; i <= 192; i++) {
      final at = start.add(Duration(minutes: 15 * i));
      final value = i <= 96 ? 18.0 + i * 0.5 : 66.0 + (i - 96) * 0.5;
      samples.add('{"timestamp": "${at.toIso8601String()}", "value": $value}');
    }
    return '[${samples.join(',')}]';
  }

  PegelClient client({
    String? level,
    bool levelFails = false,
    bool stationsFail = false,
  }) => PegelClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/stations.json')) {
        return stationsFail ? respond('', 503) : respond(stationsFixture, 200);
      }
      if (path.endsWith('/measurements.json')) return respond(series(), 200);
      return levelFails
          ? respond('', 503)
          : respond(level ?? levelFixture, 200);
    }),
  );

  Future<void> show(
    WidgetTester tester, {
    PegelClient? pegel,
    DateTime? now,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PegelScreen(
          client: pegel ?? client(),
          now: now ?? DateTime(2026, 9, 10, 18, 20),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('with no gauge chosen', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    testWidgets('it says so and explains which one to pick', (tester) async {
      // The upstream point is the whole reason this is a choice and not a
      // lookup, so it has to be on the screen where the choice is made.
      await show(tester);

      expect(find.text('Noch kein Pegel gewählt.'), findsOneWidget);
      expect(find.textContaining('flussaufwärts'), findsOneWidget);
    });

    testWidgets('it names its source and its limits', (tester) async {
      // Federal waterways only. Somebody whose river is not in the list
      // should learn why from the screen rather than concluding the app
      // is broken.
      await show(tester);

      expect(find.textContaining('Bundeswasserstraßen'), findsOneWidget);
    });

    testWidgets('picking one searches by gauge and by waterway', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.text('Pegel wählen'));
      await tester.pumpAndSettle();

      expect(find.text('KÖLN'), findsOneWidget);
      expect(find.text('ST.PAULI'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'elbe');
      await tester.pumpAndSettle();

      expect(find.text('ST.PAULI'), findsOneWidget);
      expect(find.text('KÖLN'), findsNothing);
    });

    testWidgets('a chosen gauge is then shown with its reading', (
      tester,
    ) async {
      await show(tester);
      await tester.tap(find.text('Pegel wählen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('KÖLN'));
      await tester.pumpAndSettle();

      expect(find.text('66 cm'), findsOneWidget);
    });

    testWidgets('an unreachable gauge list says what is missing', (
      tester,
    ) async {
      await show(tester, pegel: client(stationsFail: true));
      await tester.tap(find.text('Pegel wählen'));
      await tester.pumpAndSettle();

      expect(find.textContaining('einmal eine Verbindung'), findsOneWidget);
    });
  });

  group('with a gauge chosen', () {
    setUp(
      () => SharedPreferences.setMockInitialValues({
        'pegelStation':
            '{"uuid":"koeln","shortname":"KÖLN","water":"RHEIN","km":688.0}',
      }),
    );

    testWidgets('the level, its band and its trend are all shown', (
      tester,
    ) async {
      await show(tester);

      expect(find.text('66 cm'), findsOneWidget);
      // 66 is below the lowest ever measured here, 69.
      expect(find.text('Niedriger als je gemessen'), findsOneWidget);
      expect(find.textContaining('Steigend'), findsOneWidget);
    });

    testWidgets('the reference values are listed, shipping figures not', (
      tester,
    ) async {
      // GlW is in the same list and in centimetres, but it is a shipping
      // figure and comparing a water level against it says nothing.
      await show(tester);

      expect(find.text('Mittelwasser'), findsOneWidget);
      expect(find.text('297 cm'), findsOneWidget);
      expect(find.text('Mittleres Hochwasser'), findsOneWidget);
      expect(find.text('1069 cm'), findsOneWidget);
      expect(find.text('139 cm'), findsNothing, reason: 'GlW');
    });

    testWidgets('it refuses to imply a warning level', (tester) async {
      // Meldestufen are the states' and are not in this data. Without
      // this sentence a household could read "Hochwasser" as official.
      await show(tester);

      expect(find.textContaining('Keine Warnstufe'), findsOneWidget);
    });

    testWidgets('a stale reading is marked as stale', (tester) async {
      // Inland gauges report every fifteen minutes, so an hour of silence
      // is the app not reaching the service.
      await show(tester, now: DateTime(2026, 9, 10, 22));

      expect(find.textContaining('Älter als eine Stunde'), findsOneWidget);
    });

    testWidgets('a failed fetch shows the kept value and says so', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'pegelStation':
            '{"uuid":"koeln","shortname":"KÖLN","water":"RHEIN","km":688.0}',
        'pegelLastReading':
            '{"stationName":"KÖLN","water":"RHEIN","centimetres":712.0,'
            '"measuredAt":"2026-09-10T16:15:00Z","changeOverDay":30.0,'
            '"references":{"MHW":725.0,"MW":297.0}}',
      });

      await show(tester, pegel: client(levelFails: true));

      expect(find.text('712 cm'), findsOneWidget);
      expect(find.textContaining('letzte abgerufene Wert'), findsOneWidget);
    });

    testWidgets('a gauge with no references says the number has no scale', (
      tester,
    ) async {
      await show(
        tester,
        pegel: client(
          level:
              '{"shortname":"W","unit":"cm","currentMeasurement":'
              '{"timestamp":"2026-09-10T18:15:00+02:00","value":412.0}}',
        ),
      );

      expect(find.text('412 cm'), findsOneWidget);
      expect(find.textContaining('ohne Maßstab'), findsOneWidget);
      expect(find.text('Nicht einzuordnen'), findsOneWidget);
    });

    testWidgets('the screen meets the accessibility guidelines', (
      tester,
    ) async {
      await show(tester);
      await expectAccessible(tester);
    });

    testWidgets('the screen survives twice the font size', (tester) async {
      useLargeText(tester);
      await show(tester);
    });
  });
}
