import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preppsuite_client/preppsuite_client.dart' show ChecklistCategory;
import 'package:uuid/uuid.dart';

import '../../../local_db/database.dart';
import 'checklist_providers.dart';
import 'checklist_sync_controller.dart';

/// Local writes for checklist templates/items, plus nudging sync afterward.
/// See `InventoryController` for the general shape this follows.
class ChecklistController {
  ChecklistController(this._ref, this._db, this.householdId);

  final Ref _ref;
  final AppDatabase _db;
  final String householdId;

  Future<void> createTemplate({
    required String title,
    required ChecklistCategory category,
  }) async {
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: Value(householdId),
        title: title,
        category: category.name,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _triggerSync();
  }

  /// Copies [source] (built-in or the household's own) into a new,
  /// independent, fully editable template owned by this household — the
  /// Ready-Kit-inspired "duplicate template" action, and the only way to
  /// customize a built-in's title/category since the shared original stays
  /// read-only.
  Future<void> duplicateTemplate(ChecklistTemplate source) async {
    final newTemplateClientId = const Uuid().v4();
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: newTemplateClientId,
        householdId: Value(householdId),
        title: source.title,
        category: source.category,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    final items = await _db.watchChecklistItems(source.clientId).first;
    for (final item in items) {
      await _db.upsertChecklistItem(
        ChecklistItemsCompanion.insert(
          clientId: const Uuid().v4(),
          householdId: Value(householdId),
          templateClientId: newTemplateClientId,
          title: item.title,
          targetQuantity: Value(item.targetQuantity),
          sortOrder: Value(item.sortOrder),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    _triggerSync();
  }

  Future<void> deleteTemplate(ChecklistTemplate template) async {
    final now = DateTime.now().toUtc();
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: template.clientId,
        serverId: Value(template.serverId),
        householdId: Value(template.householdId),
        title: template.title,
        category: template.category,
        isBuiltIn: Value(template.isBuiltIn),
        updatedAt: now,
        deletedAt: Value(now),
      ),
    );

    final items = await _db.watchChecklistItems(template.clientId).first;
    for (final item in items) {
      await _deleteItem(item, now);
    }
    _triggerSync();
  }

  Future<void> addItem({
    required String templateClientId,
    required String title,
    double? targetQuantity,
  }) async {
    final currentItems = await _db.watchChecklistItems(templateClientId).first;
    await _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: Value(householdId),
        templateClientId: templateClientId,
        title: title,
        targetQuantity: Value(targetQuantity),
        sortOrder: Value(currentItems.length),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _triggerSync();
  }

  Future<void> toggleItem(ChecklistItem item) async {
    await _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: item.clientId,
        serverId: Value(item.serverId),
        householdId: Value(item.householdId),
        templateClientId: item.templateClientId,
        title: item.title,
        targetQuantity: Value(item.targetQuantity),
        isChecked: Value(!item.isChecked),
        linkedInventoryItemId: Value(item.linkedInventoryItemId),
        sortOrder: Value(item.sortOrder),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    _triggerSync();
  }

  Future<void> deleteItem(ChecklistItem item) async {
    await _deleteItem(item, DateTime.now().toUtc());
    _triggerSync();
  }

  Future<void> _deleteItem(ChecklistItem item, DateTime deletedAt) {
    return _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: item.clientId,
        serverId: Value(item.serverId),
        householdId: Value(item.householdId),
        templateClientId: item.templateClientId,
        title: item.title,
        targetQuantity: Value(item.targetQuantity),
        isChecked: Value(item.isChecked),
        linkedInventoryItemId: Value(item.linkedInventoryItemId),
        sortOrder: Value(item.sortOrder),
        updatedAt: deletedAt,
        deletedAt: Value(deletedAt),
      ),
    );
  }

  void _triggerSync() {
    _ref.read(checklistSyncControllerProvider(householdId).notifier).syncDebounced();
  }
}

final checklistControllerProvider = Provider.autoDispose
    .family<ChecklistController, String>(
      (ref, householdId) => ChecklistController(
        ref,
        ref.watch(appDatabaseProvider),
        householdId,
      ),
    );
