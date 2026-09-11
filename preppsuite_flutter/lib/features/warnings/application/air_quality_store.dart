import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'air_quality_client.dart';
import 'air_quality_level.dart';

/// Which measuring station this household watches, and what it last read.
///
/// Preferences rather than the database, the same as the gauge and the
/// probe: the choice is per device, and pushing one person's station onto
/// another person's phone through the shared folder would be worse than
/// asking twice.
///
/// The last reading is kept so the screen has something to show while
/// offline — which for this app is the ordinary case. It is shown with
/// its timestamp and never as if it were current.
class AirQualityStore {
  const AirQualityStore();

  static const _stationKey = 'airQualityStation';
  static const _readingKey = 'airQualityLastReading';

  Future<AirQualityStation?> loadStation() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _stationKey,
      );
      if (raw == null) return null;
      return AirQualityStation.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> saveStation(AirQualityStation station) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_stationKey, jsonEncode(station.toJson()));
      // The kept reading belongs to the old station. Left behind, it
      // would appear under the new station's name at the next launch.
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

  Future<AirQualityReading?> loadReading() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _readingKey,
      );
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, Object?>) return null;

      final at = DateTime.tryParse(json['measuredAt'] as String? ?? '');
      final stationId = json['stationId'] as String?;
      if (at == null || stationId == null) return null;

      final components = <AirQualityComponent>[];
      for (final entry in (json['components'] as List? ?? const [])) {
        if (entry is! Map<String, Object?>) continue;
        final id = (entry['id'] as num?)?.toInt();
        final value = (entry['value'] as num?)?.toDouble();
        if (id == null || value == null) continue;
        components.add(
          AirQualityComponent(
            id: id,
            code: AirQualityClient.componentCodes[id] ?? '#$id',
            unit: AirQualityClient.componentUnits[id] ?? 'µg/m³',
            value: value,
            level: AirQualityClass.fromIndex((entry['level'] as num?)?.toInt()),
          ),
        );
      }

      return AirQualityReading(
        stationId: stationId,
        measuredAt: at,
        level: AirQualityClass.fromIndex((json['level'] as num?)?.toInt()),
        components: components,
        incomplete: json['incomplete'] as bool? ?? false,
      );
    } on Object {
      return null;
    }
  }

  Future<void> saveReading(AirQualityReading reading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _readingKey,
        jsonEncode({
          'stationId': reading.stationId,
          'measuredAt': reading.measuredAt.toIso8601String(),
          'level': reading.level.step,
          'incomplete': reading.incomplete,
          'components': [
            for (final component in reading.components)
              {
                'id': component.id,
                'value': component.value,
                'level': component.level.step,
              },
          ],
        }),
      );
    } on Object {
      return;
    }
  }
}
