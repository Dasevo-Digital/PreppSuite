import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/daylight/application/sun_moon.dart';

/// Checked against the US Naval Observatory's own rise/set/twilight
/// tables (`aa.usno.navy.mil/api/rstt/oneday`), which is where the
/// expected values below come from — not from a second run of this code.
///
/// Every sun figure lands within a minute of theirs and every moon figure
/// within a minute as well. That is the whole point of testing it this
/// way: an almanac is either right or it is a decoration, and the only
/// way to know is to compare it with one that is published.
///
/// `test/live/daylight_live_test.dart` asks them again, so a wrong turn
/// in this arithmetic cannot hide behind numbers copied down here.
void main() {
  const braunschweig = (52.2689, 10.5268);
  const munich = (48.1372, 11.5756);
  const flensburg = (54.7937, 9.4469);
  const tromso = (69.6492, 18.9553);
  const quito = (-0.1807, -78.4678);

  /// Every published time is to the minute, so comparisons are too.
  void expectAt(DateTime? actual, String expected, {int slack = 1}) {
    expect(actual, isNotNull, reason: 'expected $expected, got nothing');
    final parts = expected.split(':');
    final wanted = DateTime(
      actual!.year,
      actual.month,
      actual.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final off = actual.difference(wanted).inSeconds.abs();
    expect(
      off,
      lessThanOrEqualTo(slack * 60 + 30),
      reason:
          'expected $expected, got '
          '${actual.hour}:${actual.minute.toString().padLeft(2, '0')}',
    );
  }

  group('the sun', () {
    test('an autumn day in Braunschweig', () {
      final times = sunTimesFor(
        DateTime(2026, 9, 11),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expectAt(times.civilDawn, '06:11');
      expectAt(times.sunrise, '06:46');
      expectAt(times.solarNoon, '13:15');
      expectAt(times.sunset, '19:42');
      expectAt(times.civilDusk, '20:17');
      expect(times.alwaysUp, isFalse);
      expect(times.alwaysDown, isFalse);
    });

    test('the shortest day, where the twilight matters most', () {
      final times = sunTimesFor(
        DateTime(2026, 12, 21),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 1),
      );

      expectAt(times.civilDawn, '07:44');
      expectAt(times.sunrise, '08:25');
      expectAt(times.sunset, '16:07');
      expectAt(times.civilDusk, '16:48');
      // Seven hours and three quarters of daylight, and forty minutes of
      // usable light after it.
      expect(times.dayLength!.inMinutes, closeTo(462, 2));
      expect(times.eveningTwilight!.inMinutes, closeTo(41, 2));
    });

    test('the longest day', () {
      final times = sunTimesFor(
        DateTime(2026, 6, 21),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expectAt(times.sunrise, '04:56');
      expectAt(times.sunset, '21:43');
      expectAt(times.civilDusk, '22:33');
    });

    test('an equinox in Munich is a twelve-hour day', () {
      final times = sunTimesFor(
        DateTime(2026, 3, 20),
        munich.$1,
        munich.$2,
        zoneOffset: const Duration(hours: 1),
      );

      expectAt(times.sunrise, '06:17');
      expectAt(times.sunset, '18:26');
      expect(times.dayLength!.inMinutes, closeTo(729, 2));
    });

    test('the far north of Germany, where midsummer twilight runs late', () {
      final times = sunTimesFor(
        DateTime(2026, 6, 21),
        flensburg.$1,
        flensburg.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expectAt(times.sunrise, '04:44');
      expectAt(times.sunset, '22:04');
      expectAt(times.civilDusk, '23:01');
    });

    test('midnight sun is said, not printed as a time', () {
      final times = sunTimesFor(
        DateTime(2026, 6, 21),
        tromso.$1,
        tromso.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expect(times.sunrise, isNull);
      expect(times.sunset, isNull);
      expect(times.alwaysUp, isTrue);
      expect(times.alwaysDown, isFalse);
    });

    test('polar night keeps its twilight, which is the usable part', () {
      final times = sunTimesFor(
        DateTime(2026, 12, 21),
        tromso.$1,
        tromso.$2,
        zoneOffset: const Duration(hours: 1),
      );

      expect(times.sunrise, isNull);
      expect(times.alwaysDown, isTrue);
      // Four and a half hours in which something can be done outside.
      expectAt(times.civilDawn, '09:31');
      expectAt(times.civilDusk, '13:53');
    });

    test('the equator, where the day barely moves', () {
      final times = sunTimesFor(
        DateTime(2026, 9, 11),
        quito.$1,
        quito.$2,
        zoneOffset: const Duration(hours: -5),
      );

      expectAt(times.sunrise, '06:07');
      expectAt(times.sunset, '18:14');
    });
  });

  group('the moon', () {
    test('a new moon rises with the sun and gives no light at all', () {
      final moon = moonFor(
        DateTime(2026, 9, 11),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expectAt(moon.rise, '07:02');
      expectAt(moon.set, '19:33');
      expect(moon.illumination, lessThan(0.02));
      expect(moon.phase, MoonPhase.newMoon);
    });

    test('a gibbous moon in December, lit nine tenths', () {
      final moon = moonFor(
        DateTime(2026, 12, 21),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 1),
      );

      expectAt(moon.rise, '13:21');
      expectAt(moon.set, '05:26');
      // The USNO gives 90 per cent for this day.
      expect(moon.illumination, closeTo(0.90, 0.02));
      expect(moon.waxing, isTrue);
      expect(moon.phase, MoonPhase.waxingGibbous);
    });

    test('a crescent at midsummer', () {
      final moon = moonFor(
        DateTime(2026, 6, 21),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expectAt(moon.rise, '12:56');
      expectAt(moon.set, '00:52');
      expect(moon.illumination, closeTo(0.45, 0.02));
      expect(moon.waxing, isTrue);
    });

    test('the equator, where the moon stands almost upright', () {
      final moon = moonFor(
        DateTime(2026, 9, 11),
        quito.$1,
        quito.$2,
        zoneOffset: const Duration(hours: -5),
      );

      expectAt(moon.rise, '06:23');
      expectAt(moon.set, '18:45');
    });

    test('a moon that never sets is said rather than left blank', () {
      final moon = moonFor(
        DateTime(2026, 12, 21),
        tromso.$1,
        tromso.$2,
        zoneOffset: const Duration(hours: 1),
      );

      // The USNO calls this "object continuously above the horizon".
      expect(moon.upAllDay, isTrue);
      expect(moon.downAllDay, isFalse);
      expect(moon.rise, isNull);
      expect(moon.set, isNull);
    });

    test('waxing and waning are told apart at the same lit fraction', () {
      // Either side of a full moon: the picture is the same and the week
      // ahead is the opposite.
      final before = moonFor(
        DateTime(2026, 9, 22),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );
      final after = moonFor(
        DateTime(2026, 10, 6),
        braunschweig.$1,
        braunschweig.$2,
        zoneOffset: const Duration(hours: 2),
      );

      expect(before.waxing, isTrue);
      expect(after.waxing, isFalse);
    });

    test('the phase runs through all eight names over a month', () {
      final seen = <MoonPhase>{};
      for (var day = 1; day <= 31; day++) {
        seen.add(
          moonFor(
            DateTime(2026, 10, day),
            braunschweig.$1,
            braunschweig.$2,
            zoneOffset: const Duration(hours: 2),
          ).phase,
        );
      }
      // A lunation is 29.5 days, so one calendar month passes every
      // phase. A band that never comes up is a band nothing is ever
      // called.
      expect(seen, hasLength(MoonPhase.values.length));
    });
  });

  test('the device zone is the default, and it is applied once', () {
    // The same day asked for twice: once letting the device's own offset
    // stand, once naming it. Anything else means the zone is being
    // applied twice somewhere, which is exactly the bug that put every
    // moonrise two hours out.
    final date = DateTime(2026, 9, 11);
    final implicit = sunTimesFor(date, braunschweig.$1, braunschweig.$2);
    final explicit = sunTimesFor(
      date,
      braunschweig.$1,
      braunschweig.$2,
      zoneOffset: date.timeZoneOffset,
    );

    expect(implicit.sunrise, explicit.sunrise);
    expect(implicit.sunset, explicit.sunset);
  });
}
