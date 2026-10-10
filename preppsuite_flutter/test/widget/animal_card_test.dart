import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_member_controller.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_card_form_screen.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_cards_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An animal's card, and its food in the stores (#151).
void main() {
  const householdId = 'h';
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  final anna = HouseholdMember(
    clientId: 'anna',
    householdId: householdId,
    name: 'Anna',
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );
  final bello = HouseholdMember(
    clientId: 'bello',
    householdId: householdId,
    name: 'Bello',
    species: 'dog',
    chipNumber: '276098100000001',
    sortOrder: 1,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );
  final food = InventoryItem(
    clientId: 'food',
    householdId: householdId,
    name: 'Trockenfutter',
    category: 'petFood',
    quantity: 3,
    unit: 'kg',
    storageLocation: 'Keller',
    dailyDose: 0.25,
    memberId: 'bello',
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  late AppLocalizations l10n;

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(800, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value([food])),
          householdMembersProvider(
            householdId,
          ).overrideWith((ref) => Stream.value([anna, bello])),
          householdMemberChoicesProvider(
            householdId,
          ).overrideWith((ref) async => [anna, bello]),
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

  testWidgets('the card says what the animal is and how long its food lasts', (
    tester,
  ) async {
    await pump(tester, const EmergencyCardsScreen(householdId: householdId));

    expect(find.text(l10n.cardSpeciesDog), findsOneWidget);
    expect(find.text('276098100000001'), findsOneWidget);
    // 3 kg at 250 g a day: twelve days.
    expect(
      find.text(
        l10n.emergencyCardStoredReach('Trockenfutter', l10n.medicationDays(12)),
      ),
      findsOneWidget,
    );
    // A lock screen card for Anna, none for Bello.
    expect(find.byTooltip(l10n.lockScreenCardAction), findsOneWidget);
  });

  testWidgets('a person\'s card asks for no chip number', (tester) async {
    await pump(
      tester,
      EmergencyCardFormScreen(householdId: householdId, existing: anna),
    );

    expect(find.text(l10n.cardChipNumber), findsNothing);
    expect(find.text(l10n.emergencyCardBloodType), findsOneWidget);
  });

  testWidgets('an animal\'s card asks for its chip and its vet', (
    tester,
  ) async {
    await pump(
      tester,
      EmergencyCardFormScreen(householdId: householdId, existing: bello),
    );

    expect(find.text(l10n.cardChipNumber), findsOneWidget);
    expect(find.text(l10n.cardVets), findsOneWidget);
    expect(find.text(l10n.emergencyCardBloodType), findsNothing);
  });

  testWidgets('pet food has a daily amount and offers only the animals', (
    tester,
  ) async {
    await pump(
      tester,
      InventoryItemFormScreen(householdId: householdId, existing: food),
    );

    expect(find.text(l10n.dailyFoodLabel), findsOneWidget);
    expect(find.text(l10n.inventoryAnimalLabel), findsOneWidget);
    expect(find.text(l10n.refillLeadLabel), findsNothing);

    await tester.tap(find.text('Bello'));
    await tester.pumpAndSettle();
    expect(find.text('Anna'), findsNothing);
  });
}
