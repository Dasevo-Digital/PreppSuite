import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';

/// Push/pull sync logic for [InventoryItem], following the pattern every
/// other syncable entity (checklists, budget) replicates:
///
/// - Pull returns everything changed since a client-supplied timestamp,
///   including tombstoned (soft-deleted) rows.
/// - Push upserts by `(householdId, clientId)` when the row has no
///   server-assigned id yet, otherwise by `id`. An incoming row is only
///   applied if its `updatedAt` is newer than what the server has stored
///   (last-write-wins); the server always re-stamps `updatedAt` itself so
///   client clock skew can't corrupt ordering for other devices.
class InventoryService {
  const InventoryService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  Future<List<InventoryItem>> pullChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return InventoryItem.db.find(
      session,
      where: (t) => t.householdId.equals(householdId) & (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );
  }

  Future<List<InventoryItem>> pushChanges(
    Session session, {
    required UuidValue householdId,
    required List<InventoryItem> changes,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return session.db.transaction((transaction) async {
      final results = <InventoryItem>[];
      for (final incoming in changes) {
        results.add(
          await _applyChange(
            session,
            householdId: householdId,
            incoming: incoming,
            transaction: transaction,
          ),
        );
      }
      return results;
    });
  }

  Future<InventoryItem> _applyChange(
    Session session, {
    required UuidValue householdId,
    required InventoryItem incoming,
    required Transaction transaction,
  }) async {
    final existing = incoming.id != null
        ? await InventoryItem.db.findById(
            session,
            incoming.id!,
            transaction: transaction,
          )
        : await InventoryItem.db.findFirstRow(
            session,
            where: (t) =>
                t.householdId.equals(householdId) &
                t.clientId.equals(incoming.clientId),
            transaction: transaction,
          );

    if (existing == null) {
      return InventoryItem.db.insertRow(
        session,
        InventoryItem(
          householdId: householdId,
          clientId: incoming.clientId,
          name: incoming.name,
          category: incoming.category,
          barcode: incoming.barcode,
          offProductId: incoming.offProductId,
          quantity: incoming.quantity,
          unit: incoming.unit,
          storageLocation: incoming.storageLocation,
          expirationDate: incoming.expirationDate,
          minQuantity: incoming.minQuantity,
          calories: incoming.calories,
          notes: incoming.notes,
          updatedAt: DateTime.now().toUtc(),
          deletedAt: incoming.deletedAt,
        ),
        transaction: transaction,
      );
    }

    // Last-write-wins: ignore incoming edits that are not newer than what we
    // already have, but still return the canonical row so the client can
    // reconcile its local copy.
    if (!incoming.updatedAt.isAfter(existing.updatedAt)) {
      return existing;
    }

    existing
      ..name = incoming.name
      ..category = incoming.category
      ..barcode = incoming.barcode
      ..offProductId = incoming.offProductId
      ..quantity = incoming.quantity
      ..unit = incoming.unit
      ..storageLocation = incoming.storageLocation
      ..expirationDate = incoming.expirationDate
      ..minQuantity = incoming.minQuantity
      ..calories = incoming.calories
      ..notes = incoming.notes
      ..updatedAt = DateTime.now().toUtc()
      ..deletedAt = incoming.deletedAt;

    return InventoryItem.db.updateRow(session, existing, transaction: transaction);
  }
}
