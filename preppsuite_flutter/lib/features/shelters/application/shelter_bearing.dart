import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// The eight points a direction is rounded to.
///
/// Eight and not sixteen: "north-north-east" is a bearing, not something
/// anybody walks by. What this has to answer is "which way, roughly", and
/// past eight the extra precision is false — the coordinates themselves
/// come from a crowd-sourced database.
enum CompassPoint {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest,
}

/// Great-circle distance in metres.
///
/// Haversine rather than the flat approximation in geo_bounds.dart: that
/// one is scoping a query box, where being generous is free, while this
/// number is shown to somebody deciding how far they have to walk.
double distanceMeters(LatLng from, LatLng to) {
  const earthRadius = 6371000.0;
  final lat1 = _radians(from.latitude);
  final lat2 = _radians(to.latitude);
  final dLat = lat2 - lat1;
  final dLon = _radians(to.longitude - from.longitude);

  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * earthRadius * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Which of the eight points [to] lies in, seen from [from].
///
/// The initial bearing of the great circle, which over the distances this
/// screen deals with is the same as "point that way and walk".
CompassPoint bearingFrom(LatLng from, LatLng to) {
  final lat1 = _radians(from.latitude);
  final lat2 = _radians(to.latitude);
  final dLon = _radians(to.longitude - from.longitude);

  final y = math.sin(dLon) * math.cos(lat2);
  final x =
      math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
  final degrees = (math.atan2(y, x) * 180 / math.pi + 360) % 360;

  // Each point owns 45 degrees, centred on itself — so north runs from
  // 337.5 through 22.5, which the offset before the division handles.
  final index = (((degrees + 22.5) % 360) ~/ 45).toInt();
  return CompassPoint.values[index];
}

double _radians(double degrees) => degrees * math.pi / 180;
