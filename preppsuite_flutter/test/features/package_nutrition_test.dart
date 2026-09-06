import 'package:flutter_test/flutter_test.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:preppsuite_flutter/features/inventory/application/open_food_facts_service.dart';

void main() {
  Nutriments nutriments(Map<Nutrient, double> values) {
    var result = Nutriments.empty();
    for (final entry in values.entries) {
      result = result.setValue(
        entry.key,
        PerSize.oneHundredGrams,
        entry.value,
      );
    }
    return result;
  }

  group('reading a scanned label', () {
    test('each nutrient lands in its own field', () {
      // The mapping itself is what this pins down: four numbers of the
      // same shape and unit are exactly the kind that get swapped in an
      // edit and produce a plausible-looking wrong answer.
      final nutrition = packageNutritionOf(
        nutriments({
          Nutrient.energyKCal: 250,
          Nutrient.proteins: 10,
          Nutrient.carbohydrates: 30,
          Nutrient.fat: 5,
          Nutrient.fiber: 2,
        }),
        '200 g',
      );

      expect(nutrition.kcal, 500);
      expect(nutrition.proteinGrams, closeTo(20, 0.001));
      expect(nutrition.carbohydrateGrams, closeTo(60, 0.001));
      expect(nutrition.fatGrams, closeTo(10, 0.001));
      expect(nutrition.fiberGrams, closeTo(4, 0.001));
    });

    test('a drink is measured in millilitres against the same base', () {
      final nutrition = packageNutritionOf(
        nutriments({
          Nutrient.energyKCal: 45,
          Nutrient.proteins: 0.5,
        }),
        '1,5 l',
      );

      expect(nutrition.kcal, 675);
      expect(nutrition.proteinGrams, closeTo(7.5, 0.001));
    });

    test('a label that only states energy fills only that in', () {
      // The common case by a distance: Open Food Facts is volunteer-fed,
      // and the rest of the fields have to stay null rather than zero, or
      // a shelf of unknowns would add up to a confident total.
      final nutrition = packageNutritionOf(
        nutriments({Nutrient.energyKCal: 350}),
        '500 g',
      );

      expect(nutrition.kcal, 1750);
      expect(nutrition.proteinGrams, isNull);
      expect(nutrition.carbohydrateGrams, isNull);
      expect(nutrition.fatGrams, isNull);
      expect(nutrition.fiberGrams, isNull);
      expect(nutrition.isEmpty, isFalse);
    });

    test('an unreadable package size leaves everything empty', () {
      // "6 Stück" states no weight, so there is no way from per 100 g to
      // this box, and a per-100 figure stored as a package total would be
      // wrong by whatever the box weighs.
      final nutrition = packageNutritionOf(
        nutriments({
          Nutrient.energyKCal: 250,
          Nutrient.proteins: 10,
        }),
        '6 Stück',
      );

      expect(nutrition.isEmpty, isTrue);
    });

    test('a product with no nutrition data at all is empty', () {
      // A tin of candles is in Open Food Facts too.
      expect(packageNutritionOf(null, '500 g').isEmpty, isTrue);
    });
  });
}
