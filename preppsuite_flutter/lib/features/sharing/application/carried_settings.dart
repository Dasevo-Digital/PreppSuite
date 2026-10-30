/// The settings that belong to the household rather than to the device.
///
/// Joining a household used to move the rows and nothing else, so a second
/// device arrived knowing what was in the cellar but not which region it
/// watches, which river gauge it reads, what the energy plan is, or how
/// long the freezer has been off. All of that is the household's, and
/// re-entering it by hand on every device is exactly the kind of work the
/// join was supposed to save.
///
/// **An allow-list and not a copy of everything**, because four kinds of
/// setting must not travel:
///
///  * **Identity.** `syncDeviceId` is what tells two devices apart. Copied
///    over, the household would have two devices claiming to be one.
///  * **Local paths.** The shared folder, the offline map archive, the
///    knowledge archives and the personal documents are files on *this*
///    machine. A path from the other device resolves to nothing here, and
///    a setting pointing at nothing is worse than an empty one.
///  * **Secrets.** The MapTiler key lives in the platform's credential
///    store on purpose. Carrying it would land it in the preferences file,
///    which on the desktops is plain JSON — that is a downgrade, not a
///    convenience, so the key is entered again on the new device.
///  * **Whereabouts.** The personal places of the map, the meeting points
///    among them, stay on the device they were set on (#204). They are on
///    the list only so that this device's own backup brings them back; see
///    [CarriedWhen.deviceOnly].
///
/// Caches — the last reading from each station, when the warning feed was
/// last polled — are left out for a duller reason: they are refetched in
/// seconds and carrying them would only make the handover bigger.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/private_preferences.dart';
import '../../../model/household_profile.dart';
import '../../../model/household_profile_store.dart';
import '../../inventory/application/expiry_reminder_provider.dart';
import '../../inventory/application/charge_reminder_provider.dart';

/// What kind of value a setting holds.
///
/// Spelled out rather than read off the incoming JSON. JSON has one number
/// type and `shared_preferences` has two, so a latitude that happens to be
/// a whole number would arrive as an int and be stored where `getDouble`
/// cannot read it — a setting that works everywhere except at 52° exactly.
enum CarriedKind { boolean, integer, decimal, text, textList }

/// Whether a setting keeps travelling, or only goes over once.
///
/// The split exists because "the household's settings" and "how this
/// device is set up" are two different things that sat in one list.
/// Which river gauge the household watches is the household's, and a
/// change to it should reach every device. Whether *this* screen is
/// dark, whether *this* device sends notifications, and whether *this*
/// one draws from an archive it may not even have are not — syncing
/// those would mean changing the theme on the desktop because somebody
/// turned the telephone dark on the train.
enum CarriedWhen {
  /// Carried at setup and kept in step afterwards.
  always,

  /// Carried once, when a device is being set up from another, and left
  /// alone after that.
  setupOnly,

  /// Never handed to another device, by any road. Kept in this device's
  /// own backup, which is a copy of this device and nobody else's, so a
  /// restore brings it back.
  deviceOnly,
}

/// What a carried setting is: the shape of its value, and whether it
/// keeps travelling.
typedef CarriedSetting = ({CarriedKind kind, CarriedWhen when});

const _always = CarriedWhen.always;
const _setupOnly = CarriedWhen.setupOnly;
const _deviceOnly = CarriedWhen.deviceOnly;

/// Carried settings that are kept encrypted on the device.
///
/// They are read and written through [PrivatePreferences] here too, so
/// what travels is the value and not this device's envelope — the far
/// side has a different key and could make nothing of it. The journey
/// itself is already encrypted, whichever road it takes.
const _privateSettings = {
  'preparednessHubV1',
  'personalMapPlaces.v1',
  'checkInContacts.v1',
  'heavyRainHazard.v1',
};

/// Every setting that travels with a household, and what it holds.
/// Deliberately absent: `warningCountryCode`, `warningRegionKey` and
/// `warningExtraRegions`. Those three are not settings but a *copy* of the
/// household profile, kept where the background worker can read it without
/// Riverpod (see [WarningRegionStore]). Carrying them would be carrying the
/// shadow instead of the thing — and the profile, which travels as
/// [CarriedHousehold.profile], rewrites them the moment it lands.
const carriedSettings = <String, CarriedSetting>{
  'watchedAutobahnen': (kind: CarriedKind.textList, when: _always),

  // The measuring stations it reads. Each is a place, and the household
  // is in one place.
  'pegelStation': (kind: CarriedKind.text, when: _always),
  'radiationStation': (kind: CarriedKind.text, when: _always),
  'airQualityStation': (kind: CarriedKind.text, when: _always),
  'fireDangerStation': (kind: CarriedKind.text, when: _always),

  // Where the sun rises here.
  'daylightLatitude': (kind: CarriedKind.decimal, when: _always),
  'daylightLongitude': (kind: CarriedKind.decimal, when: _always),
  'daylightPlaceName': (kind: CarriedKind.text, when: _always),

  // The energy plan: what the household draws and what it has put by.
  // Hand-entered, appliance by appliance, and the single most tedious
  // thing to type twice.
  'energyDraws': (kind: CarriedKind.textList, when: _always),
  'energyReserves': (kind: CarriedKind.textList, when: _always),

  // A blackout that is running is running for the whole household — the
  // fridge does not care which device is looking at the clock.
  'outageStartedAt': (kind: CarriedKind.text, when: _always),
  'outageFreezerFull': (kind: CarriedKind.boolean, when: _always),

  // What has been practised, and when.
  'drillProgress': (kind: CarriedKind.textList, when: _always),
  'drillLastCompleted': (kind: CarriedKind.text, when: _always),

  // Private routes, document locations and notes belong in this device's
  // backup, never in an automatic copy to the other household devices.
  'preparednessHubV1': (kind: CarriedKind.text, when: _deviceOnly),

  // The meeting point, the way out, the well. Where somebody will be is
  // not something the other devices are told: the places stay on the
  // device they were set on (#204) and go elsewhere only as a GPX or KML
  // file somebody hands over. Until 2.7.6 they travelled with every sync
  // all the same, against what the map screen says about them (#231).
  'personalMapPlaces.v1': (kind: CarriedKind.text, when: _deviceOnly),

  // Who is told that the household is alive. Typed in once, and the
  // thing nobody wants to be typing on a second phone after the event.
  'checkInContacts.v1': (kind: CarriedKind.text, when: _always),

  // The heavy rain hazard at the household's address. The household is
  // in one place, and the answer was asked for with a network.
  'heavyRainHazard.v1': (kind: CarriedKind.text, when: _always),

  // How far ahead the household wants to be warned.
  'expiryLeadDays': (kind: CarriedKind.text, when: _always),
  'chargeReminderDays': (kind: CarriedKind.integer, when: _always),

  // Which tiles new map downloads come from. The key for them does not
  // travel; see the note above.
  'mapTileProvider': (kind: CarriedKind.text, when: _always),
  'mapSourcePreference': (kind: CarriedKind.text, when: _setupOnly),

  // The knowledge area: where a first-aid pack is fetched from, how
  // articles are opened, and what has been marked.
  'firstAidPackUrl': (kind: CarriedKind.text, when: _always),
  'articleViewerChoice': (kind: CarriedKind.text, when: _setupOnly),
  'knowledgeArticleBookmarksV1': (kind: CarriedKind.textList, when: _always),

  // Taste, strictly speaking, but a second device set up from a first is
  // meant to arrive looking like it.
  'themeModeOverride': (kind: CarriedKind.text, when: _setupOnly),
  'localeOverride': (kind: CarriedKind.text, when: _setupOnly),
  'notificationsEnabled': (kind: CarriedKind.boolean, when: _setupOnly),
};

/// The household as one device has it set up, ready to hand to another.
///
/// Two halves, because they are stored in two places and applied by two
/// different owners: the [profile] goes through the household controller
/// so the app redraws, the [settings] go straight into preferences.
class CarriedHousehold {
  const CarriedHousehold({this.profile, this.settings = const {}});

  /// Who lives here, where, and how many. The single most useful thing to
  /// carry: without it a second device knows the whole stock but not the
  /// number of people it has to last.
  final HouseholdProfile? profile;

  final Map<String, Object> settings;

  bool get isEmpty => profile == null && settings.isEmpty;

  Map<String, Object?> toJson() => {
    'profile': profile?.toJson(),
    'settings': settings,
  };

  /// Never throws and never half-reads: an unusable profile costs the
  /// profile, not the settings beside it.
  static CarriedHousehold fromJson(Object? raw) {
    if (raw is! Map<String, Object?>) return const CarriedHousehold();
    final profile = raw['profile'];
    final settings = raw['settings'];
    return CarriedHousehold(
      profile: profile is Map<String, Object?>
          ? HouseholdProfile.fromJson(profile)
          : null,
      settings: {
        if (settings is Map)
          for (final entry in settings.entries)
            if (entry.key is String && entry.value is Object)
              entry.key as String: entry.value as Object,
      },
    );
  }
}

/// Everything this device would hand over about how it is set up.
Future<CarriedHousehold> readCarriedHousehold([
  SharedPreferences? preferences,
]) async => CarriedHousehold(
  profile: await const HouseholdProfileStore().load(),
  settings: await readCarriedSettings(preferences: preferences),
);

/// What this device's own backup keeps of how it is set up: what
/// [readCarriedHousehold] hands over, and what stays on the device.
Future<CarriedHousehold> readBackupHousehold([
  SharedPreferences? preferences,
]) async => CarriedHousehold(
  profile: await const HouseholdProfileStore().load(),
  settings: await readCarriedSettings(
    preferences: preferences,
    forBackup: true,
  ),
);

/// Reads the carried settings out of this device, ready to send.
///
/// A setting that was never touched is left out entirely rather than sent
/// as a null, so a household that has no opinion about something does not
/// overwrite one that does. What is [CarriedWhen.deviceOnly] is read only
/// [forBackup].
Future<Map<String, Object>> readCarriedSettings({
  SharedPreferences? preferences,
  CarriedWhen? when,
  bool forBackup = false,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  final values = <String, Object>{};
  for (final entry in carriedSettings.entries) {
    if (when != null && entry.value.when != when) continue;
    if (!forBackup && entry.value.when == _deviceOnly) continue;
    final value = await _read(prefs, entry.key, entry.value.kind);
    final normalized = normalizedCarriedSettingValue(entry.key, value);
    if (normalized != null) {
      values[entry.key] = normalized;
    }
  }
  return values;
}

/// Writes [values] into this device's settings and answers how many landed.
///
/// Anything not on the allow-list, and anything whose value does not match
/// the kind the allow-list gives, is dropped without comment: the far side
/// may be a newer or an older version of the app, and a handover must not
/// fail over a setting. So is what is [CarriedWhen.deviceOnly]: a version
/// before 2.7.6 still sends the places of its map (#231), and they are
/// not this device's to keep.
Future<int> applyCarriedSettings(
  Map<String, Object?> values, [
  SharedPreferences? preferences,
]) => _apply(values, preferences, fromBackup: false);

/// [applyCarriedSettings] for this device's own backup, which also brings
/// back what stays on the device.
Future<int> restoreBackupSettings(
  Map<String, Object?> values, [
  SharedPreferences? preferences,
]) => _apply(values, preferences, fromBackup: true);

Future<int> _apply(
  Map<String, Object?> values,
  SharedPreferences? preferences, {
  required bool fromBackup,
}) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  var applied = 0;
  for (final entry in values.entries) {
    final setting = carriedSettings[entry.key];
    if (setting == null) continue;
    if (!fromBackup && setting.when == _deviceOnly) continue;
    if (await _write(prefs, entry.key, setting.kind, entry.value)) applied++;
  }
  return applied;
}

Future<Object?> _read(
  SharedPreferences prefs,
  String key,
  CarriedKind kind,
) async {
  try {
    if (key == 'expiryLeadDays') return prefs.get(key);
    if (_privateSettings.contains(key)) {
      const store = PrivatePreferences();
      return kind == CarriedKind.textList
          ? await store.getStringList(key)
          : await store.getString(key);
    }
    return switch (kind) {
      CarriedKind.boolean => prefs.getBool(key),
      CarriedKind.integer => prefs.getInt(key),
      CarriedKind.decimal => prefs.getDouble(key),
      CarriedKind.text => prefs.getString(key),
      CarriedKind.textList => prefs.getStringList(key),
    };
  } on Object {
    // The stored value is of another type than this table says — an
    // older version wrote it differently. Not worth a failed handover.
    return null;
  }
}

Future<bool> _write(
  SharedPreferences prefs,
  String key,
  CarriedKind kind,
  Object? value,
) async {
  value = normalizedCarriedSettingValue(key, value);
  if (value == null) return false;
  try {
    if (_privateSettings.contains(key)) {
      const store = PrivatePreferences();
      if (kind == CarriedKind.textList) {
        if (value is! List) return false;
        await store.setStringList(key, [
          for (final item in value)
            if (item is String) item,
        ]);
        return true;
      }
      if (value is! String) return false;
      await store.setString(key, value);
      return true;
    }
    switch (kind) {
      case CarriedKind.boolean:
        if (value is! bool) return false;
        return await _confirmedWrite(prefs, prefs.setBool(key, value));
      case CarriedKind.integer:
        if (value is! num) return false;
        return await _confirmedWrite(prefs, prefs.setInt(key, value.toInt()));
      case CarriedKind.decimal:
        if (value is! num) return false;
        return await _confirmedWrite(
          prefs,
          prefs.setDouble(key, value.toDouble()),
        );
      case CarriedKind.text:
        if (value is! String) return false;
        return await _confirmedWrite(prefs, prefs.setString(key, value));
      case CarriedKind.textList:
        if (value is! List) return false;
        return await _confirmedWrite(
          prefs,
          prefs.setStringList(key, [
            for (final item in value)
              if (item is String) item,
          ]),
        );
    }
  } on Object {
    return false;
  }
}

Future<bool> _confirmedWrite(
  SharedPreferences prefs,
  Future<bool> write,
) async {
  try {
    final saved = await write;
    if (saved) return true;
  } catch (_) {
    // The caller counts only confirmed values; the cache must agree.
  }
  try {
    await prefs.reload();
  } catch (_) {
    /* Leave the write unacknowledged. */
  }
  return false;
}

/// The same boundary for setup, synchronization and backup. JSON numbers
/// can overflow to infinity without being a syntax error.
bool validCarriedSettingValue(String key, Object? value) =>
    normalizedCarriedSettingValue(key, value) != null;

Object? normalizedCarriedSettingValue(String key, Object? value) {
  final setting = carriedSettings[key];
  if (setting == null) return null;
  if (key == 'expiryLeadDays') {
    // Older senders used a single integer although the controller stores
    // comma-separated lead times. Never install the wrong preference type.
    if (value is num && value.isFinite && value == value.toInt()) {
      if (value == 0) return '';
      if (selectableExpiryLeadDays.contains(value.toInt())) {
        return '${value.toInt()}';
      }
      return null;
    }
    if (value is! String) return null;
    if (value.isNotEmpty &&
        !value
            .split(',')
            .every(
              (part) => selectableExpiryLeadDays.contains(int.tryParse(part)),
            )) {
      return null;
    }
  }
  final valid = switch (setting.kind) {
    CarriedKind.boolean => value is bool,
    CarriedKind.integer =>
      value is num &&
          value.isFinite &&
          value >= 0 &&
          value == value.toInt() &&
          _withinRange(key, value),
    CarriedKind.decimal =>
      value is num && value.isFinite && _withinRange(key, value),
    CarriedKind.text => value is String,
    CarriedKind.textList =>
      value is List && value.every((item) => item is String),
  };
  return valid ? value : null;
}

/// The carried numbers that have a range of their own. A test holds this
/// to every number in [carriedSettings], so a new one is a decision.
@visibleForTesting
const carriedNumberRanges = {
  'chargeReminderDays',
  'daylightLatitude',
  'daylightLongitude',
};

/// The range each carried number may take, named by key. Checked by kind
/// alone, the next whole number added here would have had to be a charge
/// interval and the next decimal a longitude.
bool _withinRange(String key, num value) => switch (key) {
  'chargeReminderDays' => isChargeReminderDays(value.toInt()),
  'daylightLatitude' => value.abs() <= 90,
  'daylightLongitude' => value.abs() <= 180,
  _ => true,
};

/// Used only by the versioned merge. A tombstone is a deletion, whereas
/// null in an unversioned setup remains an absent opinion.
Future<bool> applySyncedSettingIfUnchanged(
  String key,
  Object? value, {
  required Object? expectedStored,
  required SharedPreferences preferences,
}) async {
  if (carriedSettings[key]?.when != CarriedWhen.always) return false;
  if (value != null) {
    value = normalizedCarriedSettingValue(key, value);
    if (value == null) return false;
  }
  if (_privateSettings.contains(key)) {
    return const PrivatePreferences().compareAndSetString(
      key,
      expectedStored: expectedStored,
      value: value as String?,
      preferences: preferences,
    );
  }
  final current = preferences.get(key);
  final same = current is List && expectedStored is List
      ? current.length == expectedStored.length &&
            List.generate(
              current.length,
              (i) => current[i] == expectedStored[i],
            ).every((same) => same)
      : current == expectedStored;
  if (!same) return false;
  if (value == null) {
    return _confirmedWrite(preferences, preferences.remove(key));
  }
  return _write(preferences, key, carriedSettings[key]!.kind, value);
}
