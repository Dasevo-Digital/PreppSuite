import 'package:shared_preferences/shared_preferences.dart';

/// The last time this device could refresh official warning feeds.
class WarningPollStatusStore {
  const WarningPollStatusStore();

  static const _attemptKey = 'warningPollLastAttempt';
  static const _completeKey = 'warningPollLastComplete';
  static const _blockedKey = 'warningPollLastBlocked';

  /// One key per feed, suffixed with its name (`bbk`, `meteoalarm`).
  ///
  /// The single "last complete" above could not tell a dead BBK from a
  /// dead MeteoAlarm. A German household whose BBK refresh was current
  /// was shown an ever older warning state the whole time MeteoAlarm was
  /// down (#92), which is the symptom #46 was about in the first place.
  static const _sourcePrefix = 'warningPollLastComplete.';
  static const sources = ['bbk', 'meteoalarm'];

  Future<WarningPollStatus> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WarningPollStatus(
        lastAttempt: _parse(prefs.getString(_attemptKey)),
        lastComplete: _parse(prefs.getString(_completeKey)),
        lastBlocked: _parse(prefs.getString(_blockedKey)),
        sourceComplete: {
          for (final source in sources)
            source: ?_parse(prefs.getString('$_sourcePrefix$source')),
        },
      );
    } on Object {
      return const WarningPollStatus();
    }
  }

  /// [sourcesOk] names each feed this run asked and whether it answered
  /// in full. All of them share one timestamp with the attempt, which is
  /// how [WarningPollStatus.lagging] can tell that a feed failed in the
  /// latest run rather than in some older one.
  Future<void> record({
    required bool complete,
    Map<String, bool> sourcesOk = const {},
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().toUtc().toIso8601String();
      await prefs.setString(_attemptKey, now);
      if (complete) await prefs.setString(_completeKey, now);
      for (final MapEntry(key: source, value: ok) in sourcesOk.entries) {
        if (ok) await prefs.setString('$_sourcePrefix$source', now);
      }
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
    this.sourceComplete = const {},
  });

  final DateTime? lastAttempt;

  /// When every feed last answered in one run.
  final DateTime? lastComplete;
  final DateTime? lastBlocked;

  /// When each feed last answered in full, by name. Empty on a device that
  /// has not polled since this was added.
  final Map<String, DateTime> sourceComplete;

  /// The feed whose freshness decides whether this household's warnings
  /// are current: the BBK in Germany, MeteoAlarm everywhere else.
  static String primarySource(String countryCode) =>
      countryCode == 'DE' ? 'bbk' : 'meteoalarm';

  /// When the warnings that matter to [countryCode] were last current.
  ///
  /// A German household is current when the BBK is. MeteoAlarm adds the
  /// European weather warnings on top, and its outage is shown on its own
  /// ([lagging]) rather than making the official German state look stale.
  /// Falls back to [lastComplete] until the device has polled once with
  /// per-feed bookkeeping.
  DateTime? currentAt(String countryCode) =>
      sourceComplete[primarySource(countryCode)] ?? lastComplete;

  /// The feeds besides the primary one that did not answer in the latest
  /// run. They were all stamped with the attempt's own timestamp, so a
  /// feed whose time differs from it failed in that run.
  List<String> lagging(String countryCode) {
    final attempt = lastAttempt;
    if (attempt == null || sourceComplete.isEmpty) return const [];
    final primary = primarySource(countryCode);
    return [
      for (final source in WarningPollStatusStore.sources)
        if (source != primary &&
            (countryCode == 'DE' || source != 'bbk') &&
            sourceComplete[source] != attempt)
          source,
    ];
  }

  /// Whether the most recent thing that happened was a run that could not
  /// start. An older block that a later refresh has overtaken is history,
  /// not a state to alarm anybody about.
  bool get isBlocked {
    final blocked = lastBlocked;
    if (blocked == null) return false;
    // The newest sign of life from any feed: a run that brought the BBK
    // back after a block has overtaken it, MeteoAlarm or not.
    final times = [?lastComplete, ...sourceComplete.values];
    if (times.isEmpty) return true;
    final latest = times.reduce((a, b) => a.isAfter(b) ? a : b);
    return blocked.isAfter(latest);
  }
}
