import 'package:drift/drift.dart';

/// One thing the household owns, written down before it is gone.
///
/// **Not the same list as [InventoryItems], and deliberately so.** That
/// one answers "how long do the stores last" — it has quantities, expiry
/// dates and calories, and the supply calculator adds it up. This one
/// answers "what did we lose", which is a question an insurer asks after
/// a fire, a flood or a break-in, and which nobody can answer from memory
/// under those circumstances. Mixing them would put a washing machine
/// into the calorie target.
///
/// The idea is FEMA's ("document and insure your property now"); the
/// fields are what a claim actually needs: what it is, where it stood,
/// what it cost, and a picture.
@TableIndex(name: 'possessions_household', columns: {#householdId})
class Possessions extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  TextColumn get name => text()();

  /// Free text rather than an enum. An insurer's list is grouped by room,
  /// and a household's rooms are its own — "Dachboden", "Garage",
  /// "Wohnwagen" are all answers no fixed list would have held.
  TextColumn get room => text().nullable()();

  /// The one field that cannot be reconstructed after the fact, which is
  /// why it is here at all.
  TextColumn get serialNumber => text().nullable()();

  DateTimeColumn get acquiredOn => dateTime().nullable()();

  /// Integer cents, like [BudgetEntries] — money is never a double here.
  /// What was paid, not what it is worth today: the first is a fact the
  /// household has a receipt for, the second is an opinion an insurer
  /// forms.
  IntColumn get purchasePriceCents => integer().nullable()();
  TextColumn get currency => text().nullable()();

  TextColumn get notes => text().nullable()();

  /// Path to a locally-stored photo, relative to the app's documents
  /// directory — same convention as [InventoryItems.photoPath], and
  /// device-local for the same reason: the path means nothing elsewhere
  /// and the picture is not in the shared folder.
  ///
  /// Which is worth saying out loud for this table in particular: the
  /// photo is the most persuasive part of a claim and it lives only on
  /// the device that took it. That is what the PDF export is for.
  TextColumn get photoPath => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
