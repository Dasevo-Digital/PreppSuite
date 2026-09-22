import '../../../local_db/database.dart';

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
