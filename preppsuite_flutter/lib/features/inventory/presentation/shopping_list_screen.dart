import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/calendar_day.dart';
import '../../../core/content_swap.dart';
import '../../../core/number_input.dart';
import '../../household/application/household_providers.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_numbers.dart';
import '../application/inventory_providers.dart';
import '../application/shopping_list.dart';
import '../application/shopping_list_export.dart';
import '../application/supply_calculator.dart';
import 'inventory_item_form_screen.dart';
import 'shopping_file_share.dart';
import '../../../core/error_text.dart';

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
  /// Lines ticked as bought, by item, until they are booked (#265).
  final _ticked = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(inventoryItemsProvider(widget.householdId));
    final profile = ref.watch(householdProfileProvider).value;
    final household = SupplyHousehold(
      adults: profile?.personCount ?? 1,
      children: profile?.children ?? 0,
      dogs: profile?.dogs ?? 0,
      cats: profile?.cats ?? 0,
    );
    // A pack in daily use runs lower every day without a write (#268).
    final today = ref.watch(calendarDayProvider);
    final items = itemsAsync.value;
    final shoppingList = items == null
        ? null
        : inventoryNumbersOrNull(
            () => buildShoppingList(
              items: items,
              days: widget.days,
              household: household,
              now: today,
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.shoppingListTitle),
        actions: [
          if (shoppingList != null && shoppingList.entries.isNotEmpty)
            IconButton(
              tooltip: l10n.shoppingListExport,
              icon: const Icon(Icons.file_upload_outlined),
              onPressed: () => _export(shoppingList, l10n),
            ),
        ],
      ),
      body: ContentSwap(
        child: itemsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(describeError(l10n, error))),
          data: (_) {
            // Worked out above, from the same items.
            final list = shoppingList;
            if (list == null) {
              return Center(child: Text(l10n.inventoryInvalidNumbers));
            }

            // Built by index rather than as a list of children. The items
            // section used to be a `Column` inside this `ListView`, and a
            // Column realises and lays out every child: at 300 entries —
            // which is an ordinary number for a household that stocks up —
            // that measured 201 ms against 12 ms, with all 300 tiles in the
            // element tree instead of the nine on screen.
            final entries = list.entries;
            // A line that has left the list -- booked, or filled up on
            // another device -- is no longer ticked.
            _ticked.retainWhere(
              (id) => entries.any((entry) => entry.item.clientId == id),
            );
            // The card, the heading, the entries (or the empty line), the
            // footnote.
            final rows = 3 + (entries.isEmpty ? 1 : entries.length);

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: rows,
              itemBuilder: (context, index) {
                if (index == 0) return _TargetCard(list: list, l10n: l10n);
                if (index == 1) return _ItemsHeading(l10n: l10n);
                if (index == rows - 1) return _MinimumsNote(l10n: l10n);
                if (entries.isEmpty) return _ItemsEmpty(l10n: l10n);
                final entry = entries[index - 2];
                return _ShortfallTile(
                  entry: entry,
                  l10n: l10n,
                  ticked: _ticked.contains(entry.item.clientId),
                  onTicked: (ticked) => setState(() {
                    ticked
                        ? _ticked.add(entry.item.clientId)
                        : _ticked.remove(entry.item.clientId);
                  }),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: shoppingList == null || _ticked.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton.icon(
                  onPressed: () => _book(shoppingList, l10n),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text(l10n.shoppingListBookTicked(_ticked.length)),
                ),
              ),
            ),
      floatingActionButton: shoppingList == null || shoppingList.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _copy(shoppingList, l10n),
              icon: const Icon(Icons.copy_all_outlined),
              label: Text(l10n.shoppingListCopy),
            ),
    );
  }

  /// What was bought, into the stock (#265).
  ///
  /// The list said what to buy; until now the stock only learned of the
  /// shopping one item and one form at a time. Each ticked line is
  /// offered at what it was short, which is what most people buy, and
  /// can be changed to what they did. One booking for all of them, and a
  /// way back for a slip.
  Future<void> _book(ShoppingList list, AppLocalizations l10n) async {
    final ticked = [
      for (final entry in list.entries)
        if (_ticked.contains(entry.item.clientId)) entry,
    ];
    final bought = await showDialog<Map<String, double>>(
      context: context,
      builder: (_) => _BookDialog(entries: ticked, l10n: l10n),
    );
    if (bought == null || bought.isEmpty || !mounted) return;
    final controller = ref.read(
      inventoryControllerProvider(widget.householdId),
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      final booked = await controller.bookPurchases(bought);
      if (!mounted) return;
      setState(() => _ticked.removeAll(booked.keys));
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.shoppingListBooked(booked.length)),
            action: SnackBarAction(
              label: l10n.undoAction,
              onPressed: () => controller.takeBackPurchases(booked),
            ),
          ),
        );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(describeError(l10n, error))),
      );
    }
  }

  /// The lines as a file, for a shopping app to put on a list of its own
  /// (#155) -- see `shopping_list_export.dart` for what is in it.
  Future<void> _export(ShoppingList list, AppLocalizations l10n) {
    final now = DateTime.now();
    return shareShoppingFile(
      context,
      now: now,
      content: buildShoppingListFile(
        list,
        now: now,
        language: Localizations.localeOf(context).languageCode,
        formatAmount: (value) => _number(value, l10n),
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
          '- ${l10n.shoppingListWaterGap(_number(list.waterShortfallLiters, l10n))}',
        );
      }
      if (list.calorieShortfall > 0) {
        lines.add(
          '- ${l10n.shoppingListEnergyGap(_integer(list.calorieShortfall, l10n))}',
        );
      }
      lines.add('');
    }
    for (final entry in list.entries) {
      lines.add(
        '- ${entry.item.name}: ${_number(entry.shortfall, l10n)} ${entry.item.unit}',
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
                    _number(list.waterShortfallLiters, l10n),
                  ),
                ),
              if (list.calorieShortfall > 0)
                _GapRow(
                  icon: Icons.local_fire_department_outlined,
                  text: l10n.shoppingListEnergyGap(
                    _integer(list.calorieShortfall, l10n),
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

/// The heading above the per-item lines.
class _ItemsHeading extends StatelessWidget {
  const _ItemsHeading({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        l10n.shoppingListItemsHeading,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _ItemsEmpty extends StatelessWidget {
  const _ItemsEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Text(l10n.shoppingListItemsEmpty),
    );
  }
}

/// Says why a stocked-looking household can show an empty list: the
/// minimums are what is being watched, and they are optional.
class _MinimumsNote extends StatelessWidget {
  const _MinimumsNote({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Text(
        l10n.shoppingListNoMinimums,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One item that is short of its own minimum.
class _ShortfallTile extends StatelessWidget {
  const _ShortfallTile({
    required this.entry,
    required this.l10n,
    required this.ticked,
    required this.onTicked,
  });

  final ShoppingListEntry entry;
  final AppLocalizations l10n;

  /// Ticked as bought, waiting to be booked.
  final bool ticked;
  final ValueChanged<bool> onTicked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.tertiaryContainer,
        foregroundColor: theme.colorScheme.onTertiaryContainer,
        child: const Icon(Icons.remove_shopping_cart_outlined, size: 18),
      ),
      title: Text(entry.item.name),
      subtitle: Text(
        l10n.shoppingListShortfall(
          _number(entry.shortfall, l10n),
          entry.item.unit,
          _number(entry.item.minQuantity ?? 0, l10n),
        ),
      ),
      trailing: Checkbox(
        value: ticked,
        semanticLabel: l10n.shoppingListBought,
        onChanged: (value) => onTicked(value ?? false),
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InventoryItemFormScreen(
            householdId: entry.item.householdId,
            existing: entry.item,
          ),
        ),
      ),
    );
  }
}

/// The amounts that were bought, one field a ticked line, each offered
/// at what that line was short.
class _BookDialog extends StatefulWidget {
  const _BookDialog({required this.entries, required this.l10n});

  final List<ShoppingListEntry> entries;
  final AppLocalizations l10n;

  @override
  State<_BookDialog> createState() => _BookDialogState();
}

class _BookDialogState extends State<_BookDialog> {
  late final _fields = {
    for (final entry in widget.entries)
      entry.item.clientId: TextEditingController(
        text: fieldNumber(entry.shortfall, widget.l10n.localeName),
      ),
  };
  final _wrong = <String>{};

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final bought = <String, double>{};
    final wrong = <String>{};
    for (final MapEntry(key: id, value: field) in _fields.entries) {
      final text = field.text.trim();
      // Left empty or at nought: not bought after all, and not booked.
      if (text.isEmpty) continue;
      final amount = readNonNegativeNumber(text);
      if (amount == null) {
        wrong.add(id);
      } else if (amount > 0) {
        bought[id] = amount;
      }
    }
    if (wrong.isNotEmpty) {
      setState(
        () => _wrong
          ..clear()
          ..addAll(wrong),
      );
      return;
    }
    Navigator.pop(context, bought);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.shoppingListBookTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.shoppingListBookHint),
            for (final entry in widget.entries)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextField(
                  controller: _fields[entry.item.clientId],
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: entry.item.name,
                    suffixText: entry.item.unit,
                    errorText: _wrong.contains(entry.item.clientId)
                        ? l10n.invalidNumber
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.shoppingListBookConfirm),
        ),
      ],
    );
  }
}

/// In the reader's own notation (#294). Without a locale `intl` writes
/// en_US, and "44,000 kcal" reads as forty-four to a German or Spanish
/// reader, for whom the comma is the decimal mark.
String _number(double value, AppLocalizations l10n) =>
    value == value.roundToDouble()
    ? NumberFormat.decimalPattern(l10n.localeName).format(value)
    : NumberFormat.decimalPatternDigits(
        locale: l10n.localeName,
        decimalDigits: 1,
      ).format(value);

String _integer(int value, AppLocalizations l10n) =>
    NumberFormat.decimalPattern(l10n.localeName).format(value);
