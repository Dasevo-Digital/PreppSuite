import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/map_area_download.dart';
import 'package:preppsuite_flutter/features/maps/application/place_search.dart';

/// Asks the real geocoder for the three sizes the feature promises —
/// a town, a Bundesland and a country — and prints how deep each one
/// can actually be downloaded.
///
/// Skipped unless `PREPPSUITE_TEST_NETWORK` is set.
void main() {
  final reason = Platform.environment['PREPPSUITE_TEST_NETWORK'] == null
      ? 'set PREPPSUITE_TEST_NETWORK=1 to ask the real geocoder'
      : null;

  test(
    'a town, a state and a country, and how deep each goes',
    () async {
      final client = PlaceSearchClient();
      final expected = {
        'Hannover': ('city', 14),
        'Niedersachsen': ('state', 14),
        'Bayern': ('state', 14),
        'Deutschland': ('country', 13),
      };

      for (final entry in expected.entries) {
        final results = await client.search(entry.key);
        expect(results, isNotEmpty, reason: entry.key);
        final place = results.first;

        final deepest = deepestDetailWithin(place.areaAt(14));
        stdout.writeln(
          '${entry.key.padRight(14)} ${place.kind.padRight(9)} '
          'z14 = ${place.areaAt(14).tileCount} Kacheln, '
          'tiefste Stufe $deepest',
        );

        expect(place.kind, entry.value.$1, reason: entry.key);
        expect(deepest, entry.value.$2, reason: entry.key);

        // Nominatim asks for no more than one request a second.
        await Future<void>.delayed(const Duration(milliseconds: 1200));
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
    skip: reason,
  );
}
