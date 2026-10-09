import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'heavy_rain_hazard.dart' show samplePoints;
import '../../../core/http_client.dart';

/// River floods at one address, from the Land's own hazard maps (#124).
///
/// The EU Floods Directive has every Land map three floods -- frequent,
/// the hundred-year flood, and an extreme one -- with the water depth in
/// five classes the federal-state working group (LAWA) fixed for all of
/// them: up to 0.5 m, 0.5 to 1, 1 to 2, 2 to 4, over 4 m. The classes are
/// the same everywhere; the services are not. Each Land runs its own.
///
/// Niedersachsen, Bayern and Nordrhein-Westfalen are asked directly. Every
/// other Land comes from the national flood hazard map of the Federal
/// Institute of Hydrology (BfG), which gathers the Länder's maps into one
/// service (#148) -- Baden-Württemberg included, whose own depths are not
/// public (#131).
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
    this.national = false,
  });

  /// False where this app has no source for the Land.
  final bool covered;

  /// The Land whose map answered, which decides whose name the screen
  /// gives as the source. Results kept before a second Land came in
  /// carry none, and were all Niedersachsen's.
  final String? stateCode;

  /// Whether the answer came from the BfG's national map rather than the
  /// Land's own service -- for every Land but three, and for those three
  /// when their own service did not answer. The source line follows it.
  final bool national;

  /// The deepest LAWA class within the radius, 1 to 5, per scenario; 0
  /// where the map shows no water there; [floodDepthUnknown] where it shows
  /// water without a depth. A scenario missing here has no map at the
  /// place, which is not the same as dry.
  final Map<RiverFloodScenario, int> classes;

  bool get anyWater => classes.values.any((value) => value > 0);

  Map<String, Object?> toJson() => {
    'covered': covered,
    'stateCode': ?stateCode,
    if (national) 'national': true,
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
      national: json['national'] == true,
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
    : _httpClient = httpClient ?? TimeoutClient();

  final http.Client _httpClient;

  /// The Länder this app has a source for: all of them, three directly
  /// and the rest through the national map.
  static const coveredStates = {
    'BB', 'BE', 'BW', 'BY', 'HB', 'HE', 'HH', 'MV', //
    'NI', 'NW', 'RP', 'SH', 'SL', 'SN', 'ST', 'TH',
  };

  /// Whether [stateCode] is answered by the national map rather than by
  /// the Land's own service.
  static bool isNational(String? stateCode) =>
      coveredStates.contains(stateCode) && !_sources.containsKey(stateCode);

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
    if (!coveredStates.contains(stateCode)) {
      return const RiverFloodResult(covered: false);
    }
    final source = _sources[stateCode];
    if (source == null) {
      return _checkNational(latitude, longitude, stateCode: stateCode!);
    }
    try {
      return await _checkLand(source, latitude, longitude, stateCode!);
    } on http.ClientException {
      // The Land's own service did not answer -- the NLWKN's was out for
      // an afternoon on 2026-10-09. The national map carries the same
      // Land's maps, so the household is not left without an answer.
      return _checkNational(latitude, longitude, stateCode: stateCode!);
    }
  }

  Future<RiverFloodResult> _checkLand(
    _RiverSource source,
    double latitude,
    double longitude,
    String stateCode,
  ) async {
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

  /// The BfG's national flood hazard map, third cycle: one ArcGIS map
  /// service per scenario for rivers (`RW`), and in each a polygon layer
  /// per Land -- found on 2026-10-09 at geoportal.bafg.de.
  static const _national =
      'https://geoportal.bafg.de/arcgis3/rest/services/nHWGK_HWRK_2027';

  static const _nationalServices = {
    RiverFloodScenario.frequent: 'RWHi',
    RiverFloodScenario.hundred: 'RWMe',
    RiverFloodScenario.extreme: 'RWLo',
  };

  /// The layers of each national service, read once per client: a check
  /// asks three services, and a second check from the same screen need not
  /// list them again.
  final _nationalLayers = <String, Future<List<NationalFloodLayer>>>{};

  /// The deepest class within 25 m, from whichever Land layers of the
  /// national map cover the point.
  ///
  /// The layers are named after their Land (`DENW`, `DEHE`), except that
  /// one in each service is called "Wassertiefen" and holds a different
  /// Land each time -- Saxony for the frequent and the hundred-year flood,
  /// Baden-Württemberg for the extreme one. So the household's own layer
  /// is the one with its Land's name or, where there is none, an unnamed
  /// one whose extent holds the point.
  ///
  /// Only that layer says whether a scenario is mapped here. The extents
  /// are rectangles and overlap: Rhineland-Palatinate's reaches over
  /// Saarbrücken, and asking it there answered "dry" for a flood the
  /// Saarland never mapped. Other Länder's layers around the point are
  /// still asked, for a river on the border, but they can only add water.
  /// A scenario without its own layer and without water from a neighbour
  /// is left out of the result, which the screen shows as "no map".
  Future<RiverFloodResult> _checkNational(
    double latitude,
    double longitude, {
    required String stateCode,
  }) async {
    final (x, y) = webMercator(latitude, longitude);
    final classes = <RiverFloodScenario, int>{};
    // Whether any service listed its layers, whether any had one here, and
    // whether any of those answered. Layers here that all stayed silent
    // are a failure, not dry land.
    var listed = false;
    var asked = false;
    var heardAny = false;
    for (final MapEntry(key: scenario, value: service)
        in _nationalServices.entries) {
      final List<NationalFloodLayer> layers;
      try {
        layers = await _layersOf(service);
      } on Object {
        continue;
      }
      listed = true;
      final own = ownNationalLayers(layers, stateCode, x, y);
      final neighbours = [
        for (final layer in layers)
          if (!own.contains(layer) &&
              layer.name.startsWith('DE') &&
              layer.contains(x, y))
            layer,
      ];
      if (own.isEmpty && neighbours.isEmpty) continue;
      asked = true;
      var deepest = 0;
      var heardOwn = false;
      for (final layer in [...own, ...neighbours]) {
        final body = await _ask(
          _nationalQuery(service, layer.id, latitude, longitude),
        );
        if (body == null) continue;
        heardAny = true;
        if (own.contains(layer)) heardOwn = true;
        for (final code in parseNationalCodes(body, layer.field)) {
          final depth = nationalFloodClass(code);
          if (depth != null &&
              floodClassRank(depth) > floodClassRank(deepest)) {
            deepest = depth;
          }
        }
      }
      if (heardOwn || deepest > 0) classes[scenario] = deepest;
    }
    if (!listed || asked && !heardAny) {
      throw http.ClientException('no answer from the national flood map');
    }
    return RiverFloodResult(
      covered: true,
      classes: classes,
      stateCode: stateCode,
      national: true,
    );
  }

  Future<List<NationalFloodLayer>> _layersOf(String service) {
    final cached = _nationalLayers[service];
    if (cached != null) return cached;
    final loading = () async {
      final body = await _ask(
        Uri.parse('$_national/$service/MapServer/layers?f=json'),
      );
      final layers = body == null ? null : parseNationalLayers(body);
      if (layers == null || layers.isEmpty) {
        throw http.ClientException('no layers in $service');
      }
      return layers;
    }();
    _nationalLayers[service] = loading;
    // A failed read is not kept; the next check asks again.
    loading.then<void>(
      (_) {},
      onError: (Object _) {
        // A block body: returning the removed future would hand the same
        // error on a second time, unhandled.
        _nationalLayers.remove(service);
      },
    );
    return loading;
  }

  /// An ArcGIS query for the polygons within about 25 m of the point.
  static Uri _nationalQuery(
    String service,
    int layer,
    double latitude,
    double longitude,
  ) {
    const metres = 25.0;
    final dLat = metres / 111320;
    final dLon = metres / (111320 * cos(latitude * pi / 180));
    return Uri.parse('$_national/$service/MapServer/$layer/query').replace(
      queryParameters: {
        'geometry':
            '${longitude - dLon},${latitude - dLat},'
            '${longitude + dLon},${latitude + dLat}',
        'geometryType': 'esriGeometryEnvelope',
        'inSR': '4326',
        'spatialRel': 'esriSpatialRelIntersects',
        'outFields': '*',
        'returnGeometry': 'false',
        'f': 'json',
      },
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

/// A Land's polygon layer in one service of the national map.
class NationalFloodLayer {
  const NationalFloodLayer({
    required this.id,
    required this.name,
    required this.field,
    required this.xmin,
    required this.ymin,
    required this.xmax,
    required this.ymax,
  });

  final int id;
  final String name;

  /// The attribute holding the class code. Every Land named it its own
  /// way -- `T_class`, `gridcode`, `SIGD_CD`, `WT_KL`, `rastervalue` --
  /// and the layer's own renderer says which.
  final String field;

  /// The layer's extent in Web Mercator.
  final double xmin, ymin, xmax, ymax;

  bool contains(double x, double y) =>
      x >= xmin && x <= xmax && y >= ymin && y <= ymax;
}

/// The layers of [layers] that belong to [stateCode] at the point
/// [x], [y] (Web Mercator): the one named after the Land, or -- where the
/// service has none by that name -- an unnamed one whose extent holds the
/// point.
List<NationalFloodLayer> ownNationalLayers(
  List<NationalFloodLayer> layers,
  String stateCode,
  double x,
  double y,
) {
  final named = [
    for (final layer in layers)
      if (layer.name == 'DE$stateCode') layer,
  ];
  if (named.isNotEmpty) return named;
  return [
    for (final layer in layers)
      if (!layer.name.startsWith('DE') && layer.contains(x, y)) layer,
  ];
}

/// The layers of one national service, from its `layers?f=json`.
List<NationalFloodLayer> parseNationalLayers(String body) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final layers = decoded is Map ? decoded['layers'] : null;
  if (layers is! List) return const [];
  final found = <NationalFloodLayer>[];
  for (final layer in layers) {
    if (layer is! Map) continue;
    final id = layer['id'];
    final extent = layer['extent'];
    final renderer = (layer['drawingInfo'] as Map?)?['renderer'];
    final field = renderer is Map ? renderer['field1'] : null;
    if (id is! int || extent is! Map || field is! String) continue;
    double? at(String key) => (extent[key] as num?)?.toDouble();
    final (xmin, ymin, xmax, ymax) = (
      at('xmin'),
      at('ymin'),
      at('xmax'),
      at('ymax'),
    );
    if (xmin == null || ymin == null || xmax == null || ymax == null) {
      continue;
    }
    found.add(
      NationalFloodLayer(
        id: id,
        name: '${layer['name']}',
        field: field,
        xmin: xmin,
        ymin: ymin,
        xmax: xmax,
        ymax: ymax,
      ),
    );
  }
  return found;
}

/// The class codes in a query answer, read from [field] whatever case the
/// Land wrote it in.
List<int> parseNationalCodes(String body, String field) {
  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    return const [];
  }
  final features = decoded is Map ? decoded['features'] : null;
  if (features is! List) return const [];
  final wanted = field.toLowerCase();
  return [
    for (final feature in features)
      if (feature is Map && feature['attributes'] is Map)
        for (final MapEntry(:key, :value)
            in (feature['attributes'] as Map).entries)
          if ('$key'.toLowerCase() == wanted) ?int.tryParse('$value'.trim()),
  ];
}

/// A depth no map put a figure to: flooded, depth not given.
const floodDepthUnknown = 6;

/// The app's class for one code of the national map's legend, or null for
/// one it leaves out.
///
/// The legend, read off the service on 2026-10-09: 11 to 15 the five LAWA
/// classes; 31 to 35 the same, "nachrichtlich" -- taken over from another
/// authority, and water all the same; 16 and 17 Saxony's own two, 0.5 to
/// 2 m and over 2 m, put at the deeper of the classes they span; 18
/// flooded without a depth. 21 to 25 are areas behind flood defences,
/// left out as the Länder's own services are.
int? nationalFloodClass(int code) => switch (code) {
  >= 11 && <= 15 => code - 10,
  >= 31 && <= 35 => code - 30,
  16 => 3,
  17 => 4,
  18 => floodDepthUnknown,
  _ => null,
};

/// How deep a class is, for keeping the deepest: a known depth outranks
/// "flooded, depth not given", which outranks dry.
double floodClassRank(int depthClass) =>
    depthClass == floodDepthUnknown ? 0.5 : depthClass.toDouble();

/// [latitude] and [longitude] in Web Mercator (EPSG:3857) metres.
(double, double) webMercator(double latitude, double longitude) {
  const radius = 6378137.0;
  final x = radius * longitude * pi / 180;
  final y = radius * log(tan(pi / 4 + latitude * pi / 360));
  return (x, y);
}
