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
/// not household data. It does not sync to the other devices and it does
/// not belong in a backup — the drill is a rehearsal, and the next one
/// starts from nothing on purpose (see [clear]).
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

  /// Starts the exercise over.
  Future<void> clear() => save(const {});

  /// The most recent completed run of each scenario.
  ///
  /// This remains local like the tick marks. It is a short rehearsal log,
  /// not a household status report and not something sent to a service.
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
