/// Works out how many kilocalories a whole package holds.
///
/// Open Food Facts reports energy per 100 g (or per 100 ml for drinks) and
/// the package size separately, as free text like `"500 g"` or `"1,5 l"`.
/// The inventory stores one number: the total for the item as it stands.
/// Bridging the two is the job here.
///
/// Kept free of the Open Food Facts types on purpose, so the arithmetic and
/// the unit parsing can be tested without a network round-trip.
library;

/// A package size resolved to a plain number of grams or millilitres.
class PackageSize {
  const PackageSize(this.amount, this.unit);

  final double amount;

  /// Normalized to `g` or `ml` — the two bases Open Food Facts reports
  /// energy against.
  final String unit;

  @override
  String toString() => '$amount $unit';

  @override
  bool operator ==(Object other) =>
      other is PackageSize && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);
}

/// Multipliers onto the base unit. Litres and kilograms are the common
/// case on a label; centilitres show up on drinks.
const _unitFactors = <String, (double factor, String base)>{
  'g': (1, 'g'),
  'gr': (1, 'g'),
  'gramm': (1, 'g'),
  'kg': (1000, 'g'),
  'ml': (1, 'ml'),
  'cl': (10, 'ml'),
  'dl': (100, 'ml'),
  'l': (1000, 'ml'),
  'ltr': (1000, 'ml'),
  'liter': (1000, 'ml'),
};

/// Reads a package size out of Open Food Facts' free-text quantity field.
///
/// Returns `null` whenever the text cannot be read with confidence — an
/// unknown unit, a piece count like `"6 x 33 cl"`, or no number at all.
/// Guessing would be worse than leaving the field empty: a wrong calorie
/// total quietly corrupts the supply calculator, while an empty one is
/// visibly missing and gets filled in by hand.
PackageSize? parsePackageSize(String? text) {
  if (text == null) return null;

  final normalized = text.toLowerCase().replaceAll(',', '.').trim();
  if (normalized.isEmpty) return null;

  // A multipack ("6 x 33 cl") states one unit's size, not the total, and
  // reading it as the total would undercount by the pack size.
  if (RegExp(r'\d\s*[x×]\s*\d').hasMatch(normalized)) return null;

  final match = RegExp(
    r'^([0-9]+(?:\.[0-9]+)?)\s*([a-zäöü]+)\.?$',
  ).firstMatch(normalized);
  if (match == null) return null;

  final amount = double.tryParse(match.group(1)!);
  if (amount == null || amount <= 0) return null;

  final entry = _unitFactors[match.group(2)!];
  if (entry == null) return null;

  return PackageSize(amount * entry.$1, entry.$2);
}

/// Total kilocalories for a package, or `null` if either input is missing
/// or unreadable.
///
/// [kcalPer100] is energy per 100 g / 100 ml, as Open Food Facts reports
/// it. The result is rounded to a whole number — the inventory stores an
/// int, and a tenth of a kilocalorie is noise next to a daily target of
/// 2200.
int? estimatePackageKcal({
  required double? kcalPer100,
  required String? quantityText,
}) {
  // A single package above this is almost certainly a misread label rather
  // than real food — better no number than a nonsensical one.
  final total = estimatePackageTotal(
    per100: kcalPer100,
    quantityText: quantityText,
    implausibleAbove: 100000,
  );
  return total?.round();
}

/// Total grams of a nutrient in a package — protein, fat, carbohydrate,
/// fibre — or `null` when the label does not say.
///
/// The plausibility check here is the package itself: a nutrient cannot
/// weigh more than the food it is in. That catches the common Open Food
/// Facts data error of a per-100 g figure entered as a per-package one,
/// which would otherwise put 500 g of protein in a tin of tuna.
double? estimatePackageNutrientGrams({
  required double? gramsPer100,
  required String? quantityText,
}) {
  final size = parsePackageSize(quantityText);
  if (size == null) return null;

  return estimatePackageTotal(
    per100: gramsPer100,
    quantityText: quantityText,
    implausibleAbove: size.amount,
  );
}

/// The arithmetic both of the above share: a per-100 figure times the
/// package size, rejected when it is missing, non-positive, or larger
/// than [implausibleAbove].
double? estimatePackageTotal({
  required double? per100,
  required String? quantityText,
  required double implausibleAbove,
}) {
  if (per100 == null || per100 <= 0) return null;

  final size = parsePackageSize(quantityText);
  if (size == null) return null;

  final total = per100 * size.amount / 100;
  if (total <= 0 || !total.isFinite) return null;
  if (total > implausibleAbove) return null;

  return total;
}
