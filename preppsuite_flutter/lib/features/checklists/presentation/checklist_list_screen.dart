import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../../budget/application/missing_equipment_report.dart';
import '../../household/application/household_providers.dart';
import '../application/checklist_category_l10n.dart';
import '../application/checklist_kind_l10n.dart';
import '../application/checklist_controller.dart';
import '../application/checklist_providers.dart';
import '../application/checklist_satisfaction.dart';
import '../../inventory/application/inventory_providers.dart';
import 'checklist_detail_screen.dart';
import '../../../core/error_text.dart';

class ChecklistListScreen extends ConsumerWidget {
  const ChecklistListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(checklistTemplatesProvider(householdId));

    // Two tabs rather than two headings down one list: the question
    // "what do I do now" is asked at a different moment from "what
    // should I have", and the answer to one must not be something to
    // scroll past to reach the other.
    return DefaultTabController(
      length: ChecklistKind.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.checklistsTitle),
          actions: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf_outlined),
              tooltip: l10n.exportPdfButton,
              onPressed: () => _exportMissingEquipmentPdf(context, ref),
            ),
          ],
          bottom: TabBar(
            tabs: [
              for (final kind in ChecklistKind.values)
                Tab(
                  icon: Icon(checklistKindIcon(kind)),
                  text: localizeChecklistKind(l10n, kind),
                ),
            ],
          ),
        ),
        body: templatesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text(describeError(l10n, error))),
          data: (templates) => templates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      l10n.checklistsEmpty,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                )
              : TabBarView(
                  children: [
                    for (final kind in ChecklistKind.values)
                      _GroupedTemplateList(
                        kind: kind,
                        templates: [
                          for (final template in templates)
                            if (ChecklistKind.fromName(template.kind) == kind)
                              template,
                        ],
                        householdId: householdId,
                        l10n: l10n,
                      ),
                  ],
                ),
        ),
        floatingActionButton: Builder(
          // Its own context, so the button can read which tab is open —
          // a new list almost always belongs in the part that is being
          // looked at, and asking again would be asking twice.
          builder: (context) => FloatingActionButton.extended(
            onPressed: () => _showCreateTemplateDialog(
              context,
              ref,
              l10n,
              ChecklistKind.values[DefaultTabController.of(context).index],
            ),
            icon: const Icon(Icons.add),
            label: Text(l10n.createTemplateButton),
          ),
        ),
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

  Future<void> _showCreateTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ChecklistKind initialKind,
  ) async {
    final titleController = TextEditingController();
    var category = ChecklistCategory.custom;
    var kind = initialKind;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(l10n.createTemplateTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(labelText: l10n.templateTitleLabel),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChecklistCategory>(
                isExpanded: true,
                initialValue: category,
                decoration: InputDecoration(labelText: l10n.categoryLabel),
                items: [
                  for (final value in ChecklistCategory.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(localizeChecklistCategory(l10n, value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => category = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ChecklistKind>(
                isExpanded: true,
                initialValue: kind,
                decoration: InputDecoration(
                  labelText: l10n.checklistKindLabel,
                  helperText: describeChecklistKind(l10n, kind),
                  helperMaxLines: 2,
                ),
                items: [
                  for (final value in ChecklistKind.values)
                    DropdownMenuItem(
                      value: value,
                      child: Text(localizeChecklistKind(l10n, value)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => kind = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                ref
                    .read(checklistControllerProvider(householdId))
                    .createTemplate(
                      title: title,
                      category: category,
                      kind: kind,
                    );
                Navigator.of(dialogContext).pop();
              },
              child: Text(l10n.createButton),
            ),
          ],
        ),
      ),
    );
  }
}

/// The templates under their category headings.
///
/// Flat was fine with three lists. With ten it is a wall, and the whole
/// point of the built-in set is that someone can see at a glance which
/// area they have not thought about yet.
class _GroupedTemplateList extends StatelessWidget {
  const _GroupedTemplateList({
    required this.kind,
    required this.templates,
    required this.householdId,
    required this.l10n,
  });

  final ChecklistKind kind;
  final List<ChecklistTemplate> templates;
  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.checklistKindEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Grouped in the enum's declaration order rather than the order rows
    // happen to come back in, so the sections do not move around when a
    // template is renamed.
    final byCategory = <ChecklistCategory, List<ChecklistTemplate>>{};
    for (final template in templates) {
      byCategory
          .putIfAbsent(
            ChecklistCategory.fromName(template.category),
            () => [],
          )
          .add(template);
    }

    final sections = [
      for (final category in ChecklistCategory.values)
        if (byCategory[category] != null) (category, byCategory[category]!),
    ];

    return ListView.builder(
      // One row ahead of the sections: the tab label is two words, and
      // two words are not enough to say which of the two lists somebody
      // is looking at.
      itemCount: sections.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              describeChecklistKind(l10n, kind),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final (category, group) = sections[index - 1];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                localizeChecklistCategory(l10n, category),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            for (final template in group)
              _TemplateTile(
                template: template,
                householdId: householdId,
                l10n: l10n,
              ),
          ],
        );
      },
    );
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({
    required this.template,
    required this.householdId,
    required this.l10n,
  });

  final ChecklistTemplate template;
  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(checklistItemsProvider(template.clientId));
    final inventory =
        ref.watch(inventoryItemsProvider(householdId)).value ?? const [];
    final inventoryById = {for (final item in inventory) item.clientId: item};

    return ListTile(
      leading: Icon(
        checklistCategoryIcon(ChecklistCategory.fromName(template.category)),
      ),
      title: Row(
        children: [
          Expanded(child: Text(template.title)),
          if (template.isBuiltIn)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Chip(
                label: Text(l10n.builtInBadge),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
      subtitle: itemsAsync.maybeWhen(
        data: (items) => Text(
          l10n.checklistProgress(
            items
                .where((i) => isChecklistItemSatisfied(i, inventoryById))
                .length,
            items.length,
          ),
        ),
        orElse: () => null,
      ),
      trailing: PopupMenuButton<_TemplateAction>(
        onSelected: (action) {
          final controller = ref.read(
            checklistControllerProvider(householdId),
          );
          switch (action) {
            case _TemplateAction.duplicate:
              controller.duplicateTemplate(template);
            case _TemplateAction.delete:
              controller.deleteTemplate(template);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _TemplateAction.duplicate,
            child: Text(l10n.duplicateTemplateAction),
          ),
          if (!template.isBuiltIn)
            PopupMenuItem(
              value: _TemplateAction.delete,
              child: Text(l10n.deleteTemplateAction),
            ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChecklistDetailScreen(
            template: template,
            householdId: householdId,
          ),
        ),
      ),
    );
  }
}

enum _TemplateAction { duplicate, delete }
