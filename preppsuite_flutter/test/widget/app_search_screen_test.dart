import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/possessions/application/possession_controller.dart';
import 'package:preppsuite_flutter/features/search/presentation/app_search_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One place to ask where something is.
void main() {
  const householdId = 'h';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 2,
  );
  final now = DateTime.utc(2026, 9, 22);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  final stock = [
    InventoryItem(
      clientId: 'reis',
      householdId: householdId,
      name: 'Basmatireis',
      category: 'food',
      quantity: 2,
      unit: 'kg',
      storageLocation: 'Keller',
      updatedAt: now,
      dirty: false,
    ),
  ];

  final templates = [
    ChecklistTemplate(
      clientId: 't1',
      householdId: householdId,
      title: 'Notgepäck',
      category: 'evacuation',
      kind: 'preparation',
      isBuiltIn: true,
      updatedAt: now,
      dirty: false,
    ),
  ];

  final entries = [
    ChecklistItem(
      clientId: 'i1',
      householdId: householdId,
      templateClientId: 't1',
      title: 'Kurbelradio',
      isChecked: false,
      sortOrder: 0,
      updatedAt: now,
      dirty: false,
    ),
  ];

  var navigatedTo = <ShellDestination>[];
  late AppLocalizations l10n;

  Future<void> open(WidgetTester tester) async {
    navigatedTo = [];
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(stock)),
          checklistTemplatesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(templates)),
          allChecklistItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(entries)),
          possessionsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppSearchScreen(
            profile: profile,
            onNavigate: navigatedTo.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(AppSearchScreen)))!;
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pumpAndSettle();
  }

  testWidgets('nothing typed shows what it can look through', (tester) async {
    // A list of every screen and every tin in the house is not an
    // answer, so the empty state says what the box is for instead.
    await open(tester);

    expect(find.text(l10n.searchStartHint), findsOneWidget);
    expect(find.byType(ListTile), findsNothing);
  });

  testWidgets('a screen is found by its name', (tester) async {
    await open(tester);
    await type(tester, 'pegel');

    expect(find.text(l10n.pegelTitle), findsOneWidget);
    // And it says where it lives, which is half of finding it next time.
    expect(find.textContaining(l10n.warningsTitle), findsWidgets);
  });

  testWidgets('and by a word that is not in its name', (tester) async {
    // "Hochwasser" is what somebody types; "Pegelstände" is what the
    // screen is called.
    await open(tester);
    await type(tester, 'hochwasser');

    expect(find.text(l10n.pegelTitle), findsOneWidget);
  });

  testWidgets('the stock is searched too, and says where it is kept', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'basmati');

    expect(find.text('Basmatireis'), findsOneWidget);
    expect(find.textContaining('Keller'), findsOneWidget);
  });

  testWidgets('a checklist entry is found under the list it belongs to', (
    tester,
  ) async {
    await open(tester);
    await type(tester, 'kurbel');

    expect(find.text('Kurbelradio'), findsOneWidget);
    expect(find.textContaining('Notgepäck'), findsOneWidget);
  });

  testWidgets('a missing umlaut still finds the list', (tester) async {
    await open(tester);
    await type(tester, 'notgepack');

    expect(find.text('Notgepäck'), findsOneWidget);
  });

  testWidgets('nothing matching says so, with what was asked', (tester) async {
    await open(tester);
    await type(tester, 'quinoa');

    expect(find.text(l10n.searchNothingFound('quinoa')), findsOneWidget);
  });

  testWidgets('a tab result closes the search and switches to it', (
    tester,
  ) async {
    // Not a pushed copy of the inventory above the shell: the tab bar
    // would be gone and the back button would lead somewhere odd.
    await open(tester);
    await type(tester, l10n.inventoryTitle);
    await tester.tap(find.text(l10n.inventoryTitle).first);
    await tester.pumpAndSettle();

    expect(navigatedTo, [ShellDestination.inventory]);
  });
}
