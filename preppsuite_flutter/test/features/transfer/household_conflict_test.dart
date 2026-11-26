import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
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

  // Every built-in checklist row has one client id in every household, and
  // the merge goes by that id. Replacing merges the other household in
  // first and discards this device's rows after: this device's own copy
  // won whenever it was newer -- a tick, a deletion -- or won the tie, was
  // discarded a moment later, and the line was gone (#341).
  group('a row both households hold', () {
    Future<AppDatabase> seeded(String householdId) async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await ChecklistSeeder(db).seed(householdId);
      return db;
    }

    Future<List<ChecklistItem>> lines(AppDatabase db, String id) =>
        db.watchAllChecklistItems(id).first;

    late AppDatabase db;
    late ChecklistItem ticked;
    late ChecklistItem deleted;
    late DeviceSnapshot others;

    setUp(() async {
      db = await seeded(mine);
      final shipped = await lines(db, mine);
      ticked = shipped[0];
      deleted = shipped[1];
      final controller = ChecklistController(db, mine);
      await controller.toggleItem(ticked);
      await controller.deleteItem(deleted);

      final other = await seeded(theirs);
      addTearDown(other.close);
      others = await readHouseholdSnapshot(
        other,
        deviceId: 'other',
        householdId: theirs,
      );
    });

    tearDown(() => db.close());

    test('replacing takes the other household\'s version of it', () async {
      final shipped = (await lines(db, mine)).length + 1;

      // The QR chain's order: their rows in, then the move discards ours.
      await applyHouseholdSnapshot(db, others, replacing: true);
      await db.deleteHouseholdData(mine);

      final now = await lines(db, theirs);
      expect(now, hasLength(shipped), reason: 'no line lost');
      expect(
        now.singleWhere((line) => line.clientId == ticked.clientId).isChecked,
        isFalse,
        reason: 'their line, not the tick discarded with this device',
      );
      expect(now.map((line) => line.clientId), contains(deleted.clientId));
    });

    test('merging still keeps the newer of the two', () async {
      await applyHouseholdSnapshot(db, others);
      await db.adoptHouseholdId(from: mine, to: theirs);

      final now = await lines(db, theirs);
      expect(
        now.singleWhere((line) => line.clientId == ticked.clientId).isChecked,
        isTrue,
      );
      expect(
        now.map((line) => line.clientId),
        isNot(contains(deleted.clientId)),
      );
    });
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
