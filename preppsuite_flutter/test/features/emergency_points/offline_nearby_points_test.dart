import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/emergency_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/offline_nearby_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/osm_point_sources.dart';
import 'package:preppsuite_flutter/features/first_aid/application/defibrillators.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';

/// The defibrillators and emergency points taken along with the offline
/// map (#366).
void main() {
  late Directory dir;
  late OfflineNearbyPointStore store;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('offline-points');
    store = OfflineNearbyPointStore(directory: () async => dir);
  });
  tearDown(() => dir.deleteSync(recursive: true));

  const braunschweig = GeoBoundingBox(
    west: 10.4,
    south: 52.2,
    east: 10.7,
    north: 52.4,
  );

  const set = NearbyPointSet(
    defibrillators: [
      Defibrillator(
        id: 1,
        latitude: 52.2733,
        longitude: 10.5254,
        tags: {'defibrillator:location': 'Neben Raum 143'},
      ),
      // Inside the box, beyond the radius of a search in the centre.
      Defibrillator(id: 2, latitude: 52.39, longitude: 10.69),
    ],
    points: [
      EmergencyPoint(
        id: 3,
        kind: EmergencyPointKind.siren,
        latitude: 52.2700,
        longitude: 10.5270,
        tags: {'siren:range': '600 m'},
      ),
      EmergencyPoint(
        id: 4,
        kind: EmergencyPointKind.well,
        latitude: 52.2900,
        longitude: 10.5300,
        tags: {'ref': 'BS-12'},
      ),
    ],
  );

  group('the store', () {
    test('keeps the points and answers for a place inside its box', () async {
      final kept = await store.save(
        braunschweig,
        set,
        fetchedAt: DateTime.utc(2026, 11, 12, 10),
      );
      expect(kept.defibrillators, 2);
      expect(kept.points, 2);

      final again = await store.kept();
      expect(again!.isFor(braunschweig), isTrue);
      expect(again.fetchedAt, DateTime.utc(2026, 11, 12, 10));

      final near = await store.around(52.2689, 10.5268);
      expect(near, isNotNull);
      expect(near!.defibrillators.map((d) => d.id), [1]);
      expect(
        near.defibrillators.single.locationIn('de'),
        'Neben Raum 143',
      );
      // Each kind within its own radius, in the kinds' order.
      expect(near.points.map((p) => p.id), [4, 3]);
      expect(near.points.last.sirenRangeMetres, 600);
    });

    test('says nothing for a place outside its box', () async {
      await store.save(braunschweig, set);
      expect(await store.around(52.52, 13.40), isNull, reason: 'Berlin');
    });

    test('is packed on disk, and gone when cleared', () async {
      await store.save(braunschweig, set);
      final files = dir.listSync().map((f) => f.path.split('/').last).toSet();
      expect(files, {
        'offline_nearby_points.json',
        'offline_nearby_points.json.gz',
      });
      final packed = File('${dir.path}/offline_nearby_points.json.gz');
      // gzip's magic number.
      expect(packed.readAsBytesSync().take(2), [0x1f, 0x8b]);

      await store.clear();
      expect(dir.listSync(), isEmpty);
      expect(await store.kept(), isNull);
      expect(await store.around(52.2689, 10.5268), isNull);
    });

    test('a description without its points answers nothing', () async {
      await store.save(braunschweig, set);
      File('${dir.path}/offline_nearby_points.json.gz').deleteSync();
      expect(await store.around(52.2689, 10.5268), isNull);
    });
  });

  group('the controller', () {
    late List<GeoBoundingBox> asked;
    late Object? failWith;

    ProviderContainer container() {
      asked = [];
      failWith = null;
      final container = ProviderContainer(
        overrides: [
          offlineNearbyPointStoreProvider.overrideWithValue(store),
          offlinePointsFetcherProvider.overrideWithValue((box) async {
            asked.add(box);
            if (failWith case final error?) throw error;
            return set;
          }),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('takes a new map region along once', () async {
      final c = container();
      final points = c.read(offlineNearbyPointsProvider.notifier);

      await points.ensureFor(braunschweig);
      await points.ensureFor(braunschweig);

      expect(asked, hasLength(1));
      final state = c.read(offlineNearbyPointsProvider).value!;
      expect(state.status, OfflinePointsStatus.idle);
      expect(state.kept!.defibrillators, 2);
    });

    test('asks again for another region, or after two months', () async {
      final c = container();
      final points = c.read(offlineNearbyPointsProvider.notifier);
      await points.ensureFor(braunschweig);

      const hannover = GeoBoundingBox(
        west: 9.6,
        south: 52.3,
        east: 9.9,
        north: 52.45,
      );
      await points.ensureFor(hannover);
      expect(asked, hasLength(2));

      await points.ensureFor(
        hannover,
        now: DateTime.now().add(const Duration(days: 59)),
      );
      expect(asked, hasLength(2));
      await points.ensureFor(
        hannover,
        now: DateTime.now().add(const Duration(days: 61)),
      );
      expect(asked, hasLength(3));
    });

    test('does not take a continent along', () async {
      final c = container();
      await c
          .read(offlineNearbyPointsProvider.notifier)
          .ensureFor(
            const GeoBoundingBox(west: -25, south: 34, east: 45, north: 72),
          );
      expect(asked, isEmpty);
      expect(
        c.read(offlineNearbyPointsProvider).value!.status,
        OfflinePointsStatus.tooLarge,
      );
    });

    test('a failed attempt keeps what was kept before', () async {
      final c = container();
      final points = c.read(offlineNearbyPointsProvider.notifier);
      await points.ensureFor(braunschweig);

      failWith = const SocketException('Network unreachable');
      await points.refresh(braunschweig);

      final state = c.read(offlineNearbyPointsProvider).value!;
      expect(state.status, OfflinePointsStatus.failed);
      expect(state.kept!.isFor(braunschweig), isTrue);
      expect(await store.around(52.2689, 10.5268), isNotNull);
    });

    test('a map no longer used takes its points with it', () async {
      final c = container();
      final points = c.read(offlineNearbyPointsProvider.notifier);
      await points.ensureFor(braunschweig);

      await points.forget();

      expect(c.read(offlineNearbyPointsProvider).value!.kept, isNull);
      expect(await store.kept(), isNull);
    });
  });

  test('Germany fits, a continent does not', () {
    expect(
      offlinePointAreaFits(
        const GeoBoundingBox(west: 5.8, south: 47.2, east: 15.1, north: 55.1),
      ),
      isTrue,
    );
    expect(
      offlinePointAreaFits(
        const GeoBoundingBox(west: -180, south: -85, east: 180, north: 85),
      ),
      isFalse,
    );
  });
}
