import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/consume_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'accessibility.dart';

void main() {
  InventoryItem item({double quantity = 5, String unit = 'Stk'}) {
    return InventoryItem(
      clientId: 'c',
      householdId: 'h',
      name: 'Nudeln',
      category: 'food',
      quantity: quantity,
      unit: unit,
      storageLocation: 'Keller',
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );
  }

  /// Builds a fresh tree and opens the dialog on it, so every call starts
  /// from a clean slate — reusing one tree would leave the previous dialog
  /// on top, and the next tap would land on it instead.
  ///
  /// The returned holder is filled once the dialog pops, which is what the
  /// caller would receive and deduct.
  Future<_Result> openDialog(WidgetTester tester, InventoryItem forItem) async {
    final result = _Result();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result.value = await showDialog<double>(
                context: context,
                builder: (_) => ConsumeDialog(
                  item: forItem,
                  l10n: AppLocalizations.of(context)!,
                ),
              );
              result.closed = true;
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ConsumeDialog), findsOneWidget);
    return result;
  }

  testWidgets('is pre-filled with 1 and shows the stock on hand', (
    tester,
  ) async {
    await openDialog(tester, item(quantity: 5, unit: 'Dose'));

    expect(find.text('Nudeln verbrauchen'), findsOneWidget);
    expect(find.text('Bestand: 5 Dose'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '1',
    );
  });

  testWidgets('confirming returns the entered amount', (tester) async {
    final result = await openDialog(tester, item(quantity: 5));

    await tester.enterText(find.byType(TextField), '2');
    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();

    expect(result.value, 2);
  });

  testWidgets('a comma is accepted as the decimal separator', (tester) async {
    final result = await openDialog(tester, item(quantity: 5));

    await tester.enterText(find.byType(TextField), '1,5');
    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();

    expect(result.value, 1.5);
  });

  testWidgets('the whole stock may be deducted', (tester) async {
    final result = await openDialog(tester, item(quantity: 5));

    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();

    expect(result.value, 5, reason: 'exactly the stock is still valid');
  });

  testWidgets('rejects more than the stock on hand and stays open', (
    tester,
  ) async {
    final result = await openDialog(tester, item(quantity: 5));

    await tester.enterText(find.byType(TextField), '9');
    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsumeDialog), findsOneWidget);
    expect(result.closed, isFalse);
    expect(
      find.text('Menge muss grösser als 0 und höchstens der Bestand sein.'),
      findsOneWidget,
    );
  });

  for (final invalid in ['0', '-1', 'viel', '']) {
    testWidgets('rejects "$invalid"', (tester) async {
      final result = await openDialog(tester, item(quantity: 5));

      await tester.enterText(find.byType(TextField), invalid);
      await tester.tap(find.text('Abbuchen'));
      await tester.pumpAndSettle();

      expect(find.byType(ConsumeDialog), findsOneWidget);
      expect(result.closed, isFalse);
    });
  }

  testWidgets('"used up entirely" returns the whole stock', (tester) async {
    final result = await openDialog(tester, item(quantity: 3.5));

    await tester.tap(find.text('Alles verbraucht'));
    await tester.pumpAndSettle();

    expect(result.value, 3.5);
  });

  testWidgets('cancelling returns nothing', (tester) async {
    final result = await openDialog(tester, item(quantity: 5));

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(find.byType(ConsumeDialog), findsNothing);
    expect(result.closed, isTrue);
    expect(result.value, isNull);
  });

  testWidgets('the deduction dialog meets the accessibility guidelines', (
    tester,
  ) async {
    await openDialog(tester, item());
    await expectAccessible(tester);
  });

  testWidgets('the deduction dialog survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await openDialog(tester, item());
  });
}

/// Mutable holder for what the dialog popped: [value] is the amount, and
/// [closed] separates "dismissed with nothing" from "never closed at all",
/// which a null amount alone cannot tell apart.
class _Result {
  double? value;
  bool closed = false;
}
