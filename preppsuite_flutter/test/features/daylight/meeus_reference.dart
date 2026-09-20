/// A second, higher-precision lunar theory, kept only so the app's own
/// can be held against something.
///
/// `sun_moon.dart` uses the low-precision series from the Astronomical
/// Almanac and says in its own doc comment that it is good to about a
/// fifth of a degree, "a few minutes in a rise time". A claim like that
/// cannot be checked against the code that makes it, and there is no
/// published table in the app to check it against either — so this is
/// the other half: Meeus, *Astronomical Algorithms*, chapter 47, the
/// truncated ELP-2000/82 with sixty terms each for longitude and
/// latitude.
///
/// It shares not one term with the six-term series it is checking, which
/// is the whole point. Test-only, and deliberately verbose: every
/// coefficient is the book's, so a mistyped digit is found by reading
/// rather than by debugging.
library;

import 'dart:math' as math;

const _d = math.pi / 180;

// Table 47.A: D, M, M', F, coefficient for longitude (1e-6 deg),
// coefficient for distance (1e-3 km).
const _tableA = <List<int>>[
  [0, 0, 1, 0, 6288774, -20905355],
  [2, 0, -1, 0, 1274027, -3699111],
  [2, 0, 0, 0, 658314, -2955968],
  [0, 0, 2, 0, 213618, -569925],
  [0, 1, 0, 0, -185116, 48888],
  [0, 0, 0, 2, -114332, -3149],
  [2, 0, -2, 0, 58793, 246158],
  [2, -1, -1, 0, 57066, -152138],
  [2, 0, 1, 0, 53322, -170733],
  [2, -1, 0, 0, 45758, -204586],
  [0, 1, -1, 0, -40923, -129620],
  [1, 0, 0, 0, -34720, 108743],
  [0, 1, 1, 0, -30383, 104755],
  [2, 0, 0, -2, 15327, 10321],
  [0, 0, 1, 2, -12528, 0],
  [0, 0, 1, -2, 10980, 79661],
  [4, 0, -1, 0, 10675, -34782],
  [0, 0, 3, 0, 10034, -23210],
  [4, 0, -2, 0, 8548, -21636],
  [2, 1, -1, 0, -7888, 24208],
  [2, 1, 0, 0, -6766, 30824],
  [1, 0, -1, 0, -5163, -8379],
  [1, 1, 0, 0, 4987, -16675],
  [2, -1, 1, 0, 4036, -12831],
  [2, 0, 2, 0, 3994, -10445],
  [4, 0, 0, 0, 3861, -11650],
  [2, 0, -3, 0, 3665, 14403],
  [0, 1, -2, 0, -2689, -7003],
  [2, 0, -1, 2, -2602, 0],
  [2, -1, -2, 0, 2390, 10056],
  [1, 0, 1, 0, -2348, 6322],
  [2, -2, 0, 0, 2236, -9884],
  [0, 1, 2, 0, -2120, 5751],
  [0, 2, 0, 0, -2069, 0],
  [2, -2, -1, 0, 2048, -4950],
  [2, 0, 1, -2, -1773, 4130],
  [2, 0, 0, 2, -1595, 0],
  [4, -1, -1, 0, 1215, -3958],
  [0, 0, 2, 2, -1110, 0],
  [3, 0, -1, 0, -892, 3258],
  [2, 1, 1, 0, -810, 2616],
  [4, -1, -2, 0, 759, -1897],
  [0, 2, -1, 0, -713, -2117],
  [2, 2, -1, 0, -700, 2354],
  [2, 1, -2, 0, 691, 0],
  [2, -1, 0, -2, 596, 0],
  [4, 0, 1, 0, 549, -1423],
  [0, 0, 4, 0, 537, -1117],
  [4, -1, 0, 0, 520, -1571],
  [1, 0, -2, 0, -487, -1739],
  [2, 1, 0, -2, -399, 0],
  [0, 0, 2, -2, -381, -4421],
  [1, 1, 1, 0, 351, 0],
  [3, 0, -2, 0, -340, 0],
  [4, 0, -3, 0, 330, 0],
  [2, -1, 2, 0, 327, 0],
  [0, 2, 1, 0, -323, 1165],
  [1, 1, -1, 0, 299, 0],
  [2, 0, 3, 0, 294, 0],
  [2, 0, -1, -2, 0, 8752],
];

// Table 47.B: D, M, M', F, coefficient for latitude (1e-6 deg).
const _tableB = <List<int>>[
  [0, 0, 0, 1, 5128122],
  [0, 0, 1, 1, 280602],
  [0, 0, 1, -1, 277693],
  [2, 0, 0, -1, 173237],
  [2, 0, -1, 1, 55413],
  [2, 0, -1, -1, 46271],
  [2, 0, 0, 1, 32573],
  [0, 0, 2, 1, 17198],
  [2, 0, 1, -1, 9266],
  [0, 0, 2, -1, 8822],
  [2, -1, 0, -1, 8216],
  [2, 0, -2, -1, 4324],
  [2, 0, 1, 1, 4200],
  [2, 1, 0, -1, -3359],
  [2, -1, -1, 1, 2463],
  [2, -1, 0, 1, 2211],
  [2, -1, -1, -1, 2065],
  [0, 1, -1, -1, -1870],
  [4, 0, -1, -1, 1828],
  [0, 1, 0, 1, -1794],
  [0, 0, 0, 3, -1749],
  [0, 1, -1, 1, -1565],
  [1, 0, 0, 1, -1491],
  [0, 1, 1, 1, -1475],
  [0, 1, 1, -1, -1410],
  [0, 1, 0, -1, -1344],
  [1, 0, 0, -1, -1335],
  [0, 0, 3, 1, 1107],
  [4, 0, 0, -1, 1021],
  [4, 0, -1, 1, 833],
  [0, 0, 1, -3, 777],
  [4, 0, -2, 1, 671],
  [2, 0, 0, -3, 607],
  [2, 0, 2, -1, 596],
  [2, -1, 1, -1, 491],
  [2, 0, -2, 1, -451],
  [0, 0, 3, -1, 439],
  [2, 0, 2, 1, 422],
  [2, 0, -3, -1, 421],
  [2, 1, -1, 1, -366],
  [2, 1, 0, 1, -351],
  [4, 0, 0, 1, 331],
  [2, -1, 1, 1, 315],
  [2, -2, 0, -1, 302],
  [0, 0, 1, 3, -283],
  [2, 1, 1, -1, -229],
  [1, 1, 0, -1, 223],
  [1, 1, 0, 1, 223],
  [0, 1, -2, -1, -220],
  [2, 1, -1, -1, -220],
  [1, 0, 1, 1, -185],
  [2, -1, -2, -1, 181],
  [0, 1, 2, 1, -177],
  [4, 0, -2, -1, 176],
  [4, -1, -1, -1, 166],
  [1, 0, 1, -1, -164],
  [4, 0, 1, -1, 132],
  [1, 0, -1, -1, -119],
  [4, -1, 0, -1, 115],
  [2, -2, 0, 1, 107],
];

/// Apparent geocentric longitude, latitude (degrees) and equatorial
/// horizontal parallax (degrees).
({double longitude, double latitude, double parallax}) meeusMoon(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final lp =
      218.3164477 +
      481267.88123421 * t -
      0.0015786 * t * t +
      t * t * t / 538841 -
      t * t * t * t / 65194000;
  final dd =
      297.8501921 +
      445267.1114034 * t -
      0.0018819 * t * t +
      t * t * t / 545868 -
      t * t * t * t / 113065000;
  final m =
      357.5291092 +
      35999.0502909 * t -
      0.0001536 * t * t +
      t * t * t / 24490000;
  final mp =
      134.9633964 +
      477198.8675055 * t +
      0.0087414 * t * t +
      t * t * t / 69699 -
      t * t * t * t / 14712000;
  final f =
      93.2720950 +
      483202.0175233 * t -
      0.0036539 * t * t -
      t * t * t / 3526000 +
      t * t * t * t / 863310000;
  final a1 = 119.75 + 131.849 * t;
  final a2 = 53.09 + 479264.290 * t;
  final a3 = 313.45 + 481266.484 * t;
  final e = 1 - 0.002516 * t - 0.0000074 * t * t;

  double ePow(int mm) => switch (mm.abs()) {
    0 => 1.0,
    1 => e,
    _ => e * e,
  };

  var sumL = 0.0, sumR = 0.0, sumB = 0.0;
  for (final row in _tableA) {
    final arg = (row[0] * dd + row[1] * m + row[2] * mp + row[3] * f) * _d;
    sumL += row[4] * ePow(row[1]) * math.sin(arg);
    sumR += row[5] * ePow(row[1]) * math.cos(arg);
  }
  for (final row in _tableB) {
    final arg = (row[0] * dd + row[1] * m + row[2] * mp + row[3] * f) * _d;
    sumB += row[4] * ePow(row[1]) * math.sin(arg);
  }

  sumL +=
      3958 * math.sin(a1 * _d) +
      1962 * math.sin((lp - f) * _d) +
      318 * math.sin(a2 * _d);
  sumB +=
      -2235 * math.sin(lp * _d) +
      382 * math.sin(a3 * _d) +
      175 * math.sin((a1 - f) * _d) +
      175 * math.sin((a1 + f) * _d) +
      127 * math.sin((lp - mp) * _d) -
      115 * math.sin((lp + mp) * _d);

  final distanceKm = 385000.56 + sumR / 1000;
  return (
    longitude: (lp + sumL / 1000000) % 360,
    latitude: sumB / 1000000,
    parallax: math.asin(6378.14 / distanceKm) / _d,
  );
}

/// The sun's apparent longitude, to the same standard (Meeus ch. 25).
double meeusSunLongitude(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final l0 = 280.46646 + 36000.76983 * t + 0.0003032 * t * t;
  final m = 357.52911 + 35999.05029 * t - 0.0001537 * t * t;
  final c =
      (1.914602 - 0.004817 * t - 0.000014 * t * t) * math.sin(m * _d) +
      (0.019993 - 0.000101 * t) * math.sin(2 * m * _d) +
      0.000289 * math.sin(3 * m * _d);
  final omega = 125.04 - 1934.136 * t;
  return (l0 + c - 0.00569 - 0.00478 * math.sin(omega * _d)) % 360;
}

double meeusGmst(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  return (280.46061837 +
          360.98564736629 * (jd - 2451545.0) +
          0.000387933 * t * t -
          t * t * t / 38710000) %
      360;
}

/// Geocentric altitude in degrees, using the true obliquity.
double meeusMoonAltitude(double jd, double lat, double lon) {
  final moon = meeusMoon(jd);
  final t = (jd - 2451545.0) / 36525.0;
  final eps =
      (23 +
          (26 + (21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813))) / 60) /
              60) *
      _d;
  final lambda = moon.longitude * _d;
  final beta = moon.latitude * _d;
  final ra =
      math.atan2(
        math.sin(lambda) * math.cos(eps) - math.tan(beta) * math.sin(eps),
        math.cos(lambda),
      ) /
      _d;
  final dec = math.asin(
    math.sin(beta) * math.cos(eps) +
        math.cos(beta) * math.sin(eps) * math.sin(lambda),
  );
  final ha = (meeusGmst(jd) + lon - ra) * _d;
  return math.asin(
        math.sin(lat * _d) * math.sin(dec) +
            math.cos(lat * _d) * math.cos(dec) * math.cos(ha),
      ) /
      _d;
}

/// Meeus eq. 15.1 for the moon: the same convention the app uses.
double meeusMoonHorizon(double jd) => 0.7275 * meeusMoon(jd).parallax - 0.5667;

double julianDayOf(DateTime moment) =>
    moment.toUtc().millisecondsSinceEpoch / 86400000.0 + 2440587.5;

/// Moonrise and moonset on the UTC day [date], from the theory above.
///
/// The same ten-minute scan and the same threshold the app uses, so that
/// what is left when the two are subtracted is the difference between
/// the two series and nothing else.
({DateTime? rise, DateTime? set}) referenceMoonEvents(
  DateTime date,
  double latitude,
  double longitude,
) {
  final start = DateTime.utc(date.year, date.month, date.day);

  double above(DateTime moment) {
    final jd = julianDayOf(moment);
    return meeusMoonAltitude(jd, latitude, longitude) - meeusMoonHorizon(jd);
  }

  DateTime crossing(DateTime low, DateTime high) {
    var start = low;
    var end = high;
    for (var i = 0; i < 24; i++) {
      final middle = start.add(end.difference(start) ~/ 2);
      if ((above(start) <= 0) == (above(middle) <= 0)) {
        start = middle;
      } else {
        end = middle;
      }
    }
    return start.add(end.difference(start) ~/ 2);
  }

  DateTime? rise;
  DateTime? set;
  var previous = start;
  var previousAltitude = above(previous);
  for (var step = 1; step <= 144; step++) {
    final moment = start.add(Duration(minutes: 10 * step));
    final altitude = above(moment);
    if ((previousAltitude <= 0) != (altitude <= 0)) {
      final found = crossing(previous, moment);
      if (altitude > previousAltitude) {
        rise ??= found;
      } else {
        set ??= found;
      }
    }
    previous = moment;
    previousAltitude = altitude;
  }
  return (rise: rise, set: set);
}

/// The lit fraction at local noon on [date], the way [moonFor] takes it.
double referenceIllumination(DateTime date) {
  final jd = julianDayOf(DateTime.utc(date.year, date.month, date.day)) + 0.5;
  final moon = meeusMoon(jd);
  final elongation = math.acos(
    (math.cos(moon.latitude * _d) *
            math.cos((moon.longitude - meeusSunLongitude(jd)) * _d))
        .clamp(-1.0, 1.0),
  );
  return (1 - math.cos(elongation)) / 2;
}
