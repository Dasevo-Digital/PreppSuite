import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'pegel_client.dart';
import 'pegel_level.dart';

/// Which gauge this household watches, and what it last read.
///
/// Preferences rather than the database: the choice is per device, like
/// the map archive and the notification settings. Two people in one
/// household can live on different sides of a river, and pushing one
/// person's gauge onto the other's phone through the shared folder would
/// be worse than asking twice.
///
/// The last reading is kept so the screen has something to show while
/// offline -- which for this app is the ordinary case and not the
/// exception. It is shown with its timestamp and never as if it were
/// current.
class PegelStore {
  const PegelStore();

  static const _stationKey = 'pegelStation';
  static const _readingKey = 'pegelLastReading';

  Future<PegelStation?> loadStation() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _stationKey,
      );
      if (raw == null) return null;
      return PegelStation.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> saveStation(PegelStation station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stationKey, jsonEncode(station.toJson()));
      // The kept reading belongs to the old gauge. Left behind, it would
      // appear under the new gauge's name at the next launch.
      await prefs.remove(_readingKey);
    } on Object {
      return;
    }
  }

  Future<void> clearStation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stationKey);
      await prefs.remove(_readingKey);
    } on Object {
      return;
    }
  }

  Future<PegelReading?> loadReading() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _readingKey,
      );
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final at = DateTime.tryParse(json['measuredAt'] as String? ?? '');
      final value = (json['centimetres'] as num?)?.toDouble();
      if (at == null || value == null) return null;

      final references = <PegelReference, double>{};
      final stored = json['references'];
      if (stored is Map) {
        for (final entry in stored.entries) {
          final reference = PegelReference.fromCode('${entry.key}');
          final level = (entry.value as num?)?.toDouble();
          if (reference != null && level != null) {
            references[reference] = level;
          }
        }
      }

      return PegelReading(
        stationName: json['stationName'] as String? ?? '',
        water: json['water'] as String? ?? '',
        centimetres: value,
        measuredAt: at,
        references: references,
        changeOverDay: (json['changeOverDay'] as num?)?.toDouble(),
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveReading(PegelReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _readingKey,
        jsonEncode({
          'stationName': reading.stationName,
          'water': reading.water,
          'centimetres': reading.centimetres,
          'measuredAt': reading.measuredAt.toIso8601String(),
          'changeOverDay': reading.changeOverDay,
          'references': {
            for (final entry in reading.references.entries)
              entry.key.code: entry.value,
          },
        }),
      );
    } on Object {
      return;
    }
  }
}
