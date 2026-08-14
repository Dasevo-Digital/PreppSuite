import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../local_db/database.dart';

export '../../../core/app_database_providers.dart';

/// Not-yet-expired warnings — drives the app-wide banner.
final activeWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) => ref.watch(appDatabaseProvider).watchActiveWarnings(),
);

/// Full history, including expired warnings — the dedicated warnings screen.
final allWarningsProvider = StreamProvider.autoDispose<List<Warning>>(
  (ref) => ref.watch(appDatabaseProvider).watchAllWarnings(),
);
