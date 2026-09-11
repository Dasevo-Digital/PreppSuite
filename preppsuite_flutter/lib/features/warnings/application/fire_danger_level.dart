/// The DWD's forest fire danger index, and what its five levels mean.
///
/// The wording is the DWD's own and not this app's — "sehr geringe
/// Gefahr" through "sehr hohe Gefahr" — for the same reason the radiation
/// bands are the BfS's: an index is only useful if it says what the
/// authority issuing it says, and a five-step scale invites being
/// re-described one step too dramatically.
///
/// What it is *not* is a warning. The WBI describes the meteorological
/// potential for forest fire; whether a Land forbids entering a forest or
/// lighting a fire is the Land's decision and arrives, where it is
/// warned about at all, through the BBK feed this app already reads.
///
/// Source: dwd.de, "Informationen zum Waldbrandgefahrenindex WBI".
library;

/// One of the five steps the DWD publishes.
enum FireDangerLevel {
  /// Stufe 1 — sehr geringe Gefahr.
  veryLow(1),

  /// Stufe 2 — geringe Gefahr.
  low(2),

  /// Stufe 3 — mittlere Gefahr.
  moderate(3),

  /// Stufe 4 — hohe Gefahr.
  high(4),

  /// Stufe 5 — sehr hohe Gefahr.
  veryHigh(5);

  const FireDangerLevel(this.step);

  /// The number the DWD's own tables and signs use.
  final int step;

  static FireDangerLevel? fromStep(int step) {
    for (final value in values) {
      if (value.step == step) return value;
    }
    return null;
  }
}

/// The index for one station: today, and as far ahead as the DWD looks.
class FireDangerForecast {
  const FireDangerForecast({
    required this.stationName,
    required this.issuedFor,
    required this.days,
  });

  final String stationName;

  /// The day the row was issued for, which is the first entry of [days].
  final DateTime issuedFor;

  /// Today first, then each following day. The DWD publishes seven
  /// columns; a row with fewer is taken as far as it goes rather than
  /// discarded.
  final List<FireDangerLevel> days;

  FireDangerLevel get today => days.first;

  /// The worst level in the days ahead, and how far away it is.
  ///
  /// This is the thing worth knowing that a single number does not say:
  /// level 2 today with level 5 the day after tomorrow is a different
  /// situation from level 2 all week, and both read as "2" on the front
  /// of the screen.
  ({FireDangerLevel level, int inDays})? get peakAhead {
    if (days.length < 2) return null;

    var worst = days[1];
    var when = 1;
    for (var i = 2; i < days.length; i++) {
      if (days[i].step > worst.step) {
        worst = days[i];
        when = i;
      }
    }
    return worst.step > today.step ? (level: worst, inDays: when) : null;
  }

  /// Whether the forecast is too old to show as current.
  ///
  /// The DWD issues once a day, in the small hours, and only during the
  /// fire season — March to October, adjusted to the weather. Two days
  /// behind therefore means either the season has ended or the app has
  /// not reached the service, and both of those have to be said rather
  /// than presenting a level from last week as today's.
  bool isStale({DateTime? now}) {
    final today = now ?? DateTime.now();
    final issued = DateTime(issuedFor.year, issuedFor.month, issuedFor.day);
    final asked = DateTime(today.year, today.month, today.day);
    return asked.difference(issued).inDays > 1;
  }
}

/// The rows of one station's forecast file, newest first.
///
/// The file keeps the whole season, so the newest row is the one that
/// matters and the rest is history. Rows that do not parse are skipped
/// rather than failing the file: one malformed line costs a day, not the
/// forecast.
List<FireDangerForecast> parseForecast(String csv, {required String station}) {
  final forecasts = <FireDangerForecast>[];

  for (final line in csv.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('StationsID')) continue;

    final fields = trimmed.split(';');
    if (fields.length < 3) continue;

    final issued = _date(fields[1]);
    if (issued == null) continue;

    final days = <FireDangerLevel>[];
    for (final field in fields.skip(2)) {
      final step = int.tryParse(field.trim());
      final level = step == null ? null : FireDangerLevel.fromStep(step);
      // The columns run out at the end of the row, and a gap in the
      // middle ends the run rather than shifting every later day one
      // place closer.
      if (level == null) break;
      days.add(level);
    }
    if (days.isEmpty) continue;

    forecasts.add(
      FireDangerForecast(
        stationName: station,
        issuedFor: issued,
        days: days,
      ),
    );
  }

  forecasts.sort((a, b) => b.issuedFor.compareTo(a.issuedFor));
  return forecasts;
}

/// `20260911 04:14` — the issue date and the time of the model run.
///
/// Only the date is kept. The run time is when the DWD computed it, not
/// anything about the day being described, and showing 04:14 next to a
/// danger level would invite reading it as the hour the danger applies.
DateTime? _date(String field) {
  final value = field.trim();
  if (value.length < 8) return null;

  final year = int.tryParse(value.substring(0, 4));
  final month = int.tryParse(value.substring(4, 6));
  final day = int.tryParse(value.substring(6, 8));
  if (year == null || month == null || day == null) return null;
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;

  return DateTime(year, month, day);
}
