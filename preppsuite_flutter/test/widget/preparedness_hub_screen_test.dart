import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/preparedness/presentation/preparedness_hub_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = PreparednessHubStore();

  InventoryItem item({
    required String clientId,
    required String category,
    required double quantity,
    String unit = 'Stk',
    double? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: 'home',
    name: clientId,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    calories: calories,
    updatedAt: DateTime.utc(2026, 9, 19),
    dirty: false,
  );

  Warning warning({required String severity, required String headline}) =>
      Warning(
        source: 'bbk',
        externalId: headline,
        countryCode: 'DE',
        regionKey: '03241',
        severity: severity,
        eventType: 'Sturm',
        headline: headline,
        effective: DateTime.utc(2026, 9, 19),
        sent: DateTime.utc(2026, 9, 19),
        updatedAt: DateTime.utc(2026, 9, 19),
        notified: false,
      );

  Future<void> show(
    WidgetTester tester, {
    List<InventoryItem> items = const [],
    List<Warning> warnings = const [],
    Locale locale = const Locale('de'),
  }) async {
    // Tall enough that the whole list is built: a `ListView` builds only
    // what it can show, and this screen is the longest in the app.
    tester.view.physicalSize = const Size(1200, 14000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            'home',
          ).overrideWith((ref) => Stream.value(items)),
          householdProfileProvider.overrideWith(_TwoAdults.new),
          activeWarningsProvider.overrideWith((ref) => Stream.value(warnings)),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PreparednessHubScreen(householdId: 'home'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what the household has already written down', (
    tester,
  ) async {
    await store.save(
      PreparednessHubData(
        evacuationCards: [
          EvacuationCard(
            id: 'route',
            label: 'Zuhause',
            start: 'Wohnung',
            destination: 'Treffpunkt Sporthalle',
            route: 'Nebenstrassen',
            locations: 'Apotheke',
            checkedAt: DateTime(2026, 9, 14),
          ),
        ],
        radioPlans: [
          RadioReceptionPlan(
            id: 'radio',
            station: 'Regionalradio',
            band: 'UKW',
            frequency: '95,8 MHz',
            receiver: 'Kurbelradio',
            power: 'Kurbel',
            checkedAt: DateTime(2026, 9, 14),
          ),
        ],
        autonomy: AutonomySnapshot(
          waterDays: 8,
          foodDays: 12,
          medicineDays: 5,
          energyDays: 7,
          hygieneDays: 10,
          checkedAt: DateTime(2026, 9, 14),
        ),
      ),
    );

    await show(tester);

    expect(find.text('Zuhause'), findsOneWidget);
    expect(find.textContaining('Treffpunkt Sporthalle'), findsOneWidget);
    expect(find.text('Regionalradio'), findsOneWidget);
    expect(find.text('Warnwege und Netzwerk'), findsOneWidget);
    // The shortest range is the one that decides, and the screen has to
    // say which supply it is rather than only how many days are left.
    expect(find.textContaining('Medikamente'), findsWidgets);
  });

  testWidgets('a new evacuation card is written to the store', (tester) async {
    await show(tester);

    await tester.tap(find.text('Karte hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Zuhause');
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect((await store.load()).evacuationCards.single.label, 'Zuhause');
  });

  testWidgets('a card without a name is not created', (tester) async {
    await show(tester);

    await tester.tap(find.text('Karte hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect((await store.load()).evacuationCards, isEmpty);
  });

  testWidgets('crisis mode is kept for the next time the screen opens', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(find.text('Vereinfachte, größere Darstellung'));
    await tester.pumpAndSettle();

    expect((await store.load()).crisisMode, isTrue);
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('survives a doubled system font size', (tester) async {
    useLargeText(tester);
    await show(tester);

    expect(find.text('Krisenorganisation'), findsOneWidget);
  });

  testWidgets('the range comes out of the inventory, not out of a dialog', (
    tester,
  ) async {
    await show(
      tester,
      items: [
        item(clientId: 'w', category: 'water', quantity: 40, unit: 'l'),
        item(
          clientId: 'f',
          category: 'food',
          quantity: 1,
          unit: 'kg',
          calories: 880,
        ),
      ],
    );

    // Two adults: 40 litres at 4 a day is ten days, 8800 kcal at 4400 is
    // two — and food is the bottleneck nobody worked out by hand.
    expect(find.textContaining('Engpass Lebensmittel'), findsOneWidget);
    expect(find.text('10 Tage'), findsOneWidget);
    expect(find.text('2 Tage'), findsOneWidget);
    expect(find.text('Aus dem Bestand gerechnet'), findsWidgets);
  });

  testWidgets('a resource the app cannot divide is open, not zero', (
    tester,
  ) async {
    await show(tester);

    // Nothing recorded anywhere: five open questions and no reassuring
    // number in front of them.
    expect(find.text('offen'), findsNWidgets(5));
    expect(find.textContaining('Autarkie noch unvollständig'), findsOneWidget);
  });

  testWidgets('by hand it asks only for what it could not work out', (
    tester,
  ) async {
    await show(
      tester,
      items: [item(clientId: 'w', category: 'water', quantity: 40, unit: 'l')],
    );

    await tester.tap(find.text('Von Hand ergänzen'));
    await tester.pumpAndSettle();

    // Water is answered, so it is not asked for again.
    expect(find.textContaining('Wasser –'), findsNothing);
    expect(find.textContaining('Hygiene'), findsWidgets);
  });

  testWidgets('an English household reads English', (tester) async {
    // This screen was the one area of the app with no translations at
    // all: 171 German strings, including every heading a person has to
    // read under pressure.
    await show(
      tester,
      locale: const Locale('en'),
      items: [
        item(clientId: 'w', category: 'water', quantity: 40, unit: 'l'),
      ],
    );

    expect(find.text('Crisis organisation'), findsOneWidget);
    expect(find.text('Self-sufficiency'), findsOneWidget);
    expect(find.text('Water'), findsWidgets);
    expect(find.text('Worked out from your stock'), findsOneWidget);
    expect(find.text('Add a card'), findsOneWidget);
    expect(find.text('Emergency briefing as PDF'), findsOneWidget);
    // And nothing German left behind on it.
    expect(find.text('Krisenorganisation'), findsNothing);
    expect(find.text('Karte hinzufügen'), findsNothing);
  });

  group('when something is actually happening', () {
    testWidgets('a quiet day says nothing', (tester) async {
      await show(tester);

      expect(find.text('Es läuft gerade etwas'), findsNothing);
    });

    testWidgets('a severe warning reaches the page with the plans on it', (
      tester,
    ) async {
      await show(
        tester,
        warnings: [
          warning(severity: 'severe', headline: 'Orkanböen erwartet'),
        ],
      );

      expect(find.text('Es läuft gerade etwas'), findsOneWidget);
      expect(find.text('Orkanböen erwartet'), findsOneWidget);
      // The card sits on the error container, which is the one colour
      // pair on this page that could fail to read.
      await expectAccessible(tester);
    });

    testWidgets('a wind advisory does not', (tester) async {
      // Crying wolf over a minor warning is how a household learns to
      // scroll past the one that matters.
      await show(
        tester,
        warnings: [warning(severity: 'minor', headline: 'Windig')],
      );

      expect(find.text('Es läuft gerade etwas'), findsNothing);
    });

    testWidgets('the larger display is offered, never switched on', (
      tester,
    ) async {
      await show(
        tester,
        warnings: [warning(severity: 'extreme', headline: 'Hochwasser')],
      );

      // Offered, and off until somebody says so.
      expect((await store.load()).crisisMode, isFalse);

      await tester.tap(find.text('Größere Darstellung einschalten'));
      await tester.pumpAndSettle();

      expect((await store.load()).crisisMode, isTrue);
    });

    testWidgets('the log opens with the warning already in it', (
      tester,
    ) async {
      await show(
        tester,
        warnings: [warning(severity: 'severe', headline: 'Orkanböen erwartet')],
      );

      await tester.tap(find.text('Im Protokoll festhalten'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
      await tester.pumpAndSettle();

      final event = (await store.load()).events.single;
      expect(event.kind, 'Sturm');
      expect(event.note, 'Orkanböen erwartet');
    });
  });
}

/// A household of two adults, which is what the arithmetic in these tests
/// is worked out for.
class _TwoAdults extends HouseholdProfileController {
  @override
  Future<HouseholdProfile?> build() async => const HouseholdProfile(
    id: 'home',
    name: 'Zuhause',
    countryCode: 'DE',
    personCount: 2,
  );
}
