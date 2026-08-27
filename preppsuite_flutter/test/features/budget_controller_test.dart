import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_client/preppsuite_client.dart'
    show InventoryItemCategory;
import 'package:preppsuite_flutter/features/budget/application/budget_controller.dart';
import 'package:preppsuite_flutter/features/budget/application/budget_providers.dart';
import 'package:preppsuite_flutter/features/budget/application/budget_sync_controller.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The real controller nudges sync after every write, which starts timers
/// and reaches for the global Serverpod client. Neither is under test here.
class _NoopSyncController extends BudgetSyncController {
  _NoopSyncController(super.householdId);

  @override
  AsyncValue<void> build() => const AsyncData(null);
}

void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late ProviderContainer container;
  late BudgetController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        budgetSyncControllerProvider.overrideWith2(_NoopSyncController.new),
      ],
    );
    controller = container.read(budgetControllerProvider(householdId));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  /// An entry that has already been pushed once — `dirty` at false with a
  /// server id, the state in which the dirty bug silently dropped edits.
  Future<BudgetEntry> syncedEntry() async {
    await db.upsertBudgetEntry(
      BudgetEntriesCompanion.insert(
        clientId: 'bud-1',
        serverId: const Value('srv-bud-1'),
        householdId: householdId,
        label: 'Konserven',
        amountCents: 1250,
        currency: 'EUR',
        category: 'food',
        updatedAt: DateTime.utc(2026),
        dirty: const Value(false),
      ),
    );
    return (await db.watchBudgetEntries(householdId).first).single;
  }

  /// Same guard as in `inventory_controller_test` and
  /// `checklist_controller_test`: `dirty` defaults to true only on INSERT,
  /// and `insertOnConflictUpdate` skips columns the companion omits, so an
  /// edit to an already-synced row used to stay marked clean.
  group('every local write marks the row for push', () {
    test('adding an entry', () async {
      await controller.addEntry(
        label: 'Kurbelradio',
        amountCents: 4900,
        currency: 'EUR',
        category: InventoryItemCategory.energy,
      );

      final dirty = await db.dirtyBudgetEntries(householdId);
      expect(dirty.single.label, 'Kurbelradio');
      expect(dirty.single.dirty, isTrue);
    });

    test('editing an entry', () async {
      final existing = await syncedEntry();

      await controller.updateEntry(
        existing,
        label: 'Konserven (Nachkauf)',
        amountCents: 1800,
        currency: 'EUR',
        category: InventoryItemCategory.food,
      );

      final updated = (await db.watchBudgetEntries(householdId).first).single;
      expect(updated.amountCents, 1800);
      expect(updated.label, 'Konserven (Nachkauf)');
      expect(updated.dirty, isTrue);
      expect(
        updated.serverId,
        'srv-bud-1',
        reason: 'the server identity must survive a local edit',
      );
    });

    test('deleting an entry', () async {
      final existing = await syncedEntry();

      await controller.deleteEntry(existing);

      final dirty = await db.dirtyBudgetEntries(householdId);
      expect(dirty.single.deletedAt, isNotNull);
      expect(
        dirty.single.dirty,
        isTrue,
        reason: 'otherwise the deletion never leaves this device',
      );
    });

    test('an edit stamps a fresh updatedAt so it can win a conflict', () async {
      final existing = await syncedEntry();

      await controller.updateEntry(
        existing,
        label: 'Konserven',
        amountCents: 1300,
        currency: 'EUR',
        category: InventoryItemCategory.food,
      );

      final updated = (await db.watchBudgetEntries(householdId).first).single;
      expect(updated.updatedAt.isAfter(existing.updatedAt), isTrue);
    });
  });
}
