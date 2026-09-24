import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The optional lock in front of the app's local household data.
///
/// The verifier is deliberately held by the platform's secure store, never in
/// preferences beside the household. The passphrase itself is never saved;
/// reopening the app derives a fresh key and proves it by authenticating the
/// fixed marker. This protects a running, unattended device without turning a
/// forgotten passphrase into lost household data: resetting the device lock
/// removes the verifier, not the database.
/// The lock exists but its state cannot be read right now.
///
/// Kept apart from "no lock is set" on purpose, because the two look
/// identical to a key store that will not answer and are opposites to the
/// person in front of the screen. See [AppLockStore.isEnabled].
class AppLockStatusUnavailable implements Exception {
  const AppLockStatusUnavailable();
}

abstract interface class AppLockStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureAppLockStorage implements AppLockStorage {
  SecureAppLockStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

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

class AppLockStore {
  AppLockStore({
    AppLockStorage? storage,
    this.memory = _defaultMemory,
    this.iterations = _defaultIterations,
    this.parallelism = _defaultParallelism,
  }) : _storage = storage ?? SecureAppLockStorage();

  final AppLockStorage _storage;

  static const _enabledKey = 'appLock.enabled.v1';
  static const _saltKey = 'appLock.salt.v1';
  static const _checkKey = 'appLock.check.v1';
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
  final int memory;
  final int iterations;
  final int parallelism;

  /// Whether the app is locked.
  ///
  /// Throws [AppLockStatusUnavailable] when a lock is known to exist but
  /// its state cannot be read: the gate fails closed on that, which is the
  /// only safe answer. Where no lock was ever set up, an unreachable key
  /// store is not a reason to keep somebody out of an app that protects
  /// nothing yet -- that is the case a Mac without a signing certificate
  /// lands in, and it has to start.
  Future<bool> isEnabled() async {
    try {
      final enabled = await _storage.read(_enabledKey) == 'true';
      // Written from here rather than only in `enable`, so that an
      // installation that was locked before this marker existed gets one
      // the first time it is read successfully.
      await _rememberConfigured(enabled);
      return enabled;
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
    final salt = Uint8List.fromList(
      List.generate(_saltLength, (_) => Random.secure().nextInt(256)),
    );
    final key = await _keyFor(passphrase, salt);
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(_marker),
      secretKey: key,
    );
    await _storage.write(_saltKey, base64Encode(salt));
    await _storage.write(
      _checkKey,
      jsonEncode({
        'nonce': base64Encode(box.nonce),
        'data': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      }),
    );
    await _storage.write(_enabledKey, 'true');
    // Last, and only once the key store has taken all three. A marker set
    // before a write that then fails would claim a lock that does not
    // exist -- and the gate, failing closed on it, would lock somebody out
    // of their own household with no passphrase that opens it.
    await _rememberConfigured(true);
  }

  Future<bool> verify(String passphrase) async {
    final salt = _decode(await _storage.read(_saltKey));
    final check = await _storage.read(_checkKey);
    if (salt == null || check == null) return false;
    try {
      final raw = jsonDecode(check);
      if (raw is! Map<String, Object?>) return false;
      final nonce = _decode(raw['nonce'] as String?);
      final data = _decode(raw['data'] as String?);
      final mac = _decode(raw['mac'] as String?);
      if (nonce == null || data == null || mac == null) return false;
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(data, nonce: nonce, mac: Mac(mac)),
        secretKey: await _keyFor(passphrase, salt),
      );
      return utf8.decode(clear) == _marker;
    } on Object {
      return false;
    }
  }

  Future<void> disable() async {
    await _storage.delete(_enabledKey);
    await _storage.delete(_saltKey);
    await _storage.delete(_checkKey);
    // And here the other way round: the marker goes last, so a deletion
    // that fails leaves it standing and the gate keeps failing closed
    // rather than opening on a lock that is still there.
    await _rememberConfigured(false);
  }

  Future<SecretKey> _keyFor(String passphrase, Uint8List salt) {
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
