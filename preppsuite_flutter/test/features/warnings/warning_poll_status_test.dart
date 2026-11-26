import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_poll_status_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Which feed decides "current", and what counts as one feed lagging (#92).
void main() {
  final attempt = DateTime.utc(2026, 10, 3, 8);
  final older = DateTime.utc(2026, 9, 20, 8);

  test('Germany is current when the BBK is', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      lastComplete: older,
      sourceComplete: {'bbk': attempt, 'meteoalarm': older},
    );

    expect(status.currentAt('DE'), attempt);
    expect(status.lagging('DE'), ['meteoalarm']);
  });

  test('elsewhere MeteoAlarm is the feed, and the BBK is never missed', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      sourceComplete: {'meteoalarm': attempt},
    );

    expect(status.currentAt('AT'), attempt);
    expect(status.lagging('AT'), isEmpty);
  });

  test('before the first per-feed poll the old total is used', () {
    final status = WarningPollStatus(lastAttempt: attempt, lastComplete: older);

    expect(status.currentAt('DE'), older);
    expect(status.lagging('DE'), isEmpty);
  });

  test('a block is overtaken by a BBK refresh, MeteoAlarm or not', () {
    final status = WarningPollStatus(
      lastAttempt: attempt,
      lastComplete: older,
      lastBlocked: DateTime.utc(2026, 10, 1),
      sourceComplete: {'bbk': attempt},
    );

    expect(status.isBlocked, isFalse);
  });

  group('what the background run wrote (#396)', () {
    /// Writes past this isolate's copy of the preferences, the way the
    /// background run's isolate does.
    Future<void> writtenElsewhere(String key, Object value) =>
        SharedPreferencesStorePlatform.instance.setValue(
          value is String ? 'String' : 'StringList',
          'flutter.$key',
          value,
        );

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('reaches the open app', () async {
      const store = WarningPollStatusStore();
      // The open app has read the store once already.
      expect((await store.load()).lastAttempt, isNull);
      final morning = DateTime.utc(2026, 11, 26, 6);

      await writtenElsewhere(
        'warningPollLastAttempt',
        morning.toIso8601String(),
      );
      await writtenElsewhere(
        'warningPollLastComplete.bbk',
        morning.toIso8601String(),
      );

      final status = await store.load();
      expect(status.lastAttempt, morning);
      expect(status.currentAt('DE'), morning);
    });

    test('a feed stamp it saved is used', () async {
      const store = WarningPollStatusStore();
      expect(await store.feedStamp('germany'), isNull);

      await writtenElsewhere('warningFeedStamp.germany', [
        DateTime.now().toUtc().toIso8601String(),
        'stamp',
      ]);

      expect(await store.feedStamp('germany'), 'stamp');
    });
  });
}
