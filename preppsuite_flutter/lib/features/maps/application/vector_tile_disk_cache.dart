import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Empties the folder the vector map writes tile bytes to (#292).
///
/// `vector_map_tiles` keeps what it read in `<temp>/.vector_map` for a
/// month, under the tile's coordinates and the source name alone --
/// `12_2200_1343_openmaptiles.pbf` -- and nothing in that name says which
/// archive the bytes came from. After another archive was taken into use,
/// every tile looked at before came back from the old one: last year's
/// streets after a fresh download, or another region's where two overlap.
/// The folder is the library's default, which this app does not move.
///
/// Best effort. A test without a platform, or a file still being written,
/// costs at most a tile read twice.
Future<void> clearVectorTileDiskCache() async {
  try {
    final folder = Directory(
      p.join((await getTemporaryDirectory()).path, '.vector_map'),
    );
    if (await folder.exists()) await folder.delete(recursive: true);
  } on Object {
    // Nothing worth telling anybody about.
  }
}
