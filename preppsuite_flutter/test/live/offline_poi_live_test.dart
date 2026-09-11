import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_poi_search.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/tile_source.dart';

import '../features/maps/pmtiles_fixture.dart';

/// Builds a small archive out of real OpenFreeMap tiles and searches it.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. Worth running after
/// touching the search: everything it knows about the world is a set of
/// twenty-odd `subclass` strings, and those come from the schema rather
/// than from anything this app controls. If OpenMapTiles renames one, the
/// search quietly stops finding that thing — no error, no blank screen,
/// just a category that is always empty.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to build an archive from real tiles'
      : null;

  test(
    'the schema still carries the things a household looks for',
    () async {
      // Braunschweig, and the three tiles around its centre.
      const centre = LatLng(52.2689, 10.5268);
      final source = await TileSourceClient().load(MapTileProvider.openFreeMap);
      expect(source.maxZoom, greaterThanOrEqualTo(poiZoom));

      final client = http.Client();
      addTearDown(client.close);

      final tiles = <(int, int, int), List<int>>{};
      for (final tile in tilesAround(centre, 3000)) {
        final response = await client.get(
          source.tileUrl(poiZoom, tile.x, tile.y),
        );
        if (response.statusCode != 200) continue;
        // The archive stores gzipped bodies and the download does the same,
        // so what comes off the wire goes in unchanged — except that `http`
        // has already un-gzipped it for us.
        tiles[(poiZoom, tile.x, tile.y)] = response.bodyBytes;
      }
      stdout.writeln('${tiles.length} Kacheln geladen');
      expect(tiles, isNotEmpty);

      final workspace = Directory.systemTemp.createTempSync('poi-live');
      addTearDown(() => workspace.deleteSync(recursive: true));
      final file = File('${workspace.path}/area.pmtiles')
        ..writeAsBytesSync(
          buildBinaryArchive(
            tiles: tiles,
            bounds: (9.0, 51.0, 12.0, 53.0),
          ),
        );

      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(file),
      );
      addTearDown(archive.close);

      final started = DateTime.now();
      final progress = await OfflinePoiSearch(
        archive,
      ).search(centre: centre, radiusMeters: 3000).last;
      final took = DateTime.now().difference(started);

      final byKind = <PoiKind, int>{};
      for (final place in progress.places) {
        byKind[place.kind] = (byKind[place.kind] ?? 0) + 1;
      }
      stdout.writeln(
        '${progress.places.length} Treffer in ${took.inMilliseconds} ms: '
        '${byKind.entries.map((e) => '${e.key.name}=${e.value}').join(' ')}',
      );

      // Every group has to come back with something in a city of a quarter
      // of a million people. A group that is empty here is a group whose
      // `subclass` names the schema no longer writes.
      for (final kind in PoiKind.values) {
        expect(
          byKind[kind] ?? 0,
          greaterThan(0),
          reason: 'no ${kind.name} found — has the schema renamed a subclass?',
        );
      }

      // The distinction the whole design turns on.
      final fuel = progress.places.where((p) => p.subclass == 'fuel');
      final charging = progress.places.where(
        (p) => p.subclass == 'charging_station',
      );
      stdout.writeln(
        'Tankstellen ${fuel.length}, Ladesäulen ${charging.length}',
      );
      expect(fuel, isNotEmpty);
      expect(charging, isNotEmpty);

      // Nearest first, which is what makes the streamed answer useful.
      for (var i = 1; i < progress.places.length; i++) {
        expect(
          progress.places[i].distanceMeters,
          greaterThanOrEqualTo(progress.places[i - 1].distanceMeters),
        );
      }
    },
    skip: reason,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
