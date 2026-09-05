import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/notification_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_background_worker.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_service.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_store.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A poll service that writes a fixed warning instead of going to the
/// network, so the worker's own behaviour is what is under test.
class _StubPollService extends WarningPollService {
  _StubPollService(this._db) : super(database: _db);

  final AppDatabase _db;
  int polls = 0;

  @override
  Future<WarningPollResult> poll({
    required String countryCode,
    String? kreisSchluessel,
  }) async {
    polls++;
    await _db.upsertWarning(
      WarningsCompanion.insert(
        source: 'bbk',
        externalId: 'severe-1',
        countryCode: countryCode,
        regionKey: const Value('05334'),
        severity: 'severe',
        eventType: 'Hochwasser',
        headline: 'Hochwasserwarnung',
        effective: DateTime.utc(2026),
        sent: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    );
    return const WarningPollResult(
      fetched: 1,
      newsworthy: [],
      retired: 0,
      complete: true,
    );
  }
}

/// Records what would have been shown, so the worker can be exercised
/// without a platform channel.
class _RecordingNotifications implements NotificationService {
  final shown = <Warning>[];

  @override
  Future<void> showLocalWarning(Warning warning) async => shown.add(warning);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());

  test('does nothing when no region has ever been stored', () async {
    // A fresh install that has not reached the household screen yet.
    // Polling anyway would mean traffic against a public API for warnings
    // nobody asked for.
    final notifications = _RecordingNotifications();

    final ok = await runWarningBackgroundPoll(
      database: db,
      notifications: notifications,
    );

    expect(ok, isTrue);
    expect(notifications.shown, isEmpty);
    expect(await db.watchAllWarnings().first, isEmpty);
  });

  test('does nothing when notifications are switched off', () async {
    // The switch has to bind the background worker too — it cannot read
    // the Riverpod provider, so it reads the same preference directly.
    // Order matters: setMockInitialValues replaces the whole backing map,
    // so setting it after saving would wipe the region and make this pass
    // for the wrong reason.
    SharedPreferences.setMockInitialValues({'notificationsEnabled': false});
    await const WarningRegionStore().save(
      const WarningRegionFilter(countryCode: 'DE'),
    );
    expect(await const WarningRegionStore().load(), isNotNull);

    final notifications = _RecordingNotifications();

    await runWarningBackgroundPoll(
      database: db,
      notifications: notifications,
    );

    expect(notifications.shown, isEmpty);
    expect(
      await db.watchAllWarnings().first,
      isEmpty,
      reason: 'it must not even poll',
    );
  });

  test('polls and announces a relevant warning', () async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    await const WarningRegionStore().save(
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '053340000000',
      ),
    );
    final notifications = _RecordingNotifications();
    final poller = _StubPollService(db);

    final ok = await runWarningBackgroundPoll(
      database: db,
      notifications: notifications,
      pollService: poller,
    );

    expect(ok, isTrue);
    expect(poller.polls, 1);
    expect(notifications.shown.map((w) => w.externalId), ['severe-1']);
  });

  test('a second run does not announce the same warning again', () async {
    // The flag survives the isolate ending, which is the whole point:
    // every background run starts from nothing but the database.
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    await const WarningRegionStore().save(
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '053340000000',
      ),
    );

    await runWarningBackgroundPoll(
      database: db,
      notifications: _RecordingNotifications(),
      pollService: _StubPollService(db),
    );
    final second = _RecordingNotifications();
    await runWarningBackgroundPoll(
      database: db,
      notifications: second,
      pollService: _StubPollService(db),
    );

    expect(second.shown, isEmpty);
  });

  test('a warning for another region is fetched but not announced', () async {
    SharedPreferences.setMockInitialValues({'notificationsEnabled': true});
    await const WarningRegionStore().save(
      // Munich, while the stub warning is for Aachen.
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '091620000000',
      ),
    );
    final notifications = _RecordingNotifications();

    await runWarningBackgroundPoll(
      database: db,
      notifications: notifications,
      pollService: _StubPollService(db),
    );

    expect(await db.watchAllWarnings().first, hasLength(1));
    expect(notifications.shown, isEmpty);
  });
}
