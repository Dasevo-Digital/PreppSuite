import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 22 indexes the partition key (#99).
///
/// Every screen and every sync selects by `household_id`, and until now
/// nothing was indexed. A fresh install gets the indexes from the
/// `@TableIndex` annotations and an upgrade from the migration's own list;
/// this holds the two to the same names, and checks SQLite really uses one.
void main() {
  NativeDatabase schemaTwentyDatabase() => NativeDatabase.memory(
    setup: (raw) {
      raw
        ..execute(
          'CREATE TABLE "inventory_items" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NOT NULL, '
          '"name" TEXT NOT NULL, "category" TEXT NOT NULL, '
          '"barcode" TEXT NULL, "off_product_id" TEXT NULL, '
          '"quantity" REAL NOT NULL, "unit" TEXT NOT NULL, '
          '"storage_location" TEXT NOT NULL, '
          '"expiration_date" INTEGER NULL, "min_quantity" REAL NULL, '
          '"calories" REAL NULL, "protein_grams" REAL NULL, '
          '"carbohydrate_grams" REAL NULL, "fat_grams" REAL NULL, '
          '"fiber_grams" REAL NULL, "daily_dose" REAL NULL, '
          '"expiry_lead_days" TEXT NULL, "food_group" TEXT NULL, '
          '"notes" TEXT NULL, "photo_path" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        )
        ..execute(
          'INSERT INTO inventory_items '
          '(client_id, household_id, name, category, quantity, unit, '
          'storage_location, updated_at, dirty) VALUES '
          "('item-1', 'household-1', 'Nudeln', 'food', 2, 'kg', "
          "'Keller', 1767225600, 0)",
        )
        ..execute('PRAGMA user_version = 20');
    },
  );

  const expected = {
    'budget_entries_household',
    'checklist_items_household',
    'checklist_items_template',
    'checklist_templates_household',
    'household_members_household',
    'household_plans_household',
    'inventory_items_household',
    'possessions_household',
  };

  Future<Set<String>> indexes(AppDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name NOT LIKE 'sqlite_%'",
        )
        .get();
    return {for (final row in rows) row.read<String>('name')};
  }

  test('a fresh install has every index', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(await indexes(db), containsAll(expected));
  });

  test('an upgrade indexes the tables it has, and skips the rest', () async {
    // The schema-20 database here holds only `inventory_items`. The
    // other tables are created later in the upgrade, or were never
    // there; an index on a table that does not exist must not stop it.
    final db = AppDatabase.forTesting(schemaTwentyDatabase());
    addTearDown(db.close);
    await db.watchInventoryItems('household-1').first;

    expect(await indexes(db), contains('inventory_items_household'));
  });

  test('the inventory of a household is read through its index', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM inventory_items '
          "WHERE household_id = 'h'",
        )
        .get();
    expect(
      plan.map((row) => row.read<String>('detail')).join(' '),
      contains('inventory_items_household'),
    );
  });
}
