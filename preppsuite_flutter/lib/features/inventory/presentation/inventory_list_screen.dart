import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import 'unit_info_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../../../local_db/database.dart';
import '../../household/application/household_providers.dart';
import '../application/inventory_category_l10n.dart';
import '../application/charge_reminder_provider.dart';
import '../application/expiry_reminder_provider.dart';
import '../application/inventory_calendar_export.dart';
import '../application/inventory_csv_export.dart';
import '../application/inventory_controller.dart';
import '../application/inventory_providers.dart';
import '../../energy/presentation/energy_screen.dart';
import '../application/inventory_photo_service.dart';
import 'barcode_scanner_screen.dart';
import 'rotation_screen.dart';
import 'shopping_list_screen.dart';
import '../application/supply_calculator.dart';
import '../application/item_package.dart';
import 'consume_dialog.dart';
import 'inventory_csv_import_screen.dart';
import 'inventory_item_form_screen.dart';
import 'medication_range_screen.dart';
import 'storage_tips_screen.dart';
import 'water_treatment_screen.dart';
import '../application/inventory_filter.dart';
import 'inventory_filter_sheet.dart';
import 'package:intl/intl.dart';
import '../../../core/error_text.dart';
import '../../../core/save_file.dart';
import 'stored_photo_image.dart';

enum _InventoryMenuAction {
  consumeByScan,
  medication,
  energy,
  storageTips,
  waterTreatment,
  exportCsv,
  exportCalendar,
  importCsv,
}

class InventoryListScreen extends ConsumerStatefulWidget {
  const InventoryListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<InventoryListScreen> createState() =>
      _InventoryListScreenState();
}

class _InventoryListScreenState extends ConsumerState<InventoryListScreen> {
  final _searchController = TextEditingController();
  InventoryFilter _filter = const InventoryFilter();
  String get householdId => widget.householdId;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // debounced sync) for as long as this screen is on screen.
    final itemsAsync = ref.watch(inventoryItemsProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inventoryTitle),
        // The two errands come first as their own buttons; everything
        // else is a thing you do once in a while and lives in the menu.
        // Five icons in a row would make none of them findable.
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: l10n.shoppingListTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ShoppingListScreen(householdId: householdId),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.schedule),
            tooltip: l10n.rotationTitle,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RotationScreen(householdId: householdId),
              ),
            ),
          ),
          PopupMenuButton<_InventoryMenuAction>(
            onSelected: (action) =>
                _runMenuAction(context, ref, householdId, l10n, action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _InventoryMenuAction.consumeByScan,
                child: ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: Text(l10n.consumeScanAction),
                ),
              ),
              // Beside the storage tips rather than in the stock list:
              // it is the same question — how long does this last — for
              // everything the stock list cannot count, because a
              // cartridge has no calories and a candle has no expiry
              // date.
              PopupMenuItem(
                value: _InventoryMenuAction.medication,
                child: ListTile(
                  leading: const Icon(Icons.medication_outlined),
                  title: Text(l10n.medicationTitle),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.energy,
                child: ListTile(
                  leading: const Icon(Icons.bolt_outlined),
                  title: Text(l10n.energyTitle),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.storageTips,
                child: ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: Text(l10n.storageTipsTitle),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.waterTreatment,
                child: ListTile(
                  leading: const Icon(Icons.water_drop_outlined),
                  title: Text(l10n.waterTreatmentTitle),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.exportCsv,
                child: ListTile(
                  leading: const Icon(Icons.download),
                  title: Text(l10n.csvExportButton),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.exportCalendar,
                child: ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(l10n.calendarExportButton),
                ),
              ),
              PopupMenuItem(
                value: _InventoryMenuAction.importCsv,
                child: ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: Text(l10n.csvImportButton),
                ),
              ),
            ],
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _SupplyCalculatorCard(householdId: householdId),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l10n.inventorySearchHint,
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                            suffixIcon: _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: l10n.inventoryClearSearch,
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        setState(_searchController.clear),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: l10n.inventoryFilters,
                        icon: Icon(
                          _filter.isActive
                              ? Icons.filter_alt
                              : Icons.filter_alt_outlined,
                        ),
                        onPressed: () async {
                          final filter =
                              await showModalBottomSheet<InventoryFilter>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (_) => InventoryFilterSheet(
                                  initial: _filter,
                                  items: itemsAsync.value ?? [],
                                ),
                              );
                          if (filter != null && mounted) {
                            setState(() => _filter = filter);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                if (_filter.isActive)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InputChip(
                        label: Text(l10n.inventoryFiltersActive),
                        onDeleted: () =>
                            setState(() => _filter = const InventoryFilter()),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        body: ContentSwap(
          child: itemsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text(describeError(l10n, error))),
            data: (allItems) {
              final items = filterInventory(
                allItems,
                query: _searchController.text,
                filter: _filter,
              );
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      allItems.isEmpty
                          ? l10n.inventoryEmpty
                          : l10n.inventoryNoMatches,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: items.length,
                itemBuilder: (context, index) =>
                    _InventoryTile(item: items[index], l10n: l10n),
              );
            },
          ),
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

  Future<void> _runMenuAction(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    AppLocalizations l10n,
    _InventoryMenuAction action,
  ) async {
    switch (action) {
      case _InventoryMenuAction.consumeByScan:
        await _consumeByScan(context, ref, householdId, l10n);
      case _InventoryMenuAction.medication:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MedicationRangeScreen(householdId: householdId),
          ),
        );
      case _InventoryMenuAction.energy:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const EnergyScreen()),
        );
      case _InventoryMenuAction.storageTips:
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StorageTipsScreen(householdId: householdId),
          ),
        );
      case _InventoryMenuAction.waterTreatment:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const WaterTreatmentScreen(),
          ),
        );
      case _InventoryMenuAction.exportCsv:
        await _exportCsv(context, ref, householdId, l10n);
      case _InventoryMenuAction.exportCalendar:
        await _exportCalendar(context, ref, householdId, l10n);
      case _InventoryMenuAction.importCsv:
        final imported = await Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (_) => InventoryCsvImportScreen(householdId: householdId),
          ),
        );
        if (imported != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.csvImportSuccessMessage(imported))),
          );
        }
    }
  }

  /// Books a consumption from the barcode, the way it was added.
  ///
  /// Adding a tin by scanning and then deducting it by hand through a form
  /// is the asymmetry that makes a stock drift away from the shelf: one
  /// direction takes a second, the other takes a minute, so only one of
  /// them gets done.
  Future<void> _consumeByScan(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    AppLocalizations l10n,
  ) async {
    final barcode =
        await Navigator.of(
          context,
        ).push<String>(
          MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
        );
    if (barcode == null || !context.mounted) return;

    final item = await ref
        .read(appDatabaseProvider)
        .findInventoryItemByBarcode(householdId, barcode);
    if (!context.mounted) return;

    if (item == null) {
      // Naming the code matters: it is the one piece of the failure the
      // reader can check against the packet in their hand.
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.consumeScanNotFound(barcode))),
        );
      return;
    }

    final amount = await showDialog<double>(
      context: context,
      builder: (_) => ConsumeDialog(item: item, l10n: l10n),
    );
    if (amount == null) return;

    await ref
        .read(inventoryControllerProvider(householdId))
        .consumeQuantity(item, amount);
  }

  /// Writes the whole inventory out as CSV, in the format the importer
  /// reads back — see `inventory_csv_export.dart`.
  /// Writes the expiry dates and the battery check as an `.ics` file for
  /// a household calendar -- see `inventory_calendar_export.dart` (#102).
  Future<void> _exportCalendar(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final items =
        ref.read(inventoryItemsProvider(householdId)).value ?? const [];
    final calendar = buildInventoryCalendar(
      items: items,
      householdLeadDays: ref.read(expiryLeadDaysProvider),
      charge: ref.read(chargeCheckProvider),
      expiryTitle: (item) => l10n.calendarExpiryTitle(item.name),
      chargeTitle: l10n.chargeReminderTitle,
      chargeDescription: l10n.chargeReminderBody,
    );
    if (calendar == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.calendarExportEmpty)),
      );
      return;
    }

    try {
      final saved = await saveFileWithPicker(
        dialogTitle: l10n.calendarExportDialogTitle,
        fileName: 'preppsuite-ablaufdaten.ics',
        extension: 'ics',
        bytes: utf8.encode(calendar),
      );
      if (!saved) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.calendarExportSuccess(calendarItemCount(items)),
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.csvExportErrorMessage} ${describeError(l10n, error)}',
          ),
        ),
      );
    }
  }

  Future<void> _exportCsv(
    BuildContext context,
    WidgetRef ref,
    String householdId,
    AppLocalizations l10n,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final items =
        ref.read(inventoryItemsProvider(householdId)).value ?? const [];

    if (items.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.csvExportEmptyMessage)),
      );
      return;
    }

    // Encoded here rather than handed over as a string: file_picker wants
    // bytes, and this way the file is written exactly as built.
    final bytes = utf8.encode(buildInventoryCsv(items));

    try {
      final saved = await saveFileWithPicker(
        dialogTitle: l10n.csvExportDialogTitle,
        fileName: 'preppsuite-vorraete.csv',
        extension: 'csv',
        bytes: bytes,
      );
      if (!saved) return;

      messenger.showSnackBar(
        SnackBar(content: Text(l10n.csvExportSuccessMessage(items.length))),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.csvExportErrorMessage} ${describeError(l10n, error)}',
          ),
        ),
      );
    }
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
    final now = DateTime.now();
    final isExpired =
        item.expirationDate?.isBefore(DateTime(now.year, now.month, now.day)) ??
        false;

    final photoPath = item.photoPath;

    return ListTile(
      leading: photoPath != null
          ? CircleAvatar(
              backgroundImage: ResizeImage.resizeIfNeeded(
                96,
                96,
                StoredPhotoImage(
                  InventoryPhotoService.resolvePhotoPath(photoPath),
                ),
              ),
            )
          : CircleAvatar(child: Icon(categoryIcon(category))),
      title: Text(item.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              '${_formatQuantity(item.quantity)} ${item.unit}',
              ?_packages(item),
              item.storageLocation,
            ].join(' · '),
          ),
          if (isExpired || isLowStock)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (isExpired)
                    Chip(
                      label: Text(l10n.expiredBadge),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.errorContainer,
                    ),
                  if (isLowStock)
                    Chip(
                      label: Text(l10n.lowStockBadge),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer,
                    ),
                ],
              ),
            ),
        ],
      ),
      trailing: item.quantity > 0
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.consumeAction,
              onPressed: () => _showConsumeDialog(context, ref),
            )
          : null,
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
    return NumberFormat.decimalPattern(l10n.localeName).format(quantity);
  }

  /// "3 × Glas", or "≈ 2,7 × Glas" when the stock is not whole jars.
  /// Null for an item without a package, and for one used up entirely.
  String? _packages(InventoryItem item) {
    final package = ItemPackage.of(item);
    if (package == null || item.quantity <= 0) return null;
    final (:count, :exact) = packageCount(item.quantity, package);
    final formatted = _formatQuantity(count);
    return exact
        ? l10n.inventoryPackageCount(formatted, package.name)
        : l10n.inventoryPackageCountApprox(formatted, package.name);
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
    // Who lives here is a property of the household, not of this screen.
    // It used to be a second, device-local number kept beside the
    // household's own, and the two silently disagreed.
    final profile = ref.watch(householdProfileProvider).value;
    final household = SupplyHousehold(
      adults: profile?.personCount ?? 1,
      children: profile?.children ?? 0,
      dogs: profile?.dogs ?? 0,
      cats: profile?.cats ?? 0,
    );
    final result = calculateSupply(
      items: items,
      days: _days,
      household: household,
    );

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HouseholdLine(household: household, l10n: l10n),
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
                    formatter: (value) => NumberFormat.decimalPatternDigits(
                      locale: l10n.localeName,
                      decimalDigits: 1,
                    ).format(value),
                    unit: 'L',
                    l10n: l10n,
                  ),
                ),
                Expanded(
                  child: _SupplyRing(
                    label: l10n.supplyCalculatorCaloriesLabel,
                    current: result.caloriesCurrent.toDouble(),
                    target: result.caloriesTarget.toDouble(),
                    formatter: (value) => NumberFormat.decimalPattern(
                      l10n.localeName,
                    ).format(value),
                    unit: 'kcal',
                    l10n: l10n,
                  ),
                ),
              ],
            ),
            if (foodWithoutMeasure(items) case final uncounted
                when uncounted.isNotEmpty) ...[
              const SizedBox(height: 4),
              _UnmeasuredNotice(count: uncounted.length, l10n: l10n),
            ],
          ],
        ),
      ),
    );
  }
}

/// Says who the targets are for and where that is decided.
///
/// A line rather than a control: the counts belong to the household, and
/// two places to set them is how they came to disagree in the first
/// place.
class _HouseholdLine extends StatelessWidget {
  const _HouseholdLine({required this.household, required this.l10n});

  final SupplyHousehold household;
  final AppLocalizations l10n;

  String _who() {
    final parts = [
      for (final head in household.present)
        switch (head) {
          SupplyHead.adult => l10n.supplyCalculatorAdults(
            '${household.adults}',
          ),
          SupplyHead.child => l10n.supplyCalculatorChildren(
            '${household.children}',
          ),
          SupplyHead.dog => l10n.supplyCalculatorDogs('${household.dogs}'),
          SupplyHead.cat => l10n.supplyCalculatorCats('${household.cats}'),
        },
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.groups_outlined,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l10n.supplyCalculatorHouseholdLine(_who()),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (household.hasPets) ...[
          const SizedBox(height: 4),
          Text(
            l10n.supplyCalculatorPetFoodNote,
            style: theme.textTheme.bodySmall,
          ),
        ],
        // Shown to everyone, because age is not in the profile and the
        // app therefore cannot know whether it applies. A line that says
        // "add more if this is you" is the honest version of a number the
        // app would otherwise have to guess at.
        const SizedBox(height: 4),
        Text(
          l10n.supplyCalculatorSeniorNote,
          style: theme.textTheme.bodySmall,
        ),
      ],
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
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          tooltip: l10n.stepperDecrease(label),
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium,
          // Read on its own, the number is just a number. The label sits
          // three widgets away and a screen reader does not connect them.
          semanticsLabel: l10n.stepperValue(label, value),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          tooltip: l10n.stepperIncrease(label),
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

/// Food the supply calculator has to leave out, and where to read why.
///
/// The household decided this rather than the app: a row counted in
/// tins keeps its tin. What was missing was anybody being told — the
/// wording for this has existed since the per-100 g change and was
/// never put on a screen, so rows fell quietly out of the calculation
/// and the total looked like the whole pantry.
///
/// **A footnote inside the supply card, not a card beside it.** It
/// belongs to the figure it qualifies, and a card of its own cost the
/// whole list its height: on a short screen that pushed the first
/// item\'s buttons underneath the floating action button, which is a
/// worse fault than the one it was reporting.
///
/// One line, and the paragraph behind a tap. It will sit there every
/// time the inventory is opened until somebody changes a unit, and a
/// paragraph in that position is a paragraph people learn to skip.
class _UnmeasuredNotice extends StatelessWidget {
  const _UnmeasuredNotice({required this.count, required this.l10n});

  final int count;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.small),
      onTap: () => showUnitInfo(context, uncounted: count),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.scale_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.foodWithoutMeasureTitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.unitInfoAction,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
