import 'package:shared_preferences/shared_preferences.dart';

/// The last time this device could refresh official warning feeds.
class WarningPollStatusStore {
  const WarningPollStatusStore();

  static const _attemptKey = 'warningPollLastAttempt';
  static const _completeKey = 'warningPollLastComplete';
  static const _blockedKey = 'warningPollLastBlocked';

  Future<WarningPollStatus> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WarningPollStatus(
        lastAttempt: _parse(prefs.getString(_attemptKey)),
        lastComplete: _parse(prefs.getString(_completeKey)),
        lastBlocked: _parse(prefs.getString(_blockedKey)),
      );
    } on Object {
      return const WarningPollStatus();
    }
  }

  Future<void> record({required bool complete}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(_attemptKey, now);
      if (complete) await prefs.setString(_completeKey, now);
    } on Object {
      // A warning refresh must not be reported as failed merely because
      // its diagnostic timestamp cannot be saved.
    }
  }

  /// Notes that a scheduled poll could not run at all.
  ///
  /// Not the same as a poll that failed: this one never reached the feeds,
  /// because the local database could not be opened. It is the only trace
  /// such a run leaves, and the settings screen reads it back — a device
  /// that has quietly stopped warning must be able to say so.
  Future<void> recordBlocked() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _blockedKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    } on Object {
      // Same reasoning as above.
    }
  }

  DateTime? _parse(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toUtc();
}

class WarningPollStatus {
  const WarningPollStatus({
    this.lastAttempt,
    this.lastComplete,
    this.lastBlocked,
  });

  final DateTime? lastAttempt;
  final DateTime? lastComplete;
  final DateTime? lastBlocked;

  /// Whether the most recent thing that happened was a run that could not
  /// start. An older block that a later refresh has overtaken is history,
  /// not a state to alarm anybody about.
  bool get isBlocked {
    final blocked = lastBlocked;
    if (blocked == null) return false;
    final complete = lastComplete;
    return complete == null || blocked.isAfter(complete);
  }
}
