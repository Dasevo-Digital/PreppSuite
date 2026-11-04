import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/checklists/presentation/checklist_detail_screen.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The line under a checklist item says what is on the shelf today, the
/// same figure its tick is decided by, written as a number is written
/// here (#272). It said the count of a pack in daily use, and printed it
/// as a double: "Ramipril: 30.0 Tablette vorhanden" beside an unticked
/// box, while ten were left.
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  final template = ChecklistTemplate(
    clientId: 't',
    householdId: 'h',
    title: 'Hausapotheke',
    category: 'medical',
    kind: 'preparation',
    isBuiltIn: false,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  // Thirty counted twenty days ago at one a day: ten are left.
  final pills = InventoryItem(
    clientId: 'ramipril',
    householdId: 'h',
    name: 'Ramipril',
    category: 'medical',
    quantity: 30,
    unit: 'Tablette',
    storageLocation: 'Bad',
    dailyDose: 1,
    refillLeadDays: 7,
    stockCountedAt: DateTime.now().subtract(const Duration(days: 20)),
    updatedAt: DateTime.now().toUtc(),
    dirty: false,
  );

  final rice = InventoryItem(
    clientId: 'reis',
    householdId: 'h',
    name: 'Reis',
    category: 'food',
    quantity: 1.5,
    unit: 'kg',
    storageLocation: 'Keller',
    updatedAt: DateTime.now().toUtc(),
    dirty: false,
  );

  ChecklistItem line(String id, String title, String linked, double target) =>
      ChecklistItem(
        clientId: id,
        householdId: 'h',
        templateClientId: 't',
        title: title,
        isChecked: false,
        linkedInventoryItemId: linked,
        targetQuantity: target,
        sortOrder: 0,
        updatedAt: DateTime.utc(2026),
        dirty: false,
      );

  Future<AppLocalizations> pump(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          checklistItemsProvider('t').overrideWith(
            (ref) => Stream.value([
              line('a', 'Blutdrucktabletten für zwei Wochen', 'ramipril', 14),
              line('b', 'Reis', 'reis', 1),
            ]),
          ),
          inventoryItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([pills, rice])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChecklistDetailScreen(template: template, householdId: 'h'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('the line says what is left today, as a number is written', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Ramipril: 10 Tablette vorhanden'), findsOneWidget);
    expect(find.text('Reis: 1,5 kg vorhanden'), findsOneWidget);
    expect(find.textContaining('30.0'), findsNothing);

    // Ten are fewer than fourteen: unticked, and the line says why.
    final medicine = tester.widget<CheckboxListTile>(
      find.widgetWithText(
        CheckboxListTile,
        'Blutdrucktabletten für zwei Wochen',
      ),
    );
    expect(medicine.value, isFalse);
  });

  testWidgets('so does the list a pack is chosen from', (tester) async {
    final l10n = await pump(tester);

    await tester.tap(find.byTooltip(l10n.moreActions).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.checklistLinkStockAction));
    await tester.pumpAndSettle();

    expect(find.text('10 Tablette'), findsOneWidget);
    expect(find.text('1,5 kg'), findsOneWidget);
  });
}
