import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';
import 'package:uuid/uuid.dart';

import '../../../local_db/database.dart';
import 'budget_providers.dart';

/// Local writes for budget entries. See `InventoryController` for the
/// general shape this follows.
class BudgetController {
  BudgetController(this._db, this.householdId);

  final AppDatabase _db;
  final String householdId;

  Future<void> addEntry({
    required String label,
    required int amountCents,
    required String currency,
    required InventoryItemCategory category,
    DateTime? purchaseDate,
  }) async {
    await _db.upsertBudgetEntry(
      BudgetEntriesCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: householdId,
        label: label,
        amountCents: amountCents,
        currency: currency,
        category: category.name,
        purchaseDate: Value(purchaseDate),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> updateEntry(
    BudgetEntry existing, {
    required String label,
    required int amountCents,
    required String currency,
    required InventoryItemCategory category,
    DateTime? purchaseDate,
  }) async {
    await _db.upsertBudgetEntry(
      BudgetEntriesCompanion.insert(
        clientId: existing.clientId,
        householdId: existing.householdId,
        label: label,
        amountCents: amountCents,
        currency: currency,
        category: category.name,
        purchaseDate: Value(purchaseDate),
        linkedInventoryItemId: Value(existing.linkedInventoryItemId),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  /// Takes back a deletion, so the delete itself needs no confirmation.
  ///
  /// The counterpart to [deleteEntry], which tombstones rather than
  /// removing — the row is still there and only marked gone, so undoing
  /// is a matter of clearing the mark. Without this, deleting an entry
  /// was the one action in the app with neither a question in front of it
  /// nor a way back after it.
  ///
  /// Silent when there is nothing to restore: an entry already gone from
  /// the database, or one that was never deleted, both mean the user has
  /// nothing to gain from an error message.
  Future<void> restoreEntry(String clientId) async {
    // Two where clauses rather than one with `&`: drift joins them with
    // AND, and this file imports drift as `show Value` on purpose, which
    // does not bring the operator along.
    final row =
        await (_db.select(_db.budgetEntries)
              ..where((t) => t.clientId.equals(clientId))
              ..where((t) => t.householdId.equals(householdId)))
            .getSingleOrNull();
    if (row == null || row.deletedAt == null) return;
    await _db.upsertBudgetEntry(
      row
          .toCompanion(false)
          .copyWith(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  Future<void> deleteEntry(BudgetEntry existing) async {
    final now = DateTime.now().toUtc();
    await _db.upsertBudgetEntry(
      BudgetEntriesCompanion.insert(
        clientId: existing.clientId,
        householdId: existing.householdId,
        label: existing.label,
        amountCents: existing.amountCents,
        currency: existing.currency,
        category: existing.category,
        purchaseDate: Value(existing.purchaseDate),
        linkedInventoryItemId: Value(existing.linkedInventoryItemId),
        updatedAt: now,
        dirty: const Value(true),
        deletedAt: Value(now),
      ),
    );
  }
}

final budgetControllerProvider = Provider.autoDispose
    .family<BudgetController, String>(
      (ref, householdId) => BudgetController(
        ref.watch(appDatabaseProvider),
        householdId,
      ),
    );
