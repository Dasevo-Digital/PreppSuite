import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:preppsuite_flutter/core/biometric_unlock.dart';

class _Auth extends Fake implements LocalAuthentication {
  _Auth({this.supported = true, this.unlocks = true, this.failure});

  final bool supported;
  final bool unlocks;
  final LocalAuthExceptionCode? failure;
  bool? biometricOnly;

  @override
  Future<bool> isDeviceSupported() async => supported;

  @override
  Future<bool> authenticate({
    required String localizedReason,
    Iterable<Object> authMessages = const [],
    bool biometricOnly = false,
    bool sensitiveTransaction = true,
    bool persistAcrossBackgrounding = false,
  }) async {
    this.biometricOnly = biometricOnly;
    final code = failure;
    if (code != null) throw LocalAuthException(code: code);
    return unlocks;
  }
}

/// Asking the device's own screen lock before a lost app lock is set aside
/// (#223).
void main() {
  Future<DeviceOwnerAnswer> ask(_Auth auth, {bool platformCanAsk = true}) =>
      LocalDeviceOwnerCheck(
        auth: auth,
        platformCanAsk: platformCanAsk,
      ).confirm('reason');

  test('the PIN counts as much as a face', () async {
    final auth = _Auth();

    expect(await ask(auth), DeviceOwnerAnswer.confirmed);
    expect(auth.biometricOnly, isFalse);
  });

  test('a cancelled or wrong answer is a refusal', () async {
    expect(await ask(_Auth(unlocks: false)), DeviceOwnerAnswer.refused);
    expect(
      await ask(_Auth(failure: LocalAuthExceptionCode.userCanceled)),
      DeviceOwnerAnswer.refused,
    );
  });

  test('a lockout after wrong tries is a refusal, not a way round', () async {
    // Were it "cannot ask", five wrong PINs would lead to the plain
    // confirmation that stands in for a device without a lock.
    for (final code in [
      LocalAuthExceptionCode.temporaryLockout,
      LocalAuthExceptionCode.biometricLockout,
      LocalAuthExceptionCode.deviceError,
    ]) {
      expect(
        await ask(_Auth(failure: code)),
        DeviceOwnerAnswer.refused,
        reason: code.name,
      );
    }
  });

  test('a device without any screen lock cannot be asked', () async {
    expect(await ask(_Auth(supported: false)), DeviceOwnerAnswer.cannotAsk);
    expect(
      await ask(_Auth(failure: LocalAuthExceptionCode.noCredentialsSet)),
      DeviceOwnerAnswer.cannotAsk,
    );
  });

  test('nor can a platform without an implementation', () async {
    expect(
      await ask(_Auth(), platformCanAsk: false),
      DeviceOwnerAnswer.cannotAsk,
    );
  });
}
