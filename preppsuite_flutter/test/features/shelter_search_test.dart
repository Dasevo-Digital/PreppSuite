import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_search.dart';
import 'package:preppsuite_flutter/features/shelters/application/shelter_classification.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';
import 'package:preppsuite_flutter/features/shelters/application/overpass_shelter_client.dart';

void main() {
  const bounds = GeoBoundingBox(west: 10, east: 11, south: 51, north: 52);
  const shelter = ClassifiedShelter(
    id: 'a',
    name: 'A',
    lat: 51,
    lon: 10,
    confidence: ShelterConfidence.yellow,
    sourceLabel: 'Test',
  );
  test('a failed source hands back why, not just that it failed', () async {
    // The reason used to be caught and dropped, which left the screen
    // saying "OpenStreetMap/Overpass konnte nicht geladen werden" and
    // nothing else — the same sentence for a rate limit that clears in
    // seconds and for no network at all.
    final results = <ShelterSearchResult>[];
    final search = ShelterSearch(
      wwbota: (_) async => [shelter],
      overpass: (_) async => throw const OverpassException(429),
    );

    await search.search(bounds, results.add);

    final last = results.last;
    expect(last.overpassFailed, isTrue);
    expect(last.overpassError, isA<OverpassException>());
    expect((last.overpassError! as OverpassException).isBusy, isTrue);
    // And the source that did answer still contributed.
    expect(last.shelters, [shelter]);
    expect(last.wwbotaFailed, isFalse);
    expect(last.wwbotaError, isNull);
  });

  test(
    'both sources start together and fast results publish before slow ones',
    () async {
      final slow = Completer<List<ClassifiedShelter>>();
      var started = 0;
      final results = <ShelterSearchResult>[];
      final search = ShelterSearch(
        wwbota: (_) {
          started++;
          return slow.future;
        },
        overpass: (_) async {
          started++;
          return [shelter];
        },
      );
      final work = search.search(bounds, results.add);
      await Future<void>.delayed(Duration.zero);
      expect(started, 2);
      expect(results.last.pending, 1);
      expect(results.last.shelters, [shelter]);
      slow.completeError(StateError('offline'));
      await work;
      expect(results.last.pending, 0);
      expect(results.last.wwbotaFailed, isTrue);
      expect(results.last.shelters, [shelter]);
    },
  );
  test(
    'older responses and canceled searches never overwrite new results',
    () async {
      final slow = Completer<List<ClassifiedShelter>>();
      var calls = 0;
      final results = <ShelterSearchResult>[];
      final search = ShelterSearch(
        wwbota: (_) => ++calls == 1 ? slow.future : Future.value([]),
        overpass: (_) async => [],
      );
      final old = search.search(bounds, results.add);
      await search.search(bounds, results.add);
      final count = results.length;
      slow.complete([shelter]);
      await old;
      expect(results.length, count);
      final pending = search.search(bounds, results.add);
      search.cancel();
      final canceledCount = results.length;
      await pending;
      expect(results.length, canceledCount);
    },
  );
  test(
    'a hanging source times out without discarding the other source',
    () async {
      final search = ShelterSearch(
        timeout: const Duration(milliseconds: 5),
        wwbota: (_) => Completer<List<ClassifiedShelter>>().future,
        overpass: (_) async => [shelter],
      );
      final results = <ShelterSearchResult>[];
      await search.search(bounds, results.add);
      expect(results.last.pending, 0);
      expect(results.last.wwbotaFailed, isTrue);
      expect(results.last.overpassFailed, isFalse);
      expect(results.last.shelters, [shelter]);
    },
  );
}
