import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/daylight/application/sun_moon.dart';

/// Asks the US Naval Observatory the same questions the app answers on
/// its own.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. The unit test carries
/// the same figures written down, which is fine until somebody changes
/// the arithmetic and updates the expectations to match — this one cannot
/// be talked round, because the answer comes from somewhere else.
///
/// Nothing in the app ever calls this service. It exists so that an
/// almanac shipped as fact can be shown to be one.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to check against the USNO tables'
      : null;

  const places = [
    ('Braunschweig', 52.2689, 10.5268),
    ('München', 48.1372, 11.5756),
    ('Flensburg', 54.7937, 9.4469),
    ('Quito', -0.1807, -78.4678),
  ];

  const days = [
    (2026, 3, 20, 1),
    (2026, 6, 21, 2),
    (2026, 9, 11, 2),
    (2026, 12, 21, 1),
  ];

  test(
    'sun and moon match the published tables to the minute',
    () async {
      final client = http.Client();
      addTearDown(client.close);

      var refused = 0;
      var checked = 0;
      var worstSun = 0;
      var worstMoon = 0;

      for (final (name, latitude, longitude) in places) {
        for (final (year, month, day, zone) in days) {
          final date = '$year-${_two(month)}-${_two(day)}';
          // The service throttles a burst; a pause between questions is
          // both politer and the difference between nine days answered
          // and sixteen.
          await Future<void>.delayed(const Duration(milliseconds: 700));
          final response = await client.get(
            Uri.https('aa.usno.navy.mil', '/api/rstt/oneday', {
              'date': date,
              'coords': '$latitude,$longitude',
              'tz': '$zone',
            }),
          );
          // Counted rather than ignored: the service throttles, and a run
          // that quietly compared three days instead of sixteen would pass
          // while proving almost nothing.
          if (response.statusCode != 200) {
            refused++;
            continue;
          }

          final data =
              (jsonDecode(utf8.decode(response.bodyBytes))
                      as Map<String, Object?>)['properties']
                  as Map<String, Object?>;
          final published = data['data'] as Map<String, Object?>;

          final sun = _phenomena(published['sundata']);
          final moon = _phenomena(published['moondata']);

          final offset = Duration(hours: zone);
          final ours = sunTimesFor(
            DateTime(year, month, day),
            latitude,
            longitude,
            zoneOffset: offset,
          );
          final theirMoon = moonFor(
            DateTime(year, month, day),
            latitude,
            longitude,
            zoneOffset: offset,
          );

          void compare(
            DateTime? mine,
            String? theirs,
            String what,
            bool isSun,
          ) {
            if (theirs == null) return;
            expect(mine, isNotNull, reason: '$name $date: no $what');
            final off = _minutesApart(mine!, theirs);
            if (isSun) {
              worstSun = off > worstSun ? off : worstSun;
            } else {
              worstMoon = off > worstMoon ? off : worstMoon;
            }
            checked++;
            expect(
              off,
              lessThanOrEqualTo(2),
              reason: '$name $date $what: ours ${_hm(mine)}, theirs $theirs',
            );
          }

          compare(ours.sunrise, sun['Rise'], 'sunrise', true);
          compare(ours.sunset, sun['Set'], 'sunset', true);
          compare(ours.solarNoon, sun['Upper Transit'], 'solar noon', true);
          compare(
            ours.civilDawn,
            sun['Begin Civil Twilight'],
            'civil dawn',
            true,
          );
          compare(
            ours.civilDusk,
            sun['End Civil Twilight'],
            'civil dusk',
            true,
          );
          compare(theirMoon.rise, moon['Rise'], 'moonrise', false);
          compare(theirMoon.set, moon['Set'], 'moonset', false);

          // Their percentage is rounded to whole points.
          final fraction = published['fracillum'];
          if (fraction is String && fraction.endsWith('%')) {
            final theirs =
                int.parse(fraction.substring(0, fraction.length - 1)) / 100;
            expect(
              theirMoon.illumination,
              closeTo(theirs, 0.02),
              reason: '$name $date illumination',
            );
          }
        }
      }

      stdout.writeln(
        '$checked Zeiten geprüft, $refused Anfragen abgelehnt, '
        'Sonne höchstens $worstSun min daneben, Mond höchstens $worstMoon min',
      );
      // The service throttles. A run that quietly compared three days
      // instead of sixteen would pass while proving almost nothing, so
      // being refused is a failure of the run rather than a smaller run.
      expect(
        refused,
        lessThan(places.length * days.length ~/ 2),
        reason: 'the service refused $refused of the days asked for',
      );
      // A floor rather than a fixed number: how many comparisons there are
      // depends on how many events actually happen — a day without a
      // moonrise contributes one fewer, and so does a polar day.
      expect(checked, greaterThan(40));
    },
    skip: reason,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

String _two(int value) => value.toString().padLeft(2, '0');

String _hm(DateTime moment) => '${_two(moment.hour)}:${_two(moment.minute)}';

Map<String, String> _phenomena(Object? raw) => {
  if (raw is List)
    for (final entry in raw)
      if (entry is Map && entry['time'] is String)
        '${entry['phen']}': entry['time'] as String,
};

/// How far apart two wall-clock times are, in whole minutes, wrapping
/// around midnight — a moonset published as 00:52 and computed as 00:51
/// is one minute apart, not one thousand four hundred and thirty-nine.
int _minutesApart(DateTime mine, String theirs) {
  final parts = theirs.split(':');
  final published = int.parse(parts[0]) * 60 + int.parse(parts[1]);
  // Rounded, because every published figure is to the minute and ours
  // carries seconds.
  final ours = ((mine.hour * 60 + mine.minute) * 60 + mine.second) / 60;
  final raw = (ours - published).abs();
  return (raw > 720 ? 1440 - raw : raw).round();
}
