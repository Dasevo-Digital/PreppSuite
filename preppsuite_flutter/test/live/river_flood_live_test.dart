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
}
