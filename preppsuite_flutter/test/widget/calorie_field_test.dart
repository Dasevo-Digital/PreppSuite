import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The calorie field, on the basis a label actually prints.
///
/// Per 100 g, so the whole numbers off a packet go straight in. The
/// fractions live in the arithmetic instead — 400 g is four fifths of the
/// basis — which is why the column is still a real and why the field must
/// take a decimal at all. It once read its own contents with
/// `int.tryParse` and no comma handling, so neither "2,13" nor "2.13" was
/// accepted: it asked for a figure it would not take.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> open(WidgetTester tester, InventoryItem item) async {
    await tester.binding.setSurfaceSize(const Size(600, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: InventoryItemFormScreen(householdId: 'h', existing: item),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  InventoryItem bread({double? calories}) => InventoryItem(
    clientId: 'bread',
    householdId: 'h',
    name: 'Vollkornbrot',
    category: 'food',
    quantity: 400,
    unit: 'g',
    storageLocation: 'Keller',
    calories: calories,
    updatedAt: DateTime.utc(2026, 9, 21),
    dirty: false,
  );

  Finder calorieField(WidgetTester tester) {
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InventoryItemFormScreen)),
    )!;
    return find.widgetWithText(
      TextFormField,
      l10n.caloriesPer100Label('100 g'),
    );
  }

  testWidgets('the field is named after the unit the household typed', (
    tester,
  ) async {
    await open(tester, bread());
    expect(calorieField(tester), findsOneWidget);
  });

  testWidgets('a decimal with a comma is accepted', (tester) async {
    await open(tester, bread());
    await tester.enterText(calorieField(tester), '2,13');
    await tester.pumpAndSettle();

    final form = tester.state<FormState>(find.byType(Form));
    expect(form.validate(), isTrue);
  });

  testWidgets('and so is one with a point', (tester) async {
    await open(tester, bread());
    await tester.enterText(calorieField(tester), '2.13');
    await tester.pumpAndSettle();

    expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
  });

  testWidgets('the number reported as rejected goes in', (tester) async {
    // 1,26 — the figure from the report. Neither spelling was taken.
    for (final typed in ['1,26', '1.26']) {
      await open(tester, bread());
      await tester.enterText(calorieField(tester), typed);
      await tester.pumpAndSettle();
      expect(
        tester.state<FormState>(find.byType(Form)).validate(),
        isTrue,
        reason: typed,
      );
    }
  });

  testWidgets('something that is not a number is still refused', (
    tester,
  ) async {
    await open(tester, bread());
    await tester.enterText(calorieField(tester), 'zwei Komma eins');
    await tester.pumpAndSettle();

    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
  });

  testWidgets('the line underneath works the label out over the stock', (
    tester,
  ) async {
    // The whole reason the field can be trusted: 400 g at 213 kcal per
    // 100 g is 852, and it says so where a wrong basis would be obvious.
    await open(tester, bread());
    await tester.enterText(calorieField(tester), '213');
    await tester.pumpAndSettle();

    expect(find.textContaining('852'), findsOneWidget);
  });

  testWidgets('a stored fraction comes back as one', (tester) async {
    await open(tester, bread(calories: 2.13));
    await tester.pumpAndSettle();

    expect(find.text('2.13'), findsOneWidget);
  });

  testWidgets('a unit that is not a measure is refused for food', (
    tester,
  ) async {
    // The rule the whole basis rests on: per 100 g only becomes a total
    // if the stock can be said in grams. "Dose" cannot.
    await open(tester, bread().copyWith(unit: 'Dose'));
    expect(tester.state<FormState>(find.byType(Form)).validate(), isFalse);
  });

  testWidgets('but a medicine keeps counting in tablets', (tester) async {
    // Where forcing grams would destroy a working calculation: the
    // medicine reach divides tablets by a daily dose.
    await open(
      tester,
      InventoryItem(
        clientId: 'pills',
        householdId: 'h',
        name: 'Ramipril',
        category: 'medical',
        quantity: 60,
        unit: 'Tablette',
        storageLocation: 'Hausapotheke',
        dailyDose: 2,
        updatedAt: DateTime.utc(2026, 9, 22),
        dirty: false,
      ),
    );

    expect(tester.state<FormState>(find.byType(Form)).validate(), isTrue);
  });
}
