import 'dart:ui' show Brightness;

import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/offline_map_providers.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart';

/// Whether a downloaded archive can actually label the map.
///
/// This exists because of a workaround it replaces. `OfflineCityLabels`
/// drew "Braunschweig" as a hard-coded marker from zoom 6 up, on the
/// theory that the renderer was dropping the label. It was not: the
/// archive's own `place` layer carries Braunschweig from zoom 7 —
/// measured, 149 names in the zoom-8 tile alone — so from 7 up the
/// marker drew a second copy of a label the renderer was already
/// drawing, and at 6 it invented one the schema deliberately omits,
/// where no other German city of its size is named either. It also only
/// ever applied to the map screen and not to the shelter map, so the two
/// disagreed about the same place.
///
/// The durable answer is to check the archive instead. Run it with
///
///   PREPPSUITE_MAP=~/.../extract.pmtiles \
///     flutter test test/live/offline_map_labels_test.dart
void main() {
  final path = Platform.environment['PREPPSUITE_MAP'];

  ({int x, int y}) tileFor(double lat, double lon, int z) {
    final n = 1 << z;
    final x = ((lon + 180) / 360 * n).floor();
    final radians = lat * pi / 180;
    final y = ((1 - log(tan(radians) + 1 / cos(radians)) / pi) / 2 * n).floor();
    return (x: x, y: y);
  }

  test(
    'the place layer carries the names the style asks for',
    () async {
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(path!)),
      );
      addTearDown(archive.close);

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final theme = container.read(mapThemeProvider(Brightness.light));

      // The style's own labelling layers. Without `place` among the
      // layers the factory keeps, no name is drawn at all — which is the
      // failure this test is here to tell apart from a thin archive.
      final factory = TileFactory(theme, const Logger.noop());
      expect(factory.layerNames, contains('place'));
      expect(
        theme.layers.map((layer) => layer.id),
        containsAll(<String>['place_city', 'place_town', 'place_village']),
      );

      final reader = VectorTileReader();

      /// Every `place` name in the tile covering [lat]/[lon] at [z].
      Future<Set<String>> namesAt(double lat, double lon, int z) async {
        final at = tileFor(lat, lon, z);
        final bytes = await archive.tile(z, at.x, at.y);
        if (bytes == null) return {};

        final names = <String>{};
        for (final layer in reader.read(bytes).layers) {
          if (layer.name != 'place') continue;
          for (final feature in layer.features) {
            final name = feature.decodeProperties()['name']?.dartStringValue;
            if (name != null) names.add(name);
          }
        }
        return names;
      }

      const braunschweig = (52.2689, 10.5268);

      // Zoom 6 is a continental view: the tile there names countries,
      // Bundeslaender and the largest cities, and no city of
      // Braunschweig's size in any country. That is the schema deciding
      // what a continental view shows, not a label going missing.
      expect(
        await namesAt(braunschweig.$1, braunschweig.$2, 6),
        isNot(contains('Braunschweig')),
        reason: 'a continental view names no city this size, anywhere',
      );

      for (var z = 7; z <= 14; z++) {
        expect(
          await namesAt(braunschweig.$1, braunschweig.$2, z),
          contains('Braunschweig'),
          reason: 'Braunschweig must be labelled from zoom 7 up, missing at $z',
        );
      }

      // Towns and villages follow further in, which is what makes the
      // extract usable for finding a way out of somewhere small.
      final close = await namesAt(braunschweig.$1, braunschweig.$2, 11);
      expect(close, contains('Peine'));
      expect(close, contains('Wolfenbüttel'));
    },
    skip: path == null ? 'set PREPPSUITE_MAP to a real archive' : null,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
