import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/home/presentation/overview_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    double? calories,
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
    Size size = const Size(900, 1600),
  }) async {
    final navigated = <ShellDestination>[];

    await tester.binding.setSurfaceSize(size);
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
    //
    // The food line is five packets at 2,200 kcal each, written out
    // rather than left to the helper's defaults: the stored figure is
    // per unit and the calculator multiplies by the quantity. This test
    // used to pass with one packet's worth of calories on a shelf of
    // five, because the multiplication was missing on both sides.
    await pumpOverview(
      tester,
      items: [
        item(clientId: 'w', category: 'water', quantity: 10, unit: 'L'),
        // Five kilograms at 220 kcal per 100 g is 11,000 -- five times
        // one kilogram, so the multiplication is still visible here.
        item(clientId: 'f', quantity: 5, unit: 'kg', calories: 220),
      ],
    );

    expect(find.text('Versorgung für 10 Tage'), findsOneWidget);
    expect(find.text('10,0 von 40,0 L'), findsOneWidget);
    expect(find.text('11.000 von 44.000 kcal'), findsOneWidget);
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

  testWidgets('the short card on the right leaves no gap under it', (
    tester,
  ) async {
    // Der Wrap davor legte zeilenweise aus, und eine Zeile war so hoch wie
    // ihre hoechste Karte. Neben "Braucht Aufmerksamkeit" liess die kurze
    // "Warnungen" darunter Leere stehen, bis die naechste Zeile begann --
    // auf einem Haushalt ohne Warnung der groesste leere Fleck des
    // Bildschirms. Gemessen statt angesehen, weil genau das im Bild
    // auffaellt und in keinem Test.
    await pumpOverview(tester, size: const Size(1400, 1600));

    Rect boxOf(String title) => tester.getRect(
      find.ancestor(of: find.text(title), matching: find.byType(Card)).first,
    );

    final attention = boxOf('Braucht Aufmerksamkeit');
    final warning = boxOf('Warnungen');
    final checklists = boxOf('Checklisten');
    final resources = boxOf('Ressourcen');

    // Zwei Spalten, dieselbe Verteilung wie zuvor.
    expect(attention.left, lessThan(warning.left));
    expect(checklists.left, closeTo(attention.left, 0.5));
    expect(resources.left, closeTo(warning.left, 0.5));

    // Und beide Spalten stapeln dicht: genau der Zwischenraum, kein Rest
    // einer Zeilenhoehe. Die kurze Karte ist dabei wirklich kuerzer, sonst
    // wuerde dieser Test auch ueber einem Wrap gruen.
    expect(warning.height, lessThan(attention.height));
    expect(resources.top - warning.bottom, closeTo(12, 0.5));
    expect(checklists.top - attention.bottom, closeTo(12, 0.5));
  });

  testWidgets('narrow, the cards stay in one column', (tester) async {
    await pumpOverview(tester, size: const Size(600, 1600));

    Rect boxOf(String title) => tester.getRect(
      find.ancestor(of: find.text(title), matching: find.byType(Card)).first,
    );

    final attention = boxOf('Braucht Aufmerksamkeit');
    final warning = boxOf('Warnungen');

    expect(warning.left, closeTo(attention.left, 0.5));
    expect(warning.top, greaterThan(attention.bottom - 1));
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
    expect(spoken, 'Trinkwasser 10,0 von 40,0 L');
    expect(water.value, '25 %');
    handle.dispose();
  });

  group('the equipment check on the attention card', () {
    // It used to live only in a notification: it arrived, it was
    // dismissed, and the overview said nothing about it. Two places
    // answering "what wants doing" means one of them stops being read.
    Future<ProviderContainer> pumpWithCheck(
      WidgetTester tester, {
      required int everyDays,
      DateTime? lastChecked,
    }) async {
      SharedPreferences.setMockInitialValues({
        'chargeReminderDays': everyDays,
        if (lastChecked != null)
          'chargeReminderLastChecked': lastChecked.toIso8601String(),
      });
      final container = ProviderContainer(
        overrides: [
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value([item()])),
          activeWarningsProvider.overrideWith((ref) => Stream.value(const [])),
          checklistTemplatesProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
          allChecklistItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('de'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: OverviewScreen(
              profile: const HouseholdProfile(
                id: householdId,
                name: 'Testhaushalt',
                countryCode: 'DE',
                regionKey: '03241',
                personCount: 2,
              ),
              onNavigate: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('switched off, the card says nothing about it', (tester) async {
      await pumpWithCheck(tester, everyDays: 0);

      expect(find.textContaining('Akkugeräte prüfen'), findsNothing);
    });

    testWidgets('never confirmed reads as that, not as overdue', (
      tester,
    ) async {
      await pumpWithCheck(tester, everyDays: 90);

      expect(find.textContaining('Noch nicht bestätigt'), findsOneWidget);
      expect(find.textContaining('überfällig'), findsNothing);
    });

    testWidgets('a check long past reads as overdue', (tester) async {
      await pumpWithCheck(
        tester,
        everyDays: 14,
        lastChecked: DateTime.now().toUtc().subtract(const Duration(days: 20)),
      );

      expect(find.textContaining('überfällig'), findsOneWidget);
    });

    testWidgets('a recent check reads as the days remaining', (tester) async {
      await pumpWithCheck(
        tester,
        everyDays: 14,
        lastChecked: DateTime.now().toUtc().subtract(const Duration(days: 4)),
      );

      expect(find.textContaining('Nächste Prüfung in'), findsOneWidget);
      expect(find.textContaining('überfällig'), findsNothing);
    });

    testWidgets('confirming it there and then clears the overdue state', (
      tester,
    ) async {
      final container = await pumpWithCheck(
        tester,
        everyDays: 14,
        lastChecked: DateTime.now().toUtc().subtract(const Duration(days: 20)),
      );

      await tester.tap(find.widgetWithText(TextButton, 'Geprüft'));
      await tester.pumpAndSettle();

      expect(container.read(chargeCheckProvider).isDue(), isFalse);
      expect(find.textContaining('überfällig'), findsNothing);
      expect(find.textContaining('Nächste Prüfung in'), findsOneWidget);
    });
  });
}
