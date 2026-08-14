import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

export '../../../core/app_database_providers.dart';

/// Live view of a household's (non-deleted) inventory items, straight from
/// Drift — updates instantly on local writes, before any network round-trip.
final inventoryItemsProvider = StreamProvider.autoDispose
    .family<List<InventoryItem>, String>(
      (ref, householdId) =>
          ref.watch(appDatabaseProvider).watchInventoryItems(householdId),
    );

/// Count of items that are either below their minimum quantity or past
/// their expiration date — drives the attention badge on the Inventory nav
/// destination in `HomeShell`, so low stock/expiring items are surfaced
/// proactively instead of only when a user happens to open the list.
final inventoryAttentionCountProvider = Provider.autoDispose
    .family<int, String>((ref, householdId) {
      final itemsAsync = ref.watch(inventoryItemsProvider(householdId));
      final items = itemsAsync.value ?? const [];
      final now = DateTime.now();
      return items.where((item) {
        final isLowStock =
            item.minQuantity != null && item.quantity < item.minQuantity!;
        final isExpired =
            item.expirationDate != null && item.expirationDate!.isBefore(now);
        return isLowStock || isExpired;
      }).length;
    });
