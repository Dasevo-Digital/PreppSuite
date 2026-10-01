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

/// How finely the centre of a search is placed, in degrees: about 1.1 km
/// north–south, and 0.7 km east–west at German latitudes.
///
/// The box goes to Overpass and WWBOTA, and a box drawn around the device's
/// own fix names that fix to the metre — its middle is where somebody
/// lives. Snapping the centre to this grid first means the request only
/// says which square kilometre the search was made from.
const searchGridDegrees = 0.01;

/// Approximates a square bounding box of [radiusKm] around [center]. Good
/// enough for scoping a bunker/shelter search radius — not a geodesically
/// precise circle, but the UI already filters/labels results by the same
/// radius, so a slightly generous box is the right trade-off over an exact
/// (and much more complex) great-circle calculation.
///
/// The centre is snapped to [searchGridDegrees] before the box is drawn,
/// and the box grows by the most that moves it, so it still covers the
/// whole radius around the real position.
GeoBoundingBox boundingBoxForRadius(LatLng center, double radiusKm) {
  const kmPerDegreeLat = 111.0;
  double snap(double degrees) =>
      (degrees / searchGridDegrees).round() * searchGridDegrees;
  final snapped = LatLng(snap(center.latitude), snap(center.longitude));
  final kmPerDegreeLon = 111.0 * math.cos(snapped.latitude * math.pi / 180);

  // Half a grid step each way, which is the furthest the snap moved it.
  final latDelta = radiusKm / kmPerDegreeLat + searchGridDegrees / 2;
  final lonDelta = kmPerDegreeLon == 0
      ? 180.0
      : radiusKm / kmPerDegreeLon + searchGridDegrees / 2;

  return GeoBoundingBox(
    west: snapped.longitude - lonDelta,
    south: snapped.latitude - latDelta,
    east: snapped.longitude + lonDelta,
    north: snapped.latitude + latDelta,
  );
}
