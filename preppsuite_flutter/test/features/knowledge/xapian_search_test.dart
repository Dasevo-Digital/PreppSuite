import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_index.dart';
import 'package:preppsuite_flutter/features/knowledge/application/xapian_search.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

/// The isolate around the index, against a real archive.
///
/// Same reason as next door for needing one: a Xapian database is a C++
/// library's on-disk format, and a fixture of it would only prove the
/// fixture was read. Skipped unless `PREPPSUITE_TEST_ZIM` names an
/// archive and `native/zim_xapian` has been built.
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
    'the index on its own isolate',
    () {
      late ZimArchive archive;
      late ZimBlobLocation where;

      setUpAll(() async {
        archive = await ZimArchive.open(
          await FileByteRangeSource.open(File(archivePath!)),
        );
        final entry = await archive.fullTextIndexEntry();
        expect(entry, isNotNull, reason: 'this archive carries no index');
        where = (await archive.directAccessInfo(entry!))!;
      });

      tearDownAll(() => archive.close());

      test('it opens and reports what it holds', () async {
        final searcher = await XapianSearcher.open(archivePath!, where);
        addTearDown(searcher.close);

        expect(searcher.documentCount, greaterThan(0));
        expect(searcher.language, isNotNull);
      });

      test('a query comes back with hits the archive holds', () async {
        final searcher = await XapianSearcher.open(archivePath!, where);
        addTearDown(searcher.close);

        final found = await searcher.search('Wasser', limit: 5);

        expect(found.hits, isNotEmpty);
        expect(found.estimate, greaterThan(0));
        for (final hit in found.hits) {
          expect(
            await archive.findByUrl(hit.namespace, hit.url),
            isNotNull,
            reason: 'the index pointed at ${hit.namespace}/${hit.url}',
          );
        }
      });

      test('queries sent together are answered, each its own', () async {
        final searcher = await XapianSearcher.open(archivePath!, where);
        addTearDown(searcher.close);

        // One database, one isolate: these queue rather than run at once.
        // What matters is that each caller gets its own answer back and
        // not somebody else's.
        final answers = await Future.wait([
          searcher.search('Wasser', limit: 3),
          searcher.search('Feuer', limit: 3),
          searcher.search('zzzzqqqxyz', limit: 3),
        ]);

        expect(answers[0].hits, isNotEmpty);
        expect(answers[1].hits, isNotEmpty);
        expect(answers[2].hits, isEmpty);
      });

      test('an opened index at the wrong offset fails rather than hangs', () {
        // The failure that would otherwise be silent: a caller waiting on
        // a future that nobody is ever going to complete.
        expect(
          XapianSearcher.open(
            archivePath!,
            const ZimBlobLocation(offset: 0, length: 0),
          ),
          throwsA(isA<XapianException>()),
        );
      });

      test('searching a closed index fails rather than hangs', () async {
        final searcher = await XapianSearcher.open(archivePath!, where);
        await searcher.close();

        expect(
          searcher.search('Wasser'),
          throwsA(isA<XapianException>()),
        );
      });
    },
    skip: reason,
  );
}
