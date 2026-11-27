import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_lock.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

class _MemoryStorage implements AppLockStorage {
  final values = <String, String>{};

  /// A key store that will not answer: a Mac without a signing
  /// certificate, a Linux session without a keyring, a keychain that has
  /// not been unlocked yet.
  var refusing = false;

  @override
  Future<void> delete(String key) async {
    if (refusing) throw StateError('no key store');
    values.remove(key);
  }

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

  group('a verifier keeps the parameters it was made with (#422)', () {
    const passphrase = 'ein-langer-test-schluessel';

    /// A verifier as every version up to 3.0.3 wrote it: salt beside it,
    /// no word about the derivation.
    Future<void> writeUnnamed(_MemoryStorage storage) async {
      final salt = Uint8List.fromList(List.generate(16, (i) => i));
      final key = await Argon2id(
        memory: 1024,
        iterations: 1,
        parallelism: 1,
        hashLength: 32,
      ).deriveKeyFromPassword(password: passphrase, nonce: salt);
      final box = await AesGcm.with256bits().encrypt(
        utf8.encode('preppsuite-app-lock-v1'),
        secretKey: key,
      );
      storage.values
        ..['appLock.enabled.v1'] = 'true'
        ..['appLock.salt.v1'] = base64Encode(salt)
        ..['appLock.check.v1'] = jsonEncode({
          'nonce': base64Encode(box.nonce),
          'data': base64Encode(box.cipherText),
          'mac': base64Encode(box.mac.bytes),
        });
    }

    Map<String, Object?> stored(_MemoryStorage storage) =>
        jsonDecode(storage.values['appLock.check.v1']!) as Map<String, Object?>;

    test('raised defaults still open a lock made before them', () async {
      // The right passphrase failed once the defaults changed: the
      // verifier did not say which values had made it.
      final storage = _MemoryStorage();
      await store(storage).enable(passphrase);
      expect(stored(storage), containsPair('m', 1024));

      final stronger = AppLockStore(
        storage: storage,
        memory: 2048,
        iterations: 2,
      );
      expect(await stronger.verify('falscher-schluessel'), isFalse);
      expect(stored(storage), containsPair('m', 1024));

      expect(await stronger.verify(passphrase), isTrue);
      // Written again with today's values once it was opened.
      expect(stored(storage), containsPair('m', 2048));
      expect(stored(storage), containsPair('t', 2));
      expect(await stronger.verify(passphrase), isTrue);
    });

    test('a lock from 3.0.3 opens with the values of its day', () async {
      final storage = _MemoryStorage();
      await writeUnnamed(storage);
      final lock = AppLockStore(
        storage: storage,
        memory: 2048,
        iterations: 2,
        unnamedParameters: (memory: 1024, iterations: 1, parallelism: 1),
      );

      expect(await lock.verify('falscher-schluessel'), isFalse);
      expect(stored(storage).containsKey('kdf'), isFalse);

      expect(await lock.verify(passphrase), isTrue);
      expect(stored(storage), containsPair('kdf', 'argon2id'));
      expect(stored(storage), containsPair('m', 2048));
      // The salt beside it still belongs to it, for an older version.
      expect(stored(storage)['salt'], storage.values['appLock.salt.v1']);
      expect(await lock.verify(passphrase), isTrue);
    });

    test('a verifier that asks for absurd work is refused', () async {
      final storage = _MemoryStorage();
      await store(storage).enable(passphrase);
      storage.values['appLock.check.v1'] = jsonEncode({
        ...stored(storage),
        'm': 1 << 30,
      });

      expect(await store(storage).verify(passphrase), isFalse);
    });

    test('the parameters of 3.0.3 are the installed defaults', () {
      final lock = AppLockStore(storage: _MemoryStorage());
      expect(legacyLockParameters, (
        memory: lock.memory,
        iterations: lock.iterations,
        parallelism: lock.parallelism,
      ));
    });
  });

  group('when the key store will not answer', () {
    for (final value in [null, 'false', 'invalid']) {
      test(
        'a configured lock stays closed for missing or invalid state: $value',
        () async {
          final storage = _MemoryStorage();
          final lock = store(storage);
          await lock.enable('test-passphrase');
          if (value == null) {
            storage.values.clear();
          } else {
            storage.values['appLock.enabled.v1'] = value;
          }
          await expectLater(
            lock.isEnabled(),
            throwsA(isA<AppLockStatusUnavailable>()),
          );
          expect(
            (await SharedPreferences.getInstance()).getBool(
              'appLockConfigured.v1',
            ),
            isTrue,
          );
        },
      );
    }

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

    test(
      'starting over forgets a lock whose verifier is gone (#222)',
      () async {
        // An Android device transfer: the preferences with the marker came
        // along, the Keystore key did not, and the secure storage deleted
        // what it could no longer decrypt.
        final storage = _MemoryStorage();
        final lock = store(storage);
        await lock.enable('ein-langer-test-schluessel');
        storage.values.clear();
        await expectLater(
          lock.isEnabled(),
          throwsA(isA<AppLockStatusUnavailable>()),
        );

        await lock.forgetForFreshStart();

        expect(await lock.isEnabled(), isFalse);
      },
    );

    test('starting over drops the marker even when deleting is refused, '
        'and a lock that comes back is recognised again', () async {
      final storage = _MemoryStorage();
      final lock = store(storage);
      await lock.enable('ein-langer-test-schluessel');
      storage.refusing = true;

      await lock.forgetForFreshStart();

      expect(await lock.isEnabled(), isFalse);
      storage.refusing = false;
      expect(await lock.isEnabled(), isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool('appLockConfigured.v1'),
        isTrue,
      );
    });
  });

  group('a carried data folder (#392)', () {
    // The key store is this computer's, and the lock in it belongs to the
    // installation here.
    late Directory folder;
    late SharedPreferencesStorePlatform platform;

    setUp(() {
      folder = Directory.systemTemp.createTempSync('lock-folder');
      platform = SharedPreferencesStorePlatform.instance;
    });

    tearDown(() {
      SharedPreferencesStorePlatform.instance = platform;
      resetPortableData();
      folder.deleteSync(recursive: true);
    });

    Future<void> carry() => startPortableData(
      environment: {portableEnvironmentVariable: folder.path},
    );

    test('is not locked by the installation\'s lock', () async {
      final storage = _MemoryStorage();
      await store(storage).enable('ein-langer-test-schluessel');
      await store(storage).setBiometric(true);
      final installed = Map.of(storage.values);
      // The marker comes into the folder with the installation's settings.
      await carry();

      final lock = store(storage);
      expect(AppLockStore.available, isFalse);
      expect(await lock.isEnabled(), isFalse);
      expect(await lock.verify('ein-langer-test-schluessel'), isFalse);
      expect(await lock.biometricEnabled(), isFalse);
      expect(storage.values, installed);
    });

    test('never clears the installation\'s lock', () async {
      final storage = _MemoryStorage();
      await store(storage).enable('ein-langer-test-schluessel');
      final installed = Map.of(storage.values);
      await carry();

      // "Start over" in the folder, "reset the lock", turning it off.
      await store(storage).forgetForFreshStart();
      await store(storage).disable();
      await store(storage).setBiometric(false);

      expect(storage.values, installed);
      resetPortableData();
      SharedPreferencesStorePlatform.instance = platform;
      expect(await store(storage).isEnabled(), isTrue);
      expect(
        await store(storage).verify('ein-langer-test-schluessel'),
        isTrue,
      );
    });

    test('sets up no lock of its own', () async {
      final storage = _MemoryStorage();
      await carry();

      await expectLater(
        store(storage).enable('ein-langer-test-schluessel'),
        throwsUnsupportedError,
      );
      expect(storage.values, isEmpty);
    });

    test('a marker the folder brought along does not lock it', () async {
      // Set on the disk with 3.0.3: the marker is in the folder, the
      // verifier in the key store of whichever computer it was set on.
      SharedPreferences.setMockInitialValues({'appLockConfigured.v1': true});
      await carry();

      expect(await store(_MemoryStorage()).isEnabled(), isFalse);
    });
  });
}
