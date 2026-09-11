import 'package:shared_preferences/shared_preferences.dart';

/// Which Autobahnen this household watches.
///
/// Per device and in preferences, the same as the gauge, the probe and
/// the air quality station. The interface is per road — there is no "what
/// is shut near me" to ask — so the roads that matter have to be named
/// once.
class RoadClosureStore {
  const RoadClosureStore();

  static const _key = 'watchedAutobahnen';

  Future<List<String>> load() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_key) ??
          const [];
    } on Object {
      return const [];
    }
  }

  Future<void> save(List<String> roads) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (roads.isEmpty) {
        await prefs.remove(_key);
      } else {
        await prefs.setStringList(_key, roads);
      }
    } on Object {
      return;
    }
  }
}
