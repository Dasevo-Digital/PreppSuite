import 'dart:convert';

import 'package:http/http.dart' as http;

import 'pegel_level.dart';

/// One gauge on a federal waterway.
class PegelStation {
  const PegelStation({
    required this.uuid,
    required this.name,
    required this.water,
    this.longName,
    this.latitude,
    this.longitude,
    this.kilometre,
  });

  final String uuid;

  /// The short name, which is what the service and the signs at the river
  /// both use — "KÖLN", "MAXAU".
  final String name;

  /// The waterway, upper case as published: "RHEIN", "ELBE".
  final String water;

  final String? longName;
  final double? latitude;
  final double? longitude;

  /// River kilometre, which is what says whether a gauge is upstream of
  /// somewhere -- and upstream is the only direction that warns.
  final double? kilometre;

  static PegelStation? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final uuid = json['uuid'];
    final name = json['shortname'];
    final water = json['water'];
    if (uuid is! String || name is! String) return null;
    return PegelStation(
      uuid: uuid,
      name: name,
      water: water is Map<String, Object?>
          ? (water['shortname'] as String? ?? '')
          : (water as String? ?? ''),
      longName: json['longname'] as String?,
      latitude: _number(json['latitude']),
      longitude: _number(json['longitude']),
      kilometre: _number(json['km']),
    );
  }

  Map<String, Object?> toJson() => {
    'uuid': uuid,
    'shortname': name,
    'water': water,
    'longname': longName,
    'latitude': latitude,
    'longitude': longitude,
    'km': kilometre,
  };
}

/// Reads water levels from PEGELONLINE.
///
/// Open data of the Wasserstraßen- und Schifffahrtsverwaltung, no key and
/// no account, which is the only reason this is in the app at all -- a
/// credential shipped inside a client is a credential given away.
///
/// Federal waterways only, about 800 gauges. The small rivers that flood
/// a village are the Laender's and are not in here; their warnings arrive
/// through the BBK feed this app already reads.
class PegelClient {
  PegelClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _baseUrl =
      'https://www.pegelonline.wsv.de/webservices/rest-api/v2';

  /// Every gauge, with its position. About 120 kB, and worth keeping:
  /// the list barely changes and a household picks from it once.
  Future<List<PegelStation>> fetchStations() async {
    final body = await _get('$_baseUrl/stations.json');
    if (body == null) return const [];
    final decoded = jsonDecode(body);
    if (decoded is! List) return const [];
    return [for (final entry in decoded) ?PegelStation.fromJson(entry)];
  }

  /// The current level at [station], with its long-term reference values
  /// and the change over the preceding day.
  ///
  /// Two requests, because the service keeps the current value and the
  /// series apart. A failure of the second costs the trend and not the
  /// reading: knowing the river is at 720 cm is worth more than knowing
  /// nothing because the history did not load.
  Future<PegelReading?> fetchReading(PegelStation station) async {
    final body = await _get(
      '$_baseUrl/stations/${station.uuid}/W.json'
      '?includeCurrentMeasurement=true&includeCharacteristicValues=true',
    );
    if (body == null) return null;

    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) return null;

    final current = decoded['currentMeasurement'];
    if (current is! Map<String, Object?>) return null;
    final value = _number(current['value']);
    final at = DateTime.tryParse(current['timestamp'] as String? ?? '');
    if (value == null || at == null) return null;

    final references = <PegelReference, double>{};
    final published = decoded['characteristicValues'];
    if (published is List) {
      for (final entry in published) {
        if (entry is! Map<String, Object?>) continue;
        final code = entry['shortname'];
        final level = _number(entry['value']);
        // Only centimetres. The same list carries fairway depths and
        // gauge datums in metres above sea level, and mixing those into
        // a comparison against a water level would be nonsense.
        if (code is! String || level == null || entry['unit'] != 'cm') continue;
        final reference = PegelReference.fromCode(code);
        if (reference != null) references[reference] = level;
      }
    }

    return PegelReading(
      stationName: station.name,
      water: station.water,
      centimetres: value,
      measuredAt: at,
      references: references,
      changeOverDay: await _fetchChangeOverDay(station),
    );
  }

  Future<double?> _fetchChangeOverDay(PegelStation station) async {
    final body = await _get(
      '$_baseUrl/stations/${station.uuid}/W/measurements.json?start=P2D',
    );
    if (body == null) return null;
    final decoded = jsonDecode(body);
    if (decoded is! List) return null;

    final samples = <({DateTime at, double value})>[];
    for (final entry in decoded) {
      if (entry is! Map<String, Object?>) continue;
      final at = DateTime.tryParse(entry['timestamp'] as String? ?? '');
      final value = _number(entry['value']);
      if (at != null && value != null) samples.add((at: at, value: value));
    }
    return changeOverDay(samples);
  }

  Future<String?> _get(String url) async {
    try {
      final response = await _httpClient.get(Uri.parse(url));
      if (response.statusCode != 200) return null;
      // The service serves UTF-8 but does not always say so, and the
      // gauge names are full of umlauts.
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on Object {
      // Offline is the normal case for this app, not an error worth
      // shouting about. The caller shows the last reading it kept.
      return null;
    }
  }
}

double? _number(Object? value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text),
  _ => null,
};
