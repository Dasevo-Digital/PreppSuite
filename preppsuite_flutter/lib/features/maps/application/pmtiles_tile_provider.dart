import 'dart:typed_data';

import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'pmtiles_archive.dart';

/// Serves vector tiles out of a local PMTiles archive.
///
/// The whole point of the offline map: the renderer asks for a tile the
/// same way it would from a server, and gets it from a file instead. No
/// network, no key, no tile server.
class PmTilesVectorTileProvider implements VectorTileProvider {
  PmTilesVectorTileProvider(this.archive);

  final PmTilesArchive archive;

  @override
  int get minimumZoom => archive.header.minZoom;

  @override
  int get maximumZoom => archive.header.maxZoom;

  /// OpenMapTiles ships 512-pixel tiles, so one tile covers what two
  /// zoom levels of 256-pixel tiles would. Without this the map reads
  /// four times as many tiles and renders everything at half the size.
  @override
  TileOffset get tileOffset => TileOffset.mapbox;

  @override
  TileProviderType get type => TileProviderType.vector;

  @override
  Future<Uint8List> provide(TileIdentity tile) async {
    final Uint8List? bytes;
    try {
      bytes = await archive.tile(tile.z, tile.x, tile.y);
    } on PmTilesException catch (error) {
      // Damaged or past the size limit: asking again reads the same bytes.
      throw _damaged(error);
    } on FormatException catch (error) {
      // A gzip stream that is not one.
      throw _damaged(error);
    } on ArgumentError catch (error) {
      // A RangeError included: a number in the file no check has thought
      // of yet is the same damage (#327).
      throw _damaged(error);
    }
    if (bytes == null) {
      // An extract covers a region; asking past its edge is what panning
      // does. Not retryable — the tile will not appear on a second look.
      throw ProviderException(
        message: 'no tile at ${tile.key()}',
        statusCode: 404,
        retryable: Retryable.none,
      );
    }
    return bytes;
  }

  static ProviderException _damaged(Object error) => ProviderException(
    message: '$error',
    statusCode: 422,
    retryable: Retryable.none,
  );
}
