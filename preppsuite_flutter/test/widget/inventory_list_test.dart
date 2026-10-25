import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/consume_dialog.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/supply_groups_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Records what the screen asked for instead of writing it. The write
/// itself is covered without a widget tree in
/// `test/features/inventory_controller_test.dart` — here the question is
/// only whether the UI asks for the right thing.
class _RecordingController extends InventoryController {
  _RecordingController(super.db, super.householdId, this.consumed);

  /// Owned by the test rather than by the controller: cancelling the
  /// dialog never reads the provider, so an instance-held list would not
  /// exist to assert emptiness on.
  final List<(String clientId, double amount)> consumed;

  @override
  Future<void> consumeQuantity(InventoryItem existing, double amount) async {
    consumed.add((existing.clientId, amount));
  }
}

void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late List<(String clientId, double amount)> consumed;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    consumed = [];
  });

  tearDown(() => db.close());

  InventoryItem item({
    String clientId = 'a',
    String name = 'Nudeln',
    double quantity = 5,
    double? minQuantity,
    DateTime? expirationDate,
  }) {
    return InventoryItem(
      clientId: clientId,
      householdId: householdId,
      name: name,
      category: 'food',
      quantity: quantity,
      unit: 'Stk',
      storageLocation: 'Keller',
      minQuantity: minQuantity,
      expirationDate: expirationDate,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
  }

  /// The inventory stream is served from a plain list rather than from
  /// drift: a real drift stream needs the event loop to turn, which the
  /// widget tester's fake clock does not do, and `pumpAndSettle` would
  /// spin on the loading spinner until it times out.
  Future<void> pumpList(WidgetTester tester, List<InventoryItem> items) async {
    // A phone's height: the supply card above the list has grown with the
    // food groups (#212), and on the default 800 by 600 the rows below it
    // start outside the screen.
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(items)),
          inventoryControllerProvider(householdId).overrideWith(
            (ref) => _RecordingController(db, householdId, consumed),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const InventoryListScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the empty state when there is nothing stored', (
    tester,
  ) async {
    await pumpList(tester, const []);

    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('lists an item with its quantity and location', (tester) async {
    await pumpList(tester, [item(name: 'Nudeln', quantity: 5)]);

    expect(find.text('Nudeln'), findsOneWidget);
    expect(find.text('5 Stk · Keller'), findsOneWidget);
  });

  testWidgets('marks an item below its minimum as low stock', (tester) async {
    await pumpList(tester, [item(quantity: 1, minQuantity: 3)]);

    expect(find.widgetWithText(Chip, 'Niedriger Bestand'), findsOneWidget);
  });

  testWidgets('marks an item past its expiration date as expired', (
    tester,
  ) async {
    await pumpList(tester, [
      item(expirationDate: DateTime.now().subtract(const Duration(days: 1))),
    ]);

    expect(find.widgetWithText(Chip, 'Abgelaufen'), findsOneWidget);
  });

  testWidgets('an item that is neither low nor expired carries no chip', (
    tester,
  ) async {
    await pumpList(tester, [
      item(
        quantity: 5,
        minQuantity: 1,
        expirationDate: DateTime.now().add(const Duration(days: 365)),
      ),
    ]);

    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('deducting through the dialog asks for the entered amount', (
    tester,
  ) async {
    await pumpList(tester, [item(clientId: 'a', quantity: 5)]);

    await tester.tap(find.byTooltip('Verbrauchen'));
    await tester.pumpAndSettle();
    expect(find.byType(ConsumeDialog), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byType(ConsumeDialog),
        matching: find.byType(TextField),
      ),
      '2',
    );
    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();

    expect(consumed, [('a', 2.0)]);
  });

  testWidgets('"used up entirely" asks for the whole stock', (tester) async {
    await pumpList(tester, [item(clientId: 'a', quantity: 2)]);

    await tester.tap(find.byTooltip('Verbrauchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alles verbraucht'));
    await tester.pumpAndSettle();

    expect(consumed, [('a', 2.0)]);
  });

  testWidgets('an item at zero offers no deduct button', (tester) async {
    await pumpList(tester, [item(quantity: 0)]);

    expect(find.byTooltip('Verbrauchen'), findsNothing);
  });

  testWidgets('cancelling the dialog deducts nothing', (tester) async {
    await pumpList(tester, [item(quantity: 5)]);

    await tester.tap(find.byTooltip('Verbrauchen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(consumed, isEmpty);
  });

  testWidgets('a row with more photos says how many more (#211)', (
    tester,
  ) async {
    await pumpList(tester, [
      item(clientId: 'a', name: 'Linsen').copyWith(
        photoPath: const Value('p/a.jpg'),
        secondPhotoPath: const Value('p/b.jpg'),
        thirdPhotoPath: const Value('p/c.jpg'),
      ),
      item(clientId: 'b', name: 'Reis').copyWith(
        photoPath: const Value('p/r.jpg'),
      ),
    ]);

    expect(find.text('+2'), findsOneWidget);
    // Read out as part of the row, which merges what it holds.
    expect(find.bySemanticsLabel(RegExp('2 weitere Fotos')), findsOneWidget);
    expect(find.text('+0'), findsNothing);
  });

  testWidgets('the food groups stand in the supply card and open (#212)', (
    tester,
  ) async {
    // Ten days of calories can be ten days of noodles. The groups sat
    // behind a checklist and the search; now beside water and calories.
    await pumpList(tester, [
      item(clientId: 'n', name: 'Nudeln', quantity: 20).copyWith(
        unit: 'kg',
        foodGroup: const Value('grain'),
      ),
      item(clientId: 'b', name: 'Bohnen', quantity: 3),
    ]);

    expect(find.text('Vorratsgruppen'), findsOneWidget);
    expect(
      find.textContaining('1 von 7 Gruppen für 10 Tage gedeckt'),
      findsOneWidget,
    );
    expect(find.textContaining('am knappsten:'), findsOneWidget);
    expect(find.textContaining('1 Artikel ohne Gruppe'), findsOneWidget);

    await tester.tap(find.text('Vorratsgruppen'));
    await tester.pumpAndSettle();
    expect(find.byType(SupplyGroupsScreen), findsOneWidget);
  });

  testWidgets('the inventory list meets the accessibility guidelines', (
    tester,
  ) async {
    await pumpList(tester, [item(minQuantity: 9)]);
    await expectAccessible(tester);
  });

  testWidgets('the inventory list survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await pumpList(tester, [item(minQuantity: 9)]);
  });
}
