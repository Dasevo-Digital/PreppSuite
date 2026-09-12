import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_range.dart';
import 'package:preppsuite_flutter/features/energy/application/energy_store.dart';
import 'package:preppsuite_flutter/features/energy/presentation/energy_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> show(WidgetTester tester) async {
    // Tall enough to build the whole list; a `ListView` builds only what
    // it can show and this screen carries two lists and a card.
    tester.view.physicalSize = const Size(1200, 5000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EnergyScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> savePlan({
    List<EnergyReserve> reserves = const [],
    List<EnergyDraw> draws = const [],
  }) => const EnergyPlanStore().save(
    EnergyPlan(reserves: reserves, draws: draws),
  );

  testWidgets('with nothing entered it says what to enter', (tester) async {
    await show(tester);

    expect(find.text('Noch nichts eingetragen'), findsOneWidget);
    // And where the two numbers come from, because that is the whole
    // premise: the app does not estimate them.
    expect(find.textContaining('160 g/h'), findsOneWidget);
  });

  testWidgets('a stove and two cartridges come out as days', (tester) async {
    await savePlan(
      reserves: const [
        EnergyReserve(
          id: 'a',
          kind: EnergyKind.gas,
          label: 'Kartuschen',
          amount: 460,
        ),
      ],
      draws: const [
        EnergyDraw(
          id: 'b',
          kind: EnergyKind.gas,
          label: 'Gaskocher',
          perHour: 160,
          hoursPerDay: 1,
        ),
      ],
    );
    await show(tester);

    expect(find.text('2 Tage'), findsWidgets);
    // The working, so the number can be checked rather than believed.
    expect(find.textContaining('160 g am Tag von 460 g'), findsOneWidget);
  });

  testWidgets('the shortest reserve is named as the household range', (
    tester,
  ) async {
    await savePlan(
      reserves: const [
        EnergyReserve(
          id: 'a',
          kind: EnergyKind.gas,
          label: 'Kartuschen',
          amount: 1380,
        ),
        EnergyReserve(
          id: 'b',
          kind: EnergyKind.candles,
          label: 'Teelichter',
          amount: 40,
        ),
      ],
      draws: const [
        EnergyDraw(
          id: 'c',
          kind: EnergyKind.gas,
          label: 'Kocher',
          perHour: 160,
          hoursPerDay: 1,
        ),
        EnergyDraw(
          id: 'd',
          kind: EnergyKind.candles,
          label: 'Abendlicht',
          perHour: 1,
          hoursPerDay: 6,
        ),
      ],
    );
    await show(tester);

    // Gas lasts eight days, candlelight six. Six is the answer.
    expect(
      find.textContaining('Zuerst leer: Kerzenlicht – 6 Tage'),
      findsOneWidget,
    );
  });

  testWidgets('stocked but unused is not read as lasting for ever', (
    tester,
  ) async {
    await savePlan(
      reserves: const [
        EnergyReserve(
          id: 'a',
          kind: EnergyKind.gas,
          label: 'Kartuschen',
          amount: 460,
        ),
      ],
    );
    await show(tester);

    expect(find.textContaining('nichts verbraucht es'), findsOneWidget);
    expect(find.textContaining('Zuerst leer'), findsNothing);
    expect(find.textContaining('Noch keine Reichweite'), findsOneWidget);
  });

  testWidgets('a reserve typed in is calculated and kept', (tester) async {
    await show(tester);

    await tester.tap(find.byTooltip('Vorrat hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Kartuschen');
    await tester.enterText(find.byType(TextField).at(1), '460');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Verbraucher hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Gaskocher');
    await tester.enterText(find.byType(TextField).at(1), '160');
    await tester.enterText(find.byType(TextField).at(2), '1');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.text('2 Tage'), findsWidgets);

    final stored = await const EnergyPlanStore().load();
    expect(stored.reserves.single.amount, 460);
    expect(stored.draws.single.perHour, 160);
  });

  testWidgets('a comma is a decimal point, not a thousands separator', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(find.byTooltip('Vorrat hinzufügen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Petroleum');
    await tester.enterText(find.byType(TextField).at(1), '2,5');
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    final stored = await const EnergyPlanStore().load();
    expect(stored.reserves.single.amount, closeTo(2.5, 1e-9));
  });

  testWidgets('an entry without a number is refused with a reason', (
    tester,
  ) async {
    await show(tester);

    await tester.tap(find.byTooltip('Vorrat hinzufügen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Eine Zahl größer als null'), findsOneWidget);
    expect(find.textContaining('Eine Bezeichnung'), findsOneWidget);
    // And nothing was saved behind the dialog.
    expect((await const EnergyPlanStore().load()).reserves, isEmpty);
  });

  testWidgets('an entry can be deleted again', (tester) async {
    await savePlan(
      reserves: const [
        EnergyReserve(
          id: 'a',
          kind: EnergyKind.gas,
          label: 'Kartuschen',
          amount: 460,
        ),
      ],
    );
    await show(tester);

    await tester.tap(find.text('Kartuschen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Kartuschen'), findsNothing);
    expect((await const EnergyPlanStore().load()).reserves, isEmpty);
  });

  testWidgets('it says the figures are the household\'s own', (tester) async {
    await show(tester);

    expect(find.textContaining('schätzt keinen Verbrauch'), findsOneWidget);
    // And the one conversion that is genuinely needed, with its caveat.
    expect(find.textContaining('20000 mAh sind 74 Wh'), findsOneWidget);
    expect(
      find.textContaining('das ist die Zelle, nicht die Steckdose'),
      findsOneWidget,
    );
  });

  testWidgets('is accessible', (tester) async {
    await savePlan(
      reserves: const [
        EnergyReserve(
          id: 'a',
          kind: EnergyKind.gas,
          label: 'Kartuschen',
          amount: 460,
        ),
      ],
      draws: const [
        EnergyDraw(
          id: 'b',
          kind: EnergyKind.gas,
          label: 'Gaskocher',
          perHour: 160,
          hoursPerDay: 1,
        ),
      ],
    );
    await show(tester);

    await expectAccessible(tester);
  });
}
