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

  group('pointing another reader at a blob', () {
    // Xapian opens the archive's search index from a file offset, so the
    // reader has to be able to say where a blob physically is — not just
    // hand over its bytes.

    ZimFixture withIndex({
      required String namespace,
      required String url,
      int compression = 1,
    }) {
      return ZimFixture(
        compression: compression,
        entries: [
          const ZimFixtureEntry(
            namespace: 'C',
            url: 'Trinkwasser',
            title: 'Trinkwasser',
            content: [60, 104, 49, 62],
          ),
          ZimFixtureEntry(
            namespace: namespace,
            url: url,
            content: utf8.encode('not really a Xapian database'),
          ),
        ],
      );
    }

    test('an uncompressed blob is found at the offset it names', () async {
      final path = writeZim(
        workspace,
        withIndex(namespace: 'X', url: 'fulltext/xapian'),
      );
      final archive = await ZimArchive.open(
        await FileByteRangeSource.open(File(path)),
      );
      addTearDown(archive.close);

      final entry = (await archive.fullTextIndexEntry())!;
      final location = (await archive.directAccessInfo(entry))!;

      // Read the file directly at that position: if the arithmetic is off
      // by a byte, Xapian would be handed the wrong bytes and simply say
      // the database is corrupt.
      final raw = File(path).openSync();
      addTearDown(raw.closeSync);
      raw.setPositionSync(location.offset);

      expect(raw.readSync(location.length), await archive.readBlob(entry));
    });

    test('a compressed blob has no place to point at', () async {
      // The bytes only exist after decompression, so there is no offset
      // to give. Kiwix writes the index uncompressed for this reason, but
      // an archive built by hand need not have.
      final archive = await openFixture(
        withIndex(namespace: 'X', url: 'fulltext/xapian', compression: 4),
      );

      expect(
        await archive.directAccessInfo((await archive.fullTextIndexEntry())!),
        isNull,
      );
    });

    test('the index is found under the name older archives used', () async {
      final archive = await openFixture(
        withIndex(namespace: 'Z', url: '/fulltextIndex/xapian'),
      );

      expect((await archive.fullTextIndexEntry())?.namespace, 'Z');
    });

    test('an archive built without indexing says it has none', () async {
      // `zimwriterfs` will happily produce one, and the app has to fall
      // back to its own index rather than fail.
      final archive = await openFixture(wikipediaish());

      expect(await archive.fullTextIndexEntry(), isNull);
    });

    test('a redirect is not mistaken for content', () async {
      final archive = await openFixture(wikipediaish());
      final redirect = (await archive.findByUrl('C', 'Wasservorrat'))!;

      expect(redirect.isRedirect, isTrue);
      expect(await archive.directAccessInfo(redirect), isNull);
    });
  });
}
