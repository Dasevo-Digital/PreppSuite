import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_cache.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_classification.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const bounds = GeoBoundingBox(
    west: 10.50,
    south: 52.20,
    east: 10.60,
    north: 52.30,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'preserves the classified, dated answer for the same map area',
    () async {
      const shelter = ClassifiedShelter(
        id: 'osm:42',
        name: 'Testschutzraum',
        lat: 52.25,
        lon: 10.55,
        confidence: ShelterConfidence.yellow,
        sourceLabel: 'OpenStreetMap',
        subtitle: 'bunker',
      );
      const cache = ShelterCache();

      await cache.save(bounds, [shelter]);
      final restored = await cache.load(bounds);

      expect(restored, isNotNull);
      expect(restored!.shelters, hasLength(1));
      expect(restored.shelters.single.id, shelter.id);
      expect(restored.shelters.single.confidence, ShelterConfidence.yellow);
      expect(restored.shelters.single.subtitle, 'bunker');
    },
  );

  test('does not reuse a different search area', () async {
    const cache = ShelterCache();
    await cache.save(bounds, const []);

    final otherArea = await cache.load(
      const GeoBoundingBox(
        west: 10.51,
        south: 52.20,
        east: 10.60,
        north: 52.30,
      ),
    );

    expect(otherArea, isNull);
  });

  // The preferences hold every cached area in full (#255).
  group('what is kept', () {
    GeoBoundingBox area(int i) => GeoBoundingBox(
      west: 10 + i / 100,
      south: 52,
      east: 10.1 + i / 100,
      north: 52.1,
    );

    Future<int> cachedAreas() async => (await SharedPreferences.getInstance())
        .getKeys()
        .where((key) => key.startsWith('shelterCache.v2.'))
        .length;

    test('at most ten areas, the newest', () async {
      const cache = ShelterCache();
      for (var i = 0; i < 14; i++) {
        await cache.save(area(i), const []);
      }

      expect(await cachedAreas(), ShelterCache.maxAreas);
      expect(await cache.load(area(13)), isNotNull);
    });

    test('an area past its week is removed, not only ignored', () async {
      final old = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 8))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'shelterCache.v2.1:2:3:4': '{"savedAt":$old,"shelters":[]}',
        'shelterCache.v2.broken': 'not json',
        // From before bus stops stopped counting as shelters (#338).
        'shelterCache.v1.1:2:3:4': '{"savedAt":$old,"shelters":[]}',
      });

      await const ShelterCache().save(bounds, const []);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('shelterCache.v2.1:2:3:4'), isFalse);
      expect(prefs.containsKey('shelterCache.v2.broken'), isFalse);
      expect(prefs.containsKey('shelterCache.v1.1:2:3:4'), isFalse);
      expect(await cachedAreas(), 1);
    });

    test('deleting the household takes every area along', () async {
      const cache = ShelterCache();
      await cache.save(area(1), const []);
      await cache.save(area(2), const []);
      await (await SharedPreferences.getInstance()).setString('keep', 'me');

      await cache.clear();

      expect(await cachedAreas(), 0);
      expect(
        (await SharedPreferences.getInstance()).getString('keep'),
        'me',
      );
    });
  });
}
