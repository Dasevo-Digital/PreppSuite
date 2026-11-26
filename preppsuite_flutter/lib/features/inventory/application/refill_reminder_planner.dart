/// Reminders to get a new prescription before a medicine runs out (#150).
///
/// Only for a pack in daily use -- the household switched the reminder
/// on, and that is what makes it one; see `medication_range.dart`. The
/// end is a date counted from the last count, so the reminder stays put
/// however often the app is opened in between. Counted from today, it
/// would move a day further out each time and never come.
library;

import '../../../local_db/database.dart';
import 'expiry_reminder_planner.dart' show expiryReminderHour;
import 'medication_range.dart';

class RefillReminder {
  const RefillReminder({
    required this.id,
    required this.itemClientId,
    required this.itemName,
    required this.runsOutOn,
    required this.fireAt,
  });

  /// Notification id, unique within a run; see `ExpiryReminder.id`.
  final int id;

  final String itemClientId;
  final String itemName;

  /// The calendar day the arithmetic says the pack is empty.
  final DateTime runsOutOn;

  /// Local wall-clock instant the notification should fire at.
  final DateTime fireAt;
}

/// The reminders that should be pending now, soonest first.
///
/// Pure, like the expiry planner: [now] is passed in and the whole set is
/// worked out afresh on every change. A reminder whose moment has passed
/// is not scheduled again -- the medication screen shows a pack that is
/// due, and a notification on every sync would be noise.
///
/// A pack that lasts no longer than the lead time is due the moment it
/// is counted (#401): its refill day lies on or before the count, and that
/// moment had always passed, so the household was never reminded. It is
/// reminded once, on the morning after the count. That day is counted from
/// the count and not from [now], so planning again later moves nothing.
List<RefillReminder> planRefillReminders({
  required List<InventoryItem> items,
  required DateTime now,
  int reminderHour = expiryReminderHour,
}) {
  final reminders = <RefillReminder>[
    for (final range in medicationRanges(
      [
        for (final item in items)
          if (item.deletedAt == null) item,
      ],
      now: now,
    ))
      if (_refillDay(range) case final day?)
        if (DateTime(day.year, day.month, day.day, reminderHour)
            case final fireAt when fireAt.isAfter(now))
          RefillReminder(
            id: Object.hash('refill', range.item.clientId) & 0x7FFFFFFF,
            itemClientId: range.item.clientId,
            itemName: range.item.name,
            runsOutOn: range.runsOutOn(now),
            fireAt: fireAt,
          ),
  ];
  reminders.sort((a, b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    return byTime != 0 ? byTime : a.itemName.compareTo(b.itemName);
  });
  return reminders;
}

/// The day a pack in daily use is reminded of, or null for a reserve:
/// its refill day, and never before the day after it was counted.
DateTime? _refillDay(MedicationRange range) {
  final day = range.refillOn;
  if (day == null) return null;
  final counted = range.countedOn;
  final firstAfterCount = DateTime(
    counted.year,
    counted.month,
    counted.day + 1,
  );
  return day.isBefore(firstAfterCount) ? firstAfterCount : day;
}
