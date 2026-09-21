import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The calorie field, for a household that counts in grams.
///
/// The field is named after the unit — "Kalorien je g" — and every usable
/// number for a gram is a fraction. It used to read its own contents with
/// `int.tryParse` and no comma handling, which is two refusals at once:
/// neither "2,13" nor "2.13" was accepted. So the field asked for a figure
/// it would not take, and there was no way to answer it correctly.
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
    return find.widgetWithText(TextFormField, l10n.caloriesPerUnitLabel('g'));
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

  testWidgets('the line underneath multiplies the fraction out', (
    tester,
  ) async {
    // The whole reason the field can be trusted: 400 g at 2.13 kcal a
    // gram is 852, and it says so where a wrong basis would be obvious.
    await open(tester, bread());
    await tester.enterText(calorieField(tester), '2,13');
    await tester.pumpAndSettle();

    expect(find.textContaining('852'), findsOneWidget);
  });

  testWidgets('a stored fraction comes back as one', (tester) async {
    await open(tester, bread(calories: 2.13));
    await tester.pumpAndSettle();

    expect(find.text('2.13'), findsOneWidget);
  });
}
