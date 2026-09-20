import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/daylight/application/sun_moon.dart';

import 'meeus_reference.dart';

/// Holds `sun_moon.dart` against figures it does not contain.
///
/// `sun_moon_test.dart` next door checks the behaviour — that a polar day
/// has no sunrise, that dusk follows sunset, that nothing throws at the
/// equator. What it cannot check is whether the arithmetic is *right*,
/// because every expectation in it would have to come from the same code.
///
/// So everything here comes from somewhere else. The sun is held against
/// published almanac quantities — the equation of time's two extremes and
/// the four days a year it passes through zero, and day lengths at
/// Berlin's solstices — none of which appear anywhere in the app. The moon
/// is held against a second lunar theory in `meeus_reference.dart` that
/// shares no term with the app's, and against the phase formula, which
/// gives new and full moons without any position series at all.
void main() {
  /// The equation of time in minutes, read out of the app by way of the
  /// one place it surfaces: solar noon on the Greenwich meridian.
  double equationOfTime(DateTime day) {
    final noon = sunTimesFor(day, 51.4779, 0.0, zoneOffset: Duration.zero)
        .solarNoon!;
    return 720 - (noon.hour * 60 + noon.minute + noon.second / 60);
  }

  group('the sun, against the almanac', () {
    // The two extremes and the four zero crossings are the shape of the
    // analemma, and they are published to the tenth of a minute. Nothing
    // in `sun_moon.dart` names a date, so hitting all six is the series
    // being right rather than a constant being copied.
    test('the equation of time reaches its published extremes', () {
      expect(equationOfTime(DateTime(2026, 2, 11)), closeTo(-14.2, 0.2));
      expect(equationOfTime(DateTime(2026, 11, 3)), closeTo(16.4, 0.2));
      expect(equationOfTime(DateTime(2026, 5, 14)), closeTo(3.7, 0.2));
      expect(equationOfTime(DateTime(2026, 7, 26)), closeTo(-6.5, 0.2));
    });

    test('and passes through zero on the four days it should', () {
      for (final day in [
        DateTime(2026, 4, 15),
        DateTime(2026, 6, 13),
        DateTime(2026, 9, 1),
        DateTime(2026, 12, 25),
      ]) {
        expect(equationOfTime(day).abs(), lessThan(0.5), reason: '$day');
      }
    });

    test('Berlin gets the day lengths its solstices are known for', () {
      const zone = Duration(hours: 1);
      Duration lengthOn(int month, int day) =>
          sunTimesFor(DateTime(2026, month, day), 52.52, 13.405,
                  zoneOffset: zone)
              .dayLength!;

      // 16 h 50 min and 7 h 39 min, as every Berlin calendar prints them.
      expect(lengthOn(6, 21).inMinutes, closeTo(16 * 60 + 50, 2));
      expect(lengthOn(12, 21).inMinutes, closeTo(7 * 60 + 39, 2));

      // An equinox is not twelve hours: the disc has a radius and the
      // atmosphere lifts it, which is worth some seven minutes at this
      // latitude and six at the equator. A run that produced exactly
      // 12:00 would mean the -0.833 degrees had been lost.
      expect(lengthOn(3, 20).inMinutes, closeTo(12 * 60 + 10, 2));
      expect(lengthOn(9, 23).inMinutes, closeTo(12 * 60 + 9, 2));
      expect(
        sunTimesFor(DateTime(2026, 3, 20), 0, 0, zoneOffset: Duration.zero)
            .dayLength!
            .inMinutes,
        closeTo(12 * 60 + 6, 2),
      );
    });

    test('the events of a day come in the order they are read in', () {
      final day = sunTimesFor(DateTime(2026, 4, 3), 52.52, 13.405,
          zoneOffset: const Duration(hours: 2));
      final order = [
        day.nauticalDawn!,
        day.civilDawn!,
        day.sunrise!,
        day.solarNoon!,
        day.sunset!,
        day.civilDusk!,
        day.nauticalDusk!,
      ];
      for (var i = 1; i < order.length; i++) {
        expect(order[i].isAfter(order[i - 1]), isTrue, reason: '$order');
      }
      // Sunrise and sunset stand the same distance either side of noon,
      // give or take the declination's own drift over the day. A swapped
      // sign in the hour angle shows up here and nowhere else.
      final before = day.solarNoon!.difference(day.sunrise!).inSeconds;
      final after = day.sunset!.difference(day.solarNoon!).inSeconds;
      expect((before - after).abs(), lessThan(90));
    });
  });

  group('the moon, against a second theory', () {
    /// Meeus chapter 49: the instant of new moon number [k], counted from
    /// the one in January 2000. Pure phase arithmetic — it uses no
    /// position series, so it cannot agree with either of the two by
    /// accident.
    DateTime newMoon(int k) => DateTime.fromMillisecondsSinceEpoch(
          (((2451550.09766 + 29.530588861 * k) - 2440587.5) * 86400000)
              .round(),
          isUtc: true,
        );

    test('new and full moons fall where the phase formula puts them', () {
      var checked = 0;
      for (var k = 320; k < 340; k++) {
        final dark = newMoon(k);
        if (dark.year != 2026) continue;
        checked++;
        final full = dark.add(const Duration(hours: 354, minutes: 22));

        final atNew = moonFor(dark, 52.52, 13.405, zoneOffset: Duration.zero);
        expect(atNew.illumination, lessThan(0.02), reason: 'neu am $dark');
        expect(atNew.phase, MoonPhase.newMoon);

        final atFull = moonFor(full, 52.52, 13.405, zoneOffset: Duration.zero);
        expect(atFull.illumination, greaterThan(0.98), reason: 'voll am $full');
        expect(atFull.phase, MoonPhase.fullMoon);
      }
      expect(checked, greaterThan(10));
    });

    test('rise and set hold to within the few minutes claimed', () {
      // Five places, a year each, against the sixty-term theory. The
      // doc comment on `sun_moon.dart` promises "a few minutes"; this is
      // what makes that a measurement rather than a hope.
      const places = [
        ('Berlin', 52.52, 13.405),
        ('Muenchen', 48.14, 11.58),
        ('Tromsoe', 69.65, 18.96),
        ('Aequator', 0.0, 0.0),
        ('Kapstadt', -33.92, 18.42),
      ];

      var worst = 0;
      var worstAt = '';
      var compared = 0;
      for (final (name, latitude, longitude) in places) {
        for (var day = 0; day < 365; day += 7) {
          final date = DateTime(2026, 1, 1).add(Duration(days: day));
          final app = moonFor(date, latitude, longitude,
              zoneOffset: Duration.zero);
          final reference = referenceMoonEvents(date, latitude, longitude);

          for (final (ours, theirs) in [
            (app.rise, reference.rise),
            (app.set, reference.set),
          ]) {
            if (ours == null || theirs == null) continue;
            compared++;
            // A zero offset means the returned fields are UTC; they have
            // to be reassembled as such before anything is subtracted.
            final asUtc = DateTime.utc(ours.year, ours.month, ours.day,
                ours.hour, ours.minute, ours.second, ours.millisecond);
            final off = asUtc.difference(theirs).inMinutes.abs();
            if (off > worst) {
              worst = off;
              worstAt = '$name $date: $asUtc gegen $theirs';
            }
          }
        }
      }

      expect(compared, greaterThan(400));
      // Ten minutes, and the worst case is always the high north, where
      // the moon crosses the horizon so flatly that a fifth of a degree
      // of longitude is a quarter of an hour of nothing much. Berlin sits
      // inside two.
      expect(worst, lessThanOrEqualTo(10), reason: worstAt);
    });

    test('the lit fraction is the same to a fifth of a percent', () {
      var worst = 0.0;
      for (var day = 0; day < 365; day += 3) {
        final date = DateTime(2026, 1, 1).add(Duration(days: day));
        final app = moonFor(date, 52.52, 13.405, zoneOffset: Duration.zero);
        final off = (app.illumination - referenceIllumination(date)).abs();
        if (off > worst) worst = off;
      }
      expect(worst, lessThan(0.005));
    });
  });
}
