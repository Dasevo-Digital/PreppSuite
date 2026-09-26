import '../../../local_db/database.dart';
import 'warning_region_filter.dart';
import 'warning_relevance.dart';
import 'warning_severity_l10n.dart';

/// The order the warning list puts its entries in.
///
/// Four keys, and the first two are the ones that matter:
///
/// 1. **Region.** A warning for a followed region comes before one that
///    concerns everybody, which comes before one for somewhere else. This
///    is first because the question the screen answers is "what is going
///    on *here*"; a severe alert two states away is not a better answer
///    than a mild one at home.
/// 2. **Still in force.** Within a region, what is running comes before
///    what is over. This key was missing, and the screen showed it: on a
///    device with one active warning, the top four entries were all
///    expired — an expired severe one outranked a running mild one,
///    because severity came straight after relevance. A feed leaves an
///    expired warning in place for a while on purpose, so the list holds
///    plenty of them and they are *never* the answer to what is going on
///    now.
/// 3. **Severity**, and then
/// 4. **recency**, both only to break ties among equals.
///
/// [now] is passed in rather than read, so this can be tested without
/// waiting for a warning to expire.
int compareWarningsForList(
  Warning a,
  Warning b, {
  required WarningRegionFilter filter,
  required DateTime now,
}) {
  final relevance = warningRelevanceRank(warning: b, filter: filter).compareTo(
    warningRelevanceRank(warning: a, filter: filter),
  );
  if (relevance != 0) return relevance;

  final inForce = _inForce(b, now).compareTo(_inForce(a, now));
  if (inForce != 0) return inForce;

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
