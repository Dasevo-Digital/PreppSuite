import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/budget/application/budget_sync_controller.dart';
import '../features/checklists/application/checklist_sync_controller.dart';
import '../features/inventory/application/inventory_sync_controller.dart';
import 'sync_status.dart';

/// One full sync pass over every entity, and the record of how it went.
///
/// Lives behind a provider rather than inside the scheduling widget so the
/// clock and the "try again" button share one path — and one guard against
/// overlapping passes.
class SyncRunner {
  SyncRunner(this._ref);

  final Ref _ref;

  /// Guards against a second pass starting while one is still running — a
  /// slow connection would otherwise stack them up.
  bool _running = false;

  bool get isRunning => _running;

  /// Runs the entities one after another.
  ///
  /// Warnings are no longer part of this: the app fetches them itself from
  /// the public feeds, on its own schedule, and a failure there says
  /// nothing about whether the household's own data is in step. Mixing the
  /// two made an unreachable BBK look like a broken sync.
  ///
  /// The controllers swallow their own errors into their state rather than
  /// throwing, so the outcome is read back from there afterwards. That is
  /// what feeds [syncStatusProvider], and through it the banner.
  Future<void> runPass(String householdId) async {
    if (_running) return;
    _running = true;
    try {
      await _ref
          .read(inventorySyncControllerProvider(householdId).notifier)
          .syncNow();
      await _ref
          .read(checklistSyncControllerProvider(householdId).notifier)
          .syncNow();
      await _ref
          .read(budgetSyncControllerProvider(householdId).notifier)
          .syncNow();

      // One failing entity is enough to count the pass as failed: a
      // household whose checklists arrive but whose inventory does not is
      // exactly as out of step as one where nothing arrives.
      final failed = [
        _ref.read(inventorySyncControllerProvider(householdId)),
        _ref.read(checklistSyncControllerProvider(householdId)),
        _ref.read(budgetSyncControllerProvider(householdId)),
      ].any((state) => state.hasError);

      final status = _ref.read(syncStatusProvider.notifier);
      final now = DateTime.now();
      if (failed) {
        status.recordFailure(now);
      } else {
        status.recordSuccess(now);
      }
    } finally {
      _running = false;
    }
  }
}

final syncRunnerProvider = Provider<SyncRunner>(SyncRunner.new);
