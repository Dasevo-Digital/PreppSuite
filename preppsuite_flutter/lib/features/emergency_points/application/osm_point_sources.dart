/// Defibrillators and emergency points from OpenStreetMap, by another way
/// than Overpass (#366).
///
/// From 8 November 2026 the public Overpass instances answered 502 or
/// nothing for days, and on 12 November all three the app knows failed
/// together. The searches near a place then had nothing to offer but the
/// last list they had kept. QLever, run by the University of Freiburg,
/// holds the same OpenStreetMap data behind a SPARQL interface and was
/// answering in well under a second throughout: it is the second way for
/// a search near a place, and the first for the region a map download
/// covers, where an Overpass query of that size would be turned away.
///
/// What goes there is what goes to Overpass: a box around a grid point
/// for a search (`gridCircle`), or the box of the offline map.
library;

import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import '../../first_aid/application/defibrillators.dart';
import '../../shelters/application/geo_bounds.dart';
import '../../shelters/application/overpass_shelter_client.dart';
import 'emergency_points.dart';

/// What OpenStreetMap has in one box: the defibrillators and the three
/// kinds of emergency point.
class NearbyPointSet {
  const NearbyPointSet({
    this.defibrillators = const [],
    this.points = const [],
  });

  final List<Defibrillator> defibrillators;
  final List<EmergencyPoint> points;

  int get length => defibrillators.length + points.length;
}

/// The `emergency=*` values asked for: the defibrillators and every
/// [EmergencyPointKind].
final emergencyTags = [
  'defibrillator',
  for (final kind in EmergencyPointKind.values) kind.tag,
];

/// The tags the two screens read, and no more. A point in OpenStreetMap
/// can carry dozens -- phone numbers, photos, wheelchair access, the
/// operator's website -- and for every defibrillator in Germany those
/// would be most of the download (#366).
const osmPointKeys = [
  'emergency',
  'name',
  'official_name',
  'operator',
  'ref',
  'official_ref',
  'addr:full',
  'addr:street',
  'addr:housenumber',
  'contact:full',
  'contact:street',
  'contact:housenumber',
  'opening_hours',
  'level',
  'indoor',
  'access',
  'defibrillator:location',
  'defibrillator:location:de',
  'defibrillator:location:en',
  'defibrillator:location:es',
  'description',
  'description:de',
  'description:en',
  'description:es',
  'pump:status',
  'operational_status',
  'siren:range',
];

/// The tags of a point, cut down to [osmPointKeys].
Map<String, String> keptTags(Map<String, String> tags) => {
  for (final key in osmPointKeys) key: ?tags[key],
};

/// Sorts what came back into its two kinds. Anything without one of the
/// four `emergency` values is dropped.
NearbyPointSet pointSetOf(
  Iterable<({int id, double lat, double lon, Map<String, String> tags})>
  elements,
) {
  final defibrillators = <Defibrillator>[];
  final points = <EmergencyPoint>[];
  for (final element in elements) {
    final tags = keptTags(element.tags);
    final emergency = tags['emergency'];
    if (emergency == 'defibrillator') {
      defibrillators.add(
        Defibrillator(
          id: element.id,
          latitude: element.lat,
          longitude: element.lon,
          tags: tags,
        ),
      );
    } else if (EmergencyPointKind.fromTag(emergency) case final kind?) {
      points.add(
        EmergencyPoint(
          id: element.id,
          kind: kind,
          latitude: element.lat,
          longitude: element.lon,
          tags: tags,
        ),
      );
    }
  }
  return NearbyPointSet(defibrillators: defibrillators, points: points);
}

/// QLever's endpoint for the whole planet. The one for Germany alone
/// answered 503 when this was written; the planet one is no slower for a
/// box, because the box is what it filters on.
const qleverEndpoint = 'https://qlever.dev/api/osm-planet';

/// QLever did not answer, or not with a table.
class QleverException implements Exception {
  const QleverException(this.statusCode, {this.cause});

  /// The HTTP status, 200 for an answer that was not the table asked for,
  /// or 0 when none came.
  final int statusCode;
  final Object? cause;

  bool get unreachable => statusCode == 0 && cause is SocketException;

  @override
  String toString() => cause == null
      ? 'QleverException($statusCode)'
      : 'QleverException($statusCode, ${cause.runtimeType}: $cause)';
}

/// The SPARQL query for every point in [box]: one row per point and tag,
/// tab-separated, which for all of Germany is about 26 MB against several
/// times that as JSON.
String qleverQuery(GeoBoundingBox box) {
  String degrees(double value) => value.toStringAsFixed(5);
  final kinds = emergencyTags.map((tag) => '"$tag"').join(' ');
  final keys = osmPointKeys.map((key) => 'osmkey:$key').join(' ');
  return '''
PREFIX osmkey: <https://www.openstreetmap.org/wiki/Key:>
PREFIX geo: <http://www.opengis.net/ont/geosparql#>
PREFIX geof: <http://www.opengis.net/def/function/geosparql/>
SELECT ?node ?wkt ?key ?value WHERE {
  VALUES ?kind { $kinds }
  ?node osmkey:emergency ?kind .
  ?node geo:hasGeometry/geo:asWKT ?wkt .
  FILTER(STRSTARTS(STR(?node), "https://www.openstreetmap.org/node/"))
  FILTER(geof:longitude(?wkt) >= ${degrees(box.west)} && geof:longitude(?wkt) <= ${degrees(box.east)} && geof:latitude(?wkt) >= ${degrees(box.south)} && geof:latitude(?wkt) <= ${degrees(box.north)})
  VALUES ?key { $keys }
  ?node ?key ?value .
}''';
}

/// Every point in [box], from QLever.
Future<NearbyPointSet> askQlever(
  http.Client httpClient,
  GeoBoundingBox box, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final http.Response response;
  try {
    response = await httpClient
        .post(
          Uri.parse(qleverEndpoint),
          headers: {
            'User-Agent': 'PreppSuite/1.0',
            'Accept': 'text/tab-separated-values',
          },
          body: {'query': qleverQuery(box)},
        )
        .timeout(timeout);
  } on Object catch (error) {
    throw QleverException(0, cause: error);
  }
  if (response.statusCode != 200) {
    throw QleverException(response.statusCode);
  }
  return parseQleverPoints(utf8.decode(response.bodyBytes));
}

/// The table [qleverQuery] asks for, as points. Throws a
/// [QleverException] for anything that is not that table -- an error page
/// read as an empty table would say there is no defibrillator anywhere
/// near.
NearbyPointSet parseQleverPoints(String body) {
  final lines = const LineSplitter().convert(body);
  if (lines.isEmpty || !lines.first.startsWith('?node')) {
    throw const QleverException(200);
  }

  final byId = <int, ({double lat, double lon, Map<String, String> tags})>{};
  for (final line in lines.skip(1)) {
    final cells = line.split('\t');
    if (cells.length < 4) continue;
    final id = _nodeId(cells[0]);
    final position = _point(cells[1]);
    final key = _key(cells[2]);
    final value = _literal(cells[3]);
    if (id == null || position == null || key == null || value == null) {
      continue;
    }
    final entry = byId[id] ??= (
      lat: position.lat,
      lon: position.lon,
      tags: <String, String>{},
    );
    entry.tags[key] = value;
  }
  return pointSetOf([
    for (final MapEntry(key: id, value: entry) in byId.entries)
      (id: id, lat: entry.lat, lon: entry.lon, tags: entry.tags),
  ]);
}

const _nodePrefix = '<https://www.openstreetmap.org/node/';
const _keyPrefix = '<https://www.openstreetmap.org/wiki/Key:';

int? _nodeId(String cell) {
  if (!cell.startsWith(_nodePrefix) || !cell.endsWith('>')) return null;
  return int.tryParse(cell.substring(_nodePrefix.length, cell.length - 1));
}

String? _key(String cell) {
  if (!cell.startsWith(_keyPrefix) || !cell.endsWith('>')) return null;
  return Uri.decodeFull(cell.substring(_keyPrefix.length, cell.length - 1));
}

final _pointPattern = RegExp(
  r'POINT\(\s*(-?\d+(?:\.\d+)?)\s+(-?\d+(?:\.\d+)?)\s*\)',
);

/// `POINT(lon lat)`, bare or as a typed literal.
({double lat, double lon})? _point(String cell) {
  final match = _pointPattern.firstMatch(cell);
  if (match == null) return null;
  final lon = double.parse(match.group(1)!);
  final lat = double.parse(match.group(2)!);
  if (lat.abs() > 90 || lon.abs() > 180) return null;
  return (lat: lat, lon: lon);
}

/// An N-Triples literal: `"text"`, perhaps with `@lang` or `^^<type>`
/// behind it, with `\n`, `\t`, `\"` and `\uXXXX` escaped inside.
String? _literal(String cell) {
  if (!cell.startsWith('"')) return null;
  final end = cell.lastIndexOf('"');
  if (end <= 0) return null;
  final inner = cell.substring(1, end);
  if (!inner.contains(r'\')) return inner;

  final out = StringBuffer();
  for (var i = 0; i < inner.length; i++) {
    final char = inner[i];
    if (char != r'\' || i + 1 == inner.length) {
      out.write(char);
      continue;
    }
    final next = inner[++i];
    switch (next) {
      case 'n':
        out.write('\n');
      case 't':
        out.write('\t');
      case 'r':
        out.write('\r');
      case 'b':
        out.write('\b');
      case 'f':
        out.write('\f');
      case 'u' || 'U':
        final length = next == 'u' ? 4 : 8;
        final code = i + length < inner.length
            ? int.tryParse(inner.substring(i + 1, i + 1 + length), radix: 16)
            : null;
        if (code == null) {
          out.write(next);
        } else {
          out.writeCharCode(code);
          i += length;
        }
      default:
        out.write(next);
    }
  }
  return out.toString();
}

/// Every point in [box], from the Overpass instances: the way back when
/// QLever is the one that is down.
Future<NearbyPointSet> askOverpassForPoints(
  http.Client httpClient,
  GeoBoundingBox box, {
  Duration retryDelay = OverpassShelterClient.defaultRetryDelay,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final bbox = '${box.south},${box.west},${box.north},${box.east}';
  final tags = emergencyTags.join('|');
  final query =
      '[out:json][timeout:${timeout.inSeconds}];'
      'node["emergency"~"^($tags)\$"]($bbox);'
      'out;';
  final response = await askOverpass(
    httpClient,
    query,
    retryDelay: retryDelay,
    timeout: timeout,
  );
  final decoded = jsonDecode(utf8.decode(response.bodyBytes));
  final elements = decoded is Map ? decoded['elements'] : null;
  if (elements is! List) return const NearbyPointSet();
  return pointSetOf([
    for (final element in elements)
      if (element is Map &&
          element['type'] == 'node' &&
          element['id'] is int &&
          element['lat'] is num &&
          element['lon'] is num)
        (
          id: element['id'] as int,
          lat: (element['lat'] as num).toDouble(),
          lon: (element['lon'] as num).toDouble(),
          tags: {
            if (element['tags'] case final Map<Object?, Object?> tags)
              for (final entry in tags.entries)
                '${entry.key}': '${entry.value}',
          },
        ),
  ]);
}

/// The box around an `around:` circle from `gridCircle`, for asking
/// QLever what Overpass was asked: the same grid point, the same reach.
GeoBoundingBox boxAroundCircle(
  ({String latitude, String longitude, int radiusMetres}) circle,
) {
  const metresPerDegree = 111320.0;
  final latitude = double.parse(circle.latitude);
  final longitude = double.parse(circle.longitude);
  // A per cent over: the circle is measured on a sphere elsewhere, and a
  // box a little large only brings points the radius filter drops.
  final latDelta = circle.radiusMetres * 1.01 / metresPerDegree;
  final cosine = math.cos(latitude * math.pi / 180).abs();
  final lonDelta = cosine < 1e-6
      ? 180.0
      : circle.radiusMetres * 1.01 / (metresPerDegree * cosine);
  return GeoBoundingBox(
    west: longitude - lonDelta,
    south: latitude - latDelta,
    east: longitude + lonDelta,
    north: latitude + latDelta,
  );
}

/// A search near a place: the main Overpass instance, then QLever, then
/// the other Overpass instances (#366).
///
/// QLever comes second rather than last because of who is waiting. Asked
/// in turn, two instances that do not answer cost fifteen seconds each
/// before anything else is tried -- on 12 November 2026 the main one
/// answered 502 at once and the other two not at all, and the
/// defibrillator search took over half a minute to reach QLever, which
/// answered in under one. The main instance stays first: it is where the
/// app has always asked, and on an ordinary day it is the fastest.
///
/// Every way is tried even when the first was out of reach, since one
/// name that does not resolve is not yet no network. Only when none of
/// them was reached is that what the failure says.
Future<T> askNearbyPoints<T>(
  http.Client httpClient, {
  required String overpassQuery,
  required GeoBoundingBox box,
  required T Function(http.Response response) fromOverpass,
  required T Function(NearbyPointSet set) fromQlever,
  Duration retryDelay = OverpassShelterClient.defaultRetryDelay,
  Duration timeout = const Duration(seconds: 15),
}) async {
  const endpoints = OverpassShelterClient.endpoints;
  final OverpassException first;
  try {
    return fromOverpass(
      await askOverpass(
        httpClient,
        overpassQuery,
        retryDelay: retryDelay,
        timeout: timeout,
        endpoints: endpoints.take(1),
      ),
    );
  } on OverpassException catch (failure) {
    first = failure;
  }

  final QleverException qlever;
  try {
    return fromQlever(await askQlever(httpClient, box, timeout: timeout));
  } on QleverException catch (failure) {
    qlever = failure;
  }

  try {
    return fromOverpass(
      await askOverpass(
        httpClient,
        overpassQuery,
        retryDelay: retryDelay,
        timeout: timeout,
        endpoints: endpoints.skip(1),
      ),
    );
  } on OverpassException catch (rest) {
    if (first.noNetwork && qlever.unreachable && rest.noNetwork) throw first;
    // Reached somewhere and answered nowhere: what the screen explains is
    // the main instance's failure, never "no connection".
    throw OverpassException(
      first.statusCode,
      cause: first.cause,
      reachedAny: true,
    );
  }
}
