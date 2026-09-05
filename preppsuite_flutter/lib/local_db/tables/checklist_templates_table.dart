import 'package:drift/drift.dart';

/// A checklist. [isBuiltIn] marks the templates the app seeds itself;
/// those carry fixed [clientId]s so two devices seed the same rows rather
/// than two copies of each.
class ChecklistTemplates extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text().nullable()();

  TextColumn get title => text()();

  /// Stores a `ChecklistCategory` enum name (see
  /// `lib/model/categories.dart`) as plain text.
  TextColumn get category => text()();
  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
