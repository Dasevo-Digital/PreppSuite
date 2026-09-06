import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../household/application/household_providers.dart';
import '../application/inventory_providers.dart';
import '../application/shopping_list.dart';
import '../application/supply_calculator.dart';
import 'inventory_item_form_screen.dart';

/// What to buy.
///
/// Two answers, kept apart because they are different questions. The gap
/// to the household target says whether the stores would carry everyone
/// through the planned days; the lines below say what goes in a basket.
/// A household can meet the first and still be out of tinned tomatoes.
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({
    super.key,
    required this.householdId,
    this.days = 10,
  });

  final String householdId;

  /// The BBK's ten days, and the same horizon the supply card uses.
  final int days;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(inventoryItemsProvider(widget.householdId));
    final profile = ref.watch(householdProfileProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shoppingListTitle)),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.errorGeneric('$error'))),
        data: (items) {
          final list = buildShoppingList(
            items: items,
            days: widget.days,
            household: SupplyHousehold(
              adults: profile?.personCount ?? 1,
              children: profile?.children ?? 0,
              dogs: profile?.dogs ?? 0,
              cats: profile?.cats ?? 0,
            ),
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              _TargetCard(list: list, l10n: l10n),
              _ItemsSection(list: list, l10n: l10n),
            ],
          );
        },
      ),
      floatingActionButton: itemsAsync.maybeWhen(
        data: (items) {
          final list = buildShoppingList(
            items: items,
            days: widget.days,
            household: SupplyHousehold(
              adults: profile?.personCount ?? 1,
              children: profile?.children ?? 0,
              dogs: profile?.dogs ?? 0,
              cats: profile?.cats ?? 0,
            ),
          );
          if (list.isEmpty) return null;
          return FloatingActionButton.extended(
            onPressed: () => _copy(list, l10n),
            icon: const Icon(Icons.copy_all_outlined),
            label: Text(l10n.shoppingListCopy),
          );
        },
        orElse: () => null,
      ),
    );
  }

  /// A list you take to a shop has to leave the app. Plain text goes into
  /// a notes app, a message or a printer without anything in between.
  Future<void> _copy(ShoppingList list, AppLocalizations l10n) async {
    final lines = <String>[l10n.shoppingListTitle, ''];
    if (!list.targetMet) {
      if (list.waterShortfallLiters > 0) {
        lines.add(
          '- ${l10n.shoppingListWaterGap(_number(list.waterShortfallLiters))}',
        );
      }
      if (list.calorieShortfall > 0) {
        lines.add(
          '- ${l10n.shoppingListEnergyGap(_integer(list.calorieShortfall))}',
        );
      }
      lines.add('');
    }
    for (final entry in list.entries) {
      lines.add(
        '- ${entry.item.name}: ${_number(entry.shortfall)} ${entry.item.unit}',
      );
    }

    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.shoppingListCopied)));
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.list, required this.l10n});

  final ShoppingList list;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shoppingListTargetHeading(list.days),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (list.daysCovered == null)
              Text(l10n.shoppingListDaysUnknown)
            else
              Text(l10n.shoppingListDaysCovered(list.daysCovered!, list.days)),
            const SizedBox(height: 8),
            if (list.targetMet)
              Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.shoppingListTargetMet(list.days))),
                ],
              )
            else ...[
              if (list.waterShortfallLiters > 0)
                _GapRow(
                  icon: Icons.water_drop_outlined,
                  text: l10n.shoppingListWaterGap(
                    _number(list.waterShortfallLiters),
                  ),
                ),
              if (list.calorieShortfall > 0)
                _GapRow(
                  icon: Icons.local_fire_department_outlined,
                  text: l10n.shoppingListEnergyGap(
                    _integer(list.calorieShortfall),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection({required this.list, required this.l10n});

  final ShoppingList list;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            l10n.shoppingListItemsHeading,
            style: theme.textTheme.titleMedium,
          ),
        ),
        if (list.entries.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(l10n.shoppingListItemsEmpty),
          )
        else
          for (final entry in list.entries)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
                child: const Icon(
                  Icons.remove_shopping_cart_outlined,
                  size: 18,
                ),
              ),
              title: Text(entry.item.name),
              subtitle: Text(
                l10n.shoppingListShortfall(
                  _number(entry.shortfall),
                  entry.item.unit,
                  _number(entry.item.minQuantity ?? 0),
                ),
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InventoryItemFormScreen(
                    householdId: entry.item.householdId,
                    existing: entry.item,
                  ),
                ),
              ),
            ),
        // Says why a stocked-looking household can show an empty list:
        // the minimums are what is being watched, and they are optional.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            l10n.shoppingListNoMinimums,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

String _number(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : NumberFormat.decimalPatternDigits(decimalDigits: 1).format(value);

String _integer(int value) => NumberFormat.decimalPattern().format(value);
