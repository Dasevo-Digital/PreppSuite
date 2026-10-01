import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

import 'pmtiles_fixture.dart';

/// The reader is hand-written, so the archives it is tested against are
/// hand-written too — a small encoder here, rather than a binary fixture
/// nobody can read or amend.
void main() {
  group('tile ids follow the Hilbert curve', () {
    test('zoom 0 is the whole world and the first id', () {
      expect(tileIdFor(0, 0, 0), 0);
    });

    test('zoom 1 winds through its four tiles in curve order', () {
      // The order the specification names: bottom-left, top-left,
      // top-right, bottom-right. Row-by-row would give 1, 2, 3, 4 in a
      // different arrangement, which would read every tile from the wrong
      // place in the file.
      expect(tileIdFor(1, 0, 0), 1);
      expect(tileIdFor(1, 0, 1), 2);
      expect(tileIdFor(1, 1, 1), 3);
      expect(tileIdFor(1, 1, 0), 4);
    });

    test('each zoom starts after every tile of every zoom before it', () {
      expect(tileIdFor(2, 0, 0), 5, reason: '1 + 4 tiles come first');
      expect(tileIdFor(3, 0, 0), 21, reason: '1 + 4 + 16');
    });

    test('a zoom level uses each id exactly once', () {
      const zoom = 4;
      final ids = {
        for (var x = 0; x < 1 << zoom; x++)
          for (var y = 0; y < 1 << zoom; y++) tileIdFor(zoom, x, y),
      };

      expect(ids, hasLength(1 << (zoom * 2)));
      expect(ids.reduce((a, b) => a < b ? a : b), tileIdFor(zoom, 0, 0));
    });
  });

  group('reading an archive', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('preppsuite-pmtiles');
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    Future<PmTilesArchive> archiveOf(Uint8List bytes) async {
      final file = File('${workspace.path}/test.pmtiles')
        ..writeAsBytesSync(bytes);
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(file),
      );
      addTearDown(archive.close);
      return archive;
    }

    test(
      'a tile that unpacks past the limit is refused, not unpacked',
      () async {
        // A few kilobytes of gzip that expand into more than the limit: the
        // shape of a map file meant to end the app when it is panned onto.
        final archive = await archiveOf(
          buildBinaryArchive(
            maxZoom: 0,
            tiles: {(0, 0, 0): Uint8List(PmTilesArchive.maxBytes + 1)},
          ),
        );

        await expectLater(
          archive.tile(0, 0, 0),
          throwsA(isA<PmTilesException>()),
        );
      },
    );

    test('a tile written at a zoom/x/y comes back at the same one', () async {
      final archive = await archiveOf(
        buildArchive(
          maxZoom: 2,
          tiles: {
            (0, 0, 0): 'world',
            (1, 1, 0): 'bottom right',
            (2, 3, 2): 'somewhere',
          },
        ),
      );

      expect(utf8.decode((await archive.tile(0, 0, 0))!), 'world');
      expect(utf8.decode((await archive.tile(1, 1, 0))!), 'bottom right');
      expect(utf8.decode((await archive.tile(2, 3, 2))!), 'somewhere');
    });

    test(
      'a tile the extract does not cover is a miss, not a failure',
      () async {
        // Ordinary as soon as the user pans past the edge of their download.
        final archive = await archiveOf(
          buildArchive(maxZoom: 2, tiles: {(1, 0, 0): 'only this one'}),
        );

        expect(await archive.tile(1, 1, 1), isNull);
        expect(await archive.tile(2, 0, 0), isNull);
      },
    );

    test('zoom levels outside the header are refused without a read', () async {
      final archive = await archiveOf(
        buildArchive(minZoom: 3, maxZoom: 5, tiles: {(3, 0, 0): 'x'}),
      );

      expect(await archive.tile(2, 0, 0), isNull);
      expect(await archive.tile(6, 0, 0), isNull);
    });

    test('an offset of zero means "right after the one before"', () async {
      // How a clustered archive avoids storing most offsets at all; getting
      // it wrong reads every tile but the first from the wrong place.
      final archive = await archiveOf(
        buildArchive(
          maxZoom: 1,
          contiguousOffsets: true,
          tiles: {
            (1, 0, 0): 'first',
            (1, 0, 1): 'second',
            (1, 1, 1): 'third',
          },
        ),
      );

      expect(utf8.decode((await archive.tile(1, 0, 0))!), 'first');
      expect(utf8.decode((await archive.tile(1, 0, 1))!), 'second');
      expect(utf8.decode((await archive.tile(1, 1, 1))!), 'third');
    });

    test('an archive split into leaf directories reads the same', () async {
      // Every archive worth having is split this way — the root directory
      // has to stay small enough to read in one go — so a root-only test
      // would pass while every real download failed.
      final tiles = {
        for (var x = 0; x < 8; x++)
          for (var y = 0; y < 8; y++) (3, x, y): 'tile $x/$y',
      };
      final archive = await archiveOf(
        buildArchive(minZoom: 3, maxZoom: 3, tiles: tiles, leafSize: 7),
      );

      for (final entry in tiles.entries) {
        expect(
          utf8.decode((await archive.tile(3, entry.key.$2, entry.key.$3))!),
          entry.value,
          reason: 'tile ${entry.key}',
        );
      }
      expect(await archive.tile(3, 0, 0), isNotNull);
    });

    test('the header is read back as it was written', () async {
      final archive = await archiveOf(
        buildArchive(
          minZoom: 4,
          maxZoom: 11,
          bounds: (5.8, 47.2, 15.1, 55.1),
          tiles: {(4, 0, 0): 'x'},
        ),
      );

      expect(archive.header.minZoom, 4);
      expect(archive.header.maxZoom, 11);
      expect(archive.header.minLongitude, closeTo(5.8, 1e-6));
      expect(archive.header.maxLatitude, closeTo(55.1, 1e-6));
      expect(archive.header.tileType, PmTilesType.mvt);
    });

    test('metadata comes back decompressed and parsed', () async {
      final archive = await archiveOf(
        buildArchive(
          maxZoom: 1,
          tiles: {(1, 0, 0): 'x'},
          metadata: {
            'vector_layers': [
              {'id': 'water'},
              {'id': 'transportation'},
            ],
          },
        ),
      );

      final layers = (await archive.metadata())['vector_layers'] as List;
      expect(layers.map((l) => (l as Map)['id']), ['water', 'transportation']);
    });

    test('a file that is not an archive is refused by name', () async {
      final file = File('${workspace.path}/nonsense.pmtiles')
        ..writeAsBytesSync(Uint8List(200));

      expect(
        () async => PmTilesArchive.open(await FileByteRangeSource.open(file)),
        throwsA(isA<PmTilesException>()),
      );
    });

    test('a version this reader does not know is refused', () async {
      final bytes = buildArchive(maxZoom: 1, tiles: {(1, 0, 0): 'x'});
      bytes[7] = 4;
      final file = File('${workspace.path}/future.pmtiles')
        ..writeAsBytesSync(bytes);

      expect(
        () async => PmTilesArchive.open(await FileByteRangeSource.open(file)),
        throwsA(isA<PmTilesException>()),
      );
    });
  });

  /// The map renderer asks for a screenful of tiles at once and the
  /// article view for a page's HTML, stylesheet and images together.
  /// Before the source queued its reads, `dart:io` refused every one of
  /// them but the first — the offline map drew a single tile and an
  /// article came up blank.
  group('reads that overlap', () {
    late Directory workspace;

    setUp(() {
      workspace = Directory.systemTemp.createTempSync('preppsuite-parallel');
    });

    tearDown(() => workspace.deleteSync(recursive: true));

    test('the source answers every one of them, and correctly', () async {
      final file = File('${workspace.path}/bytes.bin')
        ..writeAsBytesSync(
          Uint8List.fromList([for (var i = 0; i < 256; i++) i]),
        );
      final source = await FileByteRangeSource.open(file);
      addTearDown(source.close);

      final reads = await Future.wait([
        for (var offset = 0; offset < 256; offset += 16) source.read(offset, 4),
      ]);

      // Each read starts where the byte equals the offset, so a read that
      // was served from another one's position is visible in the value.
      for (var i = 0; i < reads.length; i++) {
        expect(reads[i], [i * 16, i * 16 + 1, i * 16 + 2, i * 16 + 3]);
      }
    });

    test('a whole screenful of tiles comes back', () async {
      final tiles = {
        for (var x = 0; x < 8; x++)
          for (var y = 0; y < 8; y++) (3, x, y): 'tile $x/$y',
      };
      final file = File('${workspace.path}/many.pmtiles')
        ..writeAsBytesSync(buildArchive(minZoom: 3, maxZoom: 3, tiles: tiles));
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(file),
      );
      addTearDown(archive.close);

      final fetched = await Future.wait([
        for (final (z, x, y) in tiles.keys) archive.tile(z, x, y),
      ]);

      expect(
        fetched.map((bytes) => utf8.decode(bytes!)),
        containsAll(tiles.values),
      );
    });

    test('one failed read does not take the queue with it', () async {
      final file = File('${workspace.path}/short.bin')
        ..writeAsBytesSync(Uint8List.fromList([1, 2, 3, 4]));
      final source = await FileByteRangeSource.open(file);
      addTearDown(source.close);

      final failing = source.read(-1, 4);
      final following = source.read(0, 4);

      await expectLater(failing, throwsA(isA<Object>()));
      expect(await following, [1, 2, 3, 4]);
    });
  });
}
