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

  /// What the dialog suggests and hands back once an item names its
  /// package (#90). It used to suggest "1" for everything, so a quick tap
  /// on an item in grams took one gram off a kilo and the calorie total
  /// barely moved. Whatever is typed, the caller gets the item's unit.
  group('with a package', () {
    InventoryItem jars({double quantity = 1110}) => InventoryItem(
      clientId: 'beans',
      householdId: 'h',
      name: 'Bohnen',
      category: 'food',
      quantity: quantity,
      unit: 'g',
      storageLocation: 'Keller',
      packageName: 'Glas',
      packageSize: 370,
      updatedAt: DateTime.utc(2026),
      dirty: false,
    );

    String fieldText(WidgetTester tester) =>
        tester.widget<TextField>(find.byType(TextField)).controller!.text;

    Future<void> confirm(WidgetTester tester) async {
      await tester.tap(find.text('Abbuchen'));
      await tester.pumpAndSettle();
    }

    testWidgets('suggests one jar, and hands back its grams', (tester) async {
      final result = await openDialog(tester, jars());

      expect(fieldText(tester), '1');
      expect(find.text('Das sind 370 g.'), findsOneWidget);

      await confirm(tester);
      expect(result.value, 370);
    });

    testWidgets('two jars are two jars of grams', (tester) async {
      final result = await openDialog(tester, jars());

      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      expect(find.text('Das sind 740 g.'), findsOneWidget);

      await confirm(tester);
      expect(result.value, 740);
    });

    testWidgets('less than a jar left suggests what is left', (tester) async {
      final result = await openDialog(tester, jars(quantity: 185));

      expect(fieldText(tester), '0,5');
      await confirm(tester);
      expect(result.value, 185);
    });

    testWidgets('switching to grams carries the amount across', (
      tester,
    ) async {
      final result = await openDialog(tester, jars());

      await tester.tap(find.text('g').first);
      await tester.pumpAndSettle();
      expect(fieldText(tester), '370');

      await tester.enterText(find.byType(TextField), '100');
      await confirm(tester);
      expect(result.value, 100);
    });

    testWidgets('more jars than there are is refused', (tester) async {
      final result = await openDialog(tester, jars());

      await tester.enterText(find.byType(TextField), '4');
      await confirm(tester);

      expect(find.byType(ConsumeDialog), findsOneWidget);
      expect(result.closed, isFalse);
    });

    testWidgets('all three jars of a stock of exactly three are accepted', (
      tester,
    ) async {
      final result = await openDialog(tester, jars());

      await tester.enterText(find.byType(TextField), '3');
      await confirm(tester);
      expect(result.value, 1110);
    });

    testWidgets('meets the accessibility guidelines', (tester) async {
      await openDialog(tester, jars());
      await expectAccessible(tester);
    });

    testWidgets('survives twice the font size', (tester) async {
      useLargeText(tester);
      await openDialog(tester, jars());
    });
  });

  testWidgets('grams without a package suggest nothing, not one gram', (
    tester,
  ) async {
    final result = await openDialog(tester, item(quantity: 1000, unit: 'g'));

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.byType(SegmentedButton<bool>), findsNothing);

    await tester.tap(find.text('Abbuchen'));
    await tester.pumpAndSettle();
    expect(result.closed, isFalse);
  });
}

/// Mutable holder for what the dialog popped: [value] is the amount, and
/// [closed] separates "dismissed with nothing" from "never closed at all",
/// which a null amount alone cannot tell apart.
class _Result {
  double? value;
  bool closed = false;
}
