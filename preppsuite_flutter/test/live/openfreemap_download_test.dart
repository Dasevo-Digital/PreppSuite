import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/byte_size.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_session.dart';
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
            plan: MapDownloadPlan.single(area),
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

  test(
    'a download interrupted part-way finishes on the second run',
    () async {
      final source = await TileSourceClient().load(MapTileProvider.openFreeMap);

      const area = MapArea(
        minLongitude: 9.70,
        minLatitude: 52.36,
        maxLongitude: 9.78,
        maxLatitude: 52.40,
        maxZoom: 11,
      );
      final plan = MapDownloadPlan.single(area);

      final directory = await Directory.systemTemp.createTemp('ofm_resume');
      addTearDown(() => directory.delete(recursive: true));
      final target = '${directory.path}/hannover.pmtiles';

      // Stopped at the first report that shows partial progress, the way
      // closing the app stops it. Driven by the events rather than by a
      // timer, or a fast connection would finish the whole thing first.
      final stopped = Completer<void>();
      late final StreamSubscription<MapDownloadProgress> subscription;
      subscription = MapAreaDownloader(concurrency: 1)
          .download(
            plan: plan,
            source: source,
            targetPath: target,
            workingDirectory: directory,
          )
          .listen((progress) {
            if (stopped.isCompleted) return;
            if (progress.done > 0 && progress.done < progress.total) {
              stopped.complete();
            }
          });

      await stopped.future.timeout(const Duration(minutes: 2));
      await subscription.cancel();

      final stored = await const MapDownloadSessionStore().storedTileCount(
        directory,
      );
      stdout.writeln('nach dem Abbruch: $stored von ${plan.tileCount}');
      expect(stored, greaterThan(0));
      expect(stored, lessThan(plan.tileCount));
      expect(await File(target).exists(), isFalse);

      final progress = await MapAreaDownloader(concurrency: 4)
          .download(
            plan: plan,
            source: source,
            targetPath: target,
            workingDirectory: directory,
            resume: true,
          )
          .last;
      stdout.writeln(
        'nach dem Fortsetzen: ${progress.done}/${progress.total}, '
        '${formatByteSize(progress.bytes)}',
      );
      expect(progress.done, plan.tileCount);

      // Real tiles are gzip; the journal has to survive that, not just
      // the text the unit tests use.
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(target)),
      );
      addTearDown(archive.close);
      for (final tile in area.tiles()) {
        final bytes = await archive.tile(tile.z, tile.x, tile.y);
        expect(bytes, isNotNull, reason: '${tile.z}/${tile.x}/${tile.y}');
        expect(bytes!.length, greaterThan(50));
      }
      stdout.writeln('alle ${plan.tileCount} Kacheln lesbar');
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: reason,
  );
}
