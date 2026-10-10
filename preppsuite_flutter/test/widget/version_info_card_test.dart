import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preppsuite_flutter/features/settings/presentation/version_info_card.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

void main() {
  Future<void> pumpCard(WidgetTester tester, {double width = 800}) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: VersionInfoCard(
                packageInfo: Future.value(
                  PackageInfo(
                    appName: 'PreppSuite',
                    packageName: 'de.dasevo.preppsuite',
                    version: '1.2.3',
                    buildNumber: '18',
                    buildSignature: '',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('shows the app build and every local schema version', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('1.2.3 · Build 18'), findsOneWidget);
    expect(find.text('Haushaltsdatenbank'), findsOneWidget);
    expect(find.text('Wissensarchiv-Volltextindex'), findsOneWidget);
    expect(find.text('Dokument-Volltextindex'), findsOneWidget);
    // Deliberately the literal and not AppDatabase.currentSchemaVersion:
    // a migration that bumps the schema should make this test say so, and
    // reading the constant back would only prove the card can print it.
    expect(find.text('Schema 25'), findsOneWidget);
    expect(find.text('Schema 1'), findsNWidgets(2));
    expect(find.text('PMTiles v3'), findsOneWidget);
  });

  group('a name and its value', () {
    // Anordnung statt Pixel: die Testumgebung vermisst Text mit ihrer
    // eigenen, deutlich breiteren Schrift, also sagt eine Zeilenzahl aus
    // einem Widget-Test nichts ueber Roboto auf einem Telefon. Was
    // unabhaengig von der Schrift gilt, ist die Entscheidung selbst —
    // sie wird gemessen, und gemessen wird in derselben Schrift, in der
    // danach gezeichnet wird.
    const longName = 'Erste-Hilfe-Inhalte';
    const longValue = 'Quellenstand ERC 2025 (GRC-Fassung)';
    const shortName = 'Offline-Kartenformat';
    const shortValue = 'PMTiles v3';

    testWidgets('stand side by side where both fit', (tester) async {
      await pumpCard(tester, width: 800);

      final name = find.text(shortName);
      final value = find.text(shortValue);
      expect(
        tester.getTopLeft(value).dx,
        greaterThan(tester.getBottomRight(name).dx),
        reason: 'the value belongs to the right of the name',
      );
      expect(
        tester.getTopLeft(value).dy,
        lessThan(tester.getBottomRight(name).dy),
        reason: 'and on the same line, not under it',
      );
    });

    testWidgets('and stack where they do not', (tester) async {
      // The pair that broke, at 390 logical pixels. A ListTile answered
      // this by giving the value all the width it asked for and squeezing
      // the name into the remainder, where it came apart at every hyphen.
      await pumpCard(tester, width: 390);

      final name = find.text(longName);
      final value = find.text(longValue);
      expect(
        tester.getTopLeft(value).dy,
        greaterThanOrEqualTo(tester.getBottomRight(name).dy),
        reason: 'the value should sit below the name, not beside it',
      );
      expect(
        tester.getTopLeft(value).dx,
        tester.getTopLeft(name).dx,
        reason: 'and start at the same edge',
      );
      expect(
        tester.getSize(name).width,
        tester.getSize(value).width,
        reason: 'neither takes width from the other',
      );
      expect(tester.takeException(), isNull);
    });
  });
}
