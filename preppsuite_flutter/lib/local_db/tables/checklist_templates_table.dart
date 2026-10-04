import 'package:drift/drift.dart';

/// A checklist. [isBuiltIn] marks the templates the app seeds itself;
/// those carry fixed [clientId]s so two devices seed the same rows rather
/// than two copies of each.
@TableIndex(name: 'checklist_templates_household', columns: {#householdId})
class ChecklistTemplates extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text().nullable()();

  TextColumn get title => text()();

  /// Stores a `ChecklistCategory` enum name (see
  /// `lib/model/categories.dart`) as plain text.
  TextColumn get category => text()();

  /// Stores a `ChecklistKind` enum name — preparation or response.
  ///
  /// Defaulted rather than nullable, because every list is one or the
  /// other and a third state would only have to be decided again on
  /// every screen that reads it. Rows written before schema 17 come back
  /// as `preparation`; the built-in ones are put right by
  /// `ChecklistSeeder` on the next launch.
  TextColumn get kind => text().withDefault(const Constant('preparation'))();

  BoolColumn get isBuiltIn => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
