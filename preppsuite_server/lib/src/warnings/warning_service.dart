import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';
import 'services/german_states.dart';

/// Read-only warning pull, scoped to a household's country and region.
/// Unlike the syncable entities, [Warning] rows are entirely
/// server-generated (by `WarningPollFutureCall`) — there is no push.
class WarningService {
  const WarningService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  Future<List<Warning>> pullChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    final household = await Household.db.findById(session, householdId);
    if (household == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    final candidates = await Warning.db.find(
      session,
      where: (t) =>
          t.countryCode.equals(household.countryCode) & (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );

    final subscriptions = await WarningRegionSubscription.db.find(
      session,
      where: (t) => t.householdId.equals(householdId),
    );

    return [
      for (final warning in candidates)
        if (isWarningRelevant(warning, household, subscriptions)) warning,
    ];
  }
}

/// Whether [warning] should be shown to [household], given its
/// [subscriptions] (additional regions beyond the household's own
/// `regionKey`). A pure function — deliberately not a query — so it's
/// simple to unit test against fixtures rather than a live database.
///
/// `warning.regionKey` comes in two shapes depending on which BBK poll
/// found it: a 5-digit Kreisschlüssel (precise per-Kreis fetch) or a
/// 2-letter state code (nationwide fetch, id-parsed — see
/// `WarningNormalizer._bbkRegionFromId`). MeteoAlarm's `regionKey` is raw,
/// unstructured `areaDesc` text and is never matched against — those
/// warnings (and any BBK entry with no parseable region, e.g. most `dwd`
/// entries) fall through to the "always relevant" case below, same as
/// today's country-only behavior.
bool isWarningRelevant(
  Warning warning,
  Household household,
  List<WarningRegionSubscription> subscriptions,
) {
  final regionKey = warning.regionKey;
  if (regionKey == null) return true;

  final householdKreis = household.regionKey;
  final hasOwnRegion = householdKreis != null && householdKreis.length >= 5;
  if (!hasOwnRegion && subscriptions.isEmpty) return true;

  if (hasOwnRegion) {
    final kreisPrefix = householdKreis.substring(0, 5);
    if (regionKey == kreisPrefix) return true;

    final ownState = germanStateForKreisSchluessel(kreisPrefix);
    if (ownState != null &&
        (regionKey == ownState.bbkCode ||
            regionKey.startsWith(ownState.arsPrefix))) {
      return true;
    }
  }

  for (final subscription in subscriptions) {
    switch (subscription.kind) {
      case WarningRegionKind.kreis:
        if (regionKey == subscription.value) return true;
      case WarningRegionKind.bundesland:
        final state = germanStateByBbkCode(subscription.value);
        if (state == null) continue;
        if (regionKey == state.bbkCode ||
            regionKey.startsWith(state.arsPrefix)) {
          return true;
        }
    }
  }

  return false;
}
