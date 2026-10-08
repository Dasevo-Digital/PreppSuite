@Timeout(Duration(minutes: 3))
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';

/// Counts what is read where, so the leaf reads can be told apart.
class _CountingSource implements ByteRangeSource {
  _CountingSource(this._inner);

  final ByteRangeSource _inner;
  final reads = <(int, int)>[];

  /// Reads at or past this offset fail once, then work.
  int? failOnceFrom;

  @override
  Future<Uint8List> read(int offset, int length) {
    reads.add((offset, length));
    final from = failOnceFrom;
    if (from != null && offset >= from) {
      failOnceFrom = null;
      return Future.error(const FileSystemException('disk went away'));
    }
    return _inner.read(offset, length);
  }

  @override
  Future<void> close() => _inner.close();
}

/// A screenful of tiles on a part of the map not seen yet all need the same
/// leaf directory (#13).
void main() {
  late Directory dir;
  late String path;
  late PmTilesArchive archive;
  late _CountingSource source;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('pmtiles_leaf');
    final writer = await PmTilesWriter.create(dir);
    // Enough tiles that the root no longer fits and leaves are cut.
    for (var x = 0; x < 120; x++) {
      for (var y = 0; y < 120; y++) {
        await writer.add(
          12,
          2140 + x,
          1370 + y,
          Uint8List.fromList(utf8.encode('tile $x/$y')),
        );
      }
    }
    path = '${dir.path}/out.pmtiles';
    await writer.finish(
      path: path,
      minZoom: 12,
      maxZoom: 12,
      minLongitude: 5.9,
      minLatitude: 47.3,
      maxLongitude: 15.0,
      maxLatitude: 55.1,
      metadata: const {'vector_layers': <Object>[]},
    );
  });

  tearDownAll(() => dir.delete(recursive: true));

  setUp(() async {
    source = _CountingSource(await FileByteRangeSource.open(File(path)));
    archive = await PmTilesArchive.open(source);
  });

  tearDown(() => archive.close());

  int leafReads() {
    final start = archive.header.leafDirectoryOffset;
    final end = archive.header.tileDataOffset;
    return source.reads.where((r) => r.$1 >= start && r.$1 < end).length;
  }

  test('a screenful at once reads its leaf once', () async {
    expect(
      archive.header.tileDataOffset,
      greaterThan(archive.header.leafDirectoryOffset),
    );
    final tiles = await Future.wait([
      for (var dx = 0; dx < 8; dx++)
        for (var dy = 0; dy < 6; dy++) archive.tile(12, 2140 + dx, 1370 + dy),
    ]);
    expect(tiles.whereType<Uint8List>(), hasLength(48));
    // It was one read per tile: 48 reads and 48 gunzips of the same leaf.
    expect(leafReads(), 1);
  });

  test('a leaf that failed to read is read again, not kept', () async {
    source.failOnceFrom = archive.header.leafDirectoryOffset;
    await expectLater(
      archive.tile(12, 2140, 1370),
      throwsA(isA<FileSystemException>()),
    );
    expect(
      await archive.tile(12, 2140, 1370),
      Uint8List.fromList(utf8.encode('tile 0/0')),
    );
  });
}
