import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/checklist_controller.dart';
import '../application/checklist_providers.dart';

class ChecklistDetailScreen extends ConsumerStatefulWidget {
  const ChecklistDetailScreen({
    super.key,
    required this.template,
    required this.householdId,
  });

  final ChecklistTemplate template;
  final String householdId;

  @override
  ConsumerState<ChecklistDetailScreen> createState() =>
      _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends ConsumerState<ChecklistDetailScreen> {
  final _newItemController = TextEditingController();

  @override
  void dispose() {
    _newItemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final title = _newItemController.text.trim();
    if (title.isEmpty) return;
    ref
        .read(checklistControllerProvider(widget.householdId))
        .addItem(templateClientId: widget.template.clientId, title: title);
    _newItemController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(
      checklistItemsProvider(widget.template.clientId),
    );
    final controller = ref.read(
      checklistControllerProvider(widget.householdId),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.template.title)),
      body: Column(
        children: [
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) =>
                  Center(child: Text(l10n.errorGeneric(error.toString()))),
              data: (items) => ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return CheckboxListTile(
                    value: item.isChecked,
                    onChanged: (_) => controller.toggleItem(item),
                    title: Text(
                      item.title,
                      style: item.isChecked
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            )
                          : null,
                    ),
                    secondary: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => controller.deleteItem(item),
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newItemController,
                      decoration: InputDecoration(
                        hintText: l10n.addChecklistItemHint,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _addItem,
                    child: Text(l10n.addButton),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
