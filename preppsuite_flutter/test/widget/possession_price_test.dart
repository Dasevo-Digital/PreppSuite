import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/possessions/presentation/possession_form_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The purchase price of a possession, as people type it (#245).
void main() {
  const householdId = 'household-1';
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  Future<void> save(WidgetTester tester, String price) async {
    await tester.binding.setSurfaceSize(const Size(600, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const PossessionFormScreen(householdId: householdId),
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
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Gegenstand'),
      'Waschmaschine',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kaufpreis'),
      price,
    );
    await tester.ensureVisible(find.text('Speichern'));
    await tester.tap(find.text('Speichern'));
    await tester.pumpAndSettle();
  }

  testWidgets('a decimal comma is a price in cents', (tester) async {
    await save(tester, '549,90');

    final rows = await db.possessionsForSync(householdId);
    expect(rows.single.purchasePriceCents, 54990);
  });

  for (final typed in ['1e400', 'Infinity', '-20']) {
    testWidgets('"$typed" is refused and nothing is saved', (tester) async {
      await save(tester, typed);

      expect(find.text('Bitte eine gültige Zahl eingeben.'), findsOneWidget);
      expect(await db.possessionsForSync(householdId), isEmpty);
      expect(tester.takeException(), isNull);
    });
  }
}
