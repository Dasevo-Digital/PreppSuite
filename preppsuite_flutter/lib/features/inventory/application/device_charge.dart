/// A device's own battery check (#179).
///
/// Beside the household's one reminder for "the equipment", not instead
/// of it: that one covers everything with a battery nobody wrote down,
/// and this one the devices that were. The arithmetic is the same
/// [ChargeCheck] -- calendar days from the last confirmed check -- so a
/// device and the equipment as a whole cannot disagree about what "due in
/// three days" means, and the summer-time trap that class already
/// stepped around is stepped around here too.
library;

import '../../../local_db/database.dart';
import 'charge_reminder_provider.dart';
import 'expiry_reminder_planner.dart' show expiryReminderHour;

/// The intervals the form offers, in days. The household setting's,
/// without "off" -- a device that needs no check simply has none.
const deviceChargeIntervals = [14, 30, 60, 90, 180, 365];

/// What a device's check is set to when it is switched on.
const defaultDeviceChargeDays = 90;

/// [item]'s battery check, or null where it has none.
ChargeCheck? deviceChargeCheck(InventoryItem item) {
  final every = item.chargeEveryDays;
  if (every == null || every <= 0 || item.deletedAt != null) return null;
  return ChargeCheck(lastChecked: item.chargeCheckedAt, everyDays: every);
}

/// One device with a check, and where it stands.
class DeviceCharge {
  const DeviceCharge({required this.item, required this.check});

  final InventoryItem item;
  final ChargeCheck check;

  /// Days until the check, negative once overdue, null while nobody ever
  /// confirmed one.
  int? daysUntilDue({DateTime? now}) => check.daysUntilDue(now: now);

  bool isDue({DateTime? now}) => check.isDue(now: now);
}

/// Every device in [items] that has a check, the most urgent first: the
/// longest overdue, then the soonest, then the ones never confirmed.
List<DeviceCharge> deviceCharges(
  Iterable<InventoryItem> items, {
  DateTime? now,
}) {
  final charges = [
    for (final item in items)
      if (deviceChargeCheck(item) case final check?)
        DeviceCharge(item: item, check: check),
  ];
  charges.sort((a, b) {
    final da = a.daysUntilDue(now: now);
    final db = b.daysUntilDue(now: now);
    if (da == null && db == null) return a.item.name.compareTo(b.item.name);
    if (da == null) return 1;
    if (db == null) return -1;
    final byDays = da.compareTo(db);
    return byDays != 0 ? byDays : a.item.name.compareTo(b.item.name);
  });
  return charges;
}

/// A pending notification for one device.
class DeviceChargeReminder {
  const DeviceChargeReminder({
    required this.id,
    required this.itemClientId,
    required this.itemName,
    required this.fireAt,
  });

  /// Notification id, unique within a run; see `ExpiryReminder.id`.
  final int id;
  final String itemClientId;
  final String itemName;

  /// Local wall-clock instant, the morning of the day it is due.
  final DateTime fireAt;
}

/// The reminders that should be pending now, soonest first.
///
/// Only for a day still ahead. A device already overdue is on the
/// overview in red; a notification for it on every start of the app
/// would teach people to swipe them away, which is how the one that
/// matters gets swiped away too. Pure, like the expiry planner.
List<DeviceChargeReminder> planDeviceChargeReminders({
  required List<InventoryItem> items,
  required DateTime now,
  int reminderHour = expiryReminderHour,
}) {
  final reminders = <DeviceChargeReminder>[
    for (final charge in deviceCharges(items, now: now))
      if (charge.check.dueAt?.toLocal() case final due?)
        if (DateTime(due.year, due.month, due.day, reminderHour)
            case final fireAt when fireAt.isAfter(now))
          DeviceChargeReminder(
            id: Object.hash('charge', charge.item.clientId) & 0x7FFFFFFF,
            itemClientId: charge.item.clientId,
            itemName: charge.item.name,
            fireAt: fireAt,
          ),
  ];
  reminders.sort((a, b) => a.fireAt.compareTo(b.fireAt));
  return reminders;
}
