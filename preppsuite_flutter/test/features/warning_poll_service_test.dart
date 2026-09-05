import 'dart:io';

import 'package:drift/drift.dart' show Value;

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/meteoalarm_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'fixture_http_client.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final mowas = File('test/fixtures/bbk_mowas_sample.json').readAsStringSync();
  final dashboard = File(
    'test/fixtures/bbk_dashboard_sample.json',
  ).readAsStringSync();
  final meteoalarm = File(
    'test/fixtures/meteoalarm_germany_sample.xml',
  ).readAsStringSync();

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

  test('a warning that drops out of a complete poll is ended', () async {
    await service({
      ...allBbkSources(mowasBody: mowas),
    }).poll(countryCode: 'DE');

    final result = await service({
      ...allBbkSources(mowasBody: '[]'),
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
