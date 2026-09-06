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
  int get schemaVersion => 9;

  /// The tables whose rows travel through a shared folder, i.e. the ones
  /// with a `dirty` column.
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
        // (see the note in ARCHITEKTUR.md). Fixing the writes only helps
        // edits; what was already lost needs re-offering.
        //
        // Safe to do wholesale: a row is only ever accepted elsewhere if
        // its `updatedAt` is newer than what the other side holds, so rows
        // that are genuinely stale are ignored rather than overwriting
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
      if (from < 8) {
        // `serverId` held the id a server had assigned to a row. There is
        // no server, so the column has been dropped rather than left as an
        // always-null invitation to use it again. SQLite cannot drop a
        // column in place; `alterTable` recreates each table from the
        // current definition and copies the columns that still exist.
        //
        // "Current definition" is the trap here: the rebuild copies every
        // column the table has *today*, so a column added in a later
        // schema is one this SELECT reads out of a version-7 table that
        // never had it. Every such column therefore has to be named in
        // `newColumns` below — and its own branch has to skip installs
        // older than 8, which already got it here.
        await m.alterTable(
          TableMigration(
            inventoryItems,
            newColumns: [
              inventoryItems.proteinGrams,
              inventoryItems.carbohydrateGrams,
              inventoryItems.fatGrams,
              inventoryItems.fiberGrams,
            ],
          ),
        );
        await m.alterTable(TableMigration(checklistTemplates));
        await m.alterTable(TableMigration(checklistItems));
        await m.alterTable(TableMigration(budgetEntries));
      }
      if (from == 8) {
        // Macronutrients off a scanned label. Added rather than derived:
        // Open Food Facts states them per 100 g and the package size in
        // free text, so the conversion happens once, at scan time, and an
        // item whose label said nothing keeps four nulls forever.
        //
        // `== 8` and not `< 9`: anything older came through the rebuild
        // above, which already created these columns.
        await m.addColumn(inventoryItems, inventoryItems.proteinGrams);
        await m.addColumn(inventoryItems, inventoryItems.carbohydrateGrams);
        await m.addColumn(inventoryItems, inventoryItems.fatGrams);
        await m.addColumn(inventoryItems, inventoryItems.fiberGrams);
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

  /// Every item of every list this household has, for the overview's
  /// "x of y done".
  ///
  /// Not the same as watching each template's items and adding them up:
  /// that is one stream per list, and the overview would rebuild ten
  /// times for one tick.
  Stream<List<ChecklistItem>> watchAllChecklistItems(String householdId) {
    return (select(checklistItems)..where(
          (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
        ))
        .watch();
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

  // --- Shared-folder sync ----------------------------------------------

  /// Every row of the household, tombstones included.
  ///
  /// Deliberately unlike [watchInventoryItems], which hides deleted rows:
  /// a deletion has to travel to the other devices, and the only thing
  /// carrying it is the tombstone. Dropping them from the snapshot would
  /// make every delete undo itself on the next merge.
  Future<List<InventoryItem>> inventoryItemsForSync(String householdId) {
    return (select(
      inventoryItems,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  Future<List<ChecklistTemplate>> checklistTemplatesForSync(
    String householdId,
  ) {
    return (select(
      checklistTemplates,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  Future<List<ChecklistItem>> checklistItemsForSync(String householdId) {
    return (select(
      checklistItems,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  Future<List<BudgetEntry>> budgetEntriesForSync(String householdId) {
    return (select(
      budgetEntries,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  /// Gives the household's id to checklist rows that have none.
  ///
  /// Installs from before the seeder set it wrote built-in templates with
  /// a null household — a column a server used to own. Those rows are
  /// invisible to [checklistTemplatesForSync], which selects by
  /// household, so a ticked-off item on one device would quietly un-tick
  /// itself on the other. Runs with the seeder, on every launch, and does
  /// nothing once there is nothing left to claim.
  Future<void> claimOrphanChecklistRows(String householdId) {
    return transaction(() async {
      await (update(
        checklistTemplates,
      )..where((t) => t.householdId.isNull())).write(
        ChecklistTemplatesCompanion(
          householdId: Value(householdId),
          dirty: const Value(true),
        ),
      );
      await (update(
        checklistItems,
      )..where((t) => t.householdId.isNull())).write(
        ChecklistItemsCompanion(
          householdId: Value(householdId),
          dirty: const Value(true),
        ),
      );
    });
  }

  /// Clears `dirty` on everything this device has just published.
  ///
  /// [through] is the moment the snapshot was read, not the moment it was
  /// written: a row edited while the file was being written is not in it
  /// and must stay dirty, or the edit would never leave this device.
  Future<void> markHouseholdPublished(
    String householdId,
    DateTime through,
  ) {
    return transaction(() async {
      await (update(inventoryItems)..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.updatedAt.isSmallerOrEqualValue(through),
          ))
          .write(const InventoryItemsCompanion(dirty: Value(false)));
      await (update(checklistTemplates)..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.updatedAt.isSmallerOrEqualValue(through),
          ))
          .write(const ChecklistTemplatesCompanion(dirty: Value(false)));
      await (update(checklistItems)..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.updatedAt.isSmallerOrEqualValue(through),
          ))
          .write(const ChecklistItemsCompanion(dirty: Value(false)));
      await (update(budgetEntries)..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.updatedAt.isSmallerOrEqualValue(through),
          ))
          .write(const BudgetEntriesCompanion(dirty: Value(false)));
    });
  }

  /// Moves every row from one household id to another.
  ///
  /// Runs once, when this device joins a folder that already has a
  /// household in it: the rows it created before joining carry its own
  /// generated id, and without this they would simply stop being visible.
  /// They are marked dirty so the next push offers them to the others.
  Future<void> adoptHouseholdId({
    required String from,
    required String to,
  }) {
    if (from == to) return Future.value();

    return transaction(() async {
      await (update(
        inventoryItems,
      )..where((t) => t.householdId.equals(from))).write(
        InventoryItemsCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );
      await (update(
        checklistTemplates,
      )..where((t) => t.householdId.equals(from))).write(
        ChecklistTemplatesCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );
      await (update(
        checklistItems,
      )..where((t) => t.householdId.equals(from))).write(
        ChecklistItemsCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );
      await (update(
        budgetEntries,
      )..where((t) => t.householdId.equals(from))).write(
        BudgetEntriesCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );
    });
  }

  /// Applies rows that came from another device, each one only if it is
  /// newer than what is stored here.
  ///
  /// Returns how many rows actually changed, which is what tells the
  /// caller whether this device has learned anything worth republishing.
  Future<int> mergeIncomingRows({
    List<IncomingRow<InventoryItemsCompanion>> inventory = const [],
    List<IncomingRow<ChecklistTemplatesCompanion>> templates = const [],
    List<IncomingRow<ChecklistItemsCompanion>> items = const [],
    List<IncomingRow<BudgetEntriesCompanion>> budget = const [],
  }) {
    return transaction(() async {
      var changed = 0;
      changed += await _mergeInto(
        inventoryItems,
        inventory,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
      );
      changed += await _mergeInto(
        checklistTemplates,
        templates,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
      );
      changed += await _mergeInto(
        checklistItems,
        items,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
      );
      changed += await _mergeInto(
        budgetEntries,
        budget,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
      );
      return changed;
    });
  }

  /// Last-writer-wins by `updatedAt`, strictly greater.
  ///
  /// Strictly, so that replaying the same snapshot twice is free and the
  /// order the device files happen to be read in cannot change the
  /// outcome. Ties keep what is already stored: two rows sharing a
  /// `clientId` and an `updatedAt` are the same row, because a client id
  /// is generated once, on one device.
  Future<int> _mergeInto<T extends Table, R, C extends UpdateCompanion<R>>(
    TableInfo<T, R> table,
    List<IncomingRow<C>> incoming,
    ({String clientId, DateTime updatedAt}) Function(R) identify,
  ) async {
    if (incoming.isEmpty) return 0;

    final stored = {
      for (final row in await select(table).get())
        identify(row).clientId: identify(row).updatedAt.toUtc(),
    };

    final winners = [
      for (final candidate in incoming)
        if (stored[candidate.clientId]?.isBefore(
              candidate.updatedAt.toUtc(),
            ) ??
            true)
          candidate.companion,
    ];
    if (winners.isEmpty) return 0;

    await batch((b) => b.insertAllOnConflictUpdate(table, winners));
    return winners.length;
  }

  // --- Sync cursor -----------------------------------------------------

  /// When the shared folder was last read successfully. Shown to the user
  /// and nothing else — the merge is a full comparison every time, so it
  /// has no cursor to resume from.
  ///
  /// SQLite round-trips the correct instant but always hands back a
  /// local-time-flagged [DateTime] (see drift's native [DateTimeColumn]
  /// behavior); normalize to UTC here, since it is compared with
  /// `DateTime.utc(...)` elsewhere.
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

/// One row on its way in from another device's snapshot, with the two
/// fields the merge needs lifted out of the companion so the comparison
/// does not have to reach into a `Value` it cannot type.
typedef IncomingRow<C> = ({String clientId, DateTime updatedAt, C companion});

QueryExecutor _openConnection() {
  return driftDatabase(name: 'preppsuite');
}
