import 'dart:math' as math;

/// Sun and moon, worked out on the device.
///
/// The one reference in this app that needs neither a network nor an
/// authority: it is arithmetic over the calendar, the same arithmetic an
/// almanac has printed for two centuries. Nothing here is fetched, and
/// nothing here can go stale.
///
/// Why it earns a screen: without a light switch, the sun is the working
/// day, and whether the moon is up decides whether moving at night is
/// possible at all. Both are questions with exact answers, and neither is
/// answerable once the phone has no signal — unless the answer is already
/// in the phone.
///
/// The sun follows the NOAA solar-position algorithm and is good to well
/// under a minute. The moon follows the low-precision series from the
/// Astronomical Almanac, which holds its longitude to about a fifth of a
/// degree — a few minutes in a rise time. The screen says so rather than
/// printing seconds it has not got.

const _degrees = math.pi / 180;

/// The twilight thresholds, as altitudes of the sun's centre in degrees.
///
/// The first is not zero and never was: the sun's disc has a radius of
/// about sixteen arcminutes and the atmosphere lifts it another
/// thirty-four, so sunrise is the moment its centre stands 50 arcminutes
/// *below* the horizon.
const _sunriseAltitude = -0.833;
const _civilAltitude = -6.0;
const _nauticalAltitude = -12.0;

/// When the sun does what, on one day at one place.
class SunTimes {
  const SunTimes({
    required this.date,
    this.civilDawn,
    this.sunrise,
    this.solarNoon,
    this.sunset,
    this.civilDusk,
    this.nauticalDawn,
    this.nauticalDusk,
    required this.alwaysUp,
    required this.alwaysDown,
  });

  /// The local day this is about.
  final DateTime date;

  /// All in local time. Null where the event does not happen — which is
  /// not an error and not rare: north of the Arctic circle in June there
  /// is no sunrise, and saying "00:00" would be a lie rather than a gap.
  final DateTime? civilDawn;
  final DateTime? sunrise;
  final DateTime? solarNoon;
  final DateTime? sunset;
  final DateTime? civilDusk;
  final DateTime? nauticalDawn;
  final DateTime? nauticalDusk;

  /// The sun never set, or never rose.
  final bool alwaysUp;
  final bool alwaysDown;

  /// From sunrise to sunset, where both happened.
  Duration? get dayLength {
    final up = sunrise;
    final down = sunset;
    if (up == null || down == null) return null;
    return down.difference(up);
  }

  /// How long there is usable light after the sun is down — the half hour
  /// that decides whether a walk home is a walk or a stumble.
  Duration? get eveningTwilight {
    final down = sunset;
    final dark = civilDusk;
    if (down == null || dark == null) return null;
    return dark.difference(down);
  }
}

/// The moon at one instant.
class MoonState {
  const MoonState({
    required this.illumination,
    required this.waxing,
    required this.phase,
    this.rise,
    this.set,
    required this.upAllDay,
    required this.downAllDay,
  });

  /// Lit fraction of the disc, 0 to 1.
  final double illumination;

  /// Growing rather than shrinking. What tells a first quarter from a
  /// last quarter, which are the same picture otherwise.
  final bool waxing;

  final MoonPhase phase;

  /// Local time, or null where it does not happen on this day — the moon
  /// rises about fifty minutes later each day, so roughly one day in
  /// thirty has no moonrise at all.
  final DateTime? rise;
  final DateTime? set;

  final bool upAllDay;
  final bool downAllDay;
}

/// The eight names, which is how a phase is spoken about.
enum MoonPhase {
  newMoon,
  waxingCrescent,
  firstQuarter,
  waxingGibbous,
  fullMoon,
  waningGibbous,
  lastQuarter,
  waningCrescent,
}

/// Sun events for the local day [date] at [latitude]/[longitude].
///
/// [date]'s time of day is ignored. Results are expressed in
/// [zoneOffset], which defaults to the device's own — the right default,
/// because the person reading this is standing at the place they asked
/// about. It is a parameter so that the arithmetic can be checked
/// against published tables for places in other zones.
SunTimes sunTimesFor(
  DateTime date,
  double latitude,
  double longitude, {
  Duration? zoneOffset,
}) {
  final local = DateTime(date.year, date.month, date.day);
  final toLocal = _converter(zoneOffset);
  // The calendar date as an instant, with no zone applied. Everything
  // below is UTC arithmetic; letting `toUtc` in would apply the
  // machine's own zone on top of it.
  final midnight = DateTime.utc(local.year, local.month, local.day);

  DateTime? at(double altitude, {required bool morning}) {
    final minutes = _sunEventMinutes(
      midnight,
      latitude,
      longitude,
      altitude,
      morning: morning,
    );
    return minutes == null ? null : toLocal(_instantAt(midnight, minutes));
  }

  final sunrise = at(_sunriseAltitude, morning: true);
  final sunset = at(_sunriseAltitude, morning: false);

  // Neither a rise nor a set means one of two very different days, and
  // the sun's altitude at noon is what tells them apart.
  var alwaysUp = false;
  var alwaysDown = false;
  if (sunrise == null && sunset == null) {
    final noonAltitude = _sunAltitude(
      _julianDay(midnight) + 0.5 - longitude / 360,
      latitude,
      longitude,
    );
    alwaysUp = noonAltitude > _sunriseAltitude;
    alwaysDown = !alwaysUp;
  }

  final noonMinutes = _solarNoonMinutes(midnight, longitude);

  return SunTimes(
    date: local,
    nauticalDawn: at(_nauticalAltitude, morning: true),
    civilDawn: at(_civilAltitude, morning: true),
    sunrise: sunrise,
    solarNoon: toLocal(_instantAt(midnight, noonMinutes)),
    sunset: sunset,
    civilDusk: at(_civilAltitude, morning: false),
    nauticalDusk: at(_nauticalAltitude, morning: false),
    alwaysUp: alwaysUp,
    alwaysDown: alwaysDown,
  );
}

/// The moon on the local day [date] at [latitude]/[longitude].
MoonState moonFor(
  DateTime date,
  double latitude,
  double longitude, {
  Duration? zoneOffset,
}) {
  final local = DateTime(date.year, date.month, date.day);
  final toLocal = _converter(zoneOffset);
  // Midnight local, as a real UTC instant. `DateTime` already knows how
  // to do that for the device's own zone; where a zone is named instead,
  // the offset comes off by hand.
  final startUtc = zoneOffset == null
      ? local.toUtc()
      : DateTime.utc(
          local.year,
          local.month,
          local.day,
        ).subtract(zoneOffset);

  // Taken at local noon rather than at midnight: it is the figure for
  // "tonight", and the moon's lit fraction moves by a couple of points
  // over a day.
  final noonJulian = _julianDay(startUtc) + 0.5;
  final illumination = _moonIllumination(noonJulian);
  final waxing = _moonWaxing(noonJulian);

  // Rise and set by walking the day in ten-minute steps and bisecting
  // every crossing of the horizon. The moon moves thirteen degrees a day
  // against the stars, which is far too much for the closed-form solution
  // the sun gets — an hourly scan is the standard answer and this is a
  // finer one.
  const step = Duration(minutes: 10);

  /// The moon's height above its own rise-and-set threshold: positive
  /// when it is up, negative when it is down, and zero at the crossing.
  double aboveHorizon(DateTime moment) {
    final julianDay = _julianDay(moment);
    return _moonAltitude(julianDay, latitude, longitude) -
        _moonHorizonFor(julianDay);
  }

  DateTime? rise;
  DateTime? set;
  var previous = startUtc;
  var previousAltitude = aboveHorizon(previous);
  var everUp = previousAltitude > 0;
  var everDown = previousAltitude <= 0;

  for (var minutes = 10; minutes <= 24 * 60; minutes += 10) {
    final moment = startUtc.add(step * (minutes ~/ 10));
    final altitude = aboveHorizon(moment);
    everUp |= altitude > 0;
    everDown |= altitude <= 0;

    if ((previousAltitude <= 0) != (altitude <= 0)) {
      final crossing = _bisect(previous, moment, aboveHorizon);
      if (altitude > previousAltitude) {
        rise ??= toLocal(crossing);
      } else {
        set ??= toLocal(crossing);
      }
    }
    previous = moment;
    previousAltitude = altitude;
  }

  return MoonState(
    illumination: illumination,
    waxing: waxing,
    phase: _phaseFor(illumination, waxing),
    rise: rise,
    set: set,
    upAllDay: !everDown,
    downAllDay: !everUp,
  );
}

/// A UTC instant read as the wall clock in a zone that is [offset] ahead.
///
/// Milliseconds and all, so that this and `toLocal` give the same answer
/// for the same instant rather than one that is rounded and one that is
/// not.
DateTime _wallClock(DateTime instant, Duration offset) {
  final wall = instant.add(offset);
  return DateTime(
    wall.year,
    wall.month,
    wall.day,
    wall.hour,
    wall.minute,
    wall.second,
    wall.millisecond,
  );
}

DateTime _bisect(
  DateTime low,
  DateTime high,
  double Function(DateTime) altitude,
) {
  var start = low;
  var end = high;
  // Twelve halvings of ten minutes is a seventh of a second, which is far
  // finer than the series behind it deserves — but it costs nothing and
  // it stops the answer depending on the step size.
  for (var i = 0; i < 12; i++) {
    final middle = start.add(end.difference(start) ~/ 2);
    if ((altitude(start) <= 0) == (altitude(middle) <= 0)) {
      start = middle;
    } else {
      end = middle;
    }
  }
  return start.add(end.difference(start) ~/ 2);
}

MoonPhase _phaseFor(double illumination, bool waxing) {
  // By lit fraction rather than by age, because that is what somebody
  // looking up sees. The quarters own a band around a half-lit disc
  // instead of an instant, or "first quarter" would be a name nothing is
  // ever called.
  if (illumination < 0.04) return MoonPhase.newMoon;
  if (illumination > 0.96) return MoonPhase.fullMoon;
  if (illumination > 0.46 && illumination < 0.54) {
    return waxing ? MoonPhase.firstQuarter : MoonPhase.lastQuarter;
  }
  if (illumination < 0.5) {
    return waxing ? MoonPhase.waxingCrescent : MoonPhase.waningCrescent;
  }
  return waxing ? MoonPhase.waxingGibbous : MoonPhase.waningGibbous;
}

// --- the arithmetic ---------------------------------------------------

/// Julian day for an instant, which every formula below is written in.
double _julianDay(DateTime moment) =>
    moment.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

/// Julian centuries since J2000.
double _centuries(double julianDay) => (julianDay - 2451545.0) / 36525.0;

/// The sun's declination and the equation of time, both in one pass —
/// they share every term up to the last two lines.
({double declination, double equationOfTime}) _sun(double julianDay) {
  final t = _centuries(julianDay);

  final meanLongitude = (280.46646 + t * (36000.76983 + 0.0003032 * t)) % 360;
  final meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final eccentricity = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);

  final centre =
      math.sin(meanAnomaly * _degrees) *
          (1.914602 - t * (0.004817 + 0.000014 * t)) +
      math.sin(2 * meanAnomaly * _degrees) * (0.019993 - 0.000101 * t) +
      math.sin(3 * meanAnomaly * _degrees) * 0.000289;

  final trueLongitude = meanLongitude + centre;
  final omega = 125.04 - 1934.136 * t;
  final apparentLongitude =
      trueLongitude - 0.00569 - 0.00478 * math.sin(omega * _degrees);

  final meanObliquity =
      23 +
      (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60;
  final obliquity = meanObliquity + 0.00256 * math.cos(omega * _degrees);

  final declination = math.asin(
    math.sin(obliquity * _degrees) * math.sin(apparentLongitude * _degrees),
  );

  final y = math.pow(math.tan(obliquity * _degrees / 2), 2).toDouble();
  final equationOfTime =
      4 /
      _degrees *
      (y * math.sin(2 * meanLongitude * _degrees) -
          2 * eccentricity * math.sin(meanAnomaly * _degrees) +
          4 *
              eccentricity *
              y *
              math.sin(meanAnomaly * _degrees) *
              math.cos(2 * meanLongitude * _degrees) -
          0.5 * y * y * math.sin(4 * meanLongitude * _degrees) -
          1.25 *
              eccentricity *
              eccentricity *
              math.sin(2 * meanAnomaly * _degrees));

  return (declination: declination, equationOfTime: equationOfTime);
}

/// Minutes after midnight UTC at which the sun stands at [altitude].
///
/// Null where it never does on that day. Solved twice: the declination
/// changes over the day, so the first answer is used to re-evaluate it
/// nearer the event.
double? _sunEventMinutes(
  DateTime midnightUtc,
  double latitude,
  double longitude,
  double altitude, {
  required bool morning,
}) {
  final noonJulian = _julianDay(midnightUtc) + 0.5 - longitude / 360;

  double? solve(double julianDay) {
    final sun = _sun(julianDay);
    final cosHourAngle =
        (math.cos((90 - altitude) * _degrees) -
            math.sin(latitude * _degrees) * math.sin(sun.declination)) /
        (math.cos(latitude * _degrees) * math.cos(sun.declination));
    // Outside ±1 the sun never reaches that altitude on this day: the
    // midnight sun, or the polar night, or simply a twilight that never
    // ends at midsummer in Hamburg.
    if (cosHourAngle < -1 || cosHourAngle > 1) return null;

    final hourAngle = math.acos(cosHourAngle) / _degrees;
    return 720 -
        4 * (longitude + (morning ? hourAngle : -hourAngle)) -
        sun.equationOfTime;
  }

  final first = solve(noonJulian);
  if (first == null) return null;
  return solve(noonJulian + first / 1440 - 0.5) ?? first;
}

double _solarNoonMinutes(DateTime midnightUtc, double longitude) {
  final julianDay = _julianDay(midnightUtc) + 0.5 - longitude / 360;
  return 720 - 4 * longitude - _sun(julianDay).equationOfTime;
}

/// The instant [minutes] after [midnightUtc].
DateTime _instantAt(DateTime midnightUtc, double minutes) =>
    midnightUtc.add(Duration(milliseconds: (minutes * 60000).round()));

/// How a UTC instant becomes the time somebody reads off a clock.
///
/// With no [zoneOffset] given this is Dart's own `toLocal`, which is the
/// only thing that gets the two days a year when the clocks change
/// right: a fixed offset taken at midnight would put every event on the
/// morning of the last Sunday in March an hour out. The fixed offset
/// exists so that the arithmetic can be checked against tables published
/// for other zones.
DateTime Function(DateTime) _converter(Duration? zoneOffset) =>
    zoneOffset == null
    ? (instant) => instant.toLocal()
    : (instant) => _wallClock(instant, zoneOffset);

double _sunAltitude(double julianDay, double latitude, double longitude) {
  final sun = _sun(julianDay);
  final hourAngle =
      (_greenwichSiderealTime(julianDay) +
          longitude -
          _sunRightAscension(julianDay)) *
      _degrees;
  return math.asin(
        math.sin(latitude * _degrees) * math.sin(sun.declination) +
            math.cos(latitude * _degrees) *
                math.cos(sun.declination) *
                math.cos(hourAngle),
      ) /
      _degrees;
}

double _sunRightAscension(double julianDay) {
  final t = _centuries(julianDay);
  final meanLongitude = (280.46646 + t * (36000.76983 + 0.0003032 * t)) % 360;
  final meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final centre =
      math.sin(meanAnomaly * _degrees) * 1.914602 +
      math.sin(2 * meanAnomaly * _degrees) * 0.019993;
  final longitude = (meanLongitude + centre) * _degrees;
  final obliquity = 23.439 * _degrees;
  return math.atan2(
        math.cos(obliquity) * math.sin(longitude),
        math.cos(longitude),
      ) /
      _degrees;
}

/// Greenwich mean sidereal time in degrees.
double _greenwichSiderealTime(double julianDay) {
  final t = _centuries(julianDay);
  return (280.46061837 +
          360.98564736629 * (julianDay - 2451545.0) +
          0.000387933 * t * t -
          t * t * t / 38710000) %
      360;
}

/// The moon's apparent ecliptic longitude, latitude and parallax.
///
/// The low-precision series from the Astronomical Almanac: good to about
/// a fifth of a degree in longitude, which is a few minutes in a rise
/// time and nothing at all in a lit fraction.
({double longitude, double latitude, double parallax}) _moon(
  double julianDay,
) {
  final t = _centuries(julianDay);

  final longitude =
      218.32 +
      481267.881 * t +
      6.29 * math.sin((134.9 + 477198.85 * t) * _degrees) -
      1.27 * math.sin((259.2 - 413335.38 * t) * _degrees) +
      0.66 * math.sin((235.7 + 890534.23 * t) * _degrees) +
      0.21 * math.sin((269.9 + 954397.70 * t) * _degrees) -
      0.19 * math.sin((357.5 + 35999.05 * t) * _degrees) -
      0.11 * math.sin((186.6 + 966404.05 * t) * _degrees);

  final latitude =
      5.13 * math.sin((93.3 + 483202.03 * t) * _degrees) +
      0.28 * math.sin((228.2 + 960400.87 * t) * _degrees) -
      0.28 * math.sin((318.3 + 6003.18 * t) * _degrees) -
      0.17 * math.sin((217.6 - 407332.20 * t) * _degrees);

  final parallax =
      0.9508 +
      0.0518 * math.cos((134.9 + 477198.85 * t) * _degrees) +
      0.0095 * math.cos((259.2 - 413335.38 * t) * _degrees) +
      0.0078 * math.cos((235.7 + 890534.23 * t) * _degrees) +
      0.0028 * math.cos((269.9 + 954397.70 * t) * _degrees);

  return (
    longitude: longitude % 360,
    latitude: latitude,
    parallax: parallax,
  );
}

/// The sun's apparent ecliptic longitude, for the elongation below.
double _sunLongitude(double julianDay) {
  final t = _centuries(julianDay);
  final meanLongitude = 280.46646 + t * (36000.76983 + 0.0003032 * t);
  final meanAnomaly = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  return (meanLongitude +
          math.sin(meanAnomaly * _degrees) * 1.914602 +
          math.sin(2 * meanAnomaly * _degrees) * 0.019993) %
      360;
}

double _moonIllumination(double julianDay) {
  final moon = _moon(julianDay);
  final elongation = math.acos(
    math.cos(moon.latitude * _degrees) *
        math.cos((moon.longitude - _sunLongitude(julianDay)) * _degrees),
  );
  // The lit fraction of a sphere seen at that elongation. The refinement
  // for the sun's finite distance changes it by well under a percent,
  // which is invisible next to "gut zur Hälfte beleuchtet".
  return (1 - math.cos(elongation)) / 2;
}

bool _moonWaxing(double julianDay) {
  final difference =
      (_moon(julianDay).longitude - _sunLongitude(julianDay) + 360) % 360;
  return difference < 180;
}

/// How far above the geocentric horizon the moon's centre has to stand
/// for its upper limb to be visible from the ground.
///
/// `0.7275 * parallax - 34'`, which is Meeus's own figure: the first term
/// is how much closer to the horizon the moon looks from the surface than
/// from the centre of the Earth, the second is refraction and the disc's
/// own radius. It comes to about +0.125 degrees, and it is compared
/// against the *geocentric* altitude — subtracting the parallax as well
/// counts it twice, which put every moonrise six or seven minutes late
/// and every moonset the same amount early against the US Naval
/// Observatory's tables.
double _moonHorizonFor(double julianDay) =>
    0.7275 * _moon(julianDay).parallax - 0.5667;

double _moonAltitude(double julianDay, double latitude, double longitude) {
  final moon = _moon(julianDay);
  final obliquity = 23.439 * _degrees;

  final lambda = moon.longitude * _degrees;
  final beta = moon.latitude * _degrees;

  final rightAscension =
      math.atan2(
        math.sin(lambda) * math.cos(obliquity) -
            math.tan(beta) * math.sin(obliquity),
        math.cos(lambda),
      ) /
      _degrees;
  final declination = math.asin(
    math.sin(beta) * math.cos(obliquity) +
        math.cos(beta) * math.sin(obliquity) * math.sin(lambda),
  );

  final hourAngle =
      (_greenwichSiderealTime(julianDay) + longitude - rightAscension) *
      _degrees;

  final geocentric = math.asin(
    math.sin(latitude * _degrees) * math.sin(declination) +
        math.cos(latitude * _degrees) *
            math.cos(declination) *
            math.cos(hourAngle),
  );

  return geocentric / _degrees;
}
