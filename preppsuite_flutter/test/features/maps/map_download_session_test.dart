import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_session.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';

void main() {
  late Directory dir;
  const store = MapDownloadSessionStore();

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('map_session');
  });
  tearDown(() => dir.delete(recursive: true));

  MapDownloadSession sessionFor() => MapDownloadSession(
    plan: MapDownloadPlan([
      MapDownloadStep(
        label: 'Deutschland',
        area: const MapArea(
          minLongitude: 5.8663,
          minLatitude: 47.2701,
          maxLongitude: 15.0419,
          maxLatitude: 55.0992,
          maxZoom: 12,
        ),
      ),
      MapDownloadStep(
        label: 'Niedersachsen',
        area: const MapArea(
          minLongitude: 6.3459,
          minLatitude: 51.2951,
          maxLongitude: 11.5981,
          maxLatitude: 54.1378,
          minZoom: 13,
          maxZoom: 14,
        ),
      ),
    ]),
    targetPath: '${dir.path}/karte.pmtiles',
    label: 'Hannover (14)',
    startedAt: DateTime(2026, 9, 6, 10, 30),
  );

  /// The session only counts as resumable once there are bytes to resume.
  Future<void> withScratch() async {
    final writer = await PmTilesWriter.create(dir);
    await writer.add(6, 33, 20, utf8.encode('a tile'));
    await writer.close();
  }

  test('a plan survives being written and read back', () async {
    await withScratch();
    await store.write(dir, sessionFor());

    final read = (await store.read(dir))!;
    expect(read.label, 'Hannover (14)');
    expect(read.targetPath, '${dir.path}/karte.pmtiles');
    expect(read.startedAt, DateTime(2026, 9, 6, 10, 30));

    // The bands are what decide which tiles get fetched; getting them
    // back wrong would resume a download of somewhere else.
    expect(read.plan.steps.map((s) => s.label), [
      'Deutschland',
      'Niedersachsen',
    ]);
    expect(read.plan.steps.first.area.maxZoom, 12);
    expect(read.plan.steps.last.area.minZoom, 13);
    expect(read.plan.tileCount, sessionFor().plan.tileCount);
  });

  test('a session whose tiles are gone is not offered', () async {
    await withScratch();
    await store.write(dir, sessionFor());
    await PmTilesWriter.scratchFileIn(dir).delete();

    expect(await store.read(dir), isNull);
  });

  test('a file cut short by the process ending is not offered', () async {
    await withScratch();
    await store.write(dir, sessionFor());

    final file = MapDownloadSessionStore.fileIn(dir);
    final text = await file.readAsString();
    await file.writeAsString(text.substring(0, text.length ~/ 2));

    expect(await store.read(dir), isNull);
  });

  test('a plan missing a ring is refused rather than half read', () async {
    await withScratch();
    await MapDownloadSessionStore.fileIn(dir).writeAsString(
      jsonEncode({
        'target': '${dir.path}/x.pmtiles',
        'label': 'x',
        'plan': {
          'steps': [
            {'label': 'a', 'w': 1, 's': 2, 'e': 3, 'n': 4, 'from': 0, 'to': 5},
            {'label': 'broken'},
          ],
        },
      }),
    );

    expect(await store.read(dir), isNull);
  });

  test('counts what the journal says is stored', () async {
    final writer = await PmTilesWriter.create(dir);
    for (var x = 0; x < 7; x++) {
      await writer.add(6, x, 20, utf8.encode('tile $x'));
    }
    await writer.close();

    expect(await store.storedTileCount(dir), 7);
  });

  test('clearing takes the working files with it', () async {
    await withScratch();
    await store.write(dir, sessionFor());

    await store.clear(dir);

    expect(await MapDownloadSessionStore.fileIn(dir).exists(), isFalse);
    expect(await PmTilesWriter.scratchFileIn(dir).exists(), isFalse);
    expect(await PmTilesWriter.journalFileIn(dir).exists(), isFalse);
  });

  test('nothing there is not an error', () async {
    expect(await store.read(dir), isNull);
    expect(await store.storedTileCount(dir), 0);
    await store.clear(dir);
  });
}
