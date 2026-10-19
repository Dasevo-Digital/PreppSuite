import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/knowledge/application/zim_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart'
    show FileByteRangeSource;

import 'zim_fixture.dart';

void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('preppsuite-zim');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  Future<ZimArchive> openFixture(ZimFixture fixture) async {
    final path = writeZim(workspace, fixture);
    final archive = await ZimArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    addTearDown(archive.close);
    return archive;
  }

  ZimFixture wikipediaish({int majorVersion = 6, int compression = 1}) {
    return ZimFixture(
      majorVersion: majorVersion,
      compression: compression,
      entries: [
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Trinkwasser',
          title: 'Trinkwasser',
          content: [60, 104, 49, 62], // "<h1>"
        ),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Trinkwasseraufbereitung',
          title: 'Trinkwasseraufbereitung',
          content: [65],
        ),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Zivilschutz',
          title: 'Zivilschutz',
          content: [66],
        ),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Notvorrat',
          title: 'Notvorrat',
          content: [67],
        ),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Wasservorrat',
          redirectTo: 'C/Notvorrat',
          title: 'Wasservorrat',
        ),
        ZimFixtureEntry(
          namespace: 'M',
          url: 'Title',
          content: utf8.encode('Wikipedia (Auswahl)'),
        ),
      ],
    );
  }

  group('the header', () {
    test('is read back as it was written', () async {
      final archive = await openFixture(wikipediaish());

      expect(archive.header.majorVersion, 6);
      expect(archive.header.clusterCount, 1);
      expect(archive.header.entryCount, greaterThan(5));
    });

    test('a file that is not an archive is refused by name', () async {
      final path = '${workspace.path}/notes.txt';
      File(path).writeAsStringSync('this is not an archive');

      expect(
        () async => ZimArchive.open(await FileByteRangeSource.open(File(path))),
        throwsA(isA<ZimException>()),
      );
    });

    test('a version this reader does not know is refused', () async {
      final bytes = wikipediaish().build();
      bytes[4] = 7;
      final path = '${workspace.path}/future.zim';
      File(path).writeAsBytesSync(bytes);

      expect(
        () async => ZimArchive.open(await FileByteRangeSource.open(File(path))),
        throwsA(isA<ZimException>()),
      );
    });
  });

  group('finding entries', () {
    test('an article is found by its namespace and url', () async {
      final archive = await openFixture(wikipediaish());

      final entry = await archive.findByUrl('C', 'Zivilschutz');

      expect(entry, isNotNull);
      expect(entry!.title, 'Zivilschutz');
      expect(entry.isRedirect, isFalse);
    });

    test('a url the archive does not hold comes back null', () async {
      final archive = await openFixture(wikipediaish());

      expect(await archive.findByUrl('C', 'Rechenschieber'), isNull);
    });

    test('the same url in another namespace is a different entry', () async {
      // Namespace sorts before url in the index; getting that order wrong
      // finds neighbouring entries rather than the right one.
      final archive = await openFixture(wikipediaish());

      expect(await archive.findByUrl('M', 'Title'), isNotNull);
      expect(await archive.findByUrl('C', 'Title'), isNull);
    });

    test('a redirect is followed to the entry it points at', () async {
      final archive = await openFixture(wikipediaish());

      final redirect = await archive.findByUrl('C', 'Wasservorrat');
      expect(redirect!.isRedirect, isTrue);

      final target = await archive.resolve(redirect);
      expect(target!.url, 'Notvorrat');
      expect(target.isRedirect, isFalse);
    });
  });

  group('reading content', () {
    test('an article comes back byte for byte', () async {
      final archive = await openFixture(wikipediaish());

      final entry = await archive.findByUrl('C', 'Trinkwasser');

      expect(await archive.readBlob(entry!), [60, 104, 49, 62]);
    });

    test('every blob in a cluster is found at its own offset', () async {
      // One wrong offset would still return plausible-looking bytes — the
      // neighbouring article — so each is checked against what it holds.
      final archive = await openFixture(wikipediaish());

      for (final (url, byte) in [
        ('Trinkwasseraufbereitung', 65),
        ('Zivilschutz', 66),
        ('Notvorrat', 67),
      ]) {
        final entry = await archive.findByUrl('C', url);
        expect(await archive.readBlob(entry!), [byte], reason: url);
      }
    });

    test(
      'an xz-compressed cluster reads the same as an uncompressed one',
      () async {
        // What Kiwix wrote until 2020, and what every older download still
        // is.
        final archive = await openFixture(wikipediaish(compression: 4));

        final entry = await archive.findByUrl('C', 'Zivilschutz');
        expect(await archive.readBlob(entry!), [66]);
      },
    );

    test('metadata is read as text', () async {
      final archive = await openFixture(wikipediaish());

      expect(await archive.metadata('Title'), 'Wikipedia (Auswahl)');
      expect(await archive.metadata('Publisher'), isNull);
    });

    test('the mime type comes from the archive own list', () async {
      final archive = await openFixture(wikipediaish());

      final entry = await archive.findByUrl('C', 'Trinkwasser');
      expect(archive.mimeTypeOf(entry!), 'text/html');
    });
  });

  group('searching by title', () {
    test('a prefix finds every article that starts with it', () async {
      final archive = await openFixture(wikipediaish());

      final matches = await archive.searchTitles('Trinkwasser');

      expect(
        matches.map((e) => e.title),
        ['Trinkwasser', 'Trinkwasseraufbereitung'],
      );
    });

    test('a lowercase query still finds a capitalized title', () async {
      // Titles are sorted by bytes and Wikipedia's start with a capital,
      // so a literal search for "zivilschutz" would land past every match.
      final archive = await openFixture(wikipediaish());

      expect(
        (await archive.searchTitles('zivilschutz')).single.title,
        'Zivilschutz',
      );
    });

    test('a prefix nothing starts with finds nothing', () async {
      final archive = await openFixture(wikipediaish());

      expect(await archive.searchTitles('Rechenschieber'), isEmpty);
    });

    test('metadata and index entries never turn up as results', () async {
      // They are entries like any other and sit in the same tables.
      final archive = await openFixture(wikipediaish());

      final matches = await archive.searchTitles('l');
      expect(matches, isEmpty);
    });

    test('the older format finds titles through the header table', () async {
      // Version 5 keeps the title order in the header rather than in an
      // entry; every archive from before 2020 is one of these.
      final archive = await openFixture(wikipediaish(majorVersion: 5));

      expect(
        (await archive.searchTitles('Notvorrat')).single.url,
        'Notvorrat',
      );
    });

    test('an empty query asks for nothing rather than everything', () async {
      final archive = await openFixture(wikipediaish());

      expect(await archive.searchTitles(''), isEmpty);
    });
  });

  group('walking the directory in blocks', () {
    // Long enough titles that the directory spans several of the reader's
    // 64 KiB windows, so moving the window is part of what is tested.
    ZimFixture many({bool reverseDirectory = false}) => ZimFixture(
      reverseDirectory: reverseDirectory,
      entries: [
        for (var i = 0; i < 1500; i++)
          ZimFixtureEntry(
            namespace: 'C',
            url: 'Artikel${i.toString().padLeft(4, '0')}',
            title: 'Ein recht langer Titel, Nummer $i ${'x' * (i % 90)}',
            content: [i % 256],
          ),
        const ZimFixtureEntry(
          namespace: 'C',
          url: 'Weiterleitung',
          redirectTo: 'C/Artikel0001',
        ),
      ],
    );

    String describe(ZimEntry e) =>
        '${e.index} ${e.namespace}/${e.url} "${e.title}" '
        'mime=${e.mimeTypeIndex} redirect=${e.redirectIndex} '
        'at=${e.clusterNumber}/${e.blobNumber}';

    Future<void> expectSameAsOneByOne(ZimArchive archive) async {
      final total = archive.header.entryCount;
      final blocks = <ZimEntry>[
        for (var at = 0; at < total; at += 700)
          ...await archive.entriesAt(at, 700),
      ];
      final single = [for (var i = 0; i < total; i++) await archive.entryAt(i)];
      expect(blocks.map(describe), single.map(describe));
    }

    test('gives exactly what reading entry by entry gives', () async {
      await expectSameAsOneByOne(await openFixture(many()));
    });

    test('does not depend on entries lying in pointer order', () async {
      await expectSameAsOneByOne(
        await openFixture(many(reverseDirectory: true)),
      );
    });

    test('stops at the end of the directory', () async {
      final archive = await openFixture(many());
      final total = archive.header.entryCount;

      expect(await archive.entriesAt(total - 2, 10), hasLength(2));
      expect(await archive.entriesAt(total, 10), isEmpty);
    });
  });
}
