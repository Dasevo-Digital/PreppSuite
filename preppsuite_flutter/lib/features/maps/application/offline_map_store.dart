import 'package:shared_preferences/shared_preferences.dart';

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
    final location = prefs.getString(_archivePathKey);
    if (location == null || location.isEmpty) return null;

    final label = prefs.getString(_archiveLabelKey);
    return (
      location: location,
      label: label == null || label.isEmpty ? location : label,
    );
  }

  Future<void> save({required String location, required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_archivePathKey, location);
    await prefs.setString(_archiveLabelKey, label);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_archivePathKey);
    await prefs.remove(_archiveLabelKey);
  }
}
