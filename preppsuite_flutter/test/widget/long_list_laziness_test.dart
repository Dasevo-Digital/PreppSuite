import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/rotation_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/shopping_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the real profile, which loads from preferences.
class _FixedProfile extends HouseholdProfileController {
  _FixedProfile(this.profile);

  final HouseholdProfile profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}

/// The two lists that grow with the household stay lazy.
///
/// Both used to build a widget per item up front, and the shopping list
/// put them in a `Column` inside its `ListView` — which realises and lays
/// out every child. Measured at 300 items: 201 ms and 300 realised tiles
/// against 12 ms and nine. 300 is not a stress test; it is what a
/// household that stocks for ten days ends up with.
///
/// These assert the mechanism, not a duration: a wall-clock threshold in
/// a test suite is a flake waiting for a slow machine, while "how many
/// tiles exist" is exact.
void main() {
  const householdId = 'household-1';
  const count = 300;

  late AppDatabase db;

  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 2,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  /// [count] items, every one of them both short of its minimum and due
  /// for rotation, so each list has a row per item.
  List<InventoryItem> manyItems() {
    final soon = DateTime.now().add(const Duration(days: 3));
    return [
      for (var i = 0; i < count; i++)
        InventoryItem(
          clientId: 'item-$i',
          householdId: householdId,
          name: 'Artikel $i',
          category: 'food',
          quantity: 1,
          unit: 'Stück',
          storageLocation: 'Keller',
          minQuantity: 5,
          expirationDate: soon,
          updatedAt: DateTime.utc(2026),
          dirty: false,
        ),
    ];
  }

  Future<void> pump(WidgetTester tester, Widget home) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(manyItems())),
          householdProfileProvider.overrideWith(() => _FixedProfile(profile)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('the shopping list realises only what is on screen', (
    tester,
  ) async {
    await pump(
      tester,
      const ShoppingListScreen(householdId: householdId),
    );

    final tiles = find.byType(ListTile).evaluate().length;
    expect(
      tiles,
      greaterThan(0),
      reason: 'the list has to actually show the shortfalls',
    );
    expect(
      tiles,
      lessThan(count ~/ 4),
      reason: '$tiles of $count tiles realised — the Column is back',
    );
  });

  testWidgets('and it still shows the items and the footnote', (tester) async {
    // Laziness must not have cost the content: the card at the top, the
    // heading, the first shortfall, and the note that explains an empty
    // list are all still there.
    await pump(
      tester,
      const ShoppingListScreen(householdId: householdId),
    );

    expect(find.text('Artikel 0'), findsOneWidget);
    expect(find.textContaining('fehlen auf'), findsWidgets);

    // The footnote is the last row, so it takes scrolling to reach —
    // which is the point of the change.
    await tester.scrollUntilVisible(
      find.textContaining('Mindestmenge angegeben'),
      400,
      maxScrolls: 400,
    );
    expect(find.textContaining('Mindestmenge angegeben'), findsOneWidget);
  });

  testWidgets('the rotation queue realises only what is on screen', (
    tester,
  ) async {
    await pump(tester, const RotationScreen(householdId: householdId));

    final tiles = find.byType(ListTile).evaluate().length;
    expect(tiles, greaterThan(0));
    expect(
      tiles,
      lessThan(count ~/ 4),
      reason: '$tiles of $count tiles realised — the rows are eager again',
    );
  });

  testWidgets('and the rotation queue keeps its headings and order', (
    tester,
  ) async {
    await pump(tester, const RotationScreen(householdId: householdId));

    expect(find.text('Artikel 0'), findsOneWidget);
  });
}
