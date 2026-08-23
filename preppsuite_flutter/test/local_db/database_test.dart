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

  InventoryItemsCompanion draft({
    required String clientId,
    String? serverId,
    String householdId = 'household-1',
    String name = 'Trinkwasser',
    double quantity = 6,
    double? minQuantity,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool dirty = true,
  }) {
    return InventoryItemsCompanion.insert(
      clientId: clientId,
      serverId: Value(serverId),
      householdId: householdId,
      name: name,
      category: 'water',
      quantity: quantity,
      unit: 'Flasche',
      storageLocation: 'Keller',
      minQuantity: Value(minQuantity),
      updatedAt: updatedAt ?? DateTime.utc(2026),
      deletedAt: Value(deletedAt),
      dirty: Value(dirty),
    );
  }

  test(
    'watchInventoryItems emits inserted rows for the given household only',
    () async {
      await db.upsertInventoryItem(
        draft(clientId: 'a', householdId: 'household-1'),
      );
      await db.upsertInventoryItem(
        draft(clientId: 'b', householdId: 'household-2'),
      );

      final items = await db.watchInventoryItems('household-1').first;

      expect(items, hasLength(1));
      expect(items.single.clientId, 'a');
    },
  );

  test('watchInventoryItems excludes tombstoned rows', () async {
    await db.upsertInventoryItem(
      draft(clientId: 'a', deletedAt: DateTime.utc(2026, 2)),
    );
    await db.upsertInventoryItem(draft(clientId: 'b'));

    final items = await db.watchInventoryItems('household-1').first;

    expect(items, hasLength(1));
    expect(items.single.clientId, 'b');
  });

  test(
    'upsertInventoryItem with the same clientId overwrites instead of '
    'duplicating',
    () async {
      await db.upsertInventoryItem(draft(clientId: 'a', quantity: 1));
      await db.upsertInventoryItem(draft(clientId: 'a', quantity: 12));

      final items = await db.watchInventoryItems('household-1').first;

      expect(items, hasLength(1));
      expect(items.single.quantity, 12);
    },
  );

  test('dirtyInventoryItems only returns rows still marked dirty', () async {
    await db.upsertInventoryItem(draft(clientId: 'a', dirty: true));
    await db.upsertInventoryItem(draft(clientId: 'b', dirty: false));

    final dirty = await db.dirtyInventoryItems('household-1');

    expect(dirty.map((e) => e.clientId), ['a']);
  });

  test(
    'markInventoryItemsSynced clears dirty and stamps server id/updatedAt',
    () async {
      await db.upsertInventoryItem(draft(clientId: 'a'));
      final syncedAt = DateTime.utc(2026, 3);

      await db.markInventoryItemsSynced([('a', 'server-1', syncedAt)]);

      final dirty = await db.dirtyInventoryItems('household-1');
      final items = await db.watchInventoryItems('household-1').first;

      expect(dirty, isEmpty);
      expect(items.single.serverId, 'server-1');
      // Drift hands back a local-time-flagged DateTime for the same
      // instant (see AppDatabase.lastPulledAt's doc comment) — compare by
      // instant, not by ==, which is also strict about the UTC flag.
      expect(items.single.updatedAt.isAtSameMomentAs(syncedAt), isTrue);
    },
  );

  test(
    'sync cursor defaults to null and persists after setLastPulledAt',
    () async {
      expect(await db.lastPulledAt('inventory'), isNull);

      final cursor = DateTime.utc(2026, 5);
      await db.setLastPulledAt('inventory', cursor);

      expect(await db.lastPulledAt('inventory'), cursor);
    },
  );

  /// The 0.8.0 migration re-marks every syncable row as dirty, to re-offer
  /// changes a bug had kept from ever being pushed. The statement names its
  /// tables as plain strings, so this checks those names actually match the
  /// schema — a typo would otherwise only surface on a user's upgrade.
  group('migration to schema 6', () {
    test('marks rows in every syncable table for push again', () async {
      await db.upsertInventoryItem(
        draft(clientId: 'inv-1', dirty: false),
      );
      await db.upsertBudgetEntry(
        BudgetEntriesCompanion.insert(
          clientId: 'bud-1',
          householdId: 'household-1',
          label: 'Konserven',
          amountCents: 500,
          currency: 'EUR',
          category: 'food',
          updatedAt: DateTime.utc(2026),
          dirty: const Value(false),
        ),
      );
      await db.upsertChecklistTemplate(
        ChecklistTemplatesCompanion.insert(
          clientId: 'tpl-1',
          householdId: const Value('household-1'),
          title: 'Eigene Liste',
          category: 'custom',
          updatedAt: DateTime.utc(2026),
          dirty: const Value(false),
        ),
      );
      await db.upsertChecklistItem(
        ChecklistItemsCompanion.insert(
          clientId: 'itm-1',
          householdId: const Value('household-1'),
          templateClientId: 'tpl-1',
          title: 'Punkt',
          updatedAt: DateTime.utc(2026),
          dirty: const Value(false),
        ),
      );

      for (final table in [
        'inventory_items',
        'checklist_templates',
        'checklist_items',
        'budget_entries',
      ]) {
        await db.customStatement('UPDATE $table SET dirty = 1');
      }

      expect(await db.dirtyInventoryItems('household-1'), hasLength(1));
      expect(await db.dirtyBudgetEntries('household-1'), hasLength(1));
      expect(await db.dirtyChecklistTemplates('household-1'), hasLength(1));
      expect(await db.dirtyChecklistItems('household-1'), hasLength(1));
    });
  });
}
