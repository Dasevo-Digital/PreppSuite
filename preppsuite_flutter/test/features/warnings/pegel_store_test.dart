import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_level.dart';
import 'package:preppsuite_flutter/features/warnings/application/pegel_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembering the gauge and its last reading.
///
/// The kept reading is what this screen has to show while offline, which
/// for this app is the ordinary case. It therefore has to survive a
/// restart intact — a level without its reference values is a number
/// nobody can place.
void main() {
  const store = PegelStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  const koeln = PegelStation(
    uuid: 'a6ee8177',
    name: 'KÖLN',
    water: 'RHEIN',
    kilometre: 688,
    latitude: 50.936949,
    longitude: 6.9633,
  );

  final reading = PegelReading(
    stationName: 'KÖLN',
    water: 'RHEIN',
    centimetres: 712,
    measuredAt: DateTime.utc(2026, 9, 10, 16, 15),
    references: const {
      PegelReference.mean: 297,
      PegelReference.meanFlood: 725,
      PegelReference.highest: 1069,
    },
    changeOverDay: 48,
  );

  test('nothing is stored to begin with', () async {
    expect(await store.loadStation(), isNull);
    expect(await store.loadReading(), isNull);
  });

  test('a chosen gauge comes back whole', () async {
    await store.saveStation(koeln);
    final loaded = await store.loadStation();

    expect(loaded!.uuid, 'a6ee8177');
    expect(loaded.name, 'KÖLN');
    expect(loaded.water, 'RHEIN');
    // Kept because it is what says which gauge is upstream.
    expect(loaded.kilometre, 688);
    expect(loaded.latitude, closeTo(50.936949, 0.000001));
  });

  test('a reading comes back with its references and its trend', () async {
    await store.saveReading(reading);
    final loaded = await store.loadReading();

    expect(loaded!.centimetres, 712);
    expect(loaded.measuredAt, DateTime.utc(2026, 9, 10, 16, 15));
    expect(loaded.changeOverDay, 48);
    expect(loaded.reference(PegelReference.meanFlood), 725);
    // And it can still be placed, which is the point of keeping them:
    // 712 cm is above Cologne's mean of 297 and short of the 725 a flood
    // there usually reaches.
    expect(loaded.band, PegelBand.elevated);
    expect(loaded.trend, PegelTrend.rising);
  });

  test('choosing another gauge drops the reading of the old one', () async {
    // Left behind, it would appear under the new gauge's name at the next
    // launch — the same number, the wrong river.
    await store.saveStation(koeln);
    await store.saveReading(reading);

    await store.saveStation(
      const PegelStation(uuid: 'other', name: 'MAXAU', water: 'RHEIN'),
    );

    expect((await store.loadStation())!.name, 'MAXAU');
    expect(await store.loadReading(), isNull);
  });

  test('clearing removes both', () async {
    await store.saveStation(koeln);
    await store.saveReading(reading);
    await store.clearStation();

    expect(await store.loadStation(), isNull);
    expect(await store.loadReading(), isNull);
  });

  test('a corrupted entry reads as nothing stored, not as a crash', () async {
    SharedPreferences.setMockInitialValues({
      'pegelStation': 'not json at all',
      'pegelLastReading': '{"centimetres": "sechshundert"}',
    });

    expect(await store.loadStation(), isNull);
    expect(await store.loadReading(), isNull);
  });

  test('a reading without a timestamp is refused', () async {
    // A level with no time cannot be shown as either current or old, and
    // showing it as current is the one thing this screen must not do.
    SharedPreferences.setMockInitialValues({
      'pegelLastReading': '{"stationName":"KÖLN","centimetres":712.0}',
    });

    expect(await store.loadReading(), isNull);
  });
}
