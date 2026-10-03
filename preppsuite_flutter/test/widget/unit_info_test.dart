import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_list_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Why a tin is not a unit, said before somebody is refused for using one.
///
/// The rule has been enforced since nutrition moved to per 100 g. What
/// was missing was the explanation: the form said "here it needs a
/// measure" and the calculator quietly left the row out, and nothing
/// anywhere said why or what would happen to the row.
void main() {
  const householdId = 'h';
  late AppDatabase db;
  final now = DateTime.utc(2026, 9, 22);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  InventoryItem item({
    required String clientId,
    required String unit,
    String category = 'food',
  }) => InventoryItem(
    clientId: clientId,
    householdId: householdId,
    name: clientId,
    category: category,
    quantity: 6,
    unit: unit,
    storageLocation: 'Keller',
    updatedAt: now,
    dirty: false,
  );

  late AppLocalizations l10n;

  Future<void> pump(
    WidgetTester tester,
    Widget home, {
    List<InventoryItem> stock = const [],
  }) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            householdId,
          ).overrideWith((ref) => Stream.value(stock)),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  group('on the inventory', () {
    testWidgets('food in tins is named, with how many', (tester) async {
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [
          item(clientId: 'ravioli', unit: 'Dose'),
          item(clientId: 'gurken', unit: 'Glas'),
          item(clientId: 'reis', unit: 'kg'),
        ],
      );

      expect(find.text(l10n.foodWithoutMeasureTitle), findsOneWidget);
      // The paragraph stays behind the tap: this row sits above a list
      // somebody opened to do something else.
      expect(find.text(l10n.foodWithoutMeasureBody(2)), findsNothing);

      await tester.tap(find.text(l10n.unitInfoAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.foodWithoutMeasureBody(2)), findsOneWidget);
    });

    testWidgets('and a pantry that all counts says nothing', (tester) async {
      // A note about nothing is a note people learn to scroll past.
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [item(clientId: 'reis', unit: 'kg')],
      );

      expect(find.text(l10n.foodWithoutMeasureTitle), findsNothing);
    });

    testWidgets('a medicine in tablets is not a complaint', (tester) async {
      // Forcing grams here would break the one calculation it has.
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [
          item(clientId: 'ramipril', unit: 'Tablette', category: 'medical'),
        ],
      );

      expect(find.text(l10n.foodWithoutMeasureTitle), findsNothing);
    });
  });

  group('the explanation itself', () {
    testWidgets('says what happens to the rows that already say Dose', (
      tester,
    ) async {
      // The question somebody actually has when they are refused: is my
      // pantry about to be rewritten? It is not.
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [item(clientId: 'ravioli', unit: 'Dose')],
      );

      await tester.tap(find.text(l10n.unitInfoAction));
      await tester.pumpAndSettle();

      expect(find.text(l10n.unitInfoTitle), findsOneWidget);
      expect(find.text(l10n.unitInfoWhy), findsOneWidget);
      expect(find.text(l10n.unitInfoKept), findsOneWidget);
      expect(find.text(l10n.unitInfoExempt), findsOneWidget);
    });

    testWidgets('and offers the units as something to tap', (tester) async {
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [item(clientId: 'ravioli', unit: 'Dose')],
      );
      await tester.tap(find.text(l10n.unitInfoAction));
      await tester.pumpAndSettle();

      for (final unit in ['g', 'kg', 'ml', 'l']) {
        expect(find.widgetWithText(ActionChip, unit), findsOneWidget);
      }
    });
  });

  group('on the form', () {
    testWidgets('the field carries the question for food', (tester) async {
      await pump(
        tester,
        const InventoryItemFormScreen(householdId: householdId),
      );

      expect(find.byTooltip(l10n.unitInfoAction), findsOneWidget);
    });

    testWidgets('tapping a unit answers the field it was asked from', (
      tester,
    ) async {
      // An explanation beside a field that still needs filling in is
      // half an answer. The field is right behind the dialog.
      await pump(
        tester,
        const InventoryItemFormScreen(householdId: householdId),
      );

      await tester.tap(find.byTooltip(l10n.unitInfoAction));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'kg'));
      await tester.pumpAndSettle();

      // Read from the unit field itself: since #90 the package size
      // beside it shows the unit as its suffix, so "a field showing kg"
      // is two fields.
      final unitField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, l10n.unitLabel),
      );
      expect(unitField.controller!.text, 'kg');
    });
  });
}
