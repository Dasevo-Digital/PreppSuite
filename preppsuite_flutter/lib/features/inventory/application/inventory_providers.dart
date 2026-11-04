import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/calendar_day.dart';
import '../../../local_db/database.dart';
import 'inventory_filter.dart';

export '../../../core/app_database_providers.dart';

/// Live view of a household's (non-deleted) inventory items, straight from
/// Drift — updates instantly on local writes, before any network round-trip.
final inventoryItemsProvider = StreamProvider.autoDispose
    .family<List<InventoryItem>, String>(
      (ref, householdId) =>
          ref.watch(appDatabaseProvider).watchInventoryItems(householdId),
    );

/// Count of items that are either below their minimum quantity, past
/// their expiration date or due a battery check — drives the attention
/// badge on the Inventory nav destination in `HomeShell`, so low
/// stock/expiring items are surfaced proactively instead of only when a
/// user happens to open the list.
///
/// Counted by the inventory filter, so the badge and the list it leads to
/// agree on what wants looking at (#281), and again at midnight: it read
/// the clock when the rows last changed, so a tin that ran out overnight
/// came onto the badge only once something was edited (#282).
final inventoryAttentionCountProvider = Provider.autoDispose
    .family<int, String>((ref, householdId) {
      final itemsAsync = ref.watch(inventoryItemsProvider(householdId));
      final items = itemsAsync.value ?? const [];
      // Only the date counts here, so the day is the clock.
      return countNeedingAttention(items, now: ref.watch(calendarDayProvider));
    });
