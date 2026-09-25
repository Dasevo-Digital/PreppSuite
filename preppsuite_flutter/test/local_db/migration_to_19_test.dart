import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 19 lets one item carry its own expiry lead times.
///
/// The column arrives null everywhere, and null means "follow the
/// household" — so an upgrade changes nobody's reminders. That is the
/// whole claim of this file, and the reason it is worth a test: a default
/// of anything else would quietly rewrite what every existing row does.
void main() {
  NativeDatabase schemaEighteenDatabase() => NativeDatabase.memory(
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
          '"notes" TEXT NULL, "photo_path" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        )
        ..execute(
          'INSERT INTO inventory_items '
          '(client_id, household_id, name, category, quantity, unit, '
          'storage_location, expiration_date, updated_at, dirty) VALUES '
          "('item-1', 'household-1', 'Bohnen', 'food', 6, 'kg', "
          "'Keller', 1798761600, 1767225600, 0)",
        )
        ..execute('PRAGMA user_version = 18');
    },
  );

  test(
    'upgrading keeps the row and leaves it on the household setting',
    () async {
      final db = AppDatabase.forTesting(schemaEighteenDatabase());
      addTearDown(db.close);

      final item = (await db.watchInventoryItems('household-1').first).single;

      expect(item.name, 'Bohnen');
      expect(item.quantity, 6);
      // Null, not an empty string: an empty string would mean "never remind
      // me about this one", and an upgrade must not decide that for
      // anybody.
      expect(item.expiryLeadDays, isNull);
    },
  );
}
