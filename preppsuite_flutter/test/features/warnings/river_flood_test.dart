import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/river_flood.dart';

/// River floods from the Land's own map: Niedersachsen (#124), Bayern
/// (#130) and Nordrhein-Westfalen (#129); every other Land from the
/// national map of the BfG (#148, #131).
void main() {
  String answer(Map<int, String> values) => jsonEncode({
    'results': [
      for (final entry in values.entries)
        {
          'layerId': entry.key,
          'attributes': {'UniqueValue.Pixelwert': entry.value},
        },
    ],
  });

  test('pixel values become the five LAWA classes', () {
    expect(parseNiedersachsen(answer({20: 'NoData', 21: '4', 22: '14'})), [
      (RiverFloodScenario.hundred, 4),
      (RiverFloodScenario.extreme, 4),
    ]);
    expect(parseNiedersachsen(answer({22: '11'})), [
      (RiverFloodScenario.extreme, 1),
    ]);
    // An unknown code -- the "protected" classes nobody has seen yet, or a
    // value in the wrong layer -- is left out, not guessed at.
    expect(parseNiedersachsen(answer({22: '23', 21: '14', 20: '0'})), isEmpty);
    expect(parseNiedersachsen('kein json'), isEmpty);
  });

  test('the deepest class around the point wins, dry is 0', () async {
    var calls = 0;
    final client = RiverFloodClient(
      httpClient: MockClient((request) async {
        calls++;
        expect(request.url.queryParameters['layers'], 'all:20,21,22');
        return http.Response(
          calls == 3
              ? answer({20: '2', 21: '3', 22: 'NoData'})
              : answer({20: 'NoData', 21: '1', 22: '12'}),
          200,
        );
      }),
    );
    final result = await client.check(52.378, 9.7, stateCode: 'NI');
    expect(calls, 17);
    expect(result.covered, isTrue);
    expect(result.classes, {
      RiverFloodScenario.frequent: 2,
      RiverFloodScenario.hundred: 3,
      RiverFloodScenario.extreme: 2,
    });
  });

  test('a place outside Germany is not covered and not asked', () async {
    final client = RiverFloodClient(
      httpClient: MockClient((_) async => fail('must not be asked')),
    );
    final result = await client.check(47.37, 8.54, stateCode: null);
    expect(result.covered, isFalse);
    expect(result.anyWater, isFalse);
  });

  test('a service that never answers is an error, not dry land', () {
    final client = RiverFloodClient(
      httpClient: MockClient((_) async => http.Response('', 503)),
    );
    expect(
      client.check(52.378, 9.7, stateCode: 'NI'),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('a result survives being kept, with the Land that answered', () {
    const result = RiverFloodResult(
      covered: true,
      classes: {RiverFloodScenario.hundred: 4},
      stateCode: 'BY',
    );
    final kept = RiverFloodResult.fromJson(
      jsonDecode(jsonEncode(result.toJson())),
    )!;
    expect(kept.classes, {RiverFloodScenario.hundred: 4});
    expect(kept.anyWater, isTrue);
    expect(kept.stateCode, 'BY');

    // Kept before a second Land came in: those were all Niedersachsen's.
    final older = RiverFloodResult.fromJson({
      'covered': true,
      'classes': {'hundred': 2},
    })!;
    expect(older.stateCode, 'NI');
  });

  String features(String layerKey, Map<String, Map<String, String>> byLayer) =>
      jsonEncode({
        'type': 'FeatureCollection',
        'features': [
          for (final entry in byLayer.entries)
            {
              'type': 'Feature',
              'geometry': null,
              'properties': entry.value,
              layerKey: entry.key,
            },
        ],
      });

  group('Bayern', () {
    String bavarian(Map<String, String> depthByLayer) => features(
      'layerName',
      {
        for (final entry in depthByLayer.entries)
          entry.key: {
            'Gewässername': 'Donau',
            'Überflutungstiefe': entry.value,
          },
      },
    );

    test('the texts the LfU answers with become the five classes', () {
      // Exactly as the service wrote them at Passau on 2026-10-08.
      final texts = {
        'größer 0 - 0,5 m': 1,
        'größer 0,5 - 1,0 m': 2,
        'größer 1,0 - 2,0 m': 3,
        'größer 2,0 - 4,0 m': 4,
        'größer 4,0 m': 5,
      };
      for (final MapEntry(key: text, value: depth) in texts.entries) {
        expect(parseBavaria(bavarian({'wt_hq100': text})), [
          (RiverFloodScenario.hundred, depth),
        ], reason: text);
      }
      expect(
        parseBavaria(
          bavarian({
            'wt_hqhaeufig': 'größer 0 - 0,5 m',
            'wt_hqextrem': 'größer 4,0 m',
          }),
        ),
        [(RiverFloodScenario.frequent, 1), (RiverFloodScenario.extreme, 5)],
      );
    });

    test('"nicht ermittelt" and anything else unknown is left out', () {
      expect(parseBavaria(bavarian({'wt_hq100': 'nicht ermittelt'})), isEmpty);
      expect(
        parseBavaria(bavarian({'wt_hq100': 'größer 3,0 - 7,0 m'})),
        isEmpty,
      );
      expect(
        parseBavaria(bavarian({'wt_hwgg_hq100': 'größer 4,0 m'})),
        isEmpty,
      );
      expect(
        parseBavaria('{"type":"FeatureCollection","features":[]}'),
        isEmpty,
      );
      expect(parseBavaria('<html>ArcGIS Server Error</html>'), isEmpty);
    });

    test('is asked with a GetFeatureInfo, latitude first', () async {
      Uri? asked;
      final client = RiverFloodClient(
        httpClient: MockClient((request) async {
          asked = request.url;
          expect(request.headers['User-Agent'], 'PreppSuite/1.0');
          return http.Response.bytes(
            utf8.encode(bavarian({'wt_hq100': 'größer 1,0 - 2,0 m'})),
            200,
          );
        }),
      );
      final result = await client.check(48.5745, 13.464, stateCode: 'BY');
      expect(asked!.host, 'www.lfu.bayern.de');
      expect(asked!.queryParameters['REQUEST'], 'GetFeatureInfo');
      expect(
        asked!.queryParameters['QUERY_LAYERS'],
        'wt_hqhaeufig,wt_hq100,wt_hqextrem',
      );
      expect(
        asked!.queryParameters['BBOX']!.split(',').first,
        startsWith('48.'),
      );
      expect(result.stateCode, 'BY');
      expect(result.classes[RiverFloodScenario.hundred], 3);
      expect(result.classes[RiverFloodScenario.frequent], 0);
    });
  });

  group('Nordrhein-Westfalen', () {
    String nrw(Map<String, String> metresByLayer) => features(
      'layerName',
      {
        for (final entry in metresByLayer.entries)
          entry.key: {'Classify.Pixel Value': entry.value},
      },
    );

    test('the depth in metres is put into the LAWA classes', () {
      expect(
        parseNorthRhineWestphalia(
          nrw({
            'Tiefen_Ueberflutungsgebiet_hw': 'NoData',
            'Tiefen_Ueberflutungsgebiet_mw': '4.860001',
            'Tiefen_Ueberflutungsgebiet_nw': '0.3',
          }),
        ),
        [(RiverFloodScenario.hundred, 5), (RiverFloodScenario.extreme, 1)],
      );
      // The land behind defences is a layer of its own and not read.
      expect(
        parseNorthRhineWestphalia(
          nrw({'Tiefen_ueberflutungsgefaehrdete_Gebiete_mw': '2.0'}),
        ),
        isEmpty,
      );
    });

    test('the class boundaries', () {
      expect(lawaClassForMetres(0), isNull);
      expect(lawaClassForMetres(0.01), 1);
      expect(lawaClassForMetres(0.5), 1);
      expect(lawaClassForMetres(0.51), 2);
      expect(lawaClassForMetres(1), 2);
      expect(lawaClassForMetres(2), 3);
      expect(lawaClassForMetres(4), 4);
      expect(lawaClassForMetres(7.11), 5);
      expect(lawaClassForMetres(double.nan), isNull);
    });

    test('is asked at the LANUV with its own layers', () async {
      Uri? asked;
      final client = RiverFloodClient(
        httpClient: MockClient((request) async {
          asked = request.url;
          return http.Response(
            nrw({'Tiefen_Ueberflutungsgebiet_mw': '1.5'}),
            200,
          );
        }),
      );
      final result = await client.check(50.938, 6.962, stateCode: 'NW');
      expect(asked!.host, 'www.wms.nrw.de');
      expect(asked!.queryParameters['INFO_FORMAT'], 'application/geo+json');
      expect(result.stateCode, 'NW');
      expect(result.classes[RiverFloodScenario.hundred], 3);
    });
  });

  group('the national map', () {
    // Two layers as the service lists them: one named after its Land,
    // one called "Wassertiefen" that holds another (Saxony, here).
    final (hx, hy) = webMercator(50.1065, 8.6820); // Frankfurt am Main
    final (sx, sy) = webMercator(51.0560, 13.7390); // Dresden
    String layers({bool withHesse = true}) => jsonEncode({
      'layers': [
        if (withHesse)
          {
            'id': 37,
            'name': 'DEHE',
            'extent': {
              'xmin': hx - 1000,
              'ymin': hy - 1000,
              'xmax': hx + 1000,
              'ymax': hy + 1000,
            },
            'drawingInfo': {
              'renderer': {'field1': 'gridcode'},
            },
          },
        {
          'id': 0,
          'name': 'Wassertiefen',
          'extent': {
            'xmin': sx - 1000,
            'ymin': sy - 1000,
            'xmax': sx + 1000,
            'ymax': sy + 1000,
          },
          'drawingInfo': {
            'renderer': {'field1': 'LEGENDE'},
          },
        },
      ],
    });
    String codes(String field, List<Object> values) => jsonEncode({
      'features': [
        for (final value in values)
          {
            'attributes': {field: value, 'OBJECTID': 1},
          },
      ],
    });

    test('the legend becomes the app\'s classes', () {
      expect(nationalFloodClass(11), 1);
      expect(nationalFloodClass(15), 5);
      // Taken over from another authority, water all the same.
      expect(nationalFloodClass(33), 3);
      // Saxony's own: 0.5 to 2 m and over 2 m, at the deeper class.
      expect(nationalFloodClass(16), 3);
      expect(nationalFloodClass(17), 4);
      expect(nationalFloodClass(18), floodDepthUnknown);
      // Behind flood defences, and anything unknown: left out.
      expect(nationalFloodClass(23), isNull);
      expect(nationalFloodClass(99), isNull);
      // A known depth outranks "depth not given", which outranks dry.
      expect(floodClassRank(1), greaterThan(floodClassRank(floodDepthUnknown)));
      expect(floodClassRank(floodDepthUnknown), greaterThan(floodClassRank(0)));
    });

    test('codes are read whatever the Land called the field', () {
      expect(parseNationalCodes(codes('T_Class', [14]), 'T_class'), [14]);
      expect(parseNationalCodes(codes('SIGD_CD', ['11', '13']), 'SIGD_CD'), [
        11,
        13,
      ]);
      expect(parseNationalCodes('kein json', 'gridcode'), isEmpty);
    });

    test('layers are read with field and extent', () {
      final parsed = parseNationalLayers(layers());
      expect(parsed.map((l) => l.name), ['DEHE', 'Wassertiefen']);
      expect(parsed.first.field, 'gridcode');
      expect(parsed.first.contains(hx, hy), isTrue);
      expect(parsed.last.contains(hx, hy), isFalse);
    });

    test('Web Mercator as the service measures it', () {
      final (x, y) = webMercator(0, 0);
      expect(x, closeTo(0, 1e-6));
      expect(y, closeTo(0, 1e-6));
      // Cologne: inside the NRW layer's extent the service reports
      // (x 638574 to 1055039).
      final (cx, cy) = webMercator(50.94796, 6.96516);
      expect(cx, closeTo(775358.06, 0.01));
      expect(cy, closeTo(6612093.61, 0.01));
    });

    test('Hesse is asked in its own layer, by where it lies', () async {
      final asked = <String>[];
      final client = RiverFloodClient(
        httpClient: MockClient((request) async {
          final path = request.url.path;
          asked.add(path);
          if (path.endsWith('/layers')) return http.Response(layers(), 200);
          expect(
            request.url.queryParameters['geometryType'],
            'esriGeometryEnvelope',
          );
          return http.Response(codes('gridcode', [12, 23]), 200);
        }),
      );
      final result = await client.check(50.1065, 8.6820, stateCode: 'HE');
      expect(result.covered, isTrue);
      expect(result.stateCode, 'HE');
      expect(RiverFloodClient.isNational('HE'), isTrue);
      expect(RiverFloodClient.isNational('NI'), isFalse);
      // 12 is 0.5 to 1 m; 23 is behind a dike and does not count.
      expect(result.classes.values.toSet(), {2});
      expect(asked.where((p) => p.endsWith('/37/query')), hasLength(3));
      expect(asked.where((p) => p.endsWith('/0/query')), isEmpty);
    });

    test('a scenario without a layer here is left out, not dry', () async {
      final client = RiverFloodClient(
        httpClient: MockClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/layers')) {
            // The frequent flood has no Hesse layer, like the Saarland.
            return http.Response(
              layers(withHesse: !path.contains('/RWHi/')),
              200,
            );
          }
          return http.Response(codes('gridcode', <Object>[]), 200);
        }),
      );
      final result = await client.check(50.1065, 8.6820, stateCode: 'HE');
      expect(result.classes.containsKey(RiverFloodScenario.frequent), isFalse);
      expect(result.classes[RiverFloodScenario.hundred], 0);
      expect(result.anyWater, isFalse);
    });

    test('layers here that all stay silent are an error', () async {
      final client = RiverFloodClient(
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/layers')) {
            return http.Response(layers(), 200);
          }
          return http.Response('', 503);
        }),
      );
      expect(
        client.check(50.1065, 8.6820, stateCode: 'HE'),
        throwsA(isA<http.ClientException>()),
      );
    });

    test(
      'a neighbour\'s rectangle over the point does not make it dry',
      () async {
        // Saarbrücken lies inside Rhineland-Palatinate's extent, and the
        // frequent flood has no Saarland layer: that is "no map", not dry.
        final (px, py) = webMercator(49.2330, 6.9930);
        String saar({required bool withSaarland}) => jsonEncode({
          'layers': [
            {
              'id': 50,
              'name': 'DERP',
              'extent': {
                'xmin': px - 50000,
                'ymin': py - 50000,
                'xmax': px + 50000,
                'ymax': py + 50000,
              },
              'drawingInfo': {
                'renderer': {'field1': 'gridcode'},
              },
            },
            if (withSaarland)
              {
                'id': 18,
                'name': 'DESL',
                'extent': {
                  'xmin': px - 1000,
                  'ymin': py - 1000,
                  'xmax': px + 1000,
                  'ymax': py + 1000,
                },
                'drawingInfo': {
                  'renderer': {'field1': 'T_klasse'},
                },
              },
          ],
        });
        final client = RiverFloodClient(
          httpClient: MockClient((request) async {
            final path = request.url.path;
            if (path.endsWith('/layers')) {
              return http.Response(
                saar(withSaarland: !path.contains('/RWHi/')),
                200,
              );
            }
            if (path.endsWith('/18/query')) {
              return http.Response(codes('T_klasse', [15]), 200);
            }
            return http.Response(codes('gridcode', <Object>[]), 200);
          }),
        );
        final result = await client.check(49.2330, 6.9930, stateCode: 'SL');
        expect(
          result.classes.containsKey(RiverFloodScenario.frequent),
          isFalse,
        );
        expect(result.classes[RiverFloodScenario.hundred], 5);
      },
    );

    test('a river on the border still shows the neighbour\'s water', () {
      final (px, py) = webMercator(50.0, 8.0);
      final layers = parseNationalLayers(
        jsonEncode({
          'layers': [
            for (final (id, name) in [(1, 'DEHE'), (2, 'Wassertiefen')])
              {
                'id': id,
                'name': name,
                'extent': {
                  'xmin': px - 10,
                  'ymin': py - 10,
                  'xmax': px + 10,
                  'ymax': py + 10,
                },
                'drawingInfo': {
                  'renderer': {'field1': 'gridcode'},
                },
              },
          ],
        }),
      );
      // Hesse has its own layer, so the unnamed one is not Hesse's.
      expect(ownNationalLayers(layers, 'HE', px, py).map((l) => l.id), [1]);
      // A Land without a named layer takes the unnamed one at the point.
      expect(ownNationalLayers(layers, 'SN', px, py).map((l) => l.id), [2]);
      expect(ownNationalLayers(layers, 'SN', px + 100, py), isEmpty);
    });

    test(
      'a Land service that is down falls back to the national map',
      () async {
        // The NLWKN's service did not answer for an afternoon on 2026-10-09.
        final (nx, ny) = webMercator(52.378, 9.700);
        final client = RiverFloodClient(
          httpClient: MockClient((request) async {
            if (request.url.host == 'www.umweltkarten-niedersachsen.de') {
              return http.Response('', 503);
            }
            if (request.url.path.endsWith('/layers')) {
              return http.Response(
                jsonEncode({
                  'layers': [
                    {
                      'id': 43,
                      'name': 'DENI',
                      'extent': {
                        'xmin': nx - 1000,
                        'ymin': ny - 1000,
                        'xmax': nx + 1000,
                        'ymax': ny + 1000,
                      },
                      'drawingInfo': {
                        'renderer': {'field1': 'gridcode'},
                      },
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response(codes('gridcode', [14]), 200);
          }),
        );
        final result = await client.check(52.378, 9.700, stateCode: 'NI');
        expect(result.national, isTrue);
        expect(result.classes[RiverFloodScenario.hundred], 4);
        final kept = RiverFloodResult.fromJson(
          jsonDecode(jsonEncode(result.toJson())),
        )!;
        expect(kept.national, isTrue);
      },
    );
  });
}
