import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'budget_providers.dart';

/// Same cadence/shape as `InventorySyncController` and
/// `ChecklistSyncController` — see the former for the reasoning.
class BudgetSyncController extends Notifier<AsyncValue<void>> {
  BudgetSyncController(this.householdId);

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
      await ref.read(syncServiceProvider).syncBudget(householdId);
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

final budgetSyncControllerProvider = NotifierProvider.family<
  BudgetSyncController,
  AsyncValue<void>,
  String
>(BudgetSyncController.new);
