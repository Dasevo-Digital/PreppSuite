/// How many days the medicines last.
///
/// The third of the app's reach calculations, after `supply_calculator.dart`
/// (food and water) and `energy_range.dart` (light, cooking, heat). Same
/// rule as those two: **the app supplies the division and nothing else.**
/// How much is taken a day is on the packet and in the household's own
/// head; a dose this app guessed at would be the one invented figure that
/// could actually hurt somebody.
///
/// The question is FEMA's and the CDC's — both tell households to hold an
/// extra supply of prescriptions and to know how long it lasts — and it is
/// one the emergency card cannot answer. A card says "Ramipril 5 mg"; it
/// does not say whether there are three days left or three months.
library;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';

/// One medicine and how long it goes on for.
class MedicationRange {
  const MedicationRange({required this.item, required this.dailyDose});

  final InventoryItem item;

  /// In the item's own unit, and greater than zero — see
  /// [medicationRanges], which is the only thing that builds these.
  final double dailyDose;

  /// Fractional on purpose: eleven tablets at two a day is five and a
  /// half days, and rounding that up to six is how a household runs out
  /// a day earlier than it planned.
  double get days => item.quantity / dailyDose;

  /// What is said out loud. Rounded **down**, for the same reason.
  int get wholeDays => days.floor();

  /// The date the stock is gone, counted in whole days from [from].
  ///
  /// Calendar days: midnight plus whole days of 24 hours lands at 23:00 on
  /// the day before once the end of summer time lies in between, and the
  /// date shown was then a day early.
  DateTime runsOutOn(DateTime from) =>
      DateTime(from.year, from.month, from.day + wholeDays);
}

/// Every medicine that can be answered, soonest to run out first.
///
/// Three things keep an item out: it is not a medicine, it has no daily
/// dose, or there is none left. The last one is not an error — a row at
/// zero is a shopping list entry, not a reach of zero days, and reporting
/// it as "0 Tage" beside a real answer would bury the real one.
List<MedicationRange> medicationRanges(List<InventoryItem> items) {
  final ranges = <MedicationRange>[
    for (final item in items)
      if (InventoryItemCategory.fromName(item.category) ==
          InventoryItemCategory.medical)
        if (item.dailyDose case final dose? when dose > 0)
          if (item.quantity > 0) MedicationRange(item: item, dailyDose: dose),
  ];
  ranges.sort((a, b) => a.days.compareTo(b.days));
  return ranges;
}

/// Medicines the household has entered but not answered for.
///
/// Shown rather than silently skipped. A reach calculation that quietly
/// leaves out half the cupboard is worse than one that says which half:
/// the household would read a reassuring number as covering everything.
List<InventoryItem> medicationsWithoutDose(List<InventoryItem> items) => [
  for (final item in items)
    if (InventoryItemCategory.fromName(item.category) ==
        InventoryItemCategory.medical)
      if (item.dailyDose == null || item.dailyDose == 0)
        if (item.quantity > 0) item,
];

/// The one that goes first, which is the household's real answer.
MedicationRange? firstToRunOut(List<MedicationRange> ranges) =>
    ranges.isEmpty ? null : ranges.first;
