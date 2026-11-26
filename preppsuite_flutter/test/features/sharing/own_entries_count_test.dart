import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// The number the question about two households puts on screen (#399).
///
/// It was the snapshot's row count: every built-in checklist line and
/// every tombstone included. A device that had typed nothing was told that
/// some 230 entries of its own would move or be deleted, and the dialog's
/// "nothing to bring" never appeared.
void main() {
  const householdId = 'mine';
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await ChecklistSeeder(db).seed(householdId);
  });

  tearDown(() => db.close());

  InventoryItemsCompanion stock(
    String clientId, {
    double quantity = 2,
    DateTime? deletedAt,
  }) => InventoryItemsCompanion.insert(
    clientId: clientId,
    householdId: householdId,
    name: clientId,
    category: 'food',
    quantity: quantity,
    unit: 'kg',
    storageLocation: 'Keller',
    updatedAt: DateTime.utc(2026, 5),
    deletedAt: Value(deletedAt),
    dirty: const Value(true),
  );

  test('a household with only the built-in lists brings nothing', () async {
    final snapshot = await readHouseholdSnapshot(
      db,
      deviceId: 'conflict',
      householdId: householdId,
    );
    expect(snapshot.rowCount, greaterThan(200), reason: 'what used to show');

    expect(await countOwnEntries(db, householdId), 0);
  });

  test('what was made or changed here counts, a deletion does not', () async {
    final controller = ChecklistController(db, householdId);
    await db.upsertInventoryItem(stock('rice'));
    await db.upsertInventoryItem(
      stock('flour', deletedAt: DateTime.utc(2026, 5, 2)),
    );
    final line = (await db.watchAllChecklistItems(householdId).first).first;
    await controller.toggleItem(line);
    await controller.createTemplate(
      title: 'Garten',
      category: ChecklistCategory.custom,
    );

    // The rice, the ticked line and the list of its own.
    expect(await countOwnEntries(db, householdId), 3);
  });

  test('a stock row that cannot travel does not stop the question', () async {
    await db.upsertInventoryItem(stock('rice', quantity: -1));

    expect(await countOwnEntries(db, householdId), 1);
  });

  test('another household\'s rows are not this one\'s', () async {
    await db.upsertInventoryItem(
      stock('rice').copyWith(householdId: const Value('theirs')),
    );

    expect(await countOwnEntries(db, householdId), 0);
    expect(await countOwnEntries(db, 'theirs'), 1);
  });
}
