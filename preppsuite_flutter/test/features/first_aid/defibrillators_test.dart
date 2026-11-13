import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/offline_nearby_points.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/core/geolocation_service.dart';
import 'package:preppsuite_flutter/features/first_aid/presentation/defibrillator_screen.dart';
import 'package:preppsuite_flutter/features/shelters/application/overpass_shelter_client.dart';
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
    // Around the grid point, with the radius grown by the most the snap
    // moved it; never the fix itself (#293).
    expect(query, contains(',52.27,10.53);'));
    expect(query, isNot(contains('52.2689')));
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

  group('when no list comes back (#217)', () {
    DefibrillatorClient failing(Object Function() error) => DefibrillatorClient(
      retryDelay: Duration.zero,
      httpClient: MockClient((request) async => throw error()),
    );

    test('no network is told apart from a server that does not answer', () {
      expect(
        failing(() => const SocketException('Failed host lookup')).near(52, 10),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            true,
          ),
        ),
      );
      expect(
        failing(() => TimeoutException('no answer')).near(52, 10),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            false,
          ),
        ),
      );
    });

    // Geocoding answers; only OpenStreetMap's Overpass does not.
    GeolocationService geolocation() => GeolocationService(
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode([
            {'lat': '52.2689', 'lon': '10.5268'},
          ]),
          200,
        ),
      ),
    );

    Future<void> searchAddress(
      WidgetTester tester,
      DefibrillatorClient client, {
      OfflineNearbyPointStore offlinePoints = const OfflineNearbyPointStore(),
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: DefibrillatorScreen(
            client: client,
            geolocation: geolocation(),
            offlinePoints: offlinePoints,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adresse eingeben'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Braunschweig');
      await tester.tap(find.text('Abfragen'));
      await tester.pumpAndSettle();
    }

    testWidgets('no answer and nothing kept says nothing of a last search', (
      tester,
    ) async {
      await searchAddress(
        tester,
        DefibrillatorClient(
          retryDelay: Duration.zero,
          httpClient: MockClient((request) async => http.Response('', 504)),
        ),
      );

      expect(
        find.text(
          'Keiner der Suchdienste für OpenStreetMap hat gerade eine '
          'Antwort geliefert. Bitte später noch einmal versuchen.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Keine Verbindung'), findsNothing);
      expect(find.textContaining('gespeicherte Suche'), findsNothing);
    });

    testWidgets('no network over a kept list says it is the last one', (
      tester,
    ) async {
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
              tags: {'defibrillator:location': 'Neben Raum 143'},
            ),
          ],
        ),
      );

      await searchAddress(
        tester,
        failing(() => const SocketException('Network is unreachable')),
      );

      // With the day it is from (#366): a list from October is not the
      // same answer as one from this morning.
      expect(
        find.text(
          'Keine Verbindung. Gezeigt wird die gespeicherte Suche vom '
          '6. Okt. 2026.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Neben Raum 143'), findsOneWidget);
    });

    testWidgets('OpenStreetMap down: the offline map\'s points, with their '
        'day (#366)', (tester) async {
      await searchAddress(
        tester,
        DefibrillatorClient(
          retryDelay: Duration.zero,
          httpClient: MockClient((request) async => http.Response('', 502)),
        ),
        offlinePoints: _KeptWithMap([
          const Defibrillator(
            id: 7,
            latitude: 52.2733,
            longitude: 10.5254,
            tags: {'defibrillator:location': 'Am Empfang'},
          ),
        ]),
      );

      expect(
        find.text(
          'Keiner der Suchdienste für OpenStreetMap hat gerade eine '
          'Antwort geliefert. Gezeigt werden die mit der Offline-Karte '
          'gespeicherten Punkte, Stand 1. Nov. 2026.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Am Empfang'), findsOneWidget);
      expect(
        find.textContaining('1. Nov. 2026, aus der Offline-Karte'),
        findsOneWidget,
      );
      // The map's points are not kept as the last search: they are kept
      // anyway, and a real search would be lost under them.
      expect(await const DefibrillatorStore().load(), isNull);
    });

    testWidgets('the live answer replaces the offline map\'s points', (
      tester,
    ) async {
      await searchAddress(
        tester,
        DefibrillatorClient(
          retryDelay: Duration.zero,
          httpClient: MockClient(
            (request) async => http.Response.bytes(utf8.encode(answer), 200),
          ),
        ),
        offlinePoints: _KeptWithMap([
          const Defibrillator(
            id: 7,
            latitude: 52.2733,
            longitude: 10.5254,
            tags: {'defibrillator:location': 'Am Empfang'},
          ),
        ]),
      );

      expect(find.textContaining('Am Empfang'), findsNothing);
      expect(find.textContaining('Neben Raum 143'), findsOneWidget);
      expect(find.textContaining('aus der Offline-Karte'), findsNothing);
      expect(find.textContaining('Suchdienste'), findsNothing);
      expect(await const DefibrillatorStore().load(), isNotNull);
    });
  });
}

/// Points kept with an offline map of Braunschweig, fetched on
/// 1 November 2026. Answered without a file: the store itself is tested
/// in `offline_nearby_points_test.dart`, and real file reads do not run
/// in a widget test's clock.
class _KeptWithMap extends OfflineNearbyPointStore {
  _KeptWithMap(this.defibrillators);

  final List<Defibrillator> defibrillators;

  @override
  Future<OfflineNearbyAnswer?> around(
    double latitude,
    double longitude,
  ) async => OfflineNearbyAnswer(
    kept: OfflineNearbyPoints(
      bounds: const GeoBoundingBox(
        west: 10.4,
        south: 52.2,
        east: 10.7,
        north: 52.4,
      ),
      fetchedAt: DateTime(2026, 11, 1, 12),
      defibrillators: defibrillators.length,
      points: 0,
    ),
    defibrillators: defibrillators,
    points: const [],
  );
}
