import 'package:preppsuite_client/preppsuite_client.dart'
    show Household, WarningRegionKind, WarningRegionSubscription;

import '../../../local_db/database.dart';
import '../../household/application/german_states.dart';

/// How closely a warning matches a household's own region — a rank rather
/// than a yes/no, so the UI can put closer matches first among warnings
/// that are all technically relevant. Higher is more relevant.
///
/// Rank 0 is deliberately ambiguous: it covers both "concerns everyone"
/// (no region on the warning) and "concerns someone else". That was
/// harmless while a server decided what reached the device at all. It is
/// not harmless now, so anything that has to *filter* must use
/// [isWarningRelevant] instead.
int warningRelevanceRank({
  required Warning warning,
  required Household household,
  required List<WarningRegionSubscription> subscriptions,
}) {
  final regionKey = warning.regionKey;
  if (regionKey == null) return 0;

  final ownRegion = household.regionKey;
  final hasOwnRegion = ownRegion != null && ownRegion.length >= 5;
  if (!hasOwnRegion && subscriptions.isEmpty) return 0;

  if (hasOwnRegion) {
    final kreisPrefix = ownRegion.substring(0, 5);
    if (regionKey == kreisPrefix) return 2;

    final ownState = germanStateForKreisSchluessel(kreisPrefix);
    if (ownState != null &&
        (regionKey == ownState.bbkCode ||
            regionKey.startsWith(ownState.arsPrefix))) {
      return 1;
    }
  }

  for (final subscription in subscriptions) {
    switch (subscription.kind) {
      case WarningRegionKind.kreis:
        if (regionKey == subscription.value) return 2;
      case WarningRegionKind.bundesland:
        final state = germanStateByBbkCode(subscription.value);
        if (state != null &&
            (regionKey == state.bbkCode ||
                regionKey.startsWith(state.arsPrefix))) {
          return 1;
        }
    }
  }

  return 0;
}

/// Whether [warning] concerns [household] at all.
///
/// Ported from the server's `WarningService.isWarningRelevant` when the app
/// took over fetching — the app now sees every warning in the country, so
/// this is what keeps a Bavarian flood alert from waking someone in
/// Cologne. Unlike [warningRelevanceRank], "no region given" and "another
/// region" are distinguished here: a warning without a parseable region
/// concerns everyone, which is the safer reading for a civil-protection
/// alert.
bool isWarningRelevant({
  required Warning warning,
  required Household household,
  required List<WarningRegionSubscription> subscriptions,
}) {
  final regionKey = warning.regionKey;
  if (regionKey == null) return true;

  final ownRegion = household.regionKey;
  final hasOwnRegion = ownRegion != null && ownRegion.length >= 5;
  if (!hasOwnRegion && subscriptions.isEmpty) return true;

  return warningRelevanceRank(
        warning: warning,
        household: household,
        subscriptions: subscriptions,
      ) >
      0;
}
