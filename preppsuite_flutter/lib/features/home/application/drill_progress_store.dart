import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Which drill steps have been ticked off.
///
/// These used to live in the widget's own state, which meant leaving the
/// screen lost them — and a drill runs twenty minutes with the family, in
/// which somebody will navigate away to check the household plan or the
/// offline map. Coming back to an empty list is exactly the moment a drill
/// gets abandoned.
///
/// Preferences and not the database: this is progress through an exercise,
/// not inventory. It travels with the household's settings all the same
/// (`carried_settings.dart`), so a drill run together on two devices ticks
/// off on both, and the next one still starts from nothing (see [clear]).
class DrillProgressStore {
  const DrillProgressStore();

  static const _key = 'drillProgress';
  static const _completedKey = 'drillLastCompleted';

  Future<Set<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key) ?? const []).toSet();
    } on Object {
      // A drill that cannot remember its ticks is still a usable drill.
      return {};
    }
  }

  Future<void> save(Set<String> checked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (checked.isEmpty) {
        await prefs.remove(_key);
        return;
      }
      await prefs.setStringList(_key, checked.toList());
    } on Object {
      return;
    }
  }

  /// Ticks [step] off, or back on, in what is stored now, and answers the
  /// steps ticked after that. Not a whole set from the screen: a drill run
  /// on two devices ticks off on both, and the screen that saved its own
  /// set last undid the other's ticks (#258).
  Future<Set<String>> setStep(String step, {required bool done}) async {
    final checked = {...await load()};
    if (done) {
      checked.add(step);
    } else {
      checked.remove(step);
    }
    await save(checked);
    return checked;
  }

  /// Starts the exercise over.
  Future<void> clear() => save(const {});

  /// The most recent completed run of each scenario.
  ///
  /// Kept in step with the household like the tick marks. It is a short
  /// rehearsal log, not a status report, and goes to no service.
  Future<Map<String, DateTime>> loadCompleted() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(
        _completedKey,
      );
      if (raw == null) return const {};
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries)
          if (entry.key is String && entry.value is String)
            if (DateTime.tryParse(entry.value as String) case final date?)
              entry.key as String: date.toLocal(),
      };
    } on Object {
      return const {};
    }
  }

  Future<void> markCompleted(String scenarioId, DateTime completedAt) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final completed = await loadCompleted();
      await prefs.setString(
        _completedKey,
        jsonEncode({
          ...completed.map(
            (key, value) => MapEntry(key, value.toUtc().toIso8601String()),
          ),
          scenarioId: completedAt.toUtc().toIso8601String(),
        }),
      );
    } on Object {
      return;
    }
  }
}
