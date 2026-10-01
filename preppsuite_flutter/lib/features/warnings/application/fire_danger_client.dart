import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/bounded_gzip.dart';

import 'fire_danger_level.dart';

/// One of the DWD's fire-danger stations.
class FireDangerStation {
  const FireDangerStation({
    required this.id,
    required this.name,
    this.state,
    this.latitude,
    this.longitude,
    this.heightAboveSea,
  });

  /// The `Stationsindex`, which is part of the file name for this
  /// station's own forecast.
  final String id;

  final String name;

  /// The Bundesland, as the list spells it. Shown because several
  /// stations share a place name and the state is what tells them apart.
  final String? state;

  final double? latitude;
  final double? longitude;
  final int? heightAboveSea;

  static FireDangerStation? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'];
    final name = json['name'];
    if (id is! String || id.isEmpty || name is! String) return null;
    return FireDangerStation(
      id: id,
      name: name,
      state: json['state'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      heightAboveSea: (json['heightAboveSea'] as num?)?.round(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'state': state,
    'latitude': latitude,
    'longitude': longitude,
    'heightAboveSea': heightAboveSea,
  };
}

/// Reads the Waldbrandgefahrenindex from the DWD's open data server.
///
/// Open data of the Deutscher Wetterdienst, no key and no account. The
/// woodland index only: the grassland index sits beside it in the same
/// directory, but the DWD does not publish its level wording where this
/// was written, and a five-step scale described in words somebody made
/// up is exactly what this app refuses to ship.
///
/// The shape of the service decides the shape of this client: there is
/// no "all stations, current value" file, so it is a station list plus
/// one gzipped CSV per station. That is two requests for a reading and
/// the reason the station is chosen once and kept.
class FireDangerClient {
  FireDangerClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _base =
      'https://opendata.dwd.de/climate_environment/CDC/derived_germany'
      '/fire_danger_index/woodland/forecast/recent';

  /// The dataset version is in every file name, so it is here once.
  static const _version = 'v2-3--0';

  static const _prefix =
      'derived_germany_fire_danger_index_woodland_forecast_recent';

  Uri get stationsUri =>
      Uri.parse('$_base/${_prefix}_${_version}_stations_list.txt');

  Uri forecastUri(String station) =>
      Uri.parse('$_base/${_prefix}_${station}_$_version.csv.gz');

  /// Every station in the list, with its position.
  ///
  /// The list is **Latin-1**, not UTF-8. It is the only file in this app
  /// that is, and reading it as UTF-8 turns "Großenkneten" into
  /// "Gro?enkneten" — the same class of mistake that put "franÃ§ais" in
  /// the library, from the other direction.
  Future<List<FireDangerStation>> fetchStations() async {
    try {
      final response = await _httpClient
          .get(stationsUri)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return const [];

      return parseStations(
        latin1.decode(response.bodyBytes, allowInvalid: true),
      );
    } on Object {
      return const [];
    }
  }

  /// The newest forecast for [station], or null.
  ///
  /// The file holds the whole season, one row per day, and the newest row
  /// is the one that matters.
  Future<FireDangerForecast?> fetchForecast(FireDangerStation station) async {
    try {
      final response = await _httpClient
          .get(forecastUri(station.id))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;

      // Bounded on both sides: a station's season file is about 4 KB
      // compressed and a few hundred unpacked, and this app has a rule
      // about not handing an unbounded stream to a decompressor. The
      // input limit alone did not keep it — two megabytes of gzip can
      // unpack to two gigabytes.
      if (response.bodyBytes.length > 2 * 1024 * 1024) return null;

      final csv = utf8.decode(
        gunzipBounded(response.bodyBytes, limit: 8 * 1024 * 1024),
        allowMalformed: true,
      );
      final rows = parseForecast(csv, station: station.name);
      return rows.isEmpty ? null : rows.first;
    } on Object {
      return null;
    }
  }

  void close() => _httpClient.close();

  /// The station list, which is a fixed-width table with semicolons in
  /// it rather than a CSV — every field is padded, so every field is
  /// trimmed.
  static List<FireDangerStation> parseStations(String text) {
    final stations = <FireDangerStation>[];

    for (final line in text.split('\n')) {
      final fields = line.split(';');
      if (fields.length < 5) continue;

      final id = fields[0].trim();
      // The header row, and anything else that is not a number.
      if (id.isEmpty || int.tryParse(id) == null) continue;

      final name = fields[4].trim();
      if (name.isEmpty) continue;

      stations.add(
        FireDangerStation(
          id: id,
          name: name,
          state: fields.length > 5 ? _orNull(fields[5].trim()) : null,
          heightAboveSea: int.tryParse(fields[1].trim()),
          latitude: double.tryParse(fields[2].trim()),
          longitude: double.tryParse(fields[3].trim()),
        ),
      );
    }

    return stations;
  }
}

String? _orNull(String value) => value.isEmpty ? null : value;
