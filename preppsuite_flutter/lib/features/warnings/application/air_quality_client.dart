import 'dart:convert';

import 'package:http/http.dart' as http;

import 'air_quality_level.dart';

/// One measuring station of the federal air quality network.
class AirQualityStation {
  const AirQualityStation({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.latitude,
    this.longitude,
    this.setting,
  });

  /// The numeric station id the readings are asked for by.
  final String id;

  /// The station's own name — "Potsdam-Zentrum".
  final String name;

  /// The place it stands in, where that differs from the name.
  final String? city;

  /// The state that runs it, as the UBA's network name.
  final String? state;

  final double? latitude;
  final double? longitude;

  /// "städtisches Gebiet", "ländlich regional" — worth showing, because
  /// a kerbside station and a rural one are not measuring the same thing
  /// and the difference between them is not a fault.
  final String? setting;

  static AirQualityStation? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    return AirQualityStation(
      id: id,
      name: name,
      city: json['city'] as String?,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      setting: json['setting'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'city': city,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'setting': setting,
  };
}

/// Reads the air quality index from the Umweltbundesamt's open interface.
///
/// No key and no account. The index, its five classes and the thresholds
/// behind them are all the UBA's; this only fetches and parses them.
///
/// Two shapes of answer, both keyed by position rather than by name — the
/// interface sends an `indices` block naming the columns and then rows of
/// bare arrays. The column order is pinned here as constants so a shift
/// in it shows up as a parse failure rather than as a station standing in
/// the wrong federal state.
class AirQualityClient {
  AirQualityClient({http.Client? httpClient, Duration? retryDelay})
    : _httpClient = httpClient ?? http.Client(),
      _retryDelay = retryDelay ?? const Duration(seconds: 2);

  final http.Client _httpClient;

  /// The interface answers the same request with a 404 now and then —
  /// seen twice while this was written, and ten repeats of the same call
  /// straight after were all 200. One retry rather than a budget: it is a
  /// hiccup, not an outage, and an outage should still be reported.
  final Duration _retryDelay;

  static const base = 'https://luftdaten.umweltbundesamt.de/api/air-data/v3';

  /// `aq` is the classic index the `airquality` endpoint returns, at
  /// scope 2 — the one-hour mean. The UBA also publishes `aq4`, its
  /// revision after the WHO's 2021 guidelines, on the same endpoint;
  /// mixing the two would put a reading in the wrong class.
  static const thresholdType = 'aq';
  static const hourlyScope = '2';

  /// Column positions in a station row.
  static const _stationId = 0;
  static const _stationName = 2;
  static const _stationCity = 3;
  static const _stationLongitude = 7;
  static const _stationLatitude = 8;
  static const _stationNetworkName = 13;
  static const _stationSetting = 14;

  /// Every station that reports an air quality index.
  Future<List<AirQualityStation>> fetchStations({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final uri = Uri.parse(
      '$base/stations/json?use=airquality&lang=de'
      '&date_from=${_date(yesterday)}&time_from=1'
      '&date_to=${_date(today)}&time_to=24',
    );
    return parseStations(await _get(uri));
  }

  /// The newest hour this station has an index for.
  ///
  /// Asked over two days rather than one: the interface publishes an hour
  /// once it is complete, so shortly after midnight the newest reading
  /// belongs to the day before.
  Future<AirQualityReading?> fetchReading(
    String stationId, {
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final uri = Uri.parse(
      '$base/airquality/json?lang=de&station=$stationId'
      '&date_from=${_date(yesterday)}&time_from=1'
      '&date_to=${_date(today)}&time_to=24',
    );
    return parseReading(await _get(uri), stationId);
  }

  /// The UBA's own class boundaries, per pollutant, for the hourly index.
  ///
  /// Fetched rather than written down here: they are the part most likely
  /// to change — they already did once, after the WHO's 2021 guidelines —
  /// and a threshold this app remembers wrongly is exactly the invented
  /// scale it must not ship.
  Future<Map<int, List<AirQualityThreshold>>> fetchThresholds() async {
    final uri = Uri.parse(
      'https://luftdaten.umweltbundesamt.de/api/air-data/v4'
      '/thresholds/json?lang=de',
    );
    return parseThresholds(await _get(uri));
  }

  Future<String> _get(Uri uri) async {
    var response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      await Future<void>.delayed(_retryDelay);
      response = await _httpClient.get(uri);
    }
    if (response.statusCode != 200) {
      throw AirQualityException(response.statusCode);
    }
    // Never `response.body`: without a charset in the header that decodes
    // as Latin-1, and every second station name here carries an umlaut.
    return utf8.decode(response.bodyBytes, allowMalformed: true);
  }

  static String _date(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static List<AirQualityStation> parseStations(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return const [];
    final data = decoded['data'];
    if (data is! Map<String, Object?>) return const [];

    final stations = <AirQualityStation>[];
    for (final row in data.values) {
      if (row is! List || row.length <= _stationSetting) continue;
      final id = row[_stationId];
      final name = row[_stationName];
      if (id is! String || name is! String || name.isEmpty) continue;

      final city = row[_stationCity];
      stations.add(
        AirQualityStation(
          id: id,
          name: name,
          city: city is String && city.isNotEmpty && city != name ? city : null,
          state: _text(row[_stationNetworkName]),
          latitude: double.tryParse('${row[_stationLatitude]}'),
          longitude: double.tryParse('${row[_stationLongitude]}'),
          setting: _text(row[_stationSetting]),
        ),
      );
    }
    stations.sort((a, b) => a.name.compareTo(b.name));
    return stations;
  }

  /// The newest hour in an `airquality` answer, or null when the station
  /// reported nothing over the whole window.
  static AirQualityReading? parseReading(String body, String stationId) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;
    final data = decoded['data'];
    if (data is! Map<String, Object?>) return null;
    final hours =
        data[stationId] ?? (data.length == 1 ? data.values.first : null);
    if (hours is! Map<String, Object?>) return null;

    AirQualityReading? newest;
    for (final row in hours.values) {
      if (row is! List || row.length < 3) continue;
      final measuredAt = DateTime.tryParse('${row[0]}'.replaceFirst(' ', 'T'));
      if (measuredAt == null) continue;
      if (newest != null && !measuredAt.isAfter(newest.measuredAt)) continue;

      final components = <AirQualityComponent>[];
      for (final part in row.skip(3)) {
        if (part is! List || part.length < 3) continue;
        final id = (part[0] as num?)?.toInt();
        final value = (part[1] as num?)?.toDouble();
        if (id == null || value == null) continue;
        components.add(
          AirQualityComponent(
            id: id,
            code: componentCodes[id] ?? '#$id',
            unit: componentUnits[id] ?? 'µg/m³',
            value: value,
            level: AirQualityClass.fromIndex((part[2] as num?)?.toInt()),
          ),
        );
      }

      newest = AirQualityReading(
        stationId: stationId,
        measuredAt: measuredAt,
        level: AirQualityClass.fromIndex((row[1] as num?)?.toInt()),
        components: components,
        incomplete: row[2] == 1 || row[2] == true,
      );
    }
    return newest;
  }

  /// Class boundaries by component id, for the hourly index only.
  static Map<int, List<AirQualityThreshold>> parseThresholds(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return const {};

    final byComponent = <int, List<AirQualityThreshold>>{};
    for (final entry in decoded.entries) {
      if (entry.key == 'count' || entry.key == 'indices') continue;
      final row = entry.value;
      if (row is! List || row.length < 7) continue;
      if ('${row[2]}' != hourlyScope || '${row[3]}' != thresholdType) continue;

      final component = int.tryParse('${row[1]}');
      final min = double.tryParse('${row[4]}');
      final max = double.tryParse('${row[5]}');
      final index = int.tryParse('${row[6]}');
      if (component == null || min == null || max == null || index == null) {
        continue;
      }
      (byComponent[component] ??= []).add(
        AirQualityThreshold(
          level: AirQualityClass.fromIndex(index),
          min: min,
          max: max,
        ),
      );
    }
    for (final list in byComponent.values) {
      list.sort((a, b) => a.min.compareTo(b.min));
    }
    return byComponent;
  }

  /// The five pollutants the index is built from. Few, fixed and named
  /// the same way for years, so they are written down rather than fetched
  /// — the screen has to name them with no connection as well.
  static const componentCodes = <int, String>{
    1: 'PM₁₀',
    3: 'O₃',
    4: 'SO₂',
    5: 'NO₂',
    9: 'PM₂,₅',
  };

  static const componentUnits = <int, String>{
    1: 'µg/m³',
    3: 'µg/m³',
    4: 'µg/m³',
    5: 'µg/m³',
    9: 'µg/m³',
  };

  static String? _text(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
}

/// One class's span for one pollutant, as the UBA publishes it.
class AirQualityThreshold {
  const AirQualityThreshold({
    required this.level,
    required this.min,
    required this.max,
  });

  final AirQualityClass level;
  final double min;
  final double max;
}

class AirQualityException implements Exception {
  const AirQualityException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'AirQualityException: HTTP $statusCode';
}
