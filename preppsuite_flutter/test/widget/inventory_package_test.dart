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

/// The package on the form and in the list (#90).
///
/// Saving is not tapped through to the database here, for the reason
/// `emergency_card_people_test.dart` gives; what is stored is tested in
/// `inventory_controller_test.dart`.
void main() {
  const householdId = 'h';
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  InventoryItem beans({double quantity = 1110}) => InventoryItem(
    clientId: 'beans',
    householdId: householdId,
    name: 'Bohnen',
    category: 'food',
    quantity: quantity,
    unit: 'g',
    storageLocation: 'Keller',
    packageName: 'Glas',
    packageSize: 370,
    updatedAt: DateTime.utc(2026, 9, 22),
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

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  group('the form', () {
    testWidgets('opens with the stored package', (tester) async {
      await pump(
        tester,
        InventoryItemFormScreen(householdId: householdId, existing: beans()),
      );

      expect(
        tester
            .widget<TextFormField>(field(l10n.packageNameLabel))
            .controller!
            .text,
        'Glas',
      );
      expect(
        tester
            .widget<TextFormField>(field(l10n.packageSizeLabel))
            .controller!
            .text,
        '370',
      );
      expect(find.text(l10n.packageHelp('g')), findsOneWidget);
    });

    testWidgets('refuses a name without a size', (tester) async {
      await pump(
        tester,
        InventoryItemFormScreen(householdId: householdId, existing: beans()),
      );

      await tester.enterText(field(l10n.packageSizeLabel), '');
      await tester.tap(find.text(l10n.saveButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.packageIncomplete), findsOneWidget);
      expect(find.byType(InventoryItemFormScreen), findsOneWidget);
    });

    testWidgets('refuses a size of nothing', (tester) async {
      await pump(
        tester,
        InventoryItemFormScreen(householdId: householdId, existing: beans()),
      );

      await tester.enterText(field(l10n.packageSizeLabel), '0');
      await tester.tap(find.text(l10n.saveButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.packageSizeInvalid), findsOneWidget);
    });
  });

  group('the list', () {
    testWidgets('names whole jars', (tester) async {
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [beans()],
      );

      expect(find.textContaining('3 × Glas'), findsOneWidget);
      expect(find.textContaining('≈'), findsNothing);
    });

    testWidgets('says when it is not whole jars', (tester) async {
      await pump(
        tester,
        const InventoryListScreen(householdId: householdId),
        stock: [beans(quantity: 1000)],
      );

      expect(find.textContaining('≈ 2,7 × Glas'), findsOneWidget);
    });
  });
}
