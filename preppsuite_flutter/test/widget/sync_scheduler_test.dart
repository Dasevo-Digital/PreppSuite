import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/budget/application/budget_sync_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_sync_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_sync_controller.dart';
import 'package:preppsuite_flutter/sync/sync_scheduler.dart';

/// Counts sync passes instead of performing them. The real controllers
/// reach for the global Serverpod client, which does not exist in a test —
/// and what is under test here is the cadence, not the transfer.
class _CountingInventory extends InventorySyncController {
  _CountingInventory(super.householdId);
  static int runs = 0;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> syncNow() async => runs++;
}

class _CountingChecklist extends ChecklistSyncController {
  _CountingChecklist(super.householdId);
  static int runs = 0;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> syncNow() async => runs++;
}

class _CountingBudget extends BudgetSyncController {
  _CountingBudget(super.householdId);
  static int runs = 0;

  @override
  AsyncValue<void> build() => const AsyncData(null);

  @override
  Future<void> syncNow() async => runs++;
}

void main() {
  const householdId = 'household-1';

  setUp(() {
    _CountingInventory.runs = 0;
    _CountingChecklist.runs = 0;
    _CountingBudget.runs = 0;
  });

  // Warnings are deliberately absent: the app fetches them from the public
  // feeds on its own schedule, so a failing feed no longer looks like a
  // broken household sync.
  List<int> allRuns() => [
    _CountingInventory.runs,
    _CountingChecklist.runs,
    _CountingBudget.runs,
  ];

  Future<void> pumpScheduler(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventorySyncControllerProvider.overrideWith2(_CountingInventory.new),
          checklistSyncControllerProvider.overrideWith2(_CountingChecklist.new),
          budgetSyncControllerProvider.overrideWith2(_CountingBudget.new),
        ],
        child: const MaterialApp(
          home: Scaffold(body: SyncScheduler(householdId: householdId)),
        ),
      ),
    );
    await tester.pump();
  }

  /// Flutter refuses a direct jump between lifecycle states — a real app
  /// always passes through the intermediate ones, and the binding asserts
  /// on anything else. These walk the legal chain.
  Future<void> sendToBackground(WidgetTester tester) async {
    for (final state in const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  Future<void> bringToForeground(WidgetTester tester) async {
    for (final state in const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
  }

  testWidgets('takes no space in the layout', (tester) async {
    await pumpScheduler(tester);

    expect(tester.getSize(find.byType(SyncScheduler)), Size.zero);
  });

  testWidgets('one tick runs every entity exactly once', (tester) async {
    await pumpScheduler(tester);
    expect(allRuns(), [0, 0, 0], reason: 'nothing before the first tick');

    await tester.pump(syncInterval);
    await tester.pumpAndSettle();

    expect(allRuns(), [1, 1, 1]);
  });

  testWidgets('further ticks keep the entities in step with each other', (
    tester,
  ) async {
    await pumpScheduler(tester);

    for (var i = 0; i < 3; i++) {
      await tester.pump(syncInterval);
      await tester.pumpAndSettle();
    }

    expect(allRuns(), [3, 3, 3]);
  });

  testWidgets('stops ticking while the app is in the background', (
    tester,
  ) async {
    await pumpScheduler(tester);

    // The old per-entity timers kept firing here — on a phone the one
    // thing worth not doing.
    await sendToBackground(tester);

    await tester.pump(syncInterval);
    await tester.pump(syncInterval);
    await tester.pumpAndSettle();

    expect(allRuns(), [0, 0, 0]);
  });

  testWidgets('catches up at once when the app comes back', (tester) async {
    await pumpScheduler(tester);
    await sendToBackground(tester);
    await bringToForeground(tester);

    expect(
      allRuns(),
      [1, 1, 1],
      reason: 'without waiting out the interval first',
    );

    // And the clock runs again from there.
    await tester.pump(syncInterval);
    await tester.pumpAndSettle();
    expect(allRuns(), [2, 2, 2]);
  });

  testWidgets('cancels its timer when removed', (tester) async {
    await pumpScheduler(tester);
    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));

    // A leftover timer would fail the test outright, and any sync it
    // triggered would run against a disposed container.
    await tester.pump(syncInterval);
    expect(allRuns(), [0, 0, 0]);
  });
}
