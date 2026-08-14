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

  /// Total kcal for the item's current [quantity] (not per-unit) — only
  /// meaningful for `category: food`. Powers the "Vorräte für X Tage"
  /// supply calculator (`supply_calculator.dart`).
  IntColumn get calories => integer().nullable()();

  TextColumn get notes => text().nullable()();

  /// Path to a locally-stored photo of the item (see
  /// `inventory_photo_service.dart`), relative to the app's documents
  /// directory. Local-only for now — photo sync is a future server-side
  /// feature (binary uploads need their own endpoint, not the generic
  /// JSON push/pull sync channel; see docs/sync-protocol.md's treatment of
  /// large assets like map tiles for the established precedent).
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
