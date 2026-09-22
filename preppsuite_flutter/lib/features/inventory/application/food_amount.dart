/// How much food a row actually holds, in the unit a label speaks.
///
/// Nutrition is printed per 100 g, or per 100 ml on a drink. That is what
/// the app stores now, and it is the reason this file exists: a figure per
/// 100 g only becomes a household's total if the amount on the shelf can
/// be expressed in grams too. "6 Dosen" cannot, without knowing what a tin
/// of that particular thing weighs — which is on the tin and not in this
/// app.
///
/// So for food and water the unit has to be one of mass or volume, and
/// everything else in the inventory keeps its free text. A medicine is
/// counted in tablets and its daily dose with it; a tool is counted in
/// pieces. Neither has a nutrition label, and forcing grams on them would
/// break the one calculation they do have.
///
/// **Mass and volume are kept apart.** A hundred millilitres of oil is not
/// a hundred grams of it, and Open Food Facts states per 100 g for solids
/// and per 100 ml for liquids. The unit decides which basis is meant, and
/// nothing here converts between the two.
library;

/// The base a measurable unit reduces to.
enum FoodBase {
  /// Grams, and everything that scales to them.
  mass,

  /// Millilitres.
  volume,
}

/// An amount reduced to grams or millilitres.
class FoodAmount {
  const FoodAmount(this.amount, this.base);

  /// In grams for [FoodBase.mass], millilitres for [FoodBase.volume].
  final double amount;

  final FoodBase base;

  /// What a per-100 figure comes to over this amount.
  double per100(double value) => value * amount / 100;

  @override
  bool operator ==(Object other) =>
      other is FoodAmount && other.amount == amount && other.base == base;

  @override
  int get hashCode => Object.hash(amount, base);

  @override
  String toString() => '$amount ${base == FoodBase.mass ? "g" : "ml"}';
}

/// What one of each spelling comes to in the base unit.
///
/// Spellings and not a picker, because the field has always been free text
/// and a household that wrote "Gramm" or "Liter" years ago should not have
/// its rows rejected over a capital letter. What is *not* here is the
/// point: "Dose", "Glas", "Packung", "Stück" have no size until somebody
/// reads the label.
const _units = <String, (double factor, FoodBase base)>{
  'mg': (0.001, FoodBase.mass),
  'g': (1, FoodBase.mass),
  'gr': (1, FoodBase.mass),
  'gramm': (1, FoodBase.mass),
  'gramme': (1, FoodBase.mass),
  'gram': (1, FoodBase.mass),
  'grams': (1, FoodBase.mass),
  'kg': (1000, FoodBase.mass),
  'kilo': (1000, FoodBase.mass),
  'kilogramm': (1000, FoodBase.mass),
  'kilogram': (1000, FoodBase.mass),
  'ml': (1, FoodBase.volume),
  'milliliter': (1, FoodBase.volume),
  'millilitre': (1, FoodBase.volume),
  'cl': (10, FoodBase.volume),
  'dl': (100, FoodBase.volume),
  'l': (1000, FoodBase.volume),
  'ltr': (1000, FoodBase.volume),
  'liter': (1000, FoodBase.volume),
  'litre': (1000, FoodBase.volume),
  'liters': (1000, FoodBase.volume),
  'litres': (1000, FoodBase.volume),
};

/// The unit's base and factor, or null where it names no measure.
(double factor, FoodBase base)? _read(String unit) {
  final normalized = unit.trim().toLowerCase().replaceAll('.', '');
  return _units[normalized];
}

/// Whether [unit] is something a per-100 figure can be applied to.
///
/// The rule the food and water categories are held to. Everything else is
/// left alone — see the library comment.
bool isMeasurableUnit(String unit) => _read(unit) != null;

/// [quantity] of [unit] in grams or millilitres, or null where the unit
/// names no measure.
FoodAmount? measure(double quantity, String unit) {
  final read = _read(unit);
  if (read == null) return null;
  return FoodAmount(quantity * read.$1, read.$2);
}

/// One of [unit], for showing what a single one comes to.
FoodAmount? oneOf(String unit) => measure(1, unit);

/// The units offered in the form, in the order they are offered.
///
/// A suggestion list and not a closed set: [isMeasurableUnit] is what
/// decides, and it takes more spellings than these. These are the ones
/// worth one tap.
const suggestedFoodUnits = ['g', 'kg', 'ml', 'l'];
