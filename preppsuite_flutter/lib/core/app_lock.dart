import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'portable_data.dart';
import 'secure_storage.dart';

/// The lock exists but its state cannot be read right now.
///
/// Kept apart from "no lock is set" on purpose, because the two look
/// identical to a key store that will not answer and are opposites to the
/// person in front of the screen. See [AppLockStore.isEnabled].
class AppLockStatusUnavailable implements Exception {
  const AppLockStatusUnavailable();
}

/// The Argon2id parameters every app lock was set up with until 3.0.3,
/// when a verifier did not yet say which it used (#422). Never change
/// these: they are what opens those verifiers.
const legacyLockParameters = (memory: 65536, iterations: 3, parallelism: 1);

abstract interface class AppLockStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAppLockStorage implements AppLockStorage {
  SecureAppLockStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? appSecureStorage;

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Throws rather than answering "nothing stored".
  ///
  /// It used to swallow this, so that a Mac whose key store cannot be
  /// reached would still start. What it also did was turn an unreadable
  /// lock into an absent one -- and an absent lock opens the app.
  /// [AppLockStore.isEnabled] now makes that distinction with a marker
  /// that is not a secret; this stays honest.
  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// The optional lock in front of the app's local household data.
///
/// The verifier is deliberately held by the platform's secure store, never in
/// preferences beside the household. The passphrase itself is never saved;
/// reopening the app derives a fresh key and proves it by authenticating the
/// fixed marker. This protects a running, unattended device without turning a
/// forgotten passphrase into lost household data: resetting the device lock
/// removes the verifier, not the database.
///
/// **A carried data folder has no lock** ([available]). The secure store
/// is this computer's, and the installation here keeps its own lock in it:
/// read from a carried copy, the installation's passphrase locked the
/// disk, a lock set on the disk locked it on every other computer, and
/// "start over" or "reset the lock" in the folder deleted the
/// installation's verifier. Keeping a verifier in the folder instead was
/// considered and not done: the folder's data is plain on purpose, so that
/// it opens anywhere, and whoever has the disk reads it without the app.
/// What a lock there would add is a passphrase hash anyone holding the
/// disk can guess at offline, and a face or finger on another computer
/// that would open it. So in a carried folder every method here leaves
/// the secure store alone and the lock reads as off; the settings card
/// says why.
class AppLockStore {
  AppLockStore({
    AppLockStorage? storage,
    this.memory = _defaultMemory,
    this.iterations = _defaultIterations,
    this.parallelism = _defaultParallelism,
    @visibleForTesting this.unnamedParameters = legacyLockParameters,
  }) : _storage = storage ?? SecureAppLockStorage();

  final AppLockStorage _storage;

  static const _enabledKey = 'appLock.enabled.v1';
  static const _saltKey = 'appLock.salt.v1';
  static const _checkKey = 'appLock.check.v1';
  static const _biometricKey = 'appLock.biometric.v1';
  static const _marker = 'preppsuite-app-lock-v1';

  /// Says *that* a lock is set, never anything about it.
  ///
  /// In ordinary preferences rather than the key store, because its whole
  /// job is to be readable when the key store is not. It carries no
  /// passphrase, no salt and no verifier -- knowing that a device is
  /// locked is what somebody standing in front of the locked screen can
  /// already see.
  static const _configuredKey = 'appLockConfigured.v1';

  static const _saltLength = 16;
  static const _defaultMemory = 65536;
  static const _defaultIterations = 3;
  static const _defaultParallelism = 1;

  /// Production values use 64 MiB and three Argon2id iterations. Tests can
  /// lower the work factor without weakening the installed app.
  ///
  /// What a new verifier is made with. A verifier keeps the values it was
  /// made with (#422), so raising these later does not lock anybody out:
  /// an older one still opens with its own, and is written again with
  /// these once it has been opened.
  final int memory;
  final int iterations;
  final int parallelism;

  /// What a verifier that names no parameters was made with: every lock
  /// set up to 3.0.3. Only tests change it.
  final ({int memory, int iterations, int parallelism}) unnamedParameters;

  /// Whether this copy can have a lock at all: not in a carried data
  /// folder (see the class comment).
  static bool get available => !portableLocation.isPortable;

  /// Whether the app is locked.
  ///
  /// Throws [AppLockStatusUnavailable] when a lock is known to exist but
  /// its state cannot be read: the gate fails closed on that, which is the
  /// only safe answer. Where no lock was ever set up, an unreachable key
  /// store is not a reason to keep somebody out of an app that protects
  /// nothing yet -- that is the case a Mac without a signing certificate
  /// lands in, and it has to start.
  Future<bool> isEnabled() async {
    // Neither the installation's lock nor a marker the folder brought
    // along: a carried folder has none.
    if (!available) return false;
    try {
      final value = await _storage.read(_enabledKey);
      if (value != 'true') {
        // Absence is not proof of a deliberate disable. Restores and
        // unavailable key stores can return null without throwing.
        if (await _wasConfigured()) throw const AppLockStatusUnavailable();
        return false;
      }
      // Written from here rather than only in `enable`, so that an
      // installation that was locked before this marker existed gets one
      // the first time it is read successfully.
      await _rememberConfigured(true);
      return true;
    } on Object {
      if (await _wasConfigured()) throw const AppLockStatusUnavailable();
      return false;
    }
  }

  Future<bool> _wasConfigured() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_configuredKey) ?? false;
    } on Object {
      // Preferences are gone too. Nothing can be established about this
      // device, and an app that cannot say whether it is locked must not
      // claim it is open.
      return true;
    }
  }

  Future<void> _rememberConfigured(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (enabled) {
        await prefs.setBool(_configuredKey, true);
      } else {
        await prefs.remove(_configuredKey);
      }
    } on Object {
      // Best effort. A marker that cannot be written costs the
      // distinction on the next start, and `_wasConfigured` errs closed.
    }
  }

  Future<void> enable(String passphrase) async {
    if (!available) {
      throw UnsupportedError('A carried data folder has no app lock.');
    }
    final salt = Uint8List.fromList(
      List.generate(_saltLength, (_) => Random.secure().nextInt(256)),
    );
    await _storage.write(_saltKey, base64Encode(salt));
    await _storage.write(_checkKey, await _verifierFor(passphrase, salt));
    await _storage.write(_enabledKey, 'true');
    // Last, and only once the key store has taken all three. A marker set
    // before a write that then fails would claim a lock that does not
    // exist -- and the gate, failing closed on it, would lock somebody out
    // of their own household with no passphrase that opens it.
    await _rememberConfigured(true);
  }

  Future<bool> verify(String passphrase) async {
    if (!available) return false;
    final check = await _storage.read(_checkKey);
    if (check == null) return false;
    final Map<String, Object?> raw;
    final Uint8List salt;
    final ({int memory, int iterations, int parallelism}) used;
    try {
      final decoded = jsonDecode(check);
      if (decoded is! Map<String, Object?>) return false;
      raw = decoded;
      final nonce = _decode(raw['nonce'] as String?);
      final data = _decode(raw['data'] as String?);
      final mac = _decode(raw['mac'] as String?);
      // A verifier from 3.0.4 on carries its salt and its parameters; an
      // older one has its salt beside it and was made with the values of
      // its day, which are not necessarily today's.
      final named = raw['kdf'] != null;
      final ownSalt = named
          ? _decode(raw['salt'] as String?)
          : _decode(await _storage.read(_saltKey));
      final parameters = named ? _parametersIn(raw) : unnamedParameters;
      if (nonce == null ||
          data == null ||
          mac == null ||
          ownSalt == null ||
          parameters == null) {
        return false;
      }
      salt = ownSalt;
      used = parameters;
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(data, nonce: nonce, mac: Mac(mac)),
        secretKey: await _keyFor(
          passphrase,
          salt,
          memory: used.memory,
          iterations: used.iterations,
          parallelism: used.parallelism,
        ),
      );
      if (utf8.decode(clear) != _marker) return false;
    } on Object {
      return false;
    }
    if (raw['kdf'] == null ||
        used.memory != memory ||
        used.iterations != iterations ||
        used.parallelism != parallelism) {
      await _rewriteVerifier(passphrase, salt);
    }
    return true;
  }

  /// Writes the verifier again with today's parameters, in one write and
  /// with the salt it had: the salt stored beside it stays the one that
  /// belongs to it, so there is no moment at which the two disagree.
  ///
  /// Best effort. The passphrase was right; a key store that will not
  /// take the new verifier leaves the old one, which still opens.
  Future<void> _rewriteVerifier(String passphrase, Uint8List salt) async {
    try {
      await _storage.write(_checkKey, await _verifierFor(passphrase, salt));
    } on Object {
      // Kept as it was.
    }
  }

  /// The verifier for [passphrase]: the marker sealed with the key derived
  /// from it, beside the salt and every parameter that derivation took.
  Future<String> _verifierFor(String passphrase, Uint8List salt) async {
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(_marker),
      secretKey: await _keyFor(
        passphrase,
        salt,
        memory: memory,
        iterations: iterations,
        parallelism: parallelism,
      ),
    );
    return jsonEncode({
      'kdf': 'argon2id',
      'm': memory,
      't': iterations,
      'p': parallelism,
      'salt': base64Encode(salt),
      'nonce': base64Encode(box.nonce),
      'data': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  /// The parameters a verifier names, or null when it names an unknown
  /// derivation or values out of any sane range.
  static ({int memory, int iterations, int parallelism})? _parametersIn(
    Map<String, Object?> raw,
  ) {
    if (raw['kdf'] != 'argon2id') return null;
    final m = raw['m'];
    final t = raw['t'];
    final p = raw['p'];
    if (m is! int || t is! int || p is! int) return null;
    // Bounded, so that a verifier cannot ask for gigabytes or for hours.
    if (m < 8 || m > 1 << 20 || t < 1 || t > 64 || p < 1 || p > 16) {
      return null;
    }
    return (memory: m, iterations: t, parallelism: p);
  }

  /// Whether the household chose to open the lock with face or
  /// fingerprint as well (#143). Off on every installation until turned
  /// on, and off again with the lock.
  Future<bool> biometricEnabled() async {
    if (!available) return false;
    try {
      return await _storage.read(_biometricKey) == 'true';
    } on Object {
      return false;
    }
  }

  Future<void> setBiometric(bool enabled) async {
    if (!available) return;
    if (enabled) {
      await _storage.write(_biometricKey, 'true');
    } else {
      await _storage.delete(_biometricKey);
    }
  }

  Future<void> disable() async {
    // What it would delete is the installation's.
    if (!available) return;
    await _storage.delete(_biometricKey);
    await _storage.delete(_enabledKey);
    await _storage.delete(_saltKey);
    await _storage.delete(_checkKey);
    // And here the other way round: the marker goes last, so a deletion
    // that fails leaves it standing and the gate keeps failing closed
    // rather than opening on a lock that is still there.
    await _rememberConfigured(false);
  }

  /// Forgets the lock of a household that "start over" just set aside
  /// (#222).
  ///
  /// The databases were moved away because this key store no longer opens
  /// them, and the verifier lives in that same key store. Left standing,
  /// the marker would keep the fresh, empty installation behind a lock no
  /// passphrase opens, and away from "restore from a backup". That is what
  /// a device transfer on Android produced: preferences and files arrive,
  /// the Keystore key does not, and the secure storage answers what it can
  /// no longer decrypt by deleting it and returning nothing.
  ///
  /// Unlike [disable], the marker goes even when the key store refuses the
  /// deletions. Should it come back holding the old lock after all,
  /// [isEnabled] reads `true` and sets the marker again.
  Future<void> forgetForFreshStart() async {
    // "Start over" in a carried folder set aside the folder's files, and
    // the lock it deleted here was the installation's (#392).
    if (!available) return;
    for (final key in [_biometricKey, _enabledKey, _saltKey, _checkKey]) {
      try {
        await _storage.delete(key);
      } on Object {
        // A key store that cannot be read usually cannot be written either.
      }
    }
    await _rememberConfigured(false);
  }

  static Future<SecretKey> _keyFor(
    String passphrase,
    Uint8List salt, {
    required int memory,
    required int iterations,
    required int parallelism,
  }) {
    return Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: 32,
    ).deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  static Uint8List? _decode(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return Uint8List.fromList(base64Decode(value));
    } on FormatException {
      return null;
    }
  }
}
