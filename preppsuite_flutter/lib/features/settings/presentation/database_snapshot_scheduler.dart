import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_providers.dart';
import '../../../core/database_snapshots.dart';
import '../../../core/local_database_encryption.dart';

/// Takes the day's copy of the database a little after the household has
/// opened (#140). Draws nothing.
///
/// Not at once: the first seconds belong to the screen somebody opened
/// the app for. A copy of a household's database is a few hundred
/// kilobytes and takes a moment, but it takes it on the database's own
/// thread, and nothing about it is urgent.
class DatabaseSnapshotScheduler extends ConsumerStatefulWidget {
  const DatabaseSnapshotScheduler({super.key});

  static const delay = Duration(seconds: 30);

  @override
  ConsumerState<DatabaseSnapshotScheduler> createState() =>
      _DatabaseSnapshotSchedulerState();
}

class _DatabaseSnapshotSchedulerState
    extends ConsumerState<DatabaseSnapshotScheduler> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(DatabaseSnapshotScheduler.delay, _take);
  }

  Future<void> _take() async {
    if (!mounted) return;
    try {
      final database = ref.read(appDatabaseProvider);
      await DatabaseSnapshots(
        LocalDatabaseEncryption.instance.databaseFile(localDatabaseFilePrefix),
      ).takeIfDue(database.snapshotTo);
    } on Object {
      // A full disk or a database busy migrating: tomorrow, or at the
      // next start.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
