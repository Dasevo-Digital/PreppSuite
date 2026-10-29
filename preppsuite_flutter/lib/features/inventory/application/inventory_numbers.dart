import '../../../core/number_input.dart';
import '../../../local_db/database.dart';
import 'package_nutrition.dart';

class InvalidInventoryNumbers implements Exception {
  const InvalidInventoryNumbers();
}

// Beyond this even a finite quotient is not a representable calendar
// horizon. This still permits over 27,000 years of daily medication.
const maxMedicationSpanDays = 10000000;

/// A domain failure is recoverable in the screen that owns the inputs.
/// Do not catch unrelated programming or storage errors as invalid stock.
T? inventoryNumbersOrNull<T>(T Function() calculate) {
  try {
    return calculate();
  } on InvalidInventoryNumbers {
    return null;
  }
}

bool validInventoryNumbers({
  required double quantity,
  double? minQuantity,
  double? dailyDose,
  double? packageSize,
  PackageNutrition nutrition = const PackageNutrition(),
}) {
  final nutrients = [
    nutrition.kcal,
    nutrition.proteinGrams,
    nutrition.carbohydrateGrams,
    nutrition.fatGrams,
    nutrition.fiberGrams,
  ];
  if (![
    quantity,
    minQuantity,
    dailyDose,
    packageSize,
    ...nutrients,
  ].every((n) => n == null || isNonNegativeFinite(n))) {
    return false;
  }
  // Food can be measured in kilograms; each value is per 100 grams.
  if (!nutrients.every((n) => n == null || (quantity * n * 10).isFinite)) {
    return false;
  }
  if (dailyDose != null && dailyDose > 0) {
    final days = quantity / dailyDose;
    if (!days.isFinite || days > maxMedicationSpanDays) return false;
  }
  if (packageSize != null && packageSize > 0) {
    if (!(quantity / packageSize * 10).isFinite ||
        (minQuantity != null && !(minQuantity / packageSize * 10).isFinite)) {
      return false;
    }
  }
  return true;
}

bool hasInvalidInventoryNumbers(InventoryItem item) => !validInventoryNumbers(
  quantity: item.quantity,
  minQuantity: item.minQuantity,
  dailyDose: item.dailyDose,
  packageSize: item.packageSize,
  nutrition: PackageNutrition.ofItem(item),
);

void requireInventoryNumbers({
  required double quantity,
  double? minQuantity,
  double? dailyDose,
  double? packageSize,
  PackageNutrition nutrition = const PackageNutrition(),
}) {
  if (!validInventoryNumbers(
    quantity: quantity,
    minQuantity: minQuantity,
    dailyDose: dailyDose,
    packageSize: packageSize,
    nutrition: nutrition,
  )) {
    throw const InvalidInventoryNumbers();
  }
}
