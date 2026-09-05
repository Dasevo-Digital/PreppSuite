import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_tile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart'
    show ThemeLayerType;

import 'pmtiles_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory workspace;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    workspace = Directory.systemTemp.createTempSync('preppsuite-offline-map');
  });

  tearDown(() => workspace.deleteSync(recursive: true));

  String archiveFile(String name, Uint8ListBuilder build) {
    final path = '${workspace.path}/$name';
    File(path).writeAsBytesSync(build());
    return path;
  }

  group('the map style', () {
    test('reads exactly the one source the archive provides', () {
      // `VectorTileLayer` looks up a provider per source in the style. A
      // style asking for a second one would throw the moment a tile is
      // drawn, which is not where anybody would go looking.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(mapThemeProvider).tileSources, {'openmaptiles'});
    });

    test('keeps no layer that would reach for the network', () {
      // The bundled style includes a shaded relief served from a web
      // server. On an offline map that is the one layer that must not be
      // there.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final types = container
          .read(mapThemeProvider)
          .layers
          .map((layer) => layer.type)
          .toSet();
      expect(types, isNot(contains(ThemeLayerType.raster)));
      expect(types, isNotEmpty);
    });
  });

  group('serving tiles to the renderer', () {
    test('a tile in the archive is handed over as it is stored', () async {
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(
          File(
            archiveFile(
              'ok.pmtiles',
              () => buildArchive(
                minZoom: 1,
                maxZoom: 6,
                tiles: {(3, 4, 5): 'tile bytes'},
              ),
            ),
          ),
        ),
      );
      addTearDown(archive.close);
      final provider = PmTilesVectorTileProvider(archive);

      expect(await provider.provide(TileIdentity(3, 4, 5)), isNotEmpty);
      expect(provider.minimumZoom, 1);
      expect(provider.maximumZoom, 6);
      // OpenMapTiles ships 512-pixel tiles. Without this offset the map
      // reads four times as many and draws everything at half size.
      expect(provider.tileOffset.zoomOffset, -1);
    });

    test('a tile outside the extract is a plain miss, never retried', () async {
      // Panning past the edge of a download is ordinary. Marking it
      // retryable would have the renderer ask again forever.
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(
          File(
            archiveFile(
              'small.pmtiles',
              () => buildArchive(maxZoom: 6, tiles: {(3, 4, 5): 'x'}),
            ),
          ),
        ),
      );
      addTearDown(archive.close);
      final provider = PmTilesVectorTileProvider(archive);

      await expectLater(
        provider.provide(TileIdentity(3, 0, 0)),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.retryable,
            'retryable',
            Retryable.none,
          ),
        ),
      );
    });
  });

  group('choosing an archive', () {
    Future<OfflineMapProblem?> use(String path) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(offlineMapProvider.future);

      return container
          .read(offlineMapProvider.notifier)
          .useArchive(location: path, label: 'test.pmtiles');
    }

    test('an OpenMapTiles archive is taken into use', () async {
      final path = archiveFile(
        'omt.pmtiles',
        () => buildArchive(
          maxZoom: 6,
          tiles: {(1, 0, 0): 'x'},
          metadata: {
            'vector_layers': [
              {'id': 'water'},
              {'id': 'transportation'},
              {'id': 'building'},
            ],
          },
        ),
      );

      expect(await use(path), isNull);
    });

    test('an archive in another schema is refused before it draws', () async {
      // Protomaps' own extracts are the common case: same file format,
      // different layer names, and the map would come out blank with no
      // hint as to why.
      final path = archiveFile(
        'protomaps.pmtiles',
        () => buildArchive(
          maxZoom: 6,
          tiles: {(1, 0, 0): 'x'},
          metadata: {
            'vector_layers': [
              {'id': 'earth'},
              {'id': 'roads'},
              {'id': 'places'},
            ],
          },
        ),
      );

      expect(await use(path), OfflineMapProblem.unknownSchema);
    });

    test(
      'an archive that names no layers is given the benefit of the doubt',
      () async {
        // The field is optional. Refusing a file for saying nothing would be
        // worse than letting the user see whether it draws.
        final path = archiveFile(
          'bare.pmtiles',
          () => buildArchive(maxZoom: 6, tiles: {(1, 0, 0): 'x'}),
        );

        expect(await use(path), isNull);
      },
    );

    test('an archive of image tiles is refused', () async {
      final bytes = buildArchive(maxZoom: 6, tiles: {(1, 0, 0): 'x'});
      bytes[99] = 2; // tile type: png
      final path = '${workspace.path}/raster.pmtiles';
      File(path).writeAsBytesSync(bytes);

      expect(await use(path), OfflineMapProblem.notVectorTiles);
    });

    test('a file that is not an archive is refused', () async {
      final path = '${workspace.path}/notes.txt';
      File(path).writeAsStringSync('this is not a map');

      expect(await use(path), OfflineMapProblem.unreadable);
    });

    test('a refused archive is not remembered for the next launch', () async {
      final path = '${workspace.path}/notes.txt';
      File(path).writeAsStringSync('this is not a map');
      await use(path);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final restored = await container.read(offlineMapProvider.future);
      expect(restored.isReady, isFalse);
      expect(
        restored.isConfigured,
        isFalse,
        reason: 'nothing was stored, so nothing is complained about again',
      );
    });

    test('a rejected file leaves a working map in place', () async {
      // Trying a second archive and failing must not cost the first one.
      final good = archiveFile(
        'good.pmtiles',
        () => buildArchive(maxZoom: 6, tiles: {(1, 0, 0): 'x'}),
      );
      final bad = '${workspace.path}/notes.txt';
      File(bad).writeAsStringSync('this is not a map');

      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(offlineMapProvider.future);
      final controller = container.read(offlineMapProvider.notifier);

      expect(
        await controller.useArchive(location: good, label: 'good.pmtiles'),
        isNull,
      );
      expect(
        await controller.useArchive(location: bad, label: 'notes.txt'),
        OfflineMapProblem.unreadable,
      );

      final state = container.read(offlineMapProvider).requireValue;
      expect(state.isReady, isTrue);
      expect(state.label, 'good.pmtiles');
      // Still readable, so it was not closed along the way.
      expect(await state.archive!.tile(1, 0, 0), isNotNull);
    });
  });
}

typedef Uint8ListBuilder = List<int> Function();
