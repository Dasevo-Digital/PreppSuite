import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/private_preferences.dart';
import '../../first_aid/application/defibrillators.dart' show distanceMetres;
import '../../shelters/application/overpass_shelter_client.dart';

/// Emergency wells, disaster help points and sirens near a place, from
/// OpenStreetMap (#127, #128).
///
/// Three things a long blackout makes worth knowing in advance and hard to
/// find out once it has begun:
///
/// * **Emergency wells** (`emergency=drinking_water`). The federal
///   government keeps a network of them for when the mains fail; Berlin
///   alone has hundreds of hand pumps on the pavement. 1952 were mapped in
///   Germany on 2026-10-08.
/// * **Disaster help points** (`emergency=disaster_help_point`), called
///   Katastrophenschutz-Leuchtturm, Notfalltreffpunkt or Notfallinfopunkt
///   depending on the Land: a building with emergency power where there is
///   information and from where an emergency call still goes out. 579
///   mapped.
/// * **Sirens** (`emergency=siren`), 8498 mapped -- whether one is within
///   earshot of home is the question, and the answer decides whether the
///   loudest warning there is reaches this household at all.
///
/// The downloaded map has none of them -- OpenMapTiles has no layer for
/// `emergency=*` -- so, like the defibrillators, they are asked for once
/// with a network and kept.
enum EmergencyPointKind {
  well('drinking_water', 5000, 15),
  helpPoint('disaster_help_point', 10000, 10),
  siren('siren', 2000, 10);

  const EmergencyPointKind(this.tag, this.radiusMetres, this.kept);

  /// The value of `emergency=*` in OpenStreetMap.
  final String tag;

  /// How far around the place it is looked for. A well is something to
  /// walk to with a canister, a help point something to cycle to; a siren
  /// further than two kilometres away is not heard.
  final int radiusMetres;

  /// How many of the nearest are kept. Berlin has more than four hundred
  /// wells within five kilometres of its centre, and the fortieth nearest
  /// is not an answer to anything.
  final int kept;

  int get radiusKm => radiusMetres ~/ 1000;

  static EmergencyPointKind? fromTag(String? tag) {
    for (final kind in values) {
      if (kind.tag == tag) return kind;
    }
    return null;
  }
}

class EmergencyPoint {
  const EmergencyPoint({
    required this.id,
    required this.kind,
    required this.latitude,
    required this.longitude,
    this.tags = const {},
  });

  final int id;
  final EmergencyPointKind kind;
  final double latitude;
  final double longitude;
  final Map<String, String> tags;

  String? get name => tags['name'] ?? tags['official_name'];

  /// The Berlin wells carry a number on the pump, and that number is how
  /// the district refers to them.
  String? get ref => tags['ref'] ?? tags['official_ref'];

  /// The address, from `addr:*` or -- as Berlin maps its help points --
  /// from `contact:*`.
  String? get address {
    if (tags['addr:full'] ?? tags['contact:full'] case final full?) {
      return full;
    }
    for (final prefix in const ['addr', 'contact']) {
      final street = tags['$prefix:street'];
      if (street == null) continue;
      final number = tags['$prefix:housenumber'];
      return number == null ? street : '$street $number';
    }
    return null;
  }

  String? get openingHours => tags['opening_hours'];
  String? get operator => tags['operator'];

  /// A well whose pump somebody found broken or locked on their last
  /// check. Kept in the list -- it may be fixed by now, and the next one
  /// may be far -- but said.
  bool get outOfOrder => const {
    'broken',
    'locked',
    'out_of_order',
    'no',
  }.contains(tags['pump:status'] ?? tags['operational_status']);

  /// The range a mapper gave the siren, in metres, where one did.
  int? get sirenRangeMetres {
    final raw = tags['siren:range'];
    if (raw == null) return null;
    final match = RegExp(r'^\s*(\d+(?:[.,]\d+)?)\s*(km|m)?\s*$').firstMatch(
      raw,
    );
    if (match == null) return null;
    final value = double.parse(match.group(1)!.replaceAll(',', '.'));
    return (match.group(2) == 'km' ? value * 1000 : value).round();
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.tag,
    'lat': latitude,
    'lon': longitude,
    'tags': tags,
  };

  static EmergencyPoint? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final kind = EmergencyPointKind.fromTag(json['kind'] as String?);
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (id is! int || kind == null || lat == null || lon == null) return null;
    final tags = json['tags'];
    return EmergencyPoint(
      id: id,
      kind: kind,
      latitude: lat,
      longitude: lon,
      tags: {
        if (tags is Map)
          for (final entry in tags.entries) '${entry.key}': '${entry.value}',
      },
    );
  }
}

/// Whether the nearest siren is likely to be heard at the place.
///
/// The rule of thumb is the one for the E57, the motor siren the federal
/// government had built from 1957 and the yardstick electronic sirens are
/// still funded against: about 400 m in a town, 600 m in a suburb, 850 m
/// over open land. Wind, buildings and closed windows move that a long
/// way, so this says "likely", not "yes". A range a mapper entered for
/// that very siren overrides the rule.
enum SirenReach { likely, maybe, unlikely, none }

const sirenTownMetres = 400;
const sirenOpenLandMetres = 850;

SirenReach sirenReach(double? nearestMetres, {int? rangeMetres}) {
  if (nearestMetres == null) return SirenReach.none;
  if (rangeMetres != null) {
    return nearestMetres <= rangeMetres
        ? SirenReach.likely
        : SirenReach.unlikely;
  }
  if (nearestMetres <= sirenTownMetres) return SirenReach.likely;
  if (nearestMetres <= sirenOpenLandMetres) return SirenReach.maybe;
  return SirenReach.unlikely;
}

class EmergencyPointClient {
  EmergencyPointClient({http.Client? httpClient, Duration? retryDelay})
    : _ownsClient = httpClient == null,
      _httpClient = httpClient ?? http.Client(),
      _retryDelay = retryDelay ?? OverpassShelterClient.defaultRetryDelay;

  final http.Client _httpClient;
  final bool _ownsClient;
  final Duration _retryDelay;

  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// The nearest of each kind, nearest first. Throws an
  /// `OverpassException` when no instance answered.
  ///
  /// One request with an `out` per kind rather than one union: under a
  /// shared limit Berlin's wells filled every slot and pushed out the help
  /// points and sirens.
  Future<List<EmergencyPoint>> near(double latitude, double longitude) async {
    final query = StringBuffer('[out:json][timeout:25];');
    for (final kind in EmergencyPointKind.values) {
      query.write(
        'node["emergency"="${kind.tag}"]'
        '(around:${kind.radiusMetres},$latitude,$longitude);out 2000;',
      );
    }
    final response = await askOverpass(
      _httpClient,
      query.toString(),
      retryDelay: _retryDelay,
    );
    return parseEmergencyPoints(
      utf8.decode(response.bodyBytes),
      latitude,
      longitude,
    );
  }
}

/// The nearest [EmergencyPointKind.kept] of each kind in an Overpass
/// answer, nearest first.
List<EmergencyPoint> parseEmergencyPoints(
  String body,
  double latitude,
  double longitude,
) {
  final decoded = jsonDecode(body);
  final elements = decoded is Map ? decoded['elements'] : null;
  if (elements is! List) return const [];
  final byKind = <EmergencyPointKind, List<EmergencyPoint>>{};
  for (final element in elements) {
    if (element is! Map || element['type'] != 'node') continue;
    final tags = element['tags'];
    final kind = EmergencyPointKind.fromTag(
      tags is Map ? tags['emergency'] as String? : null,
    );
    if (kind == null) continue;
    final point = EmergencyPoint.fromJson({
      'id': element['id'],
      'kind': kind.tag,
      'lat': element['lat'],
      'lon': element['lon'],
      'tags': tags,
    });
    if (point != null) (byKind[kind] ??= []).add(point);
  }
  double away(EmergencyPoint point) =>
      distanceMetres(latitude, longitude, point.latitude, point.longitude);
  return [
    for (final kind in EmergencyPointKind.values)
      ...((byKind[kind] ?? [])..sort((a, b) => away(a).compareTo(away(b))))
          .take(kind.kept),
  ];
}

/// The last search, for the day without a network.
class EmergencyPointSearch {
  const EmergencyPointSearch({
    required this.latitude,
    required this.longitude,
    required this.checkedAt,
    required this.found,
    this.placeName,
  });

  final double latitude;
  final double longitude;
  final String? placeName;
  final DateTime checkedAt;
  final List<EmergencyPoint> found;

  List<EmergencyPoint> of(EmergencyPointKind kind) => [
    for (final point in found)
      if (point.kind == kind) point,
  ];

  double distanceTo(EmergencyPoint point) =>
      distanceMetres(latitude, longitude, point.latitude, point.longitude);

  /// The nearest siren and what follows from it.
  SirenReach get sirenReachHere {
    final sirens = of(EmergencyPointKind.siren);
    if (sirens.isEmpty) return SirenReach.none;
    // A siren further away with a mapped range may reach where the nearest
    // one does not; the best of them is the answer.
    var best = SirenReach.unlikely;
    for (final siren in sirens) {
      final reach = sirenReach(
        distanceTo(siren),
        rangeMetres: siren.sirenRangeMetres,
      );
      if (reach.index < best.index) best = reach;
    }
    return best;
  }

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'placeName': placeName,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
    'found': [for (final point in found) point.toJson()],
  };

  static EmergencyPointSearch? fromJson(Object? json) {
    if (json is! Map) return null;
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final checkedAt = DateTime.tryParse('${json['checkedAt']}');
    final found = json['found'];
    if (latitude == null || longitude == null || checkedAt == null) {
      return null;
    }
    return EmergencyPointSearch(
      latitude: latitude,
      longitude: longitude,
      placeName: json['placeName'] as String?,
      checkedAt: checkedAt,
      found: [
        if (found is List)
          for (final item in found) ?EmergencyPoint.fromJson(item),
      ],
    );
  }
}

/// Kept encrypted: the place searched around is usually home.
class EmergencyPointStore {
  const EmergencyPointStore();

  static const _key = 'emergencyPointSearch.v1';

  Future<EmergencyPointSearch?> load() async {
    try {
      final raw = await const PrivatePreferences().getString(_key);
      if (raw == null) return null;
      return EmergencyPointSearch.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> save(EmergencyPointSearch search) =>
      const PrivatePreferences().setString(_key, jsonEncode(search.toJson()));
}
