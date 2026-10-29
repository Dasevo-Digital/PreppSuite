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

/// What the device's own screen lock said when asked (#223).
enum DeviceOwnerAnswer {
  /// The person unlocked it: PIN, pattern, password, face or fingerprint.
  confirmed,

  /// Asked and not confirmed -- cancelled, wrong, or locked out after too
  /// many tries.
  refused,

  /// There is nothing to ask: no screen lock is set, or the platform has
  /// no way of asking (Linux).
  cannotAsk,
}

/// Asks the device's screen lock whether the owner is here.
///
/// Not the app lock's face or fingerprint: that one replaces typing a
/// passphrase the person knows. This is for the one case where nobody
/// knows it any more -- the lock's verifier is gone from the key store,
/// and no passphrase opens the app (#223). The device's own lock is the
/// best evidence left that the hand on the screen is the household's, so
/// the PIN counts here as much as a face.
abstract interface class DeviceOwnerCheck {
  Future<DeviceOwnerAnswer> confirm(String reason);
}

class LocalDeviceOwnerCheck implements DeviceOwnerCheck {
  LocalDeviceOwnerCheck({LocalAuthentication? auth, bool? platformCanAsk})
    : _auth = auth ?? LocalAuthentication(),
      // There is no implementation for Linux at all, and asking it throws.
      _platformCanAsk = platformCanAsk ?? !Platform.isLinux;

  final LocalAuthentication _auth;
  final bool _platformCanAsk;

  @override
  Future<DeviceOwnerAnswer> confirm(String reason) async {
    if (!_platformCanAsk) return DeviceOwnerAnswer.cannotAsk;
    try {
      if (!await _auth.isDeviceSupported()) return DeviceOwnerAnswer.cannotAsk;
    } on Object {
      return DeviceOwnerAnswer.cannotAsk;
    }
    try {
      final unlocked = await _auth.authenticate(
        localizedReason: reason,
        persistAcrossBackgrounding: true,
      );
      return unlocked ? DeviceOwnerAnswer.confirmed : DeviceOwnerAnswer.refused;
    } on LocalAuthException catch (error) {
      // Only "nothing is set up" may lead to the confirmation without a
      // lock. A lockout after wrong tries is a refusal: otherwise five
      // wrong PINs would be the way round the PIN.
      return error.code == LocalAuthExceptionCode.noCredentialsSet
          ? DeviceOwnerAnswer.cannotAsk
          : DeviceOwnerAnswer.refused;
    } on Object {
      return DeviceOwnerAnswer.refused;
    }
  }
}

final deviceOwnerCheckProvider = Provider<DeviceOwnerCheck>(
  (ref) => LocalDeviceOwnerCheck(),
);
