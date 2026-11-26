import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/dwd_areas.dart';
import 'package:preppsuite_flutter/features/warnings/application/meteoalarm_client.dart';

import '../fixture_http_client.dart';

/// How the MeteoAlarm feed is read.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const url =
      'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-germany';

  /// A feed of one entry, in the live shape of 2026-11-26.
  String feed(String area) =>
      '''
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2">
  <updated>2026-11-26T08:34:46.521780Z</updated>
  <entry>
    <cap:geocode>
      <valueName>EMMA_ID</valueName>
      <value>DE336</value>
    </cap:geocode>
    <cap:areaDesc>$area</cap:areaDesc>
    <cap:event>frost</cap:event>
    <cap:sent>2026-11-26T08:33:00+00:00</cap:sent>
    <cap:expires>2026-11-26T15:00:00+00:00</cap:expires>
    <cap:onset>2026-11-26T08:33:00+00:00</cap:onset>
    <cap:severity>Minor</cap:severity>
    <cap:message_type>Alert</cap:message_type>
    <cap:identifier>2.49.0.0.276.0.DWD.PVW.1795681980000.6eaf5b45-7fe5-4e2f-aed7-e0686aeaf2ab.MUL</cap:identifier>
    <title>Yellow Frost Warning issued for Germany - $area</title>
  </entry>
</feed>
''';

  test('a feed sent without a charset is read as UTF-8 (#396)', () async {
    // The fixture client sends no Content-Type at all. `response.body`
    // takes that as Latin-1, and "Lörrach" came out as "LÃ¶rrach".
    final client = MeteoAlarmClient(
      httpClient: FixtureHttpClient({url: feed('Kreis Lörrach')}),
    );

    final warnings = (await client.fetchCountry('germany')).warnings!;

    expect(warnings.single.areaDesc, 'Kreis Lörrach');
    expect(warnings.single.title, endsWith('- Kreis Lörrach'));
    // Which is what lets the region filter place it at all.
    final areas = await DwdAreas.load();
    expect(areas.regionKeyFor(warnings.single.areaDesc), '08336');
  });
}
