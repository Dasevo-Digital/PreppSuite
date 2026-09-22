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
    test('each nutrient lands in its own field, unchanged', () {
      // The mapping itself is what this pins down: five numbers of the
      // same shape and unit are exactly the kind that get swapped in an
      // edit and produce a plausible-looking wrong answer.
      //
      // Unchanged is the other half. This used to convert all five to
      // package totals against a free-text package size, and every
      // nutrition bug the app has had came out of that conversion. The
      // column holds per 100 now, which is what the label already says.
      final nutrition = packageNutritionOf(
        nutriments({
          Nutrient.energyKCal: 250,
          Nutrient.proteins: 10,
          Nutrient.carbohydrates: 30,
          Nutrient.fat: 5,
          Nutrient.fiber: 2,
        }),
      );

      expect(nutrition.kcal, 250);
      expect(nutrition.proteinGrams, closeTo(10, 0.001));
      expect(nutrition.carbohydrateGrams, closeTo(30, 0.001));
      expect(nutrition.fatGrams, closeTo(5, 0.001));
      expect(nutrition.fiberGrams, closeTo(2, 0.001));
    });

    test('a label that only states energy fills only that in', () {
      // The common case by a distance: Open Food Facts is volunteer-fed,
      // and the rest of the fields have to stay null rather than zero, or
      // a shelf of unknowns would add up to a confident total.
      final nutrition = packageNutritionOf(
        nutriments({Nutrient.energyKCal: 350}),
      );

      expect(nutrition.kcal, 350);
      expect(nutrition.proteinGrams, isNull);
      expect(nutrition.carbohydrateGrams, isNull);
      expect(nutrition.fatGrams, isNull);
      expect(nutrition.fiberGrams, isNull);
      expect(nutrition.isEmpty, isFalse);
    });

    test('a package size nobody could read no longer costs the label', () {
      // It used to. "6 Stück" states no weight, there was no way from
      // per 100 g to that box, and the whole label was therefore dropped
      // — energy, protein, everything. Nothing needs the package size any
      // more, so a box that states one badly keeps its figures.
      final nutrition = packageNutritionOf(
        nutriments({
          Nutrient.energyKCal: 250,
          Nutrient.proteins: 10,
        }),
      );

      expect(nutrition.kcal, 250);
      expect(nutrition.proteinGrams, closeTo(10, 0.001));
    });

    test('a product with no nutrition data at all is empty', () {
      // A tin of candles is in Open Food Facts too.
      expect(packageNutritionOf(null).isEmpty, isTrue);
    });
  });
}
