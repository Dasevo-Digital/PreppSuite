import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'heavy_rain_hazard.dart' show samplePoints;

/// River floods at one address, from the Land's own hazard maps (#124).
///
/// The EU Floods Directive has every Land map three floods -- frequent,
/// the hundred-year flood, and an extreme one -- with the water depth in
/// five classes the federal-state working group (LAWA) fixed for all of
/// them: up to 0.5 m, 0.5 to 1, 1 to 2, 2 to 4, over 4 m. The classes are
/// the same everywhere; the services are not. Each Land runs its own, so
/// each one is a source of its own here. Niedersachsen first.
enum RiverFloodScenario {
  /// HQhäufig: a flood that comes often.
  frequent,

  /// HQ100: statistically once in a hundred years.
  hundred,

  /// HQextrem: a rare, extreme flood.
  extreme,
}

/// What one Land's map says about one place.
class RiverFloodResult {
  const RiverFloodResult({required this.covered, this.classes = const {}});

  /// False where this app has no source for the Land.
  final bool covered;

  /// The deepest LAWA class within the radius, 1 to 5, per scenario; 0
  /// where the map shows no water there.
  final Map<RiverFloodScenario, int> classes;

  bool get anyWater => classes.values.any((value) => value > 0);

  Map<String, Object?> toJson() => {
    'covered': covered,
    'classes': {
      for (final entry in classes.entries) entry.key.name: entry.value,
    },
  };

  static RiverFloodResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final classes = json['classes'];
    return RiverFloodResult(
      covered: json['covered'] == true,
      classes: {
        if (classes is Map)
          for (final scenario in RiverFloodScenario.values)
            if (classes[scenario.name] case final int value) scenario: value,
      },
    );
  }
}

/// Asks the Land's flood hazard map about one point.
class RiverFloodClient {
  RiverFloodClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  /// The Länder this app has a source for.
  static const coveredStates = {'NI'};

  /// The NLWKN's map service on the Lower Saxony environment portal. The
  /// water depths are raster layers 20 to 22, one per scenario.
  static const _niedersachsen =
      'https://www.umweltkarten-niedersachsen.de/arcgis/rest/services/'
      'HWSchutz_wms/MapServer/identify';

  static const _niLayers = {
    20: RiverFloodScenario.frequent,
    21: RiverFloodScenario.hundred,
    22: RiverFloodScenario.extreme,
  };

  /// The deepest class around the point, per scenario, or a result that is
  /// not covered for a Land without a source. Throws when the service did
  /// not answer at all.
  Future<RiverFloodResult> check(
    double latitude,
    double longitude, {
    required String? stateCode,
  }) async {
    if (!coveredStates.contains(stateCode)) {
      return const RiverFloodResult(covered: false);
    }
    final points = samplePoints(latitude, longitude);
    final answers = <String?>[];
    for (var i = 0; i < points.length; i += 4) {
      answers.addAll(
        await Future.wait([
          for (final (lat, lon) in points.skip(i).take(4)) _identify(lat, lon),
        ]),
      );
    }
    if (answers.every((answer) => answer == null)) {
      throw http.ClientException('no answer from the flood map service');
    }

    final deepest = {
      for (final scenario in RiverFloodScenario.values) scenario: 0,
    };
    for (final answer in answers.whereType<String>()) {
      for (final (scenario, depthClass) in parseNiedersachsen(answer)) {
        if (depthClass > deepest[scenario]!) deepest[scenario] = depthClass;
      }
    }
    return RiverFloodResult(covered: true, classes: deepest);
  }

  Future<String?> _identify(double latitude, double longitude) async {
    const half = 0.002;
    final uri = Uri.parse(_niedersachsen).replace(
      queryParameters: {
        'geometry': '$longitude,$latitude',
        'geometryType': 'esriGeometryPoint',
        'sr': '4326',
        'layers': 'all:${_niLayers.keys.join(',')}',
        'tolerance': '0',
        'mapExtent':
            '${longitude - half},${latitude - half},'
            '${longitude + half},${latitude + half}',
        'imageDisplay': '400,400,96',
        'returnGeometry': 'false',
        'f': 'json',
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

/// The classes in one answer from the NLWKN service.
///
/// Each layer answers a pixel value. The service does not publish which
/// value is which class, so it was read off the rendered map on
/// 2026-10-07 against the legend's own colours: 1 to 5 in the frequent and
/// the hundred-year layer, 11 to 15 in the extreme one, each the five LAWA
/// classes in order. "NoData" is a cell the flood does not reach. The
/// extreme layer's legend also has five "protected" classes behind flood
/// defences, which no sample turned up; a value that is none of the known
/// ones is left out rather than guessed at.
List<(RiverFloodScenario, int)> parseNiedersachsen(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  if (decoded is! Map) return const [];
  final results = decoded['results'];
  if (results is! List) return const [];
  final found = <(RiverFloodScenario, int)>[];
  for (final result in results) {
    if (result is! Map) continue;
    final scenario = RiverFloodClient._niLayers[result['layerId']];
    final attributes = result['attributes'];
    if (scenario == null || attributes is! Map) continue;
    final value = int.tryParse('${attributes['UniqueValue.Pixelwert']}');
    if (value == null) continue;
    final depthClass = switch (value) {
      >= 1 && <= 5 when scenario != RiverFloodScenario.extreme => value,
      >= 11 && <= 15 when scenario == RiverFloodScenario.extreme => value - 10,
      _ => null,
    };
    if (depthClass != null) found.add((scenario, depthClass));
  }
  return found;
}
