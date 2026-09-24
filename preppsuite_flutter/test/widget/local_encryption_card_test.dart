import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/features/settings/presentation/local_encryption_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

Widget _card({
  required LocalDatabaseEncryptionMode mode,
  required List<String> pending,
  DateTime? backupVerifiedAt,
}) => ProviderScope(
  overrides: [
    localEncryptionStatusProvider.overrideWith(
      (ref) async => (
        mode: mode,
        pending: pending,
        backupVerifiedAt: backupVerifiedAt,
      ),
    ),
  ],
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: LocalEncryptionCard(
          householdId: 'h',
          l10n: AppLocalizations.of(context)!,
        ),
      ),
    ),
  ),
);

ListTile _startTile(WidgetTester tester) => tester.widget<ListTile>(
  find.ancestor(
    of: find.text('Lokale Daten jetzt verschlüsseln'),
    matching: find.byType(ListTile),
  ),
);

void main() {
  testWidgets('will not start before a backup has been read back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        mode: LocalDatabaseEncryptionMode.plaintext,
        pending: const ['preppsuite'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nicht verschlüsselt'), findsOneWidget);
    expect(_startTile(tester).enabled, isFalse);
  });

  testWidgets('starts once a backup was tested just now', (tester) async {
    await tester.pumpWidget(
      _card(
        mode: LocalDatabaseEncryptionMode.plaintext,
        pending: const ['preppsuite'],
        backupVerifiedAt: DateTime.now().toUtc(),
      ),
    );
    await tester.pumpAndSettle();

    expect(_startTile(tester).enabled, LocalDatabaseEncryption.cipherAvailable);
  });

  testWidgets('a test from last week does not count', (tester) async {
    // The household has moved on since. A backup is a safety net for the
    // data as it is now, and an old one silently is not.
    await tester.pumpWidget(
      _card(
        mode: LocalDatabaseEncryptionMode.plaintext,
        pending: const ['preppsuite'],
        backupVerifiedAt: DateTime.now().toUtc().subtract(
          const Duration(days: 7),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_startTile(tester).enabled, isFalse);
    expect(
      find.text('Die letzte Prüfung ist über einen Tag her.'),
      findsOneWidget,
    );
  });

  testWidgets('says how much is left when a run stopped part way', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        mode: LocalDatabaseEncryptionMode.encrypted,
        pending: const ['preppsuite_personal_documents'],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Noch 1 Datenbanken unverschlüsselt'), findsOneWidget);
  });

  testWidgets('offers nothing to start when everything is encrypted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _card(
        mode: LocalDatabaseEncryptionMode.encrypted,
        pending: const [],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Verschlüsselt'), findsOneWidget);
    expect(find.text('Lokale Daten jetzt verschlüsseln'), findsNothing);
  });
}
