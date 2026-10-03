import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 21 lets a row name the package it comes in — "Glas", 370 —
/// so that consuming can be counted in jars (#90).
///
/// Null everywhere after the upgrade. The size is printed on the jar and
/// is not in the database; an upgrade that guessed one would deduct the
/// wrong amount on the very first tap.
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

  test('upgrading keeps the row and gives it no package', () async {
    final db = AppDatabase.forTesting(schemaTwentyDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;

    expect(item.name, 'Nudeln');
    expect(item.quantity, 2);
    expect(item.packageName, isNull);
    expect(item.packageSize, isNull);
  });

  test('a package written after the upgrade reads back', () async {
    final db = AppDatabase.forTesting(schemaTwentyDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;
    await db.upsertInventoryItem(
      item
          .toCompanion(false)
          .copyWith(
            packageName: const Value('Packung'),
            packageSize: const Value(0.5),
          ),
    );

    final stored = (await db.watchInventoryItems('household-1').first).single;
    expect(stored.packageName, 'Packung');
    expect(stored.packageSize, 0.5);
  });
}
