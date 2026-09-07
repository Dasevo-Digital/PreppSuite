import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

/// What a downloaded archive actually covers, zoom level by zoom level.
///
/// A staggered download gives each ring its own band of zoom levels, so
/// "which zooms exist here" has a different answer in the middle than at
/// the edge. That is the thing to look at when somebody says the offline
/// map only shows a small patch.
void main() {
  final path = Platform.environment['PREPPSUITE_MAP'];

  ({int x, int y}) tileFor(double lat, double lon, int z) {
    final n = 1 << z;
    final x = ((lon + 180) / 360 * n).floor();
    final latRad = lat * pi / 180;
    final y = ((1 - log(tan(latRad) + 1 / cos(latRad)) / pi) / 2 * n).floor();
    return (x: x, y: y);
  }

  test(
    'coverage per place and zoom',
    () async {
      final archive = await PmTilesArchive.open(
        await FileByteRangeSource.open(File(path!)),
      );
      addTearDown(archive.close);

      const places = {
        'Hannover': (52.3759, 9.7320),
        'Braunschweig': (52.2689, 10.5268),
        'Hamburg': (53.5511, 9.9937),
        'Koeln': (50.9375, 6.9603),
        'Muenchen': (48.1351, 11.5820),
      };

      // ignore: avoid_print
      print('Zoom  ${places.keys.map((k) => k.padRight(13)).join()}');
      for (var z = 0; z <= 14; z++) {
        final row = StringBuffer('${z.toString().padLeft(4)}  ');
        for (final entry in places.entries) {
          final t = tileFor(entry.value.$1, entry.value.$2, z);
          final bytes = await archive.tile(z, t.x, t.y);
          row.write(
            (bytes == null ? '-' : '${bytes.length ~/ 1024} KB').padRight(13),
          );
        }
        // ignore: avoid_print
        print(row);
      }
    },
    skip: path == null ? 'set PREPPSUITE_MAP to a real archive' : null,
  );
}
