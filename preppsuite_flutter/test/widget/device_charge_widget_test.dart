import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingController extends InventoryController {
  _RecordingController(super.db, super.householdId, this.charged);

  final List<String> charged;

  @override
  Future<void> markCharged(InventoryItem existing, {DateTime? at}) async {
    charged.add(existing.name);
  }
}

/// A device's own battery check on the screens (#179). What is stored and
/// when it is due is tested in `device_charge_test.dart`.
void main() {
  const householdId = 'h';
  late AppDatabase db;
  late AppLocalizations l10n;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  InventoryItem item({
    String category = 'energy',
    int? every,
    DateTime? checked,
  }) => InventoryItem(
    clientId: 'item',
    householdId: householdId,
    name: 'Powerbank',
    category: category,
    quantity: 1,
    unit: 'Stück',
    storageLocation: 'Flur',
    chargeEveryDays: every,
    chargeCheckedAt: checked,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<InventoryItem> stock = const [],
    List<String>? charged,
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(stock)),
          if (charged != null)
            inventoryControllerProvider(householdId).overrideWith(
              (ref) => _RecordingController(db, householdId, charged),
            ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('a device is given a check, and it is saved', (tester) async {
    await pump(
      tester,
      InventoryItemFormScreen(householdId: householdId, existing: item()),
    );

    await tester.tap(find.text(l10n.deviceChargeLabel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.chargeReminderInterval(90)), findsOneWidget);
    expect(find.text(l10n.deviceChargeLastChecked), findsOneWidget);
    expect(find.text(l10n.overviewChargeNext(90)), findsOneWidget);

    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    final stored = (await tester.runAsync(
      () => db.select(db.inventoryItems).get(),
    ))!.single;
    expect(stored.chargeEveryDays, 90);
    final today = DateTime.now();
    final checked = stored.chargeCheckedAt!.toLocal();
    expect(
      DateTime(checked.year, checked.month, checked.day),
      DateTime(today.year, today.month, today.day),
    );
  });

  testWidgets('food is not asked about a battery', (tester) async {
    await pump(
      tester,
      InventoryItemFormScreen(
        householdId: householdId,
        existing: item(category: 'food'),
      ),
    );
    expect(find.text(l10n.deviceChargeLabel), findsNothing);
  });

  testWidgets('a device that is due says so, and is confirmed at the shelf', (
    tester,
  ) async {
    final charged = <String>[];
    final due = item(
      every: 30,
      checked: DateTime.now().subtract(
        const Duration(days: 40),
      ),
    );
    await pump(
      tester,
      const InventoryListScreen(householdId: householdId),
      stock: [due],
      charged: charged,
    );

    expect(find.text(l10n.deviceChargeDueBadge), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, l10n.overviewChargeDone));
    await tester.pump();
    expect(charged, ['Powerbank']);
  });

  testWidgets('a device not yet due shows when it will be', (tester) async {
    await pump(
      tester,
      const InventoryListScreen(householdId: householdId),
      stock: [
        item(
          every: 30,
          checked: DateTime.now().subtract(const Duration(days: 10)),
        ),
      ],
    );

    expect(
      find.text(l10n.deviceChargeStatus(l10n.overviewChargeNext(20))),
      findsOneWidget,
    );
    expect(find.text(l10n.deviceChargeDueBadge), findsNothing);
  });
}
