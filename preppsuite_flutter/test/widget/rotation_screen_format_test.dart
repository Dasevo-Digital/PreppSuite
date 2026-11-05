import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_providers.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/rotation_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// "What to use next" in the reader's own notation (#294).
///
/// The screen formatted its dates without a locale, and `intl` falls back
/// to en_US when nobody sets one: the fifth of November read as
/// "11/5/2026" to a German reader, who could take it for the eleventh of
/// May. Its amounts came out of `toString()`, with a decimal point.
void main() {
  testWidgets('dates and amounts as a German reader writes them', (
    tester,
  ) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final today = DateTime.now();
    final expiry = DateTime(today.year, today.month, today.day + 10);
    final item = InventoryItem(
      clientId: 'mehl',
      householdId: 'h',
      name: 'Mehl',
      category: 'food',
      quantity: 1.5,
      unit: 'kg',
      storageLocation: 'Keller',
      expirationDate: expiry,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          inventoryItemsProvider(
            'h',
          ).overrideWith((ref) => Stream.value([item])),
        ],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const RotationScreen(householdId: 'h'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final date = '${expiry.day}.${expiry.month}.${expiry.year}';
    expect(find.textContaining(date), findsOneWidget);
    expect(find.textContaining('1,5 kg'), findsOneWidget);
    expect(find.textContaining('1.5 kg'), findsNothing);
  });
}
