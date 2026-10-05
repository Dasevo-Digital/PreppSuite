import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

/// Every local database this isolate has open, so a quit can close them
/// all (#113).
///
/// `ClosesDatabasesOnExit` used to close the two it could reach through
/// providers: the household and the index of the selected archive. Others
/// are opened outside any provider the quit knows about -- the search over
/// personal documents opens its index per query, the indexer and the
/// settings screen open one for a moment -- and one of those left open at
/// the wrong time is enough. Drift keeps its SQLite handles on a
/// background isolate, and when the engine takes that isolate down the
/// native finalizers call `sqlite3_finalize` while the VM is dismantled
/// around them. In 2.4.1 that segfaulted on quit again.
///
/// So the databases report themselves here instead of being looked for:
/// each class adds itself when it opens and removes itself in `close`.
abstract final class OpenDatabases {
  static final _open = <GeneratedDatabase>{};

  /// Called by a database as it opens.
  static void track(GeneratedDatabase database) => _open.add(database);

  /// Called by a database from its `close`.
  static void untrack(GeneratedDatabase database) => _open.remove(database);

  @visibleForTesting
  static int get count => _open.length;

  /// Closes every database still open. One that fails to close does not
  /// keep the others open.
  static Future<void> closeAll() async {
    for (final database in _open.toList()) {
      try {
        await database.close();
      } on Object {
        untrack(database);
      }
    }
  }
}
