import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/presentation/backup_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import 'accessibility.dart';

/// The three roads a backup can take off this device.
///
/// Sharing is the one that exists because of a platform limit rather than
/// a wish: on Android the file picker cannot reach OneDrive or Google
/// Drive — neither registers a document tree — while both are perfectly
/// ordinary share targets. Without this tile a household using either of
/// them has no way to move its backup at all.
void main() {
  Future<void> show(WidgetTester tester, {Locale locale = const Locale('de')}) {
    return tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: SingleChildScrollView(
                child: BackupCard(
                  householdId: 'home',
                  l10n: AppLocalizations.of(context)!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('all three roads are offered', (tester) async {
    await show(tester);
    await tester.pumpAndSettle();

    expect(find.text('Datensicherung erstellen'), findsOneWidget);
    expect(find.text('Datensicherung teilen'), findsOneWidget);
    expect(find.text('Datensicherung wiederherstellen'), findsOneWidget);
  });

  testWidgets('sharing says the file is encrypted before it leaves', (
    tester,
  ) async {
    await show(tester);
    await tester.pumpAndSettle();

    // The whole reason sending a household backup through somebody
    // else's cloud is defensible, said where the decision is made and
    // not only in the documentation.
    expect(
      find.textContaining('mit deiner Passphrase verschlüsselt'),
      findsOneWidget,
    );
  });

  testWidgets('it reads in English too', (tester) async {
    await show(tester, locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Share the backup'), findsOneWidget);
    expect(
      find.textContaining('encrypted with your passphrase'),
      findsOneWidget,
    );
  });

  testWidgets('is accessible', (tester) async {
    await show(tester);
    await tester.pumpAndSettle();
    await expectAccessible(tester);
  });
}
