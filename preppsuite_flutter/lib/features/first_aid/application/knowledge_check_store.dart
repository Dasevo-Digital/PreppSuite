import 'package:shared_preferences/shared_preferences.dart';

/// Which questions sit, and when they last did.
///
/// Deliberately **not** in the household's carried settings, unlike the
/// drill progress beside it. Practising an evacuation is something a
/// household does together; knowing that a tourniquet stays on is
/// something a person knows or does not. Copying one person's result onto
/// the next device would tell somebody they know something they have
/// never been asked.
///
/// A passed question is not passed forever. It is stored with nothing but
/// its id, and the screen shows how long ago the last round was, because
/// the whole reason this exists is that the knowledge goes quiet again.
class KnowledgeCheckStore {
  const KnowledgeCheckStore();

  static const _passedKey = 'knowledgeCheckPassed';
  static const _lastKey = 'knowledgeCheckLast';

  Future<Set<String>> passed() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_passedKey) ?? const []).toSet();
  }

  /// When the last round was finished, or null if there has been none.
  Future<DateTime?> lastRound() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toUtc();
  }

  /// Records one finished round.
  ///
  /// [wrong] is taken back out again: getting a question wrong after
  /// getting it right once is exactly the thing this is looking for, and
  /// leaving it marked would hide it until somebody reset everything.
  Future<void> record({
    required Set<String> right,
    required Set<String> wrong,
    DateTime? at,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final held = (prefs.getStringList(_passedKey) ?? const []).toSet()
      ..addAll(right)
      ..removeAll(wrong);
    await prefs.setStringList(_passedKey, held.toList()..sort());
    await prefs.setString(
      _lastKey,
      (at ?? DateTime.now()).toUtc().toIso8601String(),
    );
  }

  Future<void> forget() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_passedKey);
    await prefs.remove(_lastKey);
  }
}
