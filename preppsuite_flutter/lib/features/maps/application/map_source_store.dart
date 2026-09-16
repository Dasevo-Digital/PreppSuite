import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tile_source.dart';

const _providerKey = 'mapTileProvider';
const _apiKeyKey = 'mapTilerApiKey';

/// Which tile provider new map downloads come from, and the key for one
/// that needs it. Provider choice is ordinary app state; the provider key
/// goes into the platform's protected credential store instead.
abstract interface class MapApiKeyStore {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> delete();
}

class SecureMapApiKeyStore implements MapApiKeyStore {
  const SecureMapApiKeyStore([
    this._storage = const FlutterSecureStorage(),
  ]);

  static const _secureKey = 'map_tiler_api_key';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _secureKey);

  @override
  Future<void> write(String value) =>
      _storage.write(key: _secureKey, value: value);

  @override
  Future<void> delete() => _storage.delete(key: _secureKey);
}

class MapSourceStore {
  const MapSourceStore({this.keyStore = const SecureMapApiKeyStore()});

  final MapApiKeyStore keyStore;

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
    String? protected;
    try {
      protected = await keyStore.read();
    } on Object {
      // A tile download without a MapTiler key still works. If the platform
      // credential store is unavailable, keep the provider picker usable and
      // never fall back to returning the old plaintext preference.
      return null;
    }
    if (protected != null && protected.isNotEmpty) return protected;

    // One-time migration for installations made before protected storage was
    // introduced. Remove the plaintext setting only after the secure write.
    final prefs = await SharedPreferences.getInstance();
    final legacy = prefs.getString(_apiKeyKey)?.trim();
    if (legacy == null || legacy.isEmpty) return null;
    try {
      await keyStore.write(legacy);
    } on Object {
      return null;
    }
    await prefs.remove(_apiKeyKey);
    return legacy;
  }

  Future<void> saveApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.trim().isEmpty) {
      await keyStore.delete();
      await prefs.remove(_apiKeyKey);
    } else {
      await keyStore.write(key.trim());
      await prefs.remove(_apiKeyKey);
    }
  }
}
