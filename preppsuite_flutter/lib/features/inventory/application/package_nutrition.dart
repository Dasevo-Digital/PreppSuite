import '../../../local_db/database.dart';
import 'food_amount.dart';

/// What a label says, per 100 g — or per 100 ml on a drink.
///
/// One basis for all five figures, which it did not use to be: energy was
/// per stored unit and the macronutrients per package, and a reader had to
/// know which was which. Both were conversions done on the way in, from a
/// package size read out of free text, and every nutrition bug this app
/// has had came from one of them.
///
/// Per 100 is what the label already prints, so nothing converts on the
/// way in. The multiplication happens once, in `supply_calculator.dart`,
/// against a quantity that `food_amount.dart` has reduced to grams or
/// millilitres.
///
/// Any field may be null, and usually several are. Open Food Facts is
/// filled in by volunteers, so a product often carries energy and nothing
/// else, and a tin of candles carries nothing at all. A null means "not
/// known", never zero.
class PackageNutrition {
  const PackageNutrition({
    this.kcal,
    this.proteinGrams,
    this.carbohydrateGrams,
    this.fatGrams,
    this.fiberGrams,
  });

  /// The nutrition already stored on an item.
  factory PackageNutrition.ofItem(InventoryItem item) => PackageNutrition(
    kcal: item.calories,
    proteinGrams: item.proteinGrams,
    carbohydrateGrams: item.carbohydrateGrams,
    fatGrams: item.fatGrams,
    fiberGrams: item.fiberGrams,
  );

  final double? kcal;
  final double? proteinGrams;
  final double? carbohydrateGrams;
  final double? fatGrams;
  final double? fiberGrams;

  bool get isEmpty =>
      kcal == null &&
      proteinGrams == null &&
      carbohydrateGrams == null &&
      fatGrams == null &&
      fiberGrams == null;

  bool get isNotEmpty => !isEmpty;
}

/// The most energy 100 g of food can hold: pure fat, at 9 kcal a gram.
///
/// It holds per 100 ml too, because fat is lighter than water. A figure
/// above it is not a label but, nearly always, the whole package typed
/// into the per-100 field on Open Food Facts (#402) -- and the supply
/// calculator multiplies it by the stock, so 500 g at 1250 "per 100 g"
/// count five times what they hold.
const maxKcalPer100 = 900.0;

/// The most a nutrient, or all four together, can weigh in 100 of the
/// basis.
///
/// In 100 g that is the 100 g themselves. 100 ml weigh more than 100 g
/// where the food is denser than water, and the densest a household
/// keeps by the litre, honey and syrup, are around 1.4 g a millilitre; so
/// a drink is allowed 150 g. Mass and volume are not mixed anywhere else:
/// this is a ceiling, not a conversion.
double maxGramsPer100(FoodBase base) => switch (base) {
  FoodBase.mass => 100,
  FoodBase.volume => 150,
};

/// Whether [kcal] per 100 can be a label's figure.
bool plausibleKcalPer100(double kcal) => kcal <= maxKcalPer100;

/// Whether [grams] of one nutrient fit into 100 of [base].
bool plausibleGramsPer100(double grams, FoodBase base) =>
    grams <= maxGramsPer100(base);

/// Whether protein, carbohydrate, fat and fibre together fit into 100 of
/// [base]. Null figures are not known and count for nothing.
bool plausibleGramsSumPer100(Iterable<double?> grams, FoodBase base) =>
    grams.nonNulls.fold<double>(0, (sum, g) => sum + g) <= maxGramsPer100(base);

/// A label with every figure taken out that 100 of [base] cannot hold,
/// and whether anything was (#402).
///
/// For a scan: what Open Food Facts holds is volunteers' typing, and a
/// figure that cannot be is left out rather than filled in, so that the
/// field stays empty and somebody reads the packet. Where the four
/// nutrients only fail together, there is no telling which of them is
/// wrong, and all four are left out.
({PackageNutrition nutrition, bool leftOut}) plausibleNutrition(
  PackageNutrition label, {
  FoodBase base = FoodBase.mass,
}) {
  double? grams(double? value) =>
      value == null || plausibleGramsPer100(value, base) ? value : null;

  final kcal = switch (label.kcal) {
    final value? when plausibleKcalPer100(value) => value,
    _ => null,
  };
  var nutrients = [
    grams(label.proteinGrams),
    grams(label.carbohydrateGrams),
    grams(label.fatGrams),
    grams(label.fiberGrams),
  ];
  if (!plausibleGramsSumPer100(nutrients, base)) {
    nutrients = [null, null, null, null];
  }
  final nutrition = PackageNutrition(
    kcal: kcal,
    proteinGrams: nutrients[0],
    carbohydrateGrams: nutrients[1],
    fatGrams: nutrients[2],
    fiberGrams: nutrients[3],
  );
  final leftOut =
      nutrition.kcal != label.kcal ||
      nutrition.proteinGrams != label.proteinGrams ||
      nutrition.carbohydrateGrams != label.carbohydrateGrams ||
      nutrition.fatGrams != label.fatGrams ||
      nutrition.fiberGrams != label.fiberGrams;
  return (nutrition: nutrition, leftOut: leftOut);
}
