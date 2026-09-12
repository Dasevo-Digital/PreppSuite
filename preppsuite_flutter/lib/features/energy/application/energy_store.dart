import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'energy_range.dart';

/// What the household has and what draws on it.
class EnergyPlan {
  const EnergyPlan({this.reserves = const [], this.draws = const []});

  final List<EnergyReserve> reserves;
  final List<EnergyDraw> draws;

  bool get isEmpty => reserves.isEmpty && draws.isEmpty;
}

/// Keeps the plan.
///
/// In preferences rather than the database: it is two short lists of the
/// household's own figures, not an inventory — nothing is scanned,
/// nothing expires, and nothing is counted against a barcode. The
/// emergency contacts on the same screen are kept the same way.
class EnergyPlanStore {
  const EnergyPlanStore();

  static const _reservesKey = 'energyReserves';
  static const _drawsKey = 'energyDraws';

  Future<EnergyPlan> load() async {
    final prefs = await SharedPreferences.getInstance();
    return EnergyPlan(
      reserves: [
        for (final entry in _decode(prefs.getString(_reservesKey)))
          ?EnergyReserve.fromJson(entry),
      ],
      draws: [
        for (final entry in _decode(prefs.getString(_drawsKey)))
          ?EnergyDraw.fromJson(entry),
      ],
    );
  }

  Future<void> save(EnergyPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reservesKey,
      jsonEncode([for (final item in plan.reserves) item.toJson()]),
    );
    await prefs.setString(
      _drawsKey,
      jsonEncode([for (final item in plan.draws) item.toJson()]),
    );
  }

  /// A stored string that is no longer a list is read as no entries.
  ///
  /// Not as an error: the alternative is a screen that refuses to open
  /// because of one bad character, and the two lists are typed in by
  /// hand and cheap to type again.
  static List<Object?> _decode(String? raw) {
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }
}
