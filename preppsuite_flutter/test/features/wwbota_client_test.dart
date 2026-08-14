import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/features/shelters/application/wwbota_client.dart';

void main() {
  test(
    'fetchBunkers parses a real captured response from api.wwbota.org',
    () async {
      // Captured live on 2026-08-14 against
      // api.wwbota.org/bunkers/?scheme=DLBOTA&bbox=10.3,52.1,10.7,52.4
      const fixture = '''
[
  {
    "dxcc": 230,
    "reference": "B/DL-0151",
    "type": "Hochbunker",
    "long": 10.386983,
    "locator": "JO52ED",
    "scheme": "DLBOTA",
    "name": "Hochbunker Salzgitter Heerte",
    "lat": 52.125133,
    "extra": {}
  }
]''';

      final client = WwbotaClient(
        httpClient: MockClient((request) async {
          expect(request.url.path, '/bunkers/');
          expect(request.url.queryParameters['scheme'], 'DLBOTA');
          return http.Response(fixture, 200);
        }),
      );

      final bounds = boundingBoxForRadius(const LatLng(52.25, 10.5), 25);
      final bunkers = await client.fetchBunkers(bounds);

      expect(bunkers, hasLength(1));
      expect(bunkers.single.reference, 'B/DL-0151');
      expect(bunkers.single.name, 'Hochbunker Salzgitter Heerte');
      expect(bunkers.single.lon, 10.386983);
      expect(bunkers.single.lat, 52.125133);
    },
  );

  test('fetchBunkers returns an empty list on a non-200 response', () async {
    final client = WwbotaClient(
      httpClient: MockClient((request) async => http.Response('', 503)),
    );

    final bounds = boundingBoxForRadius(const LatLng(52.25, 10.5), 25);
    expect(await client.fetchBunkers(bounds), isEmpty);
  });
}
