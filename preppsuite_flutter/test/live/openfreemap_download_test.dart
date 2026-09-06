import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/byte_size.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/tile_source.dart';

/// Builds a real archive out of real tiles and checks the app would take
/// it: the schema check in `offline_map_providers.dart` is what a
/// downloaded map has to pass, and passing it is the whole point of
/// fetching from a source that speaks OpenMapTiles.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set — see the Kiwix test
/// next door.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to fetch real tiles'
      : null;

  test(
    'an area downloaded from OpenFreeMap renders with the built-in style',
    () async {
      final source = await TileSourceClient().load(MapTileProvider.openFreeMap);
      stdout.writeln(
        'tiles: ${source.tileTemplate} (to zoom ${source.maxZoom})',
      );
      expect(source.maxZoom, greaterThanOrEqualTo(12));

      // The middle of Hannover, small enough to be polite about.
      const area = MapArea(
        minLongitude: 9.70,
        minLatitude: 52.36,
        maxLongitude: 9.78,
        maxLatitude: 52.40,
        maxZoom: 12,
      );
      stdout.writeln('area: ${area.tileCount} tiles');
      expect(area.tileCount, lessThan(200));

      final directory = await Directory.systemTemp.createTemp('ofm_live');
      addTearDown(() => directory.delete(recursive: true));
      final target = '${directory.path}/hannover.pmtiles';

      final progress = await MapAreaDownloader(concurrency: 4)
          .download(
            area: area,
            source: source,
            targetPath: target,
            workingDirectory: directory,
          )
          .last;

      stdout.writeln(
        'done ${progress.done}/${progress.total}, '
        '${progress.missing} empty, ${formatByteSize(progress.bytes)}',
      );
      expect(progress.done, area.tileCount);

      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(target)),
      );
      addTearDown(archive.close);

      // The same two layer names `_schemaLooksRight` insists on.
      final layers = {
        for (final layer
            in (await archive.metadata())['vector_layers']! as List)
          (layer as Map)['id'] as String,
      };
      stdout.writeln('layers: ${layers.length}');
      expect(layers, containsAll(<String>['water', 'transportation']));

      // Every tile the area asked for must come back out again,
      // decompressed by the reader.
      for (final wanted in area.tiles()) {
        final tile = await archive.tile(wanted.z, wanted.x, wanted.y);
        expect(
          tile,
          isNotNull,
          reason: '${wanted.z}/${wanted.x}/${wanted.y}',
        );
        expect(tile!.length, greaterThan(50));
      }

      final deepest = area.tiles().last;
      stdout.writeln(
        'deepest tile ${deepest.z}/${deepest.x}/${deepest.y}: '
        '${formatByteSize((await archive.tile(deepest.z, deepest.x, deepest.y))!.length)}',
      );

      stdout.writeln('archive: ${formatByteSize(await File(target).length())}');
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: reason,
  );
}
