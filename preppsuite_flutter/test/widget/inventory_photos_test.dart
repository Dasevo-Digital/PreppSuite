import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Up to three photos of one item in the form (#211).
///
/// The files are not there: what is tested is which path goes where. A
/// picture that is not on disk stays a grey tile, the same as it does
/// after a handover that did not bring it.
void main() {
  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<InventoryItem> stored({
    String? first,
    String? second,
    String? third,
  }) async {
    await db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'a',
        householdId: 'h',
        name: 'Linsen',
        category: 'food',
        quantity: 2,
        unit: 'kg',
        storageLocation: 'Keller',
        photoPath: Value(first),
        secondPhotoPath: Value(second),
        thirdPhotoPath: Value(third),
        updatedAt: DateTime.utc(2026),
      ),
    );
    return (await db.inventoryItemsForSync('h')).single;
  }

  Future<void> open(
    WidgetTester tester,
    InventoryItem existing, {
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: InventoryItemFormScreen(householdId: 'h', existing: existing),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.text('Speichern');
    await tester.ensureVisible(button);
    await tester.tap(button);
    // A photo left out is deleted from the disk, which is real file work
    // the test clock does not wait for.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  Future<InventoryItem> reread() async =>
      (await db.inventoryItemsForSync('h')).single;

  testWidgets('two photos stand side by side, with room for a third', (
    tester,
  ) async {
    await open(tester, await stored(first: 'p/a.jpg', second: 'p/b.jpg'));

    expect(find.bySemanticsLabel('Foto 1 von 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Foto 2 von 2'), findsOneWidget);
    expect(find.byTooltip('Foto hinzufügen'), findsOneWidget);
    expect(
      find.text('Bis zu drei Fotos. Das erste zeigt die Liste.'),
      findsOneWidget,
    );
  });

  testWidgets('the second can be put first, and the save keeps both', (
    tester,
  ) async {
    await open(tester, await stored(first: 'p/a.jpg', second: 'p/b.jpg'));

    await tester.tap(find.bySemanticsLabel('Foto 2 von 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Als erstes Foto zeigen'));
    await tester.pumpAndSettle();
    await save(tester);

    final row = await reread();
    expect(row.photoPath, 'p/b.jpg');
    expect(row.secondPhotoPath, 'p/a.jpg');
    expect(row.thirdPhotoPath, isNull);
  });

  testWidgets('the first photo offers no "put first"', (tester) async {
    await open(tester, await stored(first: 'p/a.jpg', second: 'p/b.jpg'));

    await tester.tap(find.bySemanticsLabel('Foto 1 von 2'));
    await tester.pumpAndSettle();

    expect(find.text('Foto zuschneiden'), findsOneWidget);
    expect(find.text('Als erstes Foto zeigen'), findsNothing);
  });

  testWidgets('removing the first moves the second up', (tester) async {
    await open(tester, await stored(first: 'p/a.jpg', second: 'p/b.jpg'));

    await tester.tap(find.bySemanticsLabel('Foto 1 von 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Foto entfernen'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Foto'), findsOneWidget);
    await save(tester);

    final row = await reread();
    expect(row.photoPath, 'p/b.jpg');
    expect(row.secondPhotoPath, isNull);
  });

  testWidgets('a third that came without the second is the second here', (
    tester,
  ) async {
    // After a handover that left the second photo behind. Opened and
    // saved, the form closes the gap.
    await open(tester, await stored(first: 'p/a.jpg', third: 'p/c.jpg'));

    expect(find.bySemanticsLabel('Foto 2 von 2'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Rote Linsen');
    await save(tester);

    final row = await reread();
    expect(row.photoPath, 'p/a.jpg');
    expect(row.secondPhotoPath, 'p/c.jpg');
    expect(row.thirdPhotoPath, isNull);
  });

  testWidgets('three photos fill the row on a phone at twice the font', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360 * 3, 780 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(
      tester,
      await stored(first: 'p/a.jpg', second: 'p/b.jpg', third: 'p/c.jpg'),
      textScale: 2,
    );

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Foto 3 von 3'), findsOneWidget);
    expect(find.byTooltip('Foto hinzufügen'), findsNothing);
  });

  testWidgets('without a photo it is the one labelled tile', (tester) async {
    await open(tester, await stored());

    expect(find.text('Foto hinzufügen'), findsOneWidget);
    expect(
      find.text('Bis zu drei Fotos. Das erste zeigt die Liste.'),
      findsNothing,
    );
  });
}
