import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/household/presentation/lock_screen_card_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'accessibility.dart';

/// The choice in front of the lock-screen picture (#103).
void main() {
  final card = HouseholdMember(
    clientId: 'lena',
    householdId: 'h',
    name: 'Lena',
    bloodType: 'A+',
    allergies: 'Penicillin',
    medication: 'Ramipril',
    sortOrder: 0,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  Future<AppLocalizations> show(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LockScreenCardDialog(card: card)),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(
      tester.element(find.byType(LockScreenCardDialog)),
    )!;
  }

  bool ticked(WidgetTester tester, String label) => tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, label))
      .value!;

  testWidgets('says who can read it before anything is chosen', (
    tester,
  ) async {
    final l10n = await show(tester);
    expect(find.text(l10n.lockScreenCardPrivacy), findsOneWidget);
  });

  testWidgets('offers only what the card has, medication unticked', (
    tester,
  ) async {
    final l10n = await show(tester);

    expect(ticked(tester, l10n.emergencyCardAllergies), isTrue);
    expect(ticked(tester, l10n.emergencyCardMedication), isFalse);
    // Nothing typed in, nothing offered.
    expect(
      find.widgetWithText(CheckboxListTile, l10n.emergencyCardConditions),
      findsNothing,
    );
  });

  testWidgets('nothing ticked, nothing to create', (tester) async {
    final l10n = await show(tester);
    for (final label in [
      l10n.emergencyCardName,
      l10n.emergencyCardBloodType,
      l10n.emergencyCardAllergies,
    ]) {
      await tester.tap(find.widgetWithText(CheckboxListTile, label));
    }
    await tester.pump();

    final create = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, l10n.lockScreenCardCreate),
    );
    expect(create.onPressed, isNull);
  });

  testWidgets('survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester);
  });
}
