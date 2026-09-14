import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/local_db/database.dart';

/// Every migration step has to survive being run a second time over a
/// database it has already migrated.
///
/// This is not a hypothetical. Drift runs `onUpgrade` and then records the
/// new version as a *separate* write, with no transaction around the pair
/// (`engines.dart`: "set version now, after migrations ran successfully").
/// A process that dies in between — a force quit, a crash, the bundle
/// being replaced under a running app — leaves the schema changed and the
/// version where it was. The next launch replays the same steps.
///
/// When a step is an unguarded `ALTER TABLE ADD COLUMN`, SQLite answers
/// "duplicate column name" and the migration throws. That happens before
/// there is any screen to show, so the app does not open — and it repeats
/// on every launch, for good. The real household database here reached
/// exactly that state between 1.7.4 and 1.8.0: `user_version` at 12 while
/// `household_plans` already had `local_contact_point`.
void main() {
  /// A database carrying today's schema and a little real data, with its
  /// recorded version wound back to [version] — i.e. what an interrupted
  /// upgrade leaves behind.
  Future<File> databaseRewoundTo(int version) async {
    final directory = await Directory.systemTemp.createTemp('preppsuite-db');
    addTearDown(() => directory.delete(recursive: true));
    final file = File(p.join(directory.path, 'preppsuite.sqlite'));

    final fresh = AppDatabase.forTesting(NativeDatabase(file));
    await fresh.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'household-1',
        householdId: 'household-1',
        meetingPointNear: const Value('Vor der Garage'),
        localContactPoint: const Value('Grundschule Nordstadt'),
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );
    await fresh.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'item-1',
        householdId: 'household-1',
        name: 'Haferflocken',
        category: 'Lebensmittel',
        quantity: 2,
        unit: 'kg',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );
    await fresh.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'item-2',
        householdId: 'household-1',
        name: 'Ramipril',
        category: 'medical',
        quantity: 60,
        unit: 'Tablette',
        storageLocation: 'Hausapotheke',
        dailyDose: const Value(2),
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );
    await fresh.upsertPossession(
      PossessionsCompanion.insert(
        clientId: 'possession-1',
        householdId: 'household-1',
        name: 'Waschmaschine',
        room: const Value('Keller'),
        updatedAt: DateTime.utc(2026, 9, 10),
      ),
    );
    await fresh.close();

    // Wound back in `setup`, which runs before drift reads the version,
    // so the reopen below genuinely believes it is on [version].
    return file;
  }

  AppDatabase reopenAt(File file, int version) {
    final db = AppDatabase.forTesting(
      NativeDatabase(
        file,
        setup: (raw) => raw.execute('PRAGMA user_version = $version'),
      ),
    );
    addTearDown(db.close);
    return db;
  }

  // A database wound back to anything below the current version replays
  // that many steps over a schema that already has them.
  for (var version = 1; version < AppDatabase.currentSchemaVersion; version++) {
    test('an upgrade interrupted at $version can be repeated', () async {
      final file = await databaseRewoundTo(version);
      final db = reopenAt(file, version);

      // Opening at all is the assertion that matters: this is the failure
      // that leaves no screen behind to report it.
      final plan = await db.watchHouseholdPlan('household-1').first;

      expect(plan, isNotNull, reason: 'the household plan survived');
      expect(plan!.meetingPointNear, 'Vor der Garage');
      expect(plan.localContactPoint, 'Grundschule Nordstadt');

      final items = await db.watchInventoryItems('household-1').first;
      expect(items.map((item) => item.name), contains('Haferflocken'));

      // Schema 14 added one column to a table the schema-8 rebuild
      // recreates, and one new table. Both are read here, because a
      // column left out of that branch's `newColumns` does not fail
      // loudly -- it fails on the one install that came from version 7.
      final medicine = items.firstWhere((item) => item.name == 'Ramipril');

      final owned = await db.watchPossessions('household-1').first;
      expect(owned.single.name, 'Waschmaschine');

      // The value itself only survives from 8 up, and that is correct
      // rather than a leak: `newColumns` tells drift the column is new,
      // so the rebuild creates it empty instead of copying it out of a
      // version-7 table that never had it. Nothing is lost in the field,
      // because an install that is genuinely on 7 cannot hold a dose --
      // the column did not exist there. Only this test can construct the
      // combination, by winding today's schema back.
      expect(medicine.dailyDose, version < 8 ? isNull : 2);
    });
  }

  test('the replay leaves the version recorded correctly', () async {
    final file = await databaseRewoundTo(12);
    final db = reopenAt(file, 12);
    await db.watchHouseholdPlan('household-1').first;

    final recorded = await db
        .customSelect('PRAGMA user_version')
        .map((row) => row.read<int>('user_version'))
        .getSingle();

    expect(recorded, AppDatabase.currentSchemaVersion);
  });
}
