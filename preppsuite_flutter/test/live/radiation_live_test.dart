import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/radiation_level.dart';

/// Against the BfS's real interface.
///
/// Skipped unless PREPPSUITE_TEST_NETWORK is set. Worth running after
/// touching the client: what no fixture can show is whether the service
/// still answers in the shape the parser expects, and this is the test
/// that caught the field names in the first place.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real radiation service'
      : null;

  test('the station list arrives with positions and values', () async {
    final client = RadiationClient();
    addTearDown(client.close);

    final stations = await client.fetchStations();
    stdout.writeln('${stations.length} Messstellen in Betrieb');

    // About 1700 probes; 1676 were reporting when this was written. A
    // bound rather than a number, because probes go in and out of
    // service.
    expect(stations.length, greaterThan(1000));

    final placed = stations.where(
      (s) => s.latitude != null && s.longitude != null,
    );
    expect(placed.length, stations.length);

    // The nine-digit identifier the time-series layer needs.
    expect(stations.first.id, matches(RegExp(r'^\d{9}$')));
  }, skip: reason);

  test('a station reads with a baseline of its own', () async {
    final client = RadiationClient();
    addTearDown(client.close);

    final stations = await client.fetchStations();
    // Hausach first, as before, and others where it lags. One station can
    // be hours behind the rest: on 11 November 2026 Hausach's newest value
    // was from 06:00 UTC while 1488 others had 08:00. The app says so, as
    // it should; this test wants a station on an ordinary day (#367).
    final candidates = [
      ...stations.where((s) => s.name == 'Hausach'),
      ...stations.take(10),
    ];
    RadiationReading? reading;
    for (final station in candidates) {
      final candidate = await client.fetchReading(station);
      if (candidate != null && !candidate.isStale()) {
        reading = candidate;
        break;
      }
    }
    expect(reading, isNotNull, reason: 'none of the stations asked is current');

    stdout.writeln(
      '${reading!.stationName}: ${reading.microsievertsPerHour} µSv/h, '
      'Grundlinie ${reading.baseline}, Band ${reading.band.name}, '
      'gemessen ${reading.measuredAt.toIso8601String()}',
    );

    // Inside the range the BfS states for Germany. If this ever fails,
    // the interesting question is whether it is the parser or the world.
    expect(reading.microsievertsPerHour, greaterThan(0.01));
    expect(reading.microsievertsPerHour, lessThan(naturalCeiling * 3));

    // Seven days of hourly samples is far past the twelve the median
    // needs, so a live station must produce one.
    expect(reading.baseline, isNotNull);
    expect(reading.baseline, greaterThan(naturalFloor / 2));

    // And on an ordinary day it reads as ordinary.
    expect(reading.isStale(), isFalse);
  }, skip: reason);
}
