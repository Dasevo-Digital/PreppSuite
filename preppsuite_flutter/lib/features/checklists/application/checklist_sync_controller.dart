import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'checklist_providers.dart';

/// Drives checklist sync for one household — same cadence as
/// `InventorySyncController` (immediate + 60s periodic + 2s debounce after
/// writes). See that class for the reasoning; kept as a separate controller
/// per entity so each screen only pays for the sync traffic it needs.
class ChecklistSyncController extends Notifier<AsyncValue<void>> {
  ChecklistSyncController(this.householdId);

  final String householdId;

  Timer? _debounceTimer;

  @override
  AsyncValue<void> build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    Future.microtask(syncNow);
    return const AsyncData(null);
  }

  Future<void> syncNow() async {
    try {
      await ref.read(syncServiceProvider).syncChecklists(householdId);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  void syncDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), syncNow);
  }
}

final checklistSyncControllerProvider =
    NotifierProvider.family<ChecklistSyncController, AsyncValue<void>, String>(
      ChecklistSyncController.new,
    );
