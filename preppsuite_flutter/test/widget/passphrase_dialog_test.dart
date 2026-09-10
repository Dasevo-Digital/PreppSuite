import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/passphrase_dialog.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The passphrase that stands between a stolen backup file and a
/// household's blood groups.
///
/// There were no tests here at all, and the two things worth having are
/// exactly the two that were wrong: nobody was told that forgetting the
/// passphrase is final, and the dialog did not own its text controllers.
void main() {
  /// Opens the dialog and hands back what it returned.
  Future<String?> show(WidgetTester tester, {required bool confirm}) async {
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showDialog<String>(
                  context: context,
                  builder: (_) => PassphraseDialog(
                    l10n: AppLocalizations.of(context)!,
                    confirm: confirm,
                  ),
                );
              },
              child: const Text('auf'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('auf'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('creating a backup says that a lost passphrase is final', (
    tester,
  ) async {
    await show(tester, confirm: true);

    expect(find.textContaining('nicht mehr öffnen'), findsOneWidget);
    expect(find.textContaining('kein'), findsWidgets);
  });

  testWidgets('restoring one does not, because it is already chosen', (
    tester,
  ) async {
    // The warning is about choosing a passphrase you will have to
    // remember for years. Repeating it while somebody types one they
    // already have would train them to skip it.
    await show(tester, confirm: false);

    expect(find.textContaining('nicht mehr öffnen'), findsNothing);
  });

  testWidgets('a second field is asked for only when choosing', (
    tester,
  ) async {
    await show(tester, confirm: true);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.pumpWidget(const SizedBox.shrink());
    await show(tester, confirm: false);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('eleven characters are refused, twelve accepted', (tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await show(tester, confirm: false);

    await tester.enterText(find.byType(TextField), '01234567890');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget, reason: 'still open');
    expect(find.textContaining('12 Zeichen'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '012345678901');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the two entries have to match', (tester) async {
    await show(tester, confirm: true);
    final fields = find.byType(TextField);

    await tester.enterText(fields.first, 'ein gutes Kennwort');
    await tester.enterText(fields.last, 'ein anderes Kennwort');
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('closing it does not use a disposed controller', (tester) async {
    // The regression this dialog was rebuilt for. The controllers used to
    // be created next to `showDialog` and disposed the moment it
    // returned — while the closing animation still had the fields
    // mounted. Pumping the animation frame by frame is what makes that
    // visible; `pumpAndSettle` after a throw would report the throw
    // anyway, but only if the frames in between are drawn.
    await show(tester, confirm: true);

    await tester.enterText(find.byType(TextField).first, 'lang genug hier');
    await tester.enterText(find.byType(TextField).last, 'lang genug hier');
    await tester.tap(find.text('OK'));

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(tester.takeException(), isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('the dialog meets the accessibility guidelines', (tester) async {
    await show(tester, confirm: true);
    await expectAccessible(tester);
  });

  testWidgets('it survives twice the font size', (tester) async {
    useLargeText(tester);
    await show(tester, confirm: true);
  });
}
