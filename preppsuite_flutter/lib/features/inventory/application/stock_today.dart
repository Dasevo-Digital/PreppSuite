/// What is on the shelf today (#268).
///
/// The stored quantity is what was counted, on the day it was counted.
/// For nearly everything that is also what is there today: a tin is not
/// eaten unless somebody books it. A pack of medicine in daily use is the
/// exception (see `medication_range.dart`): it shrinks by its daily dose
/// whether anybody books it or not, so what is left today is the count
/// less what has been taken since.
///
/// Everything that compares stock with a minimum, shows it, adds to it or
/// takes from it goes through here. Working from the stored figure, the
/// shopping list missed a pack that had run low without being recounted
/// -- thirty tablets counted twenty days ago at one a day are ten, not
/// thirty -- and booking a purchase or a use onto it started the count
/// afresh from the old figure: the tablets taken in between came back,
/// and the prescription reminder moved weeks too late.
library;

import '../../../core/calendar_days.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';

/// Whether [item] is taken from every day by itself: a medicine with a
/// daily dose and a prescription reminder, which is how the household
/// says so (#150).
bool isInDailyUse(InventoryItem item) {
  final dose = item.dailyDose;
  return item.refillLeadDays != null &&
      dose != null &&
      dose.isFinite &&
      dose > 0 &&
      InventoryItemCategory.fromName(item.category) ==
          InventoryItemCategory.medical;
}

/// What is left of [item] on the calendar day of [now], in its own unit.
///
/// The stored quantity for anything not [isInDailyUse]; for a pack in
/// daily use the count less a dose for every day since it was counted,
/// and never below zero.
double stockToday(InventoryItem item, {DateTime? now}) {
  if (!isInDailyUse(item)) return item.quantity;
  final at = (now ?? DateTime.now()).toLocal();
  final counted = (item.stockCountedAt ?? item.updatedAt).toLocal();
  final days = calendarDaysBetween(counted, at);
  if (days <= 0) return item.quantity;
  final left = item.quantity - item.dailyDose! * days;
  if (!(left > 0)) return 0;
  // 29.3 and not 29.299999999999997 after seven doses of 0.1.
  return (left * 1e6).roundToDouble() / 1e6;
}

/// Whether [item] is under the minimum its household set for it, today.
bool isBelowMinimum(InventoryItem item, {DateTime? now}) {
  final minimum = item.minQuantity;
  return minimum != null && stockToday(item, now: now) < minimum;
}
