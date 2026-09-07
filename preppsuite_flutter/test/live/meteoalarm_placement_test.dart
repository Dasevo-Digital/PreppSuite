import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';

/// The real table against a real feed.
///
/// Skipped unless PREPPSUITE_METEOALARM points at a saved MeteoAlarm
/// Atom feed. Fetch one with
///
///   curl -o de.xml https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-germany
void main() {
  final feed = Platform.environment['PREPPSUITE_METEOALARM'];

  test(
    'how much of a live feed can be placed',
    () async {
      final areas = DwdAreas.parse(
        await File('assets/dwd_warncells.csv').readAsString(),
      );
      final xml = await File(feed!).readAsString();
      final descriptions = RegExp(
        r'<cap:areaDesc>([^<]*)',
      ).allMatches(xml).map((m) => m.group(1)!).toList();

      var district = 0;
      var state = 0;
      var nowhere = 0;
      for (final description in descriptions) {
        final key = areas.regionKeyFor(description);
        if (key == null) {
          nowhere++;
        } else if (key.length == 5) {
          district++;
        } else {
          state++;
        }
      }

      // ignore: avoid_print
      print(
        '${descriptions.length} Warnungen: '
        '$district kreisgenau, $state nur Bundesland, $nowhere unplatzierbar',
      );
      expect(district, greaterThan(descriptions.length ~/ 2));
    },
    skip: feed == null ? 'set PREPPSUITE_METEOALARM to a saved feed' : null,
  );
}
