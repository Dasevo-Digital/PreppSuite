import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _folderPathKey = 'sharedFolderPath';
const _deviceIdKey = 'syncDeviceId';

/// Which folder this device shares through, and what it calls itself in
/// it.
///
/// Preferences rather than the database: the folder path is a property of
/// this installation, not of the household's data. Copying the database to
/// another device must not drag the first device's folder path — or its
/// identity — along with it.
class SharedFolderStore {
  const SharedFolderStore();

  /// The folder the user picked, or null when sharing is switched off.
  Future<String?> folderPath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_folderPathKey);
    return (path == null || path.isEmpty) ? null : path;
  }

  Future<void> saveFolderPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderPathKey, path);
  }

  /// Forgets the folder. Deliberately leaves this device's snapshot behind:
  /// the other devices are still reading it, and removing it would delete
  /// rows from the household that were never asked to be deleted.
  Future<void> clearFolderPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderPathKey);
  }

  /// This device's name in the folder, generated on first use.
  ///
  /// It only has to be unique, never guessable or meaningful — it exists
  /// so that no two devices write the same file.
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = const Uuid().v4();
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }
}
