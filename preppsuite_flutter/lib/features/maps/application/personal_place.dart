import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A user-owned point on the map, stored only on this device.
///
/// It deliberately is not synchronised with a household: locations such as a
/// meeting point or a medicine cabinet are sensitive, and an offline map must
/// still work without an account or network connection.
class PersonalPlace {
  const PersonalPlace({
    required this.id,
    required this.label,
    required this.latitude,
    required this.longitude,
    this.note,
  });

  final String id;
  final String label;
  final double latitude;
  final double longitude;
  final String? note;

  Map<String, Object> toJson() => {
    'id': id,
    'label': label,
    'latitude': latitude,
    'longitude': longitude,
    if (note case final note? when note.isNotEmpty) 'note': note,
  };

  static PersonalPlace? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final label = value['label'];
    final latitude = value['latitude'];
    final longitude = value['longitude'];
    if (id is! String || label is! String) return null;
    final lat = latitude is num ? latitude.toDouble() : null;
    final lon = longitude is num ? longitude.toDouble() : null;
    if (id.isEmpty || label.trim().isEmpty || !isValidCoordinates(lat, lon)) {
      return null;
    }
    final note = value['note'];
    return PersonalPlace(
      id: id,
      label: label.trim(),
      latitude: lat!,
      longitude: lon!,
      note: note is String && note.trim().isNotEmpty ? note.trim() : null,
    );
  }

  static bool isValidCoordinates(double? latitude, double? longitude) =>
      latitude != null &&
      longitude != null &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Local storage for personal map places.
///
/// Malformed or manually edited preference data is ignored entry by entry. A
/// bad marker must never keep the map from opening in an emergency.
class PersonalPlaceStore {
  const PersonalPlaceStore();

  static const _key = 'personalMapPlaces.v1';

  Future<List<PersonalPlace>> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [for (final item in decoded) ?PersonalPlace.fromJson(item)];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<PersonalPlace> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (places.isEmpty) {
        await prefs.remove(_key);
        return;
      }
      await prefs.setString(
        _key,
        jsonEncode([for (final place in places) place.toJson()]),
      );
    } on Object {
      // Saving is best effort. The visible map remains usable for this run.
    }
  }
}
