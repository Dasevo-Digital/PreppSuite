import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Finding the item behind a scanned code, for booking a consumption.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<void> insert({
    required String clientId,
    String householdId = 'h',
    String? barcode,
    DateTime? deletedAt,
    DateTime? updatedAt,
  }) => db.upsertInventoryItem(
    InventoryItemsCompanion.insert(
      clientId: clientId,
      householdId: householdId,
      name: clientId,
      category: 'food',
      barcode: Value(barcode),
      quantity: 1,
      unit: 'Stück',
      storageLocation: 'Keller',
      deletedAt: Value(deletedAt),
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
      dirty: const Value(true),
    ),
  );

  test('finds the item carrying the code', () async {
    await insert(clientId: 'bohnen', barcode: '4001234567890');

    final found = await db.findInventoryItemByBarcode('h', '4001234567890');

    expect(found?.clientId, 'bohnen');
  });

  test('an unknown code finds nothing rather than the first row', () async {
    await insert(clientId: 'bohnen', barcode: '4001234567890');

    expect(await db.findInventoryItemByBarcode('h', '999'), isNull);
  });

  test('another household is not searched', () async {
    // Every query in this app partitions by household; a scan must not be
    // the one hole in that.
    await insert(clientId: 'fremd', householdId: 'other', barcode: '111');

    expect(await db.findInventoryItemByBarcode('h', '111'), isNull);
  });

  test('a deleted row is not revived by a scan', () async {
    // A tombstone keeps its barcode. Booking a consumption against one
    // would resurrect a row someone deliberately deleted.
    await insert(
      clientId: 'geloescht',
      barcode: '111',
      deletedAt: DateTime.utc(2026, 2, 1),
    );

    expect(await db.findInventoryItemByBarcode('h', '111'), isNull);
  });

  test('with two rows on one code the newest wins', () async {
    // Happens when a second pack is entered as its own item rather than
    // added to the first. Deducting from the one last touched is the
    // guess that matches what someone just put in the cupboard.
    await insert(
      clientId: 'alt',
      barcode: '111',
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    await insert(
      clientId: 'neu',
      barcode: '111',
      updatedAt: DateTime.utc(2026, 6, 1),
    );

    final found = await db.findInventoryItemByBarcode('h', '111');

    expect(found?.clientId, 'neu');
  });

  test('an item without a code is never matched', () async {
    await insert(clientId: 'ohne');

    expect(await db.findInventoryItemByBarcode('h', ''), isNull);
  });
}
