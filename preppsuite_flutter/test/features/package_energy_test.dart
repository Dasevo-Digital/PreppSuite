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

    test('rounds to a whole kilocalorie', () {
      expect(
        estimatePackageKcal(kcalPer100: 333, quantityText: '175 g'),
        583, // 582.75
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
}
