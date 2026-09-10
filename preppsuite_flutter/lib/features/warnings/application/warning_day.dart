/// The nationwide warning day, worked out rather than fetched.
///
/// It is the one day a year on which the whole chain is tested — sirens,
/// Cell Broadcast, radio, the warning apps — and therefore the only day
/// on which a household can find out whether its own warning routes
/// actually reach it. A route that fails on a real warning fails silently:
/// nobody notices a notification that never came.
///
/// Computed from a rule and not read from a feed, because the rule has
/// been fixed since the warning day became annual: the second Thursday in
/// September. That keeps this working on a device that has been offline
/// for a year, which is the sort of device this is for.
///
/// The federal day only. Bayern, Hessen, Nordrhein-Westfalen and
/// Rheinland-Pfalz test on further dates of their own, and those follow no
/// rule this could compute — claiming otherwise would be worse than saying
/// nothing.
library;

/// 11:00 is when the test warning goes out, 11:45 the all-clear.
const warningDayTestHour = 11;
const warningDayAllClearMinute = 45;

/// The federal warning day in [year]: the second Thursday in September.
DateTime federalWarningDay(int year) {
  final first = DateTime(year, 9);
  // DateTime.thursday is 4, and weekday runs 1..7 from Monday, so this is
  // the offset to the first Thursday — zero when the first already is one.
  final toFirstThursday = (DateTime.thursday - first.weekday) % 7;
  return DateTime(year, 9, 1 + toFirstThursday + 7);
}

/// The next warning day at or after [from], which may be [from] itself.
///
/// Today counts as "next" all day: the point of knowing is to check the
/// warning routes, and that is still worth doing at four in the afternoon.
DateTime nextFederalWarningDay({DateTime? from}) {
  final today = _midnight(from ?? DateTime.now());
  final thisYear = federalWarningDay(today.year);
  if (!thisYear.isBefore(today)) return thisYear;
  return federalWarningDay(today.year + 1);
}

/// Whole days from [from] to the next warning day; zero on the day.
int daysUntilFederalWarningDay({DateTime? from}) {
  final today = _midnight(from ?? DateTime.now());
  return nextFederalWarningDay(from: today).difference(today).inDays;
}

/// Whether [when] falls on a warning day.
bool isFederalWarningDay(DateTime when) =>
    _midnight(when) == federalWarningDay(when.year);

DateTime _midnight(DateTime value) =>
    DateTime(value.year, value.month, value.day);
