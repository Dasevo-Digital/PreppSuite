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
