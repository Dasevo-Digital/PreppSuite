import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 20 lets a row say which of the BLE's supply groups it counts
/// towards.
///
/// Null everywhere after the upgrade, and null means "not stated" — the
/// group screen names such rows rather than assigning them. An upgrade
/// that guessed would put figures on a screen that nobody entered.
void main() {
  NativeDatabase schemaNineteenDatabase() => NativeDatabase.memory(
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
          '"expiry_lead_days" TEXT NULL, '
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
        ..execute('PRAGMA user_version = 19');
    },
  );

  test('upgrading keeps the row and assigns it to nothing', () async {
    final db = AppDatabase.forTesting(schemaNineteenDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;

    expect(item.name, 'Nudeln');
    expect(item.quantity, 2);
    // "Nudeln" is grain nearly always. Nearly always is not something a
    // migration writes into somebody's database.
    expect(item.foodGroup, isNull);
  });
}
