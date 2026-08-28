import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/budget/application/budget_sync_controller.dart';
import '../features/checklists/application/checklist_sync_controller.dart';
import '../features/inventory/application/inventory_sync_controller.dart';
import '../features/warnings/application/warning_sync_controller.dart';

/// How often the app looks for changes made on another device.
const syncInterval = Duration(seconds: 60);

/// The single clock for background sync.
///
/// Each entity used to keep its own periodic timer, so four of them ran
/// side by side and fired four overlapping sync passes — up to eight
/// requests at once on a connection that may be a phone's. They run one
/// after another now, on one timer, and the cadence lives in one place
/// instead of four.
///
/// The bigger gain is [_handleLifecycle]: the old timers kept firing while
/// the app sat in the background, which on a phone is the one thing worth
/// not doing. Local edits are unaffected either way — those push straight
/// away through each controller's own debounce.
///
/// Invisible, like `ExpiryReminderScheduler`; lives in [HomeShell] so it
/// stays mounted for the whole session.
class SyncScheduler extends ConsumerStatefulWidget {
  const SyncScheduler({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<SyncScheduler> createState() => _SyncSchedulerState();
}

class _SyncSchedulerState extends ConsumerState<SyncScheduler> {
  Timer? _timer;
  AppLifecycleListener? _lifecycle;

  /// Guards against a second pass starting while one is still running — a
  /// slow connection would otherwise stack them up.
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _handleLifecycle);
    _start();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle?.dispose();
    super.dispose();
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(syncInterval, (_) => _syncAll());
  }

  void _handleLifecycle(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // Catch up immediately rather than waiting out the interval — the
        // first thing someone does on returning is look at the data.
        _start();
        unawaited(_syncAll());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _timer?.cancel();
        _timer = null;
    }
  }

  /// Runs the entities one after another. Order is deliberate: warnings
  /// first because they are the time-critical ones, then the rest.
  Future<void> _syncAll() async {
    if (_running || !mounted) return;
    _running = true;
    try {
      final id = widget.householdId;
      await ref.read(warningSyncControllerProvider(id).notifier).syncNow();
      if (!mounted) return;
      await ref.read(inventorySyncControllerProvider(id).notifier).syncNow();
      if (!mounted) return;
      await ref.read(checklistSyncControllerProvider(id).notifier).syncNow();
      if (!mounted) return;
      await ref.read(budgetSyncControllerProvider(id).notifier).syncNow();
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
