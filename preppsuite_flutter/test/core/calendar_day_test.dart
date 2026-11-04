import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/calendar_day.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/rotation_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screens that count from today follow the day, not only their rows
/// (#262).
void main() {
  late DateTime clock;

  setUp(() {
    clock = DateTime(2026, 11, 3, 23, 59);
    CalendarDay.now = () => clock;
  });
  tearDown(() => CalendarDay.now = DateTime.now);

  testWidgets('the day moves on at midnight', (tester) async {
    final container = ProviderContainer();
    final days = <DateTime>[];
    container.listen(
      calendarDayProvider,
      (_, day) => days.add(day),
      fireImmediately: true,
    );

    // The timer was set for one minute and a second from 23:59.
    clock = DateTime(2026, 11, 4, 0, 0, 1);
    await tester.pump(const Duration(seconds: 61));

    expect(days, [DateTime(2026, 11, 3), DateTime(2026, 11, 4)]);
    // Before the test ends: its midnight timer must not outlive it.
    container.dispose();
  });

  testWidgets('and on coming back, when no timer could fire', (tester) async {
    final container = ProviderContainer();
    expect(container.read(calendarDayProvider), DateTime(2026, 11, 3));

    // A telephone asleep overnight: nothing ran until it woke.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    clock = DateTime(2026, 11, 4, 7, 30);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }

    expect(container.read(calendarDayProvider), DateTime(2026, 11, 4));
    container.dispose();
  });

  testWidgets('a tin that runs out today has run out tomorrow', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final item = InventoryItem(
      clientId: 'tin',
      householdId: 'h',
      name: 'Ravioli',
      category: 'food',
      quantity: 2,
      unit: 'Dose',
      storageLocation: 'Keller',
      expirationDate: DateTime(2026, 11, 3),
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([item])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RotationScreen(householdId: 'h'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(RotationScreen)),
    )!;
    expect(find.text(l10n.rotationSoonHeading), findsOneWidget);
    expect(find.text(l10n.rotationExpiredHeading), findsNothing);

    // Nothing in the inventory changes; only the day does.
    clock = DateTime(2026, 11, 4, 0, 0, 1);
    await tester.pump(const Duration(seconds: 61));

    expect(find.text(l10n.rotationExpiredHeading), findsOneWidget);
    expect(find.text(l10n.rotationSoonHeading), findsNothing);
  });

  testWidgets('and the badge on the inventory counts it then too (#282)', (
    tester,
  ) async {
    final tin = InventoryItem(
      clientId: 'tin',
      householdId: 'h',
      name: 'Ravioli',
      category: 'food',
      quantity: 2,
      unit: 'Dose',
      storageLocation: 'Keller',
      expirationDate: DateTime(2026, 11, 3),
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
    final container = ProviderContainer(
      overrides: [
        inventoryItemsProvider('h').overrideWith((ref) => Stream.value([tin])),
      ],
    );
    final counts = <int>[];
    container.listen(
      inventoryAttentionCountProvider('h'),
      (_, count) => counts.add(count),
      fireImmediately: true,
    );
    await tester.pump();
    expect(counts.last, 0);

    clock = DateTime(2026, 11, 4, 0, 0, 1);
    await tester.pump(const Duration(seconds: 61));

    expect(counts.last, 1);
    container.dispose();
  });
}
