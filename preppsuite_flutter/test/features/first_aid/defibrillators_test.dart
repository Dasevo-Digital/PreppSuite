import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/defibrillator_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Defibrillators from OpenStreetMap, kept for the day without network
/// (#117).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final answer = jsonEncode({
    'elements': [
      {
        'type': 'node',
        'id': 2,
        'lat': 52.2807,
        'lon': 10.5435,
        'tags': {
          'emergency': 'defibrillator',
          'defibrillator:location': 'Im CampusGym neben der Tür',
          'indoor': 'yes',
        },
      },
      {
        'type': 'node',
        'id': 1,
        'lat': 52.2733,
        'lon': 10.5254,
        'tags': {
          'emergency': 'defibrillator',
          'defibrillator:location': 'Neben Raum 143',
          'defibrillator:location:en': 'Next to room 143',
          'level': '1',
          'access': 'customers',
        },
      },
    ],
  });

  test('the nearest comes first', () async {
    String? query;
    final client = DefibrillatorClient(
      retryDelay: Duration.zero,
      httpClient: MockClient((request) async {
        query = request.bodyFields['data'];
        // overpass-api.de answers Dart's own user agent with 406.
        expect(request.headers['User-Agent'], 'PreppSuite/1.0');
        return http.Response.bytes(utf8.encode(answer), 200);
      }),
    );
    final found = await client.near(52.2689, 10.5268);
    expect(query, contains('"emergency"="defibrillator"'));
    expect(query, contains('around:2000,52.2689,10.5268'));
    expect(found.map((d) => d.id), [1, 2]);
    expect(found.first.locationIn('en'), 'Next to room 143');
    expect(found.first.locationIn('de'), 'Neben Raum 143');
    expect(found.first.restricted, isTrue);
    expect(found.last.indoor, isTrue);
  });

  test('distance and direction', () {
    // About 445 m north of the starting point.
    expect(distanceMetres(52.0, 10.0, 52.004, 10.0), closeTo(445, 2));
    expect(compassOctant(52.0, 10.0, 52.004, 10.0), 0);
    expect(compassOctant(52.0, 10.0, 52.0, 10.01), 2);
    expect(compassOctant(52.0, 10.0, 51.99, 9.99), 5);
  });

  test('a search is kept', () async {
    final search = DefibrillatorSearch(
      latitude: 52.2689,
      longitude: 10.5268,
      checkedAt: DateTime.utc(2026, 10, 6),
      found: const [
        Defibrillator(
          id: 1,
          latitude: 52.2733,
          longitude: 10.5254,
          tags: {'defibrillator:location': 'Neben Raum 143'},
        ),
      ],
    );
    await const DefibrillatorStore().save(search);
    final kept = await const DefibrillatorStore().load();
    expect(kept!.found.single.locationIn('de'), 'Neben Raum 143');
  });

  testWidgets('112 comes first, then the kept list', (tester) async {
    await const DefibrillatorStore().save(
      DefibrillatorSearch(
        latitude: 52.2689,
        longitude: 10.5268,
        placeName: 'Braunschweig',
        checkedAt: DateTime(2026, 10, 6),
        found: const [
          Defibrillator(
            id: 1,
            latitude: 52.2733,
            longitude: 10.5254,
            tags: {'defibrillator:location': 'Neben Raum 143', 'level': '1'},
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DefibrillatorScreen(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('zuerst 112'), findsOneWidget);
    expect(find.textContaining('Braunschweig'), findsOneWidget);
    expect(find.text('Defibrillator · 500 m nördlich'), findsOneWidget);
    expect(find.textContaining('Neben Raum 143'), findsOneWidget);
    expect(find.textContaining('Etage: 1'), findsOneWidget);
  });
}
