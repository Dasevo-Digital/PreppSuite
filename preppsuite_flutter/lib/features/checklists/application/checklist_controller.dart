import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/categories.dart';

import 'package:uuid/uuid.dart';

import '../../../local_db/database.dart';
import 'built_in_template_l10n.dart';
import 'checklist_providers.dart';

/// Local writes for checklist templates and items. See
/// `InventoryController` for the general shape this follows.
class ChecklistController {
  ChecklistController(this._db, this.householdId);

  final AppDatabase _db;
  final String householdId;

  Future<void> createTemplate({
    required String title,
    required ChecklistCategory category,
    ChecklistKind kind = ChecklistKind.preparation,
  }) async {
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: const Uuid().v4(),
        householdId: Value(householdId),
        title: title,
        category: category.name,
        kind: Value(kind.name),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  /// Copies [source] (built-in or the household's own) into a new,
  /// independent, fully editable template owned by this household — the
  /// Ready-Kit-inspired "duplicate template" action, and the only way to
  /// customize a built-in's title/category since the shared original stays
  /// read-only.
  /// A copy of [source] the household owns, in the words it was reading:
  /// a built-in list shown in Spanish is copied in Spanish (#108), because
  /// the copy is the household's own list from here on, and its own lists
  /// are never translated.
  Future<void> duplicateTemplate(
    ChecklistTemplate source, {
    String languageCode = 'de',
  }) async {
    final newTemplateClientId = const Uuid().v4();
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: newTemplateClientId,
        householdId: Value(householdId),
        title: source.titleIn(languageCode),
        category: source.category,
        kind: Value(source.kind),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );

    final items = await _db.watchChecklistItems(source.clientId).first;
    for (final item in items) {
      await _db.upsertChecklistItem(
        ChecklistItemsCompanion.insert(
          clientId: const Uuid().v4(),
          householdId: Value(householdId),
          templateClientId: newTemplateClientId,
          title: item.titleIn(languageCode),
          targetQuantity: Value(item.targetQuantity),
          sortOrder: Value(item.sortOrder),
          updatedAt: DateTime.now().toUtc(),
          dirty: const Value(true),
        ),
      );
    }
  }

  Future<void> deleteTemplate(ChecklistTemplate template) async {
    final now = DateTime.now().toUtc();
    await _db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: template.clientId,
        householdId: Value(template.householdId),
        title: template.title,
        category: template.category,
        kind: Value(template.kind),
        isBuiltIn: Value(template.isBuiltIn),
        updatedAt: now,
        dirty: const Value(true),
        deletedAt: Value(now),
      ),
    );

    final items = await _db.watchChecklistItems(template.clientId).first;
    for (final item in items) {
      await _deleteItem(item, now);
    }
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
        dirty: const Value(true),
      ),
    );
  }

  Future<void> toggleItem(ChecklistItem item) async {
    await _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: item.clientId,
        householdId: Value(item.householdId),
        templateClientId: item.templateClientId,
        title: item.title,
        targetQuantity: Value(item.targetQuantity),
        isChecked: Value(!item.isChecked),
        linkedInventoryItemId: Value(item.linkedInventoryItemId),
        sortOrder: Value(item.sortOrder),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  /// Connects a checklist row to an inventory row. The presentation can
  /// then derive completion from the live quantity without copying stock
  /// numbers into the checklist.
  Future<void> linkInventoryItem(
    ChecklistItem item,
    String? inventoryItemId,
  ) async {
    await _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: item.clientId,
        householdId: Value(item.householdId),
        templateClientId: item.templateClientId,
        title: item.title,
        targetQuantity: Value(item.targetQuantity),
        isChecked: Value(item.isChecked),
        linkedInventoryItemId: Value(inventoryItemId),
        sortOrder: Value(item.sortOrder),
        updatedAt: DateTime.now().toUtc(),
        dirty: const Value(true),
      ),
    );
  }

  Future<void> deleteItem(ChecklistItem item) async {
    await _deleteItem(item, DateTime.now().toUtc());
  }

  Future<void> _deleteItem(ChecklistItem item, DateTime deletedAt) {
    return _db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: item.clientId,
        householdId: Value(item.householdId),
        templateClientId: item.templateClientId,
        title: item.title,
        targetQuantity: Value(item.targetQuantity),
        isChecked: Value(item.isChecked),
        linkedInventoryItemId: Value(item.linkedInventoryItemId),
        sortOrder: Value(item.sortOrder),
        updatedAt: deletedAt,
        dirty: const Value(true),
        deletedAt: Value(deletedAt),
      ),
    );
  }
}

final checklistControllerProvider = Provider.autoDispose
    .family<ChecklistController, String>(
      (ref, householdId) => ChecklistController(
        ref.watch(appDatabaseProvider),
        householdId,
      ),
    );
