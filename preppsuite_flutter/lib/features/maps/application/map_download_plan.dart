import 'map_area_download.dart';
import 'pmtiles_archive.dart' show tileIdFor;

/// How far out a download reaches around the chosen place.
enum MapDownloadScope {
  /// The place alone, at the deepest level it fits.
  place,

  /// The place plus the state around it, staggered.
  region,

  /// The place, the state and the whole country, staggered — the country
  /// coarse, the place at full detail.
  country,
}

/// One ring of a staggered download: an area and the zoom levels it
/// contributes to the archive.
class MapDownloadStep {
  const MapDownloadStep({required this.label, required this.area});

  /// What the ring is, e.g. "Niedersachsen".
  final String label;

  final MapArea area;

  int get tileCount => area.tileCount;
}

/// What a download covers, ring by ring.
///
/// A whole country at street level is a third of a million tiles and some
/// fourteen gigabytes — but almost none of those tiles are ever looked at.
/// Staggering keeps the country whole and spends the detail where somebody
/// actually is: the same archive comes to a twentieth of the size and
/// still has every road in it at the level that road matters.
class MapDownloadPlan {
  const MapDownloadPlan(this.steps);

  /// A plan of one ring — a plain area download.
  MapDownloadPlan.single(MapArea area, {String label = ''})
    : steps = [MapDownloadStep(label: label, area: area)];

  /// Outermost first, so the list reads the way the rings nest.
  final List<MapDownloadStep> steps;

  /// The rings cover distinct zoom bands, so this is a plain sum.
  int get tileCount => steps.fold(0, (total, step) => total + step.tileCount);

  int get minZoom =>
      steps.map((step) => step.area.minZoom).reduce((a, b) => a < b ? a : b);

  int get maxZoom =>
      steps.map((step) => step.area.maxZoom).reduce((a, b) => a > b ? a : b);

  double get minLongitude => _least((step) => step.area.minLongitude);
  double get minLatitude => _least((step) => step.area.minLatitude);
  double get maxLongitude => _most((step) => step.area.maxLongitude);
  double get maxLatitude => _most((step) => step.area.maxLatitude);

  /// Every tile the plan covers, each one once.
  ///
  /// The bands do not overlap, so this only guards against rings that were
  /// handed in overlapping by a caller building a plan of its own.
  Iterable<({int z, int x, int y})> tiles() sync* {
    final seen = <int>{};
    for (final step in steps) {
      for (final tile in step.area.tiles()) {
        if (seen.add(tileIdFor(tile.z, tile.x, tile.y))) yield tile;
      }
    }
  }

  double _least(double Function(MapDownloadStep) of) =>
      steps.map(of).reduce((a, b) => a < b ? a : b);

  double _most(double Function(MapDownloadStep) of) =>
      steps.map(of).reduce((a, b) => a > b ? a : b);
}

/// A ring before its zoom band has been decided.
class MapDownloadRing {
  const MapDownloadRing({required this.label, required this.box});

  final String label;

  /// Only the coordinates are read; the zoom range is assigned by
  /// [staggeredPlan].
  final MapArea box;
}

/// Fits [rings] into [budget] by giving each one a band of zoom levels,
/// coarse on the outside and deepest in the middle.
///
/// [rings] runs outermost first — country, state, town. Something always
/// reaches [deepest]; what the budget decides is how far out that detail
/// extends. Preference runs inward-out: the ring nearest the middle is
/// deepened first, because detail where somebody is standing is worth
/// more than detail two states away.
///
/// A ring that its neighbour has already covered to the deepest level
/// drops out — asking for a state and a town in it, with room for the
/// whole state at full detail, should give the whole state rather than
/// hold a level back for the town.
///
/// Returns null when even the shallowest arrangement is over budget.
MapDownloadPlan? staggeredPlan({
  required List<MapDownloadRing> rings,
  int budget = MapAreaDownloader.tileLimit,
  int deepest = 14,
}) {
  if (rings.isEmpty) return null;

  if (rings.length == 1) {
    final ring = rings.single;
    final detail = deepestDetailWithin(
      ring.box.withDetail(deepest),
      budget: budget,
      lowest: 0,
      highest: deepest,
    );
    if (detail == null) return null;
    return MapDownloadPlan([
      MapDownloadStep(label: ring.label, area: ring.box.band(0, detail)),
    ]);
  }

  MapDownloadPlan? best;

  // Cuts[i] is the last zoom level ring i covers. Enumerated with the
  // innermost cut most significant and counted downwards, so the first
  // arrangement that fits is the one with the most detail nearest the
  // middle.
  for (final cuts in _cutCombinations(rings.length - 1, deepest)) {
    final plan = _planFor(rings, cuts, deepest);
    if (plan.tileCount <= budget) {
      best = plan;
      break;
    }
  }

  return best;
}

MapDownloadPlan _planFor(
  List<MapDownloadRing> rings,
  List<int> cuts,
  int deepest,
) {
  final steps = <MapDownloadStep>[];
  var from = 0;

  for (var i = 0; i < rings.length; i++) {
    final to = i == rings.length - 1 ? deepest : cuts[i];
    // An outer ring that already reached the deepest level leaves the
    // inner ones with nothing to add.
    if (to >= from) {
      steps.add(
        MapDownloadStep(
          label: rings[i].label,
          area: rings[i].box.band(from, to),
        ),
      );
    }
    from = to + 1;
  }

  return MapDownloadPlan(steps);
}

/// Strictly increasing cut levels in `0..highest`, ordered so that the
/// last cut falls first and fastest — that is the "deepen the inner ring
/// before the outer one" preference, written as an ordering rather than
/// as a search.
Iterable<List<int>> _cutCombinations(int count, int highest) sync* {
  if (count == 0) {
    yield const [];
    return;
  }

  for (var last = highest; last >= count - 1; last--) {
    for (final prefix in _cutCombinations(count - 1, last - 1)) {
      yield [...prefix, last];
    }
  }
}
