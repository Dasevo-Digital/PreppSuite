import 'package:drift/drift.dart';

/// One line on a checklist. [templateClientId] links to
/// [ChecklistTemplates.clientId], which is stable across devices — so an
/// item and its template survive a trip through a shared folder together,
/// in either order.
class ChecklistItems extends Table {
  TextColumn get clientId => text()();
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
