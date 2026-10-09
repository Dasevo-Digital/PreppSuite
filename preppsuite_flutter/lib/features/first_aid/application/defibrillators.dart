import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../core/private_preferences.dart';
import '../../shelters/application/overpass_shelter_client.dart';
import '../../../core/http_client.dart';

/// Defibrillators near a place, from OpenStreetMap (#117).
///
/// There is no national register in Germany. A few districts publish
/// theirs as open data, each in its own format; OpenStreetMap has them
/// nationwide, mapped by volunteers, and usually with the one thing that
/// matters in the minute it is needed: where exactly in the building it
/// hangs. Measured on 2026-10-06: eighteen within two kilometres of
/// Braunschweig's centre, fourteen of them with a
/// `defibrillator:location` such as "Neben Raum 143, orangener Kasten".
///
/// The downloaded map does not carry them -- OpenMapTiles has no layer for
/// `emergency=*` -- so they are asked for once with a network and kept.
class Defibrillator {
  const Defibrillator({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.tags = const {},
  });

  final int id;
  final double latitude;
  final double longitude;
  final Map<String, String> tags;

  /// Where in the building, in [language] where somebody wrote it so.
  String? locationIn(String language) =>
      tags['defibrillator:location:$language'] ??
      tags['defibrillator:location'] ??
      tags['description:$language'] ??
      tags['description'];

  String? get name => tags['name'] ?? tags['operator'];
  String? get level => tags['level'];
  String? get openingHours => tags['opening_hours'];

  /// `yes`, `no`, or null when nobody said.
  bool? get indoor => switch (tags['indoor']) {
    'yes' => true,
    'no' => false,
    _ => null,
  };

  /// Whether the mapper marked it as not open to the public.
  bool get restricted => const {
    'private',
    'no',
    'customers',
  }.contains(tags['access']);

  Map<String, Object?> toJson() => {
    'id': id,
    'lat': latitude,
    'lon': longitude,
    'tags': tags,
  };

  static Defibrillator? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final lat = (json['lat'] as num?)?.toDouble();
    final lon = (json['lon'] as num?)?.toDouble();
    if (id is! int || lat == null || lon == null) return null;
    final tags = json['tags'];
    return Defibrillator(
      id: id,
      latitude: lat,
      longitude: lon,
      tags: {
        if (tags is Map)
          for (final entry in tags.entries) '${entry.key}': '${entry.value}',
      },
    );
  }
}

/// How far around the place they are looked for. Far enough to cover a
/// neighbourhood and its schools, shops and stations; near enough that
/// the list is about this place and not the town.
const defibrillatorRadiusMetres = 2000;

/// Distance in metres, on a sphere -- plenty at two kilometres.
double distanceMetres(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          sin(dLon / 2) *
          sin(dLon / 2);
  return 2 * earth * asin(sqrt(a));
}

/// The compass direction from the first point to the second, 0 to 7 for
/// north, north-east and so on round.
int compassOctant(double lat1, double lon1, double lat2, double lon2) {
  final y = sin((lon2 - lon1) * pi / 180) * cos(lat2 * pi / 180);
  final x =
      cos(lat1 * pi / 180) * sin(lat2 * pi / 180) -
      sin(lat1 * pi / 180) *
          cos(lat2 * pi / 180) *
          cos((lon2 - lon1) * pi / 180);
  final bearing = (atan2(y, x) * 180 / pi + 360) % 360;
  return ((bearing + 22.5) ~/ 45) % 8;
}

class DefibrillatorClient {
  DefibrillatorClient({http.Client? httpClient, Duration? retryDelay})
    : _ownsClient = httpClient == null,
      _httpClient = httpClient ?? TimeoutClient(),
      _retryDelay = retryDelay ?? OverpassShelterClient.defaultRetryDelay;

  final http.Client _httpClient;
  final bool _ownsClient;
  final Duration _retryDelay;

  void close() {
    if (_ownsClient) _httpClient.close();
  }

  /// Every defibrillator within [defibrillatorRadiusMetres], nearest
  /// first. Throws an `OverpassException` when no instance answered.
  Future<List<Defibrillator>> near(double latitude, double longitude) async {
    final query =
        '[out:json][timeout:25];'
        'node["emergency"="defibrillator"]'
        '(around:$defibrillatorRadiusMetres,$latitude,$longitude);'
        'out 200;';
    final response = await askOverpass(
      _httpClient,
      query,
      retryDelay: _retryDelay,
    );
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final elements = decoded is Map ? decoded['elements'] : null;
    if (elements is! List) return const [];
    final found = [
      for (final element in elements)
        if (element is Map && element['type'] == 'node')
          ?Defibrillator.fromJson({
            'id': element['id'],
            'lat': element['lat'],
            'lon': element['lon'],
            'tags': element['tags'],
          }),
    ];
    found.sort(
      (a, b) => distanceMetres(
        latitude,
        longitude,
        a.latitude,
        a.longitude,
      ).compareTo(distanceMetres(latitude, longitude, b.latitude, b.longitude)),
    );
    return found;
  }
}

/// The last search, for the day without a network.
class DefibrillatorSearch {
  const DefibrillatorSearch({
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
  final List<Defibrillator> found;

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'placeName': placeName,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
    'found': [for (final d in found) d.toJson()],
  };

  static DefibrillatorSearch? fromJson(Object? json) {
    if (json is! Map) return null;
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final checkedAt = DateTime.tryParse('${json['checkedAt']}');
    final found = json['found'];
    if (latitude == null || longitude == null || checkedAt == null) {
      return null;
    }
    return DefibrillatorSearch(
      latitude: latitude,
      longitude: longitude,
      placeName: json['placeName'] as String?,
      checkedAt: checkedAt,
      found: [
        if (found is List)
          for (final item in found) ?Defibrillator.fromJson(item),
      ],
    );
  }
}

/// Kept encrypted: the place searched around is usually home.
class DefibrillatorStore {
  const DefibrillatorStore();

  static const _key = 'defibrillatorSearch.v1';

  Future<DefibrillatorSearch?> load() async {
    try {
      final raw = await const PrivatePreferences().getString(_key);
      if (raw == null) return null;
      return DefibrillatorSearch.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> save(DefibrillatorSearch search) =>
      const PrivatePreferences().setString(_key, jsonEncode(search.toJson()));
}
