import '../../../core/number_input.dart';
import '../../../local_db/database.dart';
import 'package_nutrition.dart';

class InvalidInventoryNumbers implements Exception {
  const InvalidInventoryNumbers();
}

bool validInventoryNumbers({
  required double quantity,
  double? minQuantity,
  double? dailyDose,
  PackageNutrition nutrition = const PackageNutrition(),
}) => [
  quantity,
  minQuantity,
  dailyDose,
  nutrition.kcal,
  nutrition.proteinGrams,
  nutrition.carbohydrateGrams,
  nutrition.fatGrams,
  nutrition.fiberGrams,
].every((n) => n == null || isNonNegativeFinite(n));

bool hasInvalidInventoryNumbers(InventoryItem item) =>
    !validInventoryNumbers(
      quantity: item.quantity,
      minQuantity: item.minQuantity,
      dailyDose: item.dailyDose,
      nutrition: PackageNutrition.ofItem(item),
    ) ||
    (item.packageSize != null && !isNonNegativeFinite(item.packageSize!));

void requireInventoryNumbers({
  required double quantity,
  double? minQuantity,
  double? dailyDose,
  PackageNutrition nutrition = const PackageNutrition(),
}) {
  if (!validInventoryNumbers(
    quantity: quantity,
    minQuantity: minQuantity,
    dailyDose: dailyDose,
    nutrition: nutrition,
  )) {
    throw const InvalidInventoryNumbers();
  }
}
