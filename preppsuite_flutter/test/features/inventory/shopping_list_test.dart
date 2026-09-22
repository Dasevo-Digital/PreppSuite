import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/shopping_list.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// What the shopping list says, and what it refuses to say.
void main() {
  final now = DateTime.utc(2026, 9, 6);

  InventoryItem item({
    required String clientId,
    String name = 'Vorrat',
    String category = 'food',
    // A hundred grams by default, which is one basis of the nutrition
    // figures — so a row's calories and its contribution are the same
    // number and the cases below read as they always did.
    double quantity = 100,
    String unit = 'g',
    double? minQuantity,
    double? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    minQuantity: minQuantity,
    calories: calories,
    updatedAt: now,
    dirty: false,
  );

  group('the household target', () {
    test('is the gap to it, never a surplus dressed as one', () {
      final list = buildShoppingList(
        items: [
          item(clientId: 'w', category: 'water', quantity: 100, unit: 'l'),
          item(clientId: 'f', calories: 999999),
        ],
        days: 10,
        household: const SupplyHousehold(adults: 1),
      );

      expect(list.waterShortfallLiters, 0);
      expect(list.calorieShortfall, 0);
      expect(list.targetMet, isTrue);
    });

    test('counts what is missing for one adult over ten days', () {
      // 2 l and 2200 kcal a day, so 20 l and 22000 kcal.
      final list = buildShoppingList(
        items: [
          item(clientId: 'w', category: 'water', quantity: 8, unit: 'l'),
          item(clientId: 'f', calories: 2000),
        ],
        days: 10,
        household: const SupplyHousehold(adults: 1),
      );

      expect(list.waterShortfallLiters, closeTo(12, 0.001));
      expect(list.calorieShortfall, 20000);
      expect(list.targetMet, isFalse);
    });
  });

  group('days covered', () {
    test('is the shorter of the two runways, not the friendlier one', () {
      // Water for 10 days, food for 2. The household lasts two days.
      final list = buildShoppingList(
        items: [
          item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
          item(clientId: 'f', calories: 4400),
        ],
        days: 10,
        household: const SupplyHousehold(adults: 1),
      );

      expect(list.daysCovered, 2);
    });

    test('rounds down, because a part-covered day is not a covered day', () {
      final list = buildShoppingList(
        items: [
          item(clientId: 'w', category: 'water', quantity: 5.9, unit: 'l'),
          item(clientId: 'f', calories: 999999),
        ],
        days: 10,
        household: const SupplyHousehold(adults: 1),
      );

      expect(list.daysCovered, 2);
    });

    test('is unknown for a household that consumes nothing', () {
      // Dividing by zero would report an endless supply, and an empty
      // flat is not well stocked.
      final list = buildShoppingList(
        items: const [],
        days: 10,
        household: const SupplyHousehold(adults: 0),
      );

      expect(list.daysCovered, isNull);
    });
  });

  group('the lines to buy', () {
    test('an item without a minimum is unanswered, not short', () {
      final list = buildShoppingList(
        items: [item(clientId: 'a', quantity: 0)],
        days: 10,
      );

      expect(list.entries, isEmpty);
    });

    test('an item at or above its minimum is not listed', () {
      final list = buildShoppingList(
        items: [item(clientId: 'a', quantity: 5, minQuantity: 5)],
        days: 10,
      );

      expect(list.entries, isEmpty);
    });

    test('the shortfall is the missing amount, in the item unit', () {
      final list = buildShoppingList(
        items: [
          item(clientId: 'a', quantity: 1.5, minQuantity: 4, unit: 'kg'),
        ],
        days: 10,
      );

      expect(list.entries.single.shortfall, closeTo(2.5, 0.001));
      expect(list.entries.single.item.unit, 'kg');
    });

    test('the emptiest comes first, not the largest number', () {
      // Two missing of three is a more pressing errand than ten of fifty,
      // and the absolute figure gets that backwards.
      final list = buildShoppingList(
        items: [
          item(clientId: 'big', name: 'Reis', quantity: 40, minQuantity: 50),
          item(clientId: 'small', name: 'Salz', quantity: 1, minQuantity: 3),
        ],
        days: 10,
      );

      expect(
        list.entries.map((e) => e.item.clientId),
        ['small', 'big'],
      );
    });

    test('an equal shortfall sorts by name, so the list does not shuffle', () {
      final list = buildShoppingList(
        items: [
          item(clientId: 'z', name: 'Zwieback', quantity: 1, minQuantity: 2),
          item(clientId: 'a', name: 'Apfelmus', quantity: 1, minQuantity: 2),
        ],
        days: 10,
      );

      expect(list.entries.map((e) => e.item.clientId), ['a', 'z']);
    });
  });

  test('a household that is stocked and complete has nothing to say', () {
    final list = buildShoppingList(
      items: [
        item(clientId: 'w', category: 'water', quantity: 100, unit: 'l'),
        item(clientId: 'f', calories: 999999, quantity: 9, minQuantity: 5),
      ],
      days: 10,
      household: const SupplyHousehold(adults: 1),
    );

    expect(list.isEmpty, isTrue);
  });

  // Two numbers on one screen that answer the same question two ways:
  // "noch X Liter zu kaufen" and "reicht Y Tage". A change to either
  // half that forgets the other lets them disagree, and a household
  // reading a green target beside a reach shorter than the plan has no
  // way to tell which one lied. So the relation itself is the test,
  // over households the cases above do not happen to cover.
  group('the target and the reach are one statement, not two', () {
    test('a met target is exactly a reach that carries the plan', () {
      final random = Random(20260920);
      var checked = 0;

      for (var run = 0; run < 2000; run++) {
        final household = SupplyHousehold(
          adults: random.nextInt(4),
          children: random.nextInt(3),
          dogs: random.nextInt(2),
          cats: random.nextInt(2),
        );
        // Dogs and cats drink but eat nothing human, so a household of
        // pets alone has a water demand and no calorie one. That is a
        // real case and it is covered above; here it would only make
        // the relation vacuous on one side.
        if (household.litersPerDay <= 0 || household.kcalPerDay <= 0) continue;

        final days = 1 + random.nextInt(30);
        final list = buildShoppingList(
          items: [
            item(
              clientId: 'w',
              category: 'water',
              quantity: random.nextInt(200).toDouble(),
              unit: 'l',
            ),
            item(
              clientId: 'f',
              quantity: random.nextInt(3000).toDouble(),
              unit: 'g',
              calories: random.nextInt(600).toDouble(),
            ),
          ],
          days: days,
          household: household,
        );

        checked++;
        final covered = list.daysCovered;
        expect(
          list.targetMet,
          covered != null && covered >= days,
          reason:
              'Haushalt ${household.adults}/${household.children}/'
              '${household.dogs}/${household.cats}, $days Tage: '
              'reicht $covered, fehlen ${list.waterShortfallLiters} l '
              'und ${list.calorieShortfall} kcal',
        );
      }

      expect(checked, greaterThan(1000));
    });
  });
}
