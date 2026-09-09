import 'package:shared_preferences/shared_preferences.dart';

/// The last time this device could refresh official warning feeds.
class WarningPollStatusStore {
  const WarningPollStatusStore();

  static const _attemptKey = 'warningPollLastAttempt';
  static const _completeKey = 'warningPollLastComplete';

  Future<WarningPollStatus> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WarningPollStatus(
        lastAttempt: _parse(prefs.getString(_attemptKey)),
        lastComplete: _parse(prefs.getString(_completeKey)),
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

  DateTime? _parse(String? value) =>
      value == null ? null : DateTime.tryParse(value)?.toUtc();
}

class WarningPollStatus {
  const WarningPollStatus({this.lastAttempt, this.lastComplete});

  final DateTime? lastAttempt;
  final DateTime? lastComplete;
}
