import 'dart:convert';

import 'package:http/http.dart' as http;

import 'map_area_download.dart';
import '../../../core/http_client.dart';

/// A place someone can download the map of.
class PlaceResult {
  const PlaceResult({
    required this.name,
    required this.description,
    required this.kind,
    this.stateName,
    this.countryName,
    required this.minLongitude,
    required this.minLatitude,
    required this.maxLongitude,
    required this.maxLatitude,
  });

  /// The place's own name, e.g. "Hannover".
  final String name;

  /// Where it is, e.g. "Hannover, Region Hannover, Niedersachsen,
  /// Deutschland" — what tells two places of the same name apart, and
  /// there is always more than one.
  final String description;

  /// Nominatim's `addresstype`: `city`, `state`, `country`, `suburb` and
  /// so on. Shown as-is rather than translated, because the list of
  /// possible values is long and open-ended.
  final String kind;

  /// The Bundesland (or equivalent) this place sits in, and the country,
  /// as Nominatim's address breakdown gives them. They are names, not
  /// boxes — [PlaceSearchClient.resolve] turns one into the other, which
  /// is what a staggered download needs to draw its outer rings.
  final String? stateName;
  final String? countryName;

  final double minLongitude;
  final double minLatitude;
  final double maxLongitude;
  final double maxLatitude;

  /// The place's outline as an area to download, at [maxZoom].
  ///
  /// A bounding box, not the border: downloading a state fetches the
  /// corners of its neighbours too. Clipping to the real outline would
  /// mean carrying the polygon and testing every tile against it, for a
  /// saving that on a rectangle roughly the shape of the place is small.
  MapArea areaAt(int maxZoom) => MapArea(
    minLongitude: minLongitude,
    minLatitude: minLatitude,
    maxLongitude: maxLongitude,
    maxLatitude: maxLatitude,
    maxZoom: maxZoom,
  );
}

class PlaceSearchException implements Exception {
  const PlaceSearchException(this.message);

  final String message;

  @override
  String toString() => 'PlaceSearchException: $message';
}

/// Finds a place by name and, more to the point, its bounding box.
///
/// Nominatim is OpenStreetMap's own geocoder: free, key-less, and already
/// what this app uses to turn a position into a Bundesland. Its usage
/// policy asks for an identifying User-Agent and no more than one request
/// a second, which a search box driven by a person stays well inside.
class PlaceSearchClient {
  PlaceSearchClient({http.Client? httpClient})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  static const _userAgent = 'PreppSuite/1.0';

  /// Places matching [query], best match first. An empty list is an
  /// ordinary answer; only an unreachable service is an error.
  Future<List<PlaceResult>> search(
    String query, {
    String language = 'de',
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'format': 'jsonv2',
      'q': trimmed,
      'limit': '$limit',
      'addressdetails': '1',
      'accept-language': language,
    });

    final response = await _httpClient.get(
      uri,
      headers: const {'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw PlaceSearchException(
        'the geocoder answered ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! List) return const [];

    return [
      for (final entry in decoded)
        if (entry is Map<String, Object?>) ?_parse(entry),
    ];
  }

  /// The first match for [name], for turning a state or country name
  /// from an address breakdown back into a box.
  Future<PlaceResult?> resolve(String name, {String language = 'de'}) async {
    final results = await search(name, language: language, limit: 1);
    return results.isEmpty ? null : results.first;
  }

  /// Nominatim gives the box as four strings in the order
  /// `[minLat, maxLat, minLon, maxLon]` — latitudes first, which is the
  /// opposite of every other coordinate pair in this codebase.
  static PlaceResult? _parse(Map<String, Object?> entry) {
    final box = entry['boundingbox'];
    if (box is! List || box.length != 4) return null;

    final numbers = [for (final value in box) double.tryParse('$value')];
    if (numbers.any((value) => value == null)) return null;

    final display = '${entry['display_name'] ?? ''}';
    final address = entry['address'];
    String? part(String key) {
      if (address is! Map) return null;
      final value = address[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return PlaceResult(
      name: '${entry['name'] ?? display}',
      description: display,
      kind: '${entry['addresstype'] ?? entry['type'] ?? ''}',
      // "state" is missing for city states and for places outside a
      // federal country; the ring is then simply left out.
      stateName: part('state') ?? part('county'),
      countryName: part('country'),
      minLatitude: numbers[0]!,
      maxLatitude: numbers[1]!,
      minLongitude: numbers[2]!,
      maxLongitude: numbers[3]!,
    );
  }
}
