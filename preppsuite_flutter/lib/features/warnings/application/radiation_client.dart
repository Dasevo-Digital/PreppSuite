import 'dart:convert';

import 'package:http/http.dart' as http;

import 'radiation_level.dart';

/// One probe of the federal gamma dose-rate network.
class RadiationStation {
  const RadiationStation({
    required this.id,
    required this.name,
    this.postalCode,
    this.latitude,
    this.longitude,
    this.heightAboveSea,
  });

  /// The nine-digit `kenn`, which is what the time-series layer wants.
  final String id;

  /// The place the probe stands in — "Hausach", "Braunschweig".
  final String name;

  final String? postalCode;
  final double? latitude;
  final double? longitude;

  /// Metres above sea level. Worth keeping: the cosmic part of the
  /// reading is a function of altitude, so this is half the explanation
  /// of why one station reads higher than another.
  final int? heightAboveSea;

  static RadiationStation? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    return RadiationStation(
      id: id,
      name: name,
      postalCode: json['postalCode'] as String?,
      latitude: _number(json['latitude']),
      longitude: _number(json['longitude']),
      heightAboveSea: (json['heightAboveSea'] as num?)?.round(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'postalCode': postalCode,
    'latitude': latitude,
    'longitude': longitude,
    'heightAboveSea': heightAboveSea,
  };
}

/// Reads gamma dose rates from the BfS's open interface.
///
/// Open data of the Bundesamt für Strahlenschutz, no key and no account,
/// which is the only reason this is in the app at all — a credential
/// shipped inside a client is a credential given away. Datenlizenz
/// Deutschland 2.0, which asks for attribution and gets it on the screen.
///
/// About 1700 probes, GeoJSON over a WFS. Everything here returns null on
/// failure rather than throwing: this app is used offline as the ordinary
/// case, and a screen that keeps the last reading and says how old it is
/// beats one that shows an error.
class RadiationClient {
  RadiationClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _host = 'www.imis.bfs.de';
  static const _path = '/ogc/opendata/ows';

  /// Current hourly value for every station, in one request.
  ///
  /// One request for all of them because that is what the service offers
  /// — there is no per-station "latest" layer — and because the picker
  /// needs every station's coordinates anyway. It is about 900 KB, so it
  /// is fetched when somebody opens the picker and not on a schedule.
  static const latestLayer = 'opendata:odlinfo_odl_1h_latest';

  /// The last seven days of hourly values for one station.
  static const seriesLayer = 'opendata:odlinfo_timeseries_odl_1h';

  Uri _uri(String layer, {String? station}) {
    return Uri.https(_host, _path, {
      'service': 'WFS',
      'version': '1.1.0',
      'request': 'GetFeature',
      'typeName': layer,
      'outputFormat': 'application/json',
      if (station != null) 'viewparams': 'kenn:$station',
    });
  }

  Future<List<Map<String, Object?>>?> _features(Uri uri) async {
    try {
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;

      // bodyBytes and not body: station names carry umlauts and the
      // header does not always name a charset, in which case `body`
      // decodes as Latin-1. That has bitten this app twice.
      final decoded = jsonDecode(
        utf8.decode(response.bodyBytes, allowMalformed: true),
      );
      if (decoded is! Map) return null;
      final features = decoded['features'];
      if (features is! List) return null;

      return [
        for (final feature in features)
          if (feature is Map<String, Object?>) feature,
      ];
    } on Object {
      return null;
    }
  }

  /// Every station the network currently reports, with its position.
  ///
  /// Stations out of service are dropped: they carry no value, and a
  /// picker offering a probe that answers nothing is worse than a shorter
  /// list.
  Future<List<RadiationStation>> fetchStations() async {
    final features = await _features(_uri(latestLayer));
    if (features == null) return const [];

    final stations = <RadiationStation>[];
    for (final feature in features) {
      final reading = _stationOf(feature);
      if (reading != null) stations.add(reading);
    }
    return stations;
  }

  /// The newest value for [station], with the station's own baseline
  /// worked out from its recent series.
  ///
  /// Two requests, and the second is the one that makes the number
  /// readable: without the station's own median, 0.16 µSv/h in the Black
  /// Forest and 0.16 µSv/h on the North Sea coast look alike, and only
  /// one of them is ordinary.
  Future<RadiationReading?> fetchReading(RadiationStation station) async {
    final features = await _features(
      _uri(seriesLayer, station: station.id),
    );
    if (features == null || features.isEmpty) return null;

    ({DateTime at, double value, bool validated})? newest;
    final values = <double>[];

    for (final feature in features) {
      final sample = _sampleOf(feature);
      if (sample == null) continue;
      values.add(sample.value);
      if (newest == null || sample.at.isAfter(newest.at)) newest = sample;
    }
    if (newest == null) return null;

    return RadiationReading(
      stationName: station.name,
      microsievertsPerHour: newest.value,
      measuredAt: newest.at,
      baseline: baselineFrom(values),
      validated: newest.validated,
    );
  }

  /// The current reading for [station] out of the all-stations layer.
  ///
  /// Cheaper than [fetchReading] where the list has just been fetched,
  /// and it carries the cosmic/terrestrial split that the series does
  /// not. No baseline, so the band falls back to the national range.
  RadiationReading? readingFrom(
    Map<String, Object?> feature,
    RadiationStation station,
  ) {
    final properties = feature['properties'];
    if (properties is! Map) return null;

    final sample = _sampleOf(feature);
    if (sample == null) return null;

    return RadiationReading(
      stationName: station.name,
      microsievertsPerHour: sample.value,
      measuredAt: sample.at,
      terrestrial: _number(properties['value_terrestrial']),
      cosmic: _number(properties['value_cosmic']),
      validated: sample.validated,
    );
  }

  void close() => _httpClient.close();

  /// A station out of a GeoJSON feature, or null where it is unusable.
  static RadiationStation? _stationOf(Map<String, Object?> feature) {
    final properties = feature['properties'];
    if (properties is! Map) return null;

    final id = properties['kenn'];
    final name = properties['name'];
    if (id is! String || id.isEmpty || name is! String || name.isEmpty) {
      return null;
    }
    // `site_status` 1 is in service. Anything else reports nothing.
    if ((properties['site_status'] as num?)?.round() != 1) return null;

    final coordinates = (feature['geometry'] as Map?)?['coordinates'];
    double? longitude;
    double? latitude;
    if (coordinates is List && coordinates.length >= 2) {
      longitude = _number(coordinates[0]);
      latitude = _number(coordinates[1]);
    }

    return RadiationStation(
      id: id,
      name: name,
      postalCode: properties['plz'] as String?,
      latitude: latitude,
      longitude: longitude,
      heightAboveSea: (properties['height_above_sea'] as num?)?.round(),
    );
  }

  /// One hourly sample.
  ///
  /// The end of the measuring hour is the sample's time, not the start:
  /// a value labelled 05:00–06:00 is what the air was doing until six,
  /// and calling it five o'clock would make every reading look an hour
  /// staler than it is.
  static ({DateTime at, double value, bool validated})? _sampleOf(
    Map<String, Object?> feature,
  ) {
    final properties = feature['properties'];
    if (properties is! Map) return null;

    final value = _number(properties['value']);
    final at = DateTime.tryParse('${properties['end_measure']}');
    if (value == null || at == null) return null;

    return (
      at: at.toUtc(),
      value: value,
      validated: (properties['validated'] as num?)?.round() == 1,
    );
  }
}

double? _number(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
