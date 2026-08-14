import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_providers.dart';

/// Drives inventory sync for one household: an immediate sync on first
/// watch, a ~2s debounce after local writes (so rapid edits batch into one
/// round-trip), and a 60s background poll while something is watching.
/// Matches the cadence described in the sync protocol design — offline is
/// the normal case, so none of this blocks the UI, which already reacts to
/// local Drift writes directly.
class InventorySyncController extends Notifier<AsyncValue<void>> {
  InventorySyncController(this.householdId);

  final String householdId;

  Timer? _periodicTimer;
  Timer? _debounceTimer;

  @override
  AsyncValue<void> build() {
    ref.onDispose(() {
      _periodicTimer?.cancel();
      _debounceTimer?.cancel();
    });
    _periodicTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => syncNow(),
    );
    Future.microtask(syncNow);
    return const AsyncData(null);
  }

  Future<void> syncNow() async {
    try {
      await ref.read(syncServiceProvider).syncInventory(householdId);
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

final inventorySyncControllerProvider =
    NotifierProvider.family<InventorySyncController, AsyncValue<void>, String>(
      InventorySyncController.new,
    );
