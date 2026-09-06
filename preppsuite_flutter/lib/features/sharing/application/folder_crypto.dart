/// Encrypting what goes into the shared folder.
///
/// The folder is the one place this app puts household data somewhere it
/// does not control. It is a Nextcloud, Syncthing or iCloud directory, so
/// the people who can read it are the provider, anyone with the sync
/// account, and anyone who finds the directory on a shared disk. That is
/// the threat this file answers — and only that one.
///
/// It is deliberately *not* an answer to someone holding an unlocked
/// device. The local database is plain SQLite and the derived key sits in
/// app-private storage beside it: protecting the key harder than the data
/// it opens would be theatre. See `docs/gemeinsamer-ordner.md`.
library;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Work factors for [Argon2id].
///
/// 64 MB and three passes is the OWASP recommendation for Argon2id at
/// this parallelism. It costs roughly a second on a mid-range phone,
/// which is paid once when a folder is opened and never during a sync —
/// the derived key is kept. Chosen high because the thing being guessed
/// is a household passphrase, and those are short.
///
/// The numbers are written into `vault.json` rather than assumed, so a
/// folder made today still opens if these ever rise.
const argon2Memory = 65536; // in 1 kB blocks, i.e. 64 MB
const argon2Iterations = 3;
const argon2Parallelism = 1;
const _keyLength = 32;
const _nonceLength = 12;
const saltLength = 16;

/// The plaintext that proves a passphrase is the right one.
///
/// Without it the only way to test a passphrase is to try decrypting a
/// device file, which fails identically for "wrong passphrase" and "file
/// truncated in transit" — and telling someone their passphrase is wrong
/// when the download is broken is the worse of the two mistakes.
const _checkPlaintext = 'preppsuite-vault-check';

/// How a folder's key is derived. Public: none of it is secret.
class VaultParameters {
  const VaultParameters({
    required this.salt,
    this.memory = argon2Memory,
    this.iterations = argon2Iterations,
    this.parallelism = argon2Parallelism,
  });

  /// Deliberately weak factors, for tests only.
  ///
  /// Argon2id at the shipped factors costs about a second per call by
  /// design, and a suite that derives a key in a dozen places would spend
  /// its life in the KDF. Named rather than hand-rolled in each test so
  /// nobody is tempted to weaken the real ones to make a test quicker —
  /// `AppDatabase.forTesting` is the same idea.
  static final testing = VaultParameters(
    salt: Uint8List.fromList(List.filled(saltLength, 7)),
    memory: 1024,
    iterations: 1,
  );

  final Uint8List salt;
  final int memory;
  final int iterations;
  final int parallelism;

  Map<String, Object?> toJson() => {
    'kdf': 'argon2id',
    'salt': base64Encode(salt),
    'memory': memory,
    'iterations': iterations,
    'parallelism': parallelism,
  };

  /// Null for anything this app cannot derive a key from — an unknown
  /// KDF, a missing salt, a work factor so large it would hang the phone.
  /// Refusing beats guessing: a wrong key produces failures that look
  /// like corruption.
  static VaultParameters? fromJson(Map<String, Object?> json) {
    if (json['kdf'] != 'argon2id') return null;

    final salt = _base64OrNull(json['salt']);
    if (salt == null || salt.length < 8) return null;

    final memory = json['memory'];
    final iterations = json['iterations'];
    final parallelism = json['parallelism'];
    if (memory is! int || memory < 1024 || memory > 1048576) return null;
    if (iterations is! int || iterations < 1 || iterations > 64) return null;
    if (parallelism is! int || parallelism < 1 || parallelism > 16) return null;

    return VaultParameters(
      salt: salt,
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
    );
  }
}

/// A folder's key, already derived.
///
/// Holding this rather than the passphrase is what keeps a sync from
/// costing a second of Argon2 every time.
class FolderKey {
  const FolderKey(this.bytes);

  final Uint8List bytes;

  String encode() => base64Encode(bytes);

  static FolderKey? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final bytes = _base64OrNull(raw);
    if (bytes == null || bytes.length != _keyLength) return null;
    return FolderKey(bytes);
  }
}

/// Derives the folder key from a passphrase.
Future<FolderKey> deriveFolderKey(
  String passphrase,
  VaultParameters parameters,
) async {
  final algorithm = Argon2id(
    memory: parameters.memory,
    iterations: parameters.iterations,
    parallelism: parameters.parallelism,
    hashLength: _keyLength,
  );
  final key = await algorithm.deriveKeyFromPassword(
    password: passphrase,
    nonce: parameters.salt,
  );
  return FolderKey(Uint8List.fromList(await key.extractBytes()));
}

/// Encrypts [plaintext] under [key].
///
/// The envelope is JSON so an unreadable file stays diagnosable: someone
/// looking at the folder can tell PreppSuite's ciphertext from a truncated
/// download without a tool. It carries nothing but the nonce and the
/// ciphertext — no household id, no device name, no length hint beyond
/// what a file size already gives away.
Future<String> encryptForFolder(String plaintext, FolderKey key) async {
  final algorithm = AesGcm.with256bits();
  final box = await algorithm.encrypt(
    utf8.encode(plaintext),
    secretKey: SecretKey(key.bytes),
    nonce: algorithm.newNonce(),
  );

  return jsonEncode({
    'preppsuite': 'enc',
    'v': 1,
    'alg': 'aes-gcm-256',
    'nonce': base64Encode(box.nonce),
    'data': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
}

/// Null when [raw] is not this app's envelope, and null when it is but the
/// key is wrong or the bytes were altered.
///
/// One return value for both on purpose. A caller that could tell them
/// apart would be telling an attacker which of their guesses got closer,
/// and the honest answer to the user — "this did not open" — is the same
/// either way. Whether a passphrase is right is answered by
/// [checkPassphrase] against the folder's own check value instead.
Future<String?> decryptFromFolder(String raw, FolderKey key) async {
  final envelope = readEnvelope(raw);
  if (envelope == null) return null;

  try {
    final clear = await AesGcm.with256bits().decrypt(
      SecretBox(
        envelope.cipherText,
        nonce: envelope.nonce,
        mac: Mac(envelope.mac),
      ),
      secretKey: SecretKey(key.bytes),
    );
    return utf8.decode(clear);
  } on Object {
    // SecretBoxAuthenticationError for a wrong key or altered bytes,
    // FormatException for ciphertext that decrypts to invalid UTF-8.
    return null;
  }
}

/// The parts of an envelope, or null if [raw] is not one.
///
/// Split out so a caller can ask "is this encrypted at all?" without
/// holding a key — which is what lets a folder hold plaintext files from
/// devices that have not been switched over yet.
({Uint8List nonce, Uint8List cipherText, Uint8List mac})? readEnvelope(
  String raw,
) {
  final Object? json;
  try {
    json = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (json is! Map<String, Object?>) return null;
  if (json['preppsuite'] != 'enc') return null;
  if (json['v'] != 1 || json['alg'] != 'aes-gcm-256') return null;

  final nonce = _base64OrNull(json['nonce']);
  final data = _base64OrNull(json['data']);
  final mac = _base64OrNull(json['mac']);
  if (nonce == null || data == null || mac == null) return null;
  if (nonce.length != _nonceLength) return null;

  return (nonce: nonce, cipherText: data, mac: mac);
}

/// Whether [raw] is one of this app's encrypted files.
bool looksEncrypted(String raw) => readEnvelope(raw) != null;

/// Builds the check value stored in `vault.json`.
Future<String> buildCheckValue(FolderKey key) =>
    encryptForFolder(_checkPlaintext, key);

/// Whether [key] is the one this folder was set up with.
Future<bool> checkFolderKey(FolderKey key, String checkValue) async =>
    await decryptFromFolder(checkValue, key) == _checkPlaintext;

Uint8List? _base64OrNull(Object? value) {
  if (value is! String || value.isEmpty) return null;
  try {
    return base64Decode(value);
  } on FormatException {
    return null;
  }
}

/// A fresh salt for a folder being set up.
///
/// `Random.secure` rather than the package's own generator: the salt is
/// written once and every future key derives from it, so it is worth
/// taking from the platform's entropy source directly.
Uint8List newSalt() {
  final random = Random.secure();
  return Uint8List.fromList([
    for (var i = 0; i < saltLength; i++) random.nextInt(256),
  ]);
}
