import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/home/application/offline_probe.dart';
import 'package:preppsuite_flutter/features/knowledge/application/personal_document_store.dart';

import 'knowledge/zim_fixture.dart';
import 'maps/pmtiles_fixture.dart';
import 'maps/offline_poi_tile.dart';

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('offline-probe-'));
  tearDown(() => root.deleteSync(recursive: true));

  Future<OfflineProbeResult> run(OfflineProbeTarget target) async =>
      (await OfflineProbe(
        targets: () async => [target],
      ).run(OfflineProbeControl()).toList()).single;

  test(
    'reads an actual saved Markdown document and detects a missing one',
    () async {
      final file = File('${root.path}/plan.md')
        ..writeAsStringSync('# Plan\nWasser');
      final d = PersonalDocument(
        id: 'one',
        location: file.path,
        label: 'Plan.md',
        addedAt: DateTime.utc(2026),
      );
      expect(
        (await run(OfflineProbe.documentTarget(d))).status,
        OfflineProbeStatus.passed,
      );
      file.deleteSync();
      expect(
        (await run(OfflineProbe.documentTarget(d))).status,
        OfflineProbeStatus.failed,
      );
    },
  );

  test('opens and decodes real PMTiles content, not just its header', () async {
    final file = File('${root.path}/map.pmtiles')
      ..writeAsBytesSync(
        buildBinaryArchive(
          tiles: {(0, 0, 0): poiTile([])},
          minZoom: 0,
          maxZoom: 0,
        ),
      );
    expect(
      (await run(OfflineProbe.mapTarget(file.path, 'Map'))).status,
      OfflineProbeStatus.passed,
    );
    file.writeAsBytesSync(
      buildBinaryArchive(
        tiles: {
          (0, 0, 0): [255, 255, 255],
        },
        minZoom: 0,
        maxZoom: 0,
      ),
    );
    expect(
      (await run(OfflineProbe.mapTarget(file.path, 'Map'))).status,
      OfflineProbeStatus.failed,
    );
  });

  test('a valid map without a sampled tile is not falsely certified', () async {
    final file = File('${root.path}/empty.pmtiles')
      ..writeAsBytesSync(
        buildBinaryArchive(
          tiles: {(1, 0, 0): poiTile([])},
          minZoom: 0,
          maxZoom: 0,
        ),
      );
    expect(
      (await run(OfflineProbe.mapTarget(file.path, 'Map'))).reason,
      OfflineProbeReason.noSample,
    );
  });

  test('opens and decompresses the actual main page of a saved ZIM', () async {
    final file = File('${root.path}/book.zim')
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
    expect(
      (await run(OfflineProbe.archiveTarget(file.path, 'Book'))).status,
      OfflineProbeStatus.passed,
    );
    file.writeAsBytesSync([1, 2, 3]);
    expect(
      (await run(OfflineProbe.archiveTarget(file.path, 'Book'))).status,
      OfflineProbeStatus.failed,
    );
  });

  test(
    'large documents are reported untested instead of reading unbounded data',
    () async {
      final file = File('${root.path}/large.md');
      final handle = file.openSync(mode: FileMode.write);
      handle.truncateSync(OfflineProbe.documentByteLimit + 1);
      handle.closeSync();
      final d = PersonalDocument(
        id: 'one',
        location: file.path,
        label: 'Large.md',
        addedAt: DateTime.utc(2026),
      );
      final result = await run(OfflineProbe.documentTarget(d));
      expect(result.status, OfflineProbeStatus.notChecked);
      expect(result.reason, OfflineProbeReason.limit);
    },
  );

  test(
    'blocks network access inside a probe, leaving unrelated HTTP usable',
    () async {
      var requests = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((r) {
        requests++;
        r.response.close();
      });
      addTearDown(() => server.close(force: true));
      final result = await run(
        OfflineProbeTarget(OfflineProbeKind.document, 'Network', (_) async {
          await HttpClient().getUrl(
            Uri.parse('http://127.0.0.1:${server.port}/'),
          );
        }),
      );
      expect(result.status, OfflineProbeStatus.failed);
      expect(requests, 0);
      final client = HttpClient();
      await (await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}/')))
          .close();
      client.close(force: true);
      expect(requests, 1);
    },
  );

  test(
    'cancellation prevents subsequent resources from being opened',
    () async {
      final control = OfflineProbeControl();
      var opened = 0;
      final probe = OfflineProbe(
        targets: () async => [
          OfflineProbeTarget(OfflineProbeKind.document, 'First', (_) async {
            control.cancel();
          }),
          OfflineProbeTarget(OfflineProbeKind.document, 'Second', (_) async {
            opened++;
          }),
        ],
      );
      final results = await probe.run(control).toList();
      expect(opened, 0);
      expect(
        results.every((r) => r.reason == OfflineProbeReason.cancelled),
        isTrue,
      );
    },
  );

  test('timeouts stop the run instead of accumulating work', () async {
    var opened = 0;
    final pending = Completer<void>();
    final probe = OfflineProbe(
      timeout: const Duration(milliseconds: 10),
      targets: () async => [
        OfflineProbeTarget(
          OfflineProbeKind.document,
          'First',
          (_) => pending.future,
        ),
        OfflineProbeTarget(OfflineProbeKind.document, 'Second', (_) async {
          opened++;
        }),
      ],
    );
    final results = await probe.run(OfflineProbeControl()).toList();
    pending.complete();
    expect(results.first.reason, OfflineProbeReason.timeout);
    expect(opened, 0);
  });

  test('a resource limit reports omitted content explicitly', () async {
    var opened = 0;
    final result = await OfflineProbe(
      maxTargets: 1,
      targets: () async => List.generate(
        3,
        (i) => OfflineProbeTarget(OfflineProbeKind.document, '$i', (_) async {
          opened++;
        }),
      ),
    ).run(OfflineProbeControl()).toList();
    expect(opened, 1);
    expect(result.last.reason, OfflineProbeReason.limit);
    expect(result.last.label, '2');
  });
}
