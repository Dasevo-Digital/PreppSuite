/// What the overview screen says, worked out away from the widget tree.
///
/// Counting is the whole content of that screen, so the counting is what
/// is worth testing — and every one of these has an edge that decides
/// whether the number reassures someone who should be worried.
library;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../inventory/application/inventory_category_l10n.dart';

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

InventoryOverview summarizeInventory(
  List<InventoryItem> items, {
  DateTime? now,
}) {
  final at = now ?? DateTime.now();
  final horizon = at.add(soonWindow);

  final byCategory = {
    for (final category in InventoryItemCategory.values) category: 0,
  };

  var expired = 0;
  var expiringSoon = 0;
  var lowStock = 0;

  for (final item in items) {
    final category = InventoryItemCategoryX.fromName(item.category);
    byCategory[category] = (byCategory[category] ?? 0) + 1;

    final expiry = item.expirationDate;
    if (expiry != null) {
      if (expiry.isBefore(at)) {
        expired++;
      } else if (expiry.isBefore(horizon)) {
        expiringSoon++;
      }
    }

    final minimum = item.minQuantity;
    if (minimum != null && item.quantity < minimum) lowStock++;
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
