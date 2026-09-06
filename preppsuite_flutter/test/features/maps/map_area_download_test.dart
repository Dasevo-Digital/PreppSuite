import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:preppsuite_flutter/features/maps/application/tile_source.dart';

/// Answers every tile with its own coordinates, and nothing at all for a
/// chosen few.
class _TileServer extends http.BaseClient {
  _TileServer({this.missing = const {}, this.status = 200});

  final Set<String> missing;
  final int status;
  final requested = <String>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final path = request.url.path;
    requested.add(path);

    if (missing.contains(path)) {
      return http.StreamedResponse(const Stream.empty(), 404);
    }
    if (status != 200) {
      return http.StreamedResponse(const Stream.empty(), status);
    }
    final body = utf8.encode('tile at $path');
    return http.StreamedResponse(
      Stream.value(body),
      200,
      contentLength: body.length,
    );
  }
}

const _germany = MapArea(
  minLongitude: 5.9,
  minLatitude: 47.3,
  maxLongitude: 15.0,
  maxLatitude: 55.1,
  maxZoom: 8,
);

void main() {
  group('MapArea', () {
    test('counts the tiles an area comes to', () {
      // Counted independently against the Web Mercator formulas; these
      // are the numbers that decide whether an area may be asked for.
      expect(_germany.tileCount, 105);
      expect(
        const MapArea(
          minLongitude: 5.9,
          minLatitude: 47.3,
          maxLongitude: 15.0,
          maxLatitude: 55.1,
          maxZoom: 12,
        ).tileCount,
        20031,
      );
    });

    test('a whole country at street level is refused', () async {
      const wholeCountry = MapArea(
        minLongitude: 5.9,
        minLatitude: 47.3,
        maxLongitude: 15.0,
        maxLatitude: 55.1,
        maxZoom: 14,
      );
      expect(wholeCountry.tileCount, greaterThan(MapAreaDownloader.tileLimit));

      await expectLater(
        MapAreaDownloader(httpClient: _TileServer())
            .download(
              area: wholeCountry,
              source: _source(14),
              targetPath: '/dev/null',
              workingDirectory: Directory.systemTemp,
            )
            .toList(),
        throwsA(isA<MapDownloadException>()),
      );
    });

    test('north is the smaller y, which is easy to get backwards', () {
      final tiles = const MapArea(
        minLongitude: 5.9,
        minLatitude: 47.3,
        maxLongitude: 15.0,
        maxLatitude: 55.1,
        minZoom: 6,
        maxZoom: 6,
      ).tiles().toList();

      expect(tiles, hasLength(6));
      expect(tiles.map((t) => t.y).reduce((a, b) => a < b ? a : b), 20);
      expect(tiles.map((t) => t.y).reduce((a, b) => a > b ? a : b), 22);
    });

    test('an area at the edge of the world stays inside the grid', () {
      final tiles = const MapArea(
        minLongitude: -180,
        minLatitude: -89,
        maxLongitude: 180,
        maxLatitude: 89,
        minZoom: 2,
        maxZoom: 2,
      ).tiles().toList();

      expect(tiles, hasLength(16));
      expect(tiles.every((t) => t.x >= 0 && t.x < 4), isTrue);
      expect(tiles.every((t) => t.y >= 0 && t.y < 4), isTrue);
    });
  });

  group('downloading', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('map_download');
    });
    tearDown(() => dir.delete(recursive: true));

    test('builds an archive the app can open', () async {
      final server = _TileServer();
      final target = '${dir.path}/area.pmtiles';

      final progress =
          await MapAreaDownloader(
                httpClient: server,
                concurrency: 2,
              )
              .download(
                area: _germany,
                source: _source(8),
                targetPath: target,
                workingDirectory: dir,
              )
              .toList();

      expect(progress.last.done, 105);
      expect(progress.last.total, 105);
      expect(server.requested, hasLength(105));

      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(target)),
      );
      addTearDown(archive.close);

      expect(archive.header.maxZoom, 8);
      expect(
        utf8.decode((await archive.tile(6, 33, 20))!),
        'tile at /6/33/20.pbf',
      );

      // Without the layer list the app rejects the archive it just
      // built, because that is how it recognizes the schema.
      final metadata = await archive.metadata();
      expect(
        (metadata['vector_layers']! as List).first,
        containsPair('id', 'water'),
      );
    });

    test('tiles the server has nothing for are counted, not fatal', () async {
      final server = _TileServer(missing: {'/6/33/20.pbf', '/6/34/22.pbf'});
      final target = '${dir.path}/sparse.pmtiles';

      final progress =
          await MapAreaDownloader(
                httpClient: server,
                concurrency: 1,
              )
              .download(
                area: const MapArea(
                  minLongitude: 5.9,
                  minLatitude: 47.3,
                  maxLongitude: 15.0,
                  maxLatitude: 55.1,
                  minZoom: 6,
                  maxZoom: 6,
                ),
                source: _source(8),
                targetPath: target,
                workingDirectory: dir,
              )
              .toList();

      expect(progress.last.missing, 2);
      expect(await File(target).exists(), isTrue);
    });

    test('a failing server leaves no scratch file behind', () async {
      await expectLater(
        MapAreaDownloader(
              httpClient: _TileServer(status: 500),
              concurrency: 2,
            )
            .download(
              area: _germany,
              source: _source(8),
              targetPath: '${dir.path}/broken.pmtiles',
              workingDirectory: dir,
            )
            .toList(),
        throwsA(isA<MapDownloadException>()),
      );

      expect(await File('${dir.path}/broken.pmtiles').exists(), isFalse);
      expect(await File('${dir.path}/tiles.scratch').exists(), isFalse);
    });

    test('asking for more zoom than the source has is refused', () async {
      await expectLater(
        MapAreaDownloader(httpClient: _TileServer())
            .download(
              area: _germany,
              source: _source(6),
              targetPath: '${dir.path}/too_deep.pmtiles',
              workingDirectory: dir,
            )
            .toList(),
        throwsA(isA<MapDownloadException>()),
      );
    });
  });
}

VectorTileSource _source(int maxZoom) => VectorTileSource(
  tileTemplate: 'https://tiles.invalid/{z}/{x}/{y}.pbf',
  minZoom: 0,
  maxZoom: maxZoom,
  vectorLayers: const [
    {'id': 'water'},
    {'id': 'transportation'},
  ],
  attribution: 'OpenStreetMap',
);
