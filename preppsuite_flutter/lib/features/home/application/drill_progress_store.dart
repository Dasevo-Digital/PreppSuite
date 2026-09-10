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
}
