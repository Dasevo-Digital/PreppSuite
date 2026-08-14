import 'package:drift/drift.dart';

/// Local, read-only mirror of the server's `Warning`. Unlike every other
/// table here, this one is pull-only — there's no `dirty`/push path, since
/// warnings are entirely server-generated (see `WarningPollFutureCall` on
/// the server).
class Warnings extends Table {
  TextColumn get serverId => text()();
  TextColumn get source => text()();
  TextColumn get externalId => text()();
  TextColumn get countryCode => text()();
  TextColumn get regionKey => text().nullable()();

  /// Stores a `WarningSeverity` enum name as plain text.
  TextColumn get severity => text()();
  TextColumn get eventType => text()();
  TextColumn get headline => text()();
  TextColumn get description => text().nullable()();

  DateTimeColumn get effective => dateTime()();
  DateTimeColumn get expires => dateTime().nullable()();
  DateTimeColumn get sent => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {serverId};
}
