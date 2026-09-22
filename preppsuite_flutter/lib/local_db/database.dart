import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../core/app_database_directory.dart';

import 'tables/budget_entries_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/checklist_templates_table.dart';
import 'tables/household_members_table.dart';
import 'tables/household_plans_table.dart';
import 'tables/inventory_items_table.dart';
import 'tables/possessions_table.dart';
import 'tables/sync_state_table.dart';
import 'tables/warnings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    InventoryItems,
    ChecklistTemplates,
    ChecklistItems,
    BudgetEntries,
    HouseholdMembers,
    HouseholdPlans,
    Possessions,
    Warnings,
    SyncState,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Shown in the settings version information without opening the database.
  static const currentSchemaVersion = 16;

  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => currentSchemaVersion;

  /// The tables whose rows travel through a shared folder, i.e. the ones
  /// with a `dirty` column.
  /// The tables that existed at schema 6, for the repair below.
  ///
  /// Deliberately not "every syncable table": this list is read by the
  /// `from < 6` migration, which runs before the later branches create
  /// anything. Adding `household_plans` here would issue an UPDATE
  /// against a table that does not exist yet and take the migration down
  /// on every install older than 6.
  static const _syncableTableNames = [
    'inventory_items',
    'checklist_templates',
    'checklist_items',
    'budget_entries',
  ];

  /// Whether the database really holds this table.
  ///
  /// Asked rather than deduced from the version. See [_addColumnOnce].
  Future<bool> _hasTable(String table) async {
    final row = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable<String>(table)],
    ).getSingleOrNull();
    return row != null;
  }

  /// Adds a column unless the table already has it.
  ///
  /// Every `addColumn` in the migration goes through here, because a
  /// migration that assumes a column is missing can brick the app for
  /// good. Drift runs `onUpgrade` and then, as a separate write, records
  /// the new version -- there is no transaction around the pair (see
  /// `engines.dart`: "set version now, after migrations ran
  /// successfully"). So a process that dies between the two -- a force
  /// quit, a crash, the bundle being replaced under a running app --
  /// leaves the column added and the version unchanged. The next launch
  /// runs the same ALTER again, SQLite answers "duplicate column name",
  /// and the app cannot open at all: the failure is in the code that runs
  /// before there is a screen to explain it, and it repeats on every
  /// single launch. It happened here, to the real household database,
  /// between 1.7.4 and 1.8.0.
  ///
  /// Asking costs one `PRAGMA table_info` per column at upgrade time,
  /// which happens once per install per version.
  Future<void> _addColumnOnce(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final columns = await customSelect(
      'PRAGMA table_info(${table.actualTableName})',
    ).get();
    final present = columns.any(
      (row) => row.read<String>('name') == column.name,
    );
    if (present) return;
    await m.addColumn(table, column);
  }

  /// Steps that change values rather than shape, and have already run.
  ///
  /// A shape change can be asked about -- [_addColumnOnce] looks at
  /// `PRAGMA table_info` and steps over a column that is there. A value
  /// change cannot: nothing in `calories = 213` says whether it was 2.13
  /// a moment ago. So such a step writes its name down, and a replay
  /// reads it.
  static const _migrationMarks = 'migration_marks';

  /// Every value conversion the history holds, by the name it writes down.
  static const _valueMigrations = ['nutrition_per_100'];

  Future<void> _ensureMigrationMarks() => customStatement(
    'CREATE TABLE IF NOT EXISTS $_migrationMarks ('
    'name TEXT NOT NULL PRIMARY KEY)',
  );

  Future<bool> _migrationDone(String name) async {
    await _ensureMigrationMarks();
    final rows = await customSelect(
      'SELECT 1 FROM $_migrationMarks WHERE name = ?',
      variables: [Variable<String>(name)],
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _markMigrationDone(String name) async {
    await _ensureMigrationMarks();
    await customStatement(
      "INSERT OR IGNORE INTO $_migrationMarks (name) VALUES ('$name')",
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // A database born at today's schema has today's meanings already,
      // so every value conversion in the history below is vacuously done.
      // Without this it would be a fresh install that a replayed upgrade
      // could still convert -- and converting correct values is exactly
      // the damage the marks exist to prevent.
      for (final mark in _valueMigrations) {
        await _markMigrationDone(mark);
      }
    },
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
        await _addColumnOnce(m, inventoryItems, inventoryItems.photoPath);
      }
      if (from < 5) {
        await _addColumnOnce(m, inventoryItems, inventoryItems.calories);
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
              inventoryItems.dailyDose,
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
        await _addColumnOnce(m, inventoryItems, inventoryItems.proteinGrams);
        await _addColumnOnce(
          m,
          inventoryItems,
          inventoryItems.carbohydrateGrams,
        );
        await _addColumnOnce(m, inventoryItems, inventoryItems.fatGrams);
        await _addColumnOnce(m, inventoryItems, inventoryItems.fiberGrams);
      }
      if (from < 10) {
        // A new table, so nothing to convert: an install that never had a
        // plan simply has none, and the screen says so.
        await m.createTable(householdPlans);
      }
      if (from < 11) {
        // Likewise. A household that never wrote a card has no cards, and
        // the head counts in the profile keep working on their own.
        await m.createTable(householdMembers);
      }
      if (from < 12) {
        // Installs older than 7 recreated the warning cache above from the
        // current definition, so its detail columns already exist. Some old
        // or partially repaired databases can lack the cache altogether;
        // recreate it in that case because warnings are fetched again anyway.
        if (from >= 7) {
          if (!await _hasTable('warnings')) {
            await m.createTable(warnings);
          } else {
            await _addColumnOnce(m, warnings, warnings.instruction);
            await _addColumnOnce(m, warnings, warnings.areaDescription);
            await _addColumnOnce(m, warnings, warnings.senderContact);
            await _addColumnOnce(m, warnings, warnings.polygonsJson);
          }
        }
      }
      if (from >= 10 && from < 13) {
        // The municipality's contact point on the household plan.
        //
        // `from >= 10` and not plain `from < 13`: anything older than 10
        // has no `household_plans` table yet and gets one created above
        // from the current definition, which already carries this column.
        //
        // Neither the table nor the column is assumed here, both are
        // looked for -- see [_addColumnOnce] for what assuming them cost.
        // A migration is the one piece of code that runs before the app
        // can say anything: if it throws, the app does not open at all
        // and there is no screen left to explain why.
        if (!await _hasTable('household_plans')) {
          await m.createTable(householdPlans);
        } else {
          await _addColumnOnce(
            m,
            householdPlans,
            householdPlans.localContactPoint,
          );
        }
      }
      if (from < 14) {
        // The household's possessions, for an insurer rather than for the
        // supply calculator. A new table, so nothing to convert.
        await m.createTable(possessions);
      }
      if (from >= 8 && from < 14) {
        // A medicine's daily dose, which is what turns a stock into a
        // number of days.
        //
        // `from >= 8` for the reason spelled out in the schema-8 branch:
        // anything older is rebuilt from today's definition there and
        // already has the column, so adding it again would be a second
        // `ALTER TABLE` on a table that has it.
        //
        // The table is looked for rather than assumed, like the warnings
        // cache above: a database repaired by hand or half-migrated can
        // be at version 10 with no `inventory_items` at all, and
        // `PRAGMA table_info` on a table that is not there answers the
        // same empty list as a table without the column -- so
        // [_addColumnOnce] would go ahead and the ALTER would take the
        // whole migration down.
        if (!await _hasTable('inventory_items')) {
          await m.createTable(inventoryItems);
        } else {
          await _addColumnOnce(m, inventoryItems, inventoryItems.dailyDose);
        }
      }
      if (from >= 8 && from < 15) {
        // `calories` was an integer and is now a real, so that a household
        // counting in grams can say 2.13 rather than 2.
        //
        // Nothing to convert: SQLite stores what it is given and every
        // existing value is a whole number that reads back as one. The
        // rebuild is only there so the column's declared type matches what
        // the generated code now expects to read.
        //
        // `from >= 8` for the reason the two branches above give: anything
        // older is rebuilt from today's definition in the schema-8 branch,
        // which already declares this column as a real. And no
        // `newColumns`, because at version 8 and later the table has every
        // column it has today.
        if (!await _hasTable('inventory_items')) {
          await m.createTable(inventoryItems);
        } else {
          await m.alterTable(TableMigration(inventoryItems));
        }
      }
      if (from < 16) {
        // Nutrition moves from "per stored unit" to "per 100 g / 100 ml",
        // which is what a label prints and therefore what nothing has to
        // convert on the way in.
        //
        // For energy the conversion is exact for every row the new rule
        // accepts, and that is the whole reason it is done here rather
        // than left to the household: a row counted in grams held
        // kilocalories per gram, so per 100 is a hundred times that; one
        // counted in kilograms held them per kilogram, so per 100 g is a
        // tenth. No rounding, no guessing, no package size involved.
        //
        // Rows counted in tins and jars are left exactly as they are.
        // There is no honest factor for them — what a tin of a particular
        // thing weighs is on the tin — and they are the rows the new rule
        // excludes from the calculator until somebody restates the unit.
        // Converting them by a guessed factor is the one thing that would
        // turn a visible gap into an invisible wrong number.
        //
        // **This one cannot simply be replayed**, which every migration
        // before it could. Drift writes the new version as a separate
        // statement after `onUpgrade` returns, so a process that dies in
        // between leaves the schema changed and the version where it was,
        // and the next launch runs these steps again -- see
        // `migration_rerun_test.dart`, which is where this was caught.
        // Adding a column twice throws and is at least loud; multiplying
        // a figure by a hundred twice is silent and wrong. So the step
        // records that it ran, and a replay steps over it.
        if (await _hasTable('inventory_items') &&
            !await _migrationDone('nutrition_per_100')) {
          for (final (factor, units) in const [
            (100.0, ['g', 'gr', 'gramm', 'gramme', 'gram', 'grams']),
            (0.1, ['kg', 'kilo', 'kilogramm', 'kilogram']),
            (100.0, ['ml', 'milliliter', 'millilitre']),
            (10.0, ['cl']),
            (1.0, ['dl']),
            (0.1, ['l', 'ltr', 'liter', 'litre', 'liters', 'litres']),
          ]) {
            final list = units.map((u) => "'$u'").join(', ');
            // Single quotes: SQLite reads a double-quoted token as an
            // identifier, so "." asked for a column called ".".
            await customStatement(
              'UPDATE inventory_items SET calories = calories * $factor '
              "WHERE calories IS NOT NULL AND category = 'food' "
              "AND lower(trim(replace(unit, '.', ''))) IN ($list)",
            );
          }
          await _markMigrationDone('nutrition_per_100');
        }
        // The macronutrients are deliberately **not** touched. They were
        // per package, and no package size was ever stored, so there is
        // no factor to apply. They are shown on the item and summed
        // nowhere, so a stale one is a wrong label rather than a wrong
        // plan — and one barcode scan replaces all four.
      }
    },
  );

  /// Permanently removes data owned by one local household. Used only by
  /// the explicit factory-reset action after its confirmation dialog.
  Future<void> deleteHouseholdData(String householdId) => transaction(() async {
    await (delete(
      checklistItems,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      checklistTemplates,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      inventoryItems,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      budgetEntries,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      householdPlans,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      householdMembers,
    )..where((t) => t.householdId.equals(householdId))).go();
    await (delete(
      possessions,
    )..where((t) => t.householdId.equals(householdId))).go();
  });

  // --- Household members ------------------------------------------------

  /// The household's people, in the order they were put in.
  Stream<List<HouseholdMember>> watchHouseholdMembers(String householdId) {
    return (select(householdMembers)
          ..where(
            (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.sortOrder),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<void> upsertHouseholdMember(HouseholdMembersCompanion member) {
    return _writeLocal(
      householdMembers,
      member.clientId.value,
      member.updatedAt.value,
      (timestamp) => member.copyWith(updatedAt: Value(timestamp)),
    );
  }

  Future<List<HouseholdMember>> dirtyHouseholdMembers(String householdId) {
    return (select(householdMembers)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<List<HouseholdMember>> householdMembersForSync(String householdId) {
    return (select(
      householdMembers,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  // --- Possessions -----------------------------------------------------

  /// What the household owns, grouped by room in the screen and ordered
  /// here so that rows from the same room arrive together.
  Stream<List<Possession>> watchPossessions(String householdId) {
    return (select(possessions)
          ..where(
            (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.room),
            (t) => OrderingTerm.asc(t.name),
          ]))
        .watch();
  }

  Future<void> upsertPossession(PossessionsCompanion possession) {
    return _writeLocal(
      possessions,
      possession.clientId.value,
      possession.updatedAt.value,
      (timestamp) => possession.copyWith(updatedAt: Value(timestamp)),
    );
  }

  Future<List<Possession>> dirtyPossessions(String householdId) {
    return (select(possessions)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<List<Possession>> possessionsForSync(String householdId) {
    return (select(
      possessions,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  /// Points one row at a picture that has just arrived from another device.
  ///
  /// Deliberately **not** an upsert: the stored path is local to this
  /// machine and belongs to no other device, so writing it must not touch
  /// `updatedAt` or raise `dirty`. If it did, taking in a photo would look
  /// to every other device like an edit and push the row straight back
  /// out again, with a path that means nothing over there.
  Future<int> setInventoryPhotoPath({
    required String householdId,
    required String clientId,
    required String photoPath,
  }) {
    return (update(inventoryItems)..where(
          (t) =>
              t.householdId.equals(householdId) & t.clientId.equals(clientId),
        ))
        .write(InventoryItemsCompanion(photoPath: Value(photoPath)));
  }

  /// The same for the possessions list. See [setInventoryPhotoPath].
  Future<int> setPossessionPhotoPath({
    required String householdId,
    required String clientId,
    required String photoPath,
  }) {
    return (update(possessions)..where(
          (t) =>
              t.householdId.equals(householdId) & t.clientId.equals(clientId),
        ))
        .write(PossessionsCompanion(photoPath: Value(photoPath)));
  }

  // --- Household plan --------------------------------------------------

  /// The household's plan, or null while there is none.
  ///
  /// Selected by [clientId] rather than by household, because for this one
  /// table they are the same value — see [HouseholdPlans]. A tombstoned
  /// plan reads as absent, which is what "we deleted it" should look like.
  Stream<HouseholdPlan?> watchHouseholdPlan(String householdId) {
    return (select(householdPlans)..where(
          (t) => t.clientId.equals(householdId) & t.deletedAt.isNull(),
        ))
        .watchSingleOrNull();
  }

  Future<void> upsertHouseholdPlan(HouseholdPlansCompanion plan) {
    return _writeLocal(
      householdPlans,
      plan.clientId.value,
      plan.updatedAt.value,
      (timestamp) => plan.copyWith(updatedAt: Value(timestamp)),
    );
  }

  Future<List<HouseholdPlan>> dirtyHouseholdPlans(String householdId) {
    return (select(householdPlans)..where(
          (t) => t.householdId.equals(householdId) & t.dirty.equals(true),
        ))
        .get();
  }

  Future<List<HouseholdPlan>> householdPlansForSync(String householdId) {
    return (select(
      householdPlans,
    )..where((t) => t.householdId.equals(householdId))).get();
  }

  // --- Inventory ------------------------------------------------------

  Stream<List<InventoryItem>> watchInventoryItems(String householdId) {
    return (select(inventoryItems)
          ..where(
            (t) => t.householdId.equals(householdId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// The item this household keeps under [barcode], or null.
  ///
  /// For booking a consumption by scanning: the same code that adds a tin
  /// is the one that takes it out again. Deleted rows are excluded — a
  /// tombstone still carries its barcode, and reviving one silently
  /// through a scan would undo a deliberate delete.
  ///
  /// The newest match wins if a household has the same code on two rows,
  /// which happens when a second pack is entered as its own item rather
  /// than added to the first.
  Future<InventoryItem?> findInventoryItemByBarcode(
    String householdId,
    String barcode,
  ) {
    return (select(inventoryItems)
          ..where(
            (t) =>
                t.householdId.equals(householdId) &
                t.deletedAt.isNull() &
                t.barcode.equals(barcode),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(1))
        .getSingleOrNull();
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
    return _writeLocal(
      inventoryItems,
      item.clientId.value,
      item.updatedAt.value,
      (timestamp) => item.copyWith(updatedAt: Value(timestamp)),
    );
  }

  /// Used by CSV import so hundreds of rows commit as a single batch
  /// instead of one write (and one sync nudge) per row.
  Future<void> upsertInventoryItems(List<InventoryItemsCompanion> items) {
    return transaction(() async {
      for (final item in items) {
        await upsertInventoryItem(item);
      }
    });
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
    return _writeLocal(
      checklistTemplates,
      template.clientId.value,
      template.updatedAt.value,
      (timestamp) => template.copyWith(updatedAt: Value(timestamp)),
    );
  }

  Future<void> upsertChecklistItem(ChecklistItemsCompanion item) {
    return _writeLocal(
      checklistItems,
      item.clientId.value,
      item.updatedAt.value,
      (timestamp) => item.copyWith(updatedAt: Value(timestamp)),
    );
  }

  /// Hides a seeded checklist row that the product no longer ships.
  ///
  /// A tombstone is synced so an older device cannot restore the row. A
  /// missing row is left missing, which keeps this safe on fresh installs.
  Future<void> retireChecklistItem(String clientId) async {
    final existing = await (select(
      checklistItems,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (existing == null || existing.deletedAt != null) return;

    final now = DateTime.now().toUtc();
    await upsertChecklistItem(
      existing
          .toCompanion(true)
          .copyWith(
            deletedAt: Value(now),
            updatedAt: Value(now),
            dirty: const Value(true),
          ),
    );
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
    return _writeLocal(
      budgetEntries,
      entry.clientId.value,
      entry.updatedAt.value,
      (timestamp) => entry.copyWith(updatedAt: Value(timestamp)),
    );
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

  /// The same thing for many, in one transaction.
  ///
  /// A poll used to write each row on its own, and every one of those was
  /// its own transaction — a journal write and an fsync apiece. This runs
  /// four times a day in a background isolate on a phone on battery, so
  /// 130 of them is not free.
  Future<void> upsertWarnings(List<WarningsCompanion> rows) async {
    if (rows.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(warnings, rows));
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

  /// Every warning of [source], keyed by the feed's own id.
  ///
  /// One query instead of one per warning. A German poll brings back
  /// upwards of 130 of them, and each was looked up twice: once to decide
  /// whether its full text needed fetching, once again to decide whether
  /// the row had moved. That is 260 round trips to answer a question about
  /// a table that fits in a page or two.
  Future<Map<String, Warning>> warningsBySource(String source) async {
    final rows = await (select(
      warnings,
    )..where((t) => t.source.equals(source))).get();
    return {for (final row in rows) row.externalId: row};
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
    final gone = active
        .where((w) => !seenExternalIds.contains(w.externalId))
        .toList();
    if (gone.isEmpty) return 0;

    // One transaction for the sweep. Written one row at a time it was one
    // transaction per retired warning, and a feed that quietens down after
    // a storm retires them by the dozen.
    await batch((b) {
      for (final warning in gone) {
        b.update(
          warnings,
          WarningsCompanion(expires: Value(now), updatedAt: Value(now)),
          where: (t) =>
              t.source.equals(warning.source) &
              t.externalId.equals(warning.externalId),
        );
      }
    });
    return gone.length;
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

  /// Acknowledges exactly the row versions present in the published file.
  /// A wall-clock cutoff is insufficient: edits can share a second, and
  /// logical timestamps may lead the clock after several rapid edits.
  Future<void> markHouseholdPublished(
    String householdId, {
    List<PublishedRow> inventory = const [],
    List<PublishedRow> templates = const [],
    List<PublishedRow> items = const [],
    List<PublishedRow> budget = const [],
    List<PublishedRow> plans = const [],
    List<PublishedRow> members = const [],
    List<PublishedRow> owned = const [],
  }) {
    return transaction(() async {
      for (final (table, rows)
          in <(TableInfo<Table, Object?>, List<PublishedRow>)>[
            (inventoryItems, inventory),
            (checklistTemplates, templates),
            (checklistItems, items),
            (budgetEntries, budget),
            (householdPlans, plans),
            (householdMembers, members),
            (possessions, owned),
          ]) {
        for (final row in rows) {
          await customUpdate(
            'UPDATE "${table.actualTableName}" SET dirty = 0 '
            'WHERE household_id = ? AND client_id = ? AND updated_at = ?',
            variables: [
              Variable(householdId),
              Variable(row.clientId),
              Variable(row.updatedAt.millisecondsSinceEpoch ~/ 1000),
            ],
            updates: {table},
          );
        }
      }
    });
  }

  /// `updatedAt` doubles as a logical version at SQLite's second precision.
  /// Local edits always advance beyond the version actually stored, even
  /// after a rapid second edit or a clock correction. The transaction
  /// serializes competing local writers. Remote merges bypass this path.
  Future<void> _writeLocal<T extends Table, R>(
    TableInfo<T, R> table,
    String clientId,
    DateTime requested,
    Insertable<R> Function(DateTime) companion,
  ) {
    return transaction(() async {
      final existing = await customSelect(
        'SELECT updated_at FROM "${table.actualTableName}" WHERE client_id = ?',
        variables: [Variable(clientId)],
        readsFrom: {table},
      ).getSingleOrNull();
      var seconds = requested.millisecondsSinceEpoch ~/ 1000;
      final previous = existing?.read<int>('updated_at');
      if (previous != null && seconds <= previous) seconds = previous + 1;
      await into(table).insertOnConflictUpdate(
        companion(
          DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true),
        ),
      );
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

      await (update(
        householdMembers,
      )..where((t) => t.householdId.equals(from))).write(
        HouseholdMembersCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );

      await (update(
        possessions,
      )..where((t) => t.householdId.equals(from))).write(
        PossessionsCompanion(
          householdId: Value(to),
          dirty: const Value(true),
        ),
      );

      // The plan cannot be re-stamped like the rest. Its `clientId` *is*
      // the household id — that is what makes two devices edit one record
      // instead of one each — so a plan left under the old key would stop
      // being the household's plan and start being an orphan that syncs
      // forever without ever being shown. It is moved to the new key,
      // keeping its `updatedAt` so the folder's own plan can still win.
      final plan = await (select(
        householdPlans,
      )..where((t) => t.clientId.equals(from))).getSingleOrNull();
      if (plan != null) {
        await (delete(
          householdPlans,
        )..where((t) => t.clientId.equals(from))).go();
        await into(householdPlans).insertOnConflictUpdate(
          plan
              .toCompanion(false)
              .copyWith(
                clientId: Value(to),
                householdId: Value(to),
                dirty: const Value(true),
              ),
        );
      }
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
    List<IncomingRow<HouseholdPlansCompanion>> plans = const [],
    List<IncomingRow<HouseholdMembersCompanion>> members = const [],
    List<IncomingRow<PossessionsCompanion>> owned = const [],
  }) {
    return transaction(() async {
      var changed = 0;
      changed += await _mergeInto(
        inventoryItems,
        inventory,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        checklistTemplates,
        templates,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        checklistItems,
        items,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        budgetEntries,
        budget,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        householdPlans,
        plans,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        householdMembers,
        members,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      changed += await _mergeInto(
        possessions,
        owned,
        (row) => (clientId: row.clientId, updatedAt: row.updatedAt),
        (row) => row.toCompanion(false),
      );
      return changed;
    });
  }

  /// Orders versions by timestamp, then by the canonical shared contents.
  /// Equal timestamps do not imply equal contents: two devices can edit a
  /// shared clientId independently. Tombstones win ties over live rows.
  /// Local-only columns never participate, and identical replays are free.
  Future<int> _mergeInto<T extends Table, R, C extends UpdateCompanion<R>>(
    TableInfo<T, R> table,
    List<IncomingRow<C>> incoming,
    ({String clientId, DateTime updatedAt}) Function(R) identify,
    C Function(R) companionOf,
  ) async {
    if (incoming.isEmpty) return 0;
    final stored = {
      for (final row in await select(table).get())
        identify(row).clientId: (
          seconds: identify(row).updatedAt.millisecondsSinceEpoch ~/ 1000,
          contents: _sharedContents(companionOf(row)),
        ),
    };
    var changed = 0;
    for (final candidate in incoming) {
      final version = (
        seconds: candidate.updatedAt.millisecondsSinceEpoch ~/ 1000,
        contents: _sharedContents(candidate.companion),
      );
      final previous = stored[candidate.clientId];
      if (previous != null &&
          (version.seconds < previous.seconds ||
              (version.seconds == previous.seconds &&
                  version.contents.compareTo(previous.contents) <= 0))) {
        continue;
      }
      await into(table).insertOnConflictUpdate(candidate.companion);
      // Also compare against rows accepted earlier in this same snapshot.
      stored[candidate.clientId] = version;
      changed++;
    }
    return changed;
  }

  static String _sharedContents(UpdateCompanion<Object?> companion) {
    final columns = companion.toColumns(false)
      ..remove('dirty')
      ..remove('photo_path')
      ..remove('updated_at');
    final names = columns.keys.toList()..sort();
    Object? valueOf(String name) {
      final value = (columns[name] as Variable).value;
      return value is DateTime ? value.millisecondsSinceEpoch ~/ 1000 : value;
    }

    final deleted =
        columns.containsKey('deleted_at') && valueOf('deleted_at') != null;
    return '${deleted ? 1 : 0}${jsonEncode({
      for (final name in names) name: valueOf(name),
    })}';
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
  // Not the default directory: see `appDatabaseDirectory` for why the
  // documents folder is the wrong place for this file.
  return driftDatabase(
    name: 'preppsuite',
    native: DriftNativeOptions(databaseDirectory: appDatabaseDirectory),
  );
}

/// Identity of one immutable version acknowledged by a successful upload.
typedef PublishedRow = ({String clientId, DateTime updatedAt});
