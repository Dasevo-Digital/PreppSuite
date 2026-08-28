import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/sync/sync_status.dart';

void main() {
  final now = DateTime(2026, 8, 28, 12);

  group('isSyncStale', () {
    test('stays quiet when nothing has failed', () {
      expect(
        isSyncStale(SyncStatus(lastSuccessAt: now), now),
        isFalse,
      );
    });

    test('stays quiet on a single failure between good passes', () {
      // Being offline is the normal case for this app. One dropped request
      // right after a success is not worth interrupting anyone for.
      final status = SyncStatus(
        lastSuccessAt: now.subtract(const Duration(minutes: 2)),
        lastFailureAt: now,
      );

      expect(isSyncStale(status, now), isFalse);
    });

    test('warns when a sync failed and none ever succeeded', () {
      // A fresh install pointing at the wrong address: nothing this device
      // holds has ever left it, and nothing ever will until it is fixed.
      expect(
        isSyncStale(SyncStatus(lastFailureAt: now), now),
        isTrue,
      );
    });

    test('warns once the last success is older than the window', () {
      final status = SyncStatus(
        lastSuccessAt: now.subtract(const Duration(minutes: 31)),
        lastFailureAt: now,
      );

      expect(isSyncStale(status, now), isTrue);
    });

    test('the window is exclusive at its edge', () {
      final atEdge = SyncStatus(
        lastSuccessAt: now.subtract(syncStaleAfter),
        lastFailureAt: now,
      );

      expect(isSyncStale(atEdge, now), isFalse);
    });

    test('the window can be overridden', () {
      final status = SyncStatus(
        lastSuccessAt: now.subtract(const Duration(minutes: 5)),
        lastFailureAt: now,
      );

      expect(
        isSyncStale(status, now, staleAfter: const Duration(minutes: 1)),
        isTrue,
      );
    });

    test('an untouched status says nothing', () {
      expect(isSyncStale(const SyncStatus(), now), isFalse);
    });
  });

  group('syncAge', () {
    test('reports whole minutes below an hour', () {
      expect(
        syncAge(const Duration(minutes: 42)),
        const SyncAge(42, SyncAgeUnit.minutes),
      );
    });

    test('reports whole hours below a day', () {
      expect(
        syncAge(const Duration(hours: 5, minutes: 30)),
        const SyncAge(5, SyncAgeUnit.hours),
      );
    });

    test('reports whole days beyond that', () {
      expect(
        syncAge(const Duration(days: 3, hours: 4)),
        const SyncAge(3, SyncAgeUnit.days),
      );
    });

    test('never reports zero, which would read like a bug', () {
      expect(
        syncAge(const Duration(seconds: 20)),
        const SyncAge(1, SyncAgeUnit.minutes),
      );
      expect(syncAge(Duration.zero), const SyncAge(1, SyncAgeUnit.minutes));
    });
  });

  group('SyncStatusController', () {
    test('a success clears an earlier failure', () {
      // Whatever went wrong before, a good pass means the household is in
      // step again — the banner has to disappear on its own.
      var status = const SyncStatus().copyWith(lastFailureAt: now);
      expect(status.hasFailed, isTrue);

      status = SyncStatus(lastSuccessAt: now.add(const Duration(minutes: 1)));
      expect(status.hasFailed, isFalse);
      expect(isSyncStale(status, now.add(const Duration(minutes: 1))), isFalse);
    });
  });
}
