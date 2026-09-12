import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/portable_paths.dart';

const _archivePathKey = 'offlineMapArchivePath';
const _archiveLabelKey = 'offlineMapArchiveLabel';

/// Which map archive this device uses, if any.
///
/// The file itself is never copied into the app: a country extract is
/// gigabytes, and a second copy on a phone is the difference between the
/// feature fitting and not. Only where it is gets kept — a path, or on
/// Android a `content://` URI.
class OfflineMapStore {
  const OfflineMapStore();

  Future<({String location, String label})?> archive() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_archivePathKey);
    if (stored == null || stored.isEmpty) return null;
    // An archive on the same disk as the app is remembered by where it
    // sits within the data folder, not by a path that names a drive
    // letter. See `portable_paths.dart`.
    final location = readLocation(stored);

    final label = prefs.getString(_archiveLabelKey);
    return (
      location: location,
      label: label == null || label.isEmpty ? location : label,
    );
  }

  Future<void> save({required String location, required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archivePathKey, storeLocation(location));
    await prefs.setString(_archiveLabelKey, label);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_archivePathKey);
    await prefs.remove(_archiveLabelKey);
  }
}
