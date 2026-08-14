import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show ChecklistCategory;

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/checklist_category_l10n.dart';
import '../application/checklist_controller.dart';
import '../application/checklist_providers.dart';
import '../application/checklist_sync_controller.dart';
import 'checklist_detail_screen.dart';

class ChecklistListScreen extends ConsumerWidget {
  const ChecklistListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(checklistSyncControllerProvider(householdId));
    final templatesAsync = ref.watch(checklistTemplatesProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklistsTitle)),
      body: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorGeneric(error.toString()))),
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
            : ListView.builder(
                itemCount: templates.length,
                itemBuilder: (context, index) => _TemplateTile(
                  template: templates[index],
                  householdId: householdId,
                  l10n: l10n,
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTemplateDialog(context, ref, l10n),
        icon: const Icon(Icons.add),
        label: Text(l10n.createTemplateButton),
      ),
    );
  }

  Future<void> _showCreateTemplateDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final titleController = TextEditingController();
    var category = ChecklistCategory.custom;

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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                if (title.isEmpty) return;
                ref
                    .read(checklistControllerProvider(householdId))
                    .createTemplate(title: title, category: category);
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

    return ListTile(
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
            items.where((i) => i.isChecked).length,
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
