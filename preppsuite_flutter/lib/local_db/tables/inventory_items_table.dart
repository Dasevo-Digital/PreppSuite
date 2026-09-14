import 'package:drift/drift.dart';

/// A stored supply. [clientId] is the row's identity everywhere — it is
/// generated once, on the device that created the row, and is what a
/// shared folder matches rows by. [dirty] marks local edits that have not
/// been published to that folder yet.
class InventoryItems extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  TextColumn get name => text()();

  /// Stores an `InventoryItemCategory` enum name (see
  /// `lib/model/categories.dart`) as plain text — which is why renaming a
  /// value there silently orphans existing rows.
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

  /// Macronutrients for the item's current [quantity], in grams — the
  /// same "whole item, not per 100 g" convention as [calories], for the
  /// same reason: a shelf is then a sum. Filled in from the barcode (see
  /// `open_food_facts_service.dart`) or by hand, and null wherever the
  /// label does not say, which is most non-food supplies.
  RealColumn get proteinGrams => real().nullable()();
  RealColumn get carbohydrateGrams => real().nullable()();
  RealColumn get fatGrams => real().nullable()();
  RealColumn get fiberGrams => real().nullable()();

  /// How much of [unit] is taken each day, for a medicine.
  ///
  /// The one figure that turns a stock into an answer: two tablets a day
  /// out of sixty is a month. Null everywhere else, and null on a
  /// medicine whose dose the household has not typed in — which stays a
  /// stock without an answer rather than becoming a guessed one.
  ///
  /// In the item's own [unit] on purpose. A dose in milligrams against a
  /// stock in tablets would need the strength per tablet, and that is a
  /// second number off the same packet for no gain: whoever counts
  /// tablets knows how many a day.
  RealColumn get dailyDose => real().nullable()();

  TextColumn get notes => text().nullable()();

  /// Path to a locally-stored photo of the item (see
  /// `inventory_photo_service.dart`), relative to the app's documents
  /// directory. Device-local and deliberately never shared: the path means
  /// nothing on another device, and the picture itself is not in the
  /// folder. The shared-folder merge leaves this column alone.
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
