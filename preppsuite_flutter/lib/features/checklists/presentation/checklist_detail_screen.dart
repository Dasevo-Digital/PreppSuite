import 'package:flutter/material.dart';

import '../../../core/feel.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../core/content_swap.dart';
import '../../../local_db/database.dart';
import '../application/built_in_template_l10n.dart';
import '../application/checklist_controller.dart';
import '../application/checklist_providers.dart';
import '../application/checklist_satisfaction.dart';
import '../../inventory/application/inventory_providers.dart';
import '../../inventory/presentation/supply_groups_screen.dart';
import '../../../model/categories.dart';
import '../../../core/error_text.dart';

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

  /// A list about food: the BLE's groups per person, which the
  /// supply-groups screen sets against the household's own stores (#31).
  bool get _food =>
      ChecklistCategory.values.asNameMap()[widget.template.category] ==
      ChecklistCategory.food;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync = ref.watch(
      checklistItemsProvider(widget.template.clientId),
    );
    final controller = ref.read(
      checklistControllerProvider(widget.householdId),
    );
    final inventory =
        ref.watch(inventoryItemsProvider(widget.householdId)).value ?? const [];
    final inventoryById = {for (final item in inventory) item.clientId: item};
    final language = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(widget.template.titleIn(language))),
      body: Column(
        children: [
          Expanded(
            child: ContentSwap(
              child: itemsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text(describeError(l10n, error))),
                data: (items) => ListView.builder(
                  itemCount: items.length + (_food ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_food) {
                      if (index == 0) {
                        return _SupplyGroupsLink(
                          householdId: widget.householdId,
                        );
                      }
                      index -= 1;
                    }
                    final item = items[index];
                    final linked = inventoryById[item.linkedInventoryItemId];
                    final complete = isChecklistItemSatisfied(
                      item,
                      inventoryById,
                    );
                    final supplied = complete && !item.isChecked;
                    return CheckboxListTile(
                      value: complete,
                      onChanged: supplied
                          ? null
                          : (_) {
                              // Packing a Notgepäck is one hand on the
                              // phone and one in a cupboard.
                              Feel.chose();
                              controller.toggleItem(item);
                            },
                      title: Text(
                        item.titleIn(language),
                        style: complete
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                              )
                            : null,
                      ),
                      subtitle: linked == null
                          ? null
                          : Text(
                              l10n.checklistLinkedStock(
                                linked.name,
                                linked.quantity,
                                linked.unit,
                              ),
                            ),
                      secondary: PopupMenuButton<_ItemAction>(
                        tooltip: l10n.moreActions,
                        onSelected: (action) async {
                          switch (action) {
                            case _ItemAction.link:
                              final id = await _chooseInventoryItem(
                                context,
                                inventory,
                                item.linkedInventoryItemId,
                                l10n,
                              );
                              if (id != null) {
                                await controller.linkInventoryItem(
                                  item,
                                  id == _unlinkStock ? null : id,
                                );
                              }
                              break;
                            case _ItemAction.delete:
                              await controller.deleteItem(item);
                              break;
                          }
                        },
                        itemBuilder: (_) => [
                          PopupMenuItem(
                            value: _ItemAction.link,
                            child: Text(l10n.checklistLinkStockAction),
                          ),
                          PopupMenuItem(
                            value: _ItemAction.delete,
                            child: Text(
                              l10n.deleteItemAction(item.titleIn(language)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
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

  Future<String?> _chooseInventoryItem(
    BuildContext context,
    List<InventoryItem> items,
    String? selected,
    AppLocalizations l10n,
  ) {
    return showDialog<String?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(l10n.checklistLinkStockTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext, _unlinkStock),
            child: ListTile(
              leading: const Icon(Icons.link_off),
              title: Text(l10n.checklistUnlinkStockAction),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          for (final item in items)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item.clientId),
              child: ListTile(
                leading: Icon(
                  item.clientId == selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                ),
                title: Text(item.name),
                subtitle: Text('${item.quantity} ${item.unit}'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.checklistNoStockToLink),
            ),
        ],
      ),
    );
  }
}

enum _ItemAction { link, delete }

const _unlinkStock = '__unlink__';

/// Where a food list's amounts meet the stores (#31).
///
/// The list says "3,5 kg Getreide pro Person für 10 Tage" and can only be
/// ticked. The supply-groups screen holds the same BLE groups against what
/// the household has tagged, scaled to its own people and days -- the
/// answer the tick box cannot give. A link rather than a copy: two places
/// working the groups out would be two answers.
class _SupplyGroupsLink extends StatelessWidget {
  const _SupplyGroupsLink({required this.householdId});

  final String householdId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: ListTile(
        leading: const Icon(Icons.donut_small_outlined),
        title: Text(l10n.supplyGroupsTitle),
        subtitle: Text(l10n.checklistFoodGroupsHint),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SupplyGroupsScreen(householdId: householdId),
          ),
        ),
      ),
    );
  }
}
