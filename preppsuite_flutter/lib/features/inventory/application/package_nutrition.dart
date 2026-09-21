import '../../../local_db/database.dart';

/// What a stored item holds, as the inventory records it.
///
/// Two bases, not one, and the difference is in `inventory_items_table.dart`
/// where the columns are: [kcal] is the energy in **one unit** — one tin,
/// one kilogram — because the supply calculator multiplies it by the
/// quantity; the macronutrients are for **one package**, as the label
/// prints them, because nothing ever adds those up.
///
/// It used to say here that every figure was a total for the current
/// quantity. That reading could not survive contact with `consumeQuantity`,
/// which lowers the quantity and cannot rescale a number whose basis it
/// does not know — and the calculator never multiplied anyway, so six tins
/// of 900 kcal came to 900.
///
/// Either way it is why scanning a barcode matters: a label states per
/// 100 g, nobody converts that by hand, and an empty calorie column is
/// what the supply calculator cannot work with.
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
