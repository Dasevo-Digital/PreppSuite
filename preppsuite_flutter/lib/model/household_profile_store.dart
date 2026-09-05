import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'household_profile.dart';

const _profileKey = 'householdProfile';

/// Where the household profile lives now that no server holds it.
///
/// Preferences rather than the drift database on purpose: the profile has
/// to be readable before the database is opened (it decides which rows are
/// even relevant), and the background isolate reads preferences too.
class HouseholdProfileStore {
  const HouseholdProfileStore();

  Future<HouseholdProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return HouseholdProfile.fromJson(decoded);
    } on FormatException {
      // Unreadable is treated as absent, which sends the user through
      // onboarding rather than into a crash loop on every launch.
      return null;
    }
  }

  Future<void> save(HouseholdProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
