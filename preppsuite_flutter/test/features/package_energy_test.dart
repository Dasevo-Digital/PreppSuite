import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/package_energy.dart';

void main() {
  group('parsePackageSize', () {
    test('reads grams and kilograms, normalizing to grams', () {
      expect(parsePackageSize('500 g'), const PackageSize(500, 'g'));
      expect(parsePackageSize('1.5 kg'), const PackageSize(1500, 'g'));
      expect(parsePackageSize('250g'), const PackageSize(250, 'g'));
    });

    test('reads volumes, normalizing to millilitres', () {
      expect(parsePackageSize('1 l'), const PackageSize(1000, 'ml'));
      expect(parsePackageSize('33 cl'), const PackageSize(330, 'ml'));
      expect(parsePackageSize('500 ml'), const PackageSize(500, 'ml'));
    });

    test('accepts a comma as the decimal separator', () {
      // German labels write "1,5 l" — the same leniency the CSV import has.
      expect(parsePackageSize('1,5 l'), const PackageSize(1500, 'ml'));
    });

    test('is case- and whitespace-insensitive', () {
      expect(parsePackageSize('  750 ML '), const PackageSize(750, 'ml'));
      expect(parsePackageSize('2 KG'), const PackageSize(2000, 'g'));
    });

    test('refuses a multipack, which states one unit and not the total', () {
      // "6 x 33 cl" is 1980 ml in total; reading 33 cl would undercount by
      // a factor of six, so it is left to the user instead.
      expect(parsePackageSize('6 x 33 cl'), isNull);
      expect(parsePackageSize('4×125 g'), isNull);
    });

    test('refuses unknown units and unitless counts', () {
      expect(parsePackageSize('6 Stück'), isNull);
      expect(parsePackageSize('1 Packung'), isNull);
      expect(parsePackageSize('500'), isNull);
      expect(parsePackageSize('ein halbes Kilo'), isNull);
    });

    test('refuses empty, blank and missing text', () {
      expect(parsePackageSize(null), isNull);
      expect(parsePackageSize(''), isNull);
      expect(parsePackageSize('   '), isNull);
    });

    test('refuses zero and negative amounts', () {
      expect(parsePackageSize('0 g'), isNull);
      expect(parsePackageSize('-500 g'), isNull);
    });
  });

  group('estimatePackageNutrientGrams', () {
    test('turns a per-100 g figure into a package total', () {
      expect(
        estimatePackageNutrientGrams(gramsPer100: 25.5, quantityText: '200 g'),
        closeTo(51, 0.001),
      );
    });

    test('a nutrient heavier than the package itself is rejected', () {
      // The common Open Food Facts data error: a per-package figure typed
      // into the per-100 g field. Taken at face value it would put 250 g
      // of protein in a 500 g tin, and every shelf total after it would
      // be wrong by that much.
      expect(
        estimatePackageNutrientGrams(gramsPer100: 120, quantityText: '500 g'),
        isNull,
      );
    });

    test('missing either half means no number at all', () {
      expect(
        estimatePackageNutrientGrams(gramsPer100: null, quantityText: '500 g'),
        isNull,
      );
      expect(
        estimatePackageNutrientGrams(gramsPer100: 12, quantityText: '6 Stück'),
        isNull,
      );
    });

    test('a label stating zero is treated as no figure', () {
      // Zero and "not filled in" are the same thing here: Open Food Facts
      // stores an empty field as 0, and a stored 0 would read as a
      // measured one.
      expect(
        estimatePackageNutrientGrams(gramsPer100: 0, quantityText: '500 g'),
        isNull,
      );
    });
  });

  group('estimatePackageKcal', () {
    test('scales energy per 100 g up to the package', () {
      // 350 kcal/100 g in a 500 g bag = 1750 kcal.
      expect(
        estimatePackageKcal(kcalPer100: 350, quantityText: '500 g'),
        1750,
      );
    });

    test('works the same for volumes', () {
      // A litre of juice at 45 kcal/100 ml.
      expect(estimatePackageKcal(kcalPer100: 45, quantityText: '1 l'), 450);
    });

    test('keeps the fraction rather than rounding it away', () {
      // It used to round to 583, because the column was an integer. The
      // rounding belonged to the column and went with it: what is stored
      // now is what the label says, and the one place that still rounds
      // is the household's total.
      expect(
        estimatePackageKcal(kcalPer100: 333, quantityText: '175 g'),
        closeTo(582.75, 0.001),
      );
    });

    test('gives nothing when the energy value is missing', () {
      expect(
        estimatePackageKcal(kcalPer100: null, quantityText: '500 g'),
        isNull,
      );
    });

    test('gives nothing when the package size cannot be read', () {
      expect(
        estimatePackageKcal(kcalPer100: 350, quantityText: '6 Stück'),
        isNull,
      );
      expect(estimatePackageKcal(kcalPer100: 350, quantityText: null), isNull);
    });

    test('gives nothing for a zero or negative energy value', () {
      expect(estimatePackageKcal(kcalPer100: 0, quantityText: '500 g'), isNull);
      expect(
        estimatePackageKcal(kcalPer100: -10, quantityText: '500 g'),
        isNull,
      );
    });

    test('refuses an implausibly large total rather than storing it', () {
      // 900 kcal/100 g over 20 kg would be 180 000 — a misread label, not
      // a supply. The supply calculator would show it as a year of food.
      expect(
        estimatePackageKcal(kcalPer100: 900, quantityText: '20 kg'),
        isNull,
      );
    });

    test('a realistic pantry item lands in a sensible range', () {
      // Dry pasta, 500 g at 350 kcal/100 g — about four fifths of one
      // person's daily 2200 kcal target.
      final kcal = estimatePackageKcal(kcalPer100: 350, quantityText: '500 g');
      expect(kcal, isNotNull);
      expect(kcal! / 2200, closeTo(0.8, 0.05));
    });
  });

  group('kilocalories for one stored unit', () {
    // The column holds energy per unit and the calculator multiplies by
    // the quantity, so what goes in has to be per unit — and "per unit"
    // is a different sum for a tin than for a kilogram.
    test('a tin is a package: the size text decides', () {
      expect(
        kcalPerStoredUnit(
          kcalPer100: 120,
          packageSizeText: '400 g',
          storedUnit: 'Dose',
        ),
        480,
      );
    });

    test('an unknown unit is treated as a package too', () {
      for (final unit in ['Packung', 'Stk', 'Glas', 'Beutel', '']) {
        expect(
          kcalPerStoredUnit(
            kcalPer100: 120,
            packageSizeText: '400 g',
            storedUnit: unit,
          ),
          480,
          reason: unit,
        );
      }
    });

    test('kilograms come from the label, not from the package', () {
      // The decisive case. Counting in kilograms and multiplying a
      // per-package figure by the number of kilograms would be wrong by
      // whatever the package weighs.
      expect(
        kcalPerStoredUnit(
          kcalPer100: 350,
          packageSizeText: '500 g',
          storedUnit: 'kg',
        ),
        3500,
      );
      expect(
        kcalPerStoredUnit(
          kcalPer100: 45,
          packageSizeText: '1,5 l',
          storedUnit: 'l',
        ),
        450,
      );
    });

    test('grams and millilitres are answered like any other unit', () {
      // These two used to get nothing. Kilocalories per gram run to
      // single digits, the column was an integer, and rounding 3.5 to 4
      // is a fourteen percent error on every gram in the cellar — so the
      // scanner left the field empty and a household counting in grams
      // could not type a usable number into it either. The obstacle was
      // the column's type, and it is gone.
      expect(
        kcalPerStoredUnit(
          kcalPer100: 350,
          packageSizeText: '500 g',
          storedUnit: 'g',
        ),
        closeTo(3.5, 0.001),
      );
      expect(
        kcalPerStoredUnit(
          kcalPer100: 45,
          packageSizeText: '1 l',
          storedUnit: 'ml',
        ),
        closeTo(0.45, 0.001),
      );
    });

    test('the package size is beside the point for a unit of mass', () {
      // A gram of bread is a gram of bread whether the loaf is 500 g or
      // 750 g, so the same label gives the same figure either way.
      for (final size in ['500 g', '750 g', null]) {
        expect(
          kcalPerStoredUnit(
            kcalPer100: 213,
            packageSizeText: size,
            storedUnit: 'g',
          ),
          closeTo(2.13, 0.001),
          reason: 'Packungsgroesse $size',
        );
      }
    });

    test('no figure on the label means no figure stored', () {
      expect(
        kcalPerStoredUnit(
          kcalPer100: null,
          packageSizeText: '400 g',
          storedUnit: 'Dose',
        ),
        isNull,
      );
    });

    test('a package whose size nobody wrote down stays unknown', () {
      expect(
        kcalPerStoredUnit(
          kcalPer100: 120,
          packageSizeText: null,
          storedUnit: 'Dose',
        ),
        isNull,
      );
    });
  });
}
