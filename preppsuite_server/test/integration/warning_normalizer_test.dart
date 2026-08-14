import 'dart:io';

import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:preppsuite_server/src/warnings/services/bbk_client.dart';
import 'package:preppsuite_server/src/warnings/services/meteoalarm_client.dart';
import 'package:preppsuite_server/src/warnings/services/warning_normalizer.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';
import '../unit/fixture_http_client.dart';

void main() {
  withServerpod('Given WarningNormalizer', (sessionBuilder, endpoints) {
    const normalizer = WarningNormalizer();

    test(
      'when upserting real captured BBK warnings then they are stored with '
      'normalized severity',
      () async {
        final session = sessionBuilder.build();
        final fixture = await File(
          'test/fixtures/bbk_mowas_sample.json',
        ).readAsString();
        final client = BbkClient(
          httpClient: FixtureHttpClient({
            'https://warnung.bund.de/api31/mowas/mapData.json': fixture,
            'https://warnung.bund.de/api31/dwd/mapData.json': '[]',
          }),
        );

        await normalizer.upsertBbk(
          session,
          await client.fetchAll(),
          countryCode: 'DE',
        );

        final stored = await Warning.db.find(
          session,
          where: (t) => t.source.equals(WarningSource.bbk),
        );

        expect(stored, hasLength(2));
        expect(stored.every((w) => w.severity == WarningSeverity.minor), isTrue);
        expect(stored.every((w) => w.countryCode == 'DE'), isTrue);
        expect(
          stored.map((w) => w.externalId),
          contains('mow.DE-HE-MKK-W220-20260811-001'),
        );
      },
    );

    test(
      'when upserting real captured MeteoAlarm warnings then they are '
      'stored with parsed effective/expires',
      () async {
        final session = sessionBuilder.build();
        final fixture = await File(
          'test/fixtures/meteoalarm_germany_sample.xml',
        ).readAsString();
        final client = MeteoAlarmClient(
          httpClient: FixtureHttpClient({
            'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-germany':
                fixture,
          }),
        );

        await normalizer.upsertMeteoAlarm(
          session,
          await client.fetchCountry('germany'),
          countryCode: 'DE',
        );

        final stored = await Warning.db.find(
          session,
          where: (t) => t.source.equals(WarningSource.meteoalarm),
        );

        expect(stored, hasLength(2));
        final frankfurt = stored.firstWhere(
          (w) => w.regionKey == 'Stadt Frankfurt am Main',
        );
        expect(frankfurt.eventType, 'strong heat');
        expect(frankfurt.expires, isNotNull);
        expect(frankfurt.effective.year, 2026);
      },
    );

    test(
      'when upserting from the per-Kreis dashboard endpoint then the '
      'precise Kreisschlüssel overrides the id-parsed state code',
      () async {
        final session = sessionBuilder.build();
        final fixture = await File(
          'test/fixtures/bbk_dashboard_sample.json',
        ).readAsString();
        final client = BbkClient(
          httpClient: FixtureHttpClient({
            'https://warnung.bund.de/api31/dashboard/053340000000.json':
                fixture,
          }),
        );

        await normalizer.upsertBbk(
          session,
          await client.fetchDashboard('05334'),
          countryCode: 'DE',
          regionKeyOverride: '05334',
        );

        final stored = await Warning.db.find(
          session,
          where: (t) => t.source.equals(WarningSource.bbk),
        );

        expect(stored, hasLength(2));
        expect(stored.every((w) => w.regionKey == '05334'), isTrue);
        expect(stored.every((w) => w.severity == WarningSeverity.minor), isTrue);
        expect(
          stored.first.sent.toIso8601String(),
          startsWith('2026-08-13'),
        );
      },
    );

    test(
      'when the same external id is upserted twice with an unchanged sent '
      'timestamp then it does not duplicate or bump updatedAt',
      () async {
        final session = sessionBuilder.build();
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

        await normalizer.upsertBbk(session, warnings, countryCode: 'DE');
        final firstPass = {
          for (final w in await Warning.db.find(
            session,
            where: (t) => t.source.equals(WarningSource.bbk),
          ))
            w.externalId: w.updatedAt,
        };

        await normalizer.upsertBbk(session, warnings, countryCode: 'DE');
        final secondPass = {
          for (final w in await Warning.db.find(
            session,
            where: (t) => t.source.equals(WarningSource.bbk),
          ))
            w.externalId: w.updatedAt,
        };

        expect(secondPass.length, firstPass.length);
        expect(secondPass, firstPass);
      },
    );
  }, rollbackDatabase: RollbackDatabase.afterEach);
}
