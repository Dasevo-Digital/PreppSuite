import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/person_count_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_category_l10n.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_providers.dart';
import '../application/inventory_sync_controller.dart';
import '../application/supply_calculator.dart';
import 'consume_dialog.dart';
import 'inventory_csv_import_screen.dart';
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
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: l10n.csvImportButton,
            onPressed: () async {
              final imported = await Navigator.of(context).push<int>(
                MaterialPageRoute(
                  builder: (_) =>
                      InventoryCsvImportScreen(householdId: householdId),
                ),
              );
              if (imported != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.csvImportSuccessMessage(imported)),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _SupplyCalculatorCard(householdId: householdId),
          Expanded(
            child: itemsAsync.when(
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
          ),
        ],
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

    final photoPath = item.photoPath;

    return ListTile(
      leading: photoPath != null
          ? CircleAvatar(backgroundImage: FileImage(File(photoPath)))
          : CircleAvatar(child: Icon(categoryIcon(category))),
      title: Text(item.name),
      subtitle: Text(
        '${_formatQuantity(item.quantity)} ${item.unit} · ${item.storageLocation}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
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
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
            ),
          // Only offered while there is something left to deduct.
          if (item.quantity > 0)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.consumeAction,
              onPressed: () => _showConsumeDialog(context, ref),
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

  Future<void> _showConsumeDialog(BuildContext context, WidgetRef ref) async {
    final amount = await showDialog<double>(
      context: context,
      builder: (_) => ConsumeDialog(item: item, l10n: l10n),
    );
    if (amount == null) return;

    await ref
        .read(inventoryControllerProvider(item.householdId))
        .consumeQuantity(item, amount);
  }

  String _formatQuantity(double quantity) {
    return quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toString();
  }
}

/// "Vorräte für X Tage" — target (BBK-recommended per-person-per-day
/// figures × person count × days) vs. current stock, as two progress
/// rings. See `supply_calculator.dart` for the actual math and its honest
/// limitations (only water/calories, only for items with countable units).
class _SupplyCalculatorCard extends ConsumerStatefulWidget {
  const _SupplyCalculatorCard({required this.householdId});

  final String householdId;

  @override
  ConsumerState<_SupplyCalculatorCard> createState() =>
      _SupplyCalculatorCardState();
}

class _SupplyCalculatorCardState extends ConsumerState<_SupplyCalculatorCard> {
  int _days = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items =
        ref.watch(inventoryItemsProvider(widget.householdId)).value ?? const [];
    final personCount = ref.watch(personCountProvider);
    final result = calculateSupply(
      items: items,
      personCount: personCount,
      days: _days,
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Stepper(
              label: l10n.supplyCalculatorPersonCountLabel,
              value: personCount,
              minValue: 1,
              onChanged: (value) =>
                  ref.read(personCountProvider.notifier).setPersonCount(value),
            ),
            const SizedBox(height: 8),
            _Stepper(
              label: l10n.supplyCalculatorDaysLabel(_days),
              value: _days,
              minValue: 1,
              onChanged: (value) => setState(() => _days = value),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SupplyRing(
                    label: l10n.supplyCalculatorWaterLabel,
                    current: result.waterCurrentLiters,
                    target: result.waterTargetLiters,
                    formatter: (value) => value.toStringAsFixed(1),
                    unit: 'L',
                    l10n: l10n,
                  ),
                ),
                Expanded(
                  child: _SupplyRing(
                    label: l10n.supplyCalculatorCaloriesLabel,
                    current: result.caloriesCurrent.toDouble(),
                    target: result.caloriesTarget.toDouble(),
                    formatter: (value) => value.toStringAsFixed(0),
                    unit: 'kcal',
                    l10n: l10n,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.minValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int minValue;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
        ),
        Text('$value', style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _SupplyRing extends StatelessWidget {
  const _SupplyRing({
    required this.label,
    required this.current,
    required this.target,
    required this.formatter,
    required this.unit,
    required this.l10n,
  });

  final String label;
  final double current;
  final double target;
  final String Function(double) formatter;
  final String unit;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.supplyCalculatorProgress(
                    formatter(current),
                    formatter(target),
                    unit,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
