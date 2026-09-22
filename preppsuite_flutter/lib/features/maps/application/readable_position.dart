import 'dart:math' as math;

/// One position, in the several ways it might have to be said out loud.
///
/// The map could already centre on "my location". What it could not do was
/// tell anybody where that is. Standing in a field on the phone to 112,
/// "I am at the blue dot" is not an answer, and reading a decimal fraction
/// digit by digit over a bad line is how a rescue team ends up in the
/// wrong field.
///
/// So the same point is offered in four shapes, because which one is
/// wanted depends on who is listening:
///
///  * **Degrees and minutes** — what a control room asks for, and what
///    survives being read aloud and written down.
///  * **UTM** — metres on a grid, which is what German emergency services
///    and the technical relief service work in.
///  * **MGRS** — the same grid as one short string, which is what a map
///    with a military grid on it is labelled with.
///  * **Plus Code** — eleven characters that need no grid at all, for
///    handing to somebody who is going to type it into a phone.
///
/// All of it is arithmetic on WGS84, computed here and needing nothing:
/// no key, no lookup, no network. That is the point — this is wanted
/// exactly when there is none.
///
/// What this deliberately does **not** do is round. A position is only as
/// good as the fix behind it, so [accuracyMetres] travels with it and the
/// screen says it; shortening the digits instead would hide the doubt
/// rather than state it.
class ReadablePosition {
  const ReadablePosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres,
    this.takenAt,
  });

  final double latitude;
  final double longitude;

  /// How far off the fix may be, as the device reports it. Null when the
  /// position did not come from a receiver — a point picked on the map is
  /// exact in itself.
  final double? accuracyMetres;

  /// When the receiver recorded it. Null for a point that was not
  /// measured at all.
  ///
  /// It matters because a fix is not always fresh: indoors the device
  /// may hand over the last one it managed, which can be minutes or
  /// hours old. Coordinates read out over a radio are a claim about
  /// where somebody is *now*, and an hour-old claim is a different
  /// sentence.
  final DateTime? takenAt;

  /// How stale the fix is, or null where there is nothing to be stale.
  Duration? ageAt(DateTime now) {
    final taken = takenAt;
    if (taken == null) return null;
    final age = now.difference(taken);
    // A receiver clock that runs ahead would otherwise report a
    // negative age, which reads as nonsense rather than as freshness.
    return age.isNegative ? Duration.zero : age;
  }

  /// Whether it is old enough to be worth saying so.
  ///
  /// Two minutes: long enough that a fix taken while the screen was
  /// being opened still counts as now, short enough that somebody who
  /// has walked away from where it was taken is told.
  static const staleAfter = Duration(minutes: 2);

  bool isStaleAt(DateTime now) => (ageAt(now) ?? Duration.zero) >= staleAfter;

  /// `52.516275, 13.377704` — six places, about ten centimetres.
  String get decimal =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';

  /// `52° 30′ 58.6″ N, 13° 22′ 39.7″ E`
  ///
  /// The form a control room reads back. Seconds to one place, which is
  /// about three metres — finer than any handheld fix and coarse enough
  /// to say over a radio without repeating.
  String get degreesMinutesSeconds =>
      '${_dms(latitude, 'N', 'S')}, ${_dms(longitude, 'E', 'W')}';

  /// `33U 389836 5819766`
  ///
  /// Zone, band, then easting and northing in whole metres.
  String get utm {
    final grid = _utm();
    return '${grid.zone}${grid.band} '
        '${grid.easting.round()} ${grid.northing.round()}';
  }

  /// `33U UU 89836 19766`
  ///
  /// The same grid reference, shortened the way a gridded map labels it:
  /// the 100 km square by letter, then five digits each way.
  String get mgrs {
    final grid = _utm();
    final easting = grid.easting.floor();
    final northing = grid.northing.floor();

    final column = _mgrsColumn(grid.zone, easting);
    final row = _mgrsRow(grid.zone, northing);
    final e = (easting % 100000).toString().padLeft(5, '0');
    final n = (northing % 100000).toString().padLeft(5, '0');
    return '${grid.zone}${grid.band} $column$row $e $n';
  }

  /// `9F4MG98H+G3` — an Open Location Code of ten digits.
  ///
  /// About fourteen metres square, and the only one of the four that can
  /// be repeated by somebody who has never seen a map.
  String get plusCode {
    // The canonical integer algorithm rather than repeated division of a
    // double: the published implementations do it this way because the
    // rounding otherwise lands on the wrong square at the edges.
    var lat = (latitude * _latMultiplier).floor() + 90 * _latMultiplier;
    var lon = (longitude * _lonMultiplier).floor() + 180 * _lonMultiplier;
    // A position exactly at the north pole belongs to the last row.
    if (lat >= 180 * _latMultiplier) lat = 180 * _latMultiplier - 1;

    lat = lat ~/ _latGrid;
    lon = lon ~/ _lonGrid;

    final digits = List<String>.filled(10, '');
    for (var place = 4; place >= 0; place--) {
      digits[place * 2] = _codeAlphabet[lat % 20];
      digits[place * 2 + 1] = _codeAlphabet[lon % 20];
      lat ~/= 20;
      lon ~/= 20;
    }
    return '${digits.take(8).join()}+${digits.skip(8).join()}';
  }

  // --- The arithmetic ---------------------------------------------------

  String _dms(double value, String positive, String negative) {
    final hemisphere = value >= 0 ? positive : negative;
    final total = value.abs();
    final degrees = total.floor();
    final minutesTotal = (total - degrees) * 60;
    var minutes = minutesTotal.floor();
    var seconds = (minutesTotal - minutes) * 60;
    // Carrying, because 59.96 seconds must not print as 60.0.
    if (seconds >= 59.95) {
      seconds = 0;
      minutes += 1;
    }
    final carriedDegrees = minutes == 60 ? degrees + 1 : degrees;
    final carriedMinutes = minutes == 60 ? 0 : minutes;
    return '$carriedDegrees° '
        "${carriedMinutes.toString().padLeft(2, '0')}′ "
        '${seconds.toStringAsFixed(1).padLeft(4, '0')}″ '
        '$hemisphere';
  }

  ({int zone, String band, double easting, double northing}) _utm() {
    final zone = utmZone(latitude, longitude);
    final phi = _radians(latitude);
    final centralMeridian = _radians((zone - 1) * 6 - 180 + 3);
    final lambda = _radians(longitude) - centralMeridian;

    final sinPhi = math.sin(phi);
    final cosPhi = math.cos(phi);
    final tanPhi = math.tan(phi);

    final n = _a / math.sqrt(1 - _e2 * sinPhi * sinPhi);
    final t = tanPhi * tanPhi;
    final c = _ep2 * cosPhi * cosPhi;
    final aTerm = cosPhi * lambda;

    final m =
        _a *
        ((1 - _e2 / 4 - 3 * _e2 * _e2 / 64 - 5 * _e2 * _e2 * _e2 / 256) * phi -
            (3 * _e2 / 8 + 3 * _e2 * _e2 / 32 + 45 * _e2 * _e2 * _e2 / 1024) *
                math.sin(2 * phi) +
            (15 * _e2 * _e2 / 256 + 45 * _e2 * _e2 * _e2 / 1024) *
                math.sin(4 * phi) -
            (35 * _e2 * _e2 * _e2 / 3072) * math.sin(6 * phi));

    final a2 = aTerm * aTerm;
    final easting =
        _k0 *
            n *
            (aTerm +
                (1 - t + c) * a2 * aTerm / 6 +
                (5 - 18 * t + t * t + 72 * c - 58 * _ep2) *
                    a2 *
                    a2 *
                    aTerm /
                    120) +
        500000;
    var northing =
        _k0 *
        (m +
            n *
                tanPhi *
                (a2 / 2 +
                    (5 - t + 9 * c + 4 * c * c) * a2 * a2 / 24 +
                    (61 - 58 * t + t * t + 600 * c - 330 * _ep2) *
                        a2 *
                        a2 *
                        a2 /
                        720));
    // The southern hemisphere counts from a false origin so that northings
    // never go negative.
    if (latitude < 0) northing += 10000000;

    return (
      zone: zone,
      band: utmBand(latitude),
      easting: easting,
      northing: northing,
    );
  }

  /// Which six-degree strip [longitude] falls in.
  ///
  /// Two strips are not six degrees wide, and both are in Europe, which is
  /// why they are here rather than left out: 32V was widened in 1950 so
  /// that south-western Norway is not split down the middle, and Svalbard
  /// was rearranged for the same reason.
  static int utmZone(double latitude, double longitude) {
    final normalised = (longitude + 180) % 360 - 180;
    var zone = ((normalised + 180) / 6).floor() + 1;
    if (latitude >= 56 && latitude < 64 && normalised >= 3 && normalised < 12) {
      zone = 32;
    }
    if (latitude >= 72 && latitude < 84) {
      if (normalised >= 0 && normalised < 9) {
        zone = 31;
      } else if (normalised >= 9 && normalised < 21) {
        zone = 33;
      } else if (normalised >= 21 && normalised < 33) {
        zone = 35;
      } else if (normalised >= 33 && normalised < 42) {
        zone = 37;
      }
    }
    return zone;
  }

  /// The eight-degree latitude band letter. I and O are left out, because
  /// they are read as one and zero.
  static String utmBand(double latitude) {
    if (latitude < -80 || latitude > 84) return 'Z';
    // The top band runs twelve degrees rather than eight, so that 84° N
    // still has a letter.
    final index = ((latitude + 80) / 8).floor().clamp(0, 19);
    return _bandLetters[index];
  }

  static String _mgrsColumn(int zone, int easting) {
    final set = (zone - 1) % 3;
    final index = (easting ~/ 100000) - 1 + set * 8;
    return _mgrsColumns[index % 24];
  }

  static String _mgrsRow(int zone, int northing) {
    // Odd zones start the row letters at A, even zones at F. The offset
    // exists so that two squares side by side never carry the same pair.
    final offset = zone.isOdd ? 0 : 5;
    final index = ((northing ~/ 100000) % 20) + offset;
    return _mgrsRows[index % 20];
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

// WGS84, which is what every receiver in a phone reports.
const _a = 6378137.0;
const _f = 1 / 298.257223563;
const _e2 = _f * (2 - _f);
const _ep2 = _e2 / (1 - _e2);
const _k0 = 0.9996;

const _bandLetters = [
  'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', //
  'N', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',
];

/// The three repeating column sets, written out once.
const _mgrsColumns = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
const _mgrsRows = 'ABCDEFGHJKLMNPQRSTUV';

/// Open Location Code: twenty digits, chosen to avoid anything that reads
/// as something else when spoken or written by hand.
const _codeAlphabet = '23456789CFGHJMPQRVWX';
const _latMultiplier = 8000 * 3125;
const _lonMultiplier = 8000 * 1024;
const _latGrid = 3125;
const _lonGrid = 1024;
