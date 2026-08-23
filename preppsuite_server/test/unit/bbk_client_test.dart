import 'dart:io';

import 'package:preppsuite_server/src/warnings/services/bbk_client.dart';
import 'package:test/test.dart';

import 'fixture_http_client.dart';

void main() {
  test(
    'fetchAll parses real captured mowas mapData.json into raw warnings',
    () async {
      final fixture = await File(
        'test/fixtures/bbk_mowas_sample.json',
      ).readAsString();

      final client = BbkClient(
        httpClient: FixtureHttpClient({
          'https://warnung.bund.de/api31/mowas/mapData.json': fixture,
          'https://warnung.bund.de/api31/dwd/mapData.json': '[]',
        }),
      );

      final warnings = await client.fetchAll();

      expect(warnings, hasLength(2));
      expect(warnings.first.id, 'mow.DE-HE-MKK-W220-20260811-001');
      expect(warnings.first.severity, 'Minor');
      expect(
        warnings.first.eventTitleDe,
        contains('Waldbrand im Bereich Nieder- und Oberrodenbach'),
      );
      expect(warnings.first.startDate, '2026-08-11T08:30:54+02:00');
    },
  );

  test(
    'fetchAll returns an empty list for a source with no warnings',
    () async {
      final client = BbkClient(
        httpClient: FixtureHttpClient({
          'https://warnung.bund.de/api31/mowas/mapData.json': '[]',
          'https://warnung.bund.de/api31/dwd/mapData.json': '[]',
        }),
      );

      expect(await client.fetchAll(), isEmpty);
    },
  );

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
