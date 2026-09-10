import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_level.dart';

/// Reaches the real PEGELONLINE service.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set, like the other live
/// tests here. Worth running after touching the client: the fixtures in
/// `pegel_client_test` were captured on 2026-09-10, and the thing a
/// fixture cannot catch is the service changing its shape.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real gauge service'
      : null;

  test('the gauge list arrives with positions and river kilometres', () async {
    final stations = await PegelClient().fetchStations();

    // Around 800 gauges on the federal waterways.
    expect(stations.length, greaterThan(500));
    expect(
      stations.where((s) => s.latitude != null).length,
      greaterThan(stations.length ~/ 2),
    );
    expect(stations.map((s) => s.water).toSet().length, greaterThan(10));
  }, skip: reason);

  test('a well-known gauge reads with its reference values', () async {
    final stations = await PegelClient().fetchStations();
    final koeln = stations.firstWhere((s) => s.name == 'KÖLN');

    final reading = await PegelClient().fetchReading(koeln);

    expect(reading, isNotNull);
    expect(reading!.centimetres, greaterThan(0));
    // Cologne publishes the full set; if this ever stops being true the
    // screen's "no scale" path is what a household would see instead.
    expect(reading.reference(PegelReference.mean), isNotNull);
    expect(reading.reference(PegelReference.meanFlood), isNotNull);
    expect(reading.reference(PegelReference.highest), isNotNull);
    // Reported every fifteen minutes, so a live reading should be fresh.
    expect(reading.isStale(), isFalse);
  }, skip: reason);

  test('the trend comes out of a real two-day series', () async {
    final stations = await PegelClient().fetchStations();
    final koeln = stations.firstWhere((s) => s.name == 'KÖLN');

    final reading = await PegelClient().fetchReading(koeln);

    // A real series is complete enough to say something; the value
    // itself is whatever the river is doing today.
    expect(reading!.changeOverDay, isNotNull);
    expect(reading.trend, isNot(PegelTrend.unknown));
  }, skip: reason);
}
