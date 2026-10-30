import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../maps/application/personal_place.dart';
import '../../shelters/application/shelter_bearing.dart';

/// Where the household plan's two meeting points are, on this device
/// (#204).
///
/// Kept as two of the device's own places ("Eigene Orte") and not in the
/// plan. The plan travels through the household's folder; the map's own
/// places deliberately do not, because where a household meets is the
/// kind of thing that stays on the device it was put on (see
/// [PersonalPlace]). As one of those places a meeting point is on the map
/// with the others and leaves in a GPX file like them, which is how a
/// second device gets it if the household wants that.
enum MeetingPoint {
  near('meetingPoint.near'),
  far('meetingPoint.far');

  const MeetingPoint(this.placeId);

  /// Fixed, so the place is found again and replaced rather than added.
  final String placeId;
}

class MeetingPointPlaces {
  const MeetingPointPlaces([this._store = const PersonalPlaceStore()]);

  final PersonalPlaceStore _store;

  Future<Map<MeetingPoint, PersonalPlace>> load() async {
    final places = await _store.load();
    return {
      for (final point in MeetingPoint.values)
        point: ?places.where((place) => place.id == point.placeId).firstOrNull,
    };
  }

  /// Puts [point] at [at] under [label], where it was in the list if it
  /// was there, so the other places keep their order.
  Future<void> put(
    MeetingPoint point,
    LatLng at, {
    required String label,
  }) async {
    final placed = PersonalPlace(
      id: point.placeId,
      label: label,
      latitude: at.latitude,
      longitude: at.longitude,
    );
    await _store.update((places) {
      final index = places.indexWhere((place) => place.id == point.placeId);
      return index < 0
          ? [...places, placed]
          : [...places.take(index), placed, ...places.skip(index + 1)];
    });
  }

  Future<void> remove(MeetingPoint point) async {
    await _store.update(
      (places) => [
        for (final place in places)
          if (place.id != point.placeId) place,
      ],
    );
  }

  /// Gives the places the names the plan has now, leaving them where
  /// they are -- the map labels a point by what the household calls it.
  Future<void> relabel(Map<MeetingPoint, String> labels) async {
    final wanted = {
      for (final point in MeetingPoint.values) point.placeId: ?labels[point],
    };
    await _store.update((places) {
      final relabelled = <PersonalPlace>[];
      for (final place in places) {
        final label = wanted[place.id];
        if (label == null || label == place.label) {
          relabelled.add(place);
          continue;
        }
        relabelled.add(
          PersonalPlace(
            id: place.id,
            label: label,
            latitude: place.latitude,
            longitude: place.longitude,
            note: place.note,
          ),
        );
      }
      return relabelled;
    });
  }
}

/// Where the meeting points are kept; a provider so a test can keep them
/// in memory.
final meetingPointStoreProvider = Provider<MeetingPointPlaces>(
  (ref) => const MeetingPointPlaces(),
);

/// The meeting points this device knows where to find.
final meetingPointPlacesProvider =
    FutureProvider.autoDispose<Map<MeetingPoint, PersonalPlace>>(
      (ref) => ref.watch(meetingPointStoreProvider).load(),
    );

/// How far and which way [place] is from [here].
({double meters, CompassPoint direction}) wayTo(
  LatLng here,
  PersonalPlace place,
) {
  final there = LatLng(place.latitude, place.longitude);
  return (
    meters: distanceMeters(here, there),
    direction: bearingFrom(here, there),
  );
}
