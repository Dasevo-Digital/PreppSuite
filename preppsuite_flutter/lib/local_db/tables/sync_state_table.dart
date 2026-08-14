import 'package:drift/drift.dart';

/// One row per syncable entity type, tracking the last successful pull
/// cursor. Advanced to the max `updatedAt` seen in a pull response (not
/// `now()`) to avoid missing rows to client/server clock skew.
class SyncState extends Table {
  TextColumn get entity => text()();
  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entity};
}
