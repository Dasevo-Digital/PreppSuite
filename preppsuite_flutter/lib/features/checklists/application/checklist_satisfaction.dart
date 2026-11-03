import '../../../local_db/database.dart';
import '../../inventory/application/stock_today.dart';

/// Ticked, or covered by the stock it is linked to -- as that stands
/// today, so a pack in daily use stops covering it as it is used (#268).
bool isChecklistItemSatisfied(
  ChecklistItem item,
  Map<String, InventoryItem> inventoryById, {
  DateTime? now,
}) {
  if (item.isChecked) return true;
  final linked = inventoryById[item.linkedInventoryItemId];
  if (linked == null) return false;
  final stock = stockToday(linked, now: now);
  if (stock <= 0) return false;
  final target = item.targetQuantity;
  return target == null || target <= 0 || stock >= target;
}

/// How far each list has got, in one pass over every item.
///
/// The checklist screen used to work this out per row: each tile opened
/// its own stream of its own items and rebuilt a map of the entire
/// inventory to look up against. With nineteen built-in lists that is
/// nineteen database subscriptions for one screen, and nineteen copies
/// of the same inventory map thrown away on every tick of it — the map
/// is the expensive half, because it is the size of the whole pantry
/// rather than the size of the list being drawn.
///
/// One pass, one map, handed down. A template with no items at all is
/// absent from the result rather than present as 0 of 0: the screen
/// shows a line per list only where there is something to report.
Map<String, ({int done, int total})> checklistProgressByTemplate({
  required Iterable<ChecklistItem> items,
  required Map<String, InventoryItem> inventoryById,
}) {
  final progress = <String, ({int done, int total})>{};
  for (final item in items) {
    final at = progress[item.templateClientId] ?? (done: 0, total: 0);
    progress[item.templateClientId] = (
      done: at.done + (isChecklistItemSatisfied(item, inventoryById) ? 1 : 0),
      total: at.total + 1,
    );
  }
  return progress;
}
