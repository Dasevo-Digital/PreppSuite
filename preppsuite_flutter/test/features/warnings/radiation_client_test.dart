import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_client.dart';

import '../fixture_http_client.dart';

/// Reading the BfS interface, against captures of what it really sends.
void main() {
  final latest = File(
    'test/fixtures/bfs_odl_latest.json',
  ).readAsStringSync();
  final series = File(
    'test/fixtures/bfs_odl_series.json',
  ).readAsStringSync();

  const latestUrl =
      'https://www.imis.bfs.de/ogc/opendata/ows'
      '?service=WFS&version=1.1.0&request=GetFeature'
      '&typeName=opendata%3Aodlinfo_odl_1h_latest'
      '&outputFormat=application%2Fjson';

  const seriesUrl =
      'https://www.imis.bfs.de/ogc/opendata/ows'
      '?service=WFS&version=1.1.0&request=GetFeature'
      '&typeName=opendata%3Aodlinfo_timeseries_odl_1h'
      '&outputFormat=application%2Fjson&viewparams=kenn%3A083170410';

  group('the station list', () {
    test('reads the identifier, the place and the position', () async {
      final client = RadiationClient(
        httpClient: FixtureHttpClient({latestUrl: latest}),
      );

      final stations = await client.fetchStations();

      expect(stations, hasLength(1));
      final station = stations.single;
      expect(station.id, '083170410');
      expect(station.name, 'Hausach');
      expect(station.postalCode, '77756');
      expect(station.heightAboveSea, 230);
      // GeoJSON is longitude first, and getting that the wrong way round
      // would put every German probe in Somalia.
      expect(station.latitude, closeTo(48.28, 0.01));
      expect(station.longitude, closeTo(8.15, 0.01));
    });

    test('a probe out of service is left out', () async {
      // The capture carries one. It reports no value, and a picker
      // offering a probe that answers nothing is worse than a shorter
      // list.
      final client = RadiationClient(
        httpClient: FixtureHttpClient({latestUrl: latest}),
      );

      final stations = await client.fetchStations();

      expect(stations.map((s) => s.name), isNot(contains('')));
      expect(stations, hasLength(1));
    });

    test('a service that will not answer gives an empty list', () async {
      // Offline is the ordinary case for this app, not an error.
      final client = RadiationClient(httpClient: FixtureHttpClient(const {}));

      expect(await client.fetchStations(), isEmpty);
    });
  });

  group('one station’s reading', () {
    const station = RadiationStation(id: '083170410', name: 'Hausach');

    test('takes the newest sample and the series’ own median', () async {
      final client = RadiationClient(
        httpClient: FixtureHttpClient({seriesUrl: series}),
      );

      final reading = await client.fetchReading(station);

      expect(reading, isNotNull);
      expect(reading!.stationName, 'Hausach');
      expect(reading.microsievertsPerHour, greaterThan(0.1));
      expect(reading.baseline, isNotNull);
      expect(reading.validated, isTrue);
    });

    test('the sample is timed at the end of its measuring hour', () async {
      // A value labelled 05:00–06:00 is what the air was doing until
      // six. Calling it five would make every reading look an hour
      // staler than it is.
      final client = RadiationClient(
        httpClient: FixtureHttpClient({seriesUrl: series}),
      );

      final reading = await client.fetchReading(station);

      expect(reading!.measuredAt.minute, 0);
      expect(reading.measuredAt.isUtc, isTrue);
    });

    test('a failed fetch is null, not an exception', () async {
      final client = RadiationClient(httpClient: FixtureHttpClient(const {}));

      expect(await client.fetchReading(station), isNull);
    });
  });

  group('the reading out of the list', () {
    test('carries the split the series does not', () async {
      // The all-stations layer states the cosmic and terrestrial parts.
      // Worth showing: a high station reads high because it is high up.
      final client = RadiationClient(
        httpClient: FixtureHttpClient({latestUrl: latest}),
      );
      final stations = await client.fetchStations();

      // Re-fetch the raw feature the way the screen would.
      final reading = client.readingFrom(
        {
          'properties': {
            'value': 0.162,
            'value_terrestrial': 0.117,
            'value_cosmic': 0.045,
            'end_measure': '2026-09-11T06:00:00Z',
            'validated': 1,
          },
        },
        stations.single,
      );

      expect(reading!.terrestrial, 0.117);
      expect(reading.cosmic, 0.045);
      // No series behind it, so no baseline — and the band falls back to
      // the national range rather than inventing one.
      expect(reading.baseline, isNull);
    });
  });
}
