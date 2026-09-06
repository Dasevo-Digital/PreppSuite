import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/storage_plan.dart';

void main() {
  group('the transcribed BLE tables', () {
    test('every printed energy total matches its own per-100 figure', () {
      // The one check that can catch a typo in a table of sixty numbers
      // copied out of a PDF: the source prints both the energy per 100 g
      // and the total for the amount, and the two have to agree. A digit
      // slipped in either column breaks this and nothing else would.
      //
      // Pieces are excluded — five eggs are 265 g, but that weight lives
      // in the row's remark rather than as a number, so the arithmetic
      // has nothing to work from.
      for (final diet in StorageDiet.values) {
        for (final group in storagePlanFor(diet).groups) {
          for (final food in group.foods) {
            if (food.unit == StorageUnit.piece) continue;

            final grams = food.unit == StorageUnit.liter
                ? food.amount * 1000
                : food.amount;

            void check(String label, int? kcalPer100, int? totalKcal) {
              if (kcalPer100 == null || totalKcal == null) return;
              expect(
                totalKcal,
                closeTo(kcalPer100 * grams / 100, 1),
                reason: '${group.name} / $label',
              );
            }

            check(food.name, food.kcalPer100, food.totalKcal);
            for (final variant in food.variants) {
              check(variant.name, variant.kcalPer100, variant.totalKcal);
            }
          }
        }
      }
    });

    test('a row is either priced itself or offers alternatives', () {
      // "Frischobst" and "Streichfett" carry no energy of their own; they
      // are headings for the fruits and fats underneath. Any other row
      // without a total would be a gap in the transcription.
      for (final group in storagePlanFor(StorageDiet.mixed).groups) {
        for (final food in group.foods) {
          if (food.totalKcal != null || food.variants.isNotEmpty) continue;
          expect(
            group.name,
            'Getränke',
            reason:
                '${food.name} states no energy, which only the brewed '
                'drinks are allowed to do',
          );
        }
      }
    });

    test('the two diets differ in exactly one group', () {
      final mixed = storagePlanFor(StorageDiet.mixed).groups;
      final vegetarian = storagePlanFor(StorageDiet.vegetarian).groups;

      expect(mixed, hasLength(vegetarian.length));

      final differing = [
        for (var i = 0; i < mixed.length; i++)
          if (mixed[i].name != vegetarian[i].name) mixed[i].name,
      ];
      expect(differing, ['Eier, Fleisch, Wurst und Fisch']);
    });

    test('the vegetarian table holds no meat, sausage or fish', () {
      final names = [
        for (final group in storagePlanFor(StorageDiet.vegetarian).groups)
          for (final food in group.foods) food.name.toLowerCase(),
      ];

      for (final banned in ['thunfisch', 'corned beef', 'bockwürstchen']) {
        expect(names, isNot(contains(banned)));
      }
      expect(names, contains('tofu'));
    });

    test('a whole table comes to roughly the 2,200 kcal a day it claims', () {
      // The source's own headline, and the check that no row was left
      // out: ten days at 2,200 is 22,000, and both tables land within a
      // few hundred of it (22,040 and 22,130) counting the first of each
      // row that offers a choice.
      for (final diet in StorageDiet.values) {
        expect(storagePlanFor(diet).totalKcal, closeTo(22000, 500));
      }
    });
  });

  group('scaling', () {
    test('doubling the people doubles the amount', () {
      expect(scaleAmount(3300, StorageUnit.gram, 2, 10), 6600);
    });

    test('half the days halves the amount', () {
      expect(scaleAmount(20, StorageUnit.liter, 1, 5), 10);
    });

    test('the printed table is one person and ten days unchanged', () {
      expect(scaleAmount(4000, StorageUnit.gram, 1, 10), 4000);
    });

    test('pieces round up, because half an egg is not a supply', () {
      // Five eggs for one person over three days is 1.5. Rounding down
      // would quietly under-stock every such row.
      expect(scaleAmount(5, StorageUnit.piece, 1, 3), 2);
      expect(scaleAmount(5, StorageUnit.piece, 2, 10), 10);
    });
  });
}
