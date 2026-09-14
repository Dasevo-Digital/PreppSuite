import 'package:shared_preferences/shared_preferences.dart';

import 'outage_food_safety.dart';

/// A running blackout: when it started, and how full the freezer is.
class OutageClock {
  const OutageClock({required this.startedAt, required this.freezerFill});

  final DateTime startedAt;
  final FreezerFill freezerFill;
}

/// Remembers the blackout across restarts.
///
/// In preferences and not in the database, for the same reason the energy
/// plan is: it is this device's own note about right now, not household
/// data. It also must not sync — two devices in the same dark flat would
/// otherwise overwrite each other's start time, and a phone that was
/// elsewhere would import a blackout that never happened here.
///
/// It has to survive a restart all the same. A four-hour countdown that
/// resets when the app is reopened would be worse than none: the app
/// would be confidently wrong about food somebody then eats.
class OutageClockStore {
  const OutageClockStore();

  static const _startedAtKey = 'outageStartedAt';
  static const _freezerFullKey = 'outageFreezerFull';

  Future<OutageClock?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_startedAtKey);
    if (raw == null) return null;
    final startedAt = DateTime.tryParse(raw);
    // An unparseable value reads as "no blackout" rather than throwing.
    // The alternative is a screen that will not open, and the household
    // can start the clock again in one tap.
    if (startedAt == null) return null;
    return OutageClock(
      startedAt: startedAt.toUtc(),
      freezerFill: (prefs.getBool(_freezerFullKey) ?? true)
          ? FreezerFill.full
          : FreezerFill.half,
    );
  }

  Future<void> save(OutageClock clock) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _startedAtKey,
      clock.startedAt.toUtc().toIso8601String(),
    );
    await prefs.setBool(_freezerFullKey, clock.freezerFill == FreezerFill.full);
  }

  /// The power is back. Keeps the freezer answer — it is a property of
  /// the household's freezer, not of this blackout.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_startedAtKey);
  }
}
