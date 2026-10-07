import 'dart:async' show unawaited;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// When this device last wrote a backup, and when it should again (#122).
///
/// Since format 3 a backup is the only way the photos, the household's own
/// documents and the downloaded archives outlive a lost or broken device --
/// none of them travel through the shared folder. A backup that is a year
/// old has a year of photos missing, and nothing said so.
///
/// Kept per device and deliberately not carried: what a backup holds is
/// this device's files, and another device having made one says nothing
/// about these.
const _daysKey = 'backupReminderDays';
const _lastKey = 'lastBackupAt';

/// The choices offered, in days; 0 is "never remind".
const selectableBackupReminderDays = [0, 14, 30, 60, 90];
const defaultBackupReminderDays = 30;

class BackupReminderDaysController extends Notifier<int> {
  @override
  int build() {
    unawaited(_load());
    return defaultBackupReminderDays;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getInt(_daysKey);
    if (!ref.mounted || stored == null) return;
    state = selectableBackupReminderDays.contains(stored)
        ? stored
        : defaultBackupReminderDays;
  }

  Future<void> setDays(int days) async {
    if (!selectableBackupReminderDays.contains(days)) return;
    state = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_daysKey, days);
  }
}

final backupReminderDaysProvider =
    NotifierProvider<BackupReminderDaysController, int>(
      BackupReminderDaysController.new,
    );

/// The last backup and the interval, and what follows from them.
class BackupStatus {
  const BackupStatus({required this.lastBackup, required this.everyDays});

  final DateTime? lastBackup;
  final int everyDays;

  bool get isOff => everyDays == 0;

  /// Whole calendar days since the last backup, or null when there was none.
  int? daysSince({DateTime? now}) {
    final last = lastBackup;
    if (last == null) return null;
    return _midnight(
      now ?? DateTime.now(),
    ).difference(_midnight(last.toLocal())).inDays;
  }

  /// When the next backup is due: the interval after the last one, or --
  /// with none made yet -- now.
  DateTime? dueAt({DateTime? now}) {
    if (isOff) return null;
    final last = lastBackup?.toLocal();
    if (last == null) return now ?? DateTime.now();
    return DateTime(last.year, last.month, last.day + everyDays, 10);
  }

  /// Whether a backup is due. With the reminder off, a backup older than
  /// the default interval still counts as not current for the readiness
  /// overview -- turning the reminder off does not make an old backup new.
  bool isCurrent({DateTime? now}) {
    final days = daysSince(now: now);
    if (days == null) return false;
    return days < (isOff ? defaultBackupReminderDays : everyDays);
  }

  static DateTime _midnight(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}

class BackupStatusController extends Notifier<BackupStatus> {
  DateTime? _last;
  var _marked = false;

  @override
  BackupStatus build() {
    final days = ref.watch(backupReminderDaysProvider);
    unawaited(_load());
    return BackupStatus(lastBackup: _last, everyDays: days);
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_lastKey);
    // A backup recorded while this was still reading is newer than
    // anything it could find, and must not be overwritten by it.
    if (!ref.mounted || _marked) return;
    _last = stored == null ? null : DateTime.tryParse(stored);
    state = BackupStatus(lastBackup: _last, everyDays: state.everyDays);
  }

  /// Called once a backup has left the app: saved, or handed to the share
  /// sheet. Not for one that was cancelled half way.
  Future<void> markBackedUp({DateTime? at}) async {
    final moment = (at ?? DateTime.now()).toUtc();
    _marked = true;
    _last = moment;
    state = BackupStatus(lastBackup: moment, everyDays: state.everyDays);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastKey, moment.toIso8601String());
  }
}

final backupStatusProvider =
    NotifierProvider<BackupStatusController, BackupStatus>(
      BackupStatusController.new,
    );
