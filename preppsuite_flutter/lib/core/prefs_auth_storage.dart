import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [KeyValueStorage] backed by `shared_preferences` instead of the Keychain.
///
/// `SecureClientAuthSuccessStorage` (Serverpod's own default) needs a
/// `keychain-access-groups` entitlement, which in turn needs the app to be
/// signed with a real Apple Developer/personal-team certificate — not
/// available on every machine that just wants to build and self-host this
/// app locally. Falling back to prefs trades OS-level encryption at rest
/// for "works without any code-signing setup." Revisit once self-hosted
/// distribution builds have proper signing in place.
class PrefsAuthKeyValueStorage implements KeyValueStorage {
  @override
  Future<String?> get(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> set(String key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
  }
}
