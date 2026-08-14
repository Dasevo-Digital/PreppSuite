import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'household_service.dart';

/// Household creation/joining and membership management. Accessed through
/// `client.household` on the client side.
class HouseholdEndpoint extends Endpoint {
  final _repository = const HouseholdService();

  @override
  bool get requireLogin => true;

  /// Creates a new household with the caller as its owner. Fails with
  /// [HouseholdException] ([HouseholdExceptionReason.alreadyInHousehold]) if
  /// the caller already belongs to a household.
  Future<Household> createHousehold(
    Session session, {
    required String name,
    required String countryCode,
    String? regionKey,
    required String displayName,
  }) {
    return _repository.createHousehold(
      session,
      name: name,
      countryCode: countryCode,
      regionKey: regionKey,
      displayName: displayName,
    );
  }

  /// Joins an existing household using its invite code. Fails with
  /// [HouseholdException] if the code is invalid or the caller already
  /// belongs to a household.
  Future<Household> joinHousehold(
    Session session, {
    required String inviteCode,
    required String displayName,
  }) {
    return _repository.joinHousehold(
      session,
      inviteCode: inviteCode,
      displayName: displayName,
    );
  }

  /// Returns the caller's current household and membership, or `null` if
  /// they have not joined or created one yet. Called on app start to decide
  /// whether to show onboarding.
  Future<HouseholdMembershipInfo?> getMyHousehold(Session session) {
    return _repository.getMyHousehold(session);
  }

  /// Lists all members of a household the caller belongs to.
  Future<List<HouseholdMember>> listMembers(
    Session session,
    UuidValue householdId,
  ) {
    return _repository.listMembers(session, householdId: householdId);
  }

  /// Rotates the invite code. Only the household's owner may do this.
  Future<Household> rotateInviteCode(
    Session session,
    UuidValue householdId,
  ) {
    return _repository.rotateInviteCode(session, householdId: householdId);
  }

  /// Updates the household's own country/region. Only the owner may do
  /// this — it changes what every member sees in the warnings feed.
  Future<Household> updateRegion(
    Session session,
    UuidValue householdId, {
    required String countryCode,
    String? regionKey,
  }) {
    return _repository.updateRegion(
      session,
      householdId: householdId,
      countryCode: countryCode,
      regionKey: regionKey,
    );
  }

  /// Lists a household's additional warning-region subscriptions (beyond
  /// its own country/region).
  Future<List<WarningRegionSubscription>> listWarningRegions(
    Session session,
    UuidValue householdId,
  ) {
    return _repository.listWarningRegions(session, householdId: householdId);
  }

  /// Adds an additional region whose warnings the household wants to see.
  /// Only the owner may do this.
  Future<WarningRegionSubscription> addWarningRegion(
    Session session,
    UuidValue householdId, {
    required WarningRegionKind kind,
    required String value,
    required String label,
  }) {
    return _repository.addWarningRegion(
      session,
      householdId: householdId,
      kind: kind,
      value: value,
      label: label,
    );
  }

  /// Removes an additional region subscription. Only the owner may do
  /// this.
  Future<void> removeWarningRegion(
    Session session,
    UuidValue householdId,
    UuidValue warningRegionSubscriptionId,
  ) {
    return _repository.removeWarningRegion(
      session,
      householdId: householdId,
      warningRegionSubscriptionId: warningRegionSubscriptionId,
    );
  }
}
