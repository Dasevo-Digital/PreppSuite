import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
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

/// The file export is offered when there are lines to put in it (#155),
/// and only then: an empty file handed to a shopping app would look like
/// a list that arrived with nothing on it.
void main() {
  const householdId = 'household-1';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 2,
  );

  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  InventoryItem rice(double quantity) => InventoryItem(
    clientId: 'rice',
    householdId: householdId,
    name: 'Reis',
    category: 'food',
    quantity: quantity,
    unit: 'kg',
    storageLocation: 'Keller',
    minQuantity: 2,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<void> pump(WidgetTester tester, List<InventoryItem> items) async {
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
          home: const ShoppingListScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('is there when something is short', (tester) async {
    await pump(tester, [rice(0.5)]);

    expect(find.byTooltip('Als Datei exportieren'), findsOneWidget);
    expect(find.text('Reis'), findsOneWidget);
  });

  testWidgets('and not when nothing is', (tester) async {
    await pump(tester, [rice(3)]);

    expect(find.byTooltip('Als Datei exportieren'), findsNothing);
  });
}
