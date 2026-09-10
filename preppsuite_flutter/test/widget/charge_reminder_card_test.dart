import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/charge_reminder_provider.dart';
import 'package:preppsuite_flutter/features/inventory/presentation/charge_reminder_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'accessibility.dart';

/// Choosing how often to check the rechargeable equipment.
///
/// The chips are the common answers; "own interval" covers the rest. What
/// matters beyond storing it is that the chip then shows the chosen number
/// — a setting that reads as unset while a reminder is in fact pending is
/// how somebody ends up setting it twice or not at all.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> show(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.binding.setSurfaceSize(const Size(500, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) =>
                  ChargeReminderCard(l10n: AppLocalizations.of(context)!),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('a fortnight is one of the offered intervals', (tester) async {
    await show(tester);

    expect(find.widgetWithText(ChoiceChip, 'alle 14 Tage'), findsOneWidget);
  });

  testWidgets('an interval typed in is taken', (tester) async {
    final container = await show(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Eigener Abstand…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '21');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(container.read(chargeReminderDaysProvider), 21);
    // And the chip says so, instead of going back to reading "own
    // interval" as though nothing had been chosen.
    expect(find.widgetWithText(ChoiceChip, 'alle 21 Tage'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Eigener Abstand…'), findsNothing);
  });

  testWidgets('a number out of range is refused and the dialog stays open', (
    tester,
  ) async {
    final container = await show(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Eigener Abstand…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '4000');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget, reason: 'still open');
    expect(find.textContaining('zwischen 1 und 365'), findsOneWidget);
    expect(
      container.read(chargeReminderDaysProvider),
      defaultChargeReminderDays,
    );
  });

  testWidgets('cancelling changes nothing', (tester) async {
    final container = await show(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Eigener Abstand…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '21');
    await tester.tap(find.widgetWithText(TextButton, 'Abbrechen'));
    await tester.pumpAndSettle();

    expect(
      container.read(chargeReminderDaysProvider),
      defaultChargeReminderDays,
    );
  });

  testWidgets('the card meets the accessibility guidelines', (tester) async {
    await show(tester);
    await expectAccessible(tester);
  });

  testWidgets('the card survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
