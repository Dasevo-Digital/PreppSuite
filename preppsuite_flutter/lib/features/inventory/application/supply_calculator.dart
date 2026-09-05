import '../../../model/categories.dart';

import '../../../local_db/database.dart';
import 'inventory_category_l10n.dart';

/// Official BBK ("Bundesamt für Bevölkerungsschutz und Katastrophenhilfe")
/// recommendation: 2 liters of drinking water per person per day.
const litersPerPersonPerDay = 2.0;

/// Official BBK recommendation: ~2200 kcal per person per day.
const kcalPerPersonPerDay = 2200;

/// Target vs. current stock for the "Vorräte für X Tage" calculator.
/// Deliberately covers only drinking water and calories — the reference
/// this is modeled on also tracks "Brauchwasser" (service/hygiene water),
/// but there's no official BBK figure for that and [InventoryItemCategory]
/// doesn't distinguish drinking from service water, so faking a number
/// there would be dishonest. See `supply_calculator.dart`'s test suite for
/// the exact rounding/unit-normalization rules.
class SupplyCalculatorResult {
  const SupplyCalculatorResult({
    required this.waterTargetLiters,
    required this.waterCurrentLiters,
    required this.caloriesTarget,
    required this.caloriesCurrent,
  });

  final double waterTargetLiters;
  final double waterCurrentLiters;
  final int caloriesTarget;
  final int caloriesCurrent;
}

SupplyCalculatorResult calculateSupply({
  required List<InventoryItem> items,
  required int personCount,
  required int days,
}) {
  var waterCurrent = 0.0;
  var caloriesCurrent = 0;

  for (final item in items) {
    final category = InventoryItemCategoryX.fromName(item.category);
    if (category == InventoryItemCategory.water) {
      final liters = _normalizeToLiters(item.quantity, item.unit);
      if (liters != null) waterCurrent += liters;
    } else if (category == InventoryItemCategory.food &&
        item.calories != null) {
      caloriesCurrent += item.calories!;
    }
  }

  return SupplyCalculatorResult(
    waterTargetLiters: personCount * days * litersPerPersonPerDay,
    waterCurrentLiters: waterCurrent,
    caloriesTarget: personCount * days * kcalPerPersonPerDay,
    caloriesCurrent: caloriesCurrent,
  );
}

/// Only counts units that unambiguously mean a liquid volume — "Flasche"
/// (bottle), "Kiste" (crate) etc. can't be reliably converted without a
/// separate per-unit volume, so those items are simply not counted rather
/// than guessed at.
double? _normalizeToLiters(double quantity, String unit) {
  final normalized = unit.trim().toLowerCase();
  switch (normalized) {
    case 'l':
    case 'liter':
    case 'litre':
      return quantity;
    case 'ml':
    case 'milliliter':
      return quantity / 1000;
    default:
      return null;
  }
}
