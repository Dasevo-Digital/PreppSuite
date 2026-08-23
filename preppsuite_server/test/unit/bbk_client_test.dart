import 'dart:io';

import 'package:preppsuite_server/src/warnings/services/bbk_client.dart';
import 'package:test/test.dart';

import 'fixture_http_client.dart';

void main() {
  /// Every source the client polls; a fixture map has to answer all of
  /// them or the fetch counts as incomplete.
  const allSources = ['mowas', 'dwd', 'katwarn', 'biwapp', 'lhp', 'police'];

  Map<String, String> emptyForAllSources({
    Map<String, String> except = const {},
  }) {
    return {
      for (final source in allSources)
        'https://warnung.bund.de/api31/$source/mapData.json':
            except[source] ?? '[]',
    };
  }

  test(
    'fetchAll parses real captured mowas mapData.json into raw warnings',
    () async {
      final fixture = await File(
        'test/fixtures/bbk_mowas_sample.json',
      ).readAsString();

      final client = BbkClient(
        httpClient: FixtureHttpClient(
          emptyForAllSources(except: {'mowas': fixture}),
        ),
      );

      final result = await client.fetchAll();

      expect(result.complete, isTrue);
      expect(result.warnings, hasLength(2));
      expect(result.warnings.first.id, 'mow.DE-HE-MKK-W220-20260811-001');
      expect(result.warnings.first.severity, 'Minor');
      expect(
        result.warnings.first.eventTitleDe,
        contains('Waldbrand im Bereich Nieder- und Oberrodenbach'),
      );
      expect(result.warnings.first.startDate, '2026-08-11T08:30:54+02:00');
    },
  );

  test('fetchAll polls every published BBK source', () async {
    final requested = <String>[];
    final client = BbkClient(
      httpClient: FixtureHttpClient(
        emptyForAllSources(),
        onRequest: requested.add,
      ),
    );

    await client.fetchAll();

    for (final source in allSources) {
      expect(
        requested,
        contains('https://warnung.bund.de/api31/$source/mapData.json'),
        reason: '$source should be polled',
      );
    }
  });

  test(
    'fetchAll reports a complete, empty result when every source answers '
    'with no warnings',
    () async {
      final client = BbkClient(
        httpClient: FixtureHttpClient(emptyForAllSources()),
      );

      final result = await client.fetchAll();

      expect(result.warnings, isEmpty);
      expect(
        result.complete,
        isTrue,
        reason: 'answered-and-empty is a complete picture',
      );
    },
  );

  test(
    'fetchAll keeps the other sources but reports incomplete when one fails',
    () async {
      final fixture = await File(
        'test/fixtures/bbk_mowas_sample.json',
      ).readAsString();

      // `police` is missing from the map, so the fake client 404s it.
      final responses = emptyForAllSources(except: {'mowas': fixture})
        ..remove('https://warnung.bund.de/api31/police/mapData.json');

      final result = await BbkClient(
        httpClient: FixtureHttpClient(responses),
      ).fetchAll();

      expect(
        result.warnings,
        hasLength(2),
        reason: 'a failing source must not discard the others',
      );
      expect(
        result.complete,
        isFalse,
        reason: 'this is what stops stale warnings being retired wrongly',
      );
    },
  );

  test('fetchAll reports incomplete when a source returns garbage', () async {
    final responses = emptyForAllSources(except: {'dwd': 'not json at all'});

    final result = await BbkClient(
      httpClient: FixtureHttpClient(responses),
    ).fetchAll();

    expect(result.complete, isFalse);
  });

  test(
    'fetchDashboard parses the real captured per-Kreis dashboard shape '
    '(nested under payload.data, unlike mapData.json)',
    () async {
      final fixture = await File(
        'test/fixtures/bbk_dashboard_sample.json',
      ).readAsString();

      final client = BbkClient(
        httpClient: FixtureHttpClient({
          'https://warnung.bund.de/api31/dashboard/053340000000.json': fixture,
        }),
      );

      final warnings = await client.fetchDashboard('05334');

      expect(warnings, hasLength(2));
      expect(warnings.first.id, 'mow.DE-NW-AC-SE090-20260813-90-000');
      expect(warnings.first.severity, 'Minor');
      expect(warnings.first.eventTitleDe, contains('Waldbrand'));
      // The dashboard endpoint's top-level `sent` is used, not `startDate`
      // (mapData.json's field) — the dashboard shape doesn't have one.
      expect(warnings.first.startDate, '2026-08-13T17:06:25+02:00');
    },
  );

  test(
    'fetchDashboard zero-pads a 5-digit Kreisschlüssel to the 12-digit '
    'ARS the API expects',
    () async {
      final client = BbkClient(
        httpClient: FixtureHttpClient({
          'https://warnung.bund.de/api31/dashboard/091620000000.json': '[]',
        }),
      );

      expect(await client.fetchDashboard('09162'), isEmpty);
    },
  );
}
