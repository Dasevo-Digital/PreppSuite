import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show InventoryItemCategory;
import 'package:uuid/uuid.dart';

import '../../../local_db/database.dart';
import 'inventory_csv_import.dart';
import 'inventory_providers.dart';
import 'inventory_sync_controller.dart';

/// Local writes (create/update/delete-as-tombstone) plus nudging the sync
/// controller afterward. The UI never talks to Drift or the network client
/// directly — everything goes through here.
class InventoryController {
  InventoryController(this._ref, this._db, this.householdId);

  final Ref _ref;
  final AppDatabase _db;
  final String householdId;

  Future<void> addItem({
    required String name,
    required InventoryItemCategory category,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    String? barcode,
    String? offProductId,
    String? photoPath,
    int? calories,
  }) async {
    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: householdId,
        name: name,
        category: category.name,
        quantity: quantity,
        unit: unit,
        storageLocation: storageLocation,
        expirationDate: Value(expirationDate),
        minQuantity: Value(minQuantity),
        notes: Value(notes),
        barcode: Value(barcode),
        offProductId: Value(offProductId),
        photoPath: Value(photoPath),
        calories: Value(calories),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _triggerSync();
  }

  Future<void> updateItem(
    InventoryItem existing, {
    required String name,
    required InventoryItemCategory category,
    required double quantity,
    required String unit,
    required String storageLocation,
    DateTime? expirationDate,
    double? minQuantity,
    String? notes,
    String? barcode,
    String? offProductId,
    String? photoPath,
    int? calories,
  }) async {
    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: existing.clientId,
        serverId: Value(existing.serverId),
        householdId: existing.householdId,
        name: name,
        category: category.name,
        barcode: Value(barcode ?? existing.barcode),
        offProductId: Value(offProductId ?? existing.offProductId),
        quantity: quantity,
        unit: unit,
        storageLocation: storageLocation,
        expirationDate: Value(expirationDate),
        minQuantity: Value(minQuantity),
        notes: Value(notes),
        photoPath: Value(photoPath),
        calories: Value(calories),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _triggerSync();
  }

  /// Inserts many items in a single batch, e.g. from a CSV import. Each
  /// row gets a fresh [clientId], same as [addItem].
  Future<void> addItemsBulk(List<ParsedInventoryRow> rows) async {
    if (rows.isEmpty) return;
    await _db.upsertInventoryItems([
      for (final row in rows)
        InventoryItemsCompanion.insert(
          clientId: const Uuid().v4(),
          householdId: householdId,
          name: row.name,
          category: row.category.name,
          quantity: row.quantity,
          unit: row.unit,
          storageLocation: row.storageLocation,
          expirationDate: Value(row.expirationDate),
          minQuantity: Value(row.minQuantity),
          notes: Value(row.notes),
          updatedAt: DateTime.now().toUtc(),
        ),
    ]);
    _triggerSync();
  }

  Future<void> deleteItem(InventoryItem existing) async {
    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: existing.clientId,
        serverId: Value(existing.serverId),
        householdId: existing.householdId,
        name: existing.name,
        category: existing.category,
        barcode: Value(existing.barcode),
        offProductId: Value(existing.offProductId),
        quantity: existing.quantity,
        unit: existing.unit,
        storageLocation: existing.storageLocation,
        expirationDate: Value(existing.expirationDate),
        minQuantity: Value(existing.minQuantity),
        notes: Value(existing.notes),
        photoPath: Value(existing.photoPath),
        calories: Value(existing.calories),
        updatedAt: DateTime.now().toUtc(),
        deletedAt: Value(DateTime.now().toUtc()),
      ),
    );
    _triggerSync();
  }

  void _triggerSync() {
    _ref
        .read(inventorySyncControllerProvider(householdId).notifier)
        .syncDebounced();
  }
}

final inventoryControllerProvider = Provider.autoDispose
    .family<InventoryController, String>(
      (ref, householdId) => InventoryController(
        ref,
        ref.watch(appDatabaseProvider),
        householdId,
      ),
    );
