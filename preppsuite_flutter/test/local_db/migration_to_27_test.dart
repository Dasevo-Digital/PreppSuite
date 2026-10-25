import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_photo_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 27 gives an item a second and a third photo (#211).
///
/// Null after the upgrade, which is "no further photo": the one picture
/// an item had stays where it was, the first and the one the list shows.
void main() {
  const schemaTwentySixInventory =
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
      '"charge_every_days" INTEGER NULL, "charge_checked_at" INTEGER NULL, '
      '"notes" TEXT NULL, "photo_path" TEXT NULL, '
      '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
      '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
      'PRIMARY KEY ("client_id"))';

  NativeDatabase schemaTwentySixDatabase() => NativeDatabase.memory(
    setup: (raw) {
      raw
        ..execute(schemaTwentySixInventory)
        ..execute(
          'CREATE INDEX inventory_items_household '
          'ON inventory_items (household_id)',
        )
        ..execute(
          'INSERT INTO inventory_items '
          '(client_id, household_id, name, category, quantity, unit, '
          'storage_location, photo_path, updated_at, dirty) VALUES '
          "('item-1', 'household-1', 'Linsen', 'food', 2, 'kg', 'Keller', "
          "'inventory_photos/linsen.jpg', 1767225600, 0)",
        )
        ..execute('PRAGMA user_version = 26');
    },
  );

  test('upgrading keeps the one photo first and adds none', () async {
    final db = AppDatabase.forTesting(schemaTwentySixDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;

    expect(item.photoPath, 'inventory_photos/linsen.jpg');
    expect(item.secondPhotoPath, isNull);
    expect(item.thirdPhotoPath, isNull);
    expect(item.photoPaths, ['inventory_photos/linsen.jpg']);
  });

  test('the two written after the upgrade read back', () async {
    final db = AppDatabase.forTesting(schemaTwentySixDatabase());
    addTearDown(db.close);

    final item = (await db.watchInventoryItems('household-1').first).single;
    await db.upsertInventoryItem(
      item
          .toCompanion(false)
          .copyWith(
            secondPhotoPath: const Value('inventory_photos/b.jpg'),
            thirdPhotoPath: const Value('inventory_photos/c.jpg'),
          ),
    );

    final stored = (await db.watchInventoryItems('household-1').first).single;
    expect(stored.photoPaths, [
      'inventory_photos/linsen.jpg',
      'inventory_photos/b.jpg',
      'inventory_photos/c.jpg',
    ]);
  });

  test('a replayed upgrade steps over the columns it already added', () async {
    // The version is written after the migration, outside any
    // transaction; a process that dies in between runs it again.
    final db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw
            ..execute(
              schemaTwentySixInventory.replaceFirst(
                '"photo_path" TEXT NULL,',
                '"photo_path" TEXT NULL, "second_photo_path" TEXT NULL, '
                    '"third_photo_path" TEXT NULL,',
              ),
            )
            ..execute('PRAGMA user_version = 26');
        },
      ),
    );
    addTearDown(db.close);

    expect(await db.watchInventoryItems('household-1').first, isEmpty);
  });
}
