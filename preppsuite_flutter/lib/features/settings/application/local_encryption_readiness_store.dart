import 'package:shared_preferences/shared_preferences.dart';

/// How recent the last backup is that this installation read back.
///
/// The at-rest encryption upgrade rewrites every database file. The only
/// honest precondition for that is a backup somebody has watched this app
/// open — not a file on a disk, and not a promise in a dialog. This store
/// holds the result of that check, and nothing else: no passphrase, no
/// path, no contents.
///
/// What it keeps is when that backup was *written*, not when it was read
/// (#406). Until 3.0.3 it kept the moment of the check, and a backup a
/// year old, read back today, cleared the upgrade for the next day as if
/// it held the household as it is.
class LocalEncryptionReadinessStore {
  const LocalEncryptionReadinessStore();

  static const _writtenKey = 'localEncryptionBackupWrittenAt.v1';

  /// Held the moment of the check until 3.0.3. No longer read: it says
  /// nothing about the age of the backup.
  static const _legacyVerifiedKey = 'localEncryptionBackupVerifiedAt';

  /// How old a backup may be and still count.
  ///
  /// A backup from last month says nothing about the household as it is
  /// today, and the upgrade is a one-off act — a backup written and read
  /// back right before it is the whole point of testing it at all.
  static const freshness = Duration(hours: 24);

  /// When the last backup read back here was written, or null.
  Future<DateTime?> lastVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_writtenKey);
      return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
    } on Object {
      return null;
    }
  }

  /// Notes that a backup written at [writtenAt] was read back. A time
  /// after now -- a clock that ran ahead where it was written -- counts
  /// as now.
  Future<void> recordVerified({required DateTime writtenAt}) async {
    final now = DateTime.now().toUtc();
    final written = writtenAt.toUtc();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _writtenKey,
      (written.isAfter(now) ? now : written).toIso8601String(),
    );
    await prefs.remove(_legacyVerifiedKey);
  }

  /// Notes the backup when it is recent enough, and says whether it was.
  ///
  /// An older one is not noted at all: it would not clear the upgrade, and
  /// noting it would put a check that counts out of sight.
  Future<bool> recordIfRecent(DateTime writtenAt) async {
    if (!isFresh(writtenAt.toUtc())) return false;
    await recordVerified(writtenAt: writtenAt);
    return true;
  }

  /// Whether a backup written at [writtenAt] is recent enough.
  static bool isFresh(DateTime? writtenAt, {DateTime? now}) {
    if (writtenAt == null) return false;
    final moment = now ?? DateTime.now().toUtc();
    return moment.difference(writtenAt) < freshness;
  }
}
