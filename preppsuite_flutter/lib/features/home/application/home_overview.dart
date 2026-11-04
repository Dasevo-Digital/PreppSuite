/// What the overview screen says, worked out away from the widget tree.
///
/// Counting is the whole content of that screen, so the counting is what
/// is worth testing — and every one of these has an edge that decides
/// whether the number reassures someone who should be worried.
library;

import '../../../core/calendar_days.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../inventory/application/inventory_category_l10n.dart';
import '../../inventory/application/stock_today.dart';

/// The state of the stores, in the terms the overview shows them.
class InventoryOverview {
  const InventoryOverview({
    required this.total,
    required this.expired,
    required this.expiringSoon,
    required this.lowStock,
    required this.countByCategory,
  });

  final int total;

  /// Past its date. Counted separately from [expiringSoon] — one is a
  /// thing to replace this month, the other is a thing that is no longer
  /// a supply at all.
  final int expired;

  /// Runs out within [soonWindow], but has not yet.
  final int expiringSoon;

  /// Below its own minimum. An item can be both this and expiring; they
  /// are different questions, so it is counted in both.
  final int lowStock;

  /// Every category, including the empty ones: a zero next to
  /// "Dokumente" is the most useful number on the screen.
  final Map<InventoryItemCategory, int> countByCategory;

  bool get isEmpty => total == 0;

  /// Whether anything on this screen wants doing.
  int get needsAttention => expired + lowStock;
}

/// How far ahead "soon" looks. A month is roughly a shopping cycle: long
/// enough to act on, short enough that the number stays small.
const soonWindow = Duration(days: 30);

/// Whether [expiry] falls on today or one of the [soonWindow] calendar
/// days after it.
///
/// The one "soon" of the overview, the rotation and the inventory filter
/// (#271). The filter's was a week, so "5 bald" on the overview opened a
/// list with two in it. And the overview counted thirty times 24 hours
/// from the moment it was drawn, so whether the thirtieth day was still
/// soon depended on the hour -- and across the end of summer time, on the
/// clock change.
bool expiresSoon(DateTime expiry, DateTime today) {
  final local = expiry.isUtc ? expiry.toLocal() : expiry;
  final days = calendarDaysBetween(today, local);
  return days >= 0 && days <= soonWindow.inDays;
}

InventoryOverview summarizeInventory(
  List<InventoryItem> items, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  // Good through its date, as the inventory list and the rotation read it:
  // an item marked for today runs out today and is not past it yet (#234).
  final local = at.toLocal();
  final today = DateTime(local.year, local.month, local.day);

  final byCategory = {
    for (final category in InventoryItemCategory.values) category: 0,
  };

  var expired = 0;
  var expiringSoon = 0;
  var lowStock = 0;

  for (final item in items) {
    final category = InventoryItemCategoryX.fromName(item.category);
    byCategory[category] = (byCategory[category] ?? 0) + 1;

    // A row at zero keeps its date, but nothing on the shelf has it
    // (#281).
    final expiry = isUsedUp(item, now: at) ? null : item.expirationDate;
    if (expiry != null) {
      if (expiry.isBefore(today)) {
        expired++;
      } else if (expiresSoon(expiry, today)) {
        expiringSoon++;
      }
    }

    if (isBelowMinimum(item, now: at)) lowStock++;
  }

  return InventoryOverview(
    total: items.length,
    expired: expired,
    expiringSoon: expiringSoon,
    lowStock: lowStock,
    countByCategory: byCategory,
  );
}

/// How much of the checklists is done.
class ChecklistOverview {
  const ChecklistOverview({
    required this.done,
    required this.total,
    required this.listsComplete,
    required this.lists,
  });

  final int done;
  final int total;

  /// Lists with nothing left in them. An empty list does not count as
  /// complete — there was never anything to complete.
  final int listsComplete;
  final int lists;

  /// 0 to 1, and 0 when there is nothing to do rather than a division by
  /// zero.
  double get progress => total == 0 ? 0 : done / total;
}

ChecklistOverview summarizeChecklists({
  required List<ChecklistTemplate> templates,
  required List<ChecklistItem> items,
}) {
  final byTemplate = <String, List<ChecklistItem>>{};
  for (final item in items) {
    byTemplate.putIfAbsent(item.templateClientId, () => []).add(item);
  }

  var done = 0;
  var listsComplete = 0;

  for (final template in templates) {
    final own = byTemplate[template.clientId] ?? const <ChecklistItem>[];
    final checked = own.where((item) => item.isChecked).length;
    done += checked;
    if (own.isNotEmpty && checked == own.length) listsComplete++;
  }

  // Counted through the templates rather than over `items` directly, so
  // an item whose list was deleted does not go on inflating the total.
  final total = [
    for (final template in templates)
      ...byTemplate[template.clientId] ?? const <ChecklistItem>[],
  ].length;

  return ChecklistOverview(
    done: done,
    total: total,
    listsComplete: listsComplete,
    lists: templates.length,
  );
}
