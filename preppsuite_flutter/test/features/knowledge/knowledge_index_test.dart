import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_index_database.dart';
import 'package:preppsuite_flutter/features/knowledge/application/knowledge_indexer.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

import 'zim_fixture.dart';

void main() {
  late Directory workspace;
  late KnowledgeIndexDatabase index;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('preppsuite-fts');
    index = KnowledgeIndexDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await index.close();
    workspace.deleteSync(recursive: true);
  });

  ZimFixtureEntry article(String title, String html, {String? url}) {
    return ZimFixtureEntry(
      namespace: 'C',
      url: url ?? title,
      title: title,
      content: utf8.encode(html),
    );
  }

  Future<ZimArchive> archiveWith(List<ZimFixtureEntry> entries) async {
    final path = writeZim(workspace, ZimFixture(entries: entries));
    final archive = await ZimArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    addTearDown(archive.close);
    return archive;
  }

  Future<List<ZimEntry>> hits(ZimArchive archive, String query) async {
    return [
      for (final entryIndex in await index.search(query))
        await archive.entryAt(entryIndex),
    ];
  }

  group('the query expression', () {
    test('every term is quoted so nothing is read as syntax', () {
      // Bare input is a query language: "AND", "NEAR" and a stray quote
      // would either throw or silently mean something else.
      expect(fts5QueryFor('wasser AND brot'), '"wasser" "AND" "brot"*');
      expect(fts5QueryFor('he said "no"'), '"he" "said" "no"*');
    });

    test('the last term is a prefix, because people are still typing it', () {
      expect(fts5QueryFor('trinkw'), '"trinkw"*');
    });

    test('input with no letters or digits asks for nothing', () {
      expect(fts5QueryFor('   '), isNull);
      expect(fts5QueryFor('-- ""'), isNull);
    });
  });

  group('indexing an archive', () {
    test('a word in the body finds the article that contains it', () async {
      // The whole point: the title index would never find this.
      final archive = await archiveWith([
        article('Notvorrat', '<p>Zwei Liter Trinkwasser pro Person.</p>'),
        article('Zivilschutz', '<p>Sirenen und Warnungen.</p>'),
      ]);

      final indexer = KnowledgeIndexer(archive: archive, index: index);
      await indexer.run(await indexer.plan(), fingerprint: 'test');

      expect(
        (await hits(archive, 'Trinkwasser')).map((e) => e.title),
        ['Notvorrat'],
      );
      expect(
        (await hits(archive, 'Sirenen')).map((e) => e.title),
        ['Zivilschutz'],
      );
    });

    test('markup is not indexed as words', () async {
      final archive = await archiveWith([
        article('Notvorrat', '<p class="lead">Wasser</p>'),
      ]);

      final indexer = KnowledgeIndexer(archive: archive, index: index);
      await indexer.run(await indexer.plan(), fingerprint: 'test');

      expect(await hits(archive, 'Wasser'), hasLength(1));
      expect(await hits(archive, 'class'), isEmpty);
      expect(await hits(archive, 'lead'), isEmpty);
    });

    test('umlauts are found without them', () async {
      // German search without this is unusable on a phone keyboard.
      final archive = await archiveWith([
        article('Vorrat', '<p>Notvorräte anlegen.</p>'),
      ]);

      final indexer = KnowledgeIndexer(archive: archive, index: index);
      await indexer.run(await indexer.plan(), fingerprint: 'test');

      expect(await hits(archive, 'Notvorrate'), hasLength(1));
      expect(await hits(archive, 'Notvorräte'), hasLength(1));
    });

    test('a half-typed word still finds the article', () async {
      final archive = await archiveWith([
        article('Notvorrat', '<p>Trinkwasser bevorraten.</p>'),
      ]);

      final indexer = KnowledgeIndexer(archive: archive, index: index);
      await indexer.run(await indexer.plan(), fingerprint: 'test');

      expect(await hits(archive, 'trinkw'), hasLength(1));
    });

    test('redirects and metadata are not indexed', () async {
      final archive = await archiveWith([
        article('Notvorrat', '<p>Wasser.</p>'),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Wasservorrat',
          title: 'Wasservorrat',
          redirectTo: 'C/Notvorrat',
        ),
        ZimFixtureEntry(
          namespace: 'M',
          url: 'Title',
          content: utf8.encode('Wasser Sammlung'),
        ),
      ]);

      final indexer = KnowledgeIndexer(archive: archive, index: index);
      final plan = await indexer.plan();
      await indexer.run(plan, fingerprint: 'test');

      expect(plan.articleCount, 1);
      expect((await hits(archive, 'Wasser')).single.title, 'Notvorrat');
    });

    test('articles are read in cluster order, not url order', () async {
      // Reading in url order would decompress the same cluster again for
      // every article inside it. The fixture writes one cluster, so what
      // is checked is the ordering itself.
      final archive = await archiveWith([
        article('Zebra', '<p>z</p>'),
        article('Anton', '<p>a</p>'),
        article('Muster', '<p>m</p>'),
      ]);

      final plan = await KnowledgeIndexer(
        archive: archive,
        index: index,
      ).plan();

      final clusters = <int>[];
      final blobs = <int>[];
      for (final entryIndex in plan.entryIndexes) {
        final entry = await archive.entryAt(entryIndex);
        clusters.add(entry.clusterNumber!);
        blobs.add(entry.blobNumber!);
      }

      expect(clusters, [0, 0, 0]);
      expect(blobs, [...blobs]..sort());
    });
  });

  group('resuming and discarding', () {
    test('an interrupted run picks up where it stopped', () async {
      final archive = await archiveWith([
        for (var i = 0; i < 6; i++)
          article('Artikel$i', '<p>Begriff$i</p>', url: 'Artikel$i'),
      ]);
      final indexer = KnowledgeIndexer(archive: archive, index: index);
      final plan = await indexer.plan();

      var seen = 0;
      final finished = await indexer.run(
        plan,
        fingerprint: 'test',
        cancelled: () => seen++ >= 3,
      );

      expect(finished, isFalse);
      expect(await index.isComplete(), isFalse);
      expect(await index.progress(), lessThan(plan.articleCount));

      expect(await indexer.run(plan, fingerprint: 'test'), isTrue);
      expect(await index.isComplete(), isTrue);
      for (var i = 0; i < 6; i++) {
        expect(await hits(archive, 'Begriff$i'), hasLength(1), reason: '$i');
      }
    });

    test(
      'an index built from another archive is thrown away, not reused',
      () async {
        // Entry numbers from a different file point at the wrong articles,
        // which is worse than having no index at all.
        final archive = await archiveWith([
          article('Notvorrat', '<p>Wasser.</p>'),
        ]);
        final indexer = KnowledgeIndexer(archive: archive, index: index);
        await indexer.run(await indexer.plan(), fingerprint: 'older-archive');

        await indexer.run(await indexer.plan(), fingerprint: 'this-archive');

        expect(await index.indexedArchive(), 'this-archive');
        expect(await hits(archive, 'Wasser'), hasLength(1));
      },
    );

    test('discarding leaves an empty, usable index behind', () async {
      final archive = await archiveWith([
        article('Notvorrat', '<p>Wasser.</p>'),
      ]);
      final indexer = KnowledgeIndexer(archive: archive, index: index);
      await indexer.run(await indexer.plan(), fingerprint: 'test');

      await index.discard();

      expect(await index.indexedArchive(), isNull);
      expect(await index.search('Wasser'), isEmpty);
    });
  });
}
