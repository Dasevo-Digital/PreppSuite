import '../../../local_db/database.dart';
import 'warning_region_filter.dart';
import 'warning_relevance.dart';
import 'warning_severity_l10n.dart';

/// The order the warning list puts its entries in.
///
/// Four keys, and the first one is the one that decides:
///
/// 1. **Still in force.** What is running comes before what is over, and
///    it comes before it whatever region either of them names. A feed
///    leaves an expired warning in place for a while on purpose, so the
///    list is full of them — and an expired warning is *never* the answer
///    to "what is going on now". Once it is over, being nearby does not
///    make it current again.
/// 2. **Region.** Within what is running, and again within what is over,
///    a warning for a followed district comes first, then one for a
///    followed state, then one that names no region at all, and last one
///    meant for somewhere else. See [warningRelevanceRank].
/// 3. **Severity**, and then
/// 4. **recency**, both only to break ties among equals.
///
/// Region used to be the first key. On a telephone that put „Amtliche
/// WARNUNG vor STURMBÖEN · Abgelaufen" above a warning that was in force,
/// because the expired one named the device's own district. The list
/// answers "what is going on", and the first thing that has to be true of
/// an answer is that it is still happening.
///
/// [now] is passed in rather than read, so this can be tested without
/// waiting for a warning to expire.
int compareWarningsForList(
  Warning a,
  Warning b, {
  required WarningRegionFilter filter,
  required DateTime now,
}) {
  final inForce = _inForce(b, now).compareTo(_inForce(a, now));
  if (inForce != 0) return inForce;

  final relevance = warningRelevanceRank(warning: b, filter: filter).compareTo(
    warningRelevanceRank(warning: a, filter: filter),
  );
  if (relevance != 0) return relevance;

  final severity = warningSeverityRank(
    warningSeverityFromName(b.severity),
  ).compareTo(warningSeverityRank(warningSeverityFromName(a.severity)));
  if (severity != 0) return severity;

  return b.sent.compareTo(a.sent);
}

/// 1 while the warning is running, 0 once it has run out.
///
/// A warning without an end is running: a civil-protection alert that
/// names no end has not ended.
int _inForce(Warning warning, DateTime now) {
  final expires = warning.expires;
  return expires == null || !expires.isBefore(now) ? 1 : 0;
}
