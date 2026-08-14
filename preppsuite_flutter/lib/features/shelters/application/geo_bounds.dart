import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// A simple lat/lon bounding box — kept independent of `flutter_map`'s own
/// `LatLngBounds` so the data-source clients in this feature don't need a
/// map-widget dependency just to describe "the area to query".
class GeoBoundingBox {
  const GeoBoundingBox({
    required this.west,
    required this.south,
    required this.east,
    required this.north,
  });

  final double west;
  final double south;
  final double east;
  final double north;
}

/// Approximates a square bounding box of [radiusKm] around [center]. Good
/// enough for scoping a bunker/shelter search radius — not a geodesically
/// precise circle, but the UI already filters/labels results by the same
/// radius, so a slightly generous box is the right trade-off over an exact
/// (and much more complex) great-circle calculation.
GeoBoundingBox boundingBoxForRadius(LatLng center, double radiusKm) {
  const kmPerDegreeLat = 111.0;
  final kmPerDegreeLon = 111.0 * math.cos(center.latitude * math.pi / 180);

  final latDelta = radiusKm / kmPerDegreeLat;
  final lonDelta = kmPerDegreeLon == 0 ? 180.0 : radiusKm / kmPerDegreeLon;

  return GeoBoundingBox(
    west: center.longitude - lonDelta,
    south: center.latitude - latDelta,
    east: center.longitude + lonDelta,
    north: center.latitude + latDelta,
  );
}
