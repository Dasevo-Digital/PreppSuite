import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'radiation_client.dart';
import 'radiation_level.dart';

/// Which probe this household watches, and what it last read.
///
/// Preferences rather than the database, the same as the gauge: the
/// choice is per device, and pushing one person's probe onto another
/// person's phone through the shared folder would be worse than asking
/// twice.
///
/// The last reading is kept so the screen has something to show while
/// offline — which for this app is the ordinary case. It is shown with
/// its timestamp and never as if it were current.
class RadiationStore {
  const RadiationStore();

  static const _stationKey = 'radiationStation';
  static const _readingKey = 'radiationLastReading';

  Future<RadiationStation?> loadStation() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _stationKey,
      );
      if (raw == null) return null;
      return RadiationStation.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> saveStation(RadiationStation station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stationKey, jsonEncode(station.toJson()));
      // The kept reading belongs to the old probe. Left behind, it would
      // appear under the new probe's name at the next launch.
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

  Future<RadiationReading?> loadReading() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _readingKey,
      );
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final at = DateTime.tryParse(json['measuredAt'] as String? ?? '');
      final value = (json['microsievertsPerHour'] as num?)?.toDouble();
      if (at == null || value == null) return null;

      return RadiationReading(
        stationName: json['stationName'] as String? ?? '',
        microsievertsPerHour: value,
        measuredAt: at,
        terrestrial: (json['terrestrial'] as num?)?.toDouble(),
        cosmic: (json['cosmic'] as num?)?.toDouble(),
        baseline: (json['baseline'] as num?)?.toDouble(),
        // Absent in anything written before the flag was stored. True is
        // the right default: the service publishes validated values for
        // everything older than a few hours.
        validated: json['validated'] as bool? ?? true,
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveReading(RadiationReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _readingKey,
        jsonEncode({
          'stationName': reading.stationName,
          'microsievertsPerHour': reading.microsievertsPerHour,
          'measuredAt': reading.measuredAt.toIso8601String(),
          'terrestrial': reading.terrestrial,
          'cosmic': reading.cosmic,
          'baseline': reading.baseline,
          'validated': reading.validated,
        }),
      );
    } on Object {
      return;
    }
  }
}
