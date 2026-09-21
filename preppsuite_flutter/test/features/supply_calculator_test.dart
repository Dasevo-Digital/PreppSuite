import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    required String category,
    double quantity = 1,
    String unit = 'L',
    double? calories,
  }) {
    return InventoryItem(
      clientId: 'c',
      householdId: 'h',
      name: 'Test',
      category: category,
      quantity: quantity,
      unit: unit,
      storageLocation: 'Keller',
      calories: calories,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
  }

  group('calculateSupply', () {
    test('target scales with person count and days using BBK figures', () {
      final result = calculateSupply(
        items: const [],
        household: const SupplyHousehold(adults: 3),
        days: 10,
      );

      expect(result.waterTargetLiters, 3 * 10 * 2.0);
      expect(result.caloriesTarget, 3 * 10 * 2200);
      expect(result.waterCurrentLiters, 0);
      expect(result.caloriesCurrent, 0);
    });

    test('sums water-category items with recognized volume units', () {
      final result = calculateSupply(
        items: [
          item(category: 'water', quantity: 6, unit: 'L'),
          item(category: 'water', quantity: 500, unit: 'ml'),
          // Not a recognized volume unit — intentionally not counted.
          item(category: 'water', quantity: 4, unit: 'Flasche'),
          // Wrong category — not counted even with a liter unit.
          item(category: 'food', quantity: 10, unit: 'L'),
        ],
        days: 1,
      );

      expect(result.waterCurrentLiters, 6.5);
    });

    // Which figure is official and which is the app's own is the whole
    // point of these living in one enum — so they are checked here.
    test('children and pets are counted, each on its own terms', () {
      final result = calculateSupply(
        items: const [],
        household: const SupplyHousehold(
          adults: 2,
          children: 2,
          dogs: 1,
          cats: 1,
        ),
        days: 10,
      );

      // Water: two adults at 2 L (BBK's 1.5 drinking + 0.5 cooking), two
      // children at 1.5 (the BLE footnote's 1 L drinking + the same 0.5),
      // a 20 kg dog at 1.2 and a 4 kg cat at 0.25.
      expect(
        result.waterTargetLiters,
        closeTo((2 * 2.0 + 2 * 1.5 + 1.45) * 10, 0.001),
      );

      // Calories: humans only. Pet food is not human food, and counting
      // it here would say the household is fed when it is not.
      expect(result.caloriesTarget, (2 * 2200 + 2 * 1400) * 10);
    });

    test('an animal adds water but never calories', () {
      const withPets = SupplyHousehold(adults: 1, dogs: 2, cats: 3);
      const without = SupplyHousehold(adults: 1);

      expect(withPets.kcalPerDay, without.kcalPerDay);
      expect(withPets.litersPerDay, greaterThan(without.litersPerDay));
      expect(withPets.hasPets, isTrue);
      expect(without.hasPets, isFalse);
    });

    test('only the kinds actually present are listed', () {
      expect(
        const SupplyHousehold(adults: 2, cats: 1).present,
        [SupplyHead.adult, SupplyHead.cat],
      );
    });

    test('sums calories only for food-category items that have them set', () {
      final result = calculateSupply(
        items: [
          item(category: 'food', calories: 2000),
          item(category: 'food', calories: 1500),
          item(category: 'food'), // no calories set — not counted
          item(category: 'water', calories: 999), // wrong category
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 3500);
    });

    test('six tins of 900 kcal are 5400, not 900', () {
      // The bug this pins, reported from the field: the calories were
      // added once per *line* and never multiplied by how many there
      // were, so a cellar was counted as a sixth of itself.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 6, unit: 'Dose', calories: 900),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 6 * 900);
    });

    test('and it was invisible because one is the same either way', () {
      // Every test above this one used the helper's default quantity of
      // one, which is also how anybody tries the app out first. A missing
      // multiplication hides perfectly behind a single tin.
      final one = calculateSupply(
        items: [item(category: 'food', quantity: 1, calories: 900)],
        days: 1,
      );

      expect(one.caloriesCurrent, 900);
    });

    test('a part of a unit counts as a part', () {
      // Half a kilogram of something at 3500 kcal the kilogram. Stored as
      // an int, so the result is rounded rather than truncated.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 0.5, unit: 'kg', calories: 3500),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 1750);
    });

    test('an emptied item stops counting on its own', () {
      // The reason the column holds a per-unit figure rather than a
      // total: nothing has to rescale it when the stock changes.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 0, unit: 'Dose', calories: 900),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 0);
    });
  });

  group('a fraction of a kilocalorie', () {
    test('four hundred grams of bread at 2.13 a gram is 852', () {
      // The case the column became a real for. As an integer this was
      // 2 kcal a gram and 800 in the cellar -- six percent light, every
      // time, on the one figure a household plans against.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 400, unit: 'g', calories: 2.13),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 852);
    });

    test('the rounding happens once, at the end, not per row', () {
      // Three rows that each end in a half. Rounded per row they come to
      // 3; rounded once they come to 2 -- and the second is the number a
      // household actually has.
      final result = calculateSupply(
        items: [
          for (var i = 0; i < 3; i++)
            item(category: 'food', quantity: 1, unit: 'Stueck', calories: 0.5),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 2);
    });

    test('and a whole number still behaves exactly as it did', () {
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 6, unit: 'Dose', calories: 900),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 5400);
    });
  });
}
