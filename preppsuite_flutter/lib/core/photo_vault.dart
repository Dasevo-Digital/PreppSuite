import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

import 'local_database_encryption.dart';
import 'portable_data.dart';

/// The photographs of the inventory and the possessions, encrypted at rest.
///
/// The databases were encrypted and the pictures beside them were not —
/// and the possessions list exists to photograph valuables with their
/// serial numbers, which makes its pictures the more interesting half of
/// a copied data folder.
///
/// The same rules as `PrivatePreferences`, for the same reasons:
///
/// * Reading accepts both forms. A picture taken by an older version is a
///   plain JPEG and is returned as it is.
/// * A plain picture read while a key exists is sealed in place. Together
///   with [sealDirectory] at start-up that is the whole migration; there
///   is no step to run and none to interrupt.
/// * Without a key — a carried copy, a device with no key store, an
///   installation waiting for recovery — pictures are written plainly, as
///   before. A sealed one cannot be read then, which is the same thing the
///   database does in that state.
///
/// A sealed file is `PSPHOTO1`, a 12-byte nonce, the AES-256-GCM
/// ciphertext and its 16-byte tag. The key is derived from the local data
/// key under a label of its own and never stored.
class PhotoVault {
  const PhotoVault([this._encryption]);

  final LocalDatabaseEncryption? _encryption;

  LocalDatabaseEncryption get _source =>
      _encryption ?? LocalDatabaseEncryption.instance;

  static const _label = 'preppsuite.photos.v1';

  static final _magic = Uint8List.fromList('PSPHOTO1'.codeUnits);
  static const _nonceLength = 12;
  static const _macLength = 16;

  static Uint8List? _derivedFrom;
  static Uint8List? _derived;

  /// For tests that swap the data key between cases.
  static void forgetDerivedKey() {
    _derivedFrom = null;
    _derived = null;
  }

  /// Whether [bytes] are a sealed picture rather than an image.
  static bool isSealed(List<int> bytes) {
    if (bytes.length < _magic.length + _nonceLength + _macLength) return false;
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) return false;
    }
    return true;
  }

  Future<Uint8List?> _key() async {
    // A carried folder travels to another computer and the key stays in
    // this one's keychain; sealing here would leave the pictures
    // unreadable on the next machine. See `private_preferences.dart`.
    if (portableLocation.isPortable) return null;

    final source = _source.dataKeyBytes;
    if (source == null) return null;

    final cached = _derived;
    final from = _derivedFrom;
    if (cached != null && from != null && _sameBytes(from, source)) {
      return cached;
    }

    final secret = await Hkdf(
      hmac: Hmac.sha256(),
      outputLength: 32,
    ).deriveKey(secretKey: SecretKey(source), info: _label.codeUnits);
    final key = Uint8List.fromList(await secret.extractBytes());
    _derivedFrom = source;
    _derived = key;
    return key;
  }

  static bool _sameBytes(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// The picture in [file] as image bytes, or null when it is missing or
  /// sealed under a key this installation does not hold.
  Future<Uint8List?> read(File file) async {
    final Uint8List stored;
    try {
      stored = await file.readAsBytes();
    } on FileSystemException {
      return null;
    }

    final key = await _key();
    if (!isSealed(stored)) {
      // Taken before this installation had a key, or while it had none.
      // Put it away properly while it is in hand; a failure here costs
      // nothing, the next read tries again.
      if (key != null) {
        try {
          await _replace(file, await _seal(stored, key));
        } on Object {
          // Read-only, or gone in the meantime.
        }
      }
      return stored;
    }

    if (key == null) return null;
    return _open(stored, key);
  }

  /// Writes [bytes] to [file], sealed where there is a key.
  ///
  /// Through a temporary file and a rename, so a picture is either the old
  /// one or the new one and never half of either.
  Future<void> write(File file, Uint8List bytes) async {
    final key = await _key();
    await _replace(file, key == null ? bytes : await _seal(bytes, key));
  }

  /// Seals every plain picture in [directory] and returns how many.
  ///
  /// Run once at start-up, so pictures nobody opens do not stay in the
  /// clear for ever. Does nothing without a key.
  Future<int> sealDirectory(Directory directory) async {
    final key = await _key();
    if (key == null || !await directory.exists()) return 0;

    var sealed = 0;
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is! File || entry.path.endsWith('.tmp')) continue;
      try {
        final bytes = await entry.readAsBytes();
        if (isSealed(bytes)) continue;
        await _replace(entry, await _seal(bytes, key));
        sealed++;
      } on Object {
        // One picture that cannot be sealed now is sealed on its next read.
      }
    }
    return sealed;
  }

  static Future<void> _replace(File file, Uint8List bytes) async {
    // Named per write: the sweep and a read can seal the same picture at
    // the same moment, and both results are valid.
    final temporary = File('${file.path}.${const Uuid().v4()}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(file.path);
    } on Object {
      try {
        await temporary.delete();
      } on Object {
        // Never written.
      }
      rethrow;
    }
  }

  // AES-GCM in pure Dart runs at a few megabytes a second, and a picture is
  // up to one: off the interface's isolate, or every thumbnail in a list
  // would cost a frame.
  static Future<Uint8List> _seal(Uint8List clear, Uint8List key) =>
      Isolate.run(() async {
        final algorithm = AesGcm.with256bits();
        final box = await algorithm.encrypt(
          clear,
          secretKey: SecretKey(key),
          nonce: algorithm.newNonce(),
        );
        return (BytesBuilder(copy: false)
              ..add(_magic)
              ..add(box.nonce)
              ..add(box.cipherText)
              ..add(box.mac.bytes))
            .takeBytes();
      });

  static Future<Uint8List?> _open(Uint8List sealed, Uint8List key) =>
      Isolate.run(() async {
        final body = sealed.length - _macLength;
        final nonceEnd = _magic.length + _nonceLength;
        try {
          final clear = await AesGcm.with256bits().decrypt(
            SecretBox(
              Uint8List.sublistView(sealed, nonceEnd, body),
              nonce: Uint8List.sublistView(sealed, _magic.length, nonceEnd),
              mac: Mac(Uint8List.sublistView(sealed, body)),
            ),
            secretKey: SecretKey(key),
          );
          return Uint8List.fromList(clear);
        } on SecretBoxAuthenticationError {
          // Another installation's key, or a damaged file.
          return null;
        }
      });
}
