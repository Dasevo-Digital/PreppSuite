/// Whether the offline map actually reaches the place being looked at.
///
/// An extract is a region, not a world. Panning past its edge is the
/// ordinary thing to do, and what the renderer does about it is draw a
/// coarser tile where it has one and nothing where it does not — so the
/// screen comes out half map and half empty, with no word anywhere about
/// why. That is not a fault to hunt: it is the download ending. But it
/// has to be said, because from the outside "the map does not load
/// properly" and "you never downloaded this area" look exactly alike.
library;

import 'map_area_download.dart';
import 'pmtiles_archive.dart';

/// How much of an area an archive holds.
class OfflineMapCoverage {
  const OfflineMapCoverage({required this.present, required this.total});

  /// Nothing was asked, because there was nothing to ask about.
  static const unknown = OfflineMapCoverage(present: 0, total: 0);

  final int present;
  final int total;

  /// Every tile of the area is in the file.
  bool get isComplete => total > 0 && present == total;

  /// Not one of them is. The archive covers somewhere else entirely.
  bool get isMissing => total > 0 && present == 0;

  /// Some are, some are not — the half-drawn screen.
  bool get isPartial => present > 0 && present < total;
}

/// The most tiles worth asking about.
///
/// Each miss is a directory walk through the archive, and the answer is
/// a sentence on a screen, not a survey. A sample tells a half-covered
/// view from a fully covered one just as well as a census.
const _maxProbes = 64;

/// How much of [box] at [zoom] the [archive] can draw.
///
/// The zoom is pulled into the archive's own range first: asking for
/// level 14 of a file that stops at 10 would report nothing present and
/// mean only that the question was wrong. Substituting a coarser tile is
/// what the renderer does anyway.
Future<OfflineMapCoverage> offlineMapCoverage(
  PmTilesArchive archive, {
  required double west,
  required double south,
  required double east,
  required double north,
  required int zoom,
}) async {
  final header = archive.header;
  if (header.maxZoom < header.minZoom) return OfflineMapCoverage.unknown;
  final level = zoom.clamp(header.minZoom, header.maxZoom);

  final area = MapArea(
    minLongitude: west,
    minLatitude: south,
    maxLongitude: east,
    maxLatitude: north,
    minZoom: level,
    maxZoom: level,
  );

  // Every nth tile where the view is larger than the budget, rather than
  // the first n — which would only ever look at one corner of it.
  final tiles = area.tiles().toList();
  final step = (tiles.length / _maxProbes).ceil();

  var present = 0;
  var total = 0;
  for (var index = 0; index < tiles.length; index += step) {
    final tile = tiles[index];
    total++;
    if (await archive.tileOrNull(tile.z, tile.x, tile.y) != null) present++;
  }

  return OfflineMapCoverage(present: present, total: total);
}
