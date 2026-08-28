import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';

/// The registry of devices that want warning pushes.
///
/// Deliberately not part of the generic push/pull sync: a device token is
/// not household data, it is not useful on a second device, and it must
/// not travel between them.
class PushDeviceService {
  const PushDeviceService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  /// Records [token] for the calling user's device, or updates it in place
  /// if it is already known.
  ///
  /// Upserting on the token rather than inserting is what keeps the table
  /// from growing without bound: the client re-registers on every launch,
  /// and FCM hands back the same token each time until it rotates. A token
  /// that turns up under a different user or household — a shared phone, a
  /// household switch — is moved rather than duplicated, because FCM would
  /// otherwise deliver the same warning once per stale row.
  Future<PushDevice> register(
    Session session, {
    required UuidValue householdId,
    required String token,
    required PushPlatform platform,
  }) async {
    await householdService.requireMember(session, householdId: householdId);
    final authUserId = session.authenticated!.authUserId;
    final now = DateTime.now().toUtc();

    final existing = await PushDevice.db.findFirstRow(
      session,
      where: (t) => t.token.equals(token),
    );

    if (existing != null) {
      existing
        ..householdId = householdId
        ..authUserId = authUserId
        ..platform = platform
        ..updatedAt = now;
      return PushDevice.db.updateRow(session, existing);
    }

    return PushDevice.db.insertRow(
      session,
      PushDevice(
        householdId: householdId,
        authUserId: authUserId,
        token: token,
        platform: platform,
        updatedAt: now,
        createdAt: now,
      ),
    );
  }

  /// Removes [token] — called when the user switches notifications off or
  /// signs out.
  ///
  /// Not scoped to the calling user on purpose. Whoever holds the token
  /// holds the device, and the failure mode of being strict here is a
  /// phone that keeps receiving another account's warnings after a
  /// handover; the failure mode of being lax is that someone can
  /// unsubscribe a token they would have to have stolen first.
  Future<void> unregister(Session session, {required String token}) async {
    await PushDevice.db.deleteWhere(
      session,
      where: (t) => t.token.equals(token),
    );
  }

  /// Every device registered for [householdIds].
  Future<List<PushDevice>> devicesForHouseholds(
    Session session,
    Set<UuidValue> householdIds,
  ) async {
    if (householdIds.isEmpty) return const [];
    return PushDevice.db.find(
      session,
      where: (t) => t.householdId.inSet(householdIds),
    );
  }

  Future<void> delete(Session session, PushDevice device) async {
    await PushDevice.db.deleteRow(session, device);
  }
}
