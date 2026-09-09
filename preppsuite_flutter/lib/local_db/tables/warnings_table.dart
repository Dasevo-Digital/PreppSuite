import 'package:drift/drift.dart';

/// Warnings fetched straight from the public BBK and MeteoAlarm feeds by
/// `WarningPollService`. A cache, not owned data: nothing here is ever
/// pushed anywhere, and losing it costs nothing but the next poll.
///
/// Identity is `(source, externalId)` — what the feeds themselves use to
/// mean "the same warning". It used to be a server-assigned id, which only
/// made sense while a server was doing the fetching.
class Warnings extends Table {
  /// A `WarningSource` enum name as plain text.
  TextColumn get source => text()();

  /// The feed's own id for this warning.
  TextColumn get externalId => text()();

  TextColumn get countryCode => text()();
  TextColumn get regionKey => text().nullable()();

  /// Stores a `WarningSeverity` enum name as plain text.
  TextColumn get severity => text()();
  TextColumn get eventType => text()();
  TextColumn get headline => text()();
  TextColumn get description => text().nullable()();
  TextColumn get instruction => text().nullable()();
  TextColumn get areaDescription => text().nullable()();
  TextColumn get senderContact => text().nullable()();
  TextColumn get polygonsJson => text().nullable()();

  DateTimeColumn get effective => dateTime()();
  DateTimeColumn get expires => dateTime().nullable()();
  DateTimeColumn get sent => dateTime()();

  /// When this row was last written locally. Drives "what is new since I
  /// last looked", which is what decides whether to notify.
  DateTimeColumn get updatedAt => dateTime()();

  /// True once a notification has gone out for this warning, so a repeated
  /// poll does not announce the same thing again. Separate from
  /// [updatedAt] because a warning can be rewritten by its source without
  /// becoming newsworthy again.
  BoolColumn get notified => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {source, externalId};
}
