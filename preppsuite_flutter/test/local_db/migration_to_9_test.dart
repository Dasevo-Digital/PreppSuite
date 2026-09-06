import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 9 adds the four macronutrient columns to `inventory_items`.
///
/// Plain `ALTER TABLE ADD COLUMN`, so the risk is not the statement but
/// the branch it sits in: an install older than 8 gets these columns from
/// the table rebuild in the schema-8 branch instead, and running both
/// would fail on a duplicate column. This covers the other half — an
/// install that is already on 8 — which `migration_to_8_test` cannot
/// reach.
void main() {
  /// `inventory_items` as schema 8 left it: today's table without the
  /// macronutrients.
  NativeDatabase schemaEightDatabase() {
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
          '"calories" INTEGER NULL, "notes" TEXT NULL, '
          '"photo_path" TEXT NULL, "updated_at" INTEGER NOT NULL, '
          '"deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'INSERT INTO inventory_items (client_id, household_id, name, '
          'category, quantity, unit, storage_location, calories, '
          'updated_at, dirty) VALUES '
          "('tuna', 'household-1', 'Thunfisch', 'food', 3, 'Dose', "
          "'Keller', 165, 1767225600, 0)",
        );

        raw.execute('PRAGMA user_version = 8');
      },
    );
  }

  test('upgrading from 8 adds the macronutrients and keeps the row', () async {
    final db = AppDatabase.forTesting(schemaEightDatabase());
    addTearDown(db.close);

    final items = await db.inventoryItemsForSync('household-1');

    expect(items.single.name, 'Thunfisch');
    expect(items.single.calories, 165);

    // Never zero: a null means the label did not say, and the difference
    // is what stops the supply calculator counting a guess as a fact.
    expect(items.single.proteinGrams, isNull);
    expect(items.single.carbohydrateGrams, isNull);
    expect(items.single.fatGrams, isNull);
    expect(items.single.fiberGrams, isNull);
  });
}
