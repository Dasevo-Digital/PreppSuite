import 'package:drift/drift.dart';

/// One person in the household, and what an ambulance would want to know.
///
/// The household profile counts heads — how many adults, children, dogs,
/// cats — because that is all the supply calculator needs. This is the
/// other half: who they actually are. Kept apart from the profile on
/// purpose, because the profile is device-local settings and this is
/// household data that has to reach every device.
///
/// **This is health data.** It travels through the shared folder like
/// everything else, which is why the folder can be encrypted — see
/// `folder_crypto.dart`. Every field below is optional: a card with a
/// name and an allergy is worth having, and a form that demanded a blood
/// type would get no card at all.
class HouseholdMembers extends Table {
  TextColumn get clientId => text()();
  TextColumn get householdId => text()();

  TextColumn get name => text()();

  /// Year only, not a date. It is asked for so a paramedic knows roughly
  /// who they are treating; a birthday would be more than the reason
  /// needs, and this app does not collect more than it uses.
  IntColumn get birthYear => integer().nullable()();

  TextColumn get bloodType => text().nullable()();
  TextColumn get allergies => text().nullable()();

  /// What they take regularly — the thing a household has to keep in the
  /// stores and the thing that must not be guessed at in an emergency.
  TextColumn get medication => text().nullable()();

  TextColumn get conditions => text().nullable()();
  TextColumn get insurance => text().nullable()();
  TextColumn get doctor => text().nullable()();

  /// Who to call about this person specifically.
  TextColumn get emergencyContact => text().nullable()();

  TextColumn get notes => text().nullable()();

  /// Keeps the cards in the order the household put them in rather than
  /// alphabetically, which would put a child before a parent for no
  /// reason anyone chose.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  BoolColumn get dirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {clientId};
}
