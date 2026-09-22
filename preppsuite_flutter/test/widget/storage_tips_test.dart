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

  testWidgets('adding a row hands over the label, not the line total', (
    tester,
  ) async {
    // The regression this pins. The table prints "710 g · 1512 kcal", and
    // the inventory column holds what a label states — per 100 g. So what
    // has to arrive in the form is 213, not 1512.
    //
    // Passing the printed total straight through was correct while the
    // column meant "total for the current quantity". After that changed
    // it read first as 1512 kcal per gram — a factor of 710, in the
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

    final field = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Kalorien je 100 g (kcal, optional)'),
    );
    expect(double.parse(field.controller!.text), closeTo(213, 1));

    // And the line underneath multiplies it back out to what the table
    // printed, which is how a wrong basis would be visible.
    expect(find.textContaining('1512'), findsOneWidget);
  });

  testWidgets('eggs come over as grams, because a label needs a weight', (
    tester,
  ) async {
    // The only row the table counts in pieces, and food is counted in a
    // measure now. The weight is the source's own arithmetic: the group
    // totals 1200 g, the other rows come to 905 g, so five eggs are
    // 295 g — 59 g each, which is weight class M.
    await pumpTips(tester);

    await tester.tap(find.text('Eier, Fleisch, Wurst und Fisch'));
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('Eier (Gewichtsklasse M)'),
      matching: find.byType(ListTile),
    );
    await tester.tap(
      find.descendant(of: row, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();

    final quantity = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Menge'),
    );
    expect(double.parse(quantity.controller!.text), closeTo(295, 1));

    final unit = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Einheit'),
    );
    expect(unit.controller!.text, 'g');
  });
}
