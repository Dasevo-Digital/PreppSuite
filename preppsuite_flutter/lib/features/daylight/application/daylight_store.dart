import 'package:shared_preferences/shared_preferences.dart';

/// The place the almanac is worked out for.
class DaylightPlace {
  const DaylightPlace({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  final double latitude;
  final double longitude;

  /// What the user called it. Optional — coordinates are the fact, a name
  /// is a convenience.
  final String? name;
}

/// Remembers that place.
///
/// Kept rather than asked for each time, and this is the point: the
/// screen exists for the day the position lookup has nothing to talk to
/// either. A place set once on a good day still works on a bad one.
class DaylightStore {
  const DaylightStore();

  static const _latitudeKey = 'daylightLatitude';
  static const _longitudeKey = 'daylightLongitude';
  static const _nameKey = 'daylightPlaceName';

  Future<DaylightPlace?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final latitude = prefs.getDouble(_latitudeKey);
    final longitude = prefs.getDouble(_longitudeKey);
    if (latitude == null || longitude == null) return null;
    return DaylightPlace(
      latitude: latitude,
      longitude: longitude,
      name: prefs.getString(_nameKey),
    );
  }

  Future<void> save(DaylightPlace place) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latitudeKey, place.latitude);
    await prefs.setDouble(_longitudeKey, place.longitude);
    final name = place.name;
    if (name == null || name.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, name);
    }
  }
}

/// Reads "52.2689, 10.5268" — and the handful of other ways people write
/// the same thing.
///
/// Returns null rather than throwing: a half-typed coordinate is the
/// normal state of a text field, not an error.
DaylightPlace? parseCoordinates(String input, {String? name}) {
  // Comma as a separator and comma as a decimal point both occur, and on
  // a German keyboard the second is the likely one. A semicolon or a
  // space settles it outright; otherwise the number of commas does. Two
  // commas means one number carries a decimal point, four halves means
  // both do.
  final cleaned = input.trim().replaceAll('°', '');
  final List<String> parts;
  if (cleaned.contains(';')) {
    parts = cleaned.split(';');
  } else if (cleaned.contains(',')) {
    final pieces = cleaned.split(',');
    parts = switch (pieces.length) {
      // "52.2689, 10.5268"
      2 => pieces,
      // "52,2689, 10.5268" — the first number's decimal point is a comma.
      3 => ['${pieces[0]}.${pieces[1]}', pieces[2]],
      // "52,2689, 10,5268" — the form a German keyboard produces.
      4 => ['${pieces[0]}.${pieces[1]}', '${pieces[2]}.${pieces[3]}'],
      _ => const [],
    };
  } else {
    parts = cleaned.split(RegExp(r'\s+'));
  }

  if (parts.length != 2) return null;
  final latitude = double.tryParse(parts[0].trim().replaceAll(',', '.'));
  final longitude = double.tryParse(parts[1].trim().replaceAll(',', '.'));
  if (latitude == null || longitude == null) return null;
  if (latitude < -90 || latitude > 90) return null;
  if (longitude < -180 || longitude > 180) return null;

  return DaylightPlace(
    latitude: latitude,
    longitude: longitude,
    name: name == null || name.trim().isEmpty ? null : name.trim(),
  );
}
