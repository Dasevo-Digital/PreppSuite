import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/preparedness/presentation/preparedness_hub_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = PreparednessHubStore();

  InventoryItem item({
    required String clientId,
    required String category,
    required double quantity,
    String unit = 'Stk',
    int? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'home',
    name: clientId,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    calories: calories,
    updatedAt: DateTime.utc(2026, 9, 19),
    dirty: false,
  );

  Future<void> show(
    WidgetTester tester, {
    List<InventoryItem> items = const [],
  }) async {
    // Tall enough that the whole list is built: a `ListView` builds only
    // what it can show, and this screen is the longest in the app.
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            'home',
          ).overrideWith((ref) => Stream.value(items)),
          householdProfileProvider.overrideWith(_TwoAdults.new),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PreparednessHubScreen(householdId: 'home'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the household has already written down', (
    tester,
  ) async {
    await store.save(
      PreparednessHubData(
        evacuationCards: [
          EvacuationCard(
            id: 'route',
            label: 'Zuhause',
            start: 'Wohnung',
            destination: 'Treffpunkt Sporthalle',
            route: 'Nebenstrassen',
            locations: 'Apotheke',
            checkedAt: DateTime(2026, 9, 14),
          ),
        ],
        radioPlans: [
          RadioReceptionPlan(
            id: 'radio',
            station: 'Regionalradio',
            band: 'UKW',
            frequency: '95,8 MHz',
            receiver: 'Kurbelradio',
            power: 'Kurbel',
            checkedAt: DateTime(2026, 9, 14),
          ),
        ],
        autonomy: AutonomySnapshot(
          waterDays: 8,
          foodDays: 12,
          medicineDays: 5,
          energyDays: 7,
          hygieneDays: 10,
          checkedAt: DateTime(2026, 9, 14),
        ),
      ),
    );

    await show(tester);

    expect(find.text('Zuhause'), findsOneWidget);
    expect(find.textContaining('Treffpunkt Sporthalle'), findsOneWidget);
    expect(find.text('Regionalradio'), findsOneWidget);
    // The shortest range is the one that decides, and the screen has to
    // say which supply it is rather than only how many days are left.
    expect(find.textContaining('Medikamente'), findsWidgets);
  });

  testWidgets('a new evacuation card is written to the store', (tester) async {
    await show(tester);

    await tester.tap(find.text('Karte hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Zuhause');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect((await store.load()).evacuationCards.single.label, 'Zuhause');
  });

  testWidgets('a card without a name is not created', (tester) async {
    await show(tester);

    await tester.tap(find.text('Karte hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect((await store.load()).evacuationCards, isEmpty);
  });

  testWidgets('crisis mode is kept for the next time the screen opens', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(find.text('Vereinfachte, größere Darstellung'));
    await tester.pumpAndSettle();

    expect((await store.load()).crisisMode, isTrue);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('survives a doubled system font size', (tester) async {
    useLargeText(tester);
    await show(tester);

    expect(find.text('Krisenorganisation'), findsOneWidget);
  });

  testWidgets('the range comes out of the inventory, not out of a dialog', (
    tester,
  ) async {
    await show(
      tester,
      items: [
        item(clientId: 'w', category: 'water', quantity: 40, unit: 'l'),
        item(clientId: 'f', category: 'food', quantity: 1, calories: 8800),
      ],
    );

    // Two adults: 40 litres at 4 a day is ten days, 8800 kcal at 4400 is
    // two — and food is the bottleneck nobody worked out by hand.
    expect(find.textContaining('Engpass Lebensmittel'), findsOneWidget);
    expect(find.text('10 Tage'), findsOneWidget);
    expect(find.text('2 Tage'), findsOneWidget);
    expect(find.text('Aus dem Bestand gerechnet'), findsWidgets);
  });

  testWidgets('a resource the app cannot divide is open, not zero', (
    tester,
  ) async {
    await show(tester);

    // Nothing recorded anywhere: five open questions and no reassuring
    // number in front of them.
    expect(find.text('offen'), findsNWidgets(5));
    expect(find.textContaining('Autarkie noch unvollständig'), findsOneWidget);
  });

  testWidgets('by hand it asks only for what it could not work out', (
    tester,
  ) async {
    await show(
      tester,
      items: [item(clientId: 'w', category: 'water', quantity: 40, unit: 'l')],
    );

    await tester.tap(find.text('Von Hand ergänzen'));
    await tester.pumpAndSettle();

    // Water is answered, so it is not asked for again.
    expect(find.textContaining('Wasser –'), findsNothing);
    expect(find.textContaining('Hygiene'), findsWidgets);
  });
}

/// A household of two adults, which is what the arithmetic in these tests
/// is worked out for.
class _TwoAdults extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async => const HouseholdProfile(
    id: 'home',
    name: 'Zuhause',
    countryCode: 'DE',
    personCount: 2,
  );
}
