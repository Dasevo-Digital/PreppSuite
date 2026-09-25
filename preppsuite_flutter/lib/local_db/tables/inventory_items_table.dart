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

  /// Kilocalories per **100 g**, or per 100 ml where [unit] is a volume
  /// — exactly as a label prints it.
  ///
  /// Only meaningful for `category: food`. The household's total is
  /// `calories / 100 * ` the stock reduced to grams or millilitres; see
  /// `food_amount.dart`, which is also what decides whether [unit] can be
  /// reduced at all.
  ///
  /// This column has meant three things, and the first two were both
  /// wrong for the same reason. It began as a total for the stock, which
  /// nothing could maintain: `consumeQuantity` lowers the quantity and
  /// cannot rescale a figure whose basis it does not know. It then became
  /// a figure per stored unit, which survived that but pushed the
  /// conversion onto the scanner — and the scanner had to guess a package
  /// size to do it, which is where both of the bugs after it came from.
  ///
  /// Per 100 is what the label says. Nothing converts on the way in, so
  /// there is nothing to get wrong on the way in; the arithmetic happens
  /// once, where the quantity is known.
  RealColumn get calories => real().nullable()();

  /// Macronutrients on the same basis: grams per 100 g, or per 100 ml.
  ///
  /// The same basis as [calories] now, which it did not use to be — these
  /// were per package while the energy was per unit, and a reader had to
  /// know that. Filled in from the barcode (see
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

  /// Which of the BLE's supply groups this row counts towards, as a
  /// `SupplyGroup` enum name — or null, which is what almost every row
  /// starts as.
  ///
  /// Set by the household and never guessed. "Nudeln" is grain and
  /// "Öl" is fats often enough that a keyword rule would look clever, and
  /// it would be wrong the once somebody stored nut oil under a brand
  /// name. The same reason `dailyDose` is asked for rather than derived.
  ///
  /// Only meaningful on `food` and `water` rows; see
  /// `supply_groups.dart`, which also explains why the axis is the BLE's
  /// groups and not nutrients.
  TextColumn get foodGroup => text().nullable()();

  /// Lead times for this one item's expiry reminders, as a
  /// comma-separated list of days — or null to follow the household's
  /// own setting, which is what nearly every row does.
  ///
  /// Three states, and the middle one is the reason this is text and not
  /// a number: null is "whatever the household picked", an empty string
  /// is "this item, never" — a jar of salt that outlives everyone does
  /// not need a reminder at all — and a list is this item's own.
  /// A single integer column could not tell the first two apart, and
  /// could not carry two reminders either.
  ///
  /// Not validated by the database. The form only ever writes the same
  /// round numbers the settings offer, and `decodeItemLeadDays` throws
  /// nothing away except what cannot be a day.
  TextColumn get expiryLeadDays => text().nullable()();

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
