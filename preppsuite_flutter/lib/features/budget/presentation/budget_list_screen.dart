import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../household/application/household_providers.dart';
import '../../inventory/application/inventory_category_l10n.dart';
import '../application/budget_providers.dart';
import '../application/missing_equipment_report.dart';
import 'budget_entry_form_screen.dart';
import '../../../core/error_text.dart';

class BudgetListScreen extends ConsumerWidget {
  const BudgetListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(budgetEntriesProvider(householdId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.budgetTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: l10n.exportPdfButton,
            onPressed: () => _exportMissingEquipmentPdf(context, ref),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(describeError(l10n, error))),
        data: (entries) => entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.budgetEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              )
            : Column(
                children: [
                  _TotalCard(entries: entries, l10n: l10n),
                  Expanded(
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) => _EntryTile(
                        entry: entries[index],
                        householdId: householdId,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BudgetEntryFormScreen(householdId: householdId),
          ),
        ),
        icon: const Icon(Icons.add),
        label: Text(l10n.addBudgetEntryButton),
      ),
    );
  }

  Future<void> _exportMissingEquipmentPdf(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final householdName = ref.read(householdProfileProvider).value?.name ?? '';
    final db = ref.read(appDatabaseProvider);

    final strings = MissingEquipmentReportStrings(
      title: l10n.pdfReportTitle,
      generatedOn: l10n.pdfGeneratedOn(
        DateFormat.yMMMMd(locale).add_Hm().format(DateTime.now()),
      ),
      checklistSectionTitle: l10n.pdfChecklistSectionTitle,
      noMissingChecklistItems: l10n.pdfNoMissingChecklistItems,
      inventorySectionTitle: l10n.pdfInventorySectionTitle,
      noLowStockItems: l10n.pdfNoLowStockItems,
      columnItem: l10n.pdfColumnItem,
      columnQuantity: l10n.pdfColumnQuantity,
      columnMinQuantity: l10n.pdfColumnMinQuantity,
      columnUnit: l10n.pdfColumnUnit,
    );

    await Printing.layoutPdf(
      onLayout: (_) => const MissingEquipmentReport().build(
        db: db,
        householdId: householdId,
        householdName: householdName,
        strings: strings,
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.entries, required this.l10n});

  final List<BudgetEntry> entries;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    // Entries could in principle mix currencies; v1 keeps this simple and
    // sums by the first entry's currency (multi-currency households are an
    // edge case, not the common one this feature targets).
    final currency = entries.first.currency;
    final totalCents = entries
        .where((e) => e.currency == currency)
        .fold<int>(0, (sum, e) => sum + e.amountCents);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.budgetTotalLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              formatMoney(totalCents, currency),
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  const _EntryTile({required this.entry, required this.householdId});

  final BudgetEntry entry;
  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = InventoryItemCategoryX.fromName(entry.category);

    return ListTile(
      leading: Icon(categoryIcon(category)),
      title: Text(entry.label),
      subtitle: entry.purchaseDate != null
          ? Text(
              MaterialLocalizations.of(
                context,
              ).formatMediumDate(entry.purchaseDate!),
            )
          : null,
      trailing: Text(
        formatMoney(entry.amountCents, entry.currency),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => BudgetEntryFormScreen(
            householdId: householdId,
            existing: entry,
          ),
        ),
      ),
    );
  }
}

String formatMoney(int amountCents, String currency) {
  final format = NumberFormat.currency(name: currency);
  return format.format(amountCents / 100);
}
