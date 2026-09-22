/// Where this device keeps the times behind its settings.
///
/// One preference holding the last set that went out, each value with
/// the moment this device last saw it change. It is both halves of the
/// job at once: the comparison base for the next publish, and the
/// stamps that travel with it.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'carried_settings.dart';
import 'settings_sync.dart';

class SettingsSyncStore {
  const SettingsSyncStore();

  static const _key = 'carriedSettingStampsV1';

  Future<Map<String, StampedSetting>> load([
    SharedPreferences? preferences,
  ]) async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      return decodeStampedSettings(jsonDecode(raw));
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
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(encodeStampedSettings(settings)),
    );
  }
}

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
    return await _readSyncedSettings(preferences, store, now);
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
  final current = await readCarriedSettings(
    preferences: prefs,
    when: CarriedWhen.always,
  );
  final previous = await store.load(prefs);

  // Nothing written down yet: start everything level at the floor
  // rather than stamping it all with this moment. See the note in
  // `settings_sync.dart` -- two devices upgrading a minute apart must
  // not decide the later one is right about everything.
  final base = previous.isNotEmpty
      ? previous
      : {
          for (final entry in current.entries)
            entry.key: (value: entry.value, at: settingsEpoch),
        };

  final stamped = stampSettings(
    current: current,
    previous: base,
    now: (now ?? DateTime.now()).toUtc(),
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
}) async {
  if (incoming.isEmpty) return 0;
  try {
    return await _applySyncedSettings(incoming, preferences, store);
  } on Object {
    return 0;
  }
}

Future<int> _applySyncedSettings(
  Map<String, StampedSetting> incoming,
  SharedPreferences? preferences,
  SettingsSyncStore store,
) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();

  // Only what this device is willing to keep in step. An incoming key
  // that is setup-only here -- or unknown, because the other side is a
  // newer version -- is dropped rather than written.
  final offered = {
    for (final entry in incoming.entries)
      if (carriedSettings[entry.key]?.when == CarriedWhen.always)
        entry.key: entry.value,
  };
  if (offered.isEmpty) return 0;

  final current = await readCarriedSettings(
    preferences: prefs,
    when: CarriedWhen.always,
  );
  final local = await store.load(prefs);
  final merged = mergeSettings(local: local, incoming: offered);
  final changed = changedBy(current: current, merged: merged);

  if (changed.isNotEmpty) {
    await applyCarriedSettings(changed, prefs);
  }
  await store.save(merged, prefs);
  return changed.length;
}
