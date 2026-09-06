import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  InventoryItem item({
    required String category,
    double quantity = 1,
    String unit = 'L',
    int? calories,
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

    // The BBK publishes figures for adults only; what the app adds for
    // children and animals is its own, and the point of these numbers
    // being in one enum is that they can be checked here.
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

      // Water: four humans at 2 L, a 20 kg dog at 1.2, a 4 kg cat at 0.25.
      expect(result.waterTargetLiters, closeTo((4 * 2.0 + 1.45) * 10, 0.001));

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
  });
}
