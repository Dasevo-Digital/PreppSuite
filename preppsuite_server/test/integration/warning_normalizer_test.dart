import 'dart:io';

import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart' show Session;
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
          (await client.fetchAll()).warnings,
          countryCode: 'DE',
        );

        final stored = await Warning.db.find(
          session,
          where: (t) => t.source.equals(WarningSource.bbk),
        );

        expect(stored, hasLength(2));
        expect(
          stored.every((w) => w.severity == WarningSeverity.minor),
          isTrue,
        );
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
        expect(
          stored.every((w) => w.severity == WarningSeverity.minor),
          isTrue,
        );
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
        final warnings = (await client.fetchAll()).warnings;

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

    /// Builds a raw BBK warning without going through the HTTP client, so
    /// id shapes and reaping can be exercised directly.
    BbkRawWarning raw(String id) => BbkRawWarning(
      id: id,
      startDate: '2026-08-11T08:30:54+02:00',
      severity: 'Minor',
      eventTitleDe: 'Test',
      raw: {'id': id},
    );

    test(
      'when a warning drops out of the feed then it is stamped with an '
      'expiry instead of staying active forever',
      () async {
        final session = sessionBuilder.build();
        await normalizer.upsertBbk(session, [
          raw('mow.DE-HE-A-1'),
          raw('mow.DE-HE-B-2'),
        ], countryCode: 'DE');

        final retired = await normalizer.expireMissingBbk(
          session,
          seenExternalIds: {'mow.DE-HE-A-1'},
          countryCode: 'DE',
        );

        expect(retired, 1);

        final stored = {
          for (final w in await Warning.db.find(
            session,
            where: (t) => t.source.equals(WarningSource.bbk),
          ))
            w.externalId: w.expires,
        };

        expect(stored['mow.DE-HE-A-1'], isNull, reason: 'still in the feed');
        expect(stored['mow.DE-HE-B-2'], isNotNull, reason: 'gone from feed');
      },
    );

    test(
      'when a warning is already expired then its expiry is not moved on a '
      'later poll',
      () async {
        final session = sessionBuilder.build();
        await normalizer.upsertBbk(session, [
          raw('mow.DE-HE-A-1'),
        ], countryCode: 'DE');

        await normalizer.expireMissingBbk(
          session,
          seenExternalIds: const {},
          countryCode: 'DE',
        );
        final firstExpiry = (await Warning.db.find(session)).single.expires;

        final retiredAgain = await normalizer.expireMissingBbk(
          session,
          seenExternalIds: const {},
          countryCode: 'DE',
        );

        expect(retiredAgain, 0, reason: 'nothing left to retire');
        expect(
          (await Warning.db.find(session)).single.expires,
          firstExpiry,
          reason: 'expiry records when it ended, it must not creep forward',
        );
      },
    );

    test('expiring is scoped to BBK warnings of the given country', () async {
      final session = sessionBuilder.build();
      await normalizer.upsertBbk(session, [
        raw('mow.DE-HE-A-1'),
      ], countryCode: 'DE');
      await normalizer.upsertBbk(session, [
        raw('mow.AT-9-B-2'),
      ], countryCode: 'AT');

      await normalizer.expireMissingBbk(
        session,
        seenExternalIds: const {},
        countryCode: 'DE',
      );

      final austrian = await Warning.db.findFirstRow(
        session,
        where: (t) => t.externalId.equals('mow.AT-9-B-2'),
      );
      expect(austrian!.expires, isNull);
    });

    /// Inserts a warning directly, so expiry and age can be set freely.
    Future<void> storeWarning(
      Session session, {
      required String externalId,
      DateTime? expires,
      DateTime? sent,
    }) async {
      final stamp = sent ?? DateTime.now().toUtc();
      await Warning.db.insertRow(
        session,
        Warning(
          source: WarningSource.bbk,
          externalId: externalId,
          countryCode: 'DE',
          severity: WarningSeverity.minor,
          eventType: 'Test',
          headline: 'Test',
          effective: stamp,
          expires: expires,
          sent: stamp,
          rawPayload: '{}',
          createdAt: stamp,
          updatedAt: stamp,
        ),
      );
    }

    group('pruneExpiredWarnings', () {
      test('removes warnings whose expiry is long past', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now().toUtc();
        await storeWarning(
          session,
          externalId: 'long-gone',
          expires: now.subtract(const Duration(days: 90)),
        );
        await storeWarning(
          session,
          externalId: 'recently-ended',
          expires: now.subtract(const Duration(days: 5)),
        );

        final pruned = await normalizer.pruneExpiredWarnings(session);

        expect(pruned, 1);
        expect(
          (await Warning.db.find(session)).map((w) => w.externalId),
          ['recently-ended'],
        );
      });

      test('keeps a warning that has no expiry, however old', () async {
        // The BBK feed carries containment zones that have stood for
        // months. They have no expiry precisely because they are still in
        // force — deleting by age alone would drop exactly those.
        final session = sessionBuilder.build();
        await storeWarning(
          session,
          externalId: 'still-in-force',
          expires: null,
          sent: DateTime.now().toUtc().subtract(const Duration(days: 200)),
        );

        final pruned = await normalizer.pruneExpiredWarnings(session);

        expect(pruned, 0);
        expect(await Warning.db.find(session), hasLength(1));
      });

      test('the retention window is configurable', () async {
        final session = sessionBuilder.build();
        await storeWarning(
          session,
          externalId: 'ended-10-days-ago',
          expires: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        );

        expect(
          await normalizer.pruneExpiredWarnings(
            session,
            retention: const Duration(days: 30),
          ),
          0,
          reason: 'inside the window',
        );
        expect(
          await normalizer.pruneExpiredWarnings(
            session,
            retention: const Duration(days: 7),
          ),
          1,
          reason: 'outside a shorter window',
        );
      });

      test('leaves an active warning alone', () async {
        final session = sessionBuilder.build();
        await storeWarning(
          session,
          externalId: 'active',
          expires: DateTime.now().toUtc().add(const Duration(days: 2)),
        );

        expect(await normalizer.pruneExpiredWarnings(session), 0);
      });
    });

    test(
      'the state code is read from both id shapes the sources use',
      () async {
        final session = sessionBuilder.build();

        await normalizer.upsertBbk(session, [
          // mowas/dwd shape
          raw('mow.DE-HE-MKK-W220-20260811-001'),
          // lhp/police shape, confirmed live: lhp.LHP.NW.nw86768
          raw('lhp.LHP.NW.nw86768'),
          // Two capitals that are not a state code must not be mistaken
          // for a region — a wrong region hides a warning, no region
          // shows it to everyone.
          raw('xyz.ZZ.QQ.123'),
        ], countryCode: 'DE');

        final byId = {
          for (final w in await Warning.db.find(session)) w.externalId: w,
        };

        expect(byId['mow.DE-HE-MKK-W220-20260811-001']!.regionKey, 'HE');
        expect(byId['lhp.LHP.NW.nw86768']!.regionKey, 'NW');
        expect(byId['xyz.ZZ.QQ.123']!.regionKey, isNull);
      },
    );
  }, rollbackDatabase: RollbackDatabase.afterEach);
}
