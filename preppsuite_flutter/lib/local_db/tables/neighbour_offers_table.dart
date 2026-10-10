import 'package:drift/drift.dart';

/// What the household offers its neighbours, and what neighbours have
/// offered it (#152).
///
/// **Only what somebody typed.** An offer is a kind, a line of text and,
/// if its author wants one, a way to reach them -- nothing read out of the
/// inventory, no address the app knows, no position. It travels as a QR
/// code from one phone to another and nowhere else: there is no server to
/// publish it on, and that is the point. Whoever scans it holds exactly
/// what was on the screen.
///
/// One table for both directions, told apart by [received]: the
/// household's own offers, which it shows as a code, and the ones it has
/// scanned, which it keeps as a list of who nearby has what. Both belong
/// to the household and travel with it to its other devices like every
/// other table, because the phone that scanned a neighbour's offer is not
/// necessarily the one in somebody's hand when it is needed.
@TableIndex(name: 'neighbour_offers_household', columns: {#householdId})
class NeighbourOffers extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  /// False for the household's own offers, true for scanned ones.
  BoolColumn get received => boolean().withDefault(const Constant(false))();

  /// `NeighbourOfferKind.name`. Text rather than an index, so a kind
  /// added later reads as "other" on an older app instead of as the
  /// wrong one.
  TextColumn get kind => text()();

  /// The offer itself, as its author wrote it: "20 l Trinkwasser".
  TextColumn get body => text()();

  /// How to reach whoever made it, as they chose to put it -- "Haus 4,
  /// 2. Stock", a first name, a phone number. Never filled in by the app.
  TextColumn get contact => text().nullable()();

  /// The day the offer was made, by its author. Carried in the code, so a
  /// scanned offer says how old it is: water offered in March is not
  /// necessarily still there in October.
  DateTimeColumn get offeredOn => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
