/// Where this device keeps the key to its shared folder.
///
/// It used to lie in preferences as plain text, on the argument that the
/// database it protects a *copy* of was plain SQLite in the same folder,
/// so guarding the key more carefully than the original would be theatre.
/// That argument died with 2.0.1: the databases are encrypted now, and
/// this key was the one thing left that opened a household to anybody who
/// copied the data folder.
///
/// It goes through [PrivatePreferences], which puts it under a key
/// derived from the local data key. Still not the platform keychain
/// itself — the threat this key answers is the folder sitting in somebody
/// else's cloud, see `folder_crypto.dart` — but no longer readable from
/// the file beside it.
///
/// Keyed by household, so joining a second folder does not silently reuse
/// the first one's key and produce failures that look like corruption.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/private_preferences.dart';
import 'folder_crypto.dart';

class FolderKeyStore {
  const FolderKeyStore();

  static String _requiredKey(String id) => 'folderEncryptionRequired.$id';

  /// Sticky even after forgetting a key or leaving the folder.
  Future<bool> requiresEncryption(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_requiredKey(householdId)) == true ||
        await const PrivatePreferences().containsKey(_keyFor(householdId));
  }

  Future<void> rememberEncryption(String householdId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_requiredKey(householdId)) == true) return;
    if (!await prefs.setBool(_requiredKey(householdId), true)) {
      throw StateError('Could not remember folder encryption');
    }
  }

  static String _keyFor(String householdId) => 'folderKey.$householdId';

  Future<FolderKey?> read(String householdId) async => FolderKey.decode(
    await const PrivatePreferences().getString(_keyFor(householdId)),
  );

  Future<void> write(String householdId, FolderKey key) async {
    await rememberEncryption(householdId);
    await const PrivatePreferences().setString(
      _keyFor(householdId),
      key.encode(),
    );
  }

  /// Forgets the key, which locks this device out until the passphrase is
  /// entered again. Used when leaving a folder — a key left behind would
  /// open a folder this device is no longer part of.
  Future<void> clear(String householdId) async {
    if (await requiresEncryption(householdId)) {
      await rememberEncryption(householdId);
    }
    await const PrivatePreferences().remove(_keyFor(householdId));
  }
}
