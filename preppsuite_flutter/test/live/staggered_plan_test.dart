import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/downloads/application/byte_size.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/map_download_plan.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/place_search.dart';
import 'package:preppsuite_flutter/features/maps/application/tile_source.dart';

/// The whole staggered path against the real services: geocode a town,
/// resolve the state and country around it, and see what the plan comes
/// to — then actually build a small one and read it back.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real services'
      : null;

  test(
    'a whole country, staggered, from a town name',
    () async {
      final client = PlaceSearchClient();

      final place = (await client.search('Hannover')).first;
      expect(place.stateName, 'Niedersachsen');
      expect(place.countryName, 'Deutschland');
      await Future<void>.delayed(const Duration(milliseconds: 1100));

      final region = await client.resolve(place.stateName!);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final country = await client.resolve(place.countryName!);
      expect(region, isNotNull);
      expect(country, isNotNull);

      final flat = country!.areaAt(14).tileCount;
      stdout.writeln('Deutschland flach bis Stufe 14: $flat Kacheln');

      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: country.name, box: country.areaAt(14)),
          MapDownloadRing(label: region!.name, box: region.areaAt(14)),
          MapDownloadRing(label: place.name, box: place.areaAt(14)),
        ],
      )!;

      for (final step in plan.steps) {
        stdout.writeln(
          '  ${step.label.padRight(14)} '
          'z${step.area.minZoom}-${step.area.maxZoom}  '
          '${step.tileCount} Kacheln',
        );
      }
      stdout.writeln(
        'gestaffelt: ${plan.tileCount} Kacheln, '
        'ca. ${formatByteSize(plan.tileCount * 45000)} '
        '(${(flat / plan.tileCount).toStringAsFixed(1)}x weniger)',
      );

      // The country is covered from the top with no gap anywhere.
      expect(plan.steps.first.area.minZoom, 0);
      expect(plan.steps.last.area.maxZoom, 14);
      expect(plan.tileCount, lessThanOrEqualTo(MapAreaDownloader.tileLimit));
      expect(plan.tileCount * 3, lessThan(flat));
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: reason,
  );

  test(
    'a small staggered plan downloads and reads back',
    () async {
      final client = PlaceSearchClient();
      final place = (await client.search('Wolfsburg')).first;
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      final region = await client.resolve(place.stateName!);

      // Deliberately tiny, so this stays polite to a public server.
      final plan = staggeredPlan(
        rings: [
          MapDownloadRing(label: region!.name, box: region.areaAt(14)),
          MapDownloadRing(label: place.name, box: place.areaAt(14)),
        ],
        budget: 400,
      )!;

      for (final step in plan.steps) {
        stdout.writeln(
          '  ${step.label} z${step.area.minZoom}-${step.area.maxZoom}: '
          '${step.tileCount}',
        );
      }
      expect(plan.steps, hasLength(2));
      expect(plan.tileCount, lessThanOrEqualTo(400));

      final source = await TileSourceClient().load(MapTileProvider.openFreeMap);
      final directory = await Directory.systemTemp.createTemp('stagger_live');
      addTearDown(() => directory.delete(recursive: true));
      final target = '${directory.path}/staggered.pmtiles';

      final progress = await MapAreaDownloader(concurrency: 4)
          .download(
            plan: plan,
            source: source,
            targetPath: target,
            workingDirectory: directory,
          )
          .last;
      stdout.writeln(
        'geladen: ${progress.done}/${progress.total}, '
        '${formatByteSize(progress.bytes)}',
      );

      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(target)),
      );
      addTearDown(archive.close);

      expect(archive.header.minZoom, 0);
      expect(archive.header.maxZoom, 14);

      // A tile from the outer ring and one from the innermost, so both
      // bands are proven to have landed in the same archive.
      final outer = plan.steps.first.area.tiles().first;
      final inner = plan.steps.last.area.tiles().last;
      expect(await archive.tile(outer.z, outer.x, outer.y), isNotNull);
      expect(await archive.tile(inner.z, inner.x, inner.y), isNotNull);
      stdout.writeln(
        'aussen z${outer.z} und innen z${inner.z} beide im Archiv',
      );
    },
    timeout: const Timeout(Duration(minutes: 10)),
    skip: reason,
  );
}
