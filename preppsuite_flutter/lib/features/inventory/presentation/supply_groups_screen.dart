import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../household/application/household_providers.dart';
import '../application/food_amount.dart';
import '../application/inventory_providers.dart';
import '../application/supply_group_l10n.dart';
import '../application/supply_groups.dart';

/// Whether the supply is more than calories.
///
/// A separate screen rather than seven more bars under the two that are
/// already on the inventory list. Most households look at this once, when
/// they build the stock, and then rarely — while the litres and the
/// kilocalories are looked at every time. A rare question does not belong
/// in the height where the first item of the list would be; that lesson
/// cost an afternoon once already.
///
/// Nothing here judges. Every row is the household's own amount beside the
/// BLE's own amount, and the two lists at the bottom name the rows that
/// are in neither — because a figure that quietly leaves rows out is worse
/// than no figure.
class SupplyGroupsScreen extends ConsumerStatefulWidget {
  const SupplyGroupsScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<SupplyGroupsScreen> createState() => _SupplyGroupsScreenState();
}

class _SupplyGroupsScreenState extends ConsumerState<SupplyGroupsScreen> {
  /// The same ten days the supply calculator starts at. Kept here rather
  /// than shared with that screen: the two are looked at in different
  /// sittings, and a stepper that moved behind your back on the other
  /// screen would be a surprise, not a convenience.
  int _days = 10;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items =
        ref.watch(inventoryItemsProvider(widget.householdId)).value ??
        const <InventoryItem>[];
    final profile = ref.watch(householdProfileProvider).value;
    // The BLE counts heads, not ages -- its own table makes no
    // distinction, and inventing one here would be a figure of this
    // app's own.
    final persons = (profile?.personCount ?? 1) + (profile?.children ?? 0);
    final result = supplyGroupCoverage(
      items: items,
      persons: persons,
      days: _days,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.supplyGroupsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(l10n.supplyGroupsIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(l10n.supplyCalculatorDaysLabel(_days)),
              ),
              IconButton(
                tooltip: l10n.stepperDecrease(
                  l10n.supplyCalculatorDaysLabel(_days),
                ),
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _days > 1 ? () => setState(() => _days--) : null,
              ),
              IconButton(
                tooltip: l10n.stepperIncrease(
                  l10n.supplyCalculatorDaysLabel(_days),
                ),
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _days++),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final row in result.coverage) _GroupRow(row: row, l10n: l10n),
          const SizedBox(height: 8),
          Text(
            l10n.supplyGroupsPersonsNote,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          if (result.unassigned.isEmpty && result.unmeasurable.isEmpty)
            Text(
              l10n.supplyGroupsAllAssigned,
              style: theme.textTheme.bodyMedium,
            ),
          if (result.unassigned.isNotEmpty)
            _Missing(
              title: l10n.supplyGroupsUnassignedTitle,
              body: l10n.supplyGroupsUnassignedBody,
              items: result.unassigned,
            ),
          if (result.unmeasurable.isNotEmpty)
            _Missing(
              title: l10n.supplyGroupsUnmeasuredTitle,
              body: l10n.supplyGroupsUnmeasuredBody,
              items: result.unmeasurable,
            ),
          const SizedBox(height: 16),
          Text(l10n.supplyGroupsSource, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.row, required this.l10n});

  final SupplyGroupCoverage row;
  final AppLocalizations l10n;

  /// Grams become kilograms and millilitres litres above a thousand,
  /// because "0,33 kg" is the BLE's own way of writing it and "330 g"
  /// would make the reader do the conversion the table already did.
  String _amount(double value) {
    final kilo = row.base == FoodBase.mass;
    if (value >= 1000) {
      final big = value / 1000;
      return '${big.toStringAsFixed(big >= 10 ? 0 : 1).replaceAll('.', ',')}'
          ' ${kilo ? 'kg' : 'l'}';
    }
    return '${value.toStringAsFixed(0)} ${kilo ? 'g' : 'ml'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizeSupplyGroup(l10n, row.group),
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.supplyGroupsShare(_amount(row.have), _amount(row.target)),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 6),
          // Clamped only for drawing. The number above it is not, so a
          // household with three times the vegetables still reads three
          // times, and the bar simply stops being informative past the
          // end — which is the honest thing for a bar to do.
          LinearProgressIndicator(
            value: row.share.clamp(0.0, 1.0),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({
    required this.title,
    required this.body,
    required this.items,
  });

  final String title;
  final String body;
  final List<InventoryItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('· ${item.name}'),
              ),
          ],
        ),
      ),
    );
  }
}
