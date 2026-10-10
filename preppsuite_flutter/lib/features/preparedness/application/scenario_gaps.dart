/// What is missing to get through a stretch without power, water or
/// heating (#149).
///
/// Not a calculation of its own. The four answers come from where the
/// app already works them out -- water and food from
/// `supply_calculator.dart`, medicines from `medication_range.dart`,
/// stored energy from `energy_range.dart` -- and this only turns "how
/// many days" into "how much is missing for this many days", which is
/// the form a shopping list needs.
///
/// The same rule as behind those: **nothing is estimated here.** Water
/// and food per person are the supply calculator's figures -- the BBK's
/// and the BLE's where they publish one, and marked as the app's own
/// there where they do not; a medicine's dose and a stove's consumption
/// are the household's own. Where the household has not said, the answer
/// is "not known", and the screen says so instead of filling in a number.
///
/// There is no season in it. Whether a stretch in January needs heat
/// depends on what heats, and only the household's own list of what
/// draws on its reserves says that; a heating period assumed here would
/// be the invented figure the rule excludes.
library;

import 'dart:math' as math;

import '../../../local_db/database.dart';
import '../../energy/application/energy_range.dart';
import '../../energy/application/energy_store.dart';
import '../../inventory/application/medication_range.dart';
import '../../inventory/application/supply_calculator.dart';

/// The stretches offered: 72 hours, and the ten days the BBK advises
/// stocking for.
const scenarioHorizons = [3, 10];

/// One medicine over the stretch.
class MedicineGap {
  const MedicineGap({
    required this.item,
    required this.needed,
    required this.available,
  });

  final InventoryItem item;

  /// Daily dose times the days, in the item's unit.
  final double needed;

  /// What there is: the stock for a reserve, what the count leaves for a
  /// pack in daily use.
  final double available;

  double get missing => math.max(0, needed - available);
}

/// One kind of stored energy over the stretch.
class EnergyGap {
  const EnergyGap({
    required this.kind,
    required this.needed,
    required this.stored,
    required this.uses,
    required this.reserves,
  });

  final EnergyKind kind;

  /// What everything of this kind draws a day, times the days.
  final double needed;

  final double stored;

  /// What draws on it, by the household's own names.
  final List<String> uses;

  /// What it is stored as, by the household's own names.
  final List<String> reserves;

  double get missing => math.max(0, needed - stored);
}

class ScenarioGaps {
  const ScenarioGaps({
    required this.days,
    required this.waterNeeded,
    required this.waterStored,
    required this.kcalNeeded,
    required this.kcalStored,
    required this.medicines,
    required this.medicinesWithoutDose,
    required this.energy,
    required this.energyUnused,
  });

  final int days;

  final double waterNeeded;
  final double waterStored;
  double get waterMissing => math.max(0, waterNeeded - waterStored);

  final int kcalNeeded;
  final int kcalStored;
  int get kcalMissing => math.max(0, kcalNeeded - kcalStored);

  /// Every medicine with a daily dose, the one shortest of the stretch
  /// first.
  final List<MedicineGap> medicines;

  /// Medicines in the stores with no daily dose: named, because the
  /// stretch cannot be answered for them.
  final List<InventoryItem> medicinesWithoutDose;

  /// Every kind of energy something draws on.
  final List<EnergyGap> energy;

  /// Kinds that are stored but that nothing draws on: no need can be
  /// worked out for them, and they are not a gap.
  final List<EnergyKind> energyUnused;

  /// Whether anything can be bought to close a gap. Calories are not on
  /// this list: a kilocalorie is not something a shop sells, and which
  /// food closes the gap is the household's choice.
  bool get hasPurchasableGap =>
      waterMissing > 0 ||
      medicines.any((m) => m.missing > 0) ||
      energy.any((e) => e.missing > 0);
}

ScenarioGaps scenarioGaps({
  required List<InventoryItem> items,
  required SupplyHousehold household,
  required EnergyPlan energy,
  required int days,
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final live = [
    for (final item in items)
      if (item.deletedAt == null) item,
  ];
  final supply = calculateSupply(
    items: live,
    days: days,
    household: household,
  );

  final medicines = [
    for (final range in medicationRanges(live, now: at))
      MedicineGap(
        item: range.item,
        needed: range.dailyDose * days,
        available: range.days * range.dailyDose,
      ),
  ]..sort((a, b) => b.missing.compareTo(a.missing));

  final energyGaps = <EnergyGap>[];
  final unused = <EnergyKind>[];
  for (final range in energyRanges(
    reserves: energy.reserves,
    draws: energy.draws,
  )) {
    if (range.unused) {
      unused.add(range.kind);
      continue;
    }
    energyGaps.add(
      EnergyGap(
        kind: range.kind,
        needed: range.perDay * days,
        stored: range.stored,
        uses: [
          for (final draw in energy.draws)
            if (draw.kind == range.kind && draw.label.trim().isNotEmpty)
              draw.label.trim(),
        ],
        reserves: [
          for (final reserve in energy.reserves)
            if (reserve.kind == range.kind && reserve.label.trim().isNotEmpty)
              reserve.label.trim(),
        ],
      ),
    );
  }

  return ScenarioGaps(
    days: days,
    waterNeeded: supply.waterTargetLiters,
    waterStored: supply.waterCurrentLiters,
    kcalNeeded: supply.caloriesTarget,
    kcalStored: supply.caloriesCurrent,
    medicines: medicines,
    medicinesWithoutDose: medicationsWithoutDose(live),
    energy: energyGaps,
    energyUnused: unused,
  );
}
