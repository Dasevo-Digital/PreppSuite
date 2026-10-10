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
///
/// Two kinds of stock, told apart by the household (#150). A reserve
/// kept for a crisis is not being taken from, so it lasts "as many days
/// as there are tablets" from whenever it is needed -- counted from
/// today. A pack in daily use shrinks every day whether anybody books it
/// or not, so it runs out on a date, counted from the day it was last
/// counted. Asking for a prescription reminder is how the household says
/// a stock is the second kind: a reminder only makes sense against a date.
library;

import 'dart:math' as math;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';

/// One medicine and how long it goes on for.
class MedicationRange {
  const MedicationRange({
    required this.item,
    required this.dailyDose,
    required this.today,
  });

  final InventoryItem item;

  /// In the item's own unit, and greater than zero — see
  /// [medicationRanges], which is the only thing that builds these.
  final double dailyDose;

  /// The calendar day this was worked out on, at local midnight.
  final DateTime today;

  /// Whether this stock is being taken from every day -- the household
  /// asked to be reminded before it runs out. See the library comment.
  bool get inDailyUse => item.refillLeadDays != null;

  /// The calendar day the stock was last counted: entered, edited to a
  /// new figure or booked down. Rows from before that was recorded count
  /// from their last change.
  DateTime get countedOn {
    final at = (item.stockCountedAt ?? item.updatedAt).toLocal();
    return DateTime(at.year, at.month, at.day);
  }

  /// Days since [countedOn] that a pack in daily use has already been
  /// taken from. Nothing for a reserve.
  int get _daysTaken =>
      inDailyUse ? math.max(0, _calendarDaysBetween(countedOn, today)) : 0;

  /// Fractional on purpose: eleven tablets at two a day is five and a
  /// half days, and rounding that up to six is how a household runs out
  /// a day earlier than it planned.
  double get days => math.max(0, item.quantity / dailyDose - _daysTaken);

  /// What is said out loud. Rounded **down**, for the same reason.
  int get wholeDays =>
      math.max(0, (item.quantity / dailyDose).floor() - _daysTaken);

  /// The date the stock is gone: for a reserve counted in whole days from
  /// [from], for a pack in daily use from the day it was counted.
  ///
  /// Calendar days: midnight plus whole days of 24 hours lands at 23:00 on
  /// the day before once the end of summer time lies in between, and the
  /// date shown was then a day early.
  DateTime runsOutOn(DateTime from) {
    if (inDailyUse) {
      final supply = (item.quantity / dailyDose).floor();
      return DateTime(countedOn.year, countedOn.month, countedOn.day + supply);
    }
    return DateTime(from.year, from.month, from.day + wholeDays);
  }

  /// The day to be reminded of a new prescription, for a pack in daily
  /// use; null for a reserve.
  DateTime? get refillOn {
    final lead = item.refillLeadDays;
    if (lead == null) return null;
    final end = runsOutOn(today);
    return DateTime(end.year, end.month, end.day - lead);
  }
}

int _calendarDaysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// Every medicine that can be answered, soonest to run out first.
///
/// Three things keep an item out: it is not a medicine, it has no daily
/// dose, or there is none left. The last one is not an error — a row at
/// zero is a shopping list entry, not a reach of zero days, and reporting
/// it as "0 Tage" beside a real answer would bury the real one.
///
/// A pack in daily use that the arithmetic says is empty stays in, at
/// zero days: either it has run out, or its count is out of date, and
/// both need somebody to look.
List<MedicationRange> medicationRanges(
  List<InventoryItem> items, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final today = DateTime(at.year, at.month, at.day);
  final ranges = <MedicationRange>[
    for (final item in items)
      if (InventoryItemCategory.fromName(item.category) ==
          InventoryItemCategory.medical)
        if (item.dailyDose case final dose? when dose > 0)
          if (item.quantity > 0)
            MedicationRange(item: item, dailyDose: dose, today: today),
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
