import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/categories.dart';

import 'package:uuid/uuid.dart';

import '../../../local_db/database.dart';
import 'inventory_csv_import.dart';
import 'inventory_providers.dart';
import 'item_package.dart';
import 'package_nutrition.dart';

/// Local writes: create, update, and delete-as-tombstone. The UI never
/// talks to Drift directly — everything goes through here, which is what
/// keeps `dirty` and `updatedAt` set on every path.
///
/// Nothing here pushes. A write only marks the row dirty; publishing it to
/// a shared folder is the sync controller's job, on its own schedule.
class InventoryController {
  InventoryController(this._db, this.householdId);

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
    double? dailyDose,

    /// Null keeps the household's own lead times for this item.
    String? expiryLeadDays,

    /// A `SupplyGroup` name, or null where the household has not said.
    String? foodGroup,

    /// The package the item comes in, or null; see `item_package.dart`.
    ItemPackage? package,
    PackageNutrition nutrition = const PackageNutrition(),

    /// Whose medicine this is, as a household member's `clientId`.
    String? memberId,

    /// Days before a medicine in daily use runs out to remind of a new
    /// prescription, or null for none; see the column.
    int? refillLeadDays,
  }) async {
    final now = DateTime.now().toUtc();
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
        dailyDose: Value(dailyDose),
        expiryLeadDays: Value(expiryLeadDays),
        foodGroup: Value(foodGroup),
        packageName: Value(package?.name),
        packageSize: Value(package?.size),
        memberId: Value(memberId),
        refillLeadDays: Value(refillLeadDays),
        stockCountedAt: Value(now),
        notes: Value(notes),
        barcode: Value(barcode),
        offProductId: Value(offProductId),
        photoPath: Value(photoPath),
        calories: Value(nutrition.kcal),
        proteinGrams: Value(nutrition.proteinGrams),
        carbohydrateGrams: Value(nutrition.carbohydrateGrams),
        fatGrams: Value(nutrition.fatGrams),
        fiberGrams: Value(nutrition.fiberGrams),
        updatedAt: now,
        dirty: const Value(true),
      ),
    );
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
    double? dailyDose,

    /// Null keeps the household's own lead times for this item.
    String? expiryLeadDays,

    /// A `SupplyGroup` name, or null where the household has not said.
    String? foodGroup,

    /// The package the item comes in, or null; see `item_package.dart`.
    ItemPackage? package,
    PackageNutrition nutrition = const PackageNutrition(),

    /// Whose medicine this is, as a household member's `clientId`.
    String? memberId,

    /// Days before a medicine in daily use runs out to remind of a new
    /// prescription, or null for none; see the column.
    int? refillLeadDays,
  }) async {
    final now = DateTime.now().toUtc();
    // A new figure is a new count. Anything else on the row -- a name, a
    // shelf, a note -- leaves the count where it was: a pack in daily use
    // counted from a rename would read as full again (#150).
    final recounted = quantity != existing.quantity;
    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: existing.clientId,
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
        dailyDose: Value(dailyDose),
        expiryLeadDays: Value(expiryLeadDays),
        foodGroup: Value(foodGroup),
        packageName: Value(package?.name),
        packageSize: Value(package?.size),
        memberId: Value(memberId),
        refillLeadDays: Value(refillLeadDays),
        stockCountedAt: recounted ? Value(now) : const Value.absent(),
        notes: Value(notes),
        photoPath: Value(photoPath),
        calories: Value(nutrition.kcal),
        proteinGrams: Value(nutrition.proteinGrams),
        carbohydrateGrams: Value(nutrition.carbohydrateGrams),
        fatGrams: Value(nutrition.fatGrams),
        fiberGrams: Value(nutrition.fiberGrams),
        updatedAt: now,
        dirty: const Value(true),
      ),
    );
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
          stockCountedAt: Value(DateTime.now().toUtc()),
          updatedAt: DateTime.now().toUtc(),
          dirty: const Value(true),
        ),
    ]);
  }

  /// Deducts [amount] from an item's stock — the rotation step: use up
  /// what is nearest to expiring and write down what is left, without
  /// going through the full edit form.
  ///
  /// Reaching zero leaves the item in place rather than tombstoning it.
  /// A staple that ran out is exactly what the low-stock badge and the
  /// missing-equipment report are for; deleting it would quietly drop it
  /// off both, which is the opposite of what an emptied supply should do.
  Future<void> consumeQuantity(InventoryItem existing, double amount) async {
    final remaining = (existing.quantity - amount).clamp(
      0.0,
      existing.quantity,
    );

    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: existing.clientId,
        householdId: existing.householdId,
        name: existing.name,
        category: existing.category,
        barcode: Value(existing.barcode),
        offProductId: Value(existing.offProductId),
        quantity: remaining,
        unit: existing.unit,
        storageLocation: existing.storageLocation,
        expirationDate: Value(existing.expirationDate),
        minQuantity: Value(existing.minQuantity),
        notes: Value(existing.notes),
        photoPath: Value(existing.photoPath),
        calories: Value(existing.calories),
        proteinGrams: Value(existing.proteinGrams),
        carbohydrateGrams: Value(existing.carbohydrateGrams),
        fatGrams: Value(existing.fatGrams),
        fiberGrams: Value(existing.fiberGrams),
        // Booking down is counting: what is left is now known (#150).
        stockCountedAt: Value(DateTime.now().toUtc()),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  /// Turns food counted in packages -- "6 Dosen" -- into a measure, once
  /// the household has said what one holds (#109).
  ///
  /// Such a row counts no calories: a label is per 100 g and a tin has no
  /// weight until somebody reads it. Since 2.3.8 the form only takes
  /// measures for food, but rows from before stay as they were typed, and
  /// the supply calculator could only say they were missing. This keeps
  /// the package as the way to say an amount at the shelf -- the old unit
  /// becomes its name -- so taking one tin still takes one tin, and the
  /// calories drop with it.
  Future<void> countInMeasure(
    InventoryItem existing, {
    required double perPackage,
    required String measure,
  }) async {
    final package = ItemPackage.from(existing.unit, perPackage);
    if (package == null) return;
    final minimum = existing.minQuantity;
    await _db.upsertInventoryItem(
      existing
          .toCompanion(false)
          .copyWith(
            quantity: Value(package.toUnits(existing.quantity)),
            unit: Value(measure),
            minQuantity: Value(
              minimum == null ? null : package.toUnits(minimum),
            ),
            packageName: Value(package.name),
            packageSize: Value(package.size),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  /// Undo restores the latest stored fields, not an old form snapshot.
  Future<void> restoreItem(String clientId) async {
    final row =
        await (_db.select(_db.inventoryItems)..where(
              (t) =>
                  t.clientId.equals(clientId) &
                  t.householdId.equals(householdId),
            ))
            .getSingleOrNull();
    if (row == null || row.deletedAt == null) return;
    await _db.upsertInventoryItem(
      row
          .toCompanion(false)
          .copyWith(
            deletedAt: const Value(null),
            updatedAt: Value(DateTime.now().toUtc()),
            dirty: const Value(true),
          ),
    );
  }

  Future<void> deleteItem(InventoryItem existing) async {
    await _db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: existing.clientId,
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
        proteinGrams: Value(existing.proteinGrams),
        carbohydrateGrams: Value(existing.carbohydrateGrams),
        fatGrams: Value(existing.fatGrams),
        fiberGrams: Value(existing.fiberGrams),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
        deletedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}

final inventoryControllerProvider = Provider.autoDispose
    .family<InventoryController, String>(
      (ref, householdId) => InventoryController(
        ref.watch(appDatabaseProvider),
        householdId,
      ),
    );
