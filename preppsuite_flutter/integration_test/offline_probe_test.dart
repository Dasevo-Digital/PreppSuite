import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:preppsuite_flutter/features/home/application/offline_probe.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';

import '../test/features/knowledge/zim_fixture.dart';
import '../test/features/maps/offline_poi_tile.dart';
import '../test/features/maps/pmtiles_fixture.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'probe reads stored content with the device parsers and isolates',
    (
      tester,
    ) async {
      await tester.runAsync(() async {
        final root = await Directory.systemTemp.createTemp('offline-content-');
        addTearDown(() => root.delete(recursive: true));
        final document = File('${root.path}/plan.md')
          ..writeAsStringSync('# Plan\nWasser');
        final map = File('${root.path}/map.pmtiles')
          ..writeAsBytesSync(
            buildBinaryArchive(
              tiles: {(0, 0, 0): poiTile([])},
              minZoom: 0,
              maxZoom: 0,
            ),
          );
        final archive = File('${root.path}/book.zim')
          ..writeAsBytesSync(
            ZimFixture(
              entries: [
                ZimFixtureEntry(
                  namespace: 'W',
                  url: 'mainPage',
                  content: utf8.encode('<h1>Start</h1>'),
                ),
              ],
              compression: 4,
            ).build(),
          );
        final targets = [
          OfflineProbe.documentTarget(
            PersonalDocument(
              id: 'sample',
              location: document.path,
              label: 'Plan.md',
              addedAt: DateTime.utc(2026),
            ),
          ),
          OfflineProbe.mapTarget(map.path, 'Map'),
          OfflineProbe.archiveTarget(archive.path, 'Book'),
        ];
        Future<List<OfflineProbeResult>> run() => OfflineProbe(
          targets: () async => targets,
        ).run(OfflineProbeControl()).toList();
        final good = await run();
        expect(good, hasLength(3));
        expect(
          good.map((r) => r.status),
          everyElement(OfflineProbeStatus.passed),
        );
        await document.delete();
        map.writeAsBytesSync([1, 2, 3]);
        archive.writeAsBytesSync([1, 2, 3]);
        expect(
          (await run()).map((r) => r.status),
          everyElement(OfflineProbeStatus.failed),
        );
      });
    },
  );
}
