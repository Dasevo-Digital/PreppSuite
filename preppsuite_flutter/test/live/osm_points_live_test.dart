import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/http_client.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/emergency_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/offline_nearby_points.dart';
import 'package:preppsuite_flutter/features/emergency_points/application/osm_point_sources.dart';
import 'package:preppsuite_flutter/features/shelters/application/geo_bounds.dart';

/// Asks QLever, the way around Overpass (#366).
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set. Worth running after
/// touching `osm_point_sources.dart`: the answer is a table read by
/// position, and its literals are escaped the way RDF escapes them.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real QLever service'
      : null;

  test(
    'Braunschweig has defibrillators with a place in the building',
    () async {
      final client = TimeoutClient();
      addTearDown(client.close);
      final set = await askQlever(
        client,
        const GeoBoundingBox(
          west: 10.45,
          south: 52.22,
          east: 10.6,
          north: 52.32,
        ),
      );
      stdout.writeln(
        '${set.defibrillators.length} Defibrillatoren, '
        '${set.points.length} Notfallpunkte',
      );

      expect(set.defibrillators.length, greaterThan(10));
      expect(
        set.defibrillators.where((d) => d.locationIn('de') != null),
        isNotEmpty,
      );
      for (final aed in set.defibrillators) {
        expect(aed.latitude, inInclusiveRange(52.22, 52.32));
        expect(aed.longitude, inInclusiveRange(10.45, 10.6));
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: reason,
  );

  test(
    'a map of Germany brings all four kinds along',
    () async {
      final set = await fetchOfflinePoints(
        const GeoBoundingBox(west: 5.8, south: 47.2, east: 15.1, north: 55.1),
      );
      final kinds = {
        for (final kind in EmergencyPointKind.values)
          kind: set.points.where((p) => p.kind == kind).length,
      };
      stdout.writeln('${set.defibrillators.length} Defibrillatoren, $kinds');

      // 12 November 2026: 35,770 defibrillators, 10,446 sirens, 1,955
      // wells and 1,633 help points in this box.
      expect(set.defibrillators.length, greaterThan(20000));
      expect(kinds[EmergencyPointKind.siren], greaterThan(5000));
      expect(kinds[EmergencyPointKind.well], greaterThan(1000));
      expect(kinds[EmergencyPointKind.helpPoint], greaterThan(300));
    },
    timeout: const Timeout(Duration(minutes: 5)),
    skip: reason,
  );
}
