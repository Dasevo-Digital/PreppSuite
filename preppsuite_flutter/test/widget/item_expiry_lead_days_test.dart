import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/item_expiry_lead_days_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

/// The lead times of one item, which has three states and not two.
///
/// Null is "follow the household", an empty string is "never for this
/// one", and a list is its own. The line on the form and the dialog
/// behind it have to agree about all three — a form that says "as the
/// household" over a row that is really silent would be the worst of the
/// possible bugs here, because nothing would ever fire to contradict it.
void main() {
  late AppLocalizations l10n;

  // A phone-sized surface clips the chip row behind the three radio
  // rows, and a tap on a widget below the fold lands on the barrier
  // instead — which reads exactly like a chip that refuses to toggle.
  Future<void> roomForTheDialog(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
  }

  Future<ItemLeadDaysChoice?> openDialog(
    WidgetTester tester, {
    required String? current,
    List<int> household = const [30, 7],
  }) async {
    await roomForTheDialog(tester);
    ItemLeadDaysChoice? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await showItemLeadDays(
                    context,
                    current: current,
                    householdLeadDays: household,
                  );
                },
                child: const Text('auf'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('auf'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('the summary line says which of the three states applies', (
    tester,
  ) async {
    await openDialog(tester, current: null);
    await tester.tap(find.text(l10n.cancelButton));
    await tester.pumpAndSettle();

    expect(
      itemLeadDaysSummary(l10n, null, const [30, 7]),
      'Wie im Haushalt: 30 Tage, 7 Tage',
    );
    expect(
      itemLeadDaysSummary(l10n, '', const [30, 7]),
      l10n.itemExpiryRemindersNever,
    );
    expect(itemLeadDaysSummary(l10n, '7,30', const [30, 7]), '30 Tage, 7 Tage');
    // Even where the household has none, "follow the household" still has
    // to read as following it and not as this item's own silence.
    expect(
      itemLeadDaysSummary(l10n, null, const []),
      l10n.itemExpiryRemindersDefaultNone,
    );
  });

  testWidgets('choosing never returns an empty string, not null', (
    tester,
  ) async {
    await roomForTheDialog(tester);
    ItemLeadDaysChoice? choice;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return Scaffold(
              body: ElevatedButton(
                onPressed: () async => choice = await showItemLeadDays(
                  context,
                  current: null,
                  householdLeadDays: const [30, 7],
                ),
                child: const Text('auf'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('auf'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.itemExpiryRemindersNever));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.saveButton));
    await tester.pumpAndSettle();

    expect(choice, isNotNull);
    // Null here would mean "follow the household", which is the opposite
    // of what was just asked for.
    expect(choice!.value, '');
  });

  testWidgets('own lead times cannot be saved with nothing ticked', (
    tester,
  ) async {
    await openDialog(tester, current: '');

    await tester.tap(find.text(l10n.itemExpiryRemindersOwn));
    await tester.pumpAndSettle();

    // Starting from "never", the chips come up preselected with the
    // household's own list, so there is something to save.
    expect(find.byType(FilterChip), findsWidgets);
    final selected = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected)
        .toList();
    expect(selected, hasLength(2));

    // Clear them all and the save button has to go dead: "own, none" is
    // just "never" spelled a second way. Tapped by their label, because
    // every tap rebuilds the chips and the old instances are gone.
    final labels = [
      for (final chip in selected) (chip.label as Text).data!,
    ];
    for (final label in labels) {
      await tester.tap(find.widgetWithText(FilterChip, label));
      await tester.pumpAndSettle();
    }
    final stillSelected = tester
        .widgetList<FilterChip>(find.byType(FilterChip))
        .where((chip) => chip.selected)
        .map((chip) => (chip.label as Text).data)
        .toList();
    expect(stillSelected, isEmpty, reason: 'noch gewaehlt: $stillSelected');
    final save = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.saveButton),
    );
    expect(save.onPressed, isNull);
  });
}
