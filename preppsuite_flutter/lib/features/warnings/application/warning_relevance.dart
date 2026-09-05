import '../../../local_db/database.dart';
import '../../household/application/german_states.dart';
import 'warning_region_filter.dart';

/// How closely a warning matches the regions a device follows — a rank
/// rather than a yes/no, so the UI can put closer matches first among
/// warnings that are all technically relevant. Higher is more relevant.
///
/// Rank 0 is deliberately ambiguous: it covers both "concerns everyone"
/// (no region on the warning) and "concerns someone else". That was
/// harmless while a server decided what reached the device at all. It is
/// not harmless now that the app sees every warning in the country, so
/// anything that *filters* must use [isWarningRelevant] instead.
int warningRelevanceRank({
  required Warning warning,
  required WarningRegionFilter filter,
}) {
  final regionKey = warning.regionKey;
  if (regionKey == null) return 0;
  if (!filter.hasAnyRegion) return 0;

  final ownKreis = filter.ownKreisSchluessel;
  if (ownKreis != null) {
    if (regionKey == ownKreis) return 2;

    final ownState = germanStateForKreisSchluessel(ownKreis);
    if (ownState != null &&
        (regionKey == ownState.bbkCode ||
            regionKey.startsWith(ownState.arsPrefix))) {
      return 1;
    }
  }

  for (final region in filter.extraRegions) {
    switch (region.kind) {
      case WarningRegionKind.kreis:
        if (regionKey == region.value) return 2;
      case WarningRegionKind.bundesland:
        final state = germanStateByBbkCode(region.value);
        if (state != null &&
            (regionKey == state.bbkCode ||
                regionKey.startsWith(state.arsPrefix))) {
          return 1;
        }
    }
  }

  return 0;
}

/// Whether [warning] concerns this device at all.
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
  required WarningRegionFilter filter,
}) {
  if (warning.countryCode != filter.countryCode) return false;
  if (warning.regionKey == null) return true;
  if (!filter.hasAnyRegion) return true;

  return warningRelevanceRank(warning: warning, filter: filter) > 0;
}
