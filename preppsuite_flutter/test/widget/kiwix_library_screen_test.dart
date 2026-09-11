import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/kiwix_catalogue.dart';
import 'package:preppsuite_flutter/features/knowledge/presentation/kiwix_library_screen.dart';
import 'package:preppsuite_flutter/l10n/generated/app_localizations.dart';

import '../features/fixture_http_client.dart';

import 'accessibility.dart';

/// The download screen against a captured catalogue, because what it puts
/// in front of somebody — the size above all — is what decides whether
/// they start a download their device cannot hold.
void main() {
  final entriesXml = File(
    'test/fixtures/kiwix_entries_de.xml',
  ).readAsStringSync();
  final languagesXml = File(
    'test/fixtures/kiwix_languages.xml',
  ).readAsStringSync();

  Future<void> show(WidgetTester tester, {KiwixCatalogue? catalogue}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (catalogue != null)
            kiwixCatalogueProvider.overrideWithValue(catalogue),
        ],
        child: const MaterialApp(
          locale: Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: KiwixLibraryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows what an archive costs before it is started', (
    tester,
  ) async {
    await show(
      tester,
      catalogue: KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries'
                  '?lang=deu&start=0&count=25':
              entriesXml,
        }),
      ),
    );

    expect(find.text('Kiwix-Bibliothek'), findsWidgets);
    expect(find.text('Wikipedia'), findsWidgets);

    // 52,392,226,816 bytes, complete, with its article count — the three
    // numbers that decide whether this fits on the device.
    expect(find.textContaining('52 GB'), findsOneWidget);
    expect(find.textContaining('vollständig'), findsOneWidget);
    expect(find.textContaining('5041970 Artikel'), findsOneWidget);
  });

  testWidgets('an unreachable library is said so, not left spinning', (
    tester,
  ) async {
    // No response for any URL, which is what a device with no connection
    // amounts to.
    await show(
      tester,
      catalogue: KiwixCatalogue(httpClient: FixtureHttpClient(const {})),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.textContaining('Die Bibliothek war nicht erreichbar'),
      findsOneWidget,
    );
  });

  testWidgets('the Kiwix library meets the accessibility guidelines', (
    tester,
  ) async {
    await show(
      tester,
      catalogue: KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries'
                  '?lang=deu&start=0&count=25':
              entriesXml,
        }),
      ),
    );
    await expectAccessible(tester);
  });

  testWidgets('the Kiwix library survives twice the font size', (
    tester,
  ) async {
    useLargeText(tester);
    await show(
      tester,
      catalogue: KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries'
                  '?lang=deu&start=0&count=25':
              entriesXml,
        }),
      ),
    );
  });

  group('picking a language', () {
    // The live catalogue offers 337 of them. A dropdown that long is
    // scrolled past rather than read — on a phone it is several screens
    // of names in their own scripts — so typing two letters is the only
    // way anybody finds theirs.
    Future<void> showWithLanguages(WidgetTester tester) async {
      await show(
        tester,
        catalogue: KiwixCatalogue(
          httpClient: FixtureHttpClient({
            'https://library.kiwix.org/catalog/v2/entries'
                    '?lang=deu&start=0&count=25':
                entriesXml,
            'https://library.kiwix.org/catalog/v2/languages': languagesXml,
          }),
        ),
      );
    }

    testWidgets('the field names the language and how many there are', (
      tester,
    ) async {
      await showWithLanguages(tester);

      expect(find.textContaining('Deutsch'), findsWidgets);
      expect(find.textContaining('3 Sprachen'), findsOneWidget);
    });

    testWidgets('the list opens and can be searched', (tester) async {
      await showWithLanguages(tester);

      await tester.tap(find.textContaining('Deutsch (306)'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('français'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, 'eng');
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('français'), findsNothing);
    });

    testWidgets('a code matches as well as a name', (tester) async {
      // Both are things people type: "fra" is what the catalogue calls it
      // and what a suggestion names, "français" is what somebody reads.
      await showWithLanguages(tester);

      await tester.tap(find.textContaining('Deutsch (306)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'fra');
      await tester.pumpAndSettle();

      expect(find.text('français'), findsOneWidget);
      expect(find.text('English'), findsNothing);
    });

    testWidgets('a search matching nothing says so', (tester) async {
      await showWithLanguages(tester);

      await tester.tap(find.textContaining('Deutsch (306)'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'klingon');
      await tester.pumpAndSettle();

      expect(find.text('Keine Sprache gefunden.'), findsOneWidget);
    });

    testWidgets('picking one reloads the list in that language', (
      tester,
    ) async {
      await show(
        tester,
        catalogue: KiwixCatalogue(
          httpClient: FixtureHttpClient({
            'https://library.kiwix.org/catalog/v2/entries'
                    '?lang=deu&start=0&count=25':
                entriesXml,
            'https://library.kiwix.org/catalog/v2/entries'
                    '?lang=eng&start=0&count=25':
                entriesXml,
            'https://library.kiwix.org/catalog/v2/languages': languagesXml,
          }),
        ),
      );

      await tester.tap(find.textContaining('Deutsch (306)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();

      expect(find.textContaining('English (1298)'), findsOneWidget);
    });
  });
}
