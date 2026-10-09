import 'dart:convert';

import 'package:http/http.dart' as http;
import '../../../core/http_client.dart';

/// Where vector tiles can be fetched from.
///
/// Both known sources describe themselves in TileJSON, so there is one
/// client rather than one per provider — and the tile URL is read from
/// that description rather than compiled in, because OpenFreeMap dates
/// its paths and moves them with every planet build.
class VectorTileSource {
  const VectorTileSource({
    required this.tileTemplate,
    required this.minZoom,
    required this.maxZoom,
    required this.vectorLayers,
    this.attribution,
  });

  /// Contains `{z}`, `{x}` and `{y}`.
  final String tileTemplate;

  final int minZoom;
  final int maxZoom;

  /// The source's own layer list, copied into the archive's metadata.
  /// Without it the app refuses the archive it just built, because that
  /// list is how an OpenMapTiles schema is told from a Protomaps one.
  final List<Object?> vectorLayers;

  final String? attribution;

  Uri tileUrl(int z, int x, int y) => Uri.parse(
    tileTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y'),
  );
}

/// Which provider a download comes from.
enum MapTileProvider {
  /// Free and key-less, OpenMapTiles schema, built from OpenStreetMap.
  openFreeMap,

  /// Needs an account. Its `tiles/v3` set is the OpenMapTiles schema too,
  /// so an archive built from it renders with the same style.
  mapTiler,
}

class TileSourceException implements Exception {
  const TileSourceException(this.message);

  final String message;

  @override
  String toString() => 'TileSourceException: $message';
}

/// Reads a provider's TileJSON.
class TileSourceClient {
  TileSourceClient({http.Client? httpClient})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  static const openFreeMapUrl = 'https://tiles.openfreemap.org/planet';
  static const _mapTilerUrl = 'https://api.maptiler.com/tiles/v3/tiles.json';

  /// The description for [provider]. [apiKey] is required for providers
  /// that have one and ignored by those that do not.
  Future<VectorTileSource> load(
    MapTileProvider provider, {
    String? apiKey,
  }) async {
    final url = switch (provider) {
      MapTileProvider.openFreeMap => Uri.parse(openFreeMapUrl),
      MapTileProvider.mapTiler => Uri.parse(
        _mapTilerUrl,
      ).replace(queryParameters: {'key': apiKey ?? ''}),
    };

    if (provider == MapTileProvider.mapTiler &&
        (apiKey == null || apiKey.isEmpty)) {
      throw const TileSourceException('this provider needs a key');
    }

    final response = await _httpClient.get(url);
    if (response.statusCode != 200) {
      throw TileSourceException('the provider answered ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, Object?>) {
      throw const TileSourceException('the provider sent no description');
    }

    final tiles = decoded['tiles'];
    if (tiles is! List || tiles.isEmpty || tiles.first is! String) {
      throw const TileSourceException('the description names no tile URL');
    }

    final layers = decoded['vector_layers'];
    if (layers is! List || layers.isEmpty) {
      // Without this the archive cannot declare its schema, and the app
      // would reject its own download when it was chosen.
      throw const TileSourceException('the description names no layers');
    }

    return VectorTileSource(
      tileTemplate: tiles.first as String,
      minZoom: (decoded['minzoom'] as num?)?.toInt() ?? 0,
      maxZoom: (decoded['maxzoom'] as num?)?.toInt() ?? 14,
      vectorLayers: layers,
      attribution: decoded['attribution'] as String?,
    );
  }
}
