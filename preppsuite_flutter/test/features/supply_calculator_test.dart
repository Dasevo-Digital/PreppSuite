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
      // 100 g each at the figures below: 2000 + 1500.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 100, unit: 'g', calories: 2000),
          item(category: 'food', quantity: 100, unit: 'g', calories: 1500),
          // No calories set — not counted.
          item(category: 'food', quantity: 100, unit: 'g'),
          // Wrong category.
          item(category: 'water', quantity: 100, unit: 'ml', calories: 999),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 3500);
    });

    test('the label is applied to the stock, not to the line', () {
      // The bug this pins, reported from the field: the calories were
      // added once per *line* and never multiplied by how much there was,
      // so a cellar was counted as a fraction of itself. Two kilograms at
      // 450 kcal per 100 g is 9,000.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 2, unit: 'kg', calories: 450),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 9000);
    });

    test('and it was invisible because 100 g of anything is the figure', () {
      // Every test above this one used the helper's default quantity of
      // one, which is also how anybody tries the app out first. A missing
      // multiplication hides perfectly behind a single unit — and behind
      // exactly 100 g it hides even from this basis.
      final one = calculateSupply(
        items: [
          item(category: 'food', quantity: 100, unit: 'g', calories: 900),
        ],
        days: 1,
      );

      expect(one.caloriesCurrent, 900);
    });

    test('a part of a unit counts as a part', () {
      // Half a kilogram at 350 kcal per 100 g. Stored as an int, so the
      // result is rounded rather than truncated.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 0.5, unit: 'kg', calories: 350),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 1750);
    });

    test('a drink is measured against the same figure in millilitres', () {
      // 1.5 litres at 45 kcal per 100 ml. Mass and volume are kept apart
      // on purpose: a hundred millilitres of oil is not a hundred grams.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 1.5, unit: 'l', calories: 45),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 675);
    });

    group('a unit no label can be applied to', () {
      test('is not counted, because a tin has no weight', () {
        // "6 Dosen" states nothing a per-100 g figure can be applied to.
        // Guessing what a tin of this particular thing weighs is the one
        // thing that would turn a visible gap into an invisible wrong
        // number.
        final result = calculateSupply(
          items: [
            item(category: 'food', quantity: 6, unit: 'Dose', calories: 250),
          ],
          days: 1,
        );

        expect(result.caloriesCurrent, 0);
      });

      test('and is named rather than silently skipped', () {
        // The rule the whole file follows: a reach that quietly omits
        // half the cupboard is worse than one that says which half.
        final items = [
          item(category: 'food', quantity: 6, unit: 'Dose', calories: 250),
          item(category: 'food', quantity: 2, unit: 'kg', calories: 350),
          // Not food: a medicine is counted in tablets and its daily dose
          // with it, and neither ever wanted grams.
          item(category: 'medical', quantity: 60, unit: 'Tablette'),
        ];

        expect(
          foodWithoutMeasure(items).map((item) => item.unit),
          ['Dose'],
        );
      });

      test('an empty row is nobody\'s gap', () {
        expect(
          foodWithoutMeasure([
            item(category: 'food', quantity: 0, unit: 'Dose', calories: 250),
          ]),
          isEmpty,
        );
      });
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
    test('four hundred grams of bread at 213 per 100 g is 852', () {
      // Whole numbers on the label, a fraction in the arithmetic: 400 g
      // is four fifths of the basis. That is the ordinary case now, which
      // is why the column has to hold a real even though every label
      // prints an integer.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 400, unit: 'g', calories: 213),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 852);
    });

    test('the rounding happens once, at the end, not per row', () {
      // Three rows that each come to half a kilocalorie. Rounded per row
      // they make 3; rounded once they make 2 — and the second is what
      // the household actually has.
      final result = calculateSupply(
        items: [
          for (var i = 0; i < 3; i++)
            item(category: 'food', quantity: 1, unit: 'g', calories: 50),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 2);
    });

    test('and a label of whole numbers still behaves plainly', () {
      // Six kilograms at 90 kcal per 100 g: 5,400, no fraction anywhere.
      final result = calculateSupply(
        items: [
          item(category: 'food', quantity: 6, unit: 'kg', calories: 90),
        ],
        days: 1,
      );

      expect(result.caloriesCurrent, 5400);
    });
  });
}
