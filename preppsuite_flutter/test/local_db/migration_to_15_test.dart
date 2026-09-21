import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 15 turns `calories` from an integer into a real.
///
/// Nothing is converted — SQLite stores what it is given and every value
/// written before this was whole — so what has to hold is that the rebuild
/// keeps the rows and that the column will now take a fraction. The second
/// half is the point of the change: bread is 2.13 kcal a gram, and as an
/// integer that was 2.
///
/// The branch is `from >= 8`, because anything older is rebuilt from
/// today's definition in the schema-8 branch and arrives already real.
/// That half is not repeated here: `migration_rerun_test.dart` already
/// replays every version from 1 up over today's schema, which is a
/// stricter version of the same question and does not need a version-7
/// database reconstructed by hand.
void main() {
  /// `inventory_items` as schema 14 left it: today's table with `calories`
  /// still declared INTEGER, and two rows already in it.
  NativeDatabase schemaFourteenDatabase() {
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
          '"fiber_grams" REAL NULL, "daily_dose" REAL NULL, '
          '"notes" TEXT NULL, "photo_path" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'INSERT INTO inventory_items (client_id, household_id, name, '
          'category, quantity, unit, storage_location, calories, '
          'updated_at, dirty) VALUES '
          "('tin', 'household-1', 'Ravioli', 'food', 6, 'Dose', "
          "'Keller', 900, 1767225600, 0)",
        );
        raw.execute(
          'INSERT INTO inventory_items (client_id, household_id, name, '
          'category, quantity, unit, storage_location, calories, '
          'updated_at, dirty) VALUES '
          "('salt', 'household-1', 'Salz', 'food', 1, 'Packung', "
          "'Keller', NULL, 1767225600, 0)",
        );
        raw.execute('PRAGMA user_version = 14');
      },
    );
  }

  test('upgrading from 14 keeps the rows and their figures', () async {
    final db = AppDatabase.forTesting(schemaFourteenDatabase());
    addTearDown(db.close);

    final items = await db.watchInventoryItems('household-1').first;
    expect(items, hasLength(2));

    final tin = items.firstWhere((item) => item.clientId == 'tin');
    expect(tin.calories, 900);
    expect(tin.quantity, 6);

    // Null stays null. An unanswered calorie figure is not a zero, and the
    // supply calculator counts on being able to tell them apart.
    expect(
      items.firstWhere((item) => item.clientId == 'salt').calories,
      isNull,
    );
  });

  test('and the column now takes the fraction it refused before', () async {
    final db = AppDatabase.forTesting(schemaFourteenDatabase());
    addTearDown(db.close);

    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'bread',
        householdId: 'household-1',
        name: 'Vollkornbrot',
        category: 'food',
        quantity: 400,
        unit: 'g',
        storageLocation: 'Keller',
        calories: const Value(2.13),
        updatedAt: DateTime.utc(2026, 9, 21),
      ),
    );

    final items = await db.watchInventoryItems('household-1').first;
    final bread = items.firstWhere((item) => item.clientId == 'bread');
    expect(bread.calories, closeTo(2.13, 0.0001));
  });
}
