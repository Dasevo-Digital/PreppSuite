import '../../../local_db/database.dart';
import '../../household/application/german_states.dart';
import 'warning_region_filter.dart';

/// The human-readable reason a warning is part of a household's view.
///
/// This is deliberately separate from [warningRelevanceRank]. The rank is
/// useful for ordering; this value is what lets the UI answer the important
/// question "why am I seeing this?" without exposing implementation details
/// such as ARS prefixes.
enum WarningRelevance {
  ownDistrict,
  followedDistrict,
  ownState,
  followedState,
  nationwide,
  noPlacesSelected,
  otherRegion,
}

/// Classifies the regional relationship between [warning] and [filter].
WarningRelevance warningRelevance({
  required Warning warning,
  required WarningRegionFilter filter,
}) {
  final regionKey = warning.regionKey;
  if (regionKey == null) return WarningRelevance.nationwide;
  if (!filter.hasAnyRegion) return WarningRelevance.noPlacesSelected;

  final ownKreis = filter.ownKreisSchluessel;
  if (ownKreis != null) {
    if (regionKey == ownKreis) return WarningRelevance.ownDistrict;
    final ownState = germanStateForKreisSchluessel(ownKreis);
    if (ownState != null &&
        (regionKey == ownState.bbkCode ||
            regionKey.startsWith(ownState.arsPrefix))) {
      return WarningRelevance.ownState;
    }
  }

  for (final region in filter.extraRegions) {
    switch (region.kind) {
      case WarningRegionKind.kreis:
        if (regionKey == region.value) {
          return WarningRelevance.followedDistrict;
        }
      case WarningRegionKind.bundesland:
        final state = germanStateByBbkCode(region.value);
        if (state != null &&
            (regionKey == state.bbkCode ||
                regionKey.startsWith(state.arsPrefix))) {
          return WarningRelevance.followedState;
        }
    }
  }
  return WarningRelevance.otherRegion;
}

/// How closely a warning matches the regions a device follows — a rank
/// rather than a yes/no, so the UI can put closer matches first among
/// warnings that are all technically relevant. Higher is more relevant.
///
/// | rank | |
/// |---|---|
/// | 3 | a district this device follows, its own or an added one |
/// | 2 | a Bundesland this device follows |
/// | 1 | no region on the warning at all: it concerns everyone |
/// | 0 | a region nobody here follows |
///
/// **Rank 1 exists because rank 0 used to mean two different things.** It
/// covered "concerns everyone" and "concerns somebody else" alike, which
/// was harmless while a server decided what reached the device — and
/// stopped being harmless once the app saw every warning in the country.
/// It showed on a telephone: a nationwide alert that was in force sat
/// below a local one that was over, because both counted as "rank 0" and
/// the sort could not tell them apart.
///
/// A warning without a region is not *more* relevant than one that names
/// the street outside, so it stays below both followed-region ranks. It
/// is simply no longer filed with the ones meant for somebody else.
int warningRelevanceRank({
  required Warning warning,
  required WarningRegionFilter filter,
}) {
  return switch (warningRelevance(warning: warning, filter: filter)) {
    WarningRelevance.ownDistrict || WarningRelevance.followedDistrict => 3,
    WarningRelevance.ownState || WarningRelevance.followedState => 2,
    WarningRelevance.nationwide || WarningRelevance.noPlacesSelected => 1,
    WarningRelevance.otherRegion => 0,
  };
}

/// Whether [warning] concerns this device at all.
///
/// Ported from the server's `WarningService.isWarningRelevant` when the app
/// took over fetching — the app now sees every warning in the country, so
/// this is what keeps a Bavarian flood alert from waking someone in
/// Cologne. A warning without a parseable region concerns everyone, which
/// is the safer reading for a civil-protection alert — [warningRelevanceRank]
/// says the same thing with its rank 1.
bool isWarningRelevant({
  required Warning warning,
  required WarningRegionFilter filter,
}) {
  if (warning.countryCode != filter.countryCode) return false;
  if (warning.regionKey == null) return true;
  if (!filter.hasAnyRegion) return true;

  return warningRelevanceRank(warning: warning, filter: filter) > 0;
}
