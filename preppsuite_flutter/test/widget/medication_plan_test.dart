import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_member_controller.dart';
import 'package:preppsuite_flutter/features/household/presentation/emergency_cards_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/medication_range_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whose medicine, the reminder for a new prescription, and the card
/// that shows both (#150). What is stored is tested in
/// `inventory_controller_test.dart`; these are the screens.
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
    medication: 'Ramipril 5 mg morgens',
    sortOrder: 0,
    updatedAt: DateTime.utc(2026, 9, 1),
    dirty: false,
  );

  InventoryItem pills({int? refillLeadDays = 14, String? memberId = 'anna'}) =>
      InventoryItem(
        clientId: 'pills',
        householdId: householdId,
        name: 'Ramipril',
        category: 'medical',
        quantity: 60,
        unit: 'Tabletten',
        storageLocation: 'Bad',
        dailyDose: 2,
        memberId: memberId,
        refillLeadDays: refillLeadDays,
        stockCountedAt: DateTime.now(),
        updatedAt: DateTime.now().toUtc(),
        dirty: false,
      );

  late AppLocalizations l10n;

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<InventoryItem> stock = const [],
    List<HouseholdMember> members = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(stock)),
          householdMembersProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(members)),
          householdMemberChoicesProvider(
            householdId,
          ).overrideWith((ref) async => members),
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

  group('the form', () {
    testWidgets('asks about a reminder only once there is a dose', (
      tester,
    ) async {
      final item = pills(refillLeadDays: null);
      await pump(
        tester,
        InventoryItemFormScreen(
          householdId: householdId,
          existing: InventoryItem(
            clientId: item.clientId,
            householdId: item.householdId,
            name: item.name,
            category: item.category,
            quantity: item.quantity,
            unit: item.unit,
            storageLocation: item.storageLocation,
            updatedAt: item.updatedAt,
            dirty: false,
          ),
        ),
      );

      expect(find.text(l10n.refillLeadLabel), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.dailyDoseLabel),
        '2',
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.refillLeadLabel), findsOneWidget);
      expect(find.text(l10n.refillLeadNone), findsOneWidget);
    });

    testWidgets('opens with the stored reminder and person', (tester) async {
      await pump(
        tester,
        InventoryItemFormScreen(householdId: householdId, existing: pills()),
        members: [anna],
      );

      expect(find.text(l10n.refillLeadDays(14)), findsOneWidget);
      expect(find.text(l10n.inventoryMemberLabel), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('does not ask whose it is without any cards', (tester) async {
      await pump(
        tester,
        InventoryItemFormScreen(householdId: householdId, existing: pills()),
      );

      expect(find.text(l10n.inventoryMemberLabel), findsNothing);
    });
  });

  testWidgets('the card shows what of hers is in the stores', (tester) async {
    await pump(
      tester,
      const EmergencyCardsScreen(householdId: householdId),
      stock: [pills()],
      members: [anna],
    );

    expect(find.text(l10n.emergencyCardStored), findsOneWidget);
    expect(
      find.text(
        l10n.emergencyCardStoredReach('Ramipril', l10n.medicationDays(30)),
      ),
      findsOneWidget,
    );
    // The typed line stays beside it.
    expect(find.text('Ramipril 5 mg morgens'), findsOneWidget);
  });

  testWidgets('the medication screen says when the reminder comes', (
    tester,
  ) async {
    await pump(
      tester,
      const MedicationRangeScreen(householdId: householdId),
      stock: [pills()],
    );

    expect(
      find.textContaining(l10n.medicationRefillOn('').trim()),
      findsOneWidget,
    );
  });
}
