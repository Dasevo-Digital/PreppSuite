import 'dart:math';

import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../generated/protocol.dart';

const _inviteCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const _inviteCodeLength = 8;

/// Business logic for creating/joining households and checking membership.
///
/// [requireMember] is the shared authorization helper every other
/// household-scoped endpoint (inventory, checklists, budget, warnings) calls
/// before touching data for a given household.
class HouseholdService {
  const HouseholdService();

  Future<Household> createHousehold(
    Session session, {
    required String name,
    required String countryCode,
    String? regionKey,
    required String displayName,
  }) async {
    final authUserId = session.authenticated!.authUserId;

    return session.db.transaction((transaction) async {
      await _requireNoExistingMembership(
        session,
        authUserId: authUserId,
        transaction: transaction,
      );

      final household = await Household.db.insertRow(
        session,
        Household(
          name: name,
          countryCode: countryCode,
          regionKey: regionKey,
          inviteCode: _generateInviteCode(),
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );

      await HouseholdMember.db.insertRow(
        session,
        HouseholdMember(
          householdId: household.id!,
          authUserId: authUserId,
          displayName: displayName,
          role: HouseholdRole.owner,
          joinedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );

      return household;
    });
  }

  Future<Household> joinHousehold(
    Session session, {
    required String inviteCode,
    required String displayName,
  }) async {
    final authUserId = session.authenticated!.authUserId;

    return session.db.transaction((transaction) async {
      await _requireNoExistingMembership(
        session,
        authUserId: authUserId,
        transaction: transaction,
      );

      final household = await Household.db.findFirstRow(
        session,
        where: (t) => t.inviteCode.equals(inviteCode),
        transaction: transaction,
      );
      if (household == null) {
        throw HouseholdException(
          reason: HouseholdExceptionReason.invalidInviteCode,
        );
      }

      await HouseholdMember.db.insertRow(
        session,
        HouseholdMember(
          householdId: household.id!,
          authUserId: authUserId,
          displayName: displayName,
          role: HouseholdRole.member,
          joinedAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );

      return household;
    });
  }

  Future<HouseholdMembershipInfo?> getMyHousehold(Session session) async {
    final authUserId = session.authenticated!.authUserId;

    final member = await HouseholdMember.db.findFirstRow(
      session,
      where: (t) => t.authUserId.equals(authUserId),
    );
    if (member == null) return null;

    final household = await Household.db.findById(session, member.householdId);
    if (household == null) return null;

    return HouseholdMembershipInfo(household: household, member: member);
  }

  Future<List<HouseholdMember>> listMembers(
    Session session, {
    required UuidValue householdId,
  }) async {
    await requireMember(session, householdId: householdId);

    return HouseholdMember.db.find(
      session,
      where: (t) => t.householdId.equals(householdId),
      orderBy: (t) => t.joinedAt,
    );
  }

  Future<Household> rotateInviteCode(
    Session session, {
    required UuidValue householdId,
  }) async {
    final member = await requireMember(session, householdId: householdId);
    if (member.role != HouseholdRole.owner) {
      throw HouseholdException(reason: HouseholdExceptionReason.notOwner);
    }

    final household = await Household.db.findById(session, householdId);
    if (household == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    household.inviteCode = _generateInviteCode();
    return Household.db.updateRow(session, household);
  }

  /// Updates the household's own country/region — the primary scope used
  /// for warning relevance (see `WarningService.isWarningRelevant`).
  /// Owner-only, since it changes what every member sees.
  Future<Household> updateRegion(
    Session session, {
    required UuidValue householdId,
    required String countryCode,
    String? regionKey,
  }) async {
    final member = await requireMember(session, householdId: householdId);
    if (member.role != HouseholdRole.owner) {
      throw HouseholdException(reason: HouseholdExceptionReason.notOwner);
    }

    final household = await Household.db.findById(session, householdId);
    if (household == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    household
      ..countryCode = countryCode
      ..regionKey = regionKey;
    return Household.db.updateRow(session, household);
  }

  /// Additional regions (beyond the household's own) whose warnings this
  /// household wants to see. Readable by any member.
  Future<List<WarningRegionSubscription>> listWarningRegions(
    Session session, {
    required UuidValue householdId,
  }) async {
    await requireMember(session, householdId: householdId);

    return WarningRegionSubscription.db.find(
      session,
      where: (t) => t.householdId.equals(householdId),
      orderBy: (t) => t.createdAt,
    );
  }

  /// Owner-only, same reasoning as [updateRegion].
  Future<WarningRegionSubscription> addWarningRegion(
    Session session, {
    required UuidValue householdId,
    required WarningRegionKind kind,
    required String value,
    required String label,
  }) async {
    final member = await requireMember(session, householdId: householdId);
    if (member.role != HouseholdRole.owner) {
      throw HouseholdException(reason: HouseholdExceptionReason.notOwner);
    }

    return WarningRegionSubscription.db.insertRow(
      session,
      WarningRegionSubscription(
        householdId: householdId,
        kind: kind,
        value: value,
        label: label,
        createdAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Owner-only, same reasoning as [updateRegion].
  Future<void> removeWarningRegion(
    Session session, {
    required UuidValue householdId,
    required UuidValue warningRegionSubscriptionId,
  }) async {
    final member = await requireMember(session, householdId: householdId);
    if (member.role != HouseholdRole.owner) {
      throw HouseholdException(reason: HouseholdExceptionReason.notOwner);
    }

    final subscription = await WarningRegionSubscription.db.findById(
      session,
      warningRegionSubscriptionId,
    );
    if (subscription == null || subscription.householdId != householdId) {
      return;
    }
    await WarningRegionSubscription.db.deleteRow(session, subscription);
  }

  /// Verifies the currently authenticated user is a member of [householdId]
  /// and returns their membership row. Every household-scoped endpoint
  /// (inventory/checklist/budget/warning) must call this before reading or
  /// writing data for that household.
  Future<HouseholdMember> requireMember(
    Session session, {
    required UuidValue householdId,
    Transaction? transaction,
  }) async {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    final member = await HouseholdMember.db.findFirstRow(
      session,
      where: (t) =>
          t.householdId.equals(householdId) & t.authUserId.equals(authUserId),
      transaction: transaction,
    );
    if (member == null) {
      throw HouseholdException(reason: HouseholdExceptionReason.notAMember);
    }

    return member;
  }

  Future<void> _requireNoExistingMembership(
    Session session, {
    required UuidValue authUserId,
    required Transaction transaction,
  }) async {
    final existingCount = await HouseholdMember.db.count(
      session,
      where: (t) => t.authUserId.equals(authUserId),
      transaction: transaction,
    );
    if (existingCount > 0) {
      throw HouseholdException(
        reason: HouseholdExceptionReason.alreadyInHousehold,
      );
    }
  }

  String _generateInviteCode() {
    final random = Random.secure();
    return List.generate(
      _inviteCodeLength,
      (_) => _inviteCodeAlphabet[random.nextInt(_inviteCodeAlphabet.length)],
    ).join();
  }
}
