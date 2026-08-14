import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  ChecklistTemplatesCompanion draftTemplate({
    required String clientId,
    String? householdId = 'household-1',
    bool isBuiltIn = false,
    String title = 'Wasser',
    DateTime? deletedAt,
  }) {
    return ChecklistTemplatesCompanion.insert(
      clientId: clientId,
      householdId: Value(householdId),
      title: title,
      category: 'water',
      isBuiltIn: Value(isBuiltIn),
      updatedAt: DateTime.utc(2026),
      deletedAt: Value(deletedAt),
    );
  }

  ChecklistItemsCompanion draftItem({
    required String clientId,
    required String templateClientId,
    String? householdId = 'household-1',
    String title = 'Taschenlampe',
    int sortOrder = 0,
    DateTime? deletedAt,
  }) {
    return ChecklistItemsCompanion.insert(
      clientId: clientId,
      householdId: Value(householdId),
      templateClientId: templateClientId,
      title: title,
      sortOrder: Value(sortOrder),
      updatedAt: DateTime.utc(2026),
      deletedAt: Value(deletedAt),
    );
  }

  BudgetEntriesCompanion draftBudget({
    required String clientId,
    String householdId = 'household-1',
    int amountCents = 999,
    DateTime? deletedAt,
    bool dirty = true,
  }) {
    return BudgetEntriesCompanion.insert(
      clientId: clientId,
      householdId: householdId,
      label: 'Wasserkanister',
      amountCents: amountCents,
      currency: 'EUR',
      category: 'water',
      updatedAt: DateTime.utc(2026),
      deletedAt: Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  group('checklist templates', () {
    test(
      "watchChecklistTemplates returns the household's own plus built-ins, "
      'excluding other households and tombstones',
      () async {
        await db.upsertChecklistTemplate(
          draftTemplate(clientId: 'own', householdId: 'household-1'),
        );
        await db.upsertChecklistTemplate(
          draftTemplate(clientId: 'built-in', householdId: null, isBuiltIn: true),
        );
        await db.upsertChecklistTemplate(
          draftTemplate(clientId: 'other', householdId: 'household-2'),
        );
        await db.upsertChecklistTemplate(
          draftTemplate(
            clientId: 'deleted',
            householdId: 'household-1',
            deletedAt: DateTime.utc(2026, 2),
          ),
        );

        final templates = await db.watchChecklistTemplates('household-1').first;

        expect(
          templates.map((t) => t.clientId),
          containsAll(['own', 'built-in']),
        );
        expect(templates.map((t) => t.clientId), isNot(contains('other')));
        expect(templates.map((t) => t.clientId), isNot(contains('deleted')));
      },
    );

    test('checklistTemplateByClientId and byServerId find the same row', () async {
      await db.upsertChecklistTemplate(draftTemplate(clientId: 'a'));
      await db.markChecklistTemplatesSynced([
        ('a', 'server-a', DateTime.utc(2026, 3)),
      ]);

      final byClient = await db.checklistTemplateByClientId('a');
      final byServer = await db.checklistTemplateByServerId('server-a');

      expect(byClient?.clientId, 'a');
      expect(byServer?.clientId, 'a');
    });

    test('dirtyChecklistTemplates excludes built-ins (never locally dirty '
        'under this household)', () async {
      await db.upsertChecklistTemplate(
        draftTemplate(clientId: 'own', householdId: 'household-1'),
      );
      await db.upsertChecklistTemplate(
        draftTemplate(clientId: 'built-in', householdId: null, isBuiltIn: true),
      );

      final dirty = await db.dirtyChecklistTemplates('household-1');

      expect(dirty.map((t) => t.clientId), ['own']);
    });
  });

  group('checklist items', () {
    test(
      'watchChecklistItems filters by templateClientId and orders by '
      'sortOrder',
      () async {
        await db.upsertChecklistItem(
          draftItem(clientId: 'b', templateClientId: 'template-1', sortOrder: 1),
        );
        await db.upsertChecklistItem(
          draftItem(clientId: 'a', templateClientId: 'template-1', sortOrder: 0),
        );
        await db.upsertChecklistItem(
          draftItem(clientId: 'c', templateClientId: 'template-2'),
        );

        final items = await db.watchChecklistItems('template-1').first;

        expect(items.map((i) => i.clientId), ['a', 'b']);
      },
    );

    test('watchChecklistItems excludes tombstoned rows', () async {
      await db.upsertChecklistItem(
        draftItem(
          clientId: 'a',
          templateClientId: 'template-1',
          deletedAt: DateTime.utc(2026, 2),
        ),
      );
      await db.upsertChecklistItem(
        draftItem(clientId: 'b', templateClientId: 'template-1'),
      );

      final items = await db.watchChecklistItems('template-1').first;

      expect(items.map((i) => i.clientId), ['b']);
    });
  });

  group('budget entries', () {
    test('watchBudgetEntries returns only the given household, newest '
        'purchase first', () async {
      await db.upsertBudgetEntry(draftBudget(clientId: 'other', householdId: 'household-2'));
      await db.upsertBudgetEntry(
        draftBudget(clientId: 'a', deletedAt: DateTime.utc(2026, 2)),
      );
      await db.upsertBudgetEntry(draftBudget(clientId: 'b'));

      final entries = await db.watchBudgetEntries('household-1').first;

      expect(entries.map((e) => e.clientId), ['b']);
    });

    test('dirtyBudgetEntries and markBudgetEntriesSynced round-trip', () async {
      await db.upsertBudgetEntry(draftBudget(clientId: 'a'));
      expect(
        (await db.dirtyBudgetEntries('household-1')).map((e) => e.clientId),
        ['a'],
      );

      await db.markBudgetEntriesSynced([
        ('a', 'server-a', DateTime.utc(2026, 4)),
      ]);

      expect(await db.dirtyBudgetEntries('household-1'), isEmpty);
    });
  });
}
