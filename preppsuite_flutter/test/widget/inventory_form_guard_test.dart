import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/inventory_item_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingController extends InventoryController {
  RecordingController(super.db, super.householdId);
  final deleted = <String>[];
  final restored = <String>[];
  @override
  Future<void> deleteItem(InventoryItem item) async =>
      deleted.add(item.clientId);
  @override
  Future<void> restoreItem(String id) async => restored.add(id);
}

void main() {
  late AppDatabase db;
  late RecordingController controller;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    controller = RecordingController(db, 'h');
  });
  tearDown(() => db.close());
  final item = InventoryItem(
    clientId: 'a',
    householdId: 'h',
    name: 'Nudeln',
    category: 'food',
    quantity: 2,
    unit: 'Stk',
    storageLocation: 'Keller',
    updatedAt: DateTime(2026),
    dirty: false,
  );
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryControllerProvider('h').overrideWith((ref) => controller),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => InventoryItemFormScreen(
                      householdId: 'h',
                      existing: item,
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('unchanged form leaves without a confirmation', (tester) async {
    await open(tester);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(InventoryItemFormScreen), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'edited form asks, keeps edits on cancel and discards only on confirmation',
    (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextFormField).first, 'Reis');
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(AlertDialog)),
      )!;
      await tester.tap(find.text(l10n.keepEditing));
      await tester.pumpAndSettle();
      expect(find.text('Reis'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.discardChanges));
      await tester.pumpAndSettle();
      expect(find.byType(InventoryItemFormScreen), findsNothing);
    },
  );
  testWidgets('reverting an edit no longer asks to discard', (tester) async {
    await open(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Reis');
    await tester.enterText(find.byType(TextFormField).first, 'Nudeln');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(InventoryItemFormScreen), findsNothing);
  });
  testWidgets('delete returns to list and offers a working undo action', (
    tester,
  ) async {
    await open(tester);
    final l10n = AppLocalizations.of(
      tester.element(find.byType(InventoryItemFormScreen)),
    )!;
    await tester.tap(find.byTooltip(l10n.deleteButton));
    await tester.pumpAndSettle();
    expect(controller.deleted, ['a']);
    expect(find.byType(InventoryItemFormScreen), findsNothing);
    await tester.tap(find.text(l10n.undoAction));
    await tester.pumpAndSettle();
    expect(controller.restored, ['a']);
  });
}
