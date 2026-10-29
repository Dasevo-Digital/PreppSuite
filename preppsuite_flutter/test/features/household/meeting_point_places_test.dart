import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:preppsuite_flutter/features/household/application/meeting_point_places.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_bearing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The plan's meeting points, kept as two of the device's own places
/// (#204): on the map with the others, and never in the shared plan.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const well = PersonalPlace(
    id: 'p1',
    label: 'Brunnen',
    latitude: 52.25,
    longitude: 10.5,
  );

  test(
    'a meeting point is one of the own places, the others untouched',
    () async {
      await const PersonalPlaceStore().save(const [well]);

      await const MeetingPointPlaces().put(
        MeetingPoint.near,
        const LatLng(52.2689, 10.5268),
        label: 'Vor der Garage',
      );

      final all = await const PersonalPlaceStore().load();
      expect(all.map((place) => place.label), ['Brunnen', 'Vor der Garage']);
      final points = await const MeetingPointPlaces().load();
      expect(points.keys, [MeetingPoint.near]);
      expect(points[MeetingPoint.near]!.latitude, 52.2689);
    },
  );

  test('moving it replaces it where it was in the list', () async {
    const places = MeetingPointPlaces();
    await places.put(MeetingPoint.far, const LatLng(52, 10), label: 'Weit');
    await const PersonalPlaceStore().save([
      ...await const PersonalPlaceStore().load(),
      well,
    ]);

    await places.put(MeetingPoint.far, const LatLng(53, 11), label: 'Weit');

    final all = await const PersonalPlaceStore().load();
    expect(all.map((place) => place.id), ['meetingPoint.far', 'p1']);
    expect(all.first.latitude, 53);
  });

  test(
    'a new name in the plan renames the place and leaves it where it is',
    () async {
      const places = MeetingPointPlaces();
      await places.put(
        MeetingPoint.near,
        const LatLng(52.2689, 10.5268),
        label: 'Treffpunkt in der Nähe',
      );

      await places.relabel({MeetingPoint.near: 'Spielplatz Ringstraße'});

      final near = (await places.load())[MeetingPoint.near]!;
      expect(near.label, 'Spielplatz Ringstraße');
      expect(near.longitude, 10.5268);
    },
  );

  test('taking it off the map leaves the other places', () async {
    await const PersonalPlaceStore().save(const [well]);
    const places = MeetingPointPlaces();
    await places.put(MeetingPoint.near, const LatLng(52, 10), label: 'Nah');

    await places.remove(MeetingPoint.near);

    expect(await places.load(), isEmpty);
    expect((await const PersonalPlaceStore().load()).single.id, 'p1');
  });

  test('the way there is a distance and one of eight directions', () {
    // About 1.1 km due north of the starting point.
    final way = wayTo(
      const LatLng(52.26, 10.52),
      const PersonalPlace(
        id: 'x',
        label: 'x',
        latitude: 52.27,
        longitude: 10.52,
      ),
    );

    expect(way.meters, closeTo(1112, 5));
    expect(way.direction, CompassPoint.north);
  });
  test('two stores keep both simultaneous meeting point writes', () async {
    await Future.wait([
      const MeetingPointPlaces(PersonalPlaceStore())
          .put(MeetingPoint.near, const LatLng(1, 2), label: 'Near'),
      const MeetingPointPlaces(PersonalPlaceStore())
          .put(MeetingPoint.far, const LatLng(3, 4), label: 'Far'),
    ]);
    expect(
      (await const MeetingPointPlaces().load()).keys,
      containsAll(MeetingPoint.values),
    );
  });
  test(
    'a queued relabel cannot resurrect a removed point or lose an import',
    () async {
      const points = MeetingPointPlaces();
      await points.put(MeetingPoint.near, const LatLng(1, 2), label: 'Near');
      await Future.wait([
        points.remove(MeetingPoint.near),
        points.relabel({MeetingPoint.near: 'Renamed'}),
        const PersonalPlaceStore().update((current) => [...current, well]),
      ]);
      final saved = await const PersonalPlaceStore().load();
      expect(saved.map((point) => point.id), ['p1']);
    },
  );
}
