import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_level.dart';

/// Reading PEGELONLINE, against what it really answered.
///
/// Captured live on 2026-09-10 from
/// pegelonline.wsv.de/webservices/rest-api/v2, gauge KÖLN on the Rhine.
/// The response is kept whole rather than trimmed to what the parser
/// wants, because the parts it has to ignore are half the work: the same
/// list of characteristic values carries fairway depths in centimetres
/// and a gauge datum in metres above sea level.
void main() {
  const stationFixture = '''
[
  {
    "uuid": "a6ee8177-107b-47dd-bcfd-30960ccc6e9c",
    "number": "2770010",
    "shortname": "KÖLN",
    "longname": "KÖLN",
    "km": 688.0,
    "agency": "WSA RHEIN",
    "longitude": 6.9633,
    "latitude": 50.936949,
    "water": { "shortname": "RHEIN", "longname": "RHEIN" }
  },
  {
    "uuid": "ec5e6a49-1234-4321-abcd-0123456789ab",
    "shortname": "ANDERNACH",
    "km": 613.8,
    "longitude": 7.4,
    "latitude": 50.44,
    "water": { "shortname": "RHEIN", "longname": "RHEIN" }
  }
]''';

  const levelFixture = '''
{
  "shortname": "W",
  "longname": "WASSERSTAND ROHDATEN",
  "unit": "cm",
  "equidistance": 15,
  "currentMeasurement": {
    "timestamp": "2026-09-10T18:15:00+02:00",
    "value": 66.0,
    "stateMnwMhw": "low",
    "stateNswHsw": "normal"
  },
  "gaugeZero": {
    "unit": "m. ü. NHN",
    "value": 35.038,
    "validFrom": "2019-11-01"
  },
  "characteristicValues": [
    { "shortname": "GlW", "longname": "gleichwertiger Wasserstand",
      "unit": "cm", "value": 139.0 },
    { "shortname": "TuGLW", "longname": "Tiefe unter GlW",
      "unit": "cm", "value": 250.0 },
    { "shortname": "M_II", "longname": "Marke_II", "unit": "cm",
      "value": 830.0 },
    { "shortname": "M_I", "longname": "Marke_I", "unit": "cm",
      "value": 620.0 },
    { "shortname": "HHW", "longname": "Höchster Hochwasserstand",
      "unit": "cm", "value": 1069.0 },
    { "shortname": "NNW", "longname": "Niedrigster Niedrigwasserstand",
      "unit": "cm", "value": 69.0 },
    { "shortname": "MNW", "longname": "Mittel der Niedrigwasserstände",
      "unit": "cm", "value": 114.0 },
    { "shortname": "MW", "longname": "Mittel der Tageswasserstände",
      "unit": "cm", "value": 297.0 },
    { "shortname": "MHW", "longname": "Mittel der Hochwasserstände",
      "unit": "cm", "value": 725.0 },
    { "shortname": "HSW", "longname": "höchster Schifffahrtswasserstand",
      "unit": "cm", "value": 830.0 }
  ]
}''';

  /// Two days of quarter-hourly samples, rising 48 cm over the second day.
  String seriesFixture() {
    final start = DateTime.utc(2026, 9, 8, 16, 15);
    final samples = <String>[];
    for (var i = 0; i <= 192; i++) {
      final at = start.add(Duration(minutes: 15 * i));
      final value = i <= 96 ? 18.0 + i * 0.5 : 66.0 + (i - 96) * 0.5;
      samples.add(
        '{"timestamp": "${at.toIso8601String()}", "value": $value}',
      );
    }
    return '[${samples.join(',')}]';
  }

  const koeln = PegelStation(
    uuid: 'a6ee8177-107b-47dd-bcfd-30960ccc6e9c',
    name: 'KÖLN',
    water: 'RHEIN',
    kilometre: 688,
  );

  /// What the service really sends, header included. Without the charset
  /// `http.Response` encodes the string as Latin-1 and every umlaut in
  /// these fixtures arrives broken -- which says nothing about the client
  /// and everything about the test.
  http.Response respond(String body, int status) => http.Response(
    body,
    status,
    headers: const {'content-type': 'application/json;charset=UTF-8'},
  );

  PegelClient clientFor({
    String? level,
    String? series,
    String? stations,
    int status = 200,
  }) => PegelClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/stations.json')) {
        return respond(stations ?? stationFixture, status);
      }
      if (path.endsWith('/measurements.json')) {
        return respond(series ?? seriesFixture(), status);
      }
      return respond(level ?? levelFixture, status);
    }),
  );

  group('the gauge list', () {
    test('parses names, waterway, position and river kilometre', () async {
      final stations = await clientFor().fetchStations();

      expect(stations, hasLength(2));
      final first = stations.first;
      expect(first.name, 'KÖLN');
      expect(first.water, 'RHEIN');
      expect(first.latitude, closeTo(50.936949, 0.000001));
      // The kilometre is what says which gauge is upstream, and upstream
      // is the only direction that warns.
      expect(first.kilometre, 688.0);
    });

    test('a refused request is an empty list, not a crash', () async {
      // Offline is the normal case for this app.
      expect(await clientFor(status: 503).fetchStations(), isEmpty);
    });

    test('an entry without a uuid is skipped rather than guessed at', () async {
      final stations = await clientFor(
        stations: '[{"shortname": "OHNE"}, {"uuid": "x", "shortname": "MIT"}]',
      ).fetchStations();

      expect(stations.map((s) => s.name), ['MIT']);
    });
  });

  group('the reading', () {
    test('gives the level the service actually reported', () async {
      final reading = await clientFor().fetchReading(koeln);

      expect(reading!.centimetres, 66.0);
      expect(reading.stationName, 'KÖLN');
      expect(reading.measuredAt.toUtc().hour, 16, reason: '18:15 +02:00');
    });

    test('keeps the centimetre references and drops the rest', () async {
      // GlW, Marke I and II and the fairway depth are shipping figures in
      // the same units; the gauge datum is metres above sea level. Only
      // the five long-term water levels may be compared against a level.
      final reading = await clientFor().fetchReading(koeln);

      expect(reading!.reference(PegelReference.mean), 297.0);
      expect(reading.reference(PegelReference.meanFlood), 725.0);
      expect(reading.reference(PegelReference.highest), 1069.0);
      expect(reading.reference(PegelReference.meanLow), 114.0);
      expect(reading.reference(PegelReference.lowest), 69.0);
      expect(reading.references, hasLength(5));
    });

    test('agrees with the service on where the level sits', () async {
      // The response carries its own coarse verdict, "stateMnwMhw": "low".
      // The bands here are finer and add the record levels the service
      // does not flag, but they must not contradict it.
      final reading = await clientFor().fetchReading(koeln);

      expect(reading!.band, PegelBand.recordLow);
    });

    test('reads the trend out of the series', () async {
      final reading = await clientFor().fetchReading(koeln);

      expect(reading!.changeOverDay, closeTo(48, 1));
      expect(reading.trend, PegelTrend.rising);
    });

    test('a failed series costs the trend and not the reading', () async {
      // Knowing the river is at 66 cm is worth more than knowing nothing
      // because the history did not load.
      final client = PegelClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/measurements.json')) {
            return respond('', 500);
          }
          return respond(levelFixture, 200);
        }),
      );

      final reading = await client.fetchReading(koeln);
      expect(reading!.centimetres, 66.0);
      expect(reading.changeOverDay, isNull);
      expect(reading.trend, PegelTrend.unknown);
    });

    test('no current measurement means no reading at all', () async {
      // Rather than a reading of zero centimetres, which on a gauge is a
      // plausible number.
      final reading = await clientFor(
        level: '{"shortname": "W", "unit": "cm"}',
      ).fetchReading(koeln);

      expect(reading, isNull);
    });

    test('a gauge with no published references still reads', () async {
      final reading = await clientFor(
        level: '''
{
  "shortname": "W", "unit": "cm",
  "currentMeasurement": {"timestamp": "2026-09-10T18:15:00+02:00",
    "value": 412.0}
}''',
      ).fetchReading(koeln);

      expect(reading!.centimetres, 412.0);
      expect(reading.references, isEmpty);
      expect(reading.band, PegelBand.unknown);
    });

    test('umlauts survive, whatever the service says about encoding', () async {
      final stations = await clientFor().fetchStations();
      expect(stations.first.name, 'KÖLN');
    });
  });
}
