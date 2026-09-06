import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';

/// The writer is checked by reading what it produced with the app's own
/// reader: agreeing with itself is the only correctness that matters,
/// since that reader is the only thing that will ever open these files.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pmtiles_writer');
  });

  tearDown(() => dir.delete(recursive: true));

  Uint8List tileFor(int z, int x, int y) =>
      Uint8List.fromList(utf8.encode('tile $z/$x/$y ${'.' * (z * 40)}'));

  Future<PmTilesArchive> writeAndOpen(
    List<(int, int, int)> coordinates, {
    Map<String, Object?> metadata = const {'vector_layers': <Object>[]},
  }) async {
    final writer = await PmTilesWriter.create(dir);
    for (final (z, x, y) in coordinates) {
      await writer.add(z, x, y, tileFor(z, x, y));
    }

    final path = '${dir.path}/out.pmtiles';
    final zooms = coordinates.map((c) => c.$1);
    await writer.finish(
      path: path,
      minZoom: zooms.reduce((a, b) => a < b ? a : b),
      maxZoom: zooms.reduce((a, b) => a > b ? a : b),
      minLongitude: 5.9,
      minLatitude: 47.3,
      maxLongitude: 15.0,
      maxLatitude: 55.1,
      metadata: metadata,
    );

    return PmTilesArchive.open(await FileByteRangeSource.open(File(path)));
  }

  test('every tile written comes back byte for byte', () async {
    final coordinates = [
      for (var z = 0; z <= 4; z++)
        for (var x = 0; x < (1 << z); x++)
          for (var y = 0; y < (1 << z); y++) (z, x, y),
    ];

    final archive = await writeAndOpen(coordinates);
    addTearDown(archive.close);

    for (final (z, x, y) in coordinates) {
      expect(await archive.tile(z, x, y), tileFor(z, x, y), reason: '$z/$x/$y');
    }
  });

  test('a tile that was never written is a miss, not an error', () async {
    final archive = await writeAndOpen([
      (5, 16, 10),
      (5, 17, 10),
    ]);
    addTearDown(archive.close);

    expect(await archive.tile(5, 18, 10), isNull);
    expect(await archive.tile(9, 1, 1), isNull);
  });

  test('the header carries the bounds and the zoom range', () async {
    final archive = await writeAndOpen([
      (3, 4, 2),
      (7, 66, 42),
    ]);
    addTearDown(archive.close);

    expect(archive.header.minZoom, 3);
    expect(archive.header.maxZoom, 7);
    expect(archive.header.minLongitude, closeTo(5.9, 0.0001));
    expect(archive.header.maxLatitude, closeTo(55.1, 0.0001));
    expect(archive.header.tileType, PmTilesType.mvt);
  });

  // The archive is rejected on being chosen unless it declares its
  // layers, which is how the app tells an OpenMapTiles schema from a
  // Protomaps one.
  test('metadata survives the round trip', () async {
    final archive = await writeAndOpen(
      [
        (2, 1, 1),
      ],
      metadata: {
        'vector_layers': [
          {'id': 'water'},
          {'id': 'transportation'},
        ],
        'attribution': 'OpenStreetMap',
      },
    );
    addTearDown(archive.close);

    final metadata = await archive.metadata();
    expect(metadata['attribution'], 'OpenStreetMap');
    expect(
      (metadata['vector_layers']! as List).map((l) => (l as Map)['id']),
      ['water', 'transportation'],
    );
  });

  // Above roughly two thousand entries the root no longer fits in the
  // first 16 KB and the writer has to cut leaf directories, which is a
  // different path through both writer and reader.
  test('an archive too large for one directory still reads', () async {
    final coordinates = [
      for (var x = 0; x < 120; x++)
        for (var y = 0; y < 120; y++) (12, 2140 + x, 1370 + y),
    ];
    expect(coordinates, hasLength(14400));

    final archive = await writeAndOpen(coordinates);
    addTearDown(archive.close);

    for (final (z, x, y) in [
      coordinates.first,
      coordinates[7231],
      coordinates.last,
    ]) {
      expect(await archive.tile(z, x, y), tileFor(z, x, y), reason: '$z/$x/$y');
    }
    expect(await archive.tile(12, 2139, 1370), isNull);
  });

  test('identical tiles are stored once', () async {
    final writer = await PmTilesWriter.create(dir);
    final same = Uint8List.fromList(utf8.encode('empty ocean' * 20));
    for (var x = 0; x < 50; x++) {
      await writer.add(6, x, 20, same);
    }

    expect(writer.tileCount, 50);
    // One tile's worth of bytes on disk, not fifty.
    expect(writer.dataLength, lessThan(200));

    final path = '${dir.path}/dedup.pmtiles';
    await writer.finish(
      path: path,
      minZoom: 6,
      maxZoom: 6,
      minLongitude: 0,
      minLatitude: 0,
      maxLongitude: 1,
      maxLatitude: 1,
      metadata: const {},
    );

    final archive = await PmTilesArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    addTearDown(archive.close);
    expect(await archive.tile(6, 17, 20), same);
    expect(await archive.tile(6, 49, 20), same);
  });
}
