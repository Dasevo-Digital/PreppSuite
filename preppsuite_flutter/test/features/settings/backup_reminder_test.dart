import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_reminder.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// How recent this device's last backup is, and when to ask again (#122).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final now = DateTime(2026, 10, 7, 15);

  test('no backup yet is due now and not current', () {
    const status = BackupStatus(lastBackup: null, everyDays: 30);
    expect(status.isCurrent(now: now), isFalse);
    expect(status.dueAt(now: now), now);
    expect(status.daysSince(now: now), isNull);
  });

  test('the next one is due the interval after the last, at ten', () {
    final status = BackupStatus(
      lastBackup: DateTime(2026, 9, 20, 22, 30),
      everyDays: 30,
    );
    expect(status.daysSince(now: now), 17);
    expect(status.isCurrent(now: now), isTrue);
    expect(status.dueAt(now: now), DateTime(2026, 10, 20, 10));
  });

  test('turning the reminder off does not make an old backup current', () {
    final status = BackupStatus(
      lastBackup: DateTime(2026, 7, 1),
      everyDays: 0,
    );
    expect(status.dueAt(now: now), isNull);
    expect(status.isCurrent(now: now), isFalse);
  });

  test('a backup that has left the app is remembered', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(backupStatusProvider);
    await container
        .read(backupStatusProvider.notifier)
        .markBackedUp(at: DateTime.utc(2026, 10, 7, 9));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lastBackupAt'), '2026-10-07T09:00:00.000Z');
  });

  test('only offered intervals are taken', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(backupReminderDaysProvider.notifier).setDays(17);
    expect(container.read(backupReminderDaysProvider), 30);
    await container.read(backupReminderDaysProvider.notifier).setDays(90);
    expect(container.read(backupReminderDaysProvider), 90);
  });
}
