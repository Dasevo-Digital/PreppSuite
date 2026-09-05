import 'package:drift/drift.dart';

/// When each kind of sync last completed. Only read to tell the user how
/// current their shared folder is — the merge itself derives nothing from
/// it, because a snapshot-based merge has nothing to catch up on.
class SyncState extends Table {
  TextColumn get entity => text()();
  DateTimeColumn get lastPulledAt => dateTime()();

  @override
  Set<Column> get primaryKey => {entity};
}
