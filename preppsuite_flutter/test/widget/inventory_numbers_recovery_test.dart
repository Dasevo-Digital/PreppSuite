import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_numbers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/supply_calculator.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/shopping_list_screen.dart';
import 'package:preppsuite_flutter/features/preparedness/application/autonomy_overview.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/preparedness/presentation/scenario_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profile extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async =>
      const HouseholdProfile(id: 'h', name: 'Test', countryCode: 'DE');
}

void main() {
  final items = [
    for (final id in ['a', 'b'])
      InventoryItem(
        clientId: id,
        householdId: 'h',
        name: id,
        category: 'water',
        quantity: 1e308,
        unit: 'l',
        storageLocation: 'Test',
        updatedAt: DateTime.utc(2026),
        dirty: false,
      ),
  ];

  test('overflow cannot produce a reassuring light or invented autonomy', () {
    expect(items.any(hasInvalidInventoryNumbers), isFalse);
    expect(
      supplyStatus(items: items, household: const SupplyHousehold()).light,
      SupplyLight.unknown,
    );
    final reaches = autonomyReaches(
      items: items,
      household: const SupplyHousehold(),
      energy: const EnergyPlan(),
      entered: const AutonomySnapshot(waterDays: 10),
    );
    final water = reaches.singleWhere(
      (reach) => reach.resource == AutonomyResource.water,
    );
    expect(water.days, isNull);
    expect(water.gap, AutonomyGap.invalidNumbers);
    expect(
      () => inventoryNumbersOrNull<void>(() => throw StateError('unrelated')),
      throwsStateError,
    );
  });

  for (final screen in <Widget>[
    const InventoryListScreen(householdId: 'h'),
    const ShoppingListScreen(householdId: 'h'),
    const ScenarioScreen(householdId: 'h'),
  ]) {
    testWidgets('${screen.runtimeType} explains overflow and remains usable', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            inventoryItemsProvider('h')
                .overrideWith((ref) => Stream.value(items)),
            householdProfileProvider.overrideWith(_Profile.new),
          ],
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: screen,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(
        tester.element(find.byType(screen.runtimeType)),
      )!;
      expect(find.text(l10n.inventoryInvalidNumbers), findsWidgets);
      expect(find.byType(ErrorWidget), findsNothing);
      expect(tester.takeException(), isNull);
      if (screen is InventoryListScreen) {
        expect(find.text('a'), findsWidgets);
        expect(find.text('b'), findsWidgets);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
