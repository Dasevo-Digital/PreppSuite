import 'dart:io';

import 'package:preppsuite_server/src/warnings/services/meteoalarm_client.dart';
import 'package:test/test.dart';

import 'fixture_http_client.dart';

void main() {
  test(
    'fetchCountry parses a real captured Atom+CAP feed into raw warnings',
    () async {
      final fixture = await File(
        'test/fixtures/meteoalarm_germany_sample.xml',
      ).readAsString();

      final client = MeteoAlarmClient(
        httpClient: FixtureHttpClient({
          'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-germany':
              fixture,
        }),
      );

      final warnings = await client.fetchCountry('germany');

      expect(warnings, hasLength(2));
      final first = warnings.first;
      expect(
        first.identifier,
        '2.49.0.0.276.0.DWD.PVW.1786692480000.e1e9e179-0509-44d4-9aea-4c9d09930eeb.MUL',
      );
      expect(first.areaDesc, 'Stadt Frankfurt am Main');
      expect(first.event, 'strong heat');
      expect(first.severity, 'Minor');
      expect(first.sent, '2026-08-14T07:28:00+00:00');
      expect(first.expires, '2026-08-15T17:00:00+00:00');
      expect(
        first.title,
        'Yellow High-temperature Warning issued for Germany - Stadt Frankfurt am Main',
      );
    },
  );

  test('country slug map covers every warningFeedCountries entry used by '
      'the Flutter app', () {
    // Mirrors the client's country list (kept in sync by hand, see
    // meteoAlarmCountrySlugs' doc comment) — this just guards against typos
    // in the ISO codes.
    const expectedCodes = [
      'DE', 'AT', 'CH', 'FR', 'IT', 'ES', 'PT', 'NL', 'BE',
      'LU', 'PL', 'CZ', 'DK', 'SE', 'NO', 'FI', 'IE', 'GB', //
    ];
    expect(meteoAlarmCountrySlugs.keys.toSet(), expectedCodes.toSet());
  });
}
