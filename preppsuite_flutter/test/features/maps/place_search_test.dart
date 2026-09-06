import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/place_search.dart';

import '../fixture_http_client.dart';

void main() {
  final hannoverJson = File(
    'test/fixtures/nominatim_hannover.json',
  ).readAsStringSync();

  const searchUrl =
      'https://nominatim.openstreetmap.org/search'
      '?format=jsonv2&q=Hannover&limit=8&accept-language=de';

  group('searching', () {
    test('reads the box, the name and what kind of place it is', () async {
      final client = PlaceSearchClient(
        httpClient: FixtureHttpClient({searchUrl: hannoverJson}),
      );

      final results = await client.search('Hannover');
      expect(results, hasLength(2));

      final city = results.first;
      expect(city.name, 'Hannover');
      expect(city.kind, 'city');
      expect(city.description, contains('Niedersachsen'));

      // Nominatim gives the box as [minLat, maxLat, minLon, maxLon] —
      // latitudes first, the opposite of every other pair here. Getting
      // this backwards would download a strip of the Atlantic.
      expect(city.minLatitude, closeTo(52.3049, 0.001));
      expect(city.maxLatitude, closeTo(52.4543, 0.001));
      expect(city.minLongitude, closeTo(9.6044, 0.001));
      expect(city.maxLongitude, closeTo(9.9186, 0.001));
    });

    test('the second Hannover is an island off Chile', () async {
      final client = PlaceSearchClient(
        httpClient: FixtureHttpClient({searchUrl: hannoverJson}),
      );

      final island = (await client.search('Hannover')).last;
      expect(island.kind, 'island');
      expect(island.minLatitude, lessThan(0));
    });

    test('an empty query asks nothing', () async {
      final asked = <String>[];
      final client = PlaceSearchClient(
        httpClient: FixtureHttpClient(const {}, onRequest: asked.add),
      );

      expect(await client.search('   '), isEmpty);
      expect(asked, isEmpty);
    });

    test('an unreachable geocoder is an error, not an empty result', () {
      final client = PlaceSearchClient(httpClient: FixtureHttpClient(const {}));
      expect(
        client.search('Hannover'),
        throwsA(isA<PlaceSearchException>()),
      );
    });
  });

  group('how deep a place can be downloaded', () {
    // Counted independently from the Web Mercator formulas. These are
    // the numbers the whole feature turns on.
    MapArea areaOf(double w, double s, double e, double n) => MapArea(
      minLongitude: w,
      minLatitude: s,
      maxLongitude: e,
      maxLatitude: n,
      maxZoom: 14,
    );

    test('a city goes to the deepest level with room to spare', () {
      final hannover = areaOf(9.6044, 52.3049, 9.9186, 52.4543);
      expect(deepestDetailWithin(hannover), 14);
      expect(hannover.tileCount, lessThan(500));
    });

    test('a Bundesland still fits at the deepest level', () {
      // Niedersachsen, as Nominatim gives it.
      final lowerSaxony = areaOf(6.3459, 51.2951, 11.5981, 54.1378);
      expect(deepestDetailWithin(lowerSaxony), 14);
      expect(
        lowerSaxony.tileCount,
        lessThanOrEqualTo(MapAreaDownloader.tileLimit),
      );
    });

    test('a country does not, and the answer is a shallower level', () {
      final germany = areaOf(5.8663, 47.2701, 15.0419, 55.0992);

      // 319,812 tiles at the deepest level, some fourteen gigabytes.
      expect(germany.tileCount, greaterThan(MapAreaDownloader.tileLimit));

      // One level down it fits, at 80,563 — which is the honest answer
      // to "a whole country at the highest detail level".
      expect(deepestDetailWithin(germany), 13);
      expect(
        germany.withDetail(13).tileCount,
        lessThanOrEqualTo(MapAreaDownloader.tileLimit),
      );
    });

    test('there is a size with no answer at all', () {
      // The whole world. Level 8 still fits at 87,381 tiles; nothing
      // below that is offered, so asking for more comes back empty.
      final world = areaOf(-180, -85, 180, 85);
      expect(deepestDetailWithin(world), 8);
      expect(deepestDetailWithin(world, lowest: 9), isNull);
    });
  });
}
