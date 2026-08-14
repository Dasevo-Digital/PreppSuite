import 'package:drift/drift.dart';

/// Local mirror of the server's `ChecklistItem`. [templateClientId] links to
/// [ChecklistTemplates.clientId] — the *local* id, not the server id, so an
/// item created offline can reference its (also not-yet-synced) template
/// immediately. The sync service is responsible for resolving this to the
/// template's server id when pushing (see `SyncService.syncChecklists`).
class ChecklistItems extends Table {
  TextColumn get clientId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get householdId => text().nullable()();
  TextColumn get templateClientId => text()();

  TextColumn get title => text()();
  RealColumn get targetQuantity => real().nullable()();
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  TextColumn get linkedInventoryItemId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
