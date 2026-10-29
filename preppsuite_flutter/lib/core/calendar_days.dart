/// Whole calendar days from [from] to [to]; negative when [to] is the
/// earlier day, zero on the same day.
///
/// Counted on the dates and not on the hours between them. Two local
/// midnights are only 23 hours apart across the start of summer time, and
/// `difference(...).inDays` rounds that down to a day too few: from March
/// to October every "noch 21 Tage" said 20, and the day after the change an
/// item that ran out the day before was "heute" instead of expired (#233).
/// The end of summer time adds an hour, which the rounding happens to hide.
/// UTC has no summer time, so the same dates there are always whole days
/// apart.
///
/// Each value's own year, month and day are taken as they stand. A caller
/// holding a UTC stamp converts it to local time first if the local day is
/// what it means.
int calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
