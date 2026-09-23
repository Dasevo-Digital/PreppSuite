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
}
