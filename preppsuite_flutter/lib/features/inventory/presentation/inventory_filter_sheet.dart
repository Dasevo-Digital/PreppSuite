import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../application/inventory_category_l10n.dart';
import '../application/inventory_filter.dart';

class InventoryFilterSheet extends StatefulWidget {
  const InventoryFilterSheet({
    super.key,
    required this.initial,
    required this.items,
  });
  final InventoryFilter initial;
  final List<InventoryItem> items;
  @override
  State<InventoryFilterSheet> createState() => _InventoryFilterSheetState();
}

class _InventoryFilterSheetState extends State<InventoryFilterSheet> {
  late String? _category = widget.initial.category;
  late String? _location = widget.initial.location;
  late InventoryStatusFilter _status = widget.initial.status;
  late InventorySort _sort = widget.initial.sort;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locations = {
      for (final item in widget.items) item.storageLocation,
      ?_location,
    }.toList()..sort();
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.inventoryFilters,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.inventoryFilterCategory,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.inventoryFilterAll),
                ),
                for (final category in InventoryItemCategory.values)
                  DropdownMenuItem(
                    value: category.name,
                    child: Text(localizeCategory(l10n, category)),
                  ),
              ],
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _location,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.inventoryFilterLocation,
              ),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(l10n.inventoryFilterAll),
                ),
                for (final location in locations)
                  DropdownMenuItem(
                    value: location,
                    child: Text(
                      location.isEmpty ? l10n.inventoryNoLocation : location,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _location = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventoryStatusFilter>(
              initialValue: _status,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.inventoryFilterStatus,
              ),
              items: [
                for (final status in InventoryStatusFilter.values)
                  DropdownMenuItem(
                    value: status,
                    child: Text(switch (status) {
                      InventoryStatusFilter.all => l10n.inventoryFilterAll,
                      InventoryStatusFilter.expired => l10n.expiredBadge,
                      InventoryStatusFilter.expiring =>
                        l10n.inventoryExpiringSoon,
                      InventoryStatusFilter.lowStock => l10n.lowStockBadge,
                    }),
                  ),
              ],
              onChanged: (value) => setState(() => _status = value!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<InventorySort>(
              initialValue: _sort,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.inventorySortLabel),
              items: [
                for (final sort in InventorySort.values)
                  DropdownMenuItem(
                    value: sort,
                    child: Text(switch (sort) {
                      InventorySort.name => l10n.inventorySortName,
                      InventorySort.expiry => l10n.inventorySortExpiry,
                      InventorySort.attention => l10n.inventorySortAttention,
                    }),
                  ),
              ],
              onChanged: (value) => setState(() => _sort = value!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                InventoryFilter(
                  category: _category,
                  location: _location,
                  status: _status,
                  sort: _sort,
                ),
              ),
              child: Text(l10n.inventoryApplyFilters),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, const InventoryFilter()),
              child: Text(l10n.inventoryResetFilters),
            ),
          ],
        ),
      ),
    );
  }
}
