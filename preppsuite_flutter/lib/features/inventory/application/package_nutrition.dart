import '../../../local_db/database.dart';

/// What a stored item holds, in the unit the inventory thinks in.
///
/// Every figure is a total for the item's current quantity, not a
/// per-100 g value. That is what makes adding up a shelf a sum rather
/// than a second calculation — and it is why scanning a barcode matters:
/// a label states per 100 g, nobody converts that by hand, and an empty
/// calorie column is what the supply calculator cannot work with.
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

  final int? kcal;
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
