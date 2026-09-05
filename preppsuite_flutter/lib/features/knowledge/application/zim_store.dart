import 'package:shared_preferences/shared_preferences.dart';

const _locationKey = 'knowledgeArchiveLocation';
const _labelKey = 'knowledgeArchiveLabel';

/// Which ZIM archive this device reads, if any.
///
/// Only where the file is, never a copy of it: a Wikipedia archive is tens
/// of gigabytes.
class ZimStore {
  const ZimStore();

  Future<({String location, String label})?> archive() async {
    final prefs = await SharedPreferences.getInstance();
    final location = prefs.getString(_locationKey);
    if (location == null || location.isEmpty) return null;

    final label = prefs.getString(_labelKey);
    return (
      location: location,
      label: label == null || label.isEmpty ? location : label,
    );
  }

  Future<void> save({required String location, required String label}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_locationKey, location);
    await prefs.setString(_labelKey, label);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_locationKey);
    await prefs.remove(_labelKey);
  }
}
