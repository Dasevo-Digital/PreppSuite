/// Defibrillators and emergency points taken along with the offline map
/// (#366).
///
/// The two searches near a place asked OpenStreetMap at the moment they
/// were made and kept the last answer, which covers one place on one day.
/// With the public Overpass instances down for days in November 2026, a
/// household that had never searched from home had nothing at all, and
/// the map it had downloaded for exactly that day did not help: the map
/// tiles carry no `emergency=*`.
///
/// So the region the offline map covers is asked for once, all of it, and
/// kept on the device beside the map: every defibrillator, emergency well,
/// disaster help point and siren in its box. For Germany that was 49,804
/// points on 12 November 2026, about 29 MB of table from QLever (3 MB
/// packed on the way) and a few MB packed here. The screens ask the
/// network and, beside it, look in here; what is here is shown until the
/// answer comes, and stays when none does.
///
/// The points go with the map: another map's box replaces them, a map
/// too large for them or none at all removes them, and an answer that
/// arrives for a map no longer in use is thrown away.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_database_directory.dart' show appSupportDirectory;
import '../../../core/error_log.dart';
import '../../../core/http_client.dart';
import '../../first_aid/application/defibrillators.dart';
import '../../maps/application/pmtiles_archive.dart';
import '../../shelters/application/geo_bounds.dart';
import 'emergency_points.dart';
import 'osm_point_sources.dart';

/// What is kept, without the points themselves: enough for the settings
/// card to say what the device holds without reading megabytes.
class OfflineNearbyPoints {
  const OfflineNearbyPoints({
    required this.bounds,
    required this.fetchedAt,
    required this.defibrillators,
    required this.points,
    this.format = offlinePointsFormat,
  });

  final GeoBoundingBox bounds;
  final DateTime fetchedAt;

  /// How the points were fetched: [offlinePointsFormat] for this version,
  /// 1 for what 3.0.1 kept, which may be a table QLever cut short.
  final int format;

  /// How many of each are kept.
  final int defibrillators;
  final int points;

  /// Whether [latitude], [longitude] lies in the box. A place near its
  /// edge gets what lies inside, which is the same as the map: it ends
  /// there too.
  bool contains(double latitude, double longitude) =>
      latitude >= bounds.south &&
      latitude <= bounds.north &&
      longitude >= bounds.west &&
      longitude <= bounds.east;

  /// Whether this was taken for [other], to a hundredth of a degree's
  /// fraction. A map downloaded again over the same area is the same box.
  bool isFor(GeoBoundingBox other) {
    bool same(double a, double b) => (a - b).abs() < 1e-4;
    return same(bounds.west, other.west) &&
        same(bounds.south, other.south) &&
        same(bounds.east, other.east) &&
        same(bounds.north, other.north);
  }

  Map<String, Object?> toJson() => {
    'west': bounds.west,
    'south': bounds.south,
    'east': bounds.east,
    'north': bounds.north,
    'fetchedAt': fetchedAt.toUtc().toIso8601String(),
    'defibrillators': defibrillators,
    'points': points,
    'format': format,
  };

  static OfflineNearbyPoints? fromJson(Object? json) {
    if (json is! Map) return null;
    double? number(String key) => (json[key] as num?)?.toDouble();
    final west = number('west');
    final south = number('south');
    final east = number('east');
    final north = number('north');
    final fetchedAt = DateTime.tryParse('${json['fetchedAt']}');
    if (west == null ||
        south == null ||
        east == null ||
        north == null ||
        fetchedAt == null) {
      return null;
    }
    return OfflineNearbyPoints(
      bounds: GeoBoundingBox(
        west: west,
        south: south,
        east: east,
        north: north,
      ),
      fetchedAt: fetchedAt,
      defibrillators: (json['defibrillators'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      format: (json['format'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Raised when what is kept has to be fetched again however young it is.
/// 2 since 3.0.2: 3.0.1 took a table QLever had cut short for the whole of
/// it (#385), so what it kept is asked for once more. Until that answer
/// comes, and if it does not, the old points are still shown.
const offlinePointsFormat = 2;

/// What the kept points have near one place.
class OfflineNearbyAnswer {
  const OfflineNearbyAnswer({
    required this.kept,
    required this.defibrillators,
    required this.points,
  });

  final OfflineNearbyPoints kept;

  /// Within the defibrillator radius, nearest first.
  final List<Defibrillator> defibrillators;

  /// The nearest of each kind within its radius.
  final List<EmergencyPoint> points;
}

/// The largest box taken along, in square degrees. Germany's is about 73;
/// a continent's would be hundreds of thousands of points for a search
/// that only ever looks two to ten kilometres around one place.
const maxOfflinePointArea = 400.0;

bool offlinePointAreaFits(GeoBoundingBox box) =>
    (box.east - box.west).abs() * (box.north - box.south).abs() <=
    maxOfflinePointArea;

/// After this long the points are asked for again. OpenStreetMap changes
/// slowly at this scale: a defibrillator here and there.
const offlinePointsRefreshAfter = Duration(days: 60);

/// The box of [archive], as its header states it.
GeoBoundingBox boundsOfArchive(PmTilesArchive archive) => GeoBoundingBox(
  west: archive.header.minLongitude,
  south: archive.header.minLatitude,
  east: archive.header.maxLongitude,
  north: archive.header.maxLatitude,
);

/// The points on disk, packed, beside a small file that says what they
/// are.
///
/// Not encrypted, unlike the last search near a place: these are public
/// points over the whole box of a map that is itself on the device in
/// the clear, and say nothing about which spot in it is somebody's home.
/// The directory is the app's own, which is left out of device backups
/// (see `app_database_directory.dart`).
class OfflineNearbyPointStore {
  const OfflineNearbyPointStore({this.directory});

  /// Where the two files go; the app's support directory by default.
  final Future<Directory> Function()? directory;

  static const _dataName = 'offline_nearby_points.json.gz';
  static const _metaName = 'offline_nearby_points.json';

  Future<File> _file(String name) async {
    final dir = await (directory ?? appSupportDirectory)();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  /// What is kept, or null for nothing or for files that do not read.
  Future<OfflineNearbyPoints?> kept() async {
    try {
      final file = await _file(_metaName);
      if (!file.existsSync()) return null;
      return OfflineNearbyPoints.fromJson(
        jsonDecode(await file.readAsString()),
      );
    } on Object {
      return null;
    }
  }

  /// What the kept points have around [latitude], [longitude], or null
  /// where nothing is kept for that place.
  ///
  /// Read and sorted on another isolate: for all of Germany that is tens
  /// of thousands of points, and the screen asking is the one somebody
  /// opens with a person on the floor in front of them.
  Future<OfflineNearbyAnswer?> around(double latitude, double longitude) async {
    final kept = await this.kept();
    if (kept == null || !kept.contains(latitude, longitude)) return null;
    try {
      final path = (await _file(_dataName)).path;
      final near = await Isolate.run(() {
        final file = File(path);
        if (!file.existsSync()) return null;
        final set = _decode(file.readAsBytesSync());
        return (
          defibrillators: nearestDefibrillators(
            set.defibrillators,
            latitude,
            longitude,
          ),
          points: nearestEmergencyPoints(set.points, latitude, longitude),
        );
      });
      if (near == null) return null;
      return OfflineNearbyAnswer(
        kept: kept,
        defibrillators: near.defibrillators,
        points: near.points,
      );
    } on Object {
      return null;
    }
  }

  /// Keeps [set] as the points of [bounds], replacing what was there.
  ///
  /// Both files are written beside the old ones first. Then the small
  /// file goes, the points take their place and the small file follows:
  /// an interrupted write leaves the old pair, or points nothing names --
  /// which read as nothing kept -- and never one box's description over
  /// another box's points.
  Future<OfflineNearbyPoints> save(
    GeoBoundingBox bounds,
    NearbyPointSet set, {
    DateTime? fetchedAt,
  }) async {
    final data = await _file(_dataName);
    final meta = await _file(_metaName);
    final dataPart = File('${data.path}.part');
    final metaPart = File('${meta.path}.part');
    final kept = OfflineNearbyPoints(
      bounds: bounds,
      fetchedAt: fetchedAt ?? DateTime.now(),
      defibrillators: set.defibrillators.length,
      points: set.points.length,
    );
    final bytes = await Isolate.run(() => _encode(set));
    await dataPart.writeAsBytes(bytes, flush: true);
    await metaPart.writeAsString(jsonEncode(kept.toJson()), flush: true);

    if (meta.existsSync()) await meta.delete();
    await dataPart.rename(data.path);
    await metaPart.rename(meta.path);
    return kept;
  }

  Future<void> clear() async {
    for (final name in const [
      _metaName,
      _dataName,
      '$_dataName.part',
      '$_metaName.part',
    ]) {
      try {
        final file = await _file(name);
        if (file.existsSync()) await file.delete();
      } on Object {
        // Already gone, or no directory in a test.
      }
    }
  }
}

List<int> _encode(NearbyPointSet set) => gzip.encode(
  utf8.encode(
    jsonEncode({
      'version': 1,
      'defibrillators': [for (final aed in set.defibrillators) aed.toJson()],
      'points': [for (final point in set.points) point.toJson()],
    }),
  ),
);

NearbyPointSet _decode(List<int> bytes) {
  final json = jsonDecode(utf8.decode(gzip.decode(bytes)));
  if (json is! Map || json['version'] != 1) return const NearbyPointSet();
  return NearbyPointSet(
    defibrillators: [
      if (json['defibrillators'] case final List<Object?> list)
        for (final item in list) ?Defibrillator.fromJson(item),
    ],
    points: [
      if (json['points'] case final List<Object?> list)
        for (final item in list) ?EmergencyPoint.fromJson(item),
    ],
  );
}

/// Every point in [box]: QLever first, because a box the size of a
/// country is what it is built for and what an Overpass instance turns
/// away; the Overpass instances when QLever does not answer.
Future<NearbyPointSet> fetchOfflinePoints(GeoBoundingBox box) async {
  // Germany is 29 MB of table from QLever, and the answer starts only
  // once the query has run.
  final client = TimeoutClient(responseTimeout: const Duration(minutes: 2));
  try {
    try {
      return await askQlever(
        client,
        box,
        timeout: const Duration(minutes: 3),
      );
    } on QleverException catch (failure) {
      if (failure.unreachable) rethrow;
      return await askOverpassForPoints(client, box);
    }
  } finally {
    client.close();
  }
}

/// Where taking the points along stands.
enum OfflinePointsStatus {
  /// Nothing under way.
  idle,

  /// Being asked for.
  fetching,

  /// The last attempt brought nothing; what was kept before for the
  /// same box stays.
  failed,

  /// The map's box is larger than [maxOfflinePointArea].
  tooLarge,
}

class OfflinePointsState {
  const OfflinePointsState({this.kept, this.status = OfflinePointsStatus.idle});

  final OfflineNearbyPoints? kept;
  final OfflinePointsStatus status;
}

final offlineNearbyPointStoreProvider = Provider<OfflineNearbyPointStore>(
  (ref) => const OfflineNearbyPointStore(),
);

/// How the points of a box are asked for. A provider so tests never reach
/// the network.
final offlinePointsFetcherProvider =
    Provider<Future<NearbyPointSet> Function(GeoBoundingBox box)>(
      (ref) => fetchOfflinePoints,
    );

final offlineNearbyPointsProvider =
    AsyncNotifierProvider<OfflineNearbyPointsController, OfflinePointsState>(
      OfflineNearbyPointsController.new,
    );

class OfflineNearbyPointsController extends AsyncNotifier<OfflinePointsState> {
  OfflineNearbyPointStore get _store =>
      ref.read(offlineNearbyPointStoreProvider);

  /// The box of the map in use, or null for none. Set before anything is
  /// awaited, so that a fetch which ends after the map changed or went
  /// knows it is no longer wanted.
  GeoBoundingBox? _wanted;

  /// The fetch under way. Asked again meanwhile, for the same box or
  /// another, the caller waits for it; it fetches again for whatever box
  /// is wanted when it ends.
  Future<void>? _running;

  @override
  Future<OfflinePointsState> build() async =>
      OfflinePointsState(kept: await _store.kept());

  /// Takes the points of [bounds] along unless they are already kept and
  /// not older than [offlinePointsRefreshAfter].
  Future<void> ensureFor(GeoBoundingBox bounds, {DateTime? now}) async {
    _wanted = bounds;
    if (_running case final running?) return running;
    final kept = (await future).kept;
    if (_running case final running?) return running;
    // Superseded while it waited; the later call sees to it.
    if (!_isWanted(bounds)) return;
    if (kept != null &&
        kept.isFor(bounds) &&
        kept.format >= offlinePointsFormat &&
        (now ?? DateTime.now()).difference(kept.fetchedAt) <
            offlinePointsRefreshAfter) {
      return;
    }
    await refresh(bounds);
  }

  /// Asks for the points of [bounds] now.
  Future<void> refresh(GeoBoundingBox bounds) {
    _wanted = bounds;
    return _running ??= _fetchWanted().whenComplete(() => _running = null);
  }

  /// Drops the kept points, for a map that is no longer used. A fetch
  /// under way is thrown away when it ends.
  Future<void> forget() async {
    _wanted = null;
    await _store.clear();
    state = const AsyncData(OfflinePointsState());
  }

  bool _isWanted(GeoBoundingBox bounds) {
    final wanted = _wanted;
    return wanted != null && _sameBox(wanted, bounds);
  }

  Future<void> _fetchWanted() async {
    while (true) {
      final bounds = _wanted;
      if (bounds == null) return;
      var kept = (await future).kept;
      if (!_isWanted(bounds)) continue;
      if (kept != null && !kept.isFor(bounds)) {
        // The points go with the map. Another map's are not shown for
        // this one while its own are fetched, nor when that fails, nor
        // when it is too large to have any.
        await _store.clear();
        kept = null;
        state = const AsyncData(OfflinePointsState());
        if (!_isWanted(bounds)) continue;
      }
      if (!offlinePointAreaFits(bounds)) {
        state = const AsyncData(
          OfflinePointsState(status: OfflinePointsStatus.tooLarge),
        );
        return;
      }
      state = AsyncData(
        OfflinePointsState(kept: kept, status: OfflinePointsStatus.fetching),
      );
      try {
        final set = await ref.read(offlinePointsFetcherProvider)(bounds);
        if (!_isWanted(bounds)) continue;
        final kept = await _store.save(bounds, set);
        if (!_isWanted(bounds)) {
          // The map changed or went while the files were written.
          await _store.clear();
          continue;
        }
        state = AsyncData(OfflinePointsState(kept: kept));
        return;
      } on Object catch (error, stack) {
        if (!_isWanted(bounds)) continue;
        // A device without network is not a fault; a service that does
        // not answer is worth the protocol.
        final offline =
            error is SocketException ||
            (error is QleverException && error.unreachable);
        if (!offline) {
          ErrorLog.instance.record(
            error,
            stack,
            context: 'Notfallpunkte der Offline-Karte',
          );
        }
        state = AsyncData(
          OfflinePointsState(kept: kept, status: OfflinePointsStatus.failed),
        );
        return;
      }
    }
  }
}

bool _sameBox(GeoBoundingBox a, GeoBoundingBox b) => OfflineNearbyPoints(
  bounds: a,
  fetchedAt: DateTime.utc(2000),
  defibrillators: 0,
  points: 0,
).isFor(b);
