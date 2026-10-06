import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/heavy_rain_hazard.dart';

/// Against the BKG's real map service.
///
/// Skipped unless PREPPSUITE_TEST_NETWORK is set. What no fixture can show
/// is whether the layer names or the plain-text answer have moved.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real BKG service'
      : null;

  test('Braunschweig has an answer for both scenarios', () async {
    final results = await HeavyRainClient().check(52.2689, 10.5268);
    stdout.writeln(results.map((k, v) => MapEntry(k.name, v.toJson())));
    expect(results[HeavyRainScenario.extreme]!.maxDepthCm, isNotNull);
    expect(results[HeavyRainScenario.exceptional]!.maxDepthCm, isNotNull);
  }, skip: reason);
}
