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
