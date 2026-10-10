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

/// A food list leads to the supply groups, where its per-person amounts
/// meet the household's own stores (#31).
void main() {
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  ChecklistTemplate template(String category) => ChecklistTemplate(
    clientId: 't',
    householdId: 'h',
    title: 'Lebensmittel',
    category: category,
    kind: 'preparation',
    isBuiltIn: true,
    updatedAt: DateTime.utc(2024),
    dirty: false,
  );

  Future<AppLocalizations> pump(WidgetTester tester, String category) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          checklistItemsProvider(
            't',
          ).overrideWith((ref) => Stream.value(const <ChecklistItem>[])),
          inventoryItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value(const <InventoryItem>[])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ChecklistDetailScreen(
            template: template(category),
            householdId: 'h',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(Scaffold).first))!;
  }

  testWidgets('a food list links to the supply groups', (tester) async {
    final l10n = await pump(tester, 'food');

    expect(find.text(l10n.supplyGroupsTitle), findsOneWidget);
  });

  testWidgets('another list does not', (tester) async {
    final l10n = await pump(tester, 'hygiene');

    expect(find.text(l10n.supplyGroupsTitle), findsNothing);
  });
}
