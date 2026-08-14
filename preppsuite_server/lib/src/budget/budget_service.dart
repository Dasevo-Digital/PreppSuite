import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import '../households/household_service.dart';

/// Push/pull sync for [BudgetEntry] — identical shape to `InventoryService`.
class BudgetService {
  const BudgetService({
    this.householdService = const HouseholdService(),
  });

  final HouseholdService householdService;

  Future<List<BudgetEntry>> pullChanges(
    Session session, {
    required UuidValue householdId,
    required DateTime since,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return BudgetEntry.db.find(
      session,
      where: (t) => t.householdId.equals(householdId) & (t.updatedAt > since),
      orderBy: (t) => t.updatedAt,
    );
  }

  Future<List<BudgetEntry>> pushChanges(
    Session session, {
    required UuidValue householdId,
    required List<BudgetEntry> changes,
  }) async {
    await householdService.requireMember(session, householdId: householdId);

    return session.db.transaction((transaction) async {
      final results = <BudgetEntry>[];
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

  Future<BudgetEntry> _applyChange(
    Session session, {
    required UuidValue householdId,
    required BudgetEntry incoming,
    required Transaction transaction,
  }) async {
    final existing = incoming.id != null
        ? await BudgetEntry.db.findById(
            session,
            incoming.id!,
            transaction: transaction,
          )
        : await BudgetEntry.db.findFirstRow(
            session,
            where: (t) =>
                t.householdId.equals(householdId) &
                t.clientId.equals(incoming.clientId),
            transaction: transaction,
          );

    if (existing == null) {
      return BudgetEntry.db.insertRow(
        session,
        BudgetEntry(
          householdId: householdId,
          clientId: incoming.clientId,
          label: incoming.label,
          amountCents: incoming.amountCents,
          currency: incoming.currency,
          category: incoming.category,
          purchaseDate: incoming.purchaseDate,
          linkedInventoryItemId: incoming.linkedInventoryItemId,
          updatedAt: DateTime.now().toUtc(),
          deletedAt: incoming.deletedAt,
        ),
        transaction: transaction,
      );
    }

    if (!incoming.updatedAt.isAfter(existing.updatedAt)) {
      return existing;
    }

    existing
      ..label = incoming.label
      ..amountCents = incoming.amountCents
      ..currency = incoming.currency
      ..category = incoming.category
      ..purchaseDate = incoming.purchaseDate
      ..linkedInventoryItemId = incoming.linkedInventoryItemId
      ..updatedAt = DateTime.now().toUtc()
      ..deletedAt = incoming.deletedAt;

    return BudgetEntry.db.updateRow(session, existing, transaction: transaction);
  }
}
