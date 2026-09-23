import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/shell_layout.dart';
import 'package:preppsuite_flutter/features/home/application/status_lights.dart';
import 'package:preppsuite_flutter/features/home/presentation/status_lights_row.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two lamps at the top of the overview.
void main() {
  const householdId = 'h';
  const profile = HouseholdProfile(
    id: householdId,
    name: 'Testhaushalt',
    countryCode: 'DE',
    personCount: 1,
  );
  final now = DateTime.utc(2026, 9, 22);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  InventoryItem item({
    required String clientId,
    String category = 'food',
    double quantity = 100,
    String unit = 'g',
    double? calories,
  }) => InventoryItem(
    clientId: clientId,
    householdId: householdId,
    name: clientId,
    category: category,
    quantity: quantity,
    unit: unit,
    storageLocation: 'Keller',
    calories: calories,
    updatedAt: now,
    dirty: false,
  );

  Warning warning(String severity) => Warning(
    source: 'bbk',
    externalId: severity,
    countryCode: 'DE',
    severity: severity,
    eventType: 'Test',
    headline: severity,
    effective: now,
    notified: false,
    sent: now,
    updatedAt: now,
  );

  final stocked = [
    item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
    item(clientId: 'f', quantity: 10000, unit: 'g', calories: 250),
  ];

  late AppLocalizations l10n;
  var went = <ShellDestination>[];

  Future<void> pump(
    WidgetTester tester, {
    required List<InventoryItem> items,
    List<Warning> warnings = const [],
  }) async {
    went = [];
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(items)),
          activeWarningsProvider.overrideWith((ref) => Stream.value(warnings)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // In a list, which is where it actually lives. A bounded box
          // hides the one way this can fail to lay out at all: a row
          // that stretches has nothing to stretch to in a `ListView`.
          home: Scaffold(
            body: ListView(
              children: [
                StatusLightsRow(profile: profile, onNavigate: went.add),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
  }

  testWidgets('a stocked household reads as covered, with the days', (
    tester,
  ) async {
    await pump(tester, items: stocked);

    expect(find.text(l10n.statusSupplyCovered(10)), findsOneWidget);
    // Whose ten days these are, said on the lamp and not in a footnote.
    expect(find.textContaining(l10n.statusSupplyLimitWater), findsOneWidget);
    expect(
      find.textContaining(l10n.statusSupplyBasis(statusLightDays)),
      findsOneWidget,
    );
  });

  testWidgets('a short household says how far it gets', (tester) async {
    await pump(
      tester,
      items: [
        item(clientId: 'w', category: 'water', quantity: 20, unit: 'l'),
        item(clientId: 'f', quantity: 500, unit: 'g', calories: 250),
      ],
    );

    expect(find.textContaining('von $statusLightDays'), findsOneWidget);
    expect(find.textContaining(l10n.statusSupplyLimitCalories), findsOneWidget);
  });

  testWidgets('the lamp admits what it could not count', (tester) async {
    await pump(
      tester,
      items: [
        ...stocked,
        item(clientId: 'ravioli', quantity: 6, unit: 'Dose', calories: 90),
      ],
    );

    expect(find.textContaining(l10n.statusSupplyUncounted(1)), findsOneWidget);
  });

  testWidgets('the limiting factor remains readable on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryItemsProvider(householdId).overrideWith(
            (ref) => Stream.value([
              item(clientId: 'w', category: 'water', quantity: 8, unit: 'l'),
              item(clientId: 'f', quantity: 500, unit: 'g', calories: 250),
            ]),
          ),
          activeWarningsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ListView(
              children: [
                StatusLightsRow(profile: profile, onNavigate: went.add),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Begrenzender Faktor:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the situation lamp', () {
    testWidgets('quiet is stated as quiet, and never as all-clear', (
      tester,
    ) async {
      await pump(tester, items: stocked);

      expect(find.text(l10n.statusSituationQuiet), findsOneWidget);
      expect(find.text(l10n.statusSituationQuietHint), findsOneWidget);
    });

    testWidgets('a warning in force shows the issuer own wording', (
      tester,
    ) async {
      await pump(tester, items: stocked, warnings: [warning('Severe')]);

      expect(find.text(l10n.warningSeveritySevere), findsOneWidget);
      expect(find.text(l10n.statusSituationActive(1)), findsOneWidget);
    });

    testWidgets('and the worst of several is the one on the lamp', (
      tester,
    ) async {
      await pump(
        tester,
        items: stocked,
        warnings: [warning('Minor'), warning('Extreme'), warning('Moderate')],
      );

      expect(find.text(l10n.warningSeverityExtreme), findsOneWidget);
      expect(find.text(l10n.statusSituationActive(3)), findsOneWidget);
    });
  });

  testWidgets('each lamp leads to the screen that can do something', (
    tester,
  ) async {
    await pump(tester, items: stocked);

    await tester.tap(find.text(l10n.statusSupplyTitle));
    await tester.pumpAndSettle();
    expect(went, [ShellDestination.inventory]);

    await tester.tap(find.text(l10n.statusSituationTitle));
    await tester.pumpAndSettle();
    expect(went, [ShellDestination.inventory, ShellDestination.warnings]);
  });
}
