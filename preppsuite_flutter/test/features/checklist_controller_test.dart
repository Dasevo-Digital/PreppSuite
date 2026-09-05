import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/model/categories.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late ProviderContainer container;
  late ChecklistController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    controller = container.read(checklistControllerProvider(householdId));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// A template and one item that have already been published — `dirty`
  /// at false, which is the state the dirty bug needed to bite.
  Future<(ChecklistTemplate, ChecklistItem)> syncedTemplateWithItem() async {
    await db.upsertChecklistTemplate(
      ChecklistTemplatesCompanion.insert(
        clientId: 'tpl-1',
        householdId: const Value(householdId),
        title: 'Eigene Liste',
        category: 'custom',
        updatedAt: DateTime.utc(2026),
        dirty: const Value(false),
      ),
    );
    await db.upsertChecklistItem(
      ChecklistItemsCompanion.insert(
        clientId: 'itm-1',
        householdId: const Value(householdId),
        templateClientId: 'tpl-1',
        title: 'Trinkwasser',
        updatedAt: DateTime.utc(2026),
        dirty: const Value(false),
      ),
    );

    final template = (await db.watchChecklistTemplates(householdId).first)
        .firstWhere((t) => t.clientId == 'tpl-1');
    final item = (await db.watchChecklistItems('tpl-1').first).single;
    return (template, item);
  }

  /// Guards the same bug `inventory_controller_test` covers, for this
  /// controller: `dirty` defaults to true only on INSERT, and
  /// `insertOnConflictUpdate` skips any column the companion leaves out —
  /// so an edit to an already-synced row used to stay marked clean and was
  /// never pushed. Checking off an item is the most visible case of it.
  group('every local write marks the row for push', () {
    test('toggling an item off and on again', () async {
      final (_, item) = await syncedTemplateWithItem();

      await controller.toggleItem(item);

      final toggled = (await db.watchChecklistItems('tpl-1').first).single;
      expect(toggled.isChecked, isTrue);
      expect(
        toggled.dirty,
        isTrue,
        reason: 'a tick that never reaches the server is worse than useless',
      );

      // And back again — the second write must not lose the mark either.
      await controller.toggleItem(toggled);
      final untoggled = (await db.watchChecklistItems('tpl-1').first).single;
      expect(untoggled.isChecked, isFalse);
      expect(untoggled.dirty, isTrue);
    });

    test('deleting an item', () async {
      final (_, item) = await syncedTemplateWithItem();

      await controller.deleteItem(item);

      final dirty = await db.dirtyChecklistItems(householdId);
      expect(dirty.single.deletedAt, isNotNull);
      expect(
        dirty.single.dirty,
        isTrue,
        reason: 'otherwise the deletion never leaves this device',
      );
    });

    test('deleting a template also marks its items', () async {
      final (template, _) = await syncedTemplateWithItem();

      await controller.deleteTemplate(template);

      final dirtyTemplates = await db.dirtyChecklistTemplates(householdId);
      expect(dirtyTemplates.single.deletedAt, isNotNull);
      expect(dirtyTemplates.single.dirty, isTrue);

      final dirtyItems = await db.dirtyChecklistItems(householdId);
      expect(dirtyItems.single.deletedAt, isNotNull);
      expect(dirtyItems.single.dirty, isTrue);
    });

    test('adding an item to an existing template', () async {
      await syncedTemplateWithItem();

      await controller.addItem(
        templateClientId: 'tpl-1',
        title: 'Wasserfilter',
      );

      final added = (await db.watchChecklistItems('tpl-1').first).firstWhere(
        (i) => i.title == 'Wasserfilter',
      );
      expect(added.dirty, isTrue);
      expect(added.sortOrder, 1, reason: 'appended after the existing item');
    });

    test('creating a template', () async {
      await controller.createTemplate(
        title: 'Neue Liste',
        category: ChecklistCategory.custom,
      );

      final dirty = await db.dirtyChecklistTemplates(householdId);
      expect(dirty.single.title, 'Neue Liste');
      expect(dirty.single.dirty, isTrue);
    });

    test('duplicating a template copies its items, all marked', () async {
      final (template, _) = await syncedTemplateWithItem();

      await controller.duplicateTemplate(template);

      final templates = await db.dirtyChecklistTemplates(householdId);
      expect(templates, hasLength(1), reason: 'only the copy is dirty');
      final copy = templates.single;
      expect(copy.clientId, isNot('tpl-1'), reason: 'a fresh local identity');
      expect(copy.title, 'Eigene Liste');

      final copiedItems = await db.watchChecklistItems(copy.clientId).first;
      expect(copiedItems.single.title, 'Trinkwasser');
      expect(copiedItems.single.dirty, isTrue);
    });
  });
}
