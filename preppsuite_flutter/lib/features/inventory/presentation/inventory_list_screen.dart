import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_category_l10n.dart';
import '../application/inventory_providers.dart';
import '../application/inventory_sync_controller.dart';
import 'inventory_item_form_screen.dart';

class InventoryListScreen extends ConsumerWidget {
  const InventoryListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Watching this keeps the sync controller alive (initial + periodic +
    // debounced sync) for as long as this screen is on screen.
    ref.watch(inventorySyncControllerProvider(householdId));
    final itemsAsync = ref.watch(inventoryItemsProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inventoryTitle)),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorGeneric(error.toString()))),
        data: (items) => items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.inventoryEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _InventoryTile(item: items[index], l10n: l10n),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InventoryItemFormScreen(householdId: householdId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addItemButton),
      ),
    );
  }
}

class _InventoryTile extends ConsumerWidget {
  const _InventoryTile({required this.item, required this.l10n});

  final InventoryItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = InventoryItemCategoryX.fromName(item.category);
    final isLowStock =
        item.minQuantity != null && item.quantity < item.minQuantity!;
    final isExpired =
        item.expirationDate != null &&
        item.expirationDate!.isBefore(DateTime.now());

    return ListTile(
      leading: Icon(categoryIcon(category)),
      title: Text(item.name),
      subtitle: Text(
        '${_formatQuantity(item.quantity)} ${item.unit} · ${item.storageLocation}',
      ),
      trailing: !isLowStock && !isExpired
          ? null
          : Wrap(
              spacing: 4,
              children: [
                if (isExpired)
                  Chip(
                    label: Text(l10n.expiredBadge),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  ),
                if (isLowStock)
                  Chip(
                    label: Text(l10n.lowStockBadge),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        Theme.of(context).colorScheme.tertiaryContainer,
                  ),
              ],
            ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InventoryItemFormScreen(
            householdId: item.householdId,
            existing: item,
          ),
        ),
      ),
    );
  }

  String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toString();
  }
}
