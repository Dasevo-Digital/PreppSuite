import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/presentation/outage_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the screen books out instead of writing it: a widget test
/// that writes to the database hangs after its last line (see
/// `emergency_card_people_test.dart`). What a booking stores is tested in
/// `inventory_controller_test.dart`.
class _RecordingController extends InventoryController {
  _RecordingController(super.db, super.householdId);

  final bookedOut = <Set<String>>[];
  final putBack = <Map<String, double>>[];

  @override
  Future<Map<String, double>> bookOutAll(Iterable<String> clientIds) async {
    bookedOut.add(clientIds.toSet());
    return {for (final id in clientIds) id: 1};
  }

  @override
  Future<Map<String, double>> bookPurchases(Map<String, double> bought) async {
    putBack.add(bought);
    return bought;
  }
}

/// The blackout clock says what the stores keep in the fridge and the
/// freezer, and once a store's time is up books it out (#276).
void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late _RecordingController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = _RecordingController(db, householdId);
  });
  tearDown(() => db.close());

  InventoryItem item(String name, String location, String category) =>
      InventoryItem(
        clientId: name,
        householdId: householdId,
        name: name,
        category: category,
        quantity: 1,
        unit: 'Stück',
        storageLocation: location,
        updatedAt: DateTime.utc(2026),
        dirty: false,
      );

  final stock = [
    item('Milch', 'Kühlschrank', 'food'),
    item('Hackfleisch', 'Kühlschrank', 'food'),
    item('Insulin', 'Kühlschrank', 'medical'),
    item('Erbsen', 'Gefriertruhe', 'food'),
    item('Nudeln', 'Keller', 'food'),
  ];

  String hoursAgo(int hours) =>
      DateTime.now().toUtc().subtract(Duration(hours: hours)).toIso8601String();

  Future<AppLocalizations> show(
    WidgetTester tester, {
    required int hours,
    List<InventoryItem>? items,
  }) async {
    SharedPreferences.setMockInitialValues({
      'outageStartedAt': hoursAgo(hours),
    });
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(items ?? stock)),
          inventoryControllerProvider(
            householdId,
          ).overrideWithValue(controller),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OutageScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // The screen ticks every 30 seconds; it has to be gone at the end.
    addTearDown(() => tester.pumpWidget(const SizedBox()));
    return AppLocalizations.of(tester.element(find.byType(OutageScreen)))!;
  }

  testWidgets('each store says what the stores keep in it', (tester) async {
    final l10n = await show(tester, hours: 1);

    expect(
      find.text(l10n.outageContents('Hackfleisch, Insulin, Milch')),
      findsOneWidget,
    );
    expect(find.text(l10n.outageContents('Erbsen')), findsOneWidget);
    expect(find.textContaining('Nudeln'), findsNothing);
    // An hour in, nothing is to be thrown out yet.
    expect(find.text(l10n.outageDiscardButton), findsNothing);
  });

  testWidgets('five hours on, the fridge is booked out, food ticked, and '
      'it can be put back', (tester) async {
    final l10n = await show(tester, hours: 5);

    // Only the fridge: the freezer has two days.
    expect(find.text(l10n.outageDiscardButton), findsOneWidget);
    await tester.tap(find.text(l10n.outageDiscardButton));
    await tester.pumpAndSettle();

    expect(find.text(l10n.outageDiscardTitleRefrigerator), findsOneWidget);
    bool ticked(String name) => tester
        .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, name))
        .value!;
    expect(ticked('Milch'), isTrue);
    expect(ticked('Hackfleisch'), isTrue);
    // A medicine has a clock of its own, and the dialog says which.
    expect(ticked('Insulin'), isFalse);
    expect(find.text(l10n.outageDiscardMedicine), findsOneWidget);

    await tester.tap(find.text(l10n.outageDiscardConfirm(2)));
    await tester.pumpAndSettle();

    expect(controller.bookedOut, [
      {'Milch', 'Hackfleisch'},
    ]);
    expect(find.text(l10n.outageDiscarded(2)), findsOneWidget);

    await tester.tap(find.text(l10n.undoAction));
    await tester.pumpAndSettle();
    expect(controller.putBack, [
      {'Milch': 1, 'Hackfleisch': 1},
    ]);
  });

  testWidgets('with nothing kept cold, the screen says how to change that', (
    tester,
  ) async {
    final l10n = await show(
      tester,
      hours: 5,
      items: [item('Nudeln', 'Keller', 'food')],
    );

    expect(find.text(l10n.outageContentsNone), findsOneWidget);
    expect(find.text(l10n.outageDiscardButton), findsNothing);
  });
}
