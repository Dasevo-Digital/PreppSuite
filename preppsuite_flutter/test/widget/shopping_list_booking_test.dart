import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/shopping_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FixedProfile extends HouseholdProfileController {
  _FixedProfile(this.profile);

  final HouseholdProfile profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}

/// Records what the screen books instead of writing it: a widget test
/// that writes to the database hangs after its last line (see
/// `emergency_card_people_test.dart`). What a booking stores is tested in
/// `inventory_controller_test.dart`.
class _RecordingController extends InventoryController {
  _RecordingController(super.db, super.householdId);

  final booked = <Map<String, double>>[];
  final takenBack = <Map<String, double>>[];

  @override
  Future<Map<String, double>> bookPurchases(Map<String, double> bought) async {
    booked.add(bought);
    return bought;
  }

  @override
  Future<void> takeBackPurchases(Map<String, double> booked) async {
    takenBack.add(booked);
  }
}

/// What was bought goes into the stock from the list it was bought from
/// (#265).
void main() {
  const householdId = 'household-1';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 2,
  );

  late AppDatabase db;
  late _RecordingController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = _RecordingController(db, householdId);
  });

  tearDown(() => db.close());

  final rice = InventoryItem(
    clientId: 'rice',
    householdId: householdId,
    name: 'Reis',
    category: 'food',
    quantity: 0.5,
    unit: 'kg',
    storageLocation: 'Keller',
    minQuantity: 2,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<AppLocalizations> pumpAndTick(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value([rice])),
          inventoryControllerProvider(householdId)
              .overrideWithValue(controller),
          householdProfileProvider.overrideWith(() => _FixedProfile(profile)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ShoppingListScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final l10n = AppLocalizations.of(
      tester.element(find.byType(ShoppingListScreen)),
    )!;

    // Nothing to book until something is ticked.
    expect(find.text(l10n.shoppingListBookTicked(1)), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.shoppingListBookTicked(1)));
    await tester.pumpAndSettle();
    return l10n;
  }

  testWidgets('tick, book at what was short, and take it back', (
    tester,
  ) async {
    final l10n = await pumpAndTick(tester);

    // Offered at what was short, with the decimal comma it is read with.
    expect(find.widgetWithText(TextField, '1,5'), findsOneWidget);
    await tester.tap(find.text(l10n.shoppingListBookConfirm));
    await tester.pumpAndSettle();

    expect(controller.booked, [
      {'rice': 1.5},
    ]);
    expect(find.text(l10n.shoppingListBooked(1)), findsOneWidget);

    await tester.tap(find.text(l10n.undoAction));
    await tester.pumpAndSettle();
    expect(controller.takenBack, [
      {'rice': 1.5},
    ]);
  });

  testWidgets('what was really bought is what is booked', (tester) async {
    final l10n = await pumpAndTick(tester);

    await tester.enterText(find.byType(TextField), '3,25');
    await tester.tap(find.text(l10n.shoppingListBookConfirm));
    await tester.pumpAndSettle();

    expect(controller.booked, [
      {'rice': 3.25},
    ]);
  });

  testWidgets('an amount that is no number is asked for again', (
    tester,
  ) async {
    final l10n = await pumpAndTick(tester);

    await tester.enterText(find.byType(TextField), 'Infinity');
    await tester.tap(find.text(l10n.shoppingListBookConfirm));
    await tester.pumpAndSettle();

    expect(find.text(l10n.invalidNumber), findsOneWidget);
    expect(controller.booked, isEmpty);
  });
}
