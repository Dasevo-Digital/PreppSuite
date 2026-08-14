import 'package:preppsuite_client/preppsuite_client.dart'
    show Household, WarningRegionKind, WarningRegionSubscription;

import '../../../local_db/database.dart';
import '../../household/application/german_states.dart';

/// How closely a warning matches a household's own region — mirrors the
/// server's `WarningService.isWarningRelevant` (which already filters what
/// reaches the client at all), but produces a rank instead of a yes/no so
/// the UI can put closer matches first among warnings that are all
/// technically relevant. Higher is more relevant.
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
