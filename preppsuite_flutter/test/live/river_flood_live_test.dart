@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/river_flood.dart';

/// Against the Länder's real map services. Skipped unless
/// PREPPSUITE_TEST_NETWORK is set. What no fixture shows: whether the
/// layer numbers or the pixel codes have moved.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real NLWKN service'
      : null;

  test('the Leine floodplain in Hannover is under water at HQ100', () async {
    final result = await RiverFloodClient().check(
      52.378,
      9.7,
      stateCode: 'NI',
    );
    stdout.writeln(result.toJson());
    // Class 4, 2 to 4 m, when this was written.
    expect(result.classes[RiverFloodScenario.hundred], greaterThanOrEqualTo(3));
    expect(result.classes[RiverFloodScenario.extreme], greaterThanOrEqualTo(3));
  }, skip: reason);

  test('the Danube at Passau is deep at HQ100 (Bayern)', () async {
    final result = await RiverFloodClient().check(
      48.58446,
      13.46498,
      stateCode: 'BY',
    );
    stdout.writeln(result.toJson());
    // Over 4 m in the river itself when this was written.
    expect(result.classes[RiverFloodScenario.hundred], greaterThanOrEqualTo(4));
  }, skip: reason);

  test('the Rhine at Cologne is deep at HQ100 (NRW)', () async {
    final result = await RiverFloodClient().check(
      50.94796,
      6.96516,
      stateCode: 'NW',
    );
    stdout.writeln(result.toJson());
    // 4.9 m when this was written.
    expect(result.classes[RiverFloodScenario.hundred], greaterThanOrEqualTo(4));
  }, skip: reason);

  group('the national map (#148)', () {
    Future<RiverFloodResult> at(double lat, double lon, String state) async {
      final result = await RiverFloodClient().check(lat, lon, stateCode: state);
      stdout.writeln('$state $lat,$lon: ${result.toJson()}');
      return result;
    }

    test(
      'the Elbe in Dresden (Saxony, a layer called "Wassertiefen")',
      () async {
        final result = await at(51.0560, 13.7390, 'SN');
        // Over 4 m in the river at HQ100 when this was written.
        expect(
          result.classes[RiverFloodScenario.hundred],
          greaterThanOrEqualTo(4),
        );
      },
      skip: reason,
    );

    test('the Neckar in Heidelberg (Baden-Württemberg, #131)', () async {
      final result = await at(49.4125, 8.6990, 'BW');
      expect(
        result.classes[RiverFloodScenario.hundred],
        greaterThanOrEqualTo(3),
      );
      // The extreme flood sits in the layer called "Wassertiefen" there.
      expect(result.classes[RiverFloodScenario.extreme], isNotNull);
    }, skip: reason);

    test('the Main in Frankfurt (Hesse)', () async {
      final result = await at(50.1065, 8.6820, 'HE');
      expect(result.covered, isTrue);
      expect(result.classes.keys, hasLength(3));
    }, skip: reason);

    test('the Saarland has no map for the frequent flood', () async {
      final result = await at(49.2330, 6.9930, 'SL');
      expect(result.classes.containsKey(RiverFloodScenario.frequent), isFalse);
      expect(result.classes.containsKey(RiverFloodScenario.hundred), isTrue);
    }, skip: reason);
  });
}
