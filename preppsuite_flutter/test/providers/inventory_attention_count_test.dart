import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() {
    container.dispose();
    db.close();
  });

  InventoryItemsCompanion draft({
    required String clientId,
    double quantity = 5,
    double? minQuantity,
    DateTime? expirationDate,
  }) {
    return InventoryItemsCompanion.insert(
      clientId: clientId,
      householdId: 'household-1',
      name: 'Item $clientId',
      category: 'water',
      quantity: quantity,
      unit: 'Stück',
      storageLocation: 'Keller',
      minQuantity: Value(minQuantity),
      expirationDate: Value(expirationDate),
      updatedAt: DateTime.utc(2026),
    );
  }

  /// [inventoryItemsProvider] is `.autoDispose`, so it tears itself down the
  /// moment nothing is watching it — keep a live subscription open (as
  /// `HomeShell`'s `ref.watch` would in the real app) for the duration of
  /// the assertion.
  Future<int> attentionCountAfterSettling() async {
    final sub = container.listen(
      inventoryItemsProvider('household-1'),
      (_, _) {},
    );
    await container.read(inventoryItemsProvider('household-1').future);
    final count = container.read(inventoryAttentionCountProvider('household-1'));
    sub.close();
    return count;
  }

  test('counts zero when nothing is low-stock or expired', () async {
    await db.upsertInventoryItem(draft(clientId: 'a', quantity: 10, minQuantity: 2));

    expect(await attentionCountAfterSettling(), 0);
  });

  test('counts items below minimum quantity', () async {
    await db.upsertInventoryItem(draft(clientId: 'low', quantity: 1, minQuantity: 5));
    await db.upsertInventoryItem(draft(clientId: 'ok', quantity: 10, minQuantity: 5));

    expect(await attentionCountAfterSettling(), 1);
  });

  test('counts expired items even without a minimum quantity set', () async {
    await db.upsertInventoryItem(
      draft(clientId: 'expired', expirationDate: DateTime.utc(2000)),
    );
    await db.upsertInventoryItem(
      draft(clientId: 'fresh', expirationDate: DateTime.utc(2100)),
    );

    expect(await attentionCountAfterSettling(), 1);
  });

  test('counts an item only once even if both low-stock and expired', () async {
    await db.upsertInventoryItem(
      draft(
        clientId: 'both',
        quantity: 1,
        minQuantity: 5,
        expirationDate: DateTime.utc(2000),
      ),
    );

    expect(await attentionCountAfterSettling(), 1);
  });
}
