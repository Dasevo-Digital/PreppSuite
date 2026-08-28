import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_database_providers.dart';
import 'notifications_provider.dart';
import 'push_registration.dart';
import 'push_token_source.dart';

const _registeredTokenPrefsKey = 'registeredPushToken';

class _PrefsRegisteredTokenStore implements RegisteredTokenStore {
  const _PrefsRegisteredTokenStore();

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredTokenPrefsKey);
  }

  @override
  Future<void> write(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_registeredTokenPrefsKey);
    } else {
      await prefs.setString(_registeredTokenPrefsKey, token);
    }
  }
}

/// Overridden once a Firebase project is configured; until then push is
/// simply unavailable and the app behaves exactly as before.
final pushTokenSourceProvider = Provider<PushTokenSource>(
  (ref) => const UnavailablePushTokenSource(),
);

final pushRegistrationServiceProvider = Provider<PushRegistrationService>((
  ref,
) {
  final sync = ref.watch(syncServiceProvider);
  return PushRegistrationService(
    tokenSource: ref.watch(pushTokenSourceProvider),
    store: const _PrefsRegisteredTokenStore(),
    register: (householdId, token, platform) => sync.registerPushDevice(
      householdId: householdId,
      token: token,
      platform: platform,
    ),
    unregister: sync.unregisterPushDevice,
  );
});

/// Keeps this device's server-side push registration in step with the
/// notification setting, for as long as a household is open.
///
/// Reconciles on start and on every change of the toggle, and again
/// whenever the push service rotates the token.
class PushRegistrationController extends Notifier<AsyncValue<String?>> {
  PushRegistrationController(this.householdId);

  final String householdId;

  @override
  AsyncValue<String?> build() {
    ref.listen(notificationsEnabledProvider, (_, next) => _reconcile(next));

    final tokenSource = ref.watch(pushTokenSourceProvider);
    if (tokenSource.isAvailable) {
      final subscription = tokenSource.onTokenRefresh.listen(
        (_) => _reconcile(ref.read(notificationsEnabledProvider)),
      );
      ref.onDispose(subscription.cancel);
    }

    Future.microtask(() async {
      // The setting is read from disk asynchronously; acting on its
      // provisional `false` would unregister the device on every launch.
      await ref.read(notificationsEnabledProvider.notifier).ensureLoaded();
      if (!ref.mounted) return;
      await _reconcile(ref.read(notificationsEnabledProvider));
    });

    return const AsyncData(null);
  }

  Future<void> _reconcile(bool enabled) async {
    try {
      final token = await ref
          .read(pushRegistrationServiceProvider)
          .reconcile(enabled: enabled, householdId: householdId);
      if (!ref.mounted) return;
      state = AsyncData(token);
    } catch (error, stackTrace) {
      // A failed registration is not worth interrupting anyone over — the
      // app keeps working, warnings still arrive while it is open, and the
      // next launch tries again.
      if (!ref.mounted) return;
      state = AsyncError(error, stackTrace);
    }
  }
}

final pushRegistrationControllerProvider =
    NotifierProvider.family<
      PushRegistrationController,
      AsyncValue<String?>,
      String
    >(PushRegistrationController.new);

/// Revokes this device's registration, for sign-out.
///
/// Signing out must not leave the phone receiving a household's warnings;
/// the token is the only thing the server matches on, and it survives the
/// session that created it.
Future<void> unregisterPushOnSignOut(PushRegistrationService service) {
  return service.reconcile(enabled: false, householdId: null);
}
