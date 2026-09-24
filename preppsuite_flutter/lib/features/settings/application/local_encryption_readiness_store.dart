import 'package:shared_preferences/shared_preferences.dart';

/// When this installation last read a backup back successfully.
///
/// The at-rest encryption upgrade rewrites every database file. The only
/// honest precondition for that is a backup somebody has watched this app
/// open — not a file on a disk, and not a promise in a dialog. This store
/// holds the result of that check, and nothing else: no passphrase, no
/// path, no contents.
class LocalEncryptionReadinessStore {
  const LocalEncryptionReadinessStore();

  static const _verifiedKey = 'localEncryptionBackupVerifiedAt';

  /// How long a successful check counts for.
  ///
  /// A backup tested last month says nothing about the household as it is
  /// today, and the upgrade is a one-off act — testing the backup right
  /// before it is the whole point of testing it at all.
  static const freshness = Duration(hours: 24);

  Future<DateTime?> lastVerified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_verifiedKey);
      return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
    } on Object {
      return null;
    }
  }

  Future<void> recordVerified() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _verifiedKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  static bool isFresh(DateTime? verifiedAt, {DateTime? now}) {
    if (verifiedAt == null) return false;
    final moment = now ?? DateTime.now().toUtc();
    return moment.difference(verifiedAt) < freshness;
  }
}
