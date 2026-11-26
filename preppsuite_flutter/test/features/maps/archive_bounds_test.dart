import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/offline_nearby_points.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_writer.dart';

import 'pmtiles_fixture.dart';

/// What a map is about, as opposed to the world base under it (#389).
///
/// Every map built in the app up to 3.0.3 stated the whole world in its
/// header, because the base of zoom 0 to 4 went into the box. The points
/// taken along with the map were never fetched (the world is too large a
/// box), the readiness overview counted every place as on the map, and
/// the offline search said "nothing found" where it should have said
/// "outside".
void main() {
  MapArea box(double w, double s, double e, double n) => MapArea(
    minLongitude: w,
    minLatitude: s,
    maxLongitude: e,
    maxLatitude: n,
    maxZoom: 14,
  );

  final germany = box(5.8663, 47.2701, 15.0419, 55.0992);
  final lowerSaxony = box(6.3459, 51.2951, 11.5981, 54.1378);
  final hannover = box(9.6044, 52.3049, 9.9186, 52.4543);

  group('tile ids read backwards', () {
    test('every tile of a level comes back from its id', () {
      for (var z = 0; z <= 6; z++) {
        for (var x = 0; x < 1 << z; x++) {
          for (var y = 0; y < 1 << z; y++) {
            expect(
              tileForId(tileIdFor(z, x, y)),
              (z: z, x: x, y: y),
              reason: '$z/$x/$y',
            );
          }
        }
      }
    });

    test('and so does a tile deep down', () {
      expect(tileForId(tileIdFor(14, 8619, 5383)), (z: 14, x: 8619, y: 5383));
    });
  });

  group('a plan states its rings, not the world', () {
    test('a staggered plan is the box of its outermost ring', () {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
        ],
      )!;

      // The world base is still in it, and still fetched.
      expect(plan.steps.first.area.coversWholeWorld, isTrue);
      expect(plan.minLongitude, germany.minLongitude);
      expect(plan.minLatitude, germany.minLatitude);
      expect(plan.maxLongitude, germany.maxLongitude);
      expect(plan.maxLatitude, germany.maxLatitude);
    });

    test('a town on its own is the town', () {
      final plan = staggeredPlan(
        rings: [MapDownloadRing(label: 'Hannover', box: hannover)],
      )!;

      expect(plan.minLongitude, hannover.minLongitude);
      expect(plan.maxLatitude, hannover.maxLatitude);
    });

    test('a plan of nothing but the world says the world', () {
      final plan = MapDownloadPlan.single(MapArea.world());

      expect(plan.minLongitude, -180);
      expect(plan.maxLongitude, 180);
    });
  });

  group('an archive that states the whole world', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('archive_bounds');
    });

    tearDown(() => dir.delete(recursive: true));

    Future<PmTilesArchive> open(Uint8List bytes) async {
      final file = File('${dir.path}/map.pmtiles')..writeAsBytesSync(bytes);
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(file),
      );
      addTearDown(archive.close);
      return archive;
    }

    /// What 3.0.3 wrote: the plan's tiles, and the world in the header.
    Future<PmTilesArchive> builtBy303(MapDownloadPlan plan) async {
      final writer = await PmTilesWriter.create(dir);
      for (final tile in plan.tiles()) {
        await writer.add(
          tile.z,
          tile.x,
          tile.y,
          Uint8List.fromList([tile.z, tile.x & 0xff, tile.y & 0xff]),
        );
      }
      final path = '${dir.path}/built.pmtiles';
      await writer.finish(
        path: path,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
        minLongitude: -180,
        minLatitude: -85.05,
        maxLongitude: 180,
        maxLatitude: 85.05,
        metadata: const {'vector_layers': <Object>[]},
      );
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(path)),
      );
      addTearDown(archive.close);
      return archive;
    }

    test('a map built by 3.0.3 is about its outermost ring', () async {
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: 'Deutschland', box: germany),
          MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony),
          MapDownloadRing(label: 'Hannover', box: hannover),
        ],
        budget: 4000,
        deepest: 12,
      )!;
      final country = plan.steps[1].area;
      expect(country.minZoom, MapArea.worldBaseZoom + 1);

      final archive = await builtBy303(plan);
      expect(archive.header.minLongitude, -180);

      final bounds = archive.bounds;
      // The whole country, and at most one of its finest tiles more.
      final tile = 360 / (1 << country.maxZoom);
      expect(bounds.west, inInclusiveRange(germany.minLongitude - tile, 5.87));
      expect(bounds.east, inInclusiveRange(15.04, germany.maxLongitude + tile));
      expect(bounds.south, inInclusiveRange(germany.minLatitude - tile, 47.28));
      expect(bounds.north, inInclusiveRange(55.09, germany.maxLatitude + tile));

      // Which is what the points taken along are fetched for: Germany
      // fits, the world did not.
      expect(offlinePointAreaFits(boundsOfArchive(archive)), isTrue);
      expect(bounds.contains(48.8566, 2.3522), isFalse, reason: 'Paris');
      expect(bounds.contains(52.3759, 9.7320), isTrue, reason: 'Hannover');
    });

    test('a map of one Bundesland is that Bundesland', () async {
      final plan = staggeredPlan(
        rings: [MapDownloadRing(label: 'Niedersachsen', box: lowerSaxony)],
        budget: 6000,
        deepest: 11,
      )!;

      final bounds = (await builtBy303(plan)).bounds;

      // Followed down to level 11: a tile is under a fifth of a degree.
      const tile = 360 / (1 << 11);
      expect(
        bounds.west,
        inInclusiveRange(lowerSaxony.minLongitude - tile, 6.35),
      );
      expect(
        bounds.north,
        inInclusiveRange(54.13, lowerSaxony.maxLatitude + tile),
      );
    });

    test('a box named in the metadata is taken as it is', () async {
      final archive = await open(
        buildArchive(
          tiles: {(0, 0, 0): 'world', (5, 16, 10): 'x'},
          metadata: {'bounds': '5.8663,47.2701,15.0419,55.0992'},
        ),
      );

      expect(archive.bounds.west, closeTo(5.8663, 1e-9));
      expect(archive.bounds.north, closeTo(55.0992, 1e-9));
    });

    test('a map of the whole world stays the whole world', () async {
      final archive = await open(
        buildArchive(
          maxZoom: 5,
          tiles: {
            for (final tile in MapArea.world(to: 5).tiles())
              (tile.z, tile.x, tile.y): 'w',
          },
          leafSize: 200,
        ),
      );

      expect(archive.bounds.isWholeWorld, isTrue);
    });

    test('only a base, with nothing on it, stays the world', () async {
      final archive = await open(
        buildArchive(
          maxZoom: 4,
          tiles: {
            for (final tile in MapArea.world().tiles())
              (tile.z, tile.x, tile.y): 'w',
          },
        ),
      );

      expect(archive.bounds.isWholeWorld, isTrue);
    });
  });

  test('an archive that names its region in the header keeps it', () async {
    final dir = await Directory.systemTemp.createTemp('archive_bounds');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/region.pmtiles')
      ..writeAsBytesSync(
        buildArchive(
          bounds: (9.0, 51.0, 12.0, 53.0),
          tiles: {
            for (final tile in MapArea.world().tiles())
              (tile.z, tile.x, tile.y): 'w',
          },
        ),
      );
    final archive = await PmTilesArchive.open(
      await FileByteRangeSource.open(file),
    );
    addTearDown(archive.close);

    expect(archive.bounds.west, closeTo(9.0, 1e-6));
    expect(archive.bounds.north, closeTo(53.0, 1e-6));
  });

  group('a box in the metadata', () {
    test('reads the MBTiles spelling and a list', () {
      expect(PmTilesBounds.parse('5.8,47.2,15.1,55.1')?.east, 15.1);
      expect(PmTilesBounds.parse([5.8, 47.2, 15.1, 55.1])?.south, 47.2);
    });

    test('refuses anything that is not a box', () {
      expect(PmTilesBounds.parse(null), isNull);
      expect(PmTilesBounds.parse('5.8,47.2,15.1'), isNull);
      expect(PmTilesBounds.parse('15.1,47.2,5.8,55.1'), isNull);
      expect(PmTilesBounds.parse('5.8,47.2,15.1,NaN'), isNull);
      expect(PmTilesBounds.parse('-200,47.2,15.1,55.1'), isNull);
      expect(PmTilesBounds.parse({'west': 5.8}), isNull);
    });
  });
}
