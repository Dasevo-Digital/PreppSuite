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
  const RiverFloodResult({
    required this.covered,
    this.classes = const {},
    this.stateCode,
  });

  /// False where this app has no source for the Land.
  final bool covered;

  /// The Land whose map answered, which decides whose name the screen
  /// gives as the source. Results kept before a second Land came in
  /// carry none, and were all Niedersachsen's.
  final String? stateCode;

  /// The deepest LAWA class within the radius, 1 to 5, per scenario; 0
  /// where the map shows no water there.
  final Map<RiverFloodScenario, int> classes;

  bool get anyWater => classes.values.any((value) => value > 0);

  Map<String, Object?> toJson() => {
    'covered': covered,
    'stateCode': ?stateCode,
    'classes': {
      for (final entry in classes.entries) entry.key.name: entry.value,
    },
  };

  static RiverFloodResult? fromJson(Object? json) {
    if (json is! Map) return null;
    final classes = json['classes'];
    final covered = json['covered'] == true;
    return RiverFloodResult(
      covered: covered,
      stateCode: json['stateCode'] as String? ?? (covered ? 'NI' : null),
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
  ///
  /// Baden-Württemberg is not among them for want of a service: the
  /// LUBW publishes its depths only through a query page for people, and
  /// its map services with them are on the state's intranet (checked
  /// 2026-10-08, #131).
  static const coveredStates = {'NI', 'BY', 'NW'};

  static final _sources = <String, _RiverSource>{
    'NI': _RiverSource(
      uri: _niedersachsenUri,
      parse: parseNiedersachsen,
    ),
    'BY': _RiverSource(
      uri: (lat, lon) => _wmsFeatureInfo(
        'https://www.lfu.bayern.de/gdi/wms/wasser/wassertiefen',
        _byLayers.keys,
        lat,
        lon,
        format: 'application/geojson',
      ),
      parse: parseBavaria,
    ),
    'NW': _RiverSource(
      uri: (lat, lon) => _wmsFeatureInfo(
        'https://www.wms.nrw.de/umwelt/wasser/HW_Gefahrenkarte',
        _nwLayers.keys,
        lat,
        lon,
        format: 'application/geo+json',
      ),
      parse: parseNorthRhineWestphalia,
    ),
  };

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

  /// The Bavarian LfU's "Wassertiefen" service: one layer per scenario,
  /// polygons that carry the class as text.
  static const _byLayers = {
    'wt_hqhaeufig': RiverFloodScenario.frequent,
    'wt_hq100': RiverFloodScenario.hundred,
    'wt_hqextrem': RiverFloodScenario.extreme,
  };

  /// The LANUV's hazard map for North Rhine-Westphalia, named after the
  /// probability: high (frequent), medium (HQ100), low (extreme). These
  /// are the flooded areas; the separate layers for land behind flood
  /// defences are left out, as the protected classes are in Niedersachsen.
  static const _nwLayers = {
    'Tiefen_Ueberflutungsgebiet_hw': RiverFloodScenario.frequent,
    'Tiefen_Ueberflutungsgebiet_mw': RiverFloodScenario.hundred,
    'Tiefen_Ueberflutungsgebiet_nw': RiverFloodScenario.extreme,
  };

  /// The deepest class around the point, per scenario, or a result that is
  /// not covered for a Land without a source. Throws when the service did
  /// not answer at all.
  Future<RiverFloodResult> check(
    double latitude,
    double longitude, {
    required String? stateCode,
  }) async {
    final source = _sources[stateCode];
    if (source == null) return const RiverFloodResult(covered: false);
    final points = samplePoints(latitude, longitude);
    final answers = <String?>[];
    for (var i = 0; i < points.length; i += 4) {
      answers.addAll(
        await Future.wait([
          for (final (lat, lon) in points.skip(i).take(4))
            _ask(source.uri(lat, lon)),
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
      for (final (scenario, depthClass) in source.parse(answer)) {
        if (depthClass > deepest[scenario]!) deepest[scenario] = depthClass;
      }
    }
    return RiverFloodResult(
      covered: true,
      classes: deepest,
      stateCode: stateCode,
    );
  }

  Future<String?> _ask(Uri uri) async {
    try {
      final response = await _httpClient
          .get(uri, headers: {'User-Agent': 'PreppSuite/1.0'})
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } on Object {
      return null;
    }
  }

  static Uri _niedersachsenUri(double latitude, double longitude) {
    const half = 0.002;
    return Uri.parse(_niedersachsen).replace(
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
  }

  /// A WMS 1.3.0 GetFeatureInfo for the centre pixel of a small window
  /// around the point. In EPSG:4326 under 1.3.0 the axes are latitude
  /// first.
  static Uri _wmsFeatureInfo(
    String base,
    Iterable<String> layers,
    double latitude,
    double longitude, {
    required String format,
  }) {
    const half = 0.0005;
    final names = layers.join(',');
    return Uri.parse(base).replace(
      queryParameters: {
        'SERVICE': 'WMS',
        'VERSION': '1.3.0',
        'REQUEST': 'GetFeatureInfo',
        'LAYERS': names,
        'QUERY_LAYERS': names,
        'STYLES': '',
        'CRS': 'EPSG:4326',
        'BBOX':
            '${latitude - half},${longitude - half},'
            '${latitude + half},${longitude + half}',
        'WIDTH': '11',
        'HEIGHT': '11',
        'I': '5',
        'J': '5',
        'INFO_FORMAT': format,
        'FEATURE_COUNT': '10',
      },
    );
  }
}

class _RiverSource {
  const _RiverSource({required this.uri, required this.parse});

  final Uri Function(double latitude, double longitude) uri;
  final List<(RiverFloodScenario, int)> Function(String body) parse;
}

/// The LAWA class for a water depth in metres, or null for none: up to
/// 0.5 m, 0.5 to 1, 1 to 2, 2 to 4, over 4.
int? lawaClassForMetres(double metres) {
  if (!metres.isFinite || metres <= 0) return null;
  if (metres <= 0.5) return 1;
  if (metres <= 1) return 2;
  if (metres <= 2) return 3;
  if (metres <= 4) return 4;
  return 5;
}

/// The features of a GeoJSON GetFeatureInfo answer, each with the layer
/// it came from.
Iterable<(String, Map)> _featuresOf(String body) sync* {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return;
  }
  if (decoded is! Map) return;
  final features = decoded['features'];
  if (features is! List) return;
  for (final feature in features) {
    if (feature is! Map) continue;
    final layer = feature['layerName'];
    final properties = feature['properties'];
    if (layer is String && properties is Map) yield (layer, properties);
  }
}

/// The classes in one answer from the Bavarian LfU.
///
/// Each polygon names its class in words, read off the live service on
/// 2026-10-08 at Passau: "größer 0 - 0,5 m", "größer 0,5 - 1,0 m",
/// "größer 1,0 - 2,0 m", "größer 2,0 - 4,0 m", "größer 4,0 m" -- the five
/// LAWA classes, told apart by their lower bound. "nicht ermittelt" is
/// what it says and is left out, like any text that is none of these.
List<(RiverFloodScenario, int)> parseBavaria(String body) => [
  for (final (layer, properties) in _featuresOf(body))
    if (RiverFloodClient._byLayers[layer] case final scenario?)
      if (_bavarianClass(properties['Überflutungstiefe']) case final depth?)
        (scenario, depth),
];

int? _bavarianClass(Object? text) {
  if (text is! String) return null;
  final match = RegExp(
    r'^größer\s+(\d+(?:,\d+)?)\s*(?:-\s*(\d+(?:,\d+)?)\s*)?m$',
  ).firstMatch(text.trim());
  if (match == null) return null;
  final lower = double.parse(match.group(1)!.replaceAll(',', '.'));
  final upper = match.group(2);
  return switch ((lower, upper)) {
    (0, '0,5') => 1,
    (0.5, '1,0') => 2,
    (1, '2,0') => 3,
    (2, '4,0') => 4,
    (4, null) => 5,
    _ => null,
  };
}

/// The classes in one answer from the NRW hazard map.
///
/// NRW answers with the computed depth itself, in metres, as the raster's
/// pixel value -- 4.86 at the Rhine in Cologne on 2026-10-08 -- and
/// "NoData" where the flood does not reach. Its own class number beside
/// it follows a scheme of its own (7.1 m came back as class 4), so the
/// depth is put into the LAWA classes here rather than trusting that.
List<(RiverFloodScenario, int)> parseNorthRhineWestphalia(String body) => [
  for (final (layer, properties) in _featuresOf(body))
    if (RiverFloodClient._nwLayers[layer] case final scenario?)
      if (double.tryParse('${properties['Classify.Pixel Value']}')
          case final metres?)
        if (lawaClassForMetres(metres) case final depth?) (scenario, depth),
];

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
