import 'package:preppsuite_client/preppsuite_client.dart' show PushPlatform;

import 'push_token_source.dart';

/// Remembers which token this device last registered, so it can still be
/// revoked after a restart — the push service will happily hand out the
/// same token again, but nothing else knows what the server was told.
abstract interface class RegisteredTokenStore {
  Future<String?> read();
  Future<void> write(String? token);
}

/// Keeps the server's idea of this device in step with the user's
/// notification setting.
///
/// One entry point, [reconcile], called at launch and whenever the setting
/// changes. Making it idempotent rather than a pair of on/off commands is
/// what lets it recover: a revocation that failed because the phone was
/// offline is simply retried the next time the app opens, instead of
/// leaving the server pushing to someone who switched notifications off a
/// week ago.
class PushRegistrationService {
  PushRegistrationService({
    required this.tokenSource,
    required this.store,
    required this.register,
    required this.unregister,
  });

  final PushTokenSource tokenSource;
  final RegisteredTokenStore store;

  final Future<void> Function(
    String householdId,
    String token,
    PushPlatform platform,
  )
  register;

  final Future<void> Function(String token) unregister;

  /// Brings the server in line with [enabled].
  ///
  /// Returns the token now registered, or null if none is (which is the
  /// normal outcome on desktop, in a build without Firebase, or when the
  /// user has notifications off).
  Future<String?> reconcile({
    required bool enabled,
    required String? householdId,
  }) async {
    final stored = await store.read();

    if (!enabled || householdId == null) {
      if (stored != null) await _revoke(stored);
      return null;
    }

    if (!tokenSource.isAvailable) return null;
    final platform = currentPushPlatform();
    if (platform == null) return null;

    final token = await tokenSource.token();
    if (token == null) return null;

    // A rotated token leaves the old one registered server-side, and FCM
    // keeps delivering to it for a while — the same warning would arrive
    // twice until the stale one finally expires.
    if (stored != null && stored != token) await _revoke(stored);

    await register(householdId, token, platform);
    await store.write(token);
    return token;
  }

  /// Revokes [token], clearing it locally only if the server confirmed.
  /// Keeping it on failure is what makes the retry on next launch
  /// possible.
  Future<void> _revoke(String token) async {
    try {
      await unregister(token);
      await store.write(null);
    } catch (_) {
      // Offline, or the server is down. The token stays recorded and the
      // next `reconcile` tries again.
    }
  }
}
