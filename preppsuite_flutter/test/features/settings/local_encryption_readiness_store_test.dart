import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/application/local_encryption_readiness_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What clears the at-rest encryption upgrade: a backup read back here
/// that holds the household as it is now (#406).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const store = LocalEncryptionReadinessStore();

  test(
    'a backup a year old does not count, however recently it was read',
    () async {
      final written = DateTime.now().toUtc().subtract(
        const Duration(days: 365),
      );

      expect(await store.recordIfRecent(written), isFalse);

      expect(await store.lastVerified(), isNull);
      expect(
        LocalEncryptionReadinessStore.isFresh(await store.lastVerified()),
        isFalse,
      );
    },
  );

  test('a recent one counts for a day from when it was written', () async {
    final now = DateTime.now().toUtc();
    final written = now.subtract(const Duration(hours: 23));

    expect(await store.recordIfRecent(written), isTrue);

    final kept = await store.lastVerified();
    expect(kept, written);
    expect(LocalEncryptionReadinessStore.isFresh(kept, now: now), isTrue);
    expect(
      LocalEncryptionReadinessStore.isFresh(
        kept,
        now: now.add(const Duration(hours: 2)),
      ),
      isFalse,
      reason: 'a day after the backup, not a day after the check',
    );
  });

  test('a backup from a clock that ran ahead counts from now', () async {
    final before = DateTime.now().toUtc();
    await store.recordVerified(
      writtenAt: before.add(const Duration(days: 3)),
    );

    final kept = (await store.lastVerified())!;
    expect(kept.isAfter(before.add(const Duration(minutes: 1))), isFalse);
  });

  test('a check stored before this counted only when it was made', () async {
    // It said when somebody read a backup, not how old that backup was.
    SharedPreferences.setMockInitialValues({
      'localEncryptionBackupVerifiedAt': DateTime.now()
          .toUtc()
          .toIso8601String(),
    });

    expect(await store.lastVerified(), isNull);
  });
}
