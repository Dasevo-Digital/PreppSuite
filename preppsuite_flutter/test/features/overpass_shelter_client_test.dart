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

  test('fetchShelters reports failure on a non-200 response', () async {
    final client = OverpassShelterClient(
      httpClient: MockClient((request) async => http.Response('', 504)),
    );

    final bounds = boundingBoxForRadius(const LatLng(52.5, 13.4), 25);
    await expectLater(
      client.fetchShelters(bounds),
      throwsA(isA<http.ClientException>()),
    );
  });
}
