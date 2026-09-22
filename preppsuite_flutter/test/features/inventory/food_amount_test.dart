import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/food_amount.dart';

/// The one rule the whole nutrition basis rests on.
///
/// A figure per 100 g only becomes a household's total if the stock can be
/// said in grams too. This is what decides whether it can.
void main() {
  group('what counts as a measure', () {
    test('mass, in the spellings a household actually writes', () {
      for (final unit in [
        'g',
        'G',
        ' g ',
        'gr',
        'Gramm',
        'gramm',
        'kg',
        'KG',
      ]) {
        expect(isMeasurableUnit(unit), isTrue, reason: unit);
      }
    });

    test('and volume', () {
      for (final unit in ['ml', 'Milliliter', 'cl', 'dl', 'l', 'L', 'Liter']) {
        expect(isMeasurableUnit(unit), isTrue, reason: unit);
      }
    });

    test('a container is not a measure, however common it is', () {
      // The whole point. These are how people count, and none of them has
      // a weight until somebody reads the tin.
      for (final unit in [
        'Dose',
        'Glas',
        'Packung',
        'Stück',
        'Stk',
        'Flasche',
        'Kiste',
        'Beutel',
        '',
      ]) {
        expect(isMeasurableUnit(unit), isFalse, reason: unit);
      }
    });
  });

  group('reducing a stock', () {
    test('mass comes out in grams', () {
      expect(measure(2, 'kg'), const FoodAmount(2000, FoodBase.mass));
      expect(measure(400, 'g'), const FoodAmount(400, FoodBase.mass));
      expect(measure(500, 'mg'), const FoodAmount(0.5, FoodBase.mass));
    });

    test('volume comes out in millilitres', () {
      expect(measure(1.5, 'l'), const FoodAmount(1500, FoodBase.volume));
      expect(measure(33, 'cl'), const FoodAmount(330, FoodBase.volume));
    });

    test('a container reduces to nothing at all', () {
      expect(measure(6, 'Dose'), isNull);
    });

    test('the two bases are never mixed', () {
      // A hundred millilitres of oil is not a hundred grams of it, and
      // Open Food Facts states per 100 g for solids and per 100 ml for
      // liquids. Nothing here converts between them, and the base is
      // carried so that a caller cannot lose track of which is meant.
      expect(measure(100, 'ml')!.base, FoodBase.volume);
      expect(measure(100, 'g')!.base, FoodBase.mass);
      expect(measure(100, 'ml'), isNot(measure(100, 'g')));
    });
  });

  group('applying a label', () {
    test('four hundred grams at 213 per 100 g is 852', () {
      expect(measure(400, 'g')!.per100(213), closeTo(852, 0.001));
    });

    test('exactly one basis of anything is the figure itself', () {
      // The case that hid a missing multiplication for so long: at
      // exactly 100 g, right and wrong look the same.
      expect(measure(100, 'g')!.per100(250), closeTo(250, 0.001));
      expect(measure(100, 'ml')!.per100(45), closeTo(45, 0.001));
    });

    test('a kilogram is ten bases, not one', () {
      expect(measure(1, 'kg')!.per100(350), closeTo(3500, 0.001));
    });

    test('and a litre likewise', () {
      expect(measure(1, 'l')!.per100(45), closeTo(450, 0.001));
    });
  });
}
