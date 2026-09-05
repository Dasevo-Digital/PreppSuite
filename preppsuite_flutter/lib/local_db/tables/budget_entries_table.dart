import 'package:drift/drift.dart';

/// One purchase, for the budget overview.
class BudgetEntries extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  TextColumn get label => text()();

  /// Integer cents, to avoid floating-point money.
  IntColumn get amountCents => integer()();
  TextColumn get currency => text()();

  /// Stores an `InventoryItemCategory` enum name as plain text.
  TextColumn get category => text()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  TextColumn get linkedInventoryItemId => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
