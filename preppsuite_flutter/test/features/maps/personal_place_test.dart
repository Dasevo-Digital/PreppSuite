import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('a personal place round-trips locally', () async {
    const place = PersonalPlace(
      id: 'p1',
      label: 'Treffpunkt',
      latitude: 52.2689,
      longitude: 10.5268,
      note: 'Nordseite',
    );

    await const PersonalPlaceStore().save(const [place]);

    expect(await const PersonalPlaceStore().load(), hasLength(1));
    final restored = (await const PersonalPlaceStore().load()).single;
    expect(restored.label, 'Treffpunkt');
    expect(restored.latitude, 52.2689);
    expect(restored.note, 'Nordseite');
  });

  test(
    'invalid stored coordinates are ignored without losing valid places',
    () async {
      SharedPreferences.setMockInitialValues({
        'personalMapPlaces.v1': jsonEncode([
          {'id': 'bad', 'label': 'Broken', 'latitude': 91, 'longitude': 10},
          {'id': 'good', 'label': 'Valid', 'latitude': 52, 'longitude': 10},
        ]),
      });

      final places = await const PersonalPlaceStore().load();

      expect(places, hasLength(1));
      expect(places.single.id, 'good');
    },
  );

  test('coordinate validator keeps points within the world bounds', () {
    expect(PersonalPlace.isValidCoordinates(90, -180), isTrue);
    expect(PersonalPlace.isValidCoordinates(-90, 180), isTrue);
    expect(PersonalPlace.isValidCoordinates(90.1, 0), isFalse);
    expect(PersonalPlace.isValidCoordinates(0, -180.1), isFalse);
  });
}
