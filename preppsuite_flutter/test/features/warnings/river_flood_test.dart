import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/river_flood.dart';

/// River floods from the Land's own map: Niedersachsen (#124), Bayern
/// (#130) and Nordrhein-Westfalen (#129).
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

  test('a Land without a source is not covered and not asked', () async {
    final client = RiverFloodClient(
      httpClient: MockClient((_) async => fail('must not be asked')),
    );
    // Baden-Württemberg has no public service with the depths (#131).
    final result = await client.check(48.78, 9.18, stateCode: 'BW');
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
}
