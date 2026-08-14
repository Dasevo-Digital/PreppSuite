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

  test('fetchAll returns an empty list for a source with no warnings', () async {
    final client = BbkClient(
      httpClient: FixtureHttpClient({
        'https://warnung.bund.de/api31/mowas/mapData.json': '[]',
        'https://warnung.bund.de/api31/dwd/mapData.json': '[]',
      }),
    );

    expect(await client.fetchAll(), isEmpty);
  });
}
