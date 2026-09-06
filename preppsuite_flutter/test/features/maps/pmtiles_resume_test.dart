import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';

/// A map of a country takes longer than anyone leaves an app open, so the
/// half-finished download has to survive being closed. These are the ways
/// it can be interrupted.
void main() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('pmtiles_resume');
  });
  tearDown(() => dir.delete(recursive: true));

  Uint8List tileFor(int z, int x, int y) =>
      Uint8List.fromList(utf8.encode('tile $z/$x/$y ${'-' * 60}'));

  Future<void> finish(PmTilesWriter writer, String path) => writer.finish(
    path: path,
    minZoom: 0,
    maxZoom: 6,
    minLongitude: 5,
    minLatitude: 47,
    maxLongitude: 15,
    maxLatitude: 55,
    metadata: const {'vector_layers': <Object>[]},
  );

  test('a closed writer is picked up where it stopped', () async {
    final first = await PmTilesWriter.create(dir);
    for (var x = 0; x < 20; x++) {
      await first.add(6, x, 20, tileFor(6, x, 20));
    }
    await first.close();

    // The scratch file and its journal are still there.
    expect(await PmTilesWriter.scratchFileIn(dir).exists(), isTrue);
    expect(await PmTilesWriter.journalFileIn(dir).exists(), isTrue);

    final second = await PmTilesWriter.resume(dir);
    expect(second.tileCount, 20);
    expect(second.storedTileIds, hasLength(20));

    for (var x = 20; x < 40; x++) {
      await second.add(6, x, 20, tileFor(6, x, 20));
    }

    final path = '${dir.path}/out.pmtiles';
    await finish(second, path);

    final archive = await PmTilesArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    addTearDown(archive.close);

    // Everything from both runs, byte for byte.
    for (var x = 0; x < 40; x++) {
      expect(await archive.tile(6, x, 20), tileFor(6, x, 20), reason: '$x');
    }
  });

  // The journal is written after the bytes are flushed, so a run killed
  // mid-tile leaves the scratch longer than the journal accounts for.
  test('bytes the journal never named are dropped', () async {
    final first = await PmTilesWriter.create(dir);
    for (var x = 0; x < 10; x++) {
      await first.add(6, x, 20, tileFor(6, x, 20));
    }
    await first.close();

    final scratch = PmTilesWriter.scratchFileIn(dir);
    final good = await scratch.length();
    await scratch.writeAsBytes(
      [...await scratch.readAsBytes(), ...utf8.encode('half a tile')],
      mode: FileMode.write,
    );
    expect(await scratch.length(), greaterThan(good));

    final second = await PmTilesWriter.resume(dir);
    expect(second.tileCount, 10);
    expect(await scratch.length(), good);

    await second.add(6, 10, 20, tileFor(6, 10, 20));
    final path = '${dir.path}/out.pmtiles';
    await finish(second, path);

    final archive = await PmTilesArchive.open(
      await FileByteRangeSource.open(File(path)),
    );
    addTearDown(archive.close);
    for (var x = 0; x <= 10; x++) {
      expect(await archive.tile(6, x, 20), tileFor(6, x, 20), reason: '$x');
    }
  });

  test('a journal line cut in half costs that tile and nothing else', () async {
    final first = await PmTilesWriter.create(dir);
    for (var x = 0; x < 10; x++) {
      await first.add(6, x, 20, tileFor(6, x, 20));
    }
    await first.close();

    final journal = PmTilesWriter.journalFileIn(dir);
    final text = await journal.readAsString();
    await journal.writeAsString('${text.substring(0, text.length - 6)}\n');

    final second = await PmTilesWriter.resume(dir);
    expect(second.tileCount, 9);
  });

  test('a fresh start throws the old attempt away', () async {
    final first = await PmTilesWriter.create(dir);
    await first.add(6, 1, 20, tileFor(6, 1, 20));
    await first.close();

    final second = await PmTilesWriter.create(dir);
    expect(second.tileCount, 0);
    expect(second.storedTileIds, isEmpty);
  });

  test('abandoning leaves nothing behind', () async {
    final writer = await PmTilesWriter.create(dir);
    await writer.add(6, 1, 20, tileFor(6, 1, 20));
    await writer.abandon();

    expect(await PmTilesWriter.scratchFileIn(dir).exists(), isFalse);
    expect(await PmTilesWriter.journalFileIn(dir).exists(), isFalse);
  });

  test('resuming where there is nothing simply starts', () async {
    final writer = await PmTilesWriter.resume(dir);
    expect(writer.tileCount, 0);
    await writer.add(6, 1, 20, tileFor(6, 1, 20));
    expect(writer.tileCount, 1);
  });
}
