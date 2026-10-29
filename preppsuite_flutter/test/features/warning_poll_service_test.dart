import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/meteoalarm_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixture_http_client.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  for (final sameTimestamp in [false, true]) {
    test(
      'an old acknowledgement leaves an escalation pending (same time: $sameTimestamp)',
      () async {
        final service = WarningPollService(database: db);
        final at = DateTime.now().toUtc();
        Future<void> put(String severity, DateTime sent) => db.upsertWarning(
          WarningsCompanion.insert(
            source: 'bbk',
            externalId: 'escalation',
            countryCode: 'DE',
            severity: severity,
            eventType: 'Test',
            headline: 'Test',
            effective: sent,
            sent: sent,
            updatedAt: sent,
            notified: const Value(false),
          ),
        );
        await put('moderate', at);
        final before = await service.pendingNotifications(
          isRelevant: (_) => true,
        );
        expect(before, hasLength(1));
        await put(
          'extreme',
          sameTimestamp ? at : at.add(const Duration(minutes: 1)),
        );
        await service.markNotified(before);
        final after = await service.pendingNotifications(
          isRelevant: (_) => true,
        );
        expect(after.single.severity, 'extreme');
        await service.markNotified(after);
        expect(
          await service.pendingNotifications(isRelevant: (_) => true),
          isEmpty,
        );
      },
    );
  }

  final mowas = File('test/fixtures/bbk_mowas_sample.json').readAsStringSync();
  final dashboard = File(
    'test/fixtures/bbk_dashboard_sample.json',
  ).readAsStringSync();

  /// The captured MeteoAlarm feed, with its expiry moved to tomorrow.
  ///
  /// The file is a real feed and therefore carries real timestamps --
  /// `2026-08-15T17:00:00+00:00`. `poll` finishes by calling
  /// [AppDatabase.pruneExpiredWarnings], which deletes anything that
  /// expired more than thirty days ago, so a fixture this old is written
  /// and then removed again inside the same call: the warnings simply
  /// stop being there, and the test fails saying MeteoAlarm stored
  /// nothing.
  ///
  /// It happened exactly that way on 2026-09-15. The two tests below had
  /// passed the evening before with under two hours to spare, because
  /// that is when the thirty-day cutoff crossed the fixture's expiry.
  /// Moving the date here rather than editing the file keeps the capture
  /// genuine and takes the clock out of it for good.
  final meteoalarm =
      File(
        'test/fixtures/meteoalarm_germany_sample.xml',
      ).readAsStringSync().replaceAll(
        '2026-08-15T17:00:00+00:00',
        DateTime.now().toUtc().add(const Duration(days: 1)).toIso8601String(),
      );

  const bbkBase = 'https://warnung.bund.de/api31';
  const meteoUrl =
      'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-germany';

  /// Every BBK source answers; only mowas has content. That is the normal
  /// live shape — most of the six are usually empty.
  Map<String, String> allBbkSources({String mowasBody = ''}) => {
    for (final source in ['mowas', 'dwd', 'katwarn', 'biwapp', 'lhp', 'police'])
      '$bbkBase/$source/mapData.json': source == 'mowas' ? mowasBody : '[]',
  };

  WarningPollService service(Map<String, String> responses) {
    final client = FixtureHttpClient(responses);
    return WarningPollService(
      database: db,
      bbkClient: BbkClient(httpClient: client),
      meteoAlarmClient: MeteoAlarmClient(httpClient: client),
    );
  }

  test(
    'detail budget keeps regional warnings and still polls weather',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.now().toUtc();
      await db.upsertWarning(
        WarningsCompanion.insert(
          source: 'bbk',
          externalId: 'regional-only',
          countryCode: 'DE',
          regionKey: const Value('05334'),
          severity: 'moderate',
          eventType: 'Test',
          headline: 'Test',
          effective: now,
          sent: now,
          updatedAt: now,
          expires: Value(now.add(const Duration(days: 1))),
        ),
      );
      final requested = <String>[];
      final client = FixtureHttpClient({
        ...allBbkSources(mowasBody: mowas),
        meteoUrl: meteoalarm,
      }, onRequest: requested.add);
      final result = await WarningPollService(
        database: db,
        bbkClient: BbkClient(httpClient: client),
        meteoAlarmClient: MeteoAlarmClient(httpClient: client),
        detailBudget: Duration.zero,
      ).poll(countryCode: 'DE', kreisSchluessel: '05334');
      expect(result.complete, isFalse);
      expect(result.retired, 0);
      expect(requested, contains(meteoUrl));
      expect(
        requested.where(
          (url) => url.contains('/dashboard/') || url.contains('/warnings/'),
        ),
        isEmpty,
      );
      expect(
        (await db.watchAllWarnings().first).any(
          (w) => w.externalId == 'regional-only',
        ),
        isTrue,
      );
      final status = await const WarningPollStatusStore().load();
      expect(status.sourceComplete['meteoalarm'], isNotNull);
      expect(status.sourceComplete['bbk'], isNull);
    },
  );

  test('stores warnings from both feeds', () async {
    final result = await service({
      ...allBbkSources(mowasBody: mowas),
      meteoUrl: meteoalarm,
    }).poll(countryCode: 'DE');

    final stored = await db.watchAllWarnings().first;
    expect(stored.map((w) => w.source).toSet(), {'bbk', 'meteoalarm'});
    expect(result.fetched, stored.length);
    expect(result.complete, isTrue);
  });

  test('polling twice does not announce the same warning again', () async {
    // The property that keeps the channel worth listening to: the feeds
    // reissue unchanged warnings constantly.
    final responses = {
      ...allBbkSources(mowasBody: mowas),
      meteoUrl: meteoalarm,
    };

    final first = await service(responses).poll(countryCode: 'DE');
    final second = await service(responses).poll(countryCode: 'DE');

    expect(first.newsworthy, isNotEmpty);
    expect(second.newsworthy, isEmpty);
  });

  test('a country without a MeteoAlarm feed still polls BBK', () async {
    final result = await service(
      allBbkSources(mowasBody: mowas),
    ).poll(countryCode: 'DE');

    expect(result.fetched, greaterThan(0));
  });

  test('a non-German country does not hit the BBK feeds at all', () async {
    // BBK is Germany-only; asking it about Austria would be pointless
    // traffic against a public API.
    final requested = <String>[];
    final client = FixtureHttpClient({
      'https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-austria':
          meteoalarm,
    }, onRequest: requested.add);

    await WarningPollService(
      database: db,
      bbkClient: BbkClient(httpClient: client),
      meteoAlarmClient: MeteoAlarmClient(httpClient: client),
    ).poll(countryCode: 'AT');

    expect(requested.every((url) => !url.contains('warnung.bund.de')), isTrue);
  });

  test('a failing BBK source leaves warnings standing', () async {
    // The whole point of tracking completeness: an unreachable source
    // looks exactly like an empty one, and retiring on that would end
    // warnings that are still running.
    await service({
      ...allBbkSources(mowasBody: mowas),
    }).poll(countryCode: 'DE');
    final before = (await db.watchAllWarnings().first).length;

    // Now only one source answers — the rest 404.
    final result = await service({
      '$bbkBase/mowas/mapData.json': '[]',
    }).poll(countryCode: 'DE');

    expect(result.complete, isFalse);
    expect(result.retired, 0);
    expect(await db.watchAllWarnings().first, hasLength(before));
  });

  test('a broken MeteoAlarm feed does not cost the BBK warnings', () async {
    // MeteoAlarm is asked last, after BBK has been stored. A feed that
    // timed out or arrived cut off used to throw out of the whole poll,
    // so the run was reported as failed and the status never recorded —
    // although every German warning had arrived (#46).
    final result = await service({
      ...allBbkSources(mowasBody: mowas),
      meteoUrl: '<feed><entry>',
    }).poll(countryCode: 'DE');

    final stored = await db.watchAllWarnings().first;
    expect(stored.map((w) => w.source).toSet(), {'bbk'});
    expect(result.complete, isFalse);
  });

  group('status per feed (#92)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('MeteoAlarm down leaves the BBK current', () async {
      await service({
        ...allBbkSources(mowasBody: mowas),
        meteoUrl: '<feed><entry>',
      }).poll(countryCode: 'DE');

      final status = await const WarningPollStatusStore().load();
      expect(status.lastComplete, isNull);
      expect(status.currentAt('DE'), status.lastAttempt);
      expect(status.lagging('DE'), ['meteoalarm']);
    });

    test(
      'an HTTP error from MeteoAlarm is an outage, not an empty feed',
      () async {
        // The fixture client answers 404 for a URL it does not know.
        final result = await service({
          ...allBbkSources(mowasBody: mowas),
        }).poll(countryCode: 'DE');

        expect(result.complete, isFalse);
        final status = await const WarningPollStatusStore().load();
        expect(status.lagging('DE'), ['meteoalarm']);
      },
    );

    test('both answering makes the whole run current', () async {
      await service({
        ...allBbkSources(mowasBody: mowas),
        meteoUrl: meteoalarm,
      }).poll(countryCode: 'DE');

      final status = await const WarningPollStatusStore().load();
      expect(status.lastComplete, status.lastAttempt);
      expect(status.lagging('DE'), isEmpty);
    });
  });

  test('a warning that drops out of a complete poll is ended', () async {
    await service({
      ...allBbkSources(mowasBody: mowas),
    }).poll(countryCode: 'DE');

    // MeteoAlarm answers too, with nothing in force: since #92 a feed that
    // is not there at all (the fixture client's 404) is an outage and
    // leaves the run incomplete.
    final result = await service({
      ...allBbkSources(mowasBody: '[]'),
      meteoUrl: '<feed xmlns="http://www.w3.org/2005/Atom"></feed>',
    }).poll(countryCode: 'DE');

    expect(result.complete, isTrue);
    expect(result.retired, greaterThan(0));
    final stored = await db.watchAllWarnings().first;
    expect(stored.every((w) => w.expires != null), isTrue);
  });

  test('the per-Kreis fetch is used when a region is known', () async {
    final requested = <String>[];
    final client = FixtureHttpClient({
      ...allBbkSources(mowasBody: mowas),
      '$bbkBase/dashboard/053340000000.json': dashboard,
    }, onRequest: requested.add);

    await WarningPollService(
      database: db,
      bbkClient: BbkClient(httpClient: client),
      meteoAlarmClient: MeteoAlarmClient(httpClient: client),
    ).poll(countryCode: 'DE', kreisSchluessel: '05334000');

    expect(requested, contains('$bbkBase/dashboard/053340000000.json'));
    final precise = (await db.watchAllWarnings().first).where(
      (w) => w.regionKey == '05334',
    );
    expect(precise, isNotEmpty);
  });

  test(
    'every followed additional district receives a precise BBK fetch',
    () async {
      final requested = <String>[];
      final client = FixtureHttpClient({
        ...allBbkSources(mowasBody: mowas),
        '$bbkBase/dashboard/053340000000.json': dashboard,
        '$bbkBase/dashboard/031010000000.json': dashboard,
      }, onRequest: requested.add);

      await WarningPollService(
        database: db,
        bbkClient: BbkClient(httpClient: client),
        meteoAlarmClient: MeteoAlarmClient(httpClient: client),
      ).poll(
        countryCode: 'DE',
        kreisSchluessel: '05334',
        extraKreisSchluessel: const ['03101', '05334'],
      );

      expect(requested, contains('$bbkBase/dashboard/053340000000.json'));
      expect(requested, contains('$bbkBase/dashboard/031010000000.json'));
    },
  );

  group('the detail behind a warning (#177)', () {
    // The bomb disposal in Braunschweig on 2026-10-16, as the feeds carried
    // it: in the nationwide MoWaS map, in the district dashboard, and with
    // its CAP detail -- HTML line breaks and all -- behind both.
    const id = 'mow.DE-NI-BS-SE129-20261016-157-000';
    const title =
        'Entschärfung einer Weltkriegsbombe - Braunschweig Leiferde/Stöckheim';
    const sent = '2026-10-16T09:49:32+02:00';
    final mapData = jsonEncode([
      {
        'id': id,
        'version': 1,
        'startDate': sent,
        'severity': 'Minor',
        'type': 'Alert',
        'i18nTitle': {'de': title},
      },
    ]);
    final districtDashboard = jsonEncode([
      {
        'id': id,
        'sent': sent,
        'i18nTitle': {'de': title},
        'payload': {
          'data': {'severity': 'Minor', 'headline': title},
        },
      },
    ]);
    final detail = jsonEncode({
      'identifier': id,
      'sender': 'DE-NI-BS-SE129',
      'info': [
        {
          'language': 'DE',
          'description':
              'Im Bereich Braunschweig Leiferde/Stöckheim kommt es zu einer '
              'Entschärfung einer Weltkriegsbombe.<br/>Aus '
              'Sicherheitsgründen ist das Gebiet in einem Umkreis von 1000 '
              'Meter unverzüglich zu verlassen.',
          'instruction':
              'Meiden Sie das betroffene Gebiet.<br/>Verlassen Sie sofort '
              'das betroffene Gebiet.',
          'area': [
            {'areaDesc': 'Braunschweig Leiferde/Stöckheim'},
          ],
        },
      ],
    });
    const dashboardUrl = '$bbkBase/dashboard/031010000000.json';
    const detailUrl = '$bbkBase/warnings/$id.json';

    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<Warning> stored() async => (await db.warningsBySource('bbk'))[id]!;

    test(
      'the district pass keeps the text the nationwide pass fetched',
      () async {
        await service({
          ...allBbkSources(mowasBody: mapData),
          dashboardUrl: districtDashboard,
          detailUrl: detail,
        }).poll(countryCode: 'DE', kreisSchluessel: '03101');

        final warning = await stored();
        expect(warning.regionKey, '03101');
        expect(warning.areaDescription, 'Braunschweig Leiferde/Stöckheim');
        expect(
          warning.description,
          'Im Bereich Braunschweig Leiferde/Stöckheim kommt es zu einer '
          'Entschärfung einer Weltkriegsbombe.\nAus Sicherheitsgründen ist '
          'das Gebiet in einem Umkreis von 1000 Meter unverzüglich zu '
          'verlassen.',
        );
        expect(
          warning.instruction,
          'Meiden Sie das betroffene Gebiet.\n'
          'Verlassen Sie sofort das betroffene Gebiet.',
        );
      },
    );

    test('a detail that failed is asked for again on the next poll', () async {
      final feeds = {
        ...allBbkSources(mowasBody: mapData),
        dashboardUrl: districtDashboard,
      };
      await service(feeds).poll(countryCode: 'DE', kreisSchluessel: '03101');
      expect((await stored()).instruction, isNull);

      await service({
        ...feeds,
        detailUrl: detail,
      }).poll(countryCode: 'DE', kreisSchluessel: '03101');

      final warning = await stored();
      expect(warning.instruction, contains('Verlassen Sie sofort'));
      expect(warning.regionKey, '03101');
    });

    test('asking again is capped per poll', () async {
      final many = jsonEncode([
        for (var i = 0; i < 30; i++)
          {
            'id': 'mow.DE-NI-BS-SE129-20261016-157-${100 + i}',
            'startDate': sent,
            'severity': 'Minor',
            'i18nTitle': {'de': title},
          },
      ]);
      await service(allBbkSources(mowasBody: many)).poll(countryCode: 'DE');

      final asked = <String>[];
      final client = FixtureHttpClient(
        allBbkSources(mowasBody: many),
        onRequest: asked.add,
      );
      await WarningPollService(
        database: db,
        bbkClient: BbkClient(httpClient: client),
        meteoAlarmClient: MeteoAlarmClient(httpClient: client),
      ).poll(countryCode: 'DE');

      expect(
        asked.where((url) => url.contains('/warnings/')),
        hasLength(WarningPollService.detailRetriesPerPoll),
      );
    });
  });

  group('pendingNotifications', () {
    /// The captured feeds contain only `Minor` entries, so anything that
    /// has to be announced is written directly. Polling first and hoping
    /// for a severe warning would make these tests pass whether the filter
    /// worked or not.
    Future<void> storeWarning({
      required String externalId,
      String severity = 'severe',
      DateTime? expires,
    }) {
      return db.upsertWarning(
        WarningsCompanion.insert(
          source: 'bbk',
          externalId: externalId,
          countryCode: 'DE',
          severity: severity,
          eventType: 'Test',
          headline: 'Warnung $externalId',
          effective: DateTime.utc(2026),
          expires: Value(expires),
          sent: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
    }

    test('minor warnings are never announced', () async {
      // Exactly what the captured feeds contain, which is also the normal
      // live case: most of what BBK carries is minor.
      await service({
        ...allBbkSources(mowasBody: mowas),
        meteoUrl: meteoalarm,
      }).poll(countryCode: 'DE');

      final pending = await service(
        {},
      ).pendingNotifications(isRelevant: (_) => true);

      expect(await db.watchAllWarnings().first, isNotEmpty);
      expect(pending, isEmpty);
    });

    test('a severe warning is announced', () async {
      await storeWarning(externalId: 'severe-1');

      final pending = await service(
        {},
      ).pendingNotifications(isRelevant: (_) => true);

      expect(pending.map((w) => w.externalId), ['severe-1']);
    });

    test('an already expired warning is not announced', () async {
      await storeWarning(
        externalId: 'over',
        expires: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
      );

      final pending = await service(
        {},
      ).pendingNotifications(isRelevant: (_) => true);

      expect(pending, isEmpty);
    });

    test('respects the relevance predicate', () async {
      await storeWarning(externalId: 'elsewhere');

      final pending = await service(
        {},
      ).pendingNotifications(isRelevant: (_) => false);

      expect(pending, isEmpty);
    });

    test('an announced warning is not offered twice', () async {
      await storeWarning(externalId: 'severe-1');
      final poller = service({});

      final first = await poller.pendingNotifications(isRelevant: (_) => true);
      await poller.markNotified(first);
      final second = await poller.pendingNotifications(isRelevant: (_) => true);

      expect(first, hasLength(1));
      expect(second, isEmpty);
    });
  });
}
