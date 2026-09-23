import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'geo_bounds.dart';
import 'shelter_classification.dart';

/// A last-known answer from the public shelter directories.
///
/// Overpass is deliberately rate-limited and WWBOTA is a volunteer service.
/// A temporary refusal must not turn a previously useful, explicitly dated
/// list into an empty map. The cache stays on this device and is only used for
/// the same search area; it never changes a shelter's confidence.
class ShelterCacheEntry {
  const ShelterCacheEntry({required this.savedAt, required this.shelters});

  final DateTime savedAt;
  final List<ClassifiedShelter> shelters;
}

class ShelterCache {
  const ShelterCache();

  static const _prefix = 'shelterCache.v1.';

  /// A week is long enough to bridge a public-service outage, while the UI
  /// always says when this answer was last confirmed.
  static const maxAge = Duration(days: 7);

  Future<ShelterCacheEntry?> load(GeoBoundingBox bounds) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      _prefix + _keyFor(bounds),
    );
    if (raw == null) return null;

    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?> || json['savedAt'] is! int) {
        return null;
      }
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        json['savedAt'] as int,
        isUtc: true,
      );
      if (DateTime.now().toUtc().difference(savedAt) > maxAge) return null;
      final values = json['shelters'];
      if (values is! List) return null;
      return ShelterCacheEntry(
        savedAt: savedAt,
        shelters: [
          for (final value in values)
            if (value is Map<String, Object?>) _shelterFromJson(value),
        ].whereType<ClassifiedShelter>().toList(growable: false),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> save(
    GeoBoundingBox bounds,
    List<ClassifiedShelter> shelters,
  ) async {
    final raw = jsonEncode({
      'savedAt': DateTime.now().toUtc().millisecondsSinceEpoch,
      'shelters': shelters.map(_shelterToJson).toList(growable: false),
    });
    await (await SharedPreferences.getInstance()).setString(
      _prefix + _keyFor(bounds),
      raw,
    );
  }

  /// Five decimals are approximately a metre. This is deliberate: the map
  /// searches a bounding box, so a nearby search should reuse the matching
  /// answer rather than potentially show shelters from a different radius.
  static String _keyFor(GeoBoundingBox bounds) => [
    bounds.south,
    bounds.west,
    bounds.north,
    bounds.east,
  ].map((value) => value.toStringAsFixed(5)).join(':');

  static Map<String, Object?> _shelterToJson(ClassifiedShelter shelter) => {
    'id': shelter.id,
    'name': shelter.name,
    'lat': shelter.lat,
    'lon': shelter.lon,
    'confidence': shelter.confidence.name,
    'source': shelter.sourceLabel,
    'subtitle': shelter.subtitle,
  };

  static ClassifiedShelter? _shelterFromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final lat = json['lat'];
    final lon = json['lon'];
    final confidence = json['confidence'];
    final source = json['source'];
    if (id is! String ||
        name is! String ||
        lat is! num ||
        lon is! num ||
        confidence is! String ||
        source is! String) {
      return null;
    }
    ShelterConfidence? value;
    for (final candidate in ShelterConfidence.values) {
      if (candidate.name == confidence) {
        value = candidate;
        break;
      }
    }
    if (value == null) return null;
    return ClassifiedShelter(
      id: id,
      name: name,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      confidence: value,
      sourceLabel: source,
      subtitle: json['subtitle'] as String?,
    );
  }
}
