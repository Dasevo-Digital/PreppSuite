/// Keeping the household's settings in step, not just handing them over
/// once.
///
/// [CarriedHousehold] moved the settings at **setup** and never again: a
/// pegel station changed on the telephone was something the desktop
/// never heard about. The reason it stopped there was good — settings
/// had no timestamps, so a merge had no way to tell which side was
/// newer, and copying wholesale onto a device in use is a silent loss.
///
/// So they get timestamps. Two decisions make that cheap and safe:
///
/// **Stamped on publish, not on write.** Nothing intercepts
/// `prefs.setString`. Instead the values that go out are compared with
/// the ones that went out last time, and whatever differs is stamped
/// with that moment. No write site to remember, and therefore no write
/// site to forget — which is the class of bug this codebase keeps
/// finding. The cost is that a change made offline carries the time of
/// the next publish rather than of the change itself. For settling which
/// of two devices is ahead, that is the same answer.
///
/// **A floor, so nobody starts out shouting.** The first publish after
/// this arrives would otherwise stamp every value with "now", and two
/// devices doing that a minute apart would let the later one overwrite
/// the earlier for no reason. Unstamped values therefore start at
/// [settingsEpoch], the same trick `ChecklistSeeder.seededAt` uses: both
/// sides start equal, and the first real change is the first thing that
/// wins.
library;

/// A value, and when this device last saw it change.
typedef StampedSetting = ({Object value, DateTime at});

/// Where a value that has never been seen to change sits.
///
/// Fixed and in the past, on every device. See the library note.
final settingsEpoch = DateTime.utc(2024, 1, 1);

/// [current] with a time against each value.
///
/// A value equal to what went out last time keeps the stamp it had. A
/// value that differs, or that is new, is stamped [now]. A value that
/// has disappeared is dropped: a setting nobody holds any more is not a
/// setting to argue about.
Map<String, StampedSetting> stampSettings({
  required Map<String, Object> current,
  required Map<String, StampedSetting> previous,
  required DateTime now,
}) {
  return {
    for (final entry in current.entries)
      entry.key: switch (previous[entry.key]) {
        final held? when _same(held.value, entry.value) => held,
        _ => (value: entry.value, at: now),
      },
  };
}

/// What this device should hold after hearing [incoming].
///
/// Later wins; a tie stays where it is. A tie is the ordinary case —
/// both sides carrying the same value since the floor — and moving on a
/// tie would make the answer depend on who spoke last.
Map<String, StampedSetting> mergeSettings({
  required Map<String, StampedSetting> local,
  required Map<String, StampedSetting> incoming,
}) {
  final merged = {...local};
  for (final entry in incoming.entries) {
    final held = merged[entry.key];
    if (held == null || entry.value.at.isAfter(held.at)) {
      merged[entry.key] = entry.value;
    }
  }
  return merged;
}

/// Which of [merged] differ from what this device holds now.
///
/// Only these are written back, so a merge that changed nothing touches
/// nothing — and the screens watching those preferences do not rebuild
/// for an answer that was already theirs.
Map<String, Object> changedBy({
  required Map<String, Object> current,
  required Map<String, StampedSetting> merged,
}) {
  return {
    for (final entry in merged.entries)
      if (!_same(current[entry.key], entry.value.value))
        entry.key: entry.value.value,
  };
}

/// `{key: {"v": value, "at": "2026-09-22T…Z"}}`.
Map<String, Object?> encodeStampedSettings(
  Map<String, StampedSetting> settings,
) => {
  for (final entry in settings.entries)
    entry.key: {
      'v': entry.value.value,
      'at': entry.value.at.toUtc().toIso8601String(),
    },
};

/// Never throws and never half-reads: one unreadable entry costs that
/// entry. The far side may be a newer or an older version of the app,
/// and a sync must not fail over a setting.
Map<String, StampedSetting> decodeStampedSettings(Object? raw) {
  if (raw is! Map) return {};
  final out = <String, StampedSetting>{};
  for (final entry in raw.entries) {
    final key = entry.key;
    final body = entry.value;
    if (key is! String || body is! Map) continue;
    final value = body['v'];
    final at = DateTime.tryParse('${body['at']}');
    if (value is! Object || at == null) continue;
    out[key] = (value: value, at: at.toUtc());
  }
  return out;
}

/// Equality that sees through the two shapes JSON gives these values.
///
/// A string list comes back as a `List<dynamic>`, and an integer that
/// crossed as JSON may arrive as a double. Comparing with `==` would
/// call every one of those a change, restamp it, and start a ping-pong
/// between two devices that agree.
bool _same(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if ('${a[i]}' != '${b[i]}') return false;
    }
    return true;
  }
  if (a is num && b is num) return a == b;
  return a == b;
}
