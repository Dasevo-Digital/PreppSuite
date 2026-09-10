import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/budget/presentation/budget_entry_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Deleting an expense.
///
/// This was the one deletion in the app with neither a question in front
/// of it nor a way back after it: one tap on an icon in the title bar,
/// gone, and the screen closed behind it. The household plan and the
/// emergency card ask first; the inventory offers an undo. Three answers
/// to one question is how a habit fails to form.
void main() {
  const householdId = 'household-1';
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  final entry = BudgetEntry(
    clientId: 'entry-1',
    householdId: householdId,
    label: 'Wasserkanister',
    amountCents: 1290,
    currency: 'EUR',
    category: 'water',
    purchaseDate: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 1),
    dirty: false,
  );

  Future<void> show(WidgetTester tester) async {
    await db.upsertBudgetEntry(
      BudgetEntriesCompanion.insert(
        clientId: entry.clientId,
        householdId: householdId,
        label: entry.label,
        amountCents: entry.amountCents,
        currency: entry.currency,
        category: entry.category,
        purchaseDate: Value(entry.purchaseDate),
        updatedAt: entry.updatedAt,
        dirty: const Value(false),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(600, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Pushed onto a route of its own, because deleting pops the
          // screen and a popped root leaves nothing for the snack bar to
          // sit on.
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BudgetEntryFormScreen(
                      householdId: householdId,
                      existing: entry,
                    ),
                  ),
                ),
                child: const Text('auf'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('auf'));
    await tester.pumpAndSettle();
  }

  Future<BudgetEntry?> stored() async {
    final rows = await db.budgetEntriesForSync(householdId);
    return rows.where((row) => row.clientId == entry.clientId).firstOrNull;
  }

  testWidgets('deleting offers a way back instead of asking first', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    // Gone, and said so, with the offer still on screen.
    expect((await stored())!.deletedAt, isNotNull);
    expect(find.text('Ausgabe gelöscht'), findsOneWidget);
    expect(find.text('Rückgängig'), findsOneWidget);
  });

  testWidgets('and taking it back really restores the entry', (tester) async {
    await show(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();

    final row = await stored();
    expect(row!.deletedAt, isNull);
    expect(row.label, 'Wasserkanister');
    // Still marked for the other devices, so the undo travels too — the
    // deletion had already gone out as a tombstone.
    expect(row.dirty, isTrue);
  });

  testWidgets('the form closes first, so the offer outlives it', (
    tester,
  ) async {
    // The order matters. Popping the screen after showing the snack bar
    // takes the snack bar down with the route it was shown on, and the
    // undo would flash past unusable. So the screen goes, then the offer
    // appears on what is left behind.
    await show(tester);
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(
      find.byType(BudgetEntryFormScreen),
      findsNothing,
      reason: 'the form is gone',
    );
    expect(find.text('Rückgängig'), findsOneWidget, reason: 'the offer is not');
  });

  testWidgets('the form meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the form survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
