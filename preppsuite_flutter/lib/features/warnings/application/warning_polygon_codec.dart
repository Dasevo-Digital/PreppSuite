import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../local_db/database.dart';

/// Decodes the locally cached CAP polygon representation.
///
/// A warning stays useful after the network is gone, so malformed or absent
/// geometry is deliberately treated as "no map available", never as an
/// exception that hides the rest of its text.
List<List<LatLng>> warningPolygons(Warning warning) {
  final encoded = warning.polygonsJson;
  if (encoded == null) return const [];
  try {
    final decoded = jsonDecode(encoded);
    if (decoded is! List) return const [];
    return [
      for (final polygon in decoded.whereType<String>())
        [
          for (final pair in polygon.split(RegExp(r'\s+')))
            if (pair.split(',') case [final lat, final lon])
              if (double.tryParse(lat) case final latitude?)
                if (double.tryParse(lon) case final longitude?)
                  LatLng(latitude, longitude),
        ],
    ].where((points) => points.length >= 3).toList();
  } on Object {
    return const [];
  }
}

/// Whether [point] lies inside [ring].
///
/// Ray casting: count how often a ray going east from the point crosses an
/// edge; an odd number means inside. Longitude is treated as x and latitude
/// as y, which is wrong on a sphere and irrelevant at the size of a German
/// district — the error stays far below the resolution of the outlines the
/// feed delivers.
bool ringContains(List<LatLng> ring, LatLng point) {
  if (ring.length < 3) return false;
  var inside = false;
  for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    final yi = ring[i].latitude;
    final xi = ring[i].longitude;
    final yj = ring[j].latitude;
    final xj = ring[j].longitude;
    // Only an edge that straddles the point's latitude can be crossed.
    if ((yi > point.latitude) == (yj > point.latitude)) continue;
    final x = xi + (point.latitude - yi) / (yj - yi) * (xj - xi);
    if (point.longitude < x) inside = !inside;
  }
  return inside;
}

/// Whether any of [polygons] covers [point].
///
/// This answers "is this spot inside the drawn outline", not "does this
/// warning apply to me" — `isWarningRelevant` answers that one, and the
/// two must not be confused. A warning that names no geometry covers no
/// point here even when it concerns everybody.
bool polygonsCover(List<List<LatLng>> polygons, LatLng point) =>
    polygons.any((ring) => ringContains(ring, point));

/// [warningPolygons], kept between rebuilds.
///
/// Decoding walks every coordinate pair of every area a warning names, and
/// a screen that draws many of them calls it for each one — on every
/// filter change and every poll, for data that did not change. Measured on
/// a desktop machine, a storm-day feed of 120 warnings costs 14 ms each
/// time round and a saturated one of 300 costs 71 ms; a phone is slower
/// than that, and 16 ms is a whole frame.
///
/// The cache is keyed by the warning's identity *and* the time it was last
/// written, so a warning the feed rewrites is decoded again rather than
/// drawn from its old outline.
class WarningPolygonCache {
  Map<String, List<List<LatLng>>> _entries = {};

  String _key(Warning warning) =>
      '${warning.source}\u0000${warning.externalId}'
      '\u0000${warning.updatedAt.microsecondsSinceEpoch}';

  /// The areas of [warning], decoded once.
  List<List<LatLng>> of(Warning warning) =>
      _entries[_key(warning)] ??= warningPolygons(warning);

  /// Forgets every warning not in [live].
  ///
  /// Called with everything the feed currently holds rather than with
  /// what a filter leaves over: otherwise turning a filter on would throw
  /// away the outlines that turning it off again needs, which is the one
  /// moment this exists to make cheap.
  void retain(Iterable<Warning> live) {
    final keys = {for (final warning in live) _key(warning)};
    _entries = {
      for (final entry in _entries.entries)
        if (keys.contains(entry.key)) entry.key: entry.value,
    };
  }
}
