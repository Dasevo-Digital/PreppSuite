import 'dart:convert';

import 'package:http/http.dart' as http;

import 'geo_bounds.dart';

/// A bunker/shelter-tagged OpenStreetMap element (node or way — ways are
/// requested with `out center`, so both shapes end up with a single
/// lat/lon). Keeps the raw `tags` map so `shelter_classification.dart` can
/// inspect things like `historic`/`disused`/`ruins`/`access` — response
/// shape confirmed live against `overpass-api.de/api/interpreter` on
/// 2026-08-14.
class OverpassShelterFeature {
  const OverpassShelterFeature({
    required this.id,
    required this.lat,
    required this.lon,
    required this.tags,
  });

  final int id;
  final double lat;
  final double lon;
  final Map<String, String> tags;

  String? get name => tags['name'];
}

/// Queries the public, key-less Overpass API for OSM elements tagged as a
/// bunker or shelter. `military`/`building=bunker` covers most German
/// Cold-War-era bunkers (per the confirmed-live sample query, usually also
/// carrying `historic`/`disused`/`ruins`); `emergency`/`amenity=shelter`
/// covers the (rare) modern civil-protection tagging.
class OverpassShelterClient {
  OverpassShelterClient({http.Client? httpClient})
    : _ownsClient = httpClient == null,
      _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Caps the number of returned elements — a 50 km radius in a dense area
  /// could otherwise return more markers than the map can usefully show.
  static const _resultLimit = 300;

  Future<List<OverpassShelterFeature>> fetchShelters(
    GeoBoundingBox bounds,
  ) async {
    // Overpass bbox order is (south,west,north,east).
    final bbox =
        '${bounds.south},${bounds.west},${bounds.north},${bounds.east}';
    final query =
        '[out:json][timeout:25];'
        '('
        'node["military"="bunker"]($bbox);'
        'way["military"="bunker"]($bbox);'
        'node["building"="bunker"]($bbox);'
        'way["building"="bunker"]($bbox);'
        'node["emergency"="shelter"]($bbox);'
        'node["amenity"="shelter"]($bbox);'
        ');'
        'out center $_resultLimit;';

    final response = await _httpClient
        .post(
          Uri.parse(_endpoint),
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Shelter service returned ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return [];
    final elements = decoded['elements'];
    if (elements is! List) return [];

    return [
      for (final entry in elements)
        if (entry is Map<String, dynamic>) _parseElement(entry),
    ].whereType<OverpassShelterFeature>().toList();
  }

  OverpassShelterFeature? _parseElement(Map<String, dynamic> entry) {
    final id = entry['id'] as int?;
    if (id == null) return null;

    // Nodes carry lat/lon directly; ways carry a `center` (requested via
    // `out center`).
    double? lat = (entry['lat'] as num?)?.toDouble();
    double? lon = (entry['lon'] as num?)?.toDouble();
    final center = entry['center'];
    if ((lat == null || lon == null) && center is Map) {
      lat = (center['lat'] as num?)?.toDouble();
      lon = (center['lon'] as num?)?.toDouble();
    }
    if (lat == null || lon == null) return null;

    final rawTags = entry['tags'];
    final tags = <String, String>{
      if (rawTags is Map)
        for (final entry in rawTags.entries) '${entry.key}': '${entry.value}',
    };

    return OverpassShelterFeature(id: id, lat: lat, lon: lon, tags: tags);
  }
}
