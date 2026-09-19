import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/features/shelters/application/overpass_shelter_client.dart';

void main() {
  test(
    'fetchShelters parses real captured elements (node with lat/lon, way '
    'with center)',
    () async {
      // Trimmed from a real capture against overpass-api.de/api/interpreter
      // for a Berlin bounding box on 2026-08-14.
      const fixture = '''
{
  "version": 0.6,
  "generator": "Overpass API",
  "elements": [
    {
      "type": "node",
      "id": 294503248,
      "lat": 52.4879449,
      "lon": 13.4220093,
      "tags": {
        "access": "no",
        "building": "bunker",
        "bunker_type": "personnel_shelter",
        "disused": "yes",
        "military": "bunker"
      }
    },
    {
      "type": "way",
      "id": 26763667,
      "center": {"lat": 52.5473549, "lon": 13.3847697},
      "tags": {"military": "bunker", "name": "Flakbunker"}
    }
  ]
}''';

      final client = OverpassShelterClient(
        httpClient: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.body, contains('military'));
          return http.Response(fixture, 200);
        }),
      );

      final bounds = boundingBoxForRadius(const LatLng(52.5, 13.4), 25);
      final features = await client.fetchShelters(bounds);

      expect(features, hasLength(2));
      expect(features[0].lat, 52.4879449);
      expect(features[0].tags['disused'], 'yes');
      // The way's coordinates come from `center`, not top-level lat/lon.
      expect(features[1].lat, 52.5473549);
      expect(features[1].lon, 13.3847697);
      expect(features[1].name, 'Flakbunker');
    },
  );

  final bounds = boundingBoxForRadius(const LatLng(52.5, 13.4), 25);

  const empty = '{"version": 0.6, "elements": []}';

  test(
    'reuses a successful identical query for the short screen cache',
    () async {
      var calls = 0;
      final client = OverpassShelterClient(
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(empty, 200);
        }),
      );

      await client.fetchShelters(bounds);
      await client.fetchShelters(bounds);

      expect(calls, 1);
    },
  );

  test('fetchShelters reports failure on a non-200 response', () async {
    final client = OverpassShelterClient(
      retryDelay: Duration.zero,
      httpClient: MockClient((request) async => http.Response('', 504)),
    );

    await expectLater(
      client.fetchShelters(bounds),
      throwsA(
        isA<OverpassException>().having((e) => e.statusCode, 'status', 504),
      ),
    );
  });

  group('when an instance will not answer', () {
    // `overpass-api.de/api/status` states "Rate limit: 2" — two
    // concurrent queries per address, 429 for the third. Pressing
    // refresh twice was enough to reach it, and every one of these came
    // out as one sentence with no reason in it.
    test(
      'a rate limit is retried on the same instance first',
      () async {
        final asked = <String>[];
        final client = OverpassShelterClient(
          httpClient: MockClient((request) async {
            asked.add(request.url.host);
            return asked.length == 1
                ? http.Response('', 429)
                : http.Response(empty, 200);
          }),
        );

        await client.fetchShelters(bounds);

        expect(asked, ['overpass-api.de', 'overpass-api.de']);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'a busy instance falls through to the mirror',
      () async {
        final asked = <String>[];
        final client = OverpassShelterClient(
          httpClient: MockClient((request) async {
            asked.add(request.url.host);
            return request.url.host == 'overpass-api.de'
                ? http.Response('', 429)
                : http.Response(empty, 200);
          }),
        );

        await client.fetchShelters(bounds);

        expect(asked, [
          'overpass-api.de',
          'overpass-api.de',
          'overpass.kumi.systems',
        ]);
      },
      timeout: const Timeout(Duration(seconds: 40)),
    );

    test('a bad request is not asked twice', () async {
      // 400 is this app's query being wrong. A second identical try is
      // just another request against a server run for other people.
      final asked = <String>[];
      final client = OverpassShelterClient(
        retryDelay: Duration.zero,
        httpClient: MockClient((request) async {
          asked.add(request.url.host);
          return http.Response('', 400);
        }),
      );

      await expectLater(
        client.fetchShelters(bounds),
        throwsA(isA<OverpassException>()),
      );
      expect(asked, ['overpass-api.de', 'overpass.kumi.systems']);
    });

    test('an unreachable instance is moved on from, not retried', () async {
      final asked = <String>[];
      final client = OverpassShelterClient(
        httpClient: MockClient((request) async {
          asked.add(request.url.host);
          throw http.ClientException('no route', request.url);
        }),
      );

      await expectLater(
        client.fetchShelters(bounds),
        throwsA(isA<OverpassException>()),
      );
      expect(asked, ['overpass-api.de', 'overpass.kumi.systems']);
    });

    test('a rate limit is the kind that clears itself', () {
      expect(const OverpassException(429).isBusy, isTrue);
      expect(const OverpassException(504).isBusy, isTrue);
      expect(const OverpassException(400).isBusy, isFalse);
      expect(const OverpassException(0).isBusy, isFalse);
    });
  });
}
