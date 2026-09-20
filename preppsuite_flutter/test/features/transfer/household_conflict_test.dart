import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// What the three answers to "two different households" actually do.
///
/// The dialog is a widget, but what it decides is data, and that is the
/// part somebody cannot get back. Each of these runs the same two steps
/// the screen runs, against a real database.
void main() {
  const mine = 'my-household';
  const theirs = 'their-household';

  Future<AppDatabase> withRow(String householdId, String name) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: name,
        householdId: householdId,
        name: name,
        category: 'food',
        quantity: 1,
        unit: 'Stk',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 9, 20),
      ),
    );
    return db;
  }

  /// Built by reading a real database, not by hand: that way the row
  /// codec is exercised too, and a snapshot that would not survive the
  /// wire cannot pass this test.
  Future<DeviceSnapshot> theirSnapshot() async {
    final other = await withRow(theirs, 'Ihre Nudeln');
    addTearDown(other.close);
    return readHouseholdSnapshot(
      other,
      deviceId: 'other',
      householdId: theirs,
    );
  }

  Future<List<String>> namesIn(AppDatabase db, String householdId) async =>
      (await db.watchInventoryItems(householdId).first)
          .map((item) => item.name)
          .toList();

  test('merging keeps both sides', () async {
    final db = await withRow(mine, 'Meine Bohnen');
    addTearDown(db.close);

    await db.adoptHouseholdId(from: mine, to: theirs);
    await applyHouseholdSnapshot(db, await theirSnapshot());

    // The whole point: the row this device had is still there, now under
    // the other household, and the other household's row arrived.
    expect(await namesIn(db, theirs), ['Ihre Nudeln', 'Meine Bohnen']);
    expect(await namesIn(db, mine), isEmpty);
  });

  test('discarding drops only this device, never the other side', () async {
    final db = await withRow(mine, 'Meine Bohnen');
    addTearDown(db.close);

    await db.deleteHouseholdData(mine);
    await db.adoptHouseholdId(from: mine, to: theirs);
    await applyHouseholdSnapshot(db, await theirSnapshot());

    expect(await namesIn(db, theirs), ['Ihre Nudeln']);
  });

  test('changing nothing really changes nothing', () async {
    final db = await withRow(mine, 'Meine Bohnen');
    addTearDown(db.close);

    // No adoption, no delete, no snapshot applied — the path the third
    // answer takes.
    expect(await namesIn(db, mine), ['Meine Bohnen']);
    expect(await namesIn(db, theirs), isEmpty);
  });

  test('deleting one household leaves the other alone', () async {
    final db = await withRow(mine, 'Meine Bohnen');
    addTearDown(db.close);
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'fremd',
        householdId: theirs,
        name: 'Fremde Bohnen',
        category: 'food',
        quantity: 1,
        unit: 'Stk',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 9, 20),
        dirty: const Value(false),
      ),
    );

    await db.deleteHouseholdData(mine);

    expect(await namesIn(db, mine), isEmpty);
    expect(await namesIn(db, theirs), ['Fremde Bohnen']);
  });

  test('a snapshot counts every table it carries, possessions too', () {
    // The counter this replaced lived in `local_handover.dart` and had
    // never been told about possessions, so a handover under-reported
    // what it had sent.
    final snapshot = DeviceSnapshot(
      deviceId: 'd',
      householdId: mine,
      writtenAt: DateTime.utc(2026, 9, 20),
      inventoryItems: [{}, {}],
      checklistItems: [{}],
      possessions: [{}, {}, {}],
    );

    expect(snapshot.rowCount, 6);
    expect(
      DeviceSnapshot(
        deviceId: 'd',
        householdId: mine,
        writtenAt: DateTime.utc(2026, 9, 20),
      ).rowCount,
      0,
    );
  });
}
