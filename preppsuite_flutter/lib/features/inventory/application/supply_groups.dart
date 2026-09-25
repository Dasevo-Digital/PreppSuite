import '../../../local_db/database.dart';
import 'food_amount.dart';

/// Whether a ten-day supply is more than ten days of calories.
///
/// The calculator answers two questions — enough litres, enough
/// kilocalories — and a household that passes both can still be stocked
/// entirely with pasta. The BLE answers the third: how much of *which
/// kind*.
///
/// The figures below are theirs, from the Vorratskalkulator of the
/// Bundesanstalt für Landwirtschaft und Ernährung, per person and day at
/// the same 2200 kcal the rest of this app's calculation uses. Nothing
/// here is derived, averaged or adjusted.
///
/// **Why groups and not nutrients.** Tagging foods with "source of vitamin
/// C" is the more attractive display and the one this app cannot honestly
/// build: micronutrients are only on a German label where they are
/// advertised, so Open Food Facts has them for almost nothing, and an
/// empty field would read as "your supply has no vitamin C". Hand-tagging
/// instead would make the tags this app's own medical claim. The BLE's
/// groups carry no such claim — they are a published table with published
/// amounts, and covering them is what the table is *for*.
enum SupplyGroup {
  /// Getreideprodukte, Brot, Kartoffeln.
  grain,

  /// Gemüse, Pilze.
  vegetables,

  /// Obst.
  fruit,

  /// Getränke.
  drinks,

  /// Milch, Milcherzeugnisse.
  dairy,

  /// Eier, Fleisch, Wurst und Fisch.
  protein,

  /// Fette, Öl.
  fats,
}

/// What the BLE names per person and day, in the base unit the inventory
/// reduces to — grams for mass, millilitres for volume.
///
/// The drinks row is the same two litres the water target already uses,
/// arrived at from the other direction: 1.5 litres to drink plus 0.5 to
/// cook with. They agree because they come from the same table.
const _perPersonPerDay = <SupplyGroup, (double amount, FoodBase base)>{
  SupplyGroup.grain: (330, FoodBase.mass),
  SupplyGroup.vegetables: (400, FoodBase.mass),
  SupplyGroup.fruit: (250, FoodBase.mass),
  SupplyGroup.drinks: (2000, FoodBase.volume),
  SupplyGroup.dairy: (250, FoodBase.mass),
  SupplyGroup.protein: (120, FoodBase.mass),
  SupplyGroup.fats: (33, FoodBase.mass),
};

/// The base unit a group is measured in.
FoodBase baseOf(SupplyGroup group) => _perPersonPerDay[group]!.$2;

/// What [persons] need of [group] over [days], in that group's base unit.
double supplyGroupTarget(
  SupplyGroup group, {
  required int persons,
  required int days,
}) => _perPersonPerDay[group]!.$1 * persons * days;

/// One group, what the household holds of it and what the table asks for.
class SupplyGroupCoverage {
  const SupplyGroupCoverage({
    required this.group,
    required this.have,
    required this.target,
  });

  final SupplyGroup group;

  /// In grams or millilitres, following [baseOf].
  final double have;
  final double target;

  FoodBase get base => baseOf(group);

  /// Deliberately uncapped. A household with three times the vegetables
  /// it needs should read 300 %, not a full bar — the bar is the whole
  /// point of the screen and a bar that cannot exceed its end says the
  /// same thing about "just enough" and "far too much".
  double get share => target <= 0 ? 0 : have / target;
}

/// What the stock covers, group by group.
///
/// Rows that name no group are **not** distributed by guesswork and not
/// silently dropped: they come back in [SupplyGroupResult.unassigned] so
/// the screen can name them. Guessing that "Nudeln" is grain would be
/// right most of the time and wrong the once that mattered, and the app
/// does not guess on this screen any more than it guesses a dose.
class SupplyGroupResult {
  const SupplyGroupResult({
    required this.coverage,
    required this.unassigned,
    required this.unmeasurable,
  });

  final List<SupplyGroupCoverage> coverage;

  /// Food and water rows with no group set.
  final List<InventoryItem> unassigned;

  /// Rows that have a group but whose unit cannot be reduced — "6 Dosen".
  /// Named for the same reason: they are missing from every total above.
  final List<InventoryItem> unmeasurable;
}

SupplyGroupResult supplyGroupCoverage({
  required List<InventoryItem> items,
  required int persons,
  required int days,
}) {
  final totals = {for (final group in SupplyGroup.values) group: 0.0};
  final unassigned = <InventoryItem>[];
  final unmeasurable = <InventoryItem>[];

  for (final item in items) {
    if (item.deletedAt != null) continue;
    // Only what the table is about. A torch has no group and is not
    // missing one.
    if (item.category != 'food' && item.category != 'water') continue;

    final group = supplyGroupFromName(item.foodGroup);
    if (group == null) {
      unassigned.add(item);
      continue;
    }

    final amount = measure(item.quantity, item.unit);
    // The base has to match as well: a litre of oil is not 1000 g of it,
    // and this app converts between the two nowhere.
    if (amount == null || amount.base != baseOf(group)) {
      unmeasurable.add(item);
      continue;
    }
    totals[group] = totals[group]! + amount.amount;
  }

  return SupplyGroupResult(
    coverage: [
      for (final group in SupplyGroup.values)
        SupplyGroupCoverage(
          group: group,
          have: totals[group]!,
          target: supplyGroupTarget(group, persons: persons, days: days),
        ),
    ],
    unassigned: unassigned,
    unmeasurable: unmeasurable,
  );
}

/// The stored name back to a group, or null for "none set" and for a name
/// this version does not know — a row written by a newer build travels
/// through the shared folder and must not crash an older one.
SupplyGroup? supplyGroupFromName(String? name) {
  if (name == null) return null;
  for (final group in SupplyGroup.values) {
    if (group.name == name) return group;
  }
  return null;
}
