import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../../../core/private_preferences.dart';
import 'river_flood.dart';
import '../../../core/http_client.dart';

/// Where water runs and stands after a cloudburst, at one address (#115).
///
/// The Bundesamt für Kartographie und Geodäsie publishes a nationwide
/// *Hinweiskarte Starkregengefahren*: a simulation of two rainfall events
/// over the whole terrain, with the deepest water and the fastest flow
/// each cell sees. Open data under dl-de/by-2-0, no key.
///
/// Three things about the service decide the shape of this file:
///
/// * **The legend is the BKG's.** Depth in centimetres in seven classes,
///   flow in metres a second in five; both are written here exactly as the
///   service's own legend draws them, and nothing is said about a class
///   that the legend does not say. The map is a *Hinweis*: it ignores the
///   sewers and infiltration, so every drop runs off on the surface.
/// * **A house is often a hole in the map.** The cell under a building
///   answers `-9999`, no value. The question a household has is whether
///   water reaches the walls, so the answer is the deepest water within
///   [hazardRadiusMetres] of the point, sampled on two rings.
/// * **Not every state is in it.** Each state is its own layer, and
///   Baden-Württemberg and Bayern have none. A neighbouring state's layer
///   answers `0` well past its own border, so a point in one of those two
///   is reported as not covered rather than as dry.
enum HeavyRainScenario {
  /// Statistically once in a hundred years.
  exceptional('agw'),

  /// 100 mm in an hour (90 mm in Nordrhein-Westfalen).
  extreme('extrem');

  const HeavyRainScenario(this.layerSuffix);

  final String layerSuffix;
}

/// The BKG legend's depth classes, lower bounds in centimetres.
///
/// The first is "unter 10 cm", which the map does not colour.
const heavyRainDepthBoundsCm = [10, 30, 50, 100, 200, 400];

/// The BKG legend's flow classes, lower bounds in metres per second.
/// "Unter 0,2 m/s" is not coloured.
const heavyRainVelocityBounds = [0.2, 0.5, 1.0, 2.0];

/// The class [value] falls in: 0 for below the first bound, then 1 for
/// the first coloured class and so on.
int classOf(num value, List<num> bounds) {
  var index = 0;
  while (index < bounds.length && value >= bounds[index]) {
    index++;
  }
  return index;
}

/// How far around the point the water is looked for.
const hazardRadiusMetres = 25.0;

/// What one scenario does around the point.
class HeavyRainScenarioResult {
  const HeavyRainScenarioResult({this.maxDepthCm, this.maxVelocity});

  /// The deepest water within the radius, in centimetres. Null when no
  /// sampled cell carried a value.
  final double? maxDepthCm;

  /// The fastest flow within the radius, in metres per second.
  final double? maxVelocity;

  int? get depthClass =>
      maxDepthCm == null ? null : classOf(maxDepthCm!, heavyRainDepthBoundsCm);

  int? get velocityClass => maxVelocity == null
      ? null
      : classOf(maxVelocity!, heavyRainVelocityBounds);

  Map<String, Object?> toJson() => {
    'maxDepthCm': maxDepthCm,
    'maxVelocity': maxVelocity,
  };

  static HeavyRainScenarioResult fromJson(Object? json) {
    if (json is! Map) return const HeavyRainScenarioResult();
    return HeavyRainScenarioResult(
      maxDepthCm: (json['maxDepthCm'] as num?)?.toDouble(),
      maxVelocity: (json['maxVelocity'] as num?)?.toDouble(),
    );
  }
}

/// One answer for one place, kept for the day there is no network.
class HeavyRainHazard {
  const HeavyRainHazard({
    required this.latitude,
    required this.longitude,
    required this.checkedAt,
    required this.covered,
    this.placeName,
    this.stateName,
    this.results = const {},
    this.river,
  });

  final double latitude;
  final double longitude;
  final String? placeName;

  /// The state the point was found in, as the reverse lookup named it.
  final String? stateName;
  final DateTime checkedAt;

  /// False where the BKG has no layer for the state.
  final bool covered;
  final Map<HeavyRainScenario, HeavyRainScenarioResult> results;

  /// The river flood map of the Land, where this app has one (#124). Null
  /// for an answer kept from before it was asked.
  final RiverFloodResult? river;

  /// Whether any scenario, rain or river, puts water within reach.
  bool get anyWater =>
      results.values.any((r) => (r.depthClass ?? 0) > 0) ||
      (river?.anyWater ?? false);

  Map<String, Object?> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'placeName': placeName,
    'stateName': stateName,
    'checkedAt': checkedAt.toUtc().toIso8601String(),
    'covered': covered,
    'results': {
      for (final entry in results.entries) entry.key.name: entry.value.toJson(),
    },
    'river': river?.toJson(),
  };

  static HeavyRainHazard? fromJson(Object? json) {
    if (json is! Map) return null;
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();
    final checkedAt = DateTime.tryParse('${json['checkedAt']}');
    if (latitude == null || longitude == null || checkedAt == null) {
      return null;
    }
    final results = json['results'];
    return HeavyRainHazard(
      latitude: latitude,
      longitude: longitude,
      placeName: json['placeName'] as String?,
      stateName: json['stateName'] as String?,
      checkedAt: checkedAt,
      covered: json['covered'] != false,
      river: RiverFloodResult.fromJson(json['river']),
      results: {
        if (results is Map)
          for (final scenario in HeavyRainScenario.values)
            if (results[scenario.name] != null)
              scenario: HeavyRainScenarioResult.fromJson(
                results[scenario.name],
              ),
      },
    );
  }
}

/// Asks the BKG's map service about one point.
class HeavyRainClient {
  HeavyRainClient({http.Client? httpClient})
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  static const _endpoint = 'https://sgx.geodatenzentrum.de/wms_starkregen';

  /// The states the BKG has no layer for. Checked against the service's
  /// own capabilities on 2026-10-06; a state added later shows up as data
  /// the moment it is there, because the group layers are what is asked.
  static const uncoveredStates = {'BW', 'BY'};

  /// The four group layers, one request per sample point for all of them.
  static const _layers = [
    'tiefe_agw',
    'tiefe_extrem',
    'geschwindigkeit_agw',
    'geschwindigkeit_extrem',
  ];

  /// The deepest water and fastest flow within [hazardRadiusMetres] of the
  /// point, per scenario. Throws when the service cannot be reached at
  /// all; a single sample that fails is left out.
  Future<Map<HeavyRainScenario, HeavyRainScenarioResult>> check(
    double latitude,
    double longitude,
  ) async {
    final points = samplePoints(latitude, longitude);
    final answers = <String?>[];
    // A few at a time: seventeen requests to a public service is fine,
    // seventeen at once is impolite.
    for (var i = 0; i < points.length; i += 4) {
      final batch = points.skip(i).take(4);
      answers.addAll(
        await Future.wait([
          for (final (lat, lon) in batch) _sample(lat, lon),
        ]),
      );
    }
    if (answers.every((answer) => answer == null)) {
      throw http.ClientException('no answer from the BKG map service');
    }

    final depth = <HeavyRainScenario, double>{};
    final velocity = <HeavyRainScenario, double>{};
    for (final answer in answers.whereType<String>()) {
      for (final reading in parseFeatureInfo(answer)) {
        final scenario = reading.scenario;
        final target = reading.isDepth ? depth : velocity;
        final previous = target[scenario];
        if (previous == null || reading.value > previous) {
          target[scenario] = reading.value;
        }
      }
    }
    return {
      for (final scenario in HeavyRainScenario.values)
        scenario: HeavyRainScenarioResult(
          maxDepthCm: depth[scenario],
          maxVelocity: velocity[scenario],
        ),
    };
  }

  Future<String?> _sample(double latitude, double longitude) async {
    // A box a few metres across with the point in the middle pixel: the
    // service answers for a pixel, not for a coordinate.
    const half = 0.00003;
    final uri = Uri.parse(_endpoint).replace(
      queryParameters: {
        'SERVICE': 'WMS',
        'VERSION': '1.3.0',
        'REQUEST': 'GetFeatureInfo',
        'LAYERS': _layers.join(','),
        'QUERY_LAYERS': _layers.join(','),
        'STYLES': '',
        'CRS': 'CRS:84',
        'BBOX':
            '${longitude - half},${latitude - half},'
            '${longitude + half},${latitude + half}',
        'WIDTH': '5',
        'HEIGHT': '5',
        'I': '2',
        'J': '2',
        'INFO_FORMAT': 'text/plain',
        'FEATURE_COUNT': '64',
      },
    );
    try {
      final response = await _httpClient
          .get(uri)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on Object {
      return null;
    }
  }
}

/// The point itself and two rings around it, at a third and the whole of
/// [hazardRadiusMetres], eight points each.
List<(double, double)> samplePoints(double latitude, double longitude) {
  const metresPerDegree = 111320.0;
  final perLongitude = metresPerDegree * cos(latitude * pi / 180);
  return [
    (latitude, longitude),
    for (final radius in [hazardRadiusMetres / 2, hazardRadiusMetres])
      for (var k = 0; k < 8; k++)
        (
          latitude + radius * sin(k * pi / 4) / metresPerDegree,
          longitude + radius * cos(k * pi / 4) / perLongitude,
        ),
  ];
}

typedef HeavyRainReading = ({
  HeavyRainScenario scenario,
  bool isDepth,
  double value,
});

/// The values in one `text/plain` answer.
///
/// The service names each state's layer --
/// `starkregen:ni_tiefe_extrem` -- and gives one line `Tiefe = 31.0` or
/// `Geschwindigkeit = 0.4` under it. `-9999` is "no value here", which is
/// what a building answers, and is left out.
List<HeavyRainReading> parseFeatureInfo(String text) {
  final readings = <HeavyRainReading>[];
  HeavyRainScenario? scenario;
  bool? isDepth;
  final layer = RegExp(r"starkregen:[a-z]{2}_(tiefe|geschw)_(agw|extrem)'");
  final value = RegExp(r'^(Tiefe|Geschwindigkeit) = (-?[0-9.]+)');
  for (final line in const LineSplitter().convert(text)) {
    final named = layer.firstMatch(line);
    if (named != null) {
      isDepth = named.group(1) == 'tiefe';
      scenario = named.group(2) == 'agw'
          ? HeavyRainScenario.exceptional
          : HeavyRainScenario.extreme;
      continue;
    }
    final found = value.firstMatch(line.trim());
    if (found == null || scenario == null || isDepth == null) continue;
    final number = double.tryParse(found.group(2)!);
    if (number == null || number < 0) continue;
    readings.add((scenario: scenario, isDepth: isDepth, value: number));
  }
  return readings;
}

/// Keeps the last answer. Encrypted: it is the household's address.
class HeavyRainStore {
  const HeavyRainStore();

  static const _key = 'heavyRainHazard.v1';

  Future<HeavyRainHazard?> load() async {
    try {
      final raw = await const PrivatePreferences().getString(_key);
      if (raw == null) return null;
      return HeavyRainHazard.fromJson(jsonDecode(raw));
    } on Object {
      return null;
    }
  }

  Future<void> save(HeavyRainHazard hazard) =>
      const PrivatePreferences().setString(_key, jsonEncode(hazard.toJson()));

  Future<void> clear() => const PrivatePreferences().remove(_key);
}
