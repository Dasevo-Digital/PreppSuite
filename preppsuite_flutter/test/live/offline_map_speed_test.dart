import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/maps/application/pmtiles_archive.dart';

/// How long a screenful of tiles takes out of a real archive.
///
/// Skipped unless PREPPSUITE_MAP points at one: the archive is gigabytes
/// and nobody checks that into a repository. Run it with
///
///   PREPPSUITE_MAP=~/Documents/PreppSuite/....pmtiles \
///     flutter test test/live/offline_map_speed_test.dart
void main() {
  final path = Platform.environment['PREPPSUITE_MAP'];

  test('a screenful of tiles', () async {
    final archive = await PmTilesArchive.open(
      await FileByteRangeSource.open(File(path!)),
    );
    addTearDown(archive.close);

    // Hannover at zoom 12, an 8x6 window — about what a desktop window
    // holds at 512-pixel tiles.
    const z = 12;
    const centreX = 2160;
    const centreY = 1345;

    final watch = Stopwatch()..start();
    var found = 0;
    final reads = <Future<void>>[];
    for (var dx = -4; dx < 4; dx++) {
      for (var dy = -3; dy < 3; dy++) {
        reads.add(
          archive.tile(z, centreX + dx, centreY + dy).then((bytes) {
            if (bytes != null) found++;
          }),
        );
      }
    }
    await Future.wait(reads);
    watch.stop();

    // ignore: avoid_print
    print('48 Kacheln: ${watch.elapsedMilliseconds} ms, $found vorhanden');
    expect(found, greaterThan(0));
  }, skip: path == null ? 'set PREPPSUITE_MAP to a real archive' : null);
}
