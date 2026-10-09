import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_lock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryStorage implements AppLockStorage {
  final values = <String, String>{};

  /// A key store that will not answer: a Mac without a signing
  /// certificate, a Linux session without a keyring, a keychain that has
  /// not been unlocked yet.
  var refusing = false;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async {
    if (refusing) throw StateError('no key store');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  AppLockStore store(_MemoryStorage storage) => AppLockStore(
    storage: storage,
    // Keeps the regression test fast. The installed app uses the secure
    // defaults documented in AppLockStore.
    memory: 1024,
    iterations: 1,
  );

  test('enables, verifies and removes the optional device lock', () async {
    final storage = _MemoryStorage();
    final lock = store(storage);

    expect(await lock.isEnabled(), isFalse);

    await lock.enable('ein-langer-test-schluessel');
    expect(await lock.isEnabled(), isTrue);
    expect(await lock.verify('ein-langer-test-schluessel'), isTrue);
    expect(await lock.verify('falscher-schluessel'), isFalse);

    await lock.disable();
    expect(await lock.isEnabled(), isFalse);
    expect(await lock.verify('ein-langer-test-schluessel'), isFalse);
  });

  test(
    'face or fingerprint is off until chosen, and goes with the lock',
    () async {
      // #143: turning the lock off must not leave a setting behind that a
      // later lock would inherit without being asked.
      final storage = _MemoryStorage();
      final lock = store(storage);
      await lock.enable('ein-langer-test-schluessel');
      expect(await lock.biometricEnabled(), isFalse);
      await lock.setBiometric(true);
      expect(await lock.biometricEnabled(), isTrue);
      await lock.disable();
      expect(await lock.biometricEnabled(), isFalse);
      await lock.enable('ein-langer-test-schluessel');
      expect(await lock.biometricEnabled(), isFalse);
    },
  );

  test('rejects an incomplete secure-store verifier', () async {
    final storage = _MemoryStorage();
    await store(storage).enable('ein-langer-test-schluessel');
    storage.values.remove('appLock.check.v1');

    expect(await store(storage).verify('ein-langer-test-schluessel'), isFalse);
  });

  group('when the key store will not answer', () {
    test('an app that was never locked still starts', () async {
      // The case a Mac without a signing certificate lands in. Keeping
      // somebody out of an app that protects nothing yet would be the
      // wrong half of the trade.
      final storage = _MemoryStorage()..refusing = true;

      expect(await store(storage).isEnabled(), isFalse);
    });

    test('a locked app refuses to say it is open', () async {
      // The half that matters. Answering "not enabled" here is what opens
      // somebody's household to whoever picked the device up.
      final storage = _MemoryStorage();
      final lock = store(storage);
      await lock.enable('ein-langer-test-schluessel');

      storage.refusing = true;

      await expectLater(
        lock.isEnabled(),
        throwsA(isA<AppLockStatusUnavailable>()),
      );
    });

    test('a lock set before the marker existed is still recognised', () async {
      // An installation locked by an older version has no marker until it
      // is read once successfully -- which is what this does.
      final storage = _MemoryStorage();
      final lock = store(storage);
      await lock.enable('ein-langer-test-schluessel');
      SharedPreferences.setMockInitialValues({});

      expect(await lock.isEnabled(), isTrue);
      storage.refusing = true;

      await expectLater(
        lock.isEnabled(),
        throwsA(isA<AppLockStatusUnavailable>()),
      );
    });

    test('an unlocked app that was locked before opens again', () async {
      final storage = _MemoryStorage();
      final lock = store(storage);
      await lock.enable('ein-langer-test-schluessel');
      await lock.disable();

      storage.refusing = true;

      expect(await lock.isEnabled(), isFalse);
    });
  });
}
