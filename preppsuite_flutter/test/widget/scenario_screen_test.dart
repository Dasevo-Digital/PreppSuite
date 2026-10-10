import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/preparedness/presentation/scenario_screen.dart';
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

/// The scenario screen (#149): what a stretch is short of, said in words,
/// and the export offered only when a shop can close something.
void main() {
  const householdId = 'h';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 2,
  );

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  InventoryItem water(double liters) => InventoryItem(
    clientId: 'water',
    householdId: householdId,
    name: 'Wasser',
    category: 'water',
    quantity: liters,
    unit: 'l',
    storageLocation: 'Keller',
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  late AppLocalizations l10n;

  Future<void> pump(
    WidgetTester tester,
    List<InventoryItem> items, {
    bool withStove = true,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (withStove) ...{
        'energyReserves': jsonEncode([
          {'id': 'r', 'kind': 'gas', 'label': 'Gaskartuschen', 'amount': 450},
        ]),
        'energyDraws': jsonEncode([
          {
            'id': 'd',
            'kind': 'gas',
            'label': 'Gaskocher',
            'perHour': 160,
            'hoursPerDay': 1,
          },
        ]),
      },
    });
    await tester.binding.setSurfaceSize(const Size(800, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(items)),
          householdProfileProvider.overrideWith(() => _FixedProfile(profile)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ScenarioScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('says what the 72 hours are short of', (tester) async {
    await pump(tester, [water(5)]);

    // Two adults, three days, 2 l a day: 12 l, 5 in stock.
    expect(find.text(l10n.scenarioNeedHave('12 l', '5 l')), findsOneWidget);
    expect(find.text(l10n.scenarioMissing('7 l')), findsOneWidget);
    // 160 g an hour for an hour a day: 480 g against 450.
    expect(find.text(l10n.scenarioMissing('30 g')), findsOneWidget);
    expect(find.byTooltip(l10n.shoppingListExport), findsOneWidget);
  });

  testWidgets('ten days need more', (tester) async {
    await pump(tester, [water(5)]);

    await tester.tap(find.text(l10n.scenarioHorizonDays(10)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.scenarioNeedHave('40 l', '5 l')), findsOneWidget);
  });

  testWidgets('a covered stretch says so and offers nothing to buy', (
    tester,
  ) async {
    await pump(tester, [water(100)], withStove: false);

    expect(find.text(l10n.scenarioCovered), findsOneWidget);
    expect(find.text(l10n.scenarioNoEnergyPlan), findsOneWidget);
    expect(find.byTooltip(l10n.shoppingListExport), findsNothing);
  });
}
