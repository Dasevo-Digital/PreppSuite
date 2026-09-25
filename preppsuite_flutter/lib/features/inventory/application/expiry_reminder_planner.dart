import '../../../local_db/database.dart';

/// Default lead times, in days before an item's expiration date. Two
/// reminders rather than one: the far one leaves room to actually use the
/// item up, the near one catches what was ignored the first time.
const defaultExpiryLeadDays = [30, 7];

/// Local wall-clock hour reminders fire at. Late enough that a phone is
/// not buzzing at night, early enough to still act on it that day.
const expiryReminderHour = 9;

/// iOS silently drops anything past 64 pending local notifications, and
/// there is no error to observe when it does. Staying under that with a
/// margin means a household with hundreds of items still gets the
/// reminders that matter — the nearest ones — instead of an arbitrary
/// subset chosen by the OS.
const maxScheduledExpiryReminders = 60;

/// This item's own lead times, or null where it follows the household.
///
/// Null and empty mean different things and both are real answers: null is
/// "whatever the household picked", an empty list is "this item, never".
/// Anything that is not a whole number of days is dropped rather than
/// refused — the column is written by a picker, so a bad value there is a
/// corrupted row, and a corrupted row should cost its own reminders and
/// nothing else.
List<int>? decodeItemLeadDays(String? stored) {
  if (stored == null) return null;
  final days =
      stored
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .where((day) => day >= 0)
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  return days;
}

/// The stored form of [leadDays]. An empty list is an empty string, which
/// is deliberately not null: see [decodeItemLeadDays].
String encodeItemLeadDays(List<int> leadDays) {
  final days = leadDays.where((day) => day >= 0).toSet().toList()
    ..sort((a, b) => b.compareTo(a));
  return days.join(',');
}

/// One reminder for one item at one lead time.
class ExpiryReminder {
  const ExpiryReminder({
    required this.id,
    required this.itemClientId,
    required this.itemName,
    required this.expirationDate,
    required this.leadDays,
    required this.fireAt,
  });

  /// Notification id. Derived from the item and lead time so the same
  /// reminder keeps its id within a run; it is deliberately *not* relied
  /// on across restarts — [NotificationService] cancels previously
  /// scheduled reminders by their payload, not by recomputing ids.
  final int id;

  final String itemClientId;
  final String itemName;

  /// The item's expiration date, as stored (treated as a calendar day).
  final DateTime expirationDate;

  /// How many days before [expirationDate] this reminder fires.
  final int leadDays;

  /// Local wall-clock instant the notification should fire at.
  final DateTime fireAt;
}

/// Works out which reminders should currently be scheduled for [items].
///
/// Pure and total: no clock, no storage, no platform calls — [now] is
/// passed in so the whole thing is testable, and it is called fresh on
/// every inventory change rather than diffed, so the result is always the
/// complete set that should be pending.
///
/// [leadDays] is the household's setting and applies to every item that
/// does not carry its own; `InventoryItem.expiryLeadDays` overrides it per
/// row, including with an empty list to mean "never for this one".
///
/// Items without an expiration date are skipped, as are reminders whose
/// moment has already passed: an item expiring tomorrow gets no 30-day
/// reminder, and an already-expired item gets none at all. Expiry that has
/// already happened is the attention badge's job (see
/// `inventoryAttentionCountProvider`), not a notification's — firing for
/// it on every sync would mean notifying about the same stale item
/// forever.
List<ExpiryReminder> planExpiryReminders({
  required List<InventoryItem> items,
  required DateTime now,
  List<int> leadDays = defaultExpiryLeadDays,
  int reminderHour = expiryReminderHour,
  int limit = maxScheduledExpiryReminders,
}) {
  final reminders = <ExpiryReminder>[];

  for (final item in items) {
    final expiration = item.expirationDate;
    if (expiration == null) continue;
    if (item.deletedAt != null) continue;

    // The item's own list wins where it has one, and an item with an
    // empty list is asking for silence -- which the loop below gives it
    // by having nothing to iterate.
    for (final lead in decodeItemLeadDays(item.expiryLeadDays) ?? leadDays) {
      if (lead < 0) continue;

      // Built from the date parts rather than by subtracting a Duration:
      // a Duration of N days across a DST boundary lands an hour off,
      // which would drift the reminder out of the intended hour.
      final fireAt = DateTime(
        expiration.year,
        expiration.month,
        expiration.day - lead,
        reminderHour,
      );
      if (!fireAt.isAfter(now)) continue;

      reminders.add(
        ExpiryReminder(
          id: _reminderId(item.clientId, lead),
          itemClientId: item.clientId,
          itemName: item.name,
          expirationDate: expiration,
          leadDays: lead,
          fireAt: fireAt,
        ),
      );
    }
  }

  // Soonest first, so truncating to [limit] keeps the reminders the user
  // needs next. Ties broken by name then lead time to keep the order
  // stable across runs (and assertable in tests).
  reminders.sort((a, b) {
    final byTime = a.fireAt.compareTo(b.fireAt);
    if (byTime != 0) return byTime;
    final byName = a.itemName.compareTo(b.itemName);
    if (byName != 0) return byName;
    return a.leadDays.compareTo(b.leadDays);
  });

  if (reminders.length > limit) {
    return reminders.sublist(0, limit);
  }
  return reminders;
}

/// Masked to 31 bits: Android notification ids are 32-bit signed, and
/// negative ids are accepted but awkward to reason about.
int _reminderId(String clientId, int leadDays) =>
    Object.hash(clientId, leadDays) & 0x7FFFFFFF;
