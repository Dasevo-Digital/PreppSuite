import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_bearing.dart';

/// Distances and directions checked against figures that can be looked up,
/// because a wrong one here is not a wrong pixel — it points somebody the
/// wrong way down a road.
void main() {
  const hannover = LatLng(52.3759, 9.7320);
  const bremen = LatLng(53.0793, 8.8017);
  const munich = LatLng(48.1351, 11.5820);
  const dresden = LatLng(51.0504, 13.7373);

  group('distance', () {
    test('is zero to itself', () {
      expect(distanceMeters(hannover, hannover), 0);
    });

    test('Hannover to Bremen is about 100 km', () {
      // 100.6 km great-circle, which every online calculator agrees on.
      expect(distanceMeters(hannover, bremen) / 1000, closeTo(100.6, 1.0));
    });

    test('Hannover to Munich is about 490 km', () {
      expect(distanceMeters(hannover, munich) / 1000, closeTo(489, 3.0));
    });

    test('is the same in both directions', () {
      expect(
        distanceMeters(hannover, munich),
        closeTo(distanceMeters(munich, hannover), 0.001),
      );
    });

    test('a hundred metres north is a hundred metres', () {
      // One degree of latitude is 111.32 km, so 0.0008993 of one is 100 m.
      const step = LatLng(52.3759 + 0.0008993, 9.7320);
      expect(distanceMeters(hannover, step), closeTo(100, 1));
    });
  });

  group('direction', () {
    test('Bremen is north-west of Hannover', () {
      expect(bearingFrom(hannover, bremen), CompassPoint.northWest);
    });

    test('Munich is due south of Hannover, not south-east', () {
      // 164 degrees: a long way down and only a little across, which the
      // eight points call south. Worth pinning, because "Munich is in the
      // south-east of Germany" is true of the country and not of this
      // bearing.
      expect(bearingFrom(hannover, munich), CompassPoint.south);
    });

    test('Dresden is south-east of Hannover', () {
      expect(bearingFrom(hannover, dresden), CompassPoint.southEast);
    });

    test('and the other way round is the opposite', () {
      expect(bearingFrom(bremen, hannover), CompassPoint.southEast);
      expect(bearingFrom(dresden, hannover), CompassPoint.northWest);
      expect(bearingFrom(munich, hannover), CompassPoint.north);
    });

    test('the four cardinal points come out exactly', () {
      expect(
        bearingFrom(hannover, const LatLng(53.0, 9.7320)),
        CompassPoint.north,
      );
      expect(
        bearingFrom(hannover, const LatLng(51.7, 9.7320)),
        CompassPoint.south,
      );
      expect(
        bearingFrom(hannover, const LatLng(52.3759, 10.5)),
        CompassPoint.east,
      );
      expect(
        bearingFrom(hannover, const LatLng(52.3759, 9.0)),
        CompassPoint.west,
      );
    });

    test('a point just east of due north still reads north', () {
      // Each point owns 45 degrees centred on itself; the boundary sits at
      // 22.5, not at 45. Getting that wrong turns every direction by half
      // a sector, which reads plausible and is wrong everywhere.
      expect(
        bearingFrom(hannover, const LatLng(53.0, 9.85)),
        CompassPoint.north,
      );
      expect(
        bearingFrom(hannover, const LatLng(53.0, 10.8)),
        CompassPoint.northEast,
      );
    });
  });
}
