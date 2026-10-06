import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/heavy_rain_hazard.dart';
import 'package:preppsuite_flutter/features/warnings/presentation/heavy_rain_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The BKG's heavy rain map, read for one address (#115).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // What the service answers, word for word, for a point in Niedersachsen
  // near the border: Sachsen-Anhalt's layer reaches this far and says 0.
  const answer = '''
Results for FeatureType 'http://bkg.bund.de/starkregen:ni_tiefe_agw':
--------------------------------------------
Tiefe = 12.0
--------------------------------------------
Results for FeatureType 'http://bkg.bund.de/starkregen:st_tiefe_agw':
--------------------------------------------
Tiefe = 0.0
--------------------------------------------
Results for FeatureType 'http://bkg.bund.de/starkregen:ni_tiefe_extrem':
--------------------------------------------
Tiefe = 31.0
--------------------------------------------
Results for FeatureType 'http://bkg.bund.de/starkregen:ni_geschw_extrem':
--------------------------------------------
Geschwindigkeit = 0.6
--------------------------------------------
Results for FeatureType 'http://bkg.bund.de/starkregen:ni_geschw_agw':
--------------------------------------------
Geschwindigkeit = -9999.0
--------------------------------------------
''';

  test('the plain text answer is read per scenario and kind', () {
    final readings = parseFeatureInfo(answer);
    expect(readings, hasLength(4), reason: '-9999 is no value');
    expect(
      readings.where(
        (r) => r.scenario == HeavyRainScenario.extreme && r.isDepth,
      ),
      [(scenario: HeavyRainScenario.extreme, isDepth: true, value: 31.0)],
    );
  });

  test('classes follow the BKG legend, bounds included', () {
    expect(classOf(9.9, heavyRainDepthBoundsCm), 0);
    expect(classOf(10, heavyRainDepthBoundsCm), 1);
    expect(classOf(31, heavyRainDepthBoundsCm), 2);
    expect(classOf(400, heavyRainDepthBoundsCm), 6);
    expect(classOf(0.19, heavyRainVelocityBounds), 0);
    expect(classOf(0.6, heavyRainVelocityBounds), 2);
    expect(classOf(2.0, heavyRainVelocityBounds), 4);
  });

  test('the samples reach the radius and no further', () {
    final points = samplePoints(52.2689, 10.5268);
    expect(points, hasLength(17));
    double metres((double, double) p) {
      final dy = (p.$1 - 52.2689) * 111320;
      final dx = (p.$2 - 10.5268) * 111320 * cos(52.2689 * pi / 180);
      return sqrt(dx * dx + dy * dy);
    }

    final farthest = points.map(metres).reduce(max);
    expect(farthest, closeTo(hazardRadiusMetres, 0.5));
  });

  test('the deepest water around the point wins', () async {
    var calls = 0;
    final client = HeavyRainClient(
      httpClient: MockClient((request) async {
        calls++;
        expect(request.url.queryParameters['QUERY_LAYERS'], contains('tiefe'));
        // Only one of the seventeen samples finds water; the others land
        // on a building.
        return http.Response(
          calls == 5
              ? answer
              : "Results for FeatureType 'http://bkg.bund.de/starkregen:"
                    "ni_tiefe_extrem':\nTiefe = -9999.0\n",
          200,
        );
      }),
    );
    final results = await client.check(52.2689, 10.5268);
    expect(calls, 17);
    expect(results[HeavyRainScenario.extreme]!.maxDepthCm, 31);
    expect(results[HeavyRainScenario.extreme]!.depthClass, 2);
    expect(results[HeavyRainScenario.extreme]!.maxVelocity, 0.6);
    expect(results[HeavyRainScenario.exceptional]!.maxDepthCm, 12);
    expect(results[HeavyRainScenario.exceptional]!.maxVelocity, isNull);
  });

  test('a service that answers nothing is an error, not a dry house', () {
    final client = HeavyRainClient(
      httpClient: MockClient((_) async => http.Response('', 503)),
    );
    expect(
      client.check(52.2689, 10.5268),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('the last answer is kept for the day without network', () async {
    final hazard = HeavyRainHazard(
      latitude: 52.2689,
      longitude: 10.5268,
      placeName: 'Braunschweig',
      stateName: 'Niedersachsen',
      checkedAt: DateTime.utc(2026, 10, 6),
      covered: true,
      results: const {
        HeavyRainScenario.extreme: HeavyRainScenarioResult(
          maxDepthCm: 31,
          maxVelocity: 0.6,
        ),
      },
    );
    await const HeavyRainStore().save(hazard);
    final kept = await const HeavyRainStore().load();
    expect(kept!.placeName, 'Braunschweig');
    expect(kept.results[HeavyRainScenario.extreme]!.maxDepthCm, 31);
    expect(kept.anyWater, isTrue);
  });

  test('a cellar is found in every language the app speaks', () {
    expect(isCellar('Keller, Regal 2'), isTrue);
    expect(isCellar('Basement shelf'), isTrue);
    expect(isCellar('Sótano'), isTrue);
    expect(isCellar('Küche'), isFalse);
  });
}
