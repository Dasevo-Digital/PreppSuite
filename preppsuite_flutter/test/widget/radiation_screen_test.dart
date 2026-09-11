import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_store.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/radiation_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Watching a gamma probe.
///
/// The figures are Hausach in the Black Forest as published: a weekly
/// median of 0.157 µSv/h and 0.162 right now. Those two numbers are the
/// whole feature — 0.162 against the national ceiling of 0.2 says
/// nothing, 0.162 against this probe's own 0.157 says "ordinary", and the
/// screen must never show the number without the context.
void main() {
  http.Response respond(String body, int status) => http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json;charset=UTF-8'},
  );

  const stations = '''
{"type": "FeatureCollection", "features": [
  {"type": "Feature", "geometry": {"type": "Point",
    "coordinates": [8.15, 48.28]},
   "properties": {"kenn": "083170410", "name": "Hausach", "plz": "77756",
     "site_status": 1, "height_above_sea": 230,
     "end_measure": "2026-09-11T06:00:00Z", "value": 0.162,
     "value_terrestrial": 0.117, "value_cosmic": 0.045, "validated": 1}},
  {"type": "Feature", "geometry": {"type": "Point",
    "coordinates": [10.52, 52.26]},
   "properties": {"kenn": "031010001", "name": "Braunschweig",
     "plz": "38100", "site_status": 1, "height_above_sea": 75,
     "end_measure": "2026-09-11T06:00:00Z", "value": 0.088,
     "validated": 1}}
]}''';

  /// A week of hourly samples around [median], with the newest at
  /// [newest] — which is how a rain spike is put on top of an otherwise
  /// ordinary series.
  String series({double median = 0.157, double? newest, int validated = 1}) {
    final start = DateTime.utc(2026, 9, 4, 7);
    final samples = <String>[];
    for (var i = 0; i < 168; i++) {
      final at = start.add(Duration(hours: i));
      final last = i == 167;
      final value = last ? (newest ?? median) : median;
      samples.add(
        '{"type": "Feature", "properties": {'
        '"end_measure": "${at.toIso8601String()}", '
        '"value": $value, "validated": ${last ? validated : 1}}}',
      );
    }
    return '{"type": "FeatureCollection", "features": [${samples.join(',')}]}';
  }

  RadiationClient client({
    String? readings,
    bool seriesFails = false,
    bool stationsFail = false,
  }) => RadiationClient(
    httpClient: MockClient((request) async {
      final layer = request.url.queryParameters['typeName'] ?? '';
      if (layer.contains('timeseries')) {
        return seriesFails
            ? respond('', 503)
            : respond(readings ?? series(), 200);
      }
      return stationsFail ? respond('', 503) : respond(stations, 200);
    }),
  );

  Future<void> show(
    WidgetTester tester, {
    RadiationClient? radiation,
    DateTime? now,
  }) async {
    await tester.binding.setSurfaceSize(const Size(500, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadiationScreen(client: radiation ?? client(), now: now),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// Walks the picker, which is also the only way to choose one.
  Future<void> choose(WidgetTester tester, String name) async {
    await tester.tap(find.text('Messstelle wählen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing is shown until a station is chosen', (tester) async {
    await show(tester);

    expect(find.text('Noch keine Messstelle gewählt'), findsOneWidget);
    // And it says what it is not, before it says any number at all.
    expect(find.textContaining('keine Warnung'), findsWidgets);
  });

  testWidgets('the source and its licence are named', (tester) async {
    // Datenlizenz Deutschland 2.0 asks for attribution, and it is the
    // reason this data may be in the app.
    await show(tester);

    expect(find.textContaining('Bundesamt für Strahlenschutz'), findsWidgets);
    expect(find.textContaining('Datenlizenz Deutschland'), findsWidgets);
  });

  testWidgets('a chosen station shows its value with its own baseline', (
    tester,
  ) async {
    // The reading comes from the station's own series, so the newest
    // sample is the value on screen — 0.162 now against a weekly median
    // of 0.157, which is Hausach on an ordinary day.
    await show(tester, radiation: client(readings: series(newest: 0.162)));
    await choose(tester, 'Hausach');

    expect(find.textContaining('0,162 µSv/h'), findsOneWidget);
    expect(find.text('Gewöhnlich für diese Messstelle'), findsOneWidget);
    expect(
      find.text('Üblich an dieser Messstelle: 0,157 µSv/h'),
      findsOneWidget,
    );
  });

  testWidgets('a rain spike is named as rain, not as an event', (
    tester,
  ) async {
    // Three quarters up on the baseline — a shower. The BfS's own
    // reading of this is weather, and the screen has to say so or the
    // number frightens somebody for nothing.
    await show(tester, radiation: client(readings: series(newest: 0.28)));
    await choose(tester, 'Hausach');

    expect(
      find.text('Erhöht — das ist nach Regen der Normalfall'),
      findsOneWidget,
    );
    expect(find.textContaining('Radon-Zerfallsprodukte'), findsOneWidget);
  });

  testWidgets('beyond the weather factor it says so, and still not more', (
    tester,
  ) async {
    await show(tester, radiation: client(readings: series(newest: 0.9)));
    await choose(tester, 'Hausach');

    expect(find.text('Über dem, was Wetter erklärt'), findsOneWidget);
    // The BfS's condition, quoted rather than turned into an alarm.
    expect(find.textContaining('einen Tag oder länger'), findsOneWidget);
    expect(find.textContaining('keine Warnung'), findsWidgets);
  });

  testWidgets('an unchecked raw value is marked as one', (tester) async {
    await show(
      tester,
      radiation: client(readings: series(validated: 0)),
    );
    await choose(tester, 'Hausach');

    expect(find.textContaining('Ungeprüfter Rohwert'), findsOneWidget);
  });

  testWidgets('an old reading is shown as old rather than as current', (
    tester,
  ) async {
    await show(
      tester,
      radiation: client(),
      now: DateTime.utc(2026, 9, 11, 20),
    );
    await choose(tester, 'Hausach');

    expect(find.textContaining('Älter als zwei Stunden'), findsOneWidget);
  });

  testWidgets('a failed fetch keeps the last reading and says so', (
    tester,
  ) async {
    await show(tester, radiation: client(readings: series(newest: 0.162)));
    await choose(tester, 'Hausach');
    expect(find.textContaining('0,162 µSv/h'), findsOneWidget);

    // A second screen over the same preferences, with the service down.
    // The key is what makes it a second screen: without one Flutter
    // reuses the element, `initState` never runs again, and the test
    // would pass on the first screen's state.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RadiationScreen(
          key: UniqueKey(),
          client: client(seriesFails: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Letzter bekannter Wert'), findsOneWidget);
    expect(find.textContaining('0,162 µSv/h'), findsOneWidget);
  });

  testWidgets('the picker searches by place and by postal code', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Messstelle wählen'));
    await tester.pumpAndSettle();

    expect(find.text('Hausach'), findsOneWidget);
    expect(find.text('Braunschweig'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '381');
    await tester.pumpAndSettle();
    expect(find.text('Braunschweig'), findsOneWidget);
    expect(find.text('Hausach'), findsNothing);
  });

  testWidgets('a picker that cannot reach the service does not crash', (
    tester,
  ) async {
    // The gauge picker crashed here once, sorting a const empty list.
    await show(tester, radiation: client(stationsFail: true));
    await tester.tap(find.text('Messstelle wählen'));
    await tester.pumpAndSettle();

    expect(find.textContaining('konnten nicht geladen werden'), findsWidgets);
  });

  testWidgets('the chosen station survives a restart', (tester) async {
    await show(tester);
    await choose(tester, 'Braunschweig');

    expect(await const RadiationStore().loadStation(), isNotNull);
    expect((await const RadiationStore().loadStation())!.name, 'Braunschweig');
  });

  testWidgets('the radiation screen meets the accessibility guidelines', (
    tester,
  ) async {
    await show(tester);
    await choose(tester, 'Hausach');
    await expectAccessible(tester);
  });

  testWidgets('the radiation screen survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(tester);
    await choose(tester, 'Hausach');
  });
}
