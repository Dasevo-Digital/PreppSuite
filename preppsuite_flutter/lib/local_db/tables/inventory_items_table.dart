import 'package:drift/drift.dart';

/// Local mirror of the server's `InventoryItem`. [clientId] is the row's
/// stable local identity (generated on first insert, before any sync);
/// [serverId] is filled in once the row has been pushed and echoed back.
/// [dirty] marks rows with local edits not yet confirmed pushed.
class InventoryItems extends Table {
  TextColumn get clientId => text()();
  TextColumn get serverId => text().nullable()();
  TextColumn get householdId => text()();

  TextColumn get name => text()();

  /// Stores an [InventoryItemCategory] enum name (see
  /// `package:preppsuite_client`), kept as plain text here so this table
  /// doesn't need to depend on the generated protocol package.
  TextColumn get category => text()();

  TextColumn get barcode => text().nullable()();
  TextColumn get offProductId => text().nullable()();
  RealColumn get quantity => real()();
  TextColumn get unit => text()();
  TextColumn get storageLocation => text()();
  DateTimeColumn get expirationDate => dateTime().nullable()();
  RealColumn get minQuantity => real().nullable()();
  TextColumn get notes => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
