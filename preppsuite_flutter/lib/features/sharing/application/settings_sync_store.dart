/// Where this device keeps the times behind its settings.
///
/// One preference holding the last set that went out, each value with
/// the moment this device last saw it change. It is both halves of the
/// job at once: the comparison base for the next publish, and the
/// stamps that travel with it.
library;

import 'dart:convert';
import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/private_preferences.dart';
import '../../../core/settings_arrival.dart';

import 'carried_settings.dart';
import 'settings_sync.dart';

class SettingsSyncStore {
  const SettingsSyncStore();

  static const _key = 'carriedSettingStampsV1';

  Future<Map<String, StampedSetting>> load([
    SharedPreferences? preferences,
  ]) async {
    final raw = await const PrivatePreferences().getString(
      _key,
      preferences: preferences,
    );
    if (raw == null) return {};
    try {
      return _shareable(decodeStampedSettings(jsonDecode(raw)));
    } on FormatException {
      // Unreadable is the same as absent: the next publish rebuilds it
      // from the floor, which costs one round of ties and nothing else.
      return {};
    }
  }

  Future<void> save(
    Map<String, StampedSetting> settings, [
    SharedPreferences? preferences,
  ]) async {
    // This baseline includes decrypted private values, not just stamps.
    // Keeping it beside their encrypted originals in clear would undo them.
    await const PrivatePreferences().setString(
      _key,
      jsonEncode(encodeStampedSettings(_shareable(settings))),
      preferences: preferences,
    );
  }
}

Map<String, StampedSetting> _shareable(Map<String, StampedSetting> values) => {
  for (final entry in values.entries)
    if (carriedSettings[entry.key]?.when == CarriedWhen.always &&
        (entry.value.value == null ||
            validCarriedSettingValue(entry.key, entry.value.value)))
      entry.key: (
        value: normalizedCarriedSettingValue(entry.key, entry.value.value),
        at: entry.value.at,
      ),
};

Future<void>? _pending;

// Publish and receive share one order, including separate service instances.
Future<T> _serialized<T>(Future<T> Function() action) {
  final previous = _pending;
  final result = previous == null
      ? Future<T>.sync(action)
      : previous.then((_) => action());
  final queued = result.then<void>(
    (_) {},
    onError: (Object _, StackTrace _) {},
  );
  _pending = queued;
  return result.whenComplete(() {
    // Do not retain an idle operation's zone or callbacks forever.
    if (identical(_pending, queued)) _pending = null;
  });
}

typedef _SettingsRead = ({
  Map<String, Object> values,
  Map<String, Object?> stored,
});

Map<String, Object?> _stored(SharedPreferences prefs) => {
  for (final entry in carriedSettings.entries)
    if (entry.value.when == CarriedWhen.always)
      entry.key: switch (prefs.get(entry.key)) {
        final List value => [...value],
        final value => value,
      },
};

Future<_SettingsRead> _current(SharedPreferences prefs) async {
  // A private read can migrate a value. Retry that benign change too;
  // never pair an old plaintext value with a newer raw comparison token.
  for (var attempt = 0; attempt < 3; attempt++) {
    final before = _stored(prefs);
    final values = await readCarriedSettings(
      preferences: prefs,
      when: CarriedWhen.always,
    );
    final after = _stored(prefs);
    if (before.keys.every((key) => _sameStored(before[key], after[key]))) {
      return (values: values, stored: after);
    }
  }
  throw StateError('Settings changed during read');
}

bool _sameStored(Object? a, Object? b) {
  if (a is List && b is List) {
    return a.length == b.length &&
        List.generate(
          a.length,
          (i) => _sameStored(a[i], b[i]),
        ).every((same) => same);
  }
  if (a is double && b is double && a.isNaN && b.isNaN) return true;
  return a == b;
}

Map<String, StampedSetting> _localSettings(
  Map<String, Object> current,
  Map<String, StampedSetting> previous,
  DateTime now,
) => stampSettings(
  current: current,
  previous: previous.isNotEmpty
      ? previous
      : {
          for (final entry in current.entries)
            entry.key: (value: entry.value, at: settingsEpoch),
        },
  now: now.toUtc(),
);

/// The household's settings, stamped and ready to travel.
///
/// Only the ones marked [CarriedWhen.always]: the rest are how *this*
/// device is set up and go over once, at setup, through
/// [CarriedHousehold].
///
/// Writes the new stamps back before returning them, so the next publish
/// compares against what actually went out.
Future<Map<String, StampedSetting>> readSyncedSettings({
  SharedPreferences? preferences,
  SettingsSyncStore store = const SettingsSyncStore(),
  DateTime? now,
}) async {
  try {
    return await _serialized(
      () => _readSyncedSettings(preferences, store, now),
    );
  } on Object {
    // A preferences store that cannot be reached is not a reason to
    // fail a household sync. The rows are the payload; the settings
    // ride along, and riding along is all they do. Same rule as
    // `applyCarriedSettings`: a handover must not fail over a setting.
    return const {};
  }
}

Future<Map<String, StampedSetting>> _readSyncedSettings(
  SharedPreferences? preferences,
  SettingsSyncStore store,
  DateTime? now,
) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final previous = await store.load(prefs);
  final current = await _current(prefs);
  final stamped = _localSettings(
    current.values,
    previous,
    now ?? DateTime.now(),
  );
  await store.save(stamped, prefs);
  return stamped;
}

/// Takes what another device sent and answers how many settings changed
/// here because of it.
///
/// Nothing is written that did not move — a merge that agreed with this
/// device touches no preference, and the screens watching them do not
/// rebuild for an answer that was already theirs.
Future<int> applySyncedSettings(
  Map<String, StampedSetting> incoming, {
  SharedPreferences? preferences,
  SettingsSyncStore store = const SettingsSyncStore(),
  DateTime? now,
}) async {
  if (incoming.isEmpty) return 0;
  try {
    return await _serialized(
      () => _applySyncedSettings(incoming, preferences, store, now),
    );
  } on Object {
    return 0;
  }
}

Future<int> _applySyncedSettings(
  Map<String, StampedSetting> incoming,
  SharedPreferences? preferences,
  SettingsSyncStore store,
  DateTime? now,
) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();

  // Only what this device is willing to keep in step. An incoming key
  // that is setup-only here -- or unknown, because the other side is a
  // newer version -- is dropped rather than written.
  final offered = _shareable(incoming);
  if (offered.isEmpty) return 0;

  final previous = await store.load(prefs);
  final current = await _current(prefs);
  final local = _localSettings(current.values, previous, now ?? DateTime.now());
  final merged = mergeSettings(local: local, incoming: offered);
  final changed = changedBy(current: current.values, merged: merged);

  var applied = 0;
  for (final entry in changed.entries) {
    if (await applySyncedSettingIfUnchanged(
      entry.key,
      entry.value,
      expectedStored: current.stored[entry.key],
      preferences: prefs,
    )) {
      applied++;
    } else {
      // A newer local edit or a failed write is not an acknowledged
      // remote value. The next publish must still see that local change.
      if (local[entry.key] case final held?) {
        merged[entry.key] = held;
      } else {
        merged.remove(entry.key);
      }
    }
  }
  await store.save(merged, prefs);
  if (applied > 0) announceSettingsArrival();
  return applied;
}
