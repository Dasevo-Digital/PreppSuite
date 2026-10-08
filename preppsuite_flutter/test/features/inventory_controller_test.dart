import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_flutter/model/categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/item_package.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/features/inventory/application/package_nutrition.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late ProviderContainer container;
  late InventoryController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    controller = container.read(inventoryControllerProvider(householdId));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<InventoryItem> storedItem() async {
    final items = await db.watchInventoryItems(householdId).first;
    return items.single;
  }

  Future<void> addItem({double quantity = 5, double? minQuantity}) {
    return db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'a',
        householdId: householdId,
        name: 'Nudeln',
        category: 'food',
        quantity: quantity,
        unit: 'Stk',
        storageLocation: 'Keller',
        minQuantity: Value(minQuantity),
        updatedAt: DateTime.utc(2026),
        dirty: const Value(false),
      ),
    );
  }

  test(
    'undo restores a deletion with a newer version and can sync again',
    () async {
      await addItem(quantity: 7, minQuantity: 9);
      final before = await storedItem();
      await controller.deleteItem(before);
      final deleted = (await db.dirtyInventoryItems(householdId)).single;
      expect(await db.watchInventoryItems(householdId).first, isEmpty);
      await controller.restoreItem(before.clientId);
      final restored = await storedItem();
      expect(restored.quantity, 7);
      expect(restored.minQuantity, 9);
      expect(restored.updatedAt.isAfter(deleted.updatedAt), isTrue);
      expect(restored.dirty, isTrue);
      await controller.restoreItem(before.clientId);
      expect((await storedItem()).updatedAt, restored.updatedAt);
    },
  );

  group('countInMeasure (#109)', () {
    test('six tins become grams, the tin stays the package', () async {
      await addItem(quantity: 6, minQuantity: 2);
      await db.customStatement(
        "UPDATE inventory_items SET unit = 'Dose', calories = 120",
      );

      await controller.countInMeasure(
        await storedItem(),
        perPackage: 400,
        measure: 'g',
      );

      final item = await storedItem();
      expect(item.quantity, 2400);
      expect(item.unit, 'g');
      expect(item.minQuantity, 800);
      expect(item.packageName, 'Dose');
      expect(item.packageSize, 400);
      expect(item.dirty, isTrue);
      // What the change is for: the calculator counts it now, 2400 g at
      // 120 kcal per 100 g.
      expect(
        calculateSupply(items: [item], days: 1).caloriesCurrent,
        2880,
      );
      expect(foodWithoutMeasure([item]), isEmpty);

      // And one tin is still one tin at the shelf.
      await controller.consumeQuantity(item, ItemPackage.of(item)!.size);
      expect((await storedItem()).quantity, 2000);
    });

    test('a size of nothing changes nothing', () async {
      await addItem(quantity: 6);
      await controller.countInMeasure(
        await storedItem(),
        perPackage: 0,
        measure: 'g',
      );
      expect((await storedItem()).unit, 'Stk');
      expect((await storedItem()).quantity, 6);
    });
  });

  group('consumeQuantity', () {
    test('subtracts the amount and marks the row dirty for sync', () async {
      await addItem(quantity: 5);

      await controller.consumeQuantity(await storedItem(), 2);

      final item = await storedItem();
      expect(item.quantity, 3);
      expect(item.dirty, isTrue, reason: 'the change has to reach the server');
    });

    test('deducting everything leaves the item in place at zero', () async {
      // An emptied staple must stay visible: it is exactly what the
      // low-stock badge and the missing-equipment report exist for.
      await addItem(quantity: 2, minQuantity: 1);

      await controller.consumeQuantity(await storedItem(), 2);

      final item = await storedItem();
      expect(item.quantity, 0);
      expect(item.deletedAt, isNull, reason: 'never tombstoned by consuming');
    });

    test(
      'never goes negative, even if more is deducted than is there',
      () async {
        await addItem(quantity: 1);

        await controller.consumeQuantity(await storedItem(), 5);

        expect((await storedItem()).quantity, 0);
      },
    );

    test('leaves every other field untouched', () async {
      await addItem(quantity: 5, minQuantity: 2);
      final before = await storedItem();

      await controller.consumeQuantity(before, 1);
      final after = await storedItem();

      expect(after.name, before.name);
      expect(after.unit, before.unit);
      expect(after.storageLocation, before.storageLocation);
      expect(after.minQuantity, before.minQuantity);
      expect(after.category, before.category);
      expect(after.clientId, before.clientId);
    });

    test('stamps a fresh updatedAt so last-write-wins can order it', () async {
      await addItem(quantity: 5);
      final before = await storedItem();

      await controller.consumeQuantity(before, 1);

      expect((await storedItem()).updatedAt.isAfter(before.updatedAt), isTrue);
    });
  });

  group('nutrition', () {
    const scanned = PackageNutrition(
      kcal: 1750,
      proteinGrams: 42.5,
      carbohydrateGrams: 300,
      fatGrams: 8,
      fiberGrams: 15,
    );

    test('what the scan read is what the row holds', () async {
      await controller.addItem(
        name: 'Haferflocken',
        category: InventoryItemCategory.food,
        quantity: 1,
        unit: 'Packung',
        storageLocation: 'Keller',
        nutrition: scanned,
      );

      final item = await storedItem();
      expect(item.calories, 1750);
      expect(item.proteinGrams, 42.5);
      expect(item.carbohydrateGrams, 300);
      expect(item.fatGrams, 8);
      expect(item.fiberGrams, 15);
    });

    test('using some of an item keeps its nutrition', () async {
      // Consuming rewrites the whole row, so a column the rewrite forgets
      // is silently emptied — which is how a scanned label would be lost
      // the first time anyone ate from the packet.
      await controller.addItem(
        name: 'Haferflocken',
        category: InventoryItemCategory.food,
        quantity: 2,
        unit: 'Packung',
        storageLocation: 'Keller',
        nutrition: scanned,
      );

      await controller.consumeQuantity(await storedItem(), 1);

      final item = await storedItem();
      expect(item.quantity, 1);
      expect(item.calories, 1750);
      expect(item.proteinGrams, 42.5);
      expect(item.fiberGrams, 15);
    });

    test('an item nobody scanned keeps four nulls, not four zeroes', () async {
      await controller.addItem(
        name: 'Kerzen',
        category: InventoryItemCategory.other,
        quantity: 10,
        unit: 'Stk',
        storageLocation: 'Keller',
      );

      final item = await storedItem();
      expect(item.calories, isNull);
      expect(item.proteinGrams, isNull);
      expect(item.carbohydrateGrams, isNull);
      expect(item.fatGrams, isNull);
      expect(item.fiberGrams, isNull);
    });
  });

  /// A package is a second way to say an amount (#90). These hold the
  /// two things that make it worth having: it survives every rewrite of
  /// the row, and taking one jar off takes that jar's calories off the
  /// supply total.
  group('package', () {
    const jar = ItemPackage(name: 'Glas', size: 370);

    Future<void> addJars() => controller.addItem(
      name: 'Bohnen',
      category: InventoryItemCategory.food,
      quantity: 1110,
      unit: 'g',
      storageLocation: 'Keller',
      package: jar,
      nutrition: const PackageNutrition(kcal: 100),
    );

    test('what the form names is what the row holds', () async {
      await addJars();

      final item = await storedItem();
      expect(item.packageName, 'Glas');
      expect(item.packageSize, 370);
    });

    test('consuming keeps the package', () async {
      await addJars();

      await controller.consumeQuantity(await storedItem(), 370);

      final item = await storedItem();
      expect(item.quantity, 740);
      expect(ItemPackage.of(item)?.size, 370);
    });

    test('one jar consumed is one jar of calories gone', () async {
      await addJars();
      int kcal(InventoryItem item) =>
          calculateSupply(items: [item], days: 10).caloriesCurrent;
      final before = await storedItem();
      expect(kcal(before), 1110);

      await controller.consumeQuantity(before, jar.toUnits(1));

      expect(kcal(await storedItem()), 740);
    });

    test('an edit without a package removes it', () async {
      await addJars();
      final item = await storedItem();

      await controller.updateItem(
        item,
        name: item.name,
        category: InventoryItemCategory.food,
        quantity: item.quantity,
        unit: item.unit,
        storageLocation: item.storageLocation,
      );

      final edited = await storedItem();
      expect(edited.packageName, isNull);
      expect(edited.packageSize, isNull);
    });
  });

  /// Guards a bug that silently lost every edit to an already-synced row:
  /// `dirty` defaults to true only on INSERT, and `insertOnConflictUpdate`
  /// leaves out any column the companion does not set — so an update wrote
  /// the new values but left `dirty` at false, and the change was never
  /// picked up for push. Deletions were affected too, meaning a row deleted
  /// on one device stayed on every other one.
  group('every local write marks the row for push', () {
    test('after editing', () async {
      await addItem(quantity: 5);

      await controller.updateItem(
        await storedItem(),
        name: 'Reis',
        category: InventoryItemCategory.food,
        quantity: 5,
        unit: 'Stk',
        storageLocation: 'Keller',
      );

      expect((await storedItem()).dirty, isTrue);
    });

    test('after consuming', () async {
      await addItem(quantity: 5);

      await controller.consumeQuantity(await storedItem(), 1);

      expect((await storedItem()).dirty, isTrue);
    });

    test('after deleting', () async {
      await addItem(quantity: 5);

      await controller.deleteItem(await storedItem());

      final tombstoned = await db.dirtyInventoryItems(householdId);
      expect(tombstoned.single.deletedAt, isNotNull);
      expect(
        tombstoned.single.dirty,
        isTrue,
        reason: 'otherwise the deletion never reaches the other devices',
      );
    });
  });
}
