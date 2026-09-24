import 'dart:convert';

import '../core/private_preferences.dart';
import 'household_profile.dart';

const _profileKey = 'householdProfile';

/// Where the household profile lives now that no server holds it.
///
/// Preferences rather than the drift database on purpose: the profile has
/// to be readable before the database is opened (it decides which rows are
/// even relevant), and the background isolate reads preferences too.
///
/// Through [PrivatePreferences], because it is the most personal thing the
/// app keeps outside the database: who lives here, how many, and where.
class HouseholdProfileStore {
  const HouseholdProfileStore();

  Future<HouseholdProfile?> load() async {
    final raw = await const PrivatePreferences().getString(_profileKey);
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
    await const PrivatePreferences().setString(
      _profileKey,
      jsonEncode(profile.toJson()),
    );
  }

  Future<void> clear() async {
    await const PrivatePreferences().remove(_profileKey);
  }
}
