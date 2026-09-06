import 'package:drift/drift.dart';

/// The household's emergency plan: where to meet, who to call.
///
/// The BBK's advice that no app has been carrying: agree a meeting point
/// before you need one, and pick someone outside the region everyone
/// rings — local lines are the first thing to congest, and a call to the
/// next town often gets through when a call across the street does not.
///
/// Exactly one row per household, and [clientId] *is* the household id
/// rather than a generated one. That is a deliberate break from the rule
/// everywhere else in this database, and it is what makes the plan a
/// single record two devices can both edit: they write the same key, and
/// last-writer-wins settles it. A generated id would give each device its
/// own plan, and the two would never converge.
///
/// The consequence is that joining a folder has to re-key this row — see
/// `adoptHouseholdId`.
class HouseholdPlans extends Table {
  /// The household id, not a generated id. See the class comment.
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  /// Where to gather if the house has to be left in a hurry — the corner,
  /// the neighbour's drive. Somewhere reachable on foot without a plan.
  TextColumn get meetingPointNear => text().nullable()();

  /// Where to gather if the whole area is cleared and the near one cannot
  /// be reached.
  TextColumn get meetingPointFar => text().nullable()();

  /// Someone outside the region everyone can ring to say where they are.
  TextColumn get contactName => text().nullable()();
  TextColumn get contactPhone => text().nullable()();

  /// Where the emergency luggage is kept, so nobody searches for it in
  /// the dark.
  TextColumn get kitLocation => text().nullable()();

  /// Where the water, gas and power can be shut off.
  TextColumn get shutoffLocation => text().nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
