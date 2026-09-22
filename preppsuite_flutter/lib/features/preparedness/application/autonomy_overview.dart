/// How long the household is on its own, resource by resource.
///
/// The crisis hub used to ask for all five of these figures by hand. Four
/// of them the app already works out elsewhere and has for some time —
/// water and food in `supply_calculator.dart`, medicines in
/// `medication_range.dart`, stored energy in `energy_range.dart` — so the
/// household was typing in numbers the app held, and the two could drift
/// apart silently. The hub's own comment gave the reason for asking only
/// for the ones that "cannot be honestly inferred", and then asked for the
/// others too.
///
/// This puts the four back where they are calculated and leaves the fifth
/// alone: nothing in the app counts soap, and nothing should pretend to.
///
/// **The app supplies the division and nothing else**, exactly as the
/// three calculations behind it do. Where the stock cannot be divided —
/// water in crates rather than litres, food with no calorie figure, a
/// medicine with no daily dose, a reserve nothing draws on — this says so
/// and falls back to what the household entered by hand, rather than
/// showing a zero that reads like an answer.
library;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';
// Both this and `medication_range.dart` answer "what runs out first", so
// both export a `firstToRunOut`. The prefix says which one is meant.
import '../../energy/application/energy_range.dart' as power;
import '../../energy/application/energy_store.dart';
import '../../inventory/application/medication_range.dart';
import '../../inventory/application/supply_calculator.dart';
import 'preparedness_hub_store.dart';

enum AutonomyResource { water, food, medicine, energy, hygiene }

/// Where a figure came from.
enum AutonomyBasis {
  /// Divided out of what the household has recorded.
  stock,

  /// Typed in, because the stock could not answer.
  entered,
}

/// Why the stock could not answer.
enum AutonomyGap {
  /// Nothing of this kind has been recorded at all.
  nothingRecorded,

  /// It is recorded, but in a form nothing divides into.
  notDivisible,

  /// Only the household can answer this one. Hygiene, and only hygiene.
  onlyByHand,
}

/// One resource and how far it reaches.
class AutonomyReach {
  const AutonomyReach({
    required this.resource,
    this.days,
    this.basis,
    this.gap,
    this.unmeasured = 0,
  });

  final AutonomyResource resource;

  /// Whole days, rounded **down**, or null where there is no answer.
  ///
  /// Down for the reason `MedicationRange.wholeDays` gives: a reserve
  /// that lasts three days and twenty hours lasts three days, and
  /// rounding up is how a plan ends a day early.
  final int? days;

  /// Null exactly when [days] is.
  final AutonomyBasis? basis;

  /// Why the stock could not answer. Set even when [days] came from the
  /// household afterwards, because that is what the screen has to
  /// explain.
  final AutonomyGap? gap;

  /// Entries of this kind the division had to leave out. A number with
  /// this above zero covers less than the cupboard does.
  final int unmeasured;

  bool get answered => days != null;
}

/// The five reaches, in the order they are shown.
List<AutonomyReach> autonomyReaches({
  required List<InventoryItem> items,
  required SupplyHousehold household,
  required EnergyPlan energy,
  required AutonomySnapshot entered,
}) => [
  _water(items, household, entered),
  _food(items, household, entered),
  _medicine(items, entered),
  _energy(energy, entered),
  _hygiene(entered),
];

/// The shortest answered reach — the household's real range.
///
/// A resource with no answer is not a reach of zero and does not win
/// this: an unanswered question is an open planning gap, which the
/// screen names separately. Null when nothing at all can be answered.
AutonomyReach? limitingReach(List<AutonomyReach> reaches) {
  AutonomyReach? shortest;
  for (final reach in reaches) {
    final days = reach.days;
    if (days == null) continue;
    if (shortest == null || days < shortest.days!) shortest = reach;
  }
  return shortest;
}

/// The resources nothing could answer, in order.
List<AutonomyReach> openQuestions(List<AutonomyReach> reaches) => [
  for (final reach in reaches)
    if (!reach.answered) reach,
];

AutonomyReach _water(
  List<InventoryItem> items,
  SupplyHousehold household,
  AutonomySnapshot entered,
) {
  final perDay = household.litersPerDay;
  final stocked = [
    for (final item in items)
      if (InventoryItemCategory.fromName(item.category) ==
          InventoryItemCategory.water)
        if (item.quantity > 0) item,
  ];
  final uncounted = waterWithoutVolume(items);
  if (stocked.isEmpty) {
    return _fallback(
      AutonomyResource.water,
      AutonomyGap.nothingRecorded,
      entered.waterDays,
    );
  }
  if (perDay <= 0 || uncounted.length == stocked.length) {
    return _fallback(
      AutonomyResource.water,
      AutonomyGap.notDivisible,
      entered.waterDays,
      unmeasured: uncounted.length,
    );
  }
  final liters = calculateSupply(
    items: items,
    days: 1,
    household: household,
  ).waterCurrentLiters;
  return AutonomyReach(
    resource: AutonomyResource.water,
    days: (liters / perDay).floor(),
    basis: AutonomyBasis.stock,
    unmeasured: uncounted.length,
  );
}

AutonomyReach _food(
  List<InventoryItem> items,
  SupplyHousehold household,
  AutonomySnapshot entered,
) {
  final perDay = household.kcalPerDay;
  final stocked = [
    for (final item in items)
      if (InventoryItemCategory.fromName(item.category) ==
          InventoryItemCategory.food)
        if (item.quantity > 0) item,
  ];
  // Two ways a food row can fail to count, and both have to show here or
  // the screen says "all of it" while rows fall out silently: no calorie
  // figure at all, and a unit no label can be applied to. A row can be
  // both, so they are joined by id rather than added up.
  final uncounted = {
    for (final item in foodWithoutCalories(items)) item.clientId: item,
    for (final item in foodWithoutMeasure(items)) item.clientId: item,
  }.values.toList();
  if (stocked.isEmpty) {
    return _fallback(
      AutonomyResource.food,
      AutonomyGap.nothingRecorded,
      entered.foodDays,
    );
  }
  if (perDay <= 0 || uncounted.length == stocked.length) {
    return _fallback(
      AutonomyResource.food,
      AutonomyGap.notDivisible,
      entered.foodDays,
      unmeasured: uncounted.length,
    );
  }
  final calories = calculateSupply(
    items: items,
    days: 1,
    household: household,
  ).caloriesCurrent;
  return AutonomyReach(
    resource: AutonomyResource.food,
    days: calories ~/ perDay,
    basis: AutonomyBasis.stock,
    unmeasured: uncounted.length,
  );
}

/// The medicine that runs out first, which is the household's answer —
/// not the average and not the longest.
AutonomyReach _medicine(List<InventoryItem> items, AutonomySnapshot entered) {
  final ranges = medicationRanges(items);
  final unanswered = medicationsWithoutDose(items);
  final first = firstToRunOut(ranges);
  if (first == null) {
    return _fallback(
      AutonomyResource.medicine,
      unanswered.isEmpty
          ? AutonomyGap.nothingRecorded
          : AutonomyGap.notDivisible,
      entered.medicineDays,
      unmeasured: unanswered.length,
    );
  }
  return AutonomyReach(
    resource: AutonomyResource.medicine,
    days: first.wholeDays,
    basis: AutonomyBasis.stock,
    unmeasured: unanswered.length,
  );
}

AutonomyReach _energy(EnergyPlan plan, AutonomySnapshot entered) {
  final ranges = power.energyRanges(
    reserves: plan.reserves,
    draws: plan.draws,
  );
  final first = power.firstToRunOut(ranges);
  if (first?.days case final days?) {
    return AutonomyReach(
      resource: AutonomyResource.energy,
      days: days,
      basis: AutonomyBasis.stock,
      // A reserve nothing draws on is not an answer and not a fault —
      // a spare cylinder for a stove nobody entered is the commonest
      // case — but the household should see that it was not counted.
      unmeasured: [
        for (final range in ranges)
          if (range.unused) range,
      ].length,
    );
  }
  return _fallback(
    AutonomyResource.energy,
    plan.isEmpty ? AutonomyGap.nothingRecorded : AutonomyGap.notDivisible,
    entered.energyDays,
    unmeasured: [
      for (final range in ranges)
        if (range.unused) range,
    ].length,
  );
}

/// Nothing in this app counts soap, towels or bin bags, and a figure it
/// invented for them would be exactly the kind this app does not ship.
AutonomyReach _hygiene(AutonomySnapshot entered) => _fallback(
  AutonomyResource.hygiene,
  AutonomyGap.onlyByHand,
  entered.hygieneDays,
);

AutonomyReach _fallback(
  AutonomyResource resource,
  AutonomyGap gap,
  int entered, {
  int unmeasured = 0,
}) => AutonomyReach(
  resource: resource,
  days: entered > 0 ? entered : null,
  basis: entered > 0 ? AutonomyBasis.entered : null,
  gap: gap,
  unmeasured: unmeasured,
);
