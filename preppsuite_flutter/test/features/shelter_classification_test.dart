import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_classification.dart';
import 'package:preppsuite_flutter/features/shelters/application/wwbota_client.dart';

void main() {
  group('classifyOverpassTags', () {
    // Real tags captured live from overpass-api.de on 2026-08-14 for a
    // Berlin bounding box.
    test('disused + access=no personnel shelter is red', () {
      expect(
        classifyOverpassTags(const {
          'access': 'no',
          'building': 'bunker',
          'bunker_type': 'personnel_shelter',
          'disused': 'yes',
          'location': 'overground',
          'military': 'bunker',
          'note': 'Splitterschutzzelle',
        }),
        ShelterConfidence.red,
      );
    });

    test('historic + ruins pillbox is red', () {
      expect(
        classifyOverpassTags(const {
          'building': 'bunker',
          'bunker_type': 'pillbox',
          'historic': 'yes',
          'military': 'bunker',
          'ruins': 'yes',
        }),
        ShelterConfidence.red,
      );
    });

    test('a plain, still-standing bunker with no historic/disused/ruins/'
        'access tag is yellow (possible, unconfirmed)', () {
      expect(
        classifyOverpassTags(const {'military': 'bunker'}),
        ShelterConfidence.yellow,
      );
    });

    test('emergency=shelter without disqualifying tags is green', () {
      expect(
        classifyOverpassTags(const {'emergency': 'shelter'}),
        ShelterConfidence.green,
      );
    });

    test('emergency=shelter that is also disused is still red — disused '
        'always overrides', () {
      expect(
        classifyOverpassTags(const {
          'emergency': 'shelter',
          'disused': 'yes',
        }),
        ShelterConfidence.red,
      );
    });
  });

  group('classifyWwbota', () {
    test('WWBOTA entries are always yellow, never green', () {
      final result = classifyWwbota(const [
        WwbotaBunker(
          reference: 'B/DL-0151',
          name: 'Hochbunker Salzgitter Heerte',
          type: 'Hochbunker',
          lat: 52.125133,
          lon: 10.386983,
        ),
      ]);

      expect(result.single.confidence, ShelterConfidence.yellow);
      expect(result.single.id, 'wwbota:B/DL-0151');
      expect(result.single.sourceLabel, 'WWBOTA/DLBOTA');
    });
  });
}
