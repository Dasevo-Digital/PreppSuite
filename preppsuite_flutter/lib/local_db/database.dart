import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/budget_entries_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/checklist_templates_table.dart';
import 'tables/inventory_items_table.dart';
import 'tables/sync_state_table.dart';
import 'tables/warnings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    InventoryItems,
    ChecklistTemplates,
    ChecklistItems,
    BudgetEntries,
    Warnings,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  /// The tables whose rows are pushed to the server, i.e. the ones with a
  /// `dirty` column.
  static const _syncableTableNames = [
    'inventory_items',
    'checklist_templates',
    'checklist_items',
    'budget_entries',
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(checklistTemplates);
        await m.createTable(checklistItems);
        await m.createTable(budgetEntries);
      }
      if (from < 3) {
        await m.createTable(warnings);
      }
      if (from < 4) {
        await m.addColumn(inventoryItems, inventoryItems.photoPath);
      }
      if (from < 5) {
        await m.addColumn(inventoryItems, inventoryItems.calories);
      }
      if (from < 6) {
        // Repairs data left behind by a bug that kept `dirty` at false when
        // an already-synced row was edited, so the change never went out
        // (see the note in CLAUDE.md). Fixing the writes only helps future
        // edits; what was already lost needs re-offering to the server.
        //
        // Safe to do wholesale: the server applies an incoming row only if
        // its `updatedAt` is newer than what it holds, so rows that are
        // genuinely stale are simply ignored rather than overwriting
        // anything.
        for (final table in _syncableTableNames) {
          await customStatement('UPDATE $table SET dirty = 1');
        }
      }
      if (from < 7) {
        // Warnings are now fetched by the app itself, so the row identity
        // changed from the old server-assigned id to `(source, externalId)`
        // — which SQLite cannot express as an ALTER. Dropping the table is
        // the honest move rather than the destructive-sounding one: every
        // row here is a cache entry that the next poll refills within
        // minutes, and none of it is data the user created.
        await m.deleteTable('warnings');
        await m.createTable(warnings);
        await customStatement(
          "DELETE FROM sync_state WHERE entity = 'warning'",
        );
      }
    },
  );

  // --- Inventory ------------------------------------------------------

  Stream<List<InventoryItem>> watchInventoryItems(String householdId) {
    return (select(inventoryItems)
          ..where(
            (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// Items below their configured minimum — used by the "missing
  /// equipment" PDF report.
  Future<List<InventoryItem>> lowStockInventoryItems(String householdId) {
    return (select(inventoryItems)..where(
          (t) =>
              t.householdId.equals(householdId) &
              t.deletedAt.isNull() &
              t.minQuantity.isNotNull() &
              t.quantity.isSmallerThan(t.minQuantity),
        ))
        .get();
  }

  Future<void> upsertInventoryItem(InventoryItemsCompanion item) {
    return into(inventoryItems).insertOnConflictUpdate(item);
  }

  /// Used by CSV import so hundreds of rows commit as a single batch
  /// instead of one write (and one sync nudge) per row.
  Future<void> upsertInventoryItems(List<InventoryItemsCompanion> items) {
    return batch((b) => b.insertAllOnConflictUpdate(inventoryItems, items));
  }

  Future<List<InventoryItem>> dirtyInventoryItems(String householdId) {
    return (select(inventoryItems)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<void> markInventoryItemsSynced(
    List<(String clientId, String serverId, DateTime updatedAt)> synced,
  ) {
    return transaction(() async {
      for (final (clientId, serverId, updatedAt) in synced) {
        await (update(
          inventoryItems,
        )..where((t) => t.clientId.equals(clientId))).write(
          InventoryItemsCompanion(
            serverId: Value(serverId),
            updatedAt: Value(updatedAt),
            dirty: const Value(false),
          ),
        );
      }
    });
  }

  // --- Checklists -------------------------------------------------------

  /// A household's own templates plus every built-in one.
  Stream<List<ChecklistTemplate>> watchChecklistTemplates(String householdId) {
    return (select(checklistTemplates)
          ..where(
            (t) =>
                (t.householdId.equals(householdId) | t.isBuiltIn.equals(true)) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch();
  }

  /// One-off (non-streaming) version of [watchChecklistTemplates], for the
  /// PDF report which needs a single snapshot rather than a live view.
  Future<List<ChecklistTemplate>> allChecklistTemplates(String householdId) {
    return (select(checklistTemplates)..where(
          (t) =>
              (t.householdId.equals(householdId) | t.isBuiltIn.equals(true)) &
              t.deletedAt.isNull(),
        ))
        .get();
  }

  /// Unchecked items across every template — used by the "missing
  /// equipment" PDF report.
  Future<List<ChecklistItem>> uncheckedChecklistItems(String householdId) {
    return (select(checklistItems)..where(
          (t) =>
              t.householdId.equals(householdId) &
              t.isChecked.equals(false) &
              t.deletedAt.isNull(),
        ))
        .get();
  }

  Stream<List<ChecklistItem>> watchChecklistItems(String templateClientId) {
    return (select(checklistItems)
          ..where(
            (t) =>
                t.templateClientId.equals(templateClientId) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<void> upsertChecklistTemplate(ChecklistTemplatesCompanion template) {
    return into(checklistTemplates).insertOnConflictUpdate(template);
  }

  Future<void> upsertChecklistItem(ChecklistItemsCompanion item) {
    return into(checklistItems).insertOnConflictUpdate(item);
  }

  Future<ChecklistTemplate?> checklistTemplateByClientId(String clientId) {
    return (select(
      checklistTemplates,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
  }

  Future<ChecklistTemplate?> checklistTemplateByServerId(String serverId) {
    return (select(
      checklistTemplates,
    )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
  }

  Future<List<ChecklistTemplate>> dirtyChecklistTemplates(String householdId) {
    return (select(checklistTemplates)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<List<ChecklistItem>> dirtyChecklistItems(String householdId) {
    return (select(checklistItems)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<void> markChecklistTemplatesSynced(
    List<(String clientId, String serverId, DateTime updatedAt)> synced,
  ) {
    return transaction(() async {
      for (final (clientId, serverId, updatedAt) in synced) {
        await (update(
          checklistTemplates,
        )..where((t) => t.clientId.equals(clientId))).write(
          ChecklistTemplatesCompanion(
            serverId: Value(serverId),
            updatedAt: Value(updatedAt),
            dirty: const Value(false),
          ),
        );
      }
    });
  }

  Future<void> markChecklistItemsSynced(
    List<(String clientId, String serverId, DateTime updatedAt)> synced,
  ) {
    return transaction(() async {
      for (final (clientId, serverId, updatedAt) in synced) {
        await (update(
          checklistItems,
        )..where((t) => t.clientId.equals(clientId))).write(
          ChecklistItemsCompanion(
            serverId: Value(serverId),
            updatedAt: Value(updatedAt),
            dirty: const Value(false),
          ),
        );
      }
    });
  }

  // --- Budget -------------------------------------------------------

  Stream<List<BudgetEntry>> watchBudgetEntries(String householdId) {
    return (select(budgetEntries)
          ..where(
            (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.purchaseDate)]))
        .watch();
  }

  Future<void> upsertBudgetEntry(BudgetEntriesCompanion entry) {
    return into(budgetEntries).insertOnConflictUpdate(entry);
  }

  Future<List<BudgetEntry>> dirtyBudgetEntries(String householdId) {
    return (select(budgetEntries)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<void> markBudgetEntriesSynced(
    List<(String clientId, String serverId, DateTime updatedAt)> synced,
  ) {
    return transaction(() async {
      for (final (clientId, serverId, updatedAt) in synced) {
        await (update(
          budgetEntries,
        )..where((t) => t.clientId.equals(clientId))).write(
          BudgetEntriesCompanion(
            serverId: Value(serverId),
            updatedAt: Value(updatedAt),
            dirty: const Value(false),
          ),
        );
      }
    });
  }

  // --- Warnings (fetched locally, never pushed) -------------------------

  /// Not-yet-expired warnings, most recent first. [severity] is stored as
  /// plain text, so it isn't sorted correctly by SQL (alphabetical, not
  /// severity rank) — pick the most severe one in Dart at the display site
  /// instead (see `warning_severity_l10n.dart`).
  Stream<List<Warning>> watchActiveWarnings() {
    return (select(warnings)
          ..where(
            (t) =>
                t.expires.isNull() |
                t.expires.isBiggerThanValue(DateTime.now()),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.sent)]))
        .watch();
  }

  /// Full history, including expired warnings, most recent first.
  Stream<List<Warning>> watchAllWarnings() {
    return (select(
      warnings,
    )..orderBy([(t) => OrderingTerm.desc(t.sent)])).watch();
  }

  Future<void> upsertWarning(WarningsCompanion warning) {
    return into(warnings).insertOnConflictUpdate(warning);
  }

  /// The warning stored under [source]/[externalId], or null.
  ///
  /// The poll needs the previous row to decide whether anything worth
  /// telling the user about actually changed — a feed reissuing the same
  /// warning with corrected wording must not notify twice.
  Future<Warning?> findWarning(String source, String externalId) {
    return (select(warnings)..where(
          (t) => t.source.equals(source) & t.externalId.equals(externalId),
        ))
        .getSingleOrNull();
  }

  /// Warnings that have not been announced yet.
  Future<List<Warning>> unnotifiedWarnings() {
    return (select(warnings)..where((t) => t.notified.equals(false))).get();
  }

  Future<void> markWarningsNotified(
    List<({String source, String externalId})> keys,
  ) async {
    await batch((b) {
      for (final key in keys) {
        b.update(
          warnings,
          const WarningsCompanion(notified: Value(true)),
          where: (t) =>
              t.source.equals(key.source) & t.externalId.equals(key.externalId),
        );
      }
    });
  }

  /// Stamps [expires] on active warnings of [source] that the feed no
  /// longer lists. Mirrors the rule the server used: the sources carry no
  /// end time, so a warning is over once it drops out of a complete poll.
  Future<int> expireMissingWarnings({
    required String source,
    required Set<String> seenExternalIds,
  }) async {
    final active = await (select(
      warnings,
    )..where((t) => t.source.equals(source) & t.expires.isNull())).get();

    final now = DateTime.now().toUtc();
    var retired = 0;
    for (final warning in active) {
      if (seenExternalIds.contains(warning.externalId)) continue;
      await (update(warnings)..where(
            (t) =>
                t.source.equals(warning.source) &
                t.externalId.equals(warning.externalId),
          ))
          .write(WarningsCompanion(expires: Value(now), updatedAt: Value(now)));
      retired++;
    }
    return retired;
  }

  /// Keeps the local cache from growing forever — long-expired warnings
  /// aren't useful history for a household to scroll through.
  Future<void> pruneExpiredWarnings({
    Duration retention = const Duration(days: 30),
  }) {
    final cutoff = DateTime.now().subtract(retention);
    return (delete(
      warnings,
    )..where((t) => t.expires.isSmallerThanValue(cutoff))).go();
  }

  // --- Sync cursor -----------------------------------------------------

  /// SQLite round-trips the correct instant but always hands back a
  /// local-time-flagged [DateTime] (see drift's native `DateTimeColumn`
  /// behavior); normalize to UTC here since this value both feeds the
  /// server's `since` comparisons and is compared with `DateTime.utc(...)`
  /// elsewhere.
  Future<DateTime?> lastPulledAt(String entity) async {
    final row = await (select(
      syncState,
    )..where((t) => t.entity.equals(entity))).getSingleOrNull();
    return row?.lastPulledAt.toUtc();
  }

  Future<void> setLastPulledAt(String entity, DateTime value) {
    return into(syncState).insertOnConflictUpdate(
      SyncStateCompanion.insert(entity: entity, lastPulledAt: value),
    );
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'preppsuite');
}
