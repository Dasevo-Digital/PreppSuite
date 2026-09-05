import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'shared_folder_access.dart';

const _folderPathKey = 'sharedFolderPath';
const _folderLabelKey = 'sharedFolderLabel';
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
  ///
  /// A filesystem path on every platform but Android, where it is the
  /// `content://` tree the Storage Access Framework handed over — which is
  /// also why the label is stored beside it rather than derived from it.
  Future<SharedFolderLocation?> location() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_folderPathKey);
    if (value == null || value.isEmpty) return null;

    final label = prefs.getString(_folderLabelKey);
    return SharedFolderLocation(
      value: value,
      label: label == null || label.isEmpty ? value : label,
    );
  }

  Future<void> saveLocation(SharedFolderLocation folder) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_folderPathKey, folder.value);
    await prefs.setString(_folderLabelKey, folder.label);
  }

  /// Forgets the folder. Deliberately leaves this device's snapshot behind:
  /// the other devices are still reading it, and removing it would delete
  /// rows from the household that were never asked to be deleted.
  Future<void> clearLocation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_folderPathKey);
    await prefs.remove(_folderLabelKey);
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
