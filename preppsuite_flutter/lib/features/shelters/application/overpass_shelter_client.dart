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
  OverpassShelterClient({
    http.Client? httpClient,
    Duration? retryDelay,
    Duration? cacheLifetime,
  }) : _ownsClient = httpClient == null,
       _httpClient = httpClient ?? http.Client(),
       _retryDelay = retryDelay ?? defaultRetryDelay,
       _cacheLifetime = cacheLifetime ?? defaultCacheLifetime;

  final http.Client _httpClient;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// The main instance first, then a mirror.
  ///
  /// Not redundancy for its own sake: `overpass-api.de/api/status` states
  /// "Rate limit: 2" — two concurrent queries per IP address — and
  /// answers 429 for the third. Pressing refresh twice is enough to hit
  /// it, which is what "OpenStreetMap/Overpass konnte nicht geladen
  /// werden" was usually reporting. Both were confirmed live on
  /// 2026-09-11; the mirror is slower (6.5 s against 0.5 s for the same
  /// query) which is why it is second and not first.
  static const endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  /// How long to wait before asking the same instance again.
  ///
  /// A refused slot frees up in seconds, and the whole search sits behind
  /// a 30-second timeout, so there is room for exactly one pause.
  /// Injectable so the tests can take it out: three real seconds per case
  /// is most of the suite's running time and none of its meaning.
  static const defaultRetryDelay = Duration(seconds: 3);

  /// A refresh should not turn a person pressing the button twice into two
  /// identical public Overpass queries. Coordinates stay only in this
  /// in-memory, per-screen cache; nothing is persisted.
  static const defaultCacheLifetime = Duration(minutes: 2);

  final Duration _retryDelay;
  final Duration _cacheLifetime;
  final _cache = <String, _CachedShelters>{};
  final _inFlight = <String, Future<List<OverpassShelterFeature>>>{};

  /// Caps the number of returned elements — a 50 km radius in a dense area
  /// could otherwise return more markers than the map can usefully show.
  static const _resultLimit = 300;

  Future<List<OverpassShelterFeature>> fetchShelters(
    GeoBoundingBox bounds,
  ) async {
    final cacheKey = _cacheKey(bounds);
    final cached = _cache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.savedAt) < _cacheLifetime) {
      return cached.features;
    }

    // Flutter's HTTP requests cannot be reliably cancelled on every target.
    // Sharing the first request is therefore both gentler to Overpass and
    // safer than sending a replacement while the earlier request is still
    // occupying one of its two public slots.
    final running = _inFlight[cacheKey];
    if (running != null) return running;

    final request = _fetchShelters(bounds).then((features) {
      _cache[cacheKey] = _CachedShelters(DateTime.now(), features);
      return features;
    });
    _inFlight[cacheKey] = request;
    return request.whenComplete(() {
      if (identical(_inFlight[cacheKey], request)) {
        _inFlight.remove(cacheKey);
      }
    });
  }

  String _cacheKey(GeoBoundingBox bounds) =>
      '${bounds.south.toStringAsFixed(5)},'
      '${bounds.west.toStringAsFixed(5)},'
      '${bounds.north.toStringAsFixed(5)},'
      '${bounds.east.toStringAsFixed(5)}';

  Future<List<OverpassShelterFeature>> _fetchShelters(
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

    final response = await _ask(query);
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) return [];
    final elements = decoded['elements'];
    if (elements is! List) return [];

    return [
      for (final entry in elements)
        if (entry is Map<String, dynamic>) _parseElement(entry),
    ].whereType<OverpassShelterFeature>().toList();
  }

  Future<http.Response> _ask(String query) =>
      askOverpass(_httpClient, query, retryDelay: _retryDelay);

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

/// Sends [query] to the public Overpass instances, once per attempt,
/// until one answers. Shared by every feature that asks OpenStreetMap,
/// so the rate limit is respected in one place.
///
/// Only a busy instance is worth asking again: 429 is the rate limit
/// and 504 is the query timing out on their side, and both are about
/// the moment rather than the request. Anything else is a bad request
/// or a broken instance, where a second identical try is just another
/// request against a server run for other people.
Future<http.Response> askOverpass(
  http.Client httpClient,
  String query, {
  Duration retryDelay = OverpassShelterClient.defaultRetryDelay,
}) async {
  OverpassException? last;

  for (final endpoint in OverpassShelterClient.endpoints) {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) await Future<void>.delayed(retryDelay);

      final http.Response response;
      try {
        response = await httpClient
            .post(
              Uri.parse(endpoint),
              // Without a name of its own a request goes out as
              // "Dart/3.x (dart:io)", and overpass-api.de answers that with
              // 406 since autumn 2026 -- measured on 2026-10-06, the same
              // query with this header answered 200. Nominatim has asked for
              // the same thing all along.
              headers: {'User-Agent': 'PreppSuite/1.0'},
              body: {'data': query},
            )
            .timeout(const Duration(seconds: 30));
      } on Object {
        // A dead instance is worth moving on from, not retrying.
        break;
      }

      if (response.statusCode == 200) return response;

      last = OverpassException(response.statusCode);
      if (!last.isBusy) break;
    }
  }

  throw last ?? const OverpassException(0);
}

class _CachedShelters {
  const _CachedShelters(this.savedAt, this.features);

  final DateTime savedAt;
  final List<OverpassShelterFeature> features;
}

/// An Overpass instance that would not answer, and with what.
///
/// A type rather than a `ClientException` with the code in its message,
/// because the screen has to tell two things apart: the service being
/// momentarily full, which resolves itself, and the service being
/// unreachable, which does not. The shelter screen used to report both
/// as one sentence with no reason in it at all.
class OverpassException implements Exception {
  const OverpassException(this.statusCode);

  /// The HTTP status, or 0 when no instance answered at all.
  final int statusCode;

  /// Whether this is the rate limit or their own query timeout — the two
  /// that are about the moment rather than the request.
  bool get isBusy => statusCode == 429 || statusCode == 504;

  @override
  String toString() => 'OverpassException($statusCode)';
}
