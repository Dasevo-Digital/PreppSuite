import 'dart:async';

import 'package:drift/drift.dart';

/// Tests deliberately open separate in-memory databases for source and target
/// households. Drift's debug-only global warning cannot distinguish those
/// isolated executors from two wrappers around one real file, so it made a
/// clean suite look like a data-corruption warning on every run.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}
