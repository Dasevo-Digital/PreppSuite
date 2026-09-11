import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:vector_tile/vector_tile.dart';

import '../../shelters/application/shelter_bearing.dart';
import 'pmtiles_archive.dart';

/// What a household looks for when there is nothing to ask.
///
/// Six groups rather than the eighty-odd classes the schema carries: this
/// is not a directory of everything, it is the short list of things worth
/// walking to when the network, the shops' tills and the telephone are
/// all gone.
enum PoiKind { water, health, food, fuel, hardware, help }

/// Which OpenStreetMap values belong to each group.
///
/// Keyed on the tile's `subclass` — the raw OSM value — and never on its
/// `class`, because the coarse class merges things this feature must keep
/// apart. Measured over 21 tiles of the real planet build: `class=fuel`
/// held 569 points, of which **525 were charging stations and 44 were
/// filling stations**. In a scenario that begins with the power being
/// off, showing those as one thing would be the single most misleading
/// answer this screen could give.
const poiSubclasses = <PoiKind, Set<String>>{
  PoiKind.water: {'drinking_water'},
  PoiKind.health: {'pharmacy', 'hospital', 'clinic', 'doctors'},
  PoiKind.food: {
    'supermarket',
    'convenience',
    'bakery',
    'butcher',
    'greengrocer',
    'marketplace',
    'deli',
  },
  PoiKind.fuel: {'fuel', 'charging_station'},
  PoiKind.hardware: {'doityourself', 'hardware'},
  PoiKind.help: {'fire_station', 'police', 'townhall', 'community_centre'},
};

/// The reverse of [poiSubclasses], built once.
final _kindBySubclass = {
  for (final entry in poiSubclasses.entries)
    for (final subclass in entry.value) subclass: entry.key,
};

/// One point found in the archive.
class NearbyPlace {
  const NearbyPlace({
    required this.kind,
    required this.subclass,
    required this.position,
    required this.distanceMeters,
    required this.bearing,
    this.name,
  });

  final PoiKind kind;

  /// The OpenStreetMap value, kept rather than folded into [kind]: a
  /// filling station and a charging point are one group and two very
  /// different answers, and the screen has to be able to say which.
  final String subclass;

  final LatLng position;
  final double distanceMeters;
  final CompassPoint bearing;

  /// What it is called, where OpenStreetMap knows. Frequently nothing —
  /// of 67 drinking-water points in the sample, 7 carried a name — which
  /// is why a nameless point is shown by what it is instead of dropped.
  final String? name;
}

/// How far a scan has got, and what it has found so far.
class PoiSearchProgress {
  const PoiSearchProgress({
    required this.places,
    required this.tilesRead,
    required this.tilesTotal,
  });

  /// Everything found up to here, nearest first.
  final List<NearbyPlace> places;

  final int tilesRead;
  final int tilesTotal;

  bool get isComplete => tilesRead >= tilesTotal;
}

/// Why a search could not be run at all.
enum PoiSearchProblem {
  /// No archive is in use.
  noArchive,

  /// The archive stops short of zoom 14, where the schema first carries
  /// points of interest. An area downloaded at zoom 12 draws a perfectly
  /// good map and holds not one pharmacy.
  tooShallow,

  /// The point searched around lies outside what the archive covers.
  outsideArchive,
}

class PoiSearchException implements Exception {
  const PoiSearchException(this.problem);

  final PoiSearchProblem problem;

  @override
  String toString() => 'PoiSearchException: ${problem.name}';
}

/// The zoom the OpenMapTiles schema first writes the `poi` layer at.
///
/// Below it the layer does not exist — not thinly, at all. So this is a
/// requirement and not a preference.
const poiZoom = 14;

/// Finds points of interest in a downloaded map archive.
///
/// The whole point is that it asks nothing of anybody: the archive is on
/// disk, and this reads the same tiles the map draws from. It is the one
/// search in this app that still answers when the network is gone — which
/// is the same moment the shelter search, the warnings and the gauges all
/// stop answering.
///
/// Three things it is not, and the screen says all three:
/// coverage is exactly what was downloaded and nothing beyond it; the
/// data is OpenStreetMap's, so it is as complete as volunteers made it;
/// and a point being on the map is no promise that it is open, stocked or
/// staffed.
class OfflinePoiSearch {
  const OfflinePoiSearch(this.archive);

  final PmTilesArchive archive;

  /// The most tiles one search will read.
  ///
  /// A tile at zoom 14 is about 1.5 km across at German latitudes and up
  /// to a quarter of a megabyte in a city, so a 10 km radius is already
  /// 196 of them. The cap is what keeps "search a wide radius" from
  /// meaning "read fifty megabytes and decode half a million features".
  static const tileBudget = 225;

  /// Points of [kinds] within [radiusMeters] of [centre], nearest first.
  ///
  /// A stream rather than a future because the tiles are read nearest
  /// first: the answer somebody actually wants — the closest pharmacy —
  /// is known long before the far edge of the radius has been touched,
  /// and making them wait for the rest would be for nothing.
  Stream<PoiSearchProgress> search({
    required LatLng centre,
    required double radiusMeters,
    Set<PoiKind> kinds = const {...PoiKind.values},
  }) async* {
    final header = archive.header;
    if (header.maxZoom < poiZoom) {
      throw const PoiSearchException(PoiSearchProblem.tooShallow);
    }
    if (centre.longitude < header.minLongitude ||
        centre.longitude > header.maxLongitude ||
        centre.latitude < header.minLatitude ||
        centre.latitude > header.maxLatitude) {
      throw const PoiSearchException(PoiSearchProblem.outsideArchive);
    }

    final tiles = tilesAround(centre, radiusMeters);
    final wanted = {
      for (final kind in kinds) ...poiSubclasses[kind] ?? const <String>{},
    };

    final found = <NearbyPlace>[];
    final seen = <String>{};
    var read = 0;

    for (final tile in tiles) {
      final bytes = await archive.tile(poiZoom, tile.x, tile.y);
      read++;

      if (bytes != null) {
        // Decoded off the main isolate. A city tile carries three and a
        // half thousand features, and decoding a screenful of them where
        // the interface lives drops frames for as long as it takes.
        final points = await Isolate.run(
          () => decodePoiTile(bytes, tile.x, tile.y, wanted),
        );

        for (final point in points) {
          final position = LatLng(point.latitude, point.longitude);
          final distance = distanceMeters(centre, position);
          if (distance > radiusMeters) continue;

          // The same shop can sit in two tiles: the schema writes a
          // small buffer around each one, so a point near an edge is
          // carried by its neighbours too.
          final key =
              '${point.subclass}|${point.name ?? ''}|'
              '${position.latitude.toStringAsFixed(5)}|'
              '${position.longitude.toStringAsFixed(5)}';
          if (!seen.add(key)) continue;

          found.add(
            NearbyPlace(
              kind: _kindBySubclass[point.subclass]!,
              subclass: point.subclass,
              position: position,
              distanceMeters: distance,
              bearing: bearingFrom(centre, position),
              name: point.name,
            ),
          );
        }
        found.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
      }

      yield PoiSearchProgress(
        places: List.unmodifiable(found),
        tilesRead: read,
        tilesTotal: tiles.length,
      );
    }

    // An archive covering the point but not the radius around it reads
    // every tile and finds none of them. That is a real answer — "the
    // download stops here" — and the empty list carries it.
    if (tiles.isEmpty) {
      yield const PoiSearchProgress(places: [], tilesRead: 0, tilesTotal: 0);
    }
  }
}

/// One tile to read, in the order it should be read in.
typedef PoiTile = ({int x, int y});

/// The zoom-14 tiles covering [radiusMeters] around [centre], nearest
/// first and never more than [OfflinePoiSearch.tileBudget].
///
/// Nearest first is what makes the stream useful: the closest tile holds
/// the closest answer, so the list is roughly right from the first frame
/// and only gets more complete.
List<PoiTile> tilesAround(LatLng centre, double radiusMeters) {
  const earthCircumference = 40075016.686;
  final scale = 1 << poiZoom;

  final metresPerTileX =
      earthCircumference * math.cos(centre.latitude * math.pi / 180) / scale;
  // Latitude runs at a constant metres-per-degree, which is not the same
  // thing as a constant metres-per-tile — Mercator stretches towards the
  // poles exactly as it does in x, so the two spans are equal here.
  final metresPerTileY = metresPerTileX;

  final spanX = (radiusMeters / metresPerTileX).ceil();
  final spanY = (radiusMeters / metresPerTileY).ceil();

  final centreX = _tileX(centre.longitude, scale);
  final centreY = _tileY(centre.latitude, scale);

  final tiles = <({int x, int y, double distance})>[];
  for (var dx = -spanX; dx <= spanX; dx++) {
    for (var dy = -spanY; dy <= spanY; dy++) {
      final x = centreX + dx;
      final y = centreY + dy;
      if (x < 0 || y < 0 || x >= scale || y >= scale) continue;
      tiles.add((
        x: x,
        y: y,
        // From the tile's centre, so the tile the point itself sits in
        // always sorts first.
        distance: (dx * dx + dy * dy).toDouble(),
      ));
    }
  }

  tiles.sort((a, b) => a.distance.compareTo(b.distance));
  return [
    for (final tile in tiles.take(OfflinePoiSearch.tileBudget))
      (x: tile.x, y: tile.y),
  ];
}

int _tileX(double longitude, int scale) =>
    ((longitude + 180) / 360 * scale).floor().clamp(0, scale - 1);

int _tileY(double latitude, int scale) {
  final radians = latitude * math.pi / 180;
  final y =
      (1 - math.log(math.tan(radians) + 1 / math.cos(radians)) / math.pi) / 2;
  return (y * scale).floor().clamp(0, scale - 1);
}

/// A point straight out of a tile, before it is measured against anything.
///
/// Deliberately plain: it crosses an isolate boundary, and everything
/// that needs the search centre to exist is worked out on the other side.
class DecodedPoi {
  const DecodedPoi({
    required this.subclass,
    required this.latitude,
    required this.longitude,
    this.name,
  });

  final String subclass;
  final double latitude;
  final double longitude;
  final String? name;
}

/// Pulls the wanted points out of one vector tile.
///
/// Top-level and free of everything but its arguments, because it runs in
/// its own isolate.
List<DecodedPoi> decodePoiTile(
  Uint8List bytes,
  int x,
  int y,
  Set<String> wanted,
) {
  final VectorTile tile;
  try {
    tile = VectorTile.fromBytes(bytes: bytes);
  } on Object {
    // One unreadable tile is not a failed search. The map itself treats a
    // tile it cannot parse as a blank square rather than an error, and a
    // search that gave up on the whole radius for one of them would be
    // strictly worse than one that is short by a street.
    return const [];
  }

  VectorTileLayer? layer;
  for (final candidate in tile.layers) {
    if (candidate.name == 'poi') layer = candidate;
  }
  if (layer == null) return const [];

  final extent = layer.extent;
  final scale = 1 << poiZoom;
  final found = <DecodedPoi>[];

  for (final feature in layer.features) {
    if (feature.type != VectorTileGeomType.POINT) continue;

    final properties = feature.decodeProperties();
    final subclass = properties['subclass']?.stringValue;
    if (subclass == null || !wanted.contains(subclass)) continue;

    final points = feature.decodePoint();
    if (points.isEmpty || points.first.length < 2) continue;
    final localX = points.first[0];
    final localY = points.first[1];

    // Outside the tile's own square. The schema writes a buffer, so a
    // point just over an edge is repeated by the neighbour that owns it —
    // dropping it here means every point is counted exactly once, by the
    // tile it belongs to.
    if (localX < 0 || localY < 0 || localX >= extent || localY >= extent) {
      continue;
    }

    final worldX = (x + localX / extent) / scale;
    final worldY = (y + localY / extent) / scale;

    final name =
        properties['name:de']?.stringValue ??
        properties['name']?.stringValue ??
        properties['name_de']?.stringValue;

    found.add(
      DecodedPoi(
        subclass: subclass,
        longitude: worldX * 360 - 180,
        latitude: _latitudeFromWorldY(worldY),
        name: name != null && name.isNotEmpty ? name : null,
      ),
    );
  }
  return found;
}

/// The inverse of the Mercator projection: `atan(sinh(pi * (1 - 2y)))`.
double _latitudeFromWorldY(double worldY) {
  final n = math.pi * (1 - 2 * worldY);
  final sinh = (math.exp(n) - math.exp(-n)) / 2;
  return math.atan(sinh) * 180 / math.pi;
}
