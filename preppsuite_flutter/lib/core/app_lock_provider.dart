import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_lock.dart';
import 'biometric_unlock.dart';

class AppLockController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => AppLockStore().isEnabled();

  Future<void> enable(String passphrase) async {
    await AppLockStore().enable(passphrase);
    state = const AsyncData(true);
  }

  Future<void> disable() async {
    await AppLockStore().disable();
    state = const AsyncData(false);
    // The lock took the face or fingerprint with it.
    ref.invalidate(appLockBiometricProvider);
  }

  /// Sets aside a lock that can no longer be read, once the device's owner
  /// has confirmed it (#223). True when the app is open afterwards.
  ///
  /// The household's data stays where it is; only the lock goes. Should
  /// the key store still hold it after all, the lock is back and asks for
  /// its passphrase -- that is not a failure, but it is not open either.
  Future<bool> forgetUnreadable() async {
    final store = AppLockStore();
    await store.forgetForFreshStart();
    ref.invalidate(appLockBiometricProvider);
    try {
      final enabled = await store.isEnabled();
      state = AsyncData(enabled);
      return !enabled;
    } on Object catch (error, stack) {
      state = AsyncError(error, stack);
      return false;
    }
  }
}

final appLockProvider = AsyncNotifierProvider<AppLockController, bool>(
  AppLockController.new,
);

/// Whether the lock opens with face or fingerprint (#143): chosen by the
/// household and possible on this device. A device whose sensor has gone
/// -- the fingerprints deleted, Face ID turned off -- reads as off, and
/// the passphrase is asked for as before.
class AppLockBiometricController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    if (!await AppLockStore().biometricEnabled()) return false;
    return ref.read(biometricAuthProvider).available();
  }

  /// Turns it on only after the sensor has recognised the person once, so
  /// it cannot be switched on for a face the device does not know.
  Future<bool> enable(String reason) async {
    final auth = ref.read(biometricAuthProvider);
    if (!await auth.available() || !await auth.authenticate(reason)) {
      return false;
    }
    await AppLockStore().setBiometric(true);
    state = const AsyncData(true);
    return true;
  }

  Future<void> disable() async {
    await AppLockStore().setBiometric(false);
    state = const AsyncData(false);
  }
}

final appLockBiometricProvider =
    AsyncNotifierProvider<AppLockBiometricController, bool>(
      AppLockBiometricController.new,
    );
