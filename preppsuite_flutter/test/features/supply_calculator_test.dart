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
      final result = calculateSupply(items: const [], personCount: 3, days: 10);

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
        personCount: 1,
        days: 1,
      );

      expect(result.waterCurrentLiters, 6.5);
    });

    test('sums calories only for food-category items that have them set', () {
      final result = calculateSupply(
        items: [
          item(category: 'food', calories: 2000),
          item(category: 'food', calories: 1500),
          item(category: 'food'), // no calories set — not counted
          item(category: 'water', calories: 999), // wrong category
        ],
        personCount: 1,
        days: 1,
      );

      expect(result.caloriesCurrent, 3500);
    });
  });
}
