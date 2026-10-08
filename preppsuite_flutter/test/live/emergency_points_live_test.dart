import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/emergency_points.dart';

/// Against the real Overpass. Skipped unless PREPPSUITE_TEST_NETWORK is
/// set. What no fixture shows: whether the tags are still the ones mapped.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real Overpass'
      : null;

  test('Berlin-Mitte has wells and Katastrophenschutz-Leuchttürme', () async {
    final client = EmergencyPointClient();
    try {
      final found = await client.near(52.52, 13.405);
      final wells = found.where((p) => p.kind == EmergencyPointKind.well);
      final helpPoints = found.where(
        (p) => p.kind == EmergencyPointKind.helpPoint,
      );
      stdout.writeln(
        '${wells.length} wells, ${helpPoints.length} help points, '
        'first: ${helpPoints.firstOrNull?.name}, '
        '${helpPoints.firstOrNull?.address}',
      );
      // Over 400 wells within 5 km and 22 help points within 10 km on
      // 2026-10-08; only the nearest are kept.
      expect(wells.length, EmergencyPointKind.well.kept);
      expect(helpPoints.length, EmergencyPointKind.helpPoint.kept);
      expect(helpPoints.first.address, isNotNull);
    } finally {
      client.close();
    }
  }, skip: reason);
}
