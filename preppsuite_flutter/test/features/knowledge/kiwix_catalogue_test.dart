import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/kiwix_catalogue.dart';

import '../fixture_http_client.dart';

void main() {
  final entriesXml = File(
    'test/fixtures/kiwix_entries_de.xml',
  ).readAsStringSync();
  final languagesXml = File(
    'test/fixtures/kiwix_languages.xml',
  ).readAsStringSync();

  group('entries', () {
    test('reads what the download screen shows', () async {
      final requested = <String>[];
      final catalogue = KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries'
                  '?lang=deu&q=wikipedia&start=0&count=3':
              entriesXml,
        }, onRequest: requested.add),
      );

      final page = await catalogue.entries(
        language: 'deu',
        query: 'wikipedia',
        count: 3,
      );

      expect(page.total, 38);
      expect(page.entries, hasLength(3));

      final first = page.entries.first;
      expect(first.title, 'Wikipedia');
      expect(first.name, 'wikipedia_de_all');
      expect(first.flavour, 'maxi');
      expect(first.language, 'deu');
      expect(first.size, 52392226816);
      expect(first.articleCount, 5041970);
      expect(first.hasFullTextIndex, isTrue);
      expect(requested, hasLength(1));
    });

    // The catalogue links a Metalink, not the archive. Downloading the
    // .meta4 would fetch a page of checksums and call it Wikipedia.
    test('points at the archive, not at its Metalink', () async {
      final catalogue = KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries?start=0&count=3':
              entriesXml,
        }),
      );

      final page = await catalogue.entries(count: 3);
      final first = page.entries.first;

      expect(
        first.downloadUrl.toString(),
        'https://lb.download.kiwix.org/zim/wikipedia/'
        'wikipedia_de_all_maxi_2026-01.zim',
      );
      expect(first.fileName, 'wikipedia_de_all_maxi_2026-01.zim');
    });

    // Every entry carries <author><name> and <publisher><name> as well as
    // its own <name>; a search through the whole subtree finds "Wikipedia"
    // where "wikipedia_de_all" belongs.
    test('takes the entry name, not the author name', () async {
      final catalogue = KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/entries?start=0&count=3':
              entriesXml,
        }),
      );

      final page = await catalogue.entries(count: 3);
      for (final entry in page.entries) {
        expect(entry.name, startsWith('wikipedia_de'));
      }
    });

    test('an unreachable library is an error, not an empty list', () {
      final catalogue = KiwixCatalogue(httpClient: FixtureHttpClient(const {}));
      expect(
        catalogue.entries(language: 'deu'),
        throwsA(isA<KiwixCatalogueException>()),
      );
    });
  });

  group('languages', () {
    test('reads the code, the native name and the stock', () async {
      final catalogue = KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/languages': languagesXml,
        }),
      );

      final languages = await catalogue.languages();

      // Sorted by how much there is, so the crowded languages come first.
      expect(languages.first.code, 'eng');
      expect(languages.first.archiveCount, 1298);

      final german = languages.firstWhere((l) => l.code == 'deu');
      expect(german.name, 'Deutsch');
      expect(german.archiveCount, 306);
    });

    test('a name is read as UTF-8, whatever the header says', () async {
      // `response.body` decodes as Latin-1 when the header names no
      // charset, and every name in this list is in its own language.
      // The comment saying to use bodyBytes had been in the client
      // longer than the code doing it: "français" came out as
      // "franÃ§ais". The live server does send `charset=utf-8`, which is
      // why it never showed — and a mirror that does not would mangle
      // the whole library.
      final catalogue = KiwixCatalogue(
        httpClient: FixtureHttpClient({
          'https://library.kiwix.org/catalog/v2/languages': languagesXml,
        }),
      );

      final languages = await catalogue.languages();

      expect(
        languages.firstWhere((l) => l.code == 'fra').name,
        'français',
      );
    });
  });
}
