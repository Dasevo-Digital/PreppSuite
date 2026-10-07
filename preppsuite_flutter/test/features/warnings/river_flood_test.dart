import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/river_flood.dart';

/// River floods from the Land's own map, Niedersachsen first (#124).
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
    final result = await client.check(48.1, 11.5, stateCode: 'BY');
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

  test('a result survives being kept', () {
    const result = RiverFloodResult(
      covered: true,
      classes: {RiverFloodScenario.hundred: 4},
    );
    final kept = RiverFloodResult.fromJson(
      jsonDecode(jsonEncode(result.toJson())),
    )!;
    expect(kept.classes, {RiverFloodScenario.hundred: 4});
    expect(kept.anyWater, isTrue);
  });
}
