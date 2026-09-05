import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_flutter/model/categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
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
