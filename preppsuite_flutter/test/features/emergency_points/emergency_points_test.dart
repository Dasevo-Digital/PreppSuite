import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/emergency_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/presentation/emergency_points_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Emergency wells, help points and sirens from OpenStreetMap, kept for
/// the day without network (#127, #128).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Map<String, Object?> node(
    int id,
    double lat,
    double lon,
    Map<String, String> tags,
  ) => {'type': 'node', 'id': id, 'lat': lat, 'lon': lon, 'tags': tags};

  test('one request, each kind with its own radius', () async {
    String? query;
    final client = EmergencyPointClient(
      retryDelay: Duration.zero,
      httpClient: MockClient((request) async {
        query = request.bodyFields['data'];
        expect(request.headers['User-Agent'], 'PreppSuite/1.0');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'elements': [
                node(1, 52.0, 10.0, {'emergency': 'siren'}),
              ],
            }),
          ),
          200,
        );
      }),
    );
    final found = await client.near(52.0, 10.0);
    expect(query, contains('"emergency"="drinking_water"](around:5000,'));
    expect(query, contains('"emergency"="disaster_help_point"](around:10000,'));
    expect(query, contains('"emergency"="siren"](around:2000,'));
    // An out per kind: under one shared limit Berlin's wells pushed out
    // everything else.
    expect('out 2000;'.allMatches(query!).length, 3);
    expect(found.single.kind, EmergencyPointKind.siren);
  });

  test('the nearest of each kind, and no more than kept', () {
    final wells = [
      for (var i = 0; i < 40; i++)
        node(100 + i, 52.0 + (40 - i) * 0.001, 10.0, {
          'emergency': 'drinking_water',
        }),
    ];
    final body = jsonEncode({
      'elements': [
        ...wells,
        node(2, 52.02, 10.0, {'emergency': 'disaster_help_point'}),
        node(3, 52.001, 10.0, {'emergency': 'disaster_help_point'}),
        node(4, 52.0, 10.0, {'emergency': 'fire_hydrant'}),
        {'type': 'way', 'id': 5},
      ],
    });
    final found = parseEmergencyPoints(body, 52.0, 10.0);
    final kept = [
      for (final point in found)
        if (point.kind == EmergencyPointKind.well) point,
    ];
    expect(kept.length, EmergencyPointKind.well.kept);
    // Nearest first: the last ones in the answer are nearest here.
    expect(kept.first.id, 139);
    expect(
      [
        for (final point in found)
          if (point.kind == EmergencyPointKind.helpPoint) point.id,
      ],
      [3, 2],
    );
    expect(found.any((point) => point.id == 4), isFalse);
  });

  test('what a point says about itself', () {
    // Berlin maps its Katastrophenschutz-Leuchttürme with contact:*.
    const helpPoint = EmergencyPoint(
      id: 1,
      kind: EmergencyPointKind.helpPoint,
      latitude: 52.5,
      longitude: 13.4,
      tags: {
        'name': 'Bezirk Mitte (Rathaus Mitte)',
        'contact:street': 'Karl-Marx-Allee',
        'contact:housenumber': '31',
      },
    );
    expect(helpPoint.address, 'Karl-Marx-Allee 31');

    const well = EmergencyPoint(
      id: 2,
      kind: EmergencyPointKind.well,
      latitude: 52.5,
      longitude: 13.4,
      tags: {
        'addr:full': 'Corinthstraße 20',
        'ref': '8',
        'pump:status': 'broken',
      },
    );
    expect(well.address, 'Corinthstraße 20');
    expect(well.ref, '8');
    expect(well.outOfOrder, isTrue);

    EmergencyPoint siren(String range) => EmergencyPoint(
      id: 3,
      kind: EmergencyPointKind.siren,
      latitude: 0,
      longitude: 0,
      tags: {'siren:range': range},
    );
    expect(siren('600').sirenRangeMetres, 600);
    expect(siren('600 m').sirenRangeMetres, 600);
    expect(siren('1,5 km').sirenRangeMetres, 1500);
    expect(siren('weit').sirenRangeMetres, isNull);
  });

  test('whether the siren is heard', () {
    expect(sirenReach(null), SirenReach.none);
    expect(sirenReach(350), SirenReach.likely);
    expect(sirenReach(400), SirenReach.likely);
    expect(sirenReach(700), SirenReach.maybe);
    expect(sirenReach(850), SirenReach.maybe);
    expect(sirenReach(1200), SirenReach.unlikely);
    // A range mapped for that siren overrides the rule of thumb, both
    // ways.
    expect(sirenReach(1200, rangeMetres: 1500), SirenReach.likely);
    expect(sirenReach(350, rangeMetres: 300), SirenReach.unlikely);
  });

  test('a farther siren with a mapped range can be the answer', () {
    final search = EmergencyPointSearch(
      latitude: 52.0,
      longitude: 10.0,
      checkedAt: DateTime.utc(2026, 10, 8),
      found: const [
        // About 1.1 km, nothing mapped: unlikely on its own.
        EmergencyPoint(
          id: 1,
          kind: EmergencyPointKind.siren,
          latitude: 52.01,
          longitude: 10.0,
        ),
        // About 1.8 km, but mapped to reach two.
        EmergencyPoint(
          id: 2,
          kind: EmergencyPointKind.siren,
          latitude: 52.016,
          longitude: 10.0,
          tags: {'siren:range': '2000'},
        ),
      ],
    );
    expect(search.sirenReachHere, SirenReach.likely);
  });

  test('a search is kept', () async {
    final search = EmergencyPointSearch(
      latitude: 52.52,
      longitude: 13.405,
      placeName: 'Berlin',
      checkedAt: DateTime.utc(2026, 10, 8),
      found: const [
        EmergencyPoint(
          id: 1,
          kind: EmergencyPointKind.well,
          latitude: 52.521,
          longitude: 13.405,
          tags: {'ref': '199'},
        ),
      ],
    );
    await const EmergencyPointStore().save(search);
    final kept = await const EmergencyPointStore().load();
    expect(kept!.placeName, 'Berlin');
    expect(kept.found.single.kind, EmergencyPointKind.well);
    expect(kept.found.single.ref, '199');
  });

  Future<void> show(WidgetTester tester, EmergencyPointSearch search) async {
    await const EmergencyPointStore().save(search);
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EmergencyPointsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the siren first, then wells and help points', (tester) async {
    await show(
      tester,
      EmergencyPointSearch(
        latitude: 52.0,
        longitude: 10.0,
        placeName: 'Musterstadt',
        checkedAt: DateTime(2026, 10, 8),
        found: const [
          EmergencyPoint(
            id: 1,
            kind: EmergencyPointKind.well,
            latitude: 52.0045,
            longitude: 10.0,
            tags: {'addr:full': 'Corinthstraße 20', 'ref': '8'},
          ),
          EmergencyPoint(
            id: 2,
            kind: EmergencyPointKind.helpPoint,
            latitude: 52.0,
            longitude: 10.02,
            tags: {'name': 'Rathaus'},
          ),
          EmergencyPoint(
            id: 3,
            kind: EmergencyPointKind.siren,
            latitude: 52.003,
            longitude: 10.0,
          ),
        ],
      ),
    );
    expect(find.textContaining('Musterstadt'), findsOneWidget);
    expect(find.text('Sirene in Hörweite?'), findsOneWidget);
    expect(
      find.textContaining('330 m nördlich. Sie ist dort sehr wahrscheinlich'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Notbrunnen · 500 m nördlich'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Notbrunnen · 500 m nördlich'), findsOneWidget);
    expect(find.textContaining('Corinthstraße 20'), findsOneWidget);
    expect(find.textContaining('Nr. 8'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rathaus · 1,4 km östlich'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rathaus · 1,4 km östlich'), findsOneWidget);
  });

  testWidgets('no siren mapped says what that does and does not mean', (
    tester,
  ) async {
    await show(
      tester,
      EmergencyPointSearch(
        latitude: 52.0,
        longitude: 10.0,
        checkedAt: DateTime(2026, 10, 8),
        found: const [],
      ),
    );
    expect(find.textContaining('keine Sirene eingetragen'), findsOneWidget);
    expect(find.textContaining('Warntag'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('kein Notbrunnen eingetragen'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('kein Notbrunnen eingetragen'), findsOneWidget);
  });
}
