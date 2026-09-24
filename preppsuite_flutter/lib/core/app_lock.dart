import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The optional lock in front of the app's local household data.
///
/// The verifier is deliberately held by the platform's secure store, never in
/// preferences beside the household. The passphrase itself is never saved;
/// reopening the app derives a fresh key and proves it by authenticating the
/// fixed marker. This protects a running, unattended device without turning a
/// forgotten passphrase into lost household data: resetting the device lock
/// removes the verifier, not the database.
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

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Object {
      return null;
    }
  }

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

  static const _saltLength = 16;
  static const _defaultMemory = 65536;
  static const _defaultIterations = 3;
  static const _defaultParallelism = 1;

  /// Production values use 64 MiB and three Argon2id iterations. Tests can
  /// lower the work factor without weakening the installed app.
  final int memory;
  final int iterations;
  final int parallelism;

  Future<bool> isEnabled() async => await _storage.read(_enabledKey) == 'true';

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
