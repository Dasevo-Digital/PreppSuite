import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'map_download_plan.dart';
import 'pmtiles_archive.dart' show tileIdFor;
import 'pmtiles_writer.dart';
import 'tile_source.dart';
import '../../../core/http_client.dart';

/// A rectangle of the world at a range of zoom levels.
class MapArea {
  const MapArea({
    required this.minLongitude,
    required this.minLatitude,
    required this.maxLongitude,
    required this.maxLatitude,
    required this.maxZoom,
    this.minZoom = 0,
  });

  final double minLongitude;
  final double minLatitude;
  final double maxLongitude;
  final double maxLatitude;

  /// Always fetched from zoom 0 by default: the low levels are a handful
  /// of tiles and without them the map is blank until it is zoomed in.
  final int minZoom;

  final int maxZoom;

  /// How many tiles this comes to — the number that decides whether an
  /// area is reasonable to ask a free tile server for.
  int get tileCount {
    var count = 0;
    for (var z = minZoom; z <= maxZoom; z++) {
      final range = _rangeAt(z);
      count += (range.maxX - range.minX + 1) * (range.maxY - range.minY + 1);
    }
    return count;
  }

  /// The whole planet, at the zoom levels worth having everywhere.
  ///
  /// Without this a download only ever holds the tiles its own box
  /// touched — and at zoom 3 a single tile already spans Barcelona to
  /// Warsaw. Zoomed out, the map was one square floating in empty grey,
  /// with nothing beside it to draw.
  ///
  /// It is affordable precisely because it is the low levels: zoom 0 to
  /// 4 is 341 tiles for the entire world, against a budget of a hundred
  /// thousand. The cut is at 4 because that is roughly where one tile
  /// stops filling a desktop window on its own.
  static const worldBaseZoom = 4;

  static MapArea world({int from = 0, int to = worldBaseZoom}) => MapArea(
    minLongitude: -180,
    minLatitude: -85.05,
    maxLongitude: 180,
    maxLatitude: 85.05,
    minZoom: from,
    maxZoom: to,
  );

  /// The same box over a different range of zoom levels.
  MapArea band(int from, int to) => MapArea(
    minLongitude: minLongitude,
    minLatitude: minLatitude,
    maxLongitude: maxLongitude,
    maxLatitude: maxLatitude,
    minZoom: from,
    maxZoom: to,
  );

  MapArea withDetail(int detail) => MapArea(
    minLongitude: minLongitude,
    minLatitude: minLatitude,
    maxLongitude: maxLongitude,
    maxLatitude: maxLatitude,
    minZoom: minZoom,
    maxZoom: detail,
  );

  /// Every tile in the area, low zoom levels first.
  Iterable<({int z, int x, int y})> tiles() sync* {
    for (var z = minZoom; z <= maxZoom; z++) {
      final range = _rangeAt(z);
      for (var x = range.minX; x <= range.maxX; x++) {
        for (var y = range.minY; y <= range.maxY; y++) {
          yield (z: z, x: x, y: y);
        }
      }
    }
  }

  ({int minX, int minY, int maxX, int maxY}) _rangeAt(int zoom) {
    final side = 1 << zoom;
    int clamp(int value) => value < 0 ? 0 : (value >= side ? side - 1 : value);

    // Y grows southwards, so the northern edge gives the smaller index.
    return (
      minX: clamp(_longitudeToX(minLongitude, zoom)),
      maxX: clamp(_longitudeToX(maxLongitude, zoom)),
      minY: clamp(_latitudeToY(maxLatitude, zoom)),
      maxY: clamp(_latitudeToY(minLatitude, zoom)),
    );
  }

  static int _longitudeToX(double longitude, int zoom) =>
      ((longitude + 180) / 360 * (1 << zoom)).floor();

  static int _latitudeToY(double latitude, int zoom) {
    // Web Mercator, which is what every {z}/{x}/{y} scheme means.
    final clamped = latitude.clamp(-85.05112878, 85.05112878);
    final radians = clamped * pi / 180;
    return ((1 - log(tan(radians) + 1 / cos(radians)) / pi) / 2 * (1 << zoom))
        .floor();
  }
}

/// The deepest detail level [area] still fits [limit] at, or null if even
/// [lowest] is too much.
///
/// This is what makes "a whole Bundesland at the highest detail level" a
/// question with an answer rather than a slider to guess at: the levels
/// differ by a factor of four each, so the one that fits is never obvious
/// and being one off means tens of thousands of tiles.
int? deepestDetailWithin(
  MapArea area, {
  int? limit,
  int? budget,
  int lowest = 8,
  int highest = 14,
}) {
  final ceiling = budget ?? limit ?? MapAreaDownloader.tileLimit;
  for (var detail = highest; detail >= lowest; detail--) {
    if (area.withDetail(detail).tileCount <= ceiling) return detail;
  }
  return null;
}

/// How far a map download has got.
class MapDownloadProgress {
  const MapDownloadProgress({
    required this.done,
    required this.total,
    required this.bytes,
    required this.missing,
  });

  final int done;
  final int total;

  /// Tile bytes stored so far, so the size can be shown as it grows —
  /// there is no way to know it in advance.
  final int bytes;

  /// Tiles the server had nothing for. Ordinary rather than an error: a
  /// vector set is sparse where there is nothing to draw.
  final int missing;

  double get fraction => total == 0 ? 0 : done / total;
}

class MapDownloadException implements Exception {
  const MapDownloadException(this.message);

  final String message;

  @override
  String toString() => 'MapDownloadException: $message';
}

/// Builds an offline map archive by fetching an area's tiles.
///
/// There is no ready-made archive to download in the schema this app
/// draws — the ones circulating are Protomaps schema and would come out
/// blank. So the archive is assembled here from a tile server that speaks
/// OpenMapTiles, which is also the only way to get an extract of exactly
/// the area someone cares about.
class MapAreaDownloader {
  MapAreaDownloader({http.Client? httpClient, this.concurrency = 4})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  /// How many tiles are in flight at once. Small on purpose: these are
  /// public servers run for other people too, and the download is
  /// measured in thousands of requests.
  final int concurrency;

  /// Above this an area is refused rather than started.
  ///
  /// Set so that every German Bundesland fits at the deepest level the
  /// sources offer — the largest, Bayern, comes to 68,028 tiles at zoom
  /// 14 — and a whole country does not: Germany would be 317,618, some
  /// fourteen gigabytes and as many requests, which is not something to
  /// ask of a tile server run for other people.
  static const tileLimit = 100000;

  /// Fetches the plan's tiles and assembles the archive at [targetPath].
  ///
  /// With [resume] the tiles a previous run already stored are skipped
  /// and its scratch file is added to rather than replaced. Without it,
  /// anything half-finished in [workingDirectory] is thrown away first.
  Stream<MapDownloadProgress> download({
    required MapDownloadPlan plan,
    required VectorTileSource source,
    required String targetPath,
    required Directory workingDirectory,
    bool resume = false,
  }) async* {
    if (plan.maxZoom > source.maxZoom) {
      throw MapDownloadException(
        'this source only goes to zoom ${source.maxZoom}',
      );
    }
    final total = plan.tileCount;
    if (total > tileLimit) {
      throw MapDownloadException('$total tiles is more than $tileLimit');
    }

    final writer = resume
        ? await PmTilesWriter.resume(workingDirectory)
        : await PmTilesWriter.create(workingDirectory);

    final alreadyStored = writer.storedTileIds;
    final queue = [
      for (final tile in plan.tiles())
        if (!alreadyStored.contains(tileIdFor(tile.z, tile.x, tile.y))) tile,
    ];

    // What a previous run finished counts towards the total, or the bar
    // would start at zero on a download that is nearly done.
    final carried = total - queue.length;

    var done = carried;
    var missing = 0;
    var next = 0;
    var complete = false;

    Object? failure;
    StackTrace? failureTrace;

    // A handful of workers off one queue: a tile request is almost all
    // waiting, so one at a time would take many times as long — and many
    // at once would be rude to a server run for other people too.
    //
    // A worker keeps its own failure rather than throwing, so that one
    // bad tile stops the others instead of leaving their futures
    // unhandled.
    Future<void> worker() async {
      while (true) {
        final index = next++;
        if (index >= queue.length) return;
        final tile = queue[index];

        try {
          final response = await _httpClient.get(
            source.tileUrl(tile.z, tile.x, tile.y),
          );

          // The status decides first. An empty body is only "nothing to
          // draw here" when the server said the request was fine —
          // reading an empty 503 the same way would fill a map with
          // holes and call it finished.
          if (response.statusCode == 404 || response.statusCode == 204) {
            // Ordinary rather than an error: a vector set is sparse
            // wherever there is nothing to draw.
            missing++;
          } else if (response.statusCode != 200) {
            throw MapDownloadException(
              'the tile server answered ${response.statusCode}',
            );
          } else if (response.bodyBytes.isEmpty) {
            missing++;
          } else {
            await writer.add(tile.z, tile.x, tile.y, response.bodyBytes);
          }
          done++;
        } on Object catch (error, trace) {
          failure ??= error;
          failureTrace ??= trace;
          next = queue.length;
          return;
        }
      }
    }

    try {
      var running = true;
      final workers = Future.wait([
        for (var i = 0; i < concurrency; i++) worker(),
      ]).whenComplete(() => running = false);

      while (running) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        yield MapDownloadProgress(
          done: done,
          total: total,
          bytes: writer.dataLength,
          missing: missing,
        );
      }
      await workers;

      if (failure != null) {
        Error.throwWithStackTrace(failure!, failureTrace!);
      }
      if (writer.tileCount == 0) {
        throw const MapDownloadException(
          'the server had no tiles for this area',
        );
      }

      await writer.finish(
        path: targetPath,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
        minLongitude: plan.minLongitude,
        minLatitude: plan.minLatitude,
        maxLongitude: plan.maxLongitude,
        maxLatitude: plan.maxLatitude,
        metadata: {
          'name': 'PreppSuite',
          'format': 'pbf',
          'type': 'baselayer',
          'vector_layers': source.vectorLayers,
          if (source.attribution != null) 'attribution': source.attribution,
        },
      );
      complete = true;

      yield MapDownloadProgress(
        done: done,
        total: total,
        bytes: writer.dataLength,
        missing: missing,
      );
    } finally {
      // Also reached when the subscriber cancels, which stops the workers
      // at their next tile. The working files stay: cancelling is how a
      // download of an hour gets paused, and throwing the tiles away
      // would make pausing the same as starting over.
      next = queue.length;
      if (!complete) await writer.close();
    }
  }
}
