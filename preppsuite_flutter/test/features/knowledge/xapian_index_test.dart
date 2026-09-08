import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

import 'archive_words.dart';

/// Runs against a real Kiwix archive, because nothing else can.
///
/// The fixture writer next door can produce a ZIM, but not a Xapian
/// database — that is a C++ library's own on-disk format, and faking it
/// would only prove that the fake was read. So this is skipped unless
/// `PREPPSUITE_TEST_ZIM` names an archive, and the native library from
/// `native/zim_xapian` has been built.
void main() {
  final archivePath = Platform.environment['PREPPSUITE_TEST_ZIM'];
  final reason = archivePath == null
      ? 'set PREPPSUITE_TEST_ZIM to a Kiwix archive to run this'
      : !File(archivePath).existsSync()
      ? 'PREPPSUITE_TEST_ZIM names no file'
      : !xapianAvailable
      ? 'run native/zim_xapian/build_macos.sh first'
      : null;

  group(
    'searching a real archive own index',
    () {
      late ZimArchive archive;
      late XapianIndex index;

      /// Words this archive really contains, rather than words the person
      /// writing the test happened to know.
      late List<String> words;

      setUpAll(() async {
        archive = await ZimArchive.open(
          await FileByteRangeSource.open(File(archivePath!)),
        );
        final entry = await archive.fullTextIndexEntry();
        expect(entry, isNotNull, reason: 'this archive carries no index');

        final location = await archive.directAccessInfo(entry!);
        expect(
          location,
          isNotNull,
          reason: 'the index cluster is compressed, so it cannot be opened',
        );

        index = XapianIndex.openFile(archivePath, location!);
        expect(index.problem, isNull);

        words = await wordsInIndex(
          archive,
          matches: (word) async => index.search(word, limit: 1).isNotEmpty,
        );
        expect(
          words,
          isNotEmpty,
          reason: 'the index answered nothing about any of its own titles',
        );
      });

      tearDownAll(() async {
        index.close();
        await archive.close();
      });

      test('the index opens where the archive says it lies', () {
        expect(index.documentCount, greaterThan(0));
      });

      test('a word in an article body finds that article', () {
        final hits = index.search(words.first, limit: 5);

        expect(hits, isNotEmpty);
        expect(index.estimatedMatches, greaterThan(0));
      });

      test('every hit names an entry the archive actually holds', () async {
        for (final hit in index.search(words.last, limit: 5)) {
          final entry = await archive.findByUrl(hit.namespace, hit.url);
          expect(
            entry,
            isNotNull,
            reason: 'the index pointed at ${hit.namespace}/${hit.url}',
          );
        }
      });

      test('a query is stemmed in the archive own language', () {
        // The whole reason for going through Xapian rather than the FTS5
        // index the app builds itself: that one matches by prefix, so a
        // plural finds the singular only by accident of spelling.
        expect(index.language, isNotNull);

        // The pair below is German, so this one test is the exception to
        // taking the query out of the archive: an inflected form and its
        // stem cannot be picked at random, they have to be a real pair in
        // a language somebody knows.
        if (!(index.language ?? '').startsWith('de')) {
          markTestSkipped('this archive is not German (${index.language})');
          return;
        }

        final singular = index.search('Element', limit: 20);
        final plural = index.search('Elemente', limit: 20);

        expect(singular, isNotEmpty);
        expect(plural, isNotEmpty);
        expect(
          plural.map((hit) => hit.url).toSet(),
          containsAll(singular.take(3).map((hit) => hit.url)),
        );
      });

      test('a word in no article comes back empty rather than failing', () {
        expect(index.search('zzzzqqqxyz'), isEmpty);
      });
    },
    skip: reason,
  );
}
