/// What to use next, worked out away from the widget tree.
///
/// The overview already says how many items are expired or close to it.
/// That is a count, and a count is not an errand: it does not say which
/// tin to open tonight. This puts them in the order they have to be dealt
/// with.
library;

import '../../../local_db/database.dart';
import '../../home/application/home_overview.dart' show soonWindow;

export '../../home/application/home_overview.dart' show soonWindow;

/// How pressing one row is.
enum RotationUrgency {
  /// Past its date. Not a thing to eat — a thing to replace.
  expired,

  /// Runs out inside [soonWindow]. This is the part that is actually a
  /// rotation: use it before it joins the group above.
  soon,

  /// Dated, but far enough off to leave alone.
  later,
}

class RotationEntry {
  const RotationEntry({
    required this.item,
    required this.daysLeft,
    required this.urgency,
  });

  final InventoryItem item;

  /// Whole calendar days until the date, negative once it has passed and
  /// zero on the day itself.
  ///
  /// Calendar days rather than elapsed hours: a tin that runs out tomorrow
  /// morning is "1", not "0", and someone reading "0" would think it had
  /// to go tonight.
  final int daysLeft;

  final RotationUrgency urgency;
}

/// The rotation queue, most pressing first.
///
/// Expired rows lead, longest overdue first, because they are the ones
/// that need a decision. The rest follow by date, soonest first.
///
/// Two kinds of row are left out on purpose. An item with no date cannot
/// be rotated — salt does not expire, and listing it would bury the ones
/// that do. An item at zero has nothing left to use; it belongs on the
/// shopping list instead, and it gets there through its minimum.
List<RotationEntry> buildRotation(
  List<InventoryItem> items, {
  DateTime? now,
  Duration soon = soonWindow,
}) {
  final today = _dateOnly(now ?? DateTime.now());
  final horizon = soon.inDays;

  final entries = <RotationEntry>[];
  for (final item in items) {
    final expiry = item.expirationDate;
    if (expiry == null) continue;
    if (item.quantity <= 0) continue;

    final daysLeft = _dateOnly(expiry).difference(today).inDays;
    entries.add(
      RotationEntry(
        item: item,
        daysLeft: daysLeft,
        urgency: daysLeft < 0
            ? RotationUrgency.expired
            : daysLeft <= horizon
            ? RotationUrgency.soon
            : RotationUrgency.later,
      ),
    );
  }

  entries.sort((a, b) {
    final byDate = a.daysLeft.compareTo(b.daysLeft);
    if (byDate != 0) return byDate;
    return a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  });
  return entries;
}

/// Midnight local time, so a difference counts date boundaries crossed
/// rather than hours elapsed.
DateTime _dateOnly(DateTime value) {
  final local = value.isUtc ? value.toLocal() : value;
  return DateTime(local.year, local.month, local.day);
}
