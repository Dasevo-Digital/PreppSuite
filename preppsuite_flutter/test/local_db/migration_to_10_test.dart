import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 10 adds `household_plans`.
///
/// A plain `CREATE TABLE`, so what is worth proving is not the statement
/// but that it runs at all for an install already on 9 — and that the
/// `from < 6` repair, which walks a hard-coded list of table names, does
/// not try to touch a table that did not exist back then.
void main() {
  /// An install sitting on schema 9.
  NativeDatabase schemaNineDatabase() {
    return NativeDatabase.memory(
      setup: (raw) {
        raw.execute(
          'CREATE TABLE "inventory_items" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NOT NULL, '
          '"name" TEXT NOT NULL, "category" TEXT NOT NULL, '
          '"barcode" TEXT NULL, "off_product_id" TEXT NULL, '
          '"quantity" REAL NOT NULL, "unit" TEXT NOT NULL, '
          '"storage_location" TEXT NOT NULL, '
          '"expiration_date" INTEGER NULL, "min_quantity" REAL NULL, '
          '"calories" INTEGER NULL, "protein_grams" REAL NULL, '
          '"carbohydrate_grams" REAL NULL, "fat_grams" REAL NULL, '
          '"fiber_grams" REAL NULL, "notes" TEXT NULL, '
          '"photo_path" TEXT NULL, "updated_at" INTEGER NOT NULL, '
          '"deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'INSERT INTO inventory_items (client_id, household_id, name, '
          'category, quantity, unit, storage_location, updated_at, dirty) '
          "VALUES ('tuna', 'household-1', 'Thunfisch', 'food', 3, 'Dose', "
          "'Keller', 1767225600, 0)",
        );

        raw.execute('PRAGMA user_version = 9');
      },
    );
  }

  test('upgrading from 9 adds the plan table and keeps the rows', () async {
    final db = AppDatabase.forTesting(schemaNineDatabase());
    addTearDown(db.close);

    // The table exists and is empty: a household that never wrote a plan
    // has none, which is a state the screen shows rather than an error.
    expect(await db.watchHouseholdPlan('household-1').first, isNull);
    expect(
      (await db.inventoryItemsForSync('household-1')).single.name,
      'Thunfisch',
    );
  });

  test('a plan written after the upgrade reads back', () async {
    final db = AppDatabase.forTesting(schemaNineDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'household-1',
        householdId: 'household-1',
        meetingPointNear: const Value('Die Ecke bei der Bäckerei'),
        updatedAt: DateTime.utc(2026),
        dirty: const Value(true),
      ),
    );

    final plan = await db.watchHouseholdPlan('household-1').first;
    expect(plan?.meetingPointNear, 'Die Ecke bei der Bäckerei');
    expect(plan?.contactName, isNull);
  });

  test('a tombstoned plan reads as absent', () async {
    // "We deleted it" has to look like "there is none", or the screen
    // would show an empty form as if it were a saved one.
    final db = AppDatabase.forTesting(schemaNineDatabase());
    addTearDown(db.close);

    await db.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: 'household-1',
        householdId: 'household-1',
        meetingPointNear: const Value('Weg damit'),
        updatedAt: DateTime.utc(2026),
        deletedAt: Value(DateTime.utc(2026, 2)),
        dirty: const Value(true),
      ),
    );

    expect(await db.watchHouseholdPlan('household-1').first, isNull);
  });
}
