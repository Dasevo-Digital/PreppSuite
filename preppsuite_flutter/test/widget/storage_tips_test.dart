import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/storage_tips_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

import 'accessibility.dart';

/// Stands in for the real profile, which loads from preferences.
class _FixedProfile extends HouseholdProfileController {
  _FixedProfile(this.profile);

  final HouseholdProfile profile;

  @override
  Future<HouseholdProfile?> build() async => profile;
}

void main() {
  const householdId = 'household-1';

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // Tall enough that the whole table is laid out at once: a ListView
  // builds nothing below the fold, so a group further down would be
  // "missing" for reasons that have nothing to do with the table.
  Future<void> tallSurface(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<void> pumpTips(
    WidgetTester tester, {
    int adults = 1,
    int children = 0,
    int dogs = 0,
  }) async {
    await tallSurface(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(
            AppDatabase.forTesting(NativeDatabase.memory()),
          ),
          householdProfileProvider.overrideWith(
            () => _FixedProfile(
              HouseholdProfile(
                id: householdId,
                name: 'Test',
                countryCode: 'DE',
                personCount: adults,
                children: children,
                dogs: dogs,
              ),
            ),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StorageTipsScreen(householdId: householdId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('one person for ten days is the table as printed', (
    tester,
  ) async {
    await pumpTips(tester);

    expect(find.text('Getreideprodukte, Brot, Kartoffeln'), findsOneWidget);
    expect(find.text('3,3 kg'), findsOneWidget);
    expect(find.text('4 kg'), findsOneWidget);
    expect(find.text('20 l'), findsOneWidget);
  });

  testWidgets('a household of four doubles a household of two', (
    tester,
  ) async {
    // The whole reason the table lives in the app instead of as a link:
    // it is printed for one person, and nobody shops for one person.
    await pumpTips(tester, adults: 2, children: 2);

    expect(find.text('13,2 kg'), findsOneWidget);
    expect(find.text('80 l'), findsOneWidget);
  });

  testWidgets('pets are not fed from this table', (tester) async {
    // They eat their own food, which the BLE table does not cover — and
    // counting them here would overstate every row in it.
    await pumpTips(tester, adults: 2, dogs: 3);

    expect(find.text('6,6 kg'), findsOneWidget);
  });

  testWidgets('switching to the vegetarian table swaps one group', (
    tester,
  ) async {
    await pumpTips(tester);

    expect(find.text('Eier, Fleisch, Wurst und Fisch'), findsOneWidget);

    await tester.tap(find.text('Vegetarisch'));
    await tester.pumpAndSettle();

    expect(find.text('Eier, Fleisch, Wurst und Fisch'), findsNothing);
    expect(
      find.text('Eier, Ersatzprodukte für Fleisch, Wurst und Fisch'),
      findsOneWidget,
    );
    // Everything else stays put.
    expect(find.text('Getreideprodukte, Brot, Kartoffeln'), findsOneWidget);
  });

  testWidgets('a food row states its scaled amount and energy', (tester) async {
    await pumpTips(tester, adults: 2);

    await tester.tap(find.text('Milch und Milcherzeugnisse'));
    await tester.pumpAndSettle();

    expect(find.text('Hartkäse'), findsOneWidget);
    expect(find.textContaining('1 kg · 3780 kcal'), findsOneWidget);
  });

  testWidgets('the storage table meets the accessibility guidelines', (
    tester,
  ) async {
    await pumpTips(tester, adults: 2, children: 1);
    await expectAccessible(tester);
  });

  testWidgets('the storage table survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await pumpTips(tester, adults: 2, children: 1);
  });

  testWidgets('adding a row hands over the energy of one unit, not the row', (
    tester,
  ) async {
    // The regression this pins. The table prints "710 g · 1512 kcal", and
    // the inventory column holds the energy in **one** unit — so what has
    // to arrive in the form is 2.13, the kilocalories of a single gram.
    //
    // Passing the printed 1512 straight through was correct while the
    // column meant "total for the current quantity". After that changed
    // it read as 1512 kcal per gram: a factor of 710, and in the
    // direction that tells a household its cellar is full.
    await pumpTips(tester);

    await tester.tap(find.text('Getreideprodukte, Brot, Kartoffeln'));
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Vollkornbrot, abgepackt'),
      matching: find.byType(ListTile),
    );
    expect(row, findsOneWidget);

    await tester.tap(
      find.descendant(of: row, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(InventoryItemFormScreen), findsOneWidget);

    // 1512 / 710. Not 1512, and not a whole number either — which is the
    // second half of the same story: as an integer the only thing this
    // could have said was 2.
    final field = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Kalorien je g (kcal, optional)'),
    );
    expect(double.parse(field.controller!.text), closeTo(2.13, 0.01));

    // And the line underneath multiplies it back out to roughly what the
    // table printed, which is how a wrong basis would be visible.
    expect(find.textContaining('1512'), findsOneWidget);
  });
}
