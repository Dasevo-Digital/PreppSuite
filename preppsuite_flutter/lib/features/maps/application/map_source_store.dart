import 'package:shared_preferences/shared_preferences.dart';

import 'tile_source.dart';

const _providerKey = 'mapTileProvider';
const _apiKeyKey = 'mapTilerApiKey';

/// Which tile provider new map downloads come from, and the key for one
/// that needs it.
///
/// The key is the user's own; it is kept in preferences beside the rest
/// of the app's settings and never sent anywhere but to the provider it
/// belongs to.
class MapSourceStore {
  const MapSourceStore();

  Future<MapTileProvider> provider() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_providerKey);
    return MapTileProvider.values.asNameMap()[name] ??
        MapTileProvider.openFreeMap;
  }

  Future<void> useProvider(MapTileProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, provider.name);
  }

  Future<String?> apiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString(_apiKeyKey);
    return key == null || key.isEmpty ? null : key;
  }

  Future<void> saveApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await prefs.remove(_apiKeyKey);
    } else {
      await prefs.setString(_apiKeyKey, key.trim());
    }
  }
}
