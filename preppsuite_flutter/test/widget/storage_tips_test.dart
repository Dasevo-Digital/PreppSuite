import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
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
}
