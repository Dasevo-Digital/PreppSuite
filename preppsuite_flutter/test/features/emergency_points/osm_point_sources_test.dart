import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/core/error_text.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/emergency_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/osm_point_sources.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/features/shelters/application/overpass_shelter_client.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations_de.dart';

/// Rows as QLever sends them, cut from its answer for Braunschweig on
/// 2026-11-12, with an escaped line break and quote put in.
const _tsv =
    '?node\t?wkt\t?key\t?value\n'
    '<https://www.openstreetmap.org/node/10>\tPOINT(10.528850 52.276314)\t'
    '<https://www.openstreetmap.org/wiki/Key:emergency>\t"defibrillator"\n'
    '<https://www.openstreetmap.org/node/10>\tPOINT(10.528850 52.276314)\t'
    '<https://www.openstreetmap.org/wiki/Key:defibrillator:location>\t'
    r'"Kaufland \"Info\"\nlinks vom Eingang"'
    '\n'
    '<https://www.openstreetmap.org/node/10>\tPOINT(10.528850 52.276314)\t'
    '<https://www.openstreetmap.org/wiki/Key:operator>\t'
    r'"Björn Steiger Stiftung"'
    '\n'
    '<https://www.openstreetmap.org/node/11>\tPOINT(10.600000 52.400000)\t'
    '<https://www.openstreetmap.org/wiki/Key:emergency>\t"defibrillator"\n'
    '<https://www.openstreetmap.org/node/20>\tPOINT(10.527000 52.270000)\t'
    '<https://www.openstreetmap.org/wiki/Key:emergency>\t"siren"\n'
    '<https://www.openstreetmap.org/node/21>\tPOINT(10.530000 52.272000)\t'
    '<https://www.openstreetmap.org/wiki/Key:emergency>\t"drinking_water"\n'
    '<https://www.openstreetmap.org/node/21>\tPOINT(10.530000 52.272000)\t'
    '<https://www.openstreetmap.org/wiki/Key:ref>\t"BS-12"\n'
    '<https://www.openstreetmap.org/node/30>\tPOINT(10.5 52.27)\t'
    '<https://www.openstreetmap.org/wiki/Key:emergency>\t"fire_hydrant"\n';

bool _isOverpass(http.BaseRequest request) =>
    request.url.host.contains('overpass');

bool _isQlever(http.BaseRequest request) => request.url.host == 'qlever.dev';

void main() {
  group('QLever (#366)', () {
    test('rows become points, with their tags read as written', () {
      final set = parseQleverPoints(_tsv);

      expect(set.defibrillators.map((d) => d.id), unorderedEquals([10, 11]));
      final kaufland = set.defibrillators.firstWhere((d) => d.id == 10);
      expect(kaufland.latitude, closeTo(52.276314, 1e-6));
      expect(kaufland.longitude, closeTo(10.528850, 1e-6));
      expect(
        kaufland.tags['defibrillator:location'],
        'Kaufland "Info"\nlinks vom Eingang',
      );
      expect(kaufland.tags['operator'], 'Björn Steiger Stiftung');

      expect(set.points.map((p) => p.kind), [
        EmergencyPointKind.siren,
        EmergencyPointKind.well,
      ]);
      expect(set.points.last.ref, 'BS-12');
      // A hydrant is `emergency=*` too, and not one of the four.
      expect(set.length, 4);
    });

    test('an answer that is not the table is not an empty table', () {
      // An empty table would say there is no defibrillator anywhere near.
      expect(
        () => parseQleverPoints('<html><body>503</body></html>'),
        throwsA(isA<QleverException>()),
      );
      expect(parseQleverPoints('?node\t?wkt\t?key\t?value\n').length, 0);
    });

    test('only the tags the screens read are kept', () {
      final tags = keptTags({
        'emergency': 'defibrillator',
        'name': 'Rathaus',
        'phone': '+49 531 0',
        'image': 'https://example.org/aed.jpg',
        'defibrillator:location': 'Foyer',
      });
      expect(tags.keys.toSet(), {
        'emergency',
        'name',
        'defibrillator:location',
      });
    });

    test('the query asks for the box and the four kinds', () {
      final query = qleverQuery(
        const GeoBoundingBox(west: 5.8, south: 47.2, east: 15.1, north: 55.1),
      );
      for (final needle in [
        '"defibrillator"',
        '"drinking_water"',
        '"disaster_help_point"',
        '"siren"',
        '>= 5.80000',
        '<= 15.10000',
        '>= 47.20000',
        '<= 55.10000',
        'osmkey:siren:range',
      ]) {
        expect(query, contains(needle));
      }
    });

    test('the box around a search circle holds the whole circle', () {
      final circle = gridCircle(52.2689, 10.5268, 2000);
      final box = boxAroundCircle(circle);
      final centreLat = double.parse(circle.latitude);
      final centreLon = double.parse(circle.longitude);
      // Two kilometres north, south, east and west of the centre.
      expect(
        distanceMetres(centreLat, centreLon, box.north, centreLon),
        greaterThanOrEqualTo(circle.radiusMetres - 1),
      );
      expect(
        distanceMetres(centreLat, centreLon, centreLat, box.east),
        greaterThanOrEqualTo(circle.radiusMetres - 1),
      );
      expect(box.south, lessThan(52.25));
      expect(box.west, lessThan(10.50));
    });
  });

  group('Overpass instances (#366)', () {
    test('three of them, none where a home search area should not go', () {
      expect(OverpassShelterClient.endpoints, hasLength(3));
      expect(
        OverpassShelterClient.endpoints,
        contains('https://overpass.private.coffee/api/interpreter'),
      );
      for (final endpoint in OverpassShelterClient.endpoints) {
        final host = Uri.parse(endpoint).host;
        expect(host, isNot(endsWith('.ru')));
        expect(host, isNot(contains('mail.ru')));
      }
    });

    test('one instance out of reach is not "no connection"', () async {
      // The first one's name no longer resolves, the others answer 502:
      // the network works, the service does not.
      var asked = 0;
      final client = MockClient((request) async {
        asked++;
        if (request.url.host == 'overpass-api.de') {
          throw const SocketException('Failed host lookup');
        }
        return http.Response('', 502);
      });
      await expectLater(
        askOverpass(client, '[out:json];', retryDelay: Duration.zero),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            false,
          ),
        ),
      );
      expect(asked, 3);
    });

    test('a timeout behind one that is unreachable is not either', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'overpass-api.de') {
          throw TimeoutException('no answer');
        }
        throw const SocketException('Failed host lookup');
      });
      // The last error is the socket one; what counts is that an instance
      // took the request at all.
      await expectLater(
        askOverpass(client, '[out:json];', retryDelay: Duration.zero),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            false,
          ),
        ),
      );
    });

    test('none in reach is "no connection", on the screen too', () async {
      final client = MockClient(
        (request) async => throw const SocketException('Network unreachable'),
      );
      Object? caught;
      try {
        await askOverpass(client, '[out:json];', retryDelay: Duration.zero);
      } on OverpassException catch (error) {
        caught = error;
      }
      expect((caught! as OverpassException).noNetwork, isTrue);
      expect(
        describeError(AppLocalizationsDe(), caught),
        AppLocalizationsDe().errorNoConnection,
      );
      expect(
        describeError(AppLocalizationsDe(), const OverpassException(502)),
        AppLocalizationsDe().errorServiceUnavailable,
      );
    });
  });

  group('a search near a place when every Overpass instance fails', () {
    test('defibrillators come from QLever, nearest first', () async {
      String? sparql;
      final client = DefibrillatorClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (_isOverpass(request)) return http.Response('', 502);
          expect(_isQlever(request), isTrue);
          expect(request.headers['User-Agent'], 'PreppSuite/1.0');
          sparql = request.bodyFields['query'];
          return http.Response.bytes(utf8.encode(_tsv), 200);
        }),
      );

      final found = await client.near(52.2689, 10.5268);

      // Node 11 is fifteen kilometres away; the box was larger than the
      // radius, the list is not.
      expect(found.map((d) => d.id), [10]);
      // The box is drawn round the grid point, not the position itself.
      expect(sparql, isNot(contains('52.2689')));
      expect(sparql, contains('"defibrillator"'));
    });

    test(
      'emergency points come from QLever, each kind in its radius',
      () async {
        final client = EmergencyPointClient(
          retryDelay: Duration.zero,
          httpClient: MockClient((request) async {
            if (_isOverpass(request)) throw TimeoutException('no answer');
            return http.Response.bytes(utf8.encode(_tsv), 200);
          }),
        );

        final found = await client.near(52.2689, 10.5268);

        expect(found.map((p) => (p.id, p.kind)), [
          (21, EmergencyPointKind.well),
          (20, EmergencyPointKind.siren),
        ]);
      },
    );

    test('QLever is asked right after the main instance', () async {
      // On 12 November 2026 the main instance answered 502 at once and
      // the other two not at all: asked in turn, they cost half a minute
      // before QLever was tried.
      final asked = <String>[];
      final client = DefibrillatorClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          asked.add(request.url.host);
          if (_isOverpass(request)) return http.Response('', 502);
          return http.Response.bytes(utf8.encode(_tsv), 200);
        }),
      );

      await client.near(52.2689, 10.5268);

      expect(asked, ['overpass-api.de', 'qlever.dev']);
    });

    test('without any network every way is tried and it says so', () async {
      final asked = <String>[];
      final client = DefibrillatorClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          asked.add(request.url.host);
          throw const SocketException('Network unreachable');
        }),
      );

      await expectLater(
        client.near(52.2689, 10.5268),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            true,
          ),
        ),
      );
      expect(asked, [
        'overpass-api.de',
        'qlever.dev',
        'overpass.private.coffee',
        'overpass.kumi.systems',
      ]);
    });

    test('one name that does not resolve is not "no connection"', () async {
      final client = DefibrillatorClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (request.url.host == 'overpass-api.de') {
            throw const SocketException('Failed host lookup');
          }
          return http.Response('', 503);
        }),
      );

      await expectLater(
        client.near(52.2689, 10.5268),
        throwsA(
          isA<OverpassException>().having(
            (e) => e.noNetwork,
            'noNetwork',
            false,
          ),
        ),
      );
    });

    test('when QLever fails too, the Overpass failure is reported', () async {
      final client = DefibrillatorClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          if (_isOverpass(request)) return http.Response('', 502);
          return http.Response('<html>503</html>', 503);
        }),
      );

      await expectLater(
        client.near(52.2689, 10.5268),
        throwsA(
          isA<OverpassException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.noNetwork, 'noNetwork', false),
        ),
      );
    });
  });

  test('a country box from Overpass, when QLever is the one down', () async {
    String? query;
    final client = MockClient((request) async {
      query = request.bodyFields['data'];
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'elements': [
              {
                'type': 'node',
                'id': 5,
                'lat': 52.27,
                'lon': 10.52,
                'tags': {'emergency': 'disaster_help_point', 'phone': '110'},
              },
              {'type': 'way', 'id': 6},
            ],
          }),
        ),
        200,
      );
    });

    final set = await askOverpassForPoints(
      client,
      const GeoBoundingBox(west: 10, south: 52, east: 11, north: 53),
      retryDelay: Duration.zero,
    );

    expect(query, contains('(52.0,10.0,53.0,11.0)'));
    expect(query, contains('defibrillator|drinking_water'));
    expect(set.points.single.kind, EmergencyPointKind.helpPoint);
    expect(set.points.single.tags.containsKey('phone'), isFalse);
  });
}
