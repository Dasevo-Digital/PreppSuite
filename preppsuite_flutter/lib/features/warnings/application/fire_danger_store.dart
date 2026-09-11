import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'fire_danger_client.dart';
import 'fire_danger_level.dart';

/// Which fire-danger station this household watches, and its last
/// forecast.
///
/// Preferences rather than the database, the same as the gauge and the
/// radiation probe: the choice is per device.
///
/// The last forecast is kept so the screen has something to show while
/// offline. It is shown with the day it was issued for and never as if
/// it were today's — which matters more here than for the other two,
/// because the DWD stops issuing outside the fire season and a level
/// from October would otherwise stand all winter.
class FireDangerStore {
  const FireDangerStore();

  static const _stationKey = 'fireDangerStation';
  static const _forecastKey = 'fireDangerLastForecast';

  Future<FireDangerStation?> loadStation() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _stationKey,
      );
      if (raw == null) return null;
      return FireDangerStation.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> saveStation(FireDangerStation station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stationKey, jsonEncode(station.toJson()));
      // The kept forecast belongs to the old station.
      await prefs.remove(_forecastKey);
    } on Object {
      return;
    }
  }

  Future<void> clearStation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_stationKey);
      await prefs.remove(_forecastKey);
    } on Object {
      return;
    }
  }

  Future<FireDangerForecast?> loadForecast() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _forecastKey,
      );
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final issued = DateTime.tryParse(json['issuedFor'] as String? ?? '');
      final steps = json['days'];
      if (issued == null || steps is! List) return null;

      final days = <FireDangerLevel>[];
      for (final step in steps) {
        final level = step is int ? FireDangerLevel.fromStep(step) : null;
        if (level == null) return null;
        days.add(level);
      }
      if (days.isEmpty) return null;

      return FireDangerForecast(
        stationName: json['stationName'] as String? ?? '',
        issuedFor: issued,
        days: days,
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveForecast(FireDangerForecast forecast) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _forecastKey,
        jsonEncode({
          'stationName': forecast.stationName,
          'issuedFor': forecast.issuedFor.toIso8601String(),
          'days': [for (final day in forecast.days) day.step],
        }),
      );
    } on Object {
      return;
    }
  }
}
