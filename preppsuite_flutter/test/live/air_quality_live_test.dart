import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/air_quality_level.dart';

/// Asks the Umweltbundesamt's own interface.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. Worth running after
/// touching the client: every row there is keyed by position, so a column
/// the UBA inserts would put a station in the wrong state and a reading
/// in the wrong class without anything else noticing.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real air quality service'
      : null;

  test(
    'the station list arrives with positions and states',
    () async {
      final stations = await AirQualityClient().fetchStations();
      stdout.writeln('${stations.length} Stationen');

      expect(stations.length, greaterThan(300));
      final named = stations.where((s) => s.state != null).toList();
      expect(named.length, stations.length, reason: 'every station has a state');

      final located = stations.where(
        (s) => s.latitude != null && s.longitude != null,
      );
      expect(located.length, greaterThan(stations.length - 20));
      // Germany, roughly.
      for (final station in located.take(50)) {
        expect(station.latitude, inInclusiveRange(47, 56));
        expect(station.longitude, inInclusiveRange(5, 16));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: reason,
  );

  test(
    'a station reads with a class the UBA gave it',
    () async {
      final client = AirQualityClient();
      final stations = await client.fetchStations();
      expect(stations, isNotEmpty);

      // The first station that is reporting at all — a single station can
      // be down for maintenance, and that is not a failure of the client.
      AirQualityReading? reading;
      for (final station in stations.take(12)) {
        reading = await client.fetchReading(station.id);
        if (reading != null) {
          stdout.writeln(
            '${station.name}: ${reading.level.name}, '
            '${reading.components.length} Schadstoffe, '
            'gemessen ${reading.measuredAt}',
          );
          break;
        }
      }

      expect(reading, isNotNull, reason: 'no station in twelve reported');
      expect(reading!.level, isNot(AirQualityClass.unknown));
      expect(reading.components, isNotEmpty);
      expect(reading.leading, isNotNull);
      // Hourly data: the newest hour must not be from last week.
      expect(
        DateTime.now().difference(reading.measuredAt),
        lessThan(const Duration(days: 2)),
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: reason,
  );

  test(
    'the thresholds are the ones the classes are built from',
    () async {
      final thresholds = await AirQualityClient().fetchThresholds();
      stdout.writeln('Schwellen für ${thresholds.length} Schadstoffe');

      // Ozone, nitrogen dioxide, particulates — the components the index
      // is actually built from.
      expect(thresholds.keys, containsAll([1, 3, 5]));

      for (final entry in thresholds.entries) {
        final spans = entry.value;
        expect(
          spans.length,
          5,
          reason: 'five classes for component ${entry.key}',
        );
        expect(
          spans.map((s) => s.level),
          [
            AirQualityClass.veryGood,
            AirQualityClass.good,
            AirQualityClass.moderate,
            AirQualityClass.poor,
            AirQualityClass.veryPoor,
          ],
          reason: 'in order, and none missing',
        );
        expect(spans.first.min, 0);
      }

      // The boundary the app was written against: ozone's best class ends
      // at 60 µg/m³ in the hourly index.
      expect(thresholds[3]!.first.max, 60);
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: reason,
  );
}
