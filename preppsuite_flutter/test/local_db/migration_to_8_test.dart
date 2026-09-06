import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 8 drops `server_id` from the four shared tables.
///
/// SQLite cannot drop a column in place, so drift recreates each table and
/// copies what remains. That is the kind of migration that either works or
/// destroys an install's data, and it only ever runs on a database this
/// test suite would otherwise never see — so the old schema is written out
/// by hand here and upgraded for real.
void main() {
  /// The tables as schema 7 left them: everything today has, plus the
  /// server ids, and `user_version` set so drift runs `onUpgrade`.
  NativeDatabase schemaSevenDatabase() {
    return NativeDatabase.memory(
      setup: (raw) {
        raw.execute(
          'CREATE TABLE "inventory_items" ('
          '"client_id" TEXT NOT NULL, "server_id" TEXT NULL, '
          '"household_id" TEXT NOT NULL, "name" TEXT NOT NULL, '
          '"category" TEXT NOT NULL, "barcode" TEXT NULL, '
          '"off_product_id" TEXT NULL, "quantity" REAL NOT NULL, '
          '"unit" TEXT NOT NULL, "storage_location" TEXT NOT NULL, '
          '"expiration_date" INTEGER NULL, "min_quantity" REAL NULL, '
          '"calories" INTEGER NULL, "notes" TEXT NULL, '
          '"photo_path" TEXT NULL, "updated_at" INTEGER NOT NULL, '
          '"deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'CREATE TABLE "checklist_templates" ('
          '"client_id" TEXT NOT NULL, "server_id" TEXT NULL, '
          '"household_id" TEXT NULL, "title" TEXT NOT NULL, '
          '"category" TEXT NOT NULL, '
          '"is_built_in" INTEGER NOT NULL DEFAULT 0 '
          'CHECK ("is_built_in" IN (0, 1)), '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'CREATE TABLE "checklist_items" ('
          '"client_id" TEXT NOT NULL, "server_id" TEXT NULL, '
          '"household_id" TEXT NULL, '
          '"template_client_id" TEXT NOT NULL, "title" TEXT NOT NULL, '
          '"target_quantity" REAL NULL, '
          '"is_checked" INTEGER NOT NULL DEFAULT 0 '
          'CHECK ("is_checked" IN (0, 1)), '
          '"linked_inventory_item_id" TEXT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'CREATE TABLE "budget_entries" ('
          '"client_id" TEXT NOT NULL, "server_id" TEXT NULL, '
          '"household_id" TEXT NOT NULL, "label" TEXT NOT NULL, '
          '"amount_cents" INTEGER NOT NULL, "currency" TEXT NOT NULL, '
          '"category" TEXT NOT NULL, "purchase_date" INTEGER NULL, '
          '"linked_inventory_item_id" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'CREATE TABLE "warnings" ('
          '"source" TEXT NOT NULL, "external_id" TEXT NOT NULL, '
          '"country_code" TEXT NOT NULL, "region_key" TEXT NULL, '
          '"severity" TEXT NOT NULL, "event_type" TEXT NOT NULL, '
          '"headline" TEXT NOT NULL, "description" TEXT NULL, '
          '"effective" INTEGER NOT NULL, "expires" INTEGER NULL, '
          '"sent" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, '
          '"notified" INTEGER NOT NULL DEFAULT 0 '
          'CHECK ("notified" IN (0, 1)), '
          'PRIMARY KEY ("source", "external_id"))',
        );
        raw.execute(
          'CREATE TABLE "sync_state" ("entity" TEXT NOT NULL, '
          '"last_pulled_at" INTEGER NOT NULL, PRIMARY KEY ("entity"))',
        );

        raw.execute(
          'INSERT INTO inventory_items (client_id, server_id, household_id, '
          'name, category, quantity, unit, storage_location, photo_path, '
          'updated_at, dirty) VALUES '
          "('water', 'srv-1', 'household-1', 'Trinkwasser', 'water', 6, "
          "'Flasche', 'Keller', 'photos/water.jpg', 1767225600, 0)",
        );
        raw.execute(
          'INSERT INTO budget_entries (client_id, server_id, household_id, '
          'label, amount_cents, currency, category, updated_at, dirty) '
          "VALUES ('bud-1', 'srv-2', 'household-1', 'Konserven', 1250, "
          "'EUR', 'food', 1767225600, 0)",
        );
        raw.execute(
          'INSERT INTO checklist_templates (client_id, server_id, '
          'household_id, title, category, updated_at, dirty) VALUES '
          "('tpl-1', 'srv-3', 'household-1', 'Eigene Liste', 'custom', "
          '1767225600, 0)',
        );
        raw.execute(
          'INSERT INTO checklist_items (client_id, server_id, household_id, '
          'template_client_id, title, updated_at, dirty) VALUES '
          "('itm-1', 'srv-4', 'household-1', 'tpl-1', 'Punkt', 1767225600, 0)",
        );

        raw.execute('PRAGMA user_version = 7');
      },
    );
  }

  test('upgrading from 7 drops server_id and keeps every row', () async {
    final db = AppDatabase.forTesting(schemaSevenDatabase());
    addTearDown(db.close);

    // Any query triggers the migration.
    final items = await db.inventoryItemsForSync('household-1');

    expect(items.single.clientId, 'water');
    expect(items.single.quantity, 6);
    expect(
      items.single.photoPath,
      'photos/water.jpg',
      reason: 'a column after server_id must not have shifted',
    );
    expect(
      items.single.proteinGrams,
      isNull,
      reason:
          'the rebuild copies the table as defined today, so a column '
          'added after schema 8 has to arrive empty rather than being '
          'read out of a version-7 table that never had it',
    );
    expect(
      (await db.budgetEntriesForSync('household-1')).single.label,
      'Konserven',
    );
    expect(
      (await db.checklistTemplatesForSync('household-1')).single.title,
      'Eigene Liste',
    );
    expect(
      (await db.checklistItemsForSync('household-1')).single.title,
      'Punkt',
    );

    for (final table in [
      'inventory_items',
      'checklist_templates',
      'checklist_items',
      'budget_entries',
    ]) {
      final columns = await db
          .customSelect('PRAGMA table_info($table)')
          .get()
          .then((rows) => rows.map((r) => r.data['name']).toList());
      expect(columns, isNot(contains('server_id')), reason: table);
    }
  });
}
