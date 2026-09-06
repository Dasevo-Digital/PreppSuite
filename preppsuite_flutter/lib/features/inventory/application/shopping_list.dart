/// What is missing, worked out away from the widget tree.
///
/// Two questions are answered here, and they are not the same one. The
/// household target says whether the stores would carry everyone through
/// the planned days at all; the per-item minimums say what to put in a
/// basket. A household can meet the first and still be out of tinned
/// tomatoes, and it can hold every minimum and still be four days short.
library;

import '../../../local_db/database.dart';
import 'supply_calculator.dart';

/// One line to buy: an item under the minimum its household set for it.
class ShoppingListEntry {
  const ShoppingListEntry({required this.item, required this.shortfall});

  final InventoryItem item;

  /// How much is missing, in the item's own unit. Always above zero —
  /// an entry only exists because something is short.
  final double shortfall;

  /// The share of the minimum that is missing, 0..1.
  ///
  /// What sorts the list. Two bottles missing from a minimum of three is
  /// a more pressing errand than two missing from a minimum of fifty, and
  /// the absolute figure cannot say that.
  double get shortfallRatio {
    final minimum = item.minQuantity;
    if (minimum == null || minimum <= 0) return 1;
    return (shortfall / minimum).clamp(0, 1);
  }
}

/// The whole list.
class ShoppingList {
  const ShoppingList({
    required this.days,
    required this.waterShortfallLiters,
    required this.calorieShortfall,
    required this.daysCovered,
    required this.entries,
  });

  /// The horizon the target was worked out for.
  final int days;

  /// Litres still to buy to reach the target. Zero once it is met.
  final double waterShortfallLiters;

  /// Kilocalories still to buy. Zero once the target is met.
  final int calorieShortfall;

  /// Whole days the current stores would carry the household, limited by
  /// whichever of water and food runs out first.
  ///
  /// Null when the household eats and drinks nothing a day, which only a
  /// profile with no people can manage — dividing by that would give an
  /// infinite supply, and an empty flat is not well stocked.
  final int? daysCovered;

  /// Items below their own minimum, most depleted first.
  final List<ShoppingListEntry> entries;

  bool get targetMet => waterShortfallLiters <= 0 && calorieShortfall <= 0;

  bool get isEmpty => targetMet && entries.isEmpty;
}

ShoppingList buildShoppingList({
  required List<InventoryItem> items,
  required int days,
  SupplyHousehold household = const SupplyHousehold(),
}) {
  final supply = calculateSupply(
    items: items,
    days: days,
    household: household,
  );

  final entries = <ShoppingListEntry>[];
  for (final item in items) {
    final minimum = item.minQuantity;
    // An item without a minimum is not "at zero", it is unanswered. Only
    // a household that stated a target can be short of it.
    if (minimum == null) continue;
    final shortfall = minimum - item.quantity;
    if (shortfall <= 0) continue;
    entries.add(ShoppingListEntry(item: item, shortfall: shortfall));
  }

  entries.sort((a, b) {
    final byRatio = b.shortfallRatio.compareTo(a.shortfallRatio);
    if (byRatio != 0) return byRatio;
    // Stable and readable rather than arbitrary: the same list twice
    // running must not reshuffle itself.
    return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  });

  return ShoppingList(
    days: days,
    waterShortfallLiters: _shortfall(
      supply.waterTargetLiters,
      supply.waterCurrentLiters,
    ),
    calorieShortfall: _shortfall(
      supply.caloriesTarget.toDouble(),
      supply.caloriesCurrent.toDouble(),
    ).round(),
    daysCovered: _daysCovered(supply, household),
    entries: entries,
  );
}

double _shortfall(double target, double current) {
  final missing = target - current;
  return missing > 0 ? missing : 0;
}

/// The shorter of the two runways, rounded down.
///
/// Down, because a day that is only two thirds covered is not a day the
/// household is carried through, and this number's whole job is to be
/// trusted when it is uncomfortable.
int? _daysCovered(SupplyCalculatorResult supply, SupplyHousehold household) {
  final perDayWater = household.litersPerDay;
  final perDayKcal = household.kcalPerDay;
  if (perDayWater <= 0 && perDayKcal <= 0) return null;

  var covered = <int>[];
  if (perDayWater > 0) {
    covered.add((supply.waterCurrentLiters / perDayWater).floor());
  }
  if (perDayKcal > 0) {
    covered.add((supply.caloriesCurrent / perDayKcal).floor());
  }
  return covered.reduce((a, b) => a < b ? a : b);
}
