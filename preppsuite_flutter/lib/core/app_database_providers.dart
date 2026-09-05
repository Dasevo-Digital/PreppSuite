import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local_db/database.dart';

/// App-wide singleton: the local SQLite database is the UI's source of
/// truth, independent of network/auth state. Shared by every feature
/// (inventory, checklists, budget, ...).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
