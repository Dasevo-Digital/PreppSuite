import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'geo_bounds.dart';
import '../../../core/http_client.dart';

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
/// carrying `historic`/`disused`/`ruins`); `emergency=shelter` covers the
/// (rare) modern civil-protection tagging. `amenity=shelter` is deliberately
/// not asked for (#338): in OpenStreetMap that is shelter from the weather,
/// a bus stop or a hut at a barbecue site, and the map showed them as
/// possible bunkers.
class OverpassShelterClient {
  OverpassShelterClient({
    http.Client? httpClient,
    Duration? retryDelay,
    Duration? cacheLifetime,
  }) : _ownsClient = httpClient == null,
       _httpClient = httpClient ?? TimeoutClient(),
       _retryDelay = retryDelay ?? defaultRetryDelay,
       _cacheLifetime = cacheLifetime ?? defaultCacheLifetime;

  final http.Client _httpClient;
  final bool _ownsClient;
  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// The main instance first, then two others.
  ///
  /// Not redundancy for its own sake: `overpass-api.de/api/status` states
  /// "Rate limit: 2" — two concurrent queries per IP address — and
  /// answers 429 for the third. Pressing refresh twice is enough to hit
  /// it, which is what "OpenStreetMap/Overpass konnte nicht geladen
  /// werden" was usually reporting. The kumi mirror was confirmed live on
  /// 2026-09-11 and is slower (6.5 s against 0.5 s for the same query),
  /// which is why it is last. private.coffee came in with #366: from 8
  /// November 2026 the main instance answered 502 for days and kumi not
  /// at all. All three are in Germany or Switzerland; instances run by
  /// mail.ru or in Russia are left out, because what goes there is a
  /// search area around somebody's home.
  ///
  /// Even three fail together, as they did on 12 November. The
  /// defibrillator and emergency-point searches ask QLever
  /// (`osm_point_sources.dart`), which is not an Overpass at all, right
  /// after the main instance and before the other two (`askNearbyPoints`).
  static const endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.private.coffee/api/interpreter',
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
        ');'
        'out center $_resultLimit;';

    final response = await _ask(query);
    final elements = overpassElements(utf8.decode(response.bodyBytes));

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
///
/// [timeout] is per instance. A screen somebody is waiting at in an
/// emergency can ask for less than the thirty seconds a map can afford.
Future<http.Response> askOverpass(
  http.Client httpClient,
  String query, {
  Duration retryDelay = OverpassShelterClient.defaultRetryDelay,
  Duration timeout = const Duration(seconds: 30),
  Iterable<String> endpoints = OverpassShelterClient.endpoints,
}) async {
  OverpassException? last;
  Object? failure;
  // Whether any instance was there at all: answered, or took the request
  // and ran out of time. With one instance the last error said that on
  // its own; with three, a single one whose name no longer resolves
  // would have turned "the service is down" into "no connection" (#366).
  var reached = false;

  for (final endpoint in endpoints) {
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
            .timeout(timeout);
      } on Object catch (error) {
        // A dead instance is worth moving on from, not retrying.
        failure = error;
        if (error is! SocketException) reached = true;
        break;
      }

      reached = true;
      if (response.statusCode == 200) {
        if (!overpassGaveUp(response.bodyBytes)) return response;
        // Said 200 and gave up on the query: another instance may not.
        last = const OverpassException(200);
        break;
      }

      last = OverpassException(response.statusCode);
      if (!last.isBusy) break;
    }
  }

  throw last ?? OverpassException(0, cause: failure, reachedAny: reached);
}

/// Whether an answer with status 200 says that Overpass gave up on the
/// query. It reports its own time limit or memory running out -- under
/// load, for a query that is normally done in a second -- not with an
/// error status but with 200, whatever elements it had by then, and a
/// remark at the end: `"remark": "runtime error: Query timed out in
/// "query" at line 1 after 26 seconds."`. Read as an answer, that is
/// "nothing near", and it replaced a good last search (#366).
///
/// Only the end is read, where the remark stands, so that a large answer
/// is not decoded twice; [overpassElements] looks at the whole.
bool overpassGaveUp(Uint8List bytes) {
  final tail = utf8.decode(
    bytes.sublist(math.max(0, bytes.length - 4096)),
    allowMalformed: true,
  );
  return _gaveUpRemark.hasMatch(tail);
}

final _gaveUpRemark = RegExp(
  r'"remark"\s*:\s*"runtime error|<remark>\s*runtime error',
);

/// The `elements` of an Overpass answer in JSON. Throws an
/// [OverpassException] with status 200 for an answer that is not one: not
/// JSON (a sign-in page of a hotel network, a body cut short), no list of
/// elements, or the remark of [overpassGaveUp]. Each of them used to read
/// as an empty list, which a screen shows as "nothing near".
List<Object?> overpassElements(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    throw const OverpassException(200);
  }
  if (decoded is! Map) throw const OverpassException(200);
  final remark = decoded['remark'];
  if (remark is String && remark.contains('runtime error')) {
    throw const OverpassException(200);
  }
  final elements = decoded['elements'];
  if (elements is! List) throw const OverpassException(200);
  return elements;
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
  const OverpassException(
    this.statusCode, {
    this.cause,
    this.reachedAny = false,
  });

  /// The HTTP status, or 0 when no instance answered at all. 200 is an
  /// answer that was not one: the query given up on, or not the JSON
  /// asked for (see [overpassElements]).
  final int statusCode;

  /// Why no instance answered, when none did: the last error on the way.
  final Object? cause;

  /// Whether one of the instances was there at all -- answered, or took
  /// the request and ran out of time -- although none gave an answer.
  final bool reachedAny;

  /// Whether this device could not reach any instance at all, as opposed
  /// to reaching them and getting no answer in time. Only the first is
  /// "no connection"; saying so for the second sends somebody to look at
  /// a network that works (#217). Every instance has to have been out of
  /// reach, not only the last one asked (#366).
  bool get noNetwork =>
      statusCode == 0 && cause is SocketException && !reachedAny;

  /// Whether this is the rate limit or their own query timeout — the two
  /// that are about the moment rather than the request.
  bool get isBusy => statusCode == 429 || statusCode == 504;

  @override
  String toString() => cause == null
      ? 'OverpassException($statusCode)'
      : 'OverpassException($statusCode, ${cause.runtimeType}: $cause)';
}
