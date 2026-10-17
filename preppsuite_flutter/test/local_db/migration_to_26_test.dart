import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 26 lets a device carry its own battery check (#179).
///
/// Null everywhere after the upgrade, and null is "no battery to look
/// after": an upgrade that switched a check on would call every torch in
/// the cupboard overdue the morning after the update.
void main() {
  const schemaTwentyFiveInventory =
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
      '"food_group" TEXT NULL, "package_name" TEXT NULL, '
      '"package_size" REAL NULL, "expiry_lead_days" TEXT NULL, '
      '"member_id" TEXT NULL, "refill_lead_days" INTEGER NULL, '
      '"stock_counted_at" INTEGER NULL, '
      '"notes" TEXT NULL, "photo_path" TEXT NULL, '
      '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
      '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
      'PRIMARY KEY ("client_id"))';

  NativeDatabase schemaTwentyFiveDatabase() => NativeDatabase.memory(
    setup: (raw) {
      raw
        ..execute(schemaTwentyFiveInventory)
        ..execute(
          'CREATE INDEX inventory_items_household '
          'ON inventory_items (household_id)',
        )
        ..execute(
          'INSERT INTO inventory_items '
          '(client_id, household_id, name, category, quantity, unit, '
          'storage_location, updated_at, dirty) VALUES '
          "('item-1', 'household-1', 'Powerbank 20 Ah', 'energy', 1, "
          "'Stück', 'Flur', 1767225600, 0)",
        )
        ..execute('PRAGMA user_version = 25');
    },
  );

  test('upgrading keeps the device and switches no check on', () async {
    final db = AppDatabase.forTesting(schemaTwentyFiveDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;

    expect(item.name, 'Powerbank 20 Ah');
    expect(item.chargeEveryDays, isNull);
    expect(item.chargeCheckedAt, isNull);
  });

  test('the two written after the upgrade read back', () async {
    final db = AppDatabase.forTesting(schemaTwentyFiveDatabase());
    addTearDown(db.close);

    final checked = DateTime.utc(2026, 10, 17);
    final item = (await db.watchInventoryItems('household-1').first).single;
    await db.upsertInventoryItem(
      item
          .toCompanion(false)
          .copyWith(
            chargeEveryDays: const Value(30),
            chargeCheckedAt: Value(checked),
          ),
    );

    final stored = (await db.watchInventoryItems('household-1').first).single;
    expect(stored.chargeEveryDays, 30);
    expect(stored.chargeCheckedAt?.toUtc(), checked);
  });

  test('a replayed upgrade steps over the columns it already added', () async {
    // The version is written after the migration, outside any
    // transaction; a process that dies in between runs it again.
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              schemaTwentyFiveInventory.replaceFirst(
                '"notes" TEXT NULL,',
                '"charge_every_days" INTEGER NULL, '
                    '"charge_checked_at" INTEGER NULL, "notes" TEXT NULL,',
              ),
            )
            ..execute('PRAGMA user_version = 25');
        },
      ),
    );
    addTearDown(db.close);

    expect(await db.watchInventoryItems('household-1').first, isEmpty);
  });
}
