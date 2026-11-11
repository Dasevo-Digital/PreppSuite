import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preppsuite_flutter/features/warnings/application/bbk_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/meteoalarm_client.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A feed that is not as expected must cost what is wrong with it and no
/// more (#369), and a poll that did not get everything must say so (#371).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() => db.close());

  http.Response answer(Object body, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(body)), status);

  Map<String, Object?> entry(String id) => {
    'id': id,
    'startDate': '2026-11-11T08:00:00+01:00',
    'severity': 'Severe',
    'type': 'Alert',
    'i18nTitle': {'de': 'Warnung $id'},
  };

  BbkClient bbk({
    List<Object?> mowas = const [],
    List<Object?> dwd = const [],
    int dashboardStatus = 200,
  }) => BbkClient(
    httpClient: MockClient((request) async {
      final path = request.url.path;
      if (path.endsWith('/mowas/mapData.json')) return answer(mowas);
      if (path.endsWith('/dwd/mapData.json')) return answer(dwd);
      if (path.contains('/dashboard/')) {
        return dashboardStatus == 200
            ? answer(<Object>[])
            : answer({}, dashboardStatus);
      }
      if (path.contains('/warnings/')) return answer({}, 404);
      return answer(<Object>[]);
    }),
  );

  Future<Set<String>> stored() async =>
      (await db.warningsBySource('bbk')).keys.toSet();

  test('one entry without its date leaves the others and MeteoAlarm', () async {
    final meteo = _Meteo();
    final result = await WarningPollService(
      database: db,
      bbkClient: bbk(
        mowas: [
          entry('mow.good'),
          {'id': 'mow.bad', 'severity': 'Severe'},
        ],
        dwd: [entry('dwd.frost')],
      ),
      meteoAlarmClient: meteo,
    ).poll(countryCode: 'DE');

    expect(await stored(), {'mow.good', 'dwd.frost'});
    expect(meteo.asked, isTrue, reason: 'the weather source is still asked');
    expect(result.complete, isFalse, reason: 'one entry could not be read');
    final status = await const WarningPollStatusStore().load();
    expect(status.sourceComplete['bbk'], isNull);
    expect(status.sourceComplete['meteoalarm'], isNotNull);
  });

  test('something that is not an entry makes the source incomplete', () async {
    final result = await WarningPollService(
      database: db,
      bbkClient: bbk(mowas: [entry('mow.good'), 'kaputt', 42]),
      meteoAlarmClient: _Meteo(),
    ).poll(countryCode: 'DE');

    expect(await stored(), {'mow.good'});
    expect(result.complete, isFalse);
  });

  test('an incomplete source ends no stored warning', () async {
    await _storeRunning(db, 'mow.earlier');
    await WarningPollService(
      database: db,
      bbkClient: bbk(
        mowas: [
          entry('mow.good'),
          {'severity': 'Severe'},
        ],
      ),
      meteoAlarmClient: _Meteo(),
    ).poll(countryCode: 'DE');

    final earlier = (await db.warningsBySource('bbk'))['mow.earlier']!;
    expect(earlier.expires, isNull, reason: 'it may be the unreadable one');
  });

  test('a BBK client that throws still lets MeteoAlarm be asked', () async {
    final meteo = _Meteo();
    final result = await WarningPollService(
      database: db,
      bbkClient: _ThrowingBbk(),
      meteoAlarmClient: meteo,
    ).poll(countryCode: 'DE');

    expect(meteo.asked, isTrue);
    expect(result.complete, isFalse);
  });

  group('a district dashboard that does not answer (#371)', () {
    test('makes the poll incomplete and says BBK is not current', () async {
      final result = await WarningPollService(
        database: db,
        bbkClient: bbk(mowas: [entry('mow.good')], dashboardStatus: 503),
        meteoAlarmClient: _Meteo(),
      ).poll(countryCode: 'DE', kreisSchluessel: '03101');

      expect(result.complete, isFalse);
      final status = await const WarningPollStatusStore().load();
      expect(status.sourceComplete['bbk'], isNull);
      expect(status.lastComplete, isNull);
    });

    test('still ends nationwide warnings, and keeps its own', () async {
      await _storeRunning(db, 'mow.ended');
      await _storeRunning(db, 'mow.district', regionKey: '03101');

      await WarningPollService(
        database: db,
        bbkClient: bbk(mowas: [entry('mow.good')], dashboardStatus: 503),
        meteoAlarmClient: _Meteo(),
      ).poll(countryCode: 'DE', kreisSchluessel: '03101');

      final rows = await db.warningsBySource('bbk');
      expect(rows['mow.ended']!.expires, isNotNull);
      expect(rows['mow.district']!.expires, isNull);
    });
  });
}

/// MeteoAlarm answering "nothing new" and remembering it was asked.
class _Meteo extends MeteoAlarmClient {
  bool asked = false;

  @override
  Future<MeteoAlarmFeed> fetchCountry(
    String countrySlug, {
    String? knownStamp,
  }) async {
    asked = true;
    return const MeteoAlarmFeed(stamp: 'unchanged');
  }
}

class _ThrowingBbk extends BbkClient {
  @override
  Future<BbkFetchResult> fetchAll() async => throw StateError('broken');
}

Future<void> _storeRunning(
  AppDatabase db,
  String id, {
  String? regionKey,
}) => db.upsertWarnings([
  WarningsCompanion.insert(
    source: 'bbk',
    externalId: id,
    countryCode: 'DE',
    regionKey: Value(regionKey),
    severity: 'severe',
    eventType: 'Warnung',
    headline: 'Warnung',
    effective: DateTime.utc(2026, 11, 10),
    sent: DateTime.utc(2026, 11, 10),
    updatedAt: DateTime.utc(2026, 11, 10),
    notified: const Value(true),
  ),
]);
