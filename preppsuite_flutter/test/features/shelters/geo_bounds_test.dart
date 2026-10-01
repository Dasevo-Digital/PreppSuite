import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';

/// The box a shelter search sends to Overpass and WWBOTA.
///
/// Drawn around the device's own fix, its middle named that fix to the
/// metre. The centre is snapped to a grid first, and the box grows by as
/// much as the snap moved it.
void main() {
  const home = LatLng(52.268874, 10.526770);
  const neighbour = LatLng(52.271200, 10.528100);

  test('two positions in the same square send the same box', () {
    final a = boundingBoxForRadius(home, 25);
    final b = boundingBoxForRadius(neighbour, 25);

    expect(a.west, b.west);
    expect(a.south, b.south);
    expect(a.east, b.east);
    expect(a.north, b.north);
  });

  test('its middle is the grid point, not the position', () {
    final box = boundingBoxForRadius(home, 25);

    expect((box.south + box.north) / 2, closeTo(52.27, 1e-9));
    expect((box.west + box.east) / 2, closeTo(10.53, 1e-9));
  });

  test('it still covers the whole radius around the real position', () {
    for (final position in [home, neighbour, const LatLng(52.265, 10.535)]) {
      final box = boundingBoxForRadius(position, 25);
      final reach = boundingBoxWithoutSnapping(position, 25);

      expect(box.south, lessThanOrEqualTo(reach.south));
      expect(box.north, greaterThanOrEqualTo(reach.north));
      expect(box.west, lessThanOrEqualTo(reach.west));
      expect(box.east, greaterThanOrEqualTo(reach.east));
    }
  });
}

/// The box as it was drawn before the snap, which is what has to fit
/// inside the new one.
GeoBoundingBox boundingBoxWithoutSnapping(LatLng center, double radiusKm) {
  const kmPerDegreeLat = 111.0;
  final kmPerDegreeLon = 111.0 * _cos(center.latitude);
  return GeoBoundingBox(
    west: center.longitude - radiusKm / kmPerDegreeLon,
    south: center.latitude - radiusKm / kmPerDegreeLat,
    east: center.longitude + radiusKm / kmPerDegreeLon,
    north: center.latitude + radiusKm / kmPerDegreeLat,
  );
}

double _cos(double degrees) => math.cos(degrees * math.pi / 180);
