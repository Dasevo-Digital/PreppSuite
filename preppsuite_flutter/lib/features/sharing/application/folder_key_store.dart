/// Where this device keeps the key to its shared folder.
///
/// Beside the database, in app-private storage, and not behind the
/// platform keychain. That is a deliberate choice rather than a shortcut:
/// the database this key protects a *copy* of is plain SQLite in the same
/// place, so a keychain here would guard the copy more carefully than the
/// original. The threat this key answers is the folder sitting in someone
/// else's cloud — see `folder_crypto.dart`.
///
/// Keyed by household, so joining a second folder does not silently reuse
/// the first one's key and produce failures that look like corruption.
library;

import 'package:shared_preferences/shared_preferences.dart';

import 'folder_crypto.dart';

class FolderKeyStore {
  const FolderKeyStore();

  static String _keyFor(String householdId) => 'folderKey.$householdId';

  Future<FolderKey?> read(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    return FolderKey.decode(prefs.getString(_keyFor(householdId)));
  }

  Future<void> write(String householdId, FolderKey key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFor(householdId), key.encode());
  }

  /// Forgets the key, which locks this device out until the passphrase is
  /// entered again. Used when leaving a folder — a key left behind would
  /// open a folder this device is no longer part of.
  Future<void> clear(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFor(householdId));
  }
}
