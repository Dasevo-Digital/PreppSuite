import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Face or fingerprint in place of the app lock's passphrase (#143).
///
/// A passphrase of twelve characters is a fair lock on a phone left on a
/// table, and a poor one for a hand that shakes. Since 2.4.8 the emergency
/// help is reachable without unlocking; what still needs the passphrase
/// is the household's own data -- the emergency cards among it. This
/// opens the lock with what the device already knows of its owner.
///
/// It replaces only the typing. The passphrase stays the lock: it is still
/// set first, it still opens the app when the sensor will not, and turning
/// the lock off still asks for nothing more than it did. The lock guards
/// the open app, not the data's key, so nothing here touches a key either.
abstract interface class BiometricAuth {
  /// Whether this device has a face or fingerprint enrolled that can be
  /// asked for.
  Future<bool> available();

  /// Asks for it. True only when the person was recognised; a cancelled
  /// prompt, a locked-out sensor or a platform without one is false.
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuth implements BiometricAuth {
  LocalBiometricAuth([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> available() async {
    // There is no implementation for Linux at all, and asking it throws.
    if (Platform.isLinux) return false;
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // The point is not to type. A fallback to the device PIN would
        // be a second passphrase, and Windows Hello decides for itself.
        biometricOnly: !Platform.isWindows,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}

final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => LocalBiometricAuth(),
);

/// Whether this device could open the lock with face or fingerprint at
/// all -- what decides whether the setting is offered.
final biometricAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(biometricAuthProvider).available(),
);
