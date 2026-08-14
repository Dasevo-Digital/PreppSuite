import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart';

import '../../../main.dart';

/// The caller's current household + membership, or `null` if they have not
/// created or joined one yet. Drives [HouseholdGate]'s onboarding decision.
final myHouseholdProvider =
    FutureProvider.autoDispose<HouseholdMembershipInfo?>(
      (ref) => client.household.getMyHousehold(),
    );

final householdMembersProvider = FutureProvider.autoDispose
    .family<List<HouseholdMember>, UuidValue>(
      (ref, householdId) => client.household.listMembers(householdId),
    );

final householdWarningRegionsProvider = FutureProvider.autoDispose
    .family<List<WarningRegionSubscription>, UuidValue>(
      (ref, householdId) => client.household.listWarningRegions(householdId),
    );
