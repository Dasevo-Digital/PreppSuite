import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_coverage.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

import 'pmtiles_fixture.dart';

/// Telling "you never downloaded this area" apart from "the map is
/// broken".
///
/// The two look identical on screen — half a map and half nothing — and
/// only one of them is worth a household's afternoon.
void main() {
  late Directory workspace;

  setUp(() {
    workspace = Directory.systemTemp.createTempSync('preppsuite-coverage');
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

  /// Zoom 2 splits the world into four by four. Tile (2, 2, 1) is
  /// roughly western Europe, which is where every box below sits.
  Future<PmTilesArchive> zoomTwo(Set<(int, int, int)> tiles) => archiveOf(
    buildArchive(
      minZoom: 2,
      maxZoom: 2,
      tiles: {for (final tile in tiles) tile: 'tile'},
    ),
  );

  test('an area the archive holds in full is complete', () async {
    final archive = await zoomTwo({(2, 2, 1)});

    final coverage = await offlineMapCoverage(
      archive,
      west: 10.0,
      south: 52.0,
      east: 10.5,
      north: 52.5,
      zoom: 2,
    );

    expect(coverage.isComplete, isTrue);
    expect(coverage.isPartial, isFalse);
    expect(coverage.isMissing, isFalse);
  });

  test('an area it holds nothing of is missing, not partial', () async {
    // Somewhere in the Pacific, in an archive of western Europe.
    final archive = await zoomTwo({(2, 2, 1)});

    final coverage = await offlineMapCoverage(
      archive,
      west: -150.0,
      south: -20.0,
      east: -149.5,
      north: -19.5,
      zoom: 2,
    );

    expect(coverage.isMissing, isTrue);
    expect(coverage.present, 0);
  });

  test('a view that straddles the edge is partial', () async {
    // The symptom the whole file is about: some of it draws and some of
    // it does not, and nothing on screen says which is which.
    final archive = await zoomTwo({(2, 2, 1)});

    final coverage = await offlineMapCoverage(
      archive,
      west: -10.0,
      south: 10.0,
      east: 10.0,
      north: 50.0,
      zoom: 2,
    );

    expect(coverage.isPartial, isTrue);
    expect(coverage.present, greaterThan(0));
    expect(coverage.present, lessThan(coverage.total));
  });

  test('a zoom the archive does not reach is not counted as missing', () async {
    // A staggered download stops at a shallower level outside the chosen
    // region, and the renderer substitutes a coarser tile. Reporting
    // "nothing here" for a level the file never claimed would be the app
    // answering a question nobody asked.
    final archive = await zoomTwo({(2, 2, 1)});

    final coverage = await offlineMapCoverage(
      archive,
      west: 10.0,
      south: 52.0,
      east: 10.5,
      north: 52.5,
      zoom: 14,
    );

    expect(coverage.isComplete, isTrue);
  });

  test('a huge view is sampled rather than walked tile by tile', () async {
    // Zoom 12 over the whole of Germany is tens of thousands of tiles,
    // and the answer is one sentence on a screen.
    final archive = await archiveOf(
      buildArchive(maxZoom: 14, tiles: const {(12, 2000, 1000): 'tile'}),
    );

    final coverage = await offlineMapCoverage(
      archive,
      west: 5.0,
      south: 47.0,
      east: 15.0,
      north: 55.0,
      zoom: 12,
    );

    // Germany at zoom 12 is over a hundred thousand tiles.
    expect(coverage.total, lessThanOrEqualTo(64));
    expect(coverage.total, greaterThan(1));
    expect(coverage.isMissing, isTrue);
  });
}
