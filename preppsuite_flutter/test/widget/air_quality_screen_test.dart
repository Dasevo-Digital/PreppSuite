import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_level.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_store.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/air_quality_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

const _station = AirQualityStation(
  id: '513',
  name: 'Braunschweig',
  state: 'Niedersachsen',
  setting: 'städtisches Gebiet',
);

AirQualityReading _reading({
  required AirQualityClass level,
  DateTime? at,
  bool incomplete = false,
}) => AirQualityReading(
  stationId: '513',
  measuredAt: at ?? DateTime(2026, 9, 4, 9),
  level: level,
  incomplete: incomplete,
  components: [
    AirQualityComponent(
      id: 3,
      code: 'O₃',
      unit: 'µg/m³',
      value: 67,
      level: level,
    ),
    const AirQualityComponent(
      id: 5,
      code: 'NO₂',
      unit: 'µg/m³',
      value: 5,
      level: AirQualityClass.veryGood,
    ),
  ],
);

class _FakeClient implements AirQualityClient {
  _FakeClient({this.reading, this.fails = false});

  final AirQualityReading? reading;
  final bool fails;
  var readingCalls = 0;

  @override
  Future<AirQualityReading?> fetchReading(
    String stationId, {
    DateTime? now,
  }) async {
    readingCalls++;
    if (fails) throw const AirQualityException(503);
    return reading;
  }

  @override
  Future<List<AirQualityStation>> fetchStations({DateTime? now}) async =>
      const [_station];

  @override
  Future<Map<int, List<AirQualityThreshold>>> fetchThresholds() async => const {
    3: [
      AirQualityThreshold(level: AirQualityClass.good, min: 61, max: 120),
    ],
  };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(
    WidgetTester tester, {
    required _FakeClient client,
    DateTime? now,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AirQualityScreen(client: client, now: now),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing chosen it asks for a station', (tester) async {
    await show(tester, client: _FakeClient());

    expect(find.text('Noch keine Messstation gewählt'), findsOneWidget);
    expect(find.text('Messstation wählen'), findsOneWidget);
    // Said before anything else: this is a measurement, not a warning.
    expect(find.textContaining('keine Warnung'), findsOneWidget);
  });

  testWidgets('a chosen station shows the class in the UBA\'s words', (
    tester,
  ) async {
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(reading: _reading(level: AirQualityClass.good)),
      now: DateTime(2026, 9, 4, 10),
    );

    expect(find.text('Braunschweig'), findsOneWidget);
    expect(find.text('Gut'), findsWidgets);
    // Which pollutant it came from, because the index is the worst of them.
    expect(find.textContaining('Ausschlaggebend: O₃'), findsOneWidget);
    // And the UBA's own span for that class.
    expect(find.textContaining('61 bis 120'), findsOneWidget);
  });

  testWidgets('an old reading is called old', (tester) async {
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(reading: _reading(level: AirQualityClass.good)),
      now: DateTime(2026, 9, 4, 16),
    );

    expect(find.textContaining('über drei Stunden alt'), findsOneWidget);
  });

  testWidgets('a partial hour says so rather than passing for the whole', (
    tester,
  ) async {
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(
        reading: _reading(level: AirQualityClass.moderate, incomplete: true),
      ),
      now: DateTime(2026, 9, 4, 10),
    );

    expect(find.textContaining('Nicht alle Schadstoffe'), findsOneWidget);
  });

  testWidgets('a failed fetch keeps the last reading and says so', (
    tester,
  ) async {
    await const AirQualityStore().saveStation(_station);
    await const AirQualityStore().saveReading(
      _reading(level: AirQualityClass.poor),
    );
    await show(
      tester,
      client: _FakeClient(fails: true),
      now: DateTime(2026, 9, 4, 10),
    );

    expect(find.text('Schlecht'), findsWidgets);
    expect(find.textContaining('Zuletzt gespeicherter Wert'), findsOneWidget);
  });

  testWidgets('no health advice of this app\'s own is given', (tester) async {
    // The UBA publishes its behaviour advice only as images; paraphrasing
    // somebody else's health advice is what this app refuses to do.
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(reading: _reading(level: AirQualityClass.veryPoor)),
      now: DateTime(2026, 9, 4, 10),
    );

    expect(
      find.textContaining('keine eigenen Gesundheitshinweise'),
      findsOneWidget,
    );
  });

  testWidgets('the screen meets the accessibility guidelines', (tester) async {
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(reading: _reading(level: AirQualityClass.good)),
      now: DateTime(2026, 9, 4, 10),
    );
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await const AirQualityStore().saveStation(_station);
    await show(
      tester,
      client: _FakeClient(reading: _reading(level: AirQualityClass.good)),
      now: DateTime(2026, 9, 4, 10),
    );
  });
}
