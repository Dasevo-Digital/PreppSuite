import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Schema 16 moves nutrition from "per stored unit" to "per 100 g".
///
/// No column changes shape, so what has to hold is the arithmetic on the
/// values — and the line between the rows it can convert and the rows it
/// must leave alone. For a row counted in a measure the factor is exact
/// and known; for a row counted in tins there is no honest factor at all,
/// and inventing one would turn a gap somebody can see into a wrong number
/// nobody can.
void main() {
  NativeDatabase schemaFifteenDatabase() {
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
          '"calories" REAL NULL, "protein_grams" REAL NULL, '
          '"carbohydrate_grams" REAL NULL, "fat_grams" REAL NULL, '
          '"fiber_grams" REAL NULL, "daily_dose" REAL NULL, '
          '"notes" TEXT NULL, "photo_path" TEXT NULL, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );

        void put(
          String id,
          String category,
          double quantity,
          String unit,
          double? calories,
        ) {
          final value = calories == null ? 'NULL' : '$calories';
          raw.execute(
            'INSERT INTO inventory_items (client_id, household_id, name, '
            'category, quantity, unit, storage_location, calories, '
            'updated_at, dirty) VALUES '
            "('$id', 'household-1', '$id', '$category', $quantity, "
            "'$unit', 'Keller', $value, 1767225600, 0)",
          );
        }

        // Per gram, per kilogram, per litre: all exactly convertible.
        put('bread', 'food', 400, 'g', 2.13);
        put('rice', 'food', 2, 'kg', 3500);
        put('juice', 'food', 1.5, 'l', 450);
        // Per tin: no factor exists, so it has to be left alone.
        put('ravioli', 'food', 6, 'Dose', 900);
        // Not food, and not touched whatever the unit says.
        put('pills', 'medical', 60, 'Tablette', 5);
        // Nothing to convert.
        put('salt', 'food', 1, 'kg', null);

        raw.execute('PRAGMA user_version = 15');
      },
    );
  }

  Future<Map<String, double?>> caloriesById(AppDatabase db) async {
    final items = await db.watchInventoryItems('household-1').first;
    return {for (final item in items) item.clientId: item.calories};
  }

  test('a row counted in a measure is converted exactly', () async {
    final db = AppDatabase.forTesting(schemaFifteenDatabase());
    addTearDown(db.close);

    final calories = await caloriesById(db);

    // 2.13 kcal in a gram is 213 in a hundred of them.
    expect(calories['bread'], closeTo(213, 0.0001));
    // 3500 in a kilogram is 350 in a hundred grams.
    expect(calories['rice'], closeTo(350, 0.0001));
    // 450 in a litre is 45 in a hundred millilitres.
    expect(calories['juice'], closeTo(45, 0.0001));
  });

  test('and the household total comes out unchanged', () async {
    // The point of converting at all rather than asking the household to
    // retype everything: the numbers on the screen must not move.
    final db = AppDatabase.forTesting(schemaFifteenDatabase());
    addTearDown(db.close);

    final calories = await caloriesById(db);

    // 400 g of bread was 400 x 2.13; it is now 400/100 x 213.
    expect(400 / 100 * calories['bread']!, closeTo(852, 0.001));
    expect(2000 / 100 * calories['rice']!, closeTo(7000, 0.001));
    expect(1500 / 100 * calories['juice']!, closeTo(675, 0.001));
  });

  test('a row counted in tins is left exactly as it was', () async {
    // There is no factor for a tin. The row keeps its figure and stops
    // counting until somebody restates the unit, and the supply screen
    // names it rather than quietly dropping it.
    final db = AppDatabase.forTesting(schemaFifteenDatabase());
    addTearDown(db.close);

    expect((await caloriesById(db))['ravioli'], closeTo(900, 0.0001));
  });

  test('a medicine is not touched, whatever its unit says', () async {
    final db = AppDatabase.forTesting(schemaFifteenDatabase());
    addTearDown(db.close);

    expect((await caloriesById(db))['pills'], closeTo(5, 0.0001));
  });

  test('and a row with no figure still has none', () async {
    // Null means "not known" and has to survive as null: a zero would be
    // indistinguishable from a measured one.
    final db = AppDatabase.forTesting(schemaFifteenDatabase());
    addTearDown(db.close);

    expect((await caloriesById(db))['salt'], isNull);
  });
}
