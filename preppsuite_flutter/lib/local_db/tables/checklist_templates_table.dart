import 'package:drift/drift.dart';

/// Local mirror of the server's `ChecklistTemplate`. [householdId] is null
/// for built-in templates shared read-only across all households.
class ChecklistTemplates extends Table {
  TextColumn get clientId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get householdId => text().nullable()();

  TextColumn get title => text()();

  /// Stores a `ChecklistCategory` enum name (see
  /// `package:preppsuite_client`) as plain text.
  TextColumn get category => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
