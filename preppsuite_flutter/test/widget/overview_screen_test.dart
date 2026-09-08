import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/home/presentation/overview_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

import 'accessibility.dart';

/// The counting is settled in `test/features/home/home_overview_test.dart`.
/// What is left here is whether the cards show it, and whether tapping one
/// leads where it says it does.
void main() {
  const householdId = 'household-1';
  final now = DateTime.now();

  InventoryItem item({
    String clientId = 'a',
    String category = 'food',
    double quantity = 5,
    String unit = 'Packung',
    double? minQuantity,
    DateTime? expirationDate,
    int? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: householdId,
    name: 'Vorrat',
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    minQuantity: minQuantity,
    expirationDate: expirationDate,
    calories: calories,
    updatedAt: now,
    dirty: false,
  );

  Warning warning({String headline = 'Hochwasser', String? regionKey}) =>
      Warning(
        source: 'bbk',
        externalId: 'w1',
        countryCode: 'DE',
        regionKey: regionKey,
        severity: 'severe',
        eventType: 'Flood',
        headline: headline,
        effective: now,
        sent: now,
        updatedAt: now,
        notified: false,
      );

  Future<List<ShellDestination>> pumpOverview(
    WidgetTester tester, {
    List<InventoryItem> items = const [],
    List<Warning> warnings = const [],
    List<ChecklistTemplate> templates = const [],
    List<ChecklistItem> checklistItems = const [],
    int adults = 2,
  }) async {
    final navigated = <ShellDestination>[];

    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(items)),
          activeWarningsProvider.overrideWith((ref) => Stream.value(warnings)),
          checklistTemplatesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(templates)),
          allChecklistItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(checklistItems)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OverviewScreen(
            profile: HouseholdProfile(
              id: householdId,
              name: 'Testhaushalt',
              countryCode: 'DE',
              regionKey: '03241',
              personCount: adults,
            ),
            onNavigate: navigated.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return navigated;
  }

  testWidgets('an empty household says so instead of looking ready', (
    tester,
  ) async {
    await pumpOverview(tester);

    expect(find.textContaining('noch nichts eingetragen'), findsOneWidget);
    expect(
      find.text('Zurzeit keine Warnung für deine Regionen.'),
      findsOneWidget,
    );
  });

  testWidgets('the supply card counts water and calories for ten days', (
    tester,
  ) async {
    // Two adults, ten days: 40 litres and 44,000 kcal.
    await pumpOverview(
      tester,
      items: [
        item(clientId: 'w', category: 'water', quantity: 10, unit: 'L'),
        item(clientId: 'f', calories: 11000),
      ],
    );

    expect(find.text('Versorgung für 10 Tage'), findsOneWidget);
    expect(find.text('10.0 von 40.0 L'), findsOneWidget);
    expect(find.text('11000 von 44000 kcal'), findsOneWidget);
  });

  testWidgets('expired and low stock are shown apart', (tester) async {
    await pumpOverview(
      tester,
      items: [
        item(
          clientId: 'old',
          expirationDate: now.subtract(const Duration(days: 2)),
        ),
        item(clientId: 'low', quantity: 1, minQuantity: 5),
      ],
    );

    expect(find.text('abgelaufen'), findsOneWidget);
    expect(find.text('unter Mindestmenge'), findsOneWidget);
    expect(find.text('läuft in 30 Tagen ab'), findsOneWidget);
  });

  testWidgets('a warning for this region is named on the card', (tester) async {
    await pumpOverview(
      tester,
      warnings: [warning(headline: 'Hochwasser Leine', regionKey: '03241')],
    );

    expect(find.text('Hochwasser Leine'), findsOneWidget);
  });

  testWidgets('a warning somewhere else is not counted here', (tester) async {
    // The card uses the same relevance rule as the banner, so it cannot
    // report calm while the banner above it is red.
    await pumpOverview(
      tester,
      warnings: [warning(headline: 'Sturm Bayern', regionKey: '09162')],
    );

    expect(find.text('Sturm Bayern'), findsNothing);
    expect(
      find.text('Zurzeit keine Warnung für deine Regionen.'),
      findsOneWidget,
    );
  });

  testWidgets('every category is listed, including the empty ones', (
    tester,
  ) async {
    await pumpOverview(tester, items: [item(category: 'water')]);

    expect(find.text('Wasser · 1'), findsOneWidget);
    expect(find.text('Dokumente · 0'), findsOneWidget);
  });

  testWidgets('a card leads to the screen that can act on it', (tester) async {
    final navigated = await pumpOverview(
      tester,
      warnings: [warning(regionKey: '03241')],
    );

    await tester.tap(find.text('Warnungen'));
    await tester.pumpAndSettle();
    expect(navigated, [ShellDestination.warnings]);

    await tester.tap(find.text('Ressourcen'));
    await tester.pumpAndSettle();
    expect(navigated.last, ShellDestination.inventory);
  });

  testWidgets('the overview meets the accessibility guidelines', (
    tester,
  ) async {
    await pumpOverview(
      tester,
      items: [item()],
      warnings: [warning(regionKey: '03241')],
    );
    await expectAccessible(tester);
  });

  testWidgets('the overview survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await pumpOverview(
      tester,
      items: [item()],
      warnings: [warning(regionKey: '03241')],
    );
  });

  testWidgets('a supply gauge is read out as one thing, not three', (
    tester,
  ) async {
    // Name, figure and bar only mean anything together. Without merging,
    // a screen reader stops three times and the percentage arrives
    // detached from what it is a percentage of.
    final handle = tester.ensureSemantics();
    await pumpOverview(
      tester,
      items: [item(clientId: 'w', category: 'water', quantity: 10, unit: 'L')],
    );

    final water = tester.getSemantics(
      find.byType(LinearProgressIndicator).first,
    );
    // Flutter joins the labels it merges with newlines.
    final spoken = water.label.replaceAll('\n', ' ');
    expect(spoken, 'Trinkwasser 10.0 von 40.0 L');
    expect(water.value, '25 %');
    handle.dispose();
  });
}
