import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preppsuite_flutter/features/settings/presentation/version_info_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('shows the app build and every local schema version', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: VersionInfoCard(
            packageInfo: Future.value(
              PackageInfo(
                appName: 'PreppSuite',
                packageName: 'de.status403.preppsuite',
                version: '1.2.3',
                buildNumber: '18',
                buildSignature: '',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1.2.3 · Build 18'), findsOneWidget);
    expect(find.text('Haushaltsdatenbank'), findsOneWidget);
    expect(find.text('Wissensarchiv-Volltextindex'), findsOneWidget);
    expect(find.text('Dokument-Volltextindex'), findsOneWidget);
    // Deliberately the literal and not AppDatabase.currentSchemaVersion:
    // a migration that bumps the schema should make this test say so, and
    // reading the constant back would only prove the card can print it.
    expect(find.text('Schema 13'), findsOneWidget);
    expect(find.text('Schema 1'), findsNWidgets(2));
    expect(find.text('PMTiles v3'), findsOneWidget);
  });
}
