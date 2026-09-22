/// The settings that belong to the household rather than to the device.
///
/// Joining a household used to move the rows and nothing else, so a second
/// device arrived knowing what was in the cellar but not which region it
/// watches, which river gauge it reads, what the energy plan is, or how
/// long the freezer has been off. All of that is the household's, and
/// re-entering it by hand on every device is exactly the kind of work the
/// join was supposed to save.
///
/// **An allow-list and not a copy of everything**, because three kinds of
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
///
/// Caches — the last reading from each station, when the warning feed was
/// last polled — are left out for a duller reason: they are refetched in
/// seconds and carrying them would only make the handover bigger.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../model/household_profile.dart';
import '../../../model/household_profile_store.dart';

/// What kind of value a setting holds.
///
/// Spelled out rather than read off the incoming JSON. JSON has one number
/// type and `shared_preferences` has two, so a latitude that happens to be
/// a whole number would arrive as an int and be stored where `getDouble`
/// cannot read it — a setting that works everywhere except at 52° exactly.
enum CarriedKind { boolean, integer, decimal, text, textList }

/// Every setting that travels with a household, and what it holds.
/// Deliberately absent: `warningCountryCode`, `warningRegionKey` and
/// `warningExtraRegions`. Those three are not settings but a *copy* of the
/// household profile, kept where the background worker can read it without
/// Riverpod (see [WarningRegionStore]). Carrying them would be carrying the
/// shadow instead of the thing — and the profile, which travels as
/// [CarriedHousehold.profile], rewrites them the moment it lands.
const carriedSettings = <String, CarriedKind>{
  'watchedAutobahnen': CarriedKind.textList,

  // The measuring stations it reads. Each is a place, and the household
  // is in one place.
  'pegelStation': CarriedKind.text,
  'radiationStation': CarriedKind.text,
  'airQualityStation': CarriedKind.text,
  'fireDangerStation': CarriedKind.text,

  // Where the sun rises here.
  'daylightLatitude': CarriedKind.decimal,
  'daylightLongitude': CarriedKind.decimal,
  'daylightPlaceName': CarriedKind.text,

  // The energy plan: what the household draws and what it has put by.
  // Hand-entered, appliance by appliance, and the single most tedious
  // thing to type twice.
  'energyDraws': CarriedKind.textList,
  'energyReserves': CarriedKind.textList,

  // A blackout that is running is running for the whole household — the
  // fridge does not care which device is looking at the clock.
  'outageStartedAt': CarriedKind.text,
  'outageFreezerFull': CarriedKind.boolean,

  // What has been practised, and when.
  'drillProgress': CarriedKind.textList,
  'drillLastCompleted': CarriedKind.text,

  // What the household has worked out about itself in the crisis
  // overview: the answers the records cannot supply, entered by hand.
  'preparednessHubV1': CarriedKind.text,

  // The meeting point, the way out, the well. Places the household
  // agreed on — the most useful thing on the map and, until now, the
  // one thing about the map that did not travel with a handover. They
  // are coordinates, not paths, so nothing here points at a file on the
  // other machine.
  'personalMapPlaces.v1': CarriedKind.text,

  // How far ahead the household wants to be warned.
  'expiryLeadDays': CarriedKind.integer,
  'chargeReminderDays': CarriedKind.integer,

  // Which tiles new map downloads come from. The key for them does not
  // travel; see the note above.
  'mapTileProvider': CarriedKind.text,
  'mapSourcePreference': CarriedKind.text,

  // The knowledge area: where a first-aid pack is fetched from, how
  // articles are opened, and what has been marked.
  'firstAidPackUrl': CarriedKind.text,
  'articleViewerChoice': CarriedKind.text,
  'knowledgeArticleBookmarksV1': CarriedKind.textList,

  // Taste, strictly speaking, but a second device set up from a first is
  // meant to arrive looking like it.
  'themeModeOverride': CarriedKind.text,
  'localeOverride': CarriedKind.text,
  'notificationsEnabled': CarriedKind.boolean,
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
  settings: await readCarriedSettings(preferences),
);

/// Reads the carried settings out of this device, ready to send.
///
/// A setting that was never touched is left out entirely rather than sent
/// as a null, so a household that has no opinion about something does not
/// overwrite one that does.
Future<Map<String, Object>> readCarriedSettings([
  SharedPreferences? preferences,
]) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  return {
    for (final entry in carriedSettings.entries)
      entry.key: ?_read(prefs, entry.key, entry.value),
  };
}

/// Writes [values] into this device's settings and answers how many landed.
///
/// Anything not on the allow-list, and anything whose value does not match
/// the kind the allow-list gives, is dropped without comment: the far side
/// may be a newer or an older version of the app, and a handover must not
/// fail over a setting.
Future<int> applyCarriedSettings(
  Map<String, Object?> values, [
  SharedPreferences? preferences,
]) async {
  final prefs = preferences ?? await SharedPreferences.getInstance();
  var applied = 0;
  for (final entry in values.entries) {
    final kind = carriedSettings[entry.key];
    if (kind == null) continue;
    if (await _write(prefs, entry.key, kind, entry.value)) applied++;
  }
  return applied;
}

Object? _read(SharedPreferences prefs, String key, CarriedKind kind) {
  try {
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
  try {
    switch (kind) {
      case CarriedKind.boolean:
        if (value is! bool) return false;
        await prefs.setBool(key, value);
      case CarriedKind.integer:
        if (value is! num) return false;
        await prefs.setInt(key, value.toInt());
      case CarriedKind.decimal:
        if (value is! num) return false;
        await prefs.setDouble(key, value.toDouble());
      case CarriedKind.text:
        if (value is! String) return false;
        await prefs.setString(key, value);
      case CarriedKind.textList:
        if (value is! List) return false;
        await prefs.setStringList(key, [
          for (final item in value)
            if (item is String) item,
        ]);
    }
    return true;
  } on Object {
    return false;
  }
}
