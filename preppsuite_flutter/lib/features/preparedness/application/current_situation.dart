/// What is happening right now, as far as the app can tell.
///
/// The crisis hub held a switch called "crisis mode" that did one thing:
/// scale the text on its own page by a quarter. Meanwhile the app already
/// knew when something was actually going on — a severe warning over the
/// household's own region, a blackout clock the household started — and
/// none of that reached the screen where the plans are.
///
/// This is the join, and it is deliberately narrow. It reports; it decides
/// nothing. Turning crisis mode on stays the household's choice, because a
/// screen that rearranges itself on a feed's say-so is a screen nobody can
/// rely on.
library;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../../model/household_profile.dart';
import '../../energy/application/outage_store.dart';
import '../../warnings/application/warning_relevance.dart';
import '../../warnings/application/warning_severity_l10n.dart';

/// The situation, as the records have it.
class CurrentSituation {
  const CurrentSituation({this.warnings = const [], this.outage});

  /// Active, relevant and at least severe, most severe first.
  ///
  /// Only severe and above: a wind advisory is not a reason to offer a
  /// household a larger typeface and an incident log, and an app that
  /// cries wolf over one is an app people learn to scroll past.
  final List<Warning> warnings;

  /// A blackout the household started the clock on.
  final OutageClock? outage;

  bool get isQuiet => warnings.isEmpty && outage == null;

  /// The one to lead with.
  Warning? get leadWarning => warnings.isEmpty ? null : warnings.first;
}

CurrentSituation currentSituation({
  required List<Warning> warnings,
  required HouseholdProfile? profile,
  OutageClock? outage,
}) {
  if (profile == null) {
    return CurrentSituation(outage: outage);
  }
  final severe = [
    for (final warning in warnings)
      if (warning.countryCode == profile.countryCode)
        if (isWarningRelevant(warning: warning, filter: profile.warningFilter))
          if (warningSeverityRank(
                warningSeverityFromName(warning.severity),
              ) >=
              warningSeverityRank(WarningSeverity.severe))
            warning,
  ];
  severe.sort((a, b) {
    final rank = warningSeverityRank(
      warningSeverityFromName(b.severity),
    ).compareTo(warningSeverityRank(warningSeverityFromName(a.severity)));
    return rank != 0 ? rank : b.sent.compareTo(a.sent);
  });
  return CurrentSituation(warnings: severe, outage: outage);
}

/// How long the blackout has been running, in whole hours.
///
/// Whole hours and rounded down, which is what the food-safety clock on
/// the outage screen counts in: reporting three hours as four is how a
/// household throws away food it could have kept.
int? outageHours(OutageClock? outage, DateTime now) =>
    outage == null ? null : now.toUtc().difference(outage.startedAt).inHours;
