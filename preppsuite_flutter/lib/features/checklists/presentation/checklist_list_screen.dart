import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/checklist_category_l10n.dart';
import '../application/checklist_controller.dart';
import '../application/checklist_providers.dart';
import 'checklist_detail_screen.dart';
import '../../../core/error_text.dart';

class ChecklistListScreen extends ConsumerWidget {
  const ChecklistListScreen({super.key, required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final templatesAsync = ref.watch(checklistTemplatesProvider(householdId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.checklistsTitle)),
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
            : _GroupedTemplateList(
                templates: templates,
                householdId: householdId,
                l10n: l10n,
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

/// The templates under their category headings.
///
/// Flat was fine with three lists. With ten it is a wall, and the whole
/// point of the built-in set is that someone can see at a glance which
/// area they have not thought about yet.
class _GroupedTemplateList extends StatelessWidget {
  const _GroupedTemplateList({
    required this.templates,
    required this.householdId,
    required this.l10n,
  });

  final List<ChecklistTemplate> templates;
  final String householdId;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
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
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final (category, group) = sections[index];
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
