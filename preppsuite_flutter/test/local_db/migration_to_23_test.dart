import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 23 lets a medicine name whose it is, ask for a reminder before
/// it runs out, and remember when it was last counted (#150).
///
/// Null everywhere after the upgrade, and each null is an answer: nobody
/// in particular, no reminder, count from `updated_at`. An upgrade that
/// switched a reminder on would start counting a reserve down that
/// nobody is taking from.
void main() {
  NativeDatabase schemaTwentyTwoDatabase() => NativeDatabase.memory(
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
          '"food_group" TEXT NULL, "package_name" TEXT NULL, '
          '"package_size" REAL NULL, "expiry_lead_days" TEXT NULL, '
          '"notes" TEXT NULL, "photo_path" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        )
        ..execute(
          'CREATE INDEX inventory_items_household '
          'ON inventory_items (household_id)',
        )
        ..execute(
          'INSERT INTO inventory_items '
          '(client_id, household_id, name, category, quantity, unit, '
          'storage_location, daily_dose, updated_at, dirty) VALUES '
          "('item-1', 'household-1', 'Ramipril 5 mg', 'medical', 60, "
          "'Tabletten', 'Bad', 1, 1767225600, 0)",
        )
        ..execute('PRAGMA user_version = 22');
    },
  );

  test('upgrading keeps the medicine and switches nothing on', () async {
    final db = AppDatabase.forTesting(schemaTwentyTwoDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;

    expect(item.name, 'Ramipril 5 mg');
    expect(item.dailyDose, 1);
    expect(item.memberId, isNull);
    expect(item.refillLeadDays, isNull);
    expect(item.stockCountedAt, isNull);
  });

  test('the three written after the upgrade read back', () async {
    final db = AppDatabase.forTesting(schemaTwentyTwoDatabase());
    addTearDown(db.close);

    final counted = DateTime.utc(2026, 10, 1);
    final item = (await db.watchInventoryItems('household-1').first).single;
    await db.upsertInventoryItem(
      item
          .toCompanion(false)
          .copyWith(
            memberId: const Value('member-1'),
            refillLeadDays: const Value(14),
            stockCountedAt: Value(counted),
          ),
    );

    final stored = (await db.watchInventoryItems('household-1').first).single;
    expect(stored.memberId, 'member-1');
    expect(stored.refillLeadDays, 14);
    expect(stored.stockCountedAt?.toUtc(), counted);
  });

  test('a replayed upgrade steps over the columns it already added', () async {
    // The version is written after the migration, outside any
    // transaction; a process that dies in between runs it again.
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(
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
              '"food_group" TEXT NULL, "package_name" TEXT NULL, '
              '"package_size" REAL NULL, "expiry_lead_days" TEXT NULL, '
              '"member_id" TEXT NULL, "refill_lead_days" INTEGER NULL, '
              '"stock_counted_at" INTEGER NULL, '
              '"notes" TEXT NULL, "photo_path" TEXT NULL, '
              '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
              '"dirty" INTEGER NOT NULL DEFAULT 1 '
              'CHECK ("dirty" IN (0, 1)), '
              'PRIMARY KEY ("client_id"))',
            )
            ..execute('PRAGMA user_version = 22');
        },
      ),
    );
    addTearDown(db.close);

    expect(await db.watchInventoryItems('household-1').first, isEmpty);
  });
}
