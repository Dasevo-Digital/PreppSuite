import '../../../local_db/database.dart';

bool isChecklistItemSatisfied(
  ChecklistItem item,
  Map<String, InventoryItem> inventoryById,
) {
  if (item.isChecked) return true;
  final linked = inventoryById[item.linkedInventoryItemId];
  if (linked == null || linked.quantity <= 0) return false;
  final target = item.targetQuantity;
  return target == null || target <= 0 || linked.quantity >= target;
}
