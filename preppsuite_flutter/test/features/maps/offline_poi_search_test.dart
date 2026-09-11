import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_poi_search.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_bearing.dart';
import 'offline_poi_tile.dart';
import 'pmtiles_fixture.dart';

void main() {
  // Braunschweig's town centre sits in 14/8671/5391.
  const centre = LatLng(52.2689, 10.5268);

  late Directory workspace;
  setUp(() => workspace = Directory.systemTemp.createTempSync('poi'));
  tearDown(() => workspace.deleteSync(recursive: true));

  var serial = 0;

  Future<PmTilesArchive> archiveWith(
    Map<(int, int, int), List<TestPoi>> tiles, {
    int maxZoom = 14,
  }) async {
    final bytes = buildBinaryArchive(
      tiles: {
        for (final tile in tiles.entries) tile.key: poiTile(tile.value),
      },
      maxZoom: maxZoom,
      bounds: (9.0, 51.0, 12.0, 53.0),
    );
    final file = File('${workspace.path}/${serial++}.pmtiles')
      ..writeAsBytesSync(bytes);
    return PmTilesArchive.open(await FileByteRangeSource.open(file));
  }

  test(
    'a point in the tile comes back at the coordinate it was put at',
    () async {
      // Dead centre of the tile: half the extent in both directions.
      final archive = await archiveWith({
        (14, 8671, 5391): [
          (subclass: 'pharmacy', name: 'Apotheke am Markt', x: 2048, y: 2048),
        ],
      });
      addTearDown(archive.close);

      final centreOfTile = LatLng(
        // Worked out independently of the code under test: the tile's own
        // centre in Web Mercator.
        _latitudeOfWorldY((5391 + 0.5) / 16384),
        (8671 + 0.5) / 16384 * 360 - 180,
      );

      final progress = await OfflinePoiSearch(
        archive,
      ).search(centre: centreOfTile, radiusMeters: 2000).last;

      expect(progress.places, hasLength(1));
      final found = progress.places.single;
      expect(found.name, 'Apotheke am Markt');
      expect(found.kind, PoiKind.health);
      expect(found.position.latitude, closeTo(centreOfTile.latitude, 0.0005));
      expect(found.position.longitude, closeTo(centreOfTile.longitude, 0.0005));
      expect(found.distanceMeters, lessThan(50));
    },
  );

  test('a filling station and a charging point stay apart', () async {
    // The measured reason this search keys on `subclass`: the schema puts
    // both under class `fuel`, and in the sample there were twelve times
    // as many charging points as filling stations.
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'fuel', name: 'Tankstelle', x: 2048, y: 2048),
        (subclass: 'charging_station', name: 'Ladesäule', x: 2050, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 3000).last;

    expect(progress.places.map((p) => p.subclass), contains('fuel'));
    expect(
      progress.places.map((p) => p.subclass),
      contains('charging_station'),
    );
    expect(progress.places.every((p) => p.kind == PoiKind.fuel), isTrue);
  });

  test('a nameless point is kept and says what it is', () async {
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'drinking_water', name: null, x: 2048, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 3000).last;

    expect(progress.places, hasLength(1));
    expect(progress.places.single.name, isNull);
    expect(progress.places.single.kind, PoiKind.water);
  });

  test('everything the household never asked for is left out', () async {
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'waste_basket', name: null, x: 2000, y: 2000),
        (subclass: 'hairdresser', name: 'Schnitt', x: 2010, y: 2000),
        (subclass: 'bakery', name: 'Bäckerei', x: 2020, y: 2000),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 3000).last;

    expect(progress.places.map((p) => p.subclass), ['bakery']);
  });

  test('only the kinds asked for are read', () async {
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'bakery', name: 'Bäckerei', x: 2000, y: 2000),
        (subclass: 'pharmacy', name: 'Apotheke', x: 2010, y: 2000),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 3000, kinds: {PoiKind.health}).last;

    expect(progress.places.map((p) => p.subclass), ['pharmacy']);
  });

  test('a point carried by a neighbouring tile is not counted twice', () async {
    // The schema buffers each tile, so a shop near an edge is written
    // into its neighbour as well — at a coordinate outside that
    // neighbour's own square, and rounded to that tile's own grid, so
    // the two copies do not land on exactly the same number.
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'supermarket', name: 'Markt', x: 4090, y: 2048),
      ],
      (14, 8672, 5391): [
        (subclass: 'supermarket', name: 'Markt', x: -5, y: 2049),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 4000).last;

    expect(progress.places, hasLength(1));
  });

  test('a buffered copy alone is not read as a point in that tile', () async {
    // Only the neighbour is in the archive, carrying the point at a
    // coordinate outside its own square. Attributing it to that tile
    // would put it somewhere it is not.
    final archive = await archiveWith({
      (14, 8672, 5391): [
        (subclass: 'supermarket', name: 'Markt', x: -5, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 4000).last;

    expect(progress.places, isEmpty);
  });

  test('nothing outside the radius is offered', () async {
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'pharmacy', name: 'Nah', x: 2048, y: 2048),
      ],
      (14, 8674, 5391): [
        (subclass: 'pharmacy', name: 'Fern', x: 2048, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 2000).last;

    expect(progress.places.map((p) => p.name), isNot(contains('Fern')));
  });

  test('the nearest tile is read first, so the list is useful early', () async {
    final archive = await archiveWith({
      (14, 8671, 5391): [
        (subclass: 'pharmacy', name: 'Nah', x: 2048, y: 2048),
      ],
      (14, 8672, 5392): [
        (subclass: 'pharmacy', name: 'Weiter', x: 2048, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final steps = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 5000).toList();

    final firstWithAnything = steps.firstWhere((s) => s.places.isNotEmpty);
    expect(firstWithAnything.places.first.name, 'Nah');
    expect(steps.last.isComplete, isTrue);
  });

  test('results carry the direction to walk in', () async {
    final archive = await archiveWith({
      // North of the centre: a smaller y is further north.
      (14, 8671, 5390): [
        (subclass: 'pharmacy', name: 'Nord', x: 2048, y: 2048),
      ],
    });
    addTearDown(archive.close);

    final progress = await OfflinePoiSearch(
      archive,
    ).search(centre: centre, radiusMeters: 5000).last;

    expect(progress.places.single.bearing, CompassPoint.north);
  });

  test(
    'an archive that stops above zoom 14 says so instead of finding nothing',
    () async {
      final archive = await archiveWith({
        (14, 8671, 5391): [
          (subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048),
        ],
      }, maxZoom: 12);
      addTearDown(archive.close);

      expect(
        () => OfflinePoiSearch(
          archive,
        ).search(centre: centre, radiusMeters: 2000).last,
        throwsA(
          isA<PoiSearchException>().having(
            (e) => e.problem,
            'problem',
            PoiSearchProblem.tooShallow,
          ),
        ),
      );
    },
  );

  test(
    'a point outside what was downloaded is refused, not searched',
    () async {
      final archive = await archiveWith({
        (14, 8671, 5391): [
          (subclass: 'pharmacy', name: 'Apotheke', x: 2048, y: 2048),
        ],
      });
      addTearDown(archive.close);

      expect(
        () => OfflinePoiSearch(archive)
            // Munich; the fixture declares 9–12 E, 51–53 N.
            .search(centre: const LatLng(48.1372, 11.5756), radiusMeters: 2000)
            .last,
        throwsA(
          isA<PoiSearchException>().having(
            (e) => e.problem,
            'problem',
            PoiSearchProblem.outsideArchive,
          ),
        ),
      );
    },
  );

  test('a wide radius is capped rather than left to read the country', () {
    final tiles = tilesAround(centre, 100000);
    expect(tiles, hasLength(OfflinePoiSearch.tileBudget));
    // Capped or not, the nearest tile is still the first one read.
    expect(tiles.first, (x: 8671, y: 5391));
  });

  test('a five-kilometre radius covers the tiles around the point', () {
    final tiles = tilesAround(centre, 5000);
    expect(tiles, contains((x: 8671, y: 5391)));
    expect(tiles, contains((x: 8672, y: 5391)));
    expect(tiles, contains((x: 8671, y: 5392)));
    expect(tiles.length, lessThan(OfflinePoiSearch.tileBudget));
  });
}

/// The inverse Mercator, written out here rather than taken from the code
/// under test — an expectation that calls the thing it is checking proves
/// nothing.
double _latitudeOfWorldY(double worldY) {
  final n = math.pi * (1 - 2 * worldY);
  final sinh = (math.exp(n) - math.exp(-n)) / 2;
  return math.atan(sinh) * 180 / math.pi;
}
