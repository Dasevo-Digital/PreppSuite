import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/sharing/application/folder_crypto.dart';
import 'local_database_encryption.dart';
import 'portable_data.dart';

/// Preferences that hold something about the household rather than about
/// the app's operation.
///
/// The databases are encrypted at rest; the values beside them were not,
/// and some of them are the more interesting half: where somebody lives,
/// who they would call, the key to their shared folder. A copied data
/// folder gave all of that away while the database it sat next to gave
/// away nothing.
///
/// Values go in as an AES-GCM envelope under a key derived from the local
/// data key. Language, theme and the rest stay readable on purpose -- the
/// app has to be able to draw a screen before it has opened anything.
///
/// Three properties make this safe to put underneath stores that already
/// exist:
///
/// * Reading accepts both forms. A value written by an older version is
///   still plain text, and it is returned as it is rather than as a
///   failure.
/// * A plain value read while a key exists is written back encrypted. The
///   migration is the normal use of the app; there is no step to run and
///   none to interrupt.
/// * Without a key -- a device with no key store, an installation waiting
///   for recovery -- values are written plainly, as before. Refusing to
///   store somebody's warning region because the keyring is missing would
///   be a worse answer than storing it the way it was stored yesterday.
class PrivatePreferences {
  const PrivatePreferences([this._encryption]);

  final LocalDatabaseEncryption? _encryption;

  LocalDatabaseEncryption get _source =>
      _encryption ?? LocalDatabaseEncryption.instance;

  /// Derived rather than used directly: the data key opens the databases,
  /// and a key that opens two different things is one mistake away from
  /// opening both.
  static const _label = 'preppsuite.privatePreferences.v1';

  static Uint8List? _derivedFrom;
  static FolderKey? _derived;
  static final _pending = <String, Future<void>>{};

  // A read can migrate an old value. It must share the same order as
  // edits and deletion, including calls from another store instance.
  Future<T> _serialized<T>(String key, Future<T> Function() action) {
    final previous = _pending[key];
    final result = previous == null
        ? Future<T>.sync(action)
        : previous.then((_) => action());
    final queued = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    _pending[key] = queued;
    return result.whenComplete(() {
      if (identical(_pending[key], queued)) _pending.remove(key);
    });
  }

  Future<FolderKey?> _key() async {
    // A carried folder travels to another computer; the key does not, it
    // sits in this machine's keychain. Sealing the settings here would
    // make them unreadable on the very next computer -- which is the one
    // thing a carried folder exists for. See the migration document: a
    // portable vault would have to be passphrase-based and is a format of
    // its own, not this key under another name.
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
    final key = FolderKey(Uint8List.fromList(await secret.extractBytes()));
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

  Future<String?> getString(String key, {SharedPreferences? preferences}) =>
      _serialized(
        key,
        () async => _readString(
          key,
          preferences ?? await SharedPreferences.getInstance(),
        ),
      );

  Future<String?> _readString(String key, SharedPreferences prefs) async {
    final stored = prefs.getString(key);
    if (stored == null) return null;
    final folderKey = await _key();
    if (readEnvelope(stored) == null) {
      if (folderKey != null) {
        final sealed = await encryptForFolder(stored, folderKey);
        // Also tolerate a legacy caller clearing raw preferences while
        // the key was being derived. Migration must not recreate its data.
        if (prefs.getString(key) == stored) await prefs.setString(key, sealed);
      }
      return stored;
    }
    if (folderKey == null) return null;
    return decryptFromFolder(stored, folderKey);
  }

  Future<void> setString(
    String key,
    String value, {
    SharedPreferences? preferences,
  }) => _serialized(key, () async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    await _writeString(key, value, prefs);
  });

  Future<void> _writeString(
    String key,
    String? value,
    SharedPreferences prefs,
  ) async {
    final folderKey = await _key();
    final stored = value == null || folderKey == null
        ? value
        : await encryptForFolder(value, folderKey);
    await _persistString(key, stored, prefs);
  }

  Future<void> _persistString(
    String key,
    String? value,
    SharedPreferences prefs,
  ) async {
    try {
      final saved = value == null
          ? await prefs.remove(key)
          : await prefs.setString(key, value);
      if (!saved) throw StateError('Preference write failed');
    } catch (_) {
      // shared_preferences updates its cache before the backend answers.
      // A failed write must not become the next edit's phantom baseline.
      try {
        await prefs.reload();
      } catch (_) {
        /* Preserve the write error. */
      }
      rethrow;
    }
  }

  /// The whole edit shares the key's queue, including writers in another
  /// store and a backup restore. A lock around setString alone loses edits.
  Future<String?> updateString(
    String key,
    String? Function(String? current) update,
  ) => _serialized(key, () async {
    final prefs = await SharedPreferences.getInstance();
    final value = update(await _readString(key, prefs));
    await _writeString(key, value, prefs);
    return value;
  });

  /// Refuse a received value if a local edit landed while it was being
  /// decrypted or sealed. Check after encryption, immediately before writing.
  Future<bool> compareAndSetString(
    String key, {
    required Object? expectedStored,
    required String? value,
    required SharedPreferences preferences,
  }) => _serialized(key, () async {
    final folderKey = await _key();
    final stored = value == null || folderKey == null
        ? value
        : await encryptForFolder(value, folderKey);
    if (preferences.get(key) != expectedStored) return false;
    await _persistString(key, stored, preferences);
    return true;
  });

  /// A list is one encrypted string so the envelope covers its length too.
  Future<List<String>?> getStringList(
    String key, {
    SharedPreferences? preferences,
  }) => _serialized(key, () async {
    final prefs = preferences ?? await SharedPreferences.getInstance();
    final legacy = _stringListOrNull(prefs, key);
    if (legacy != null) {
      final folderKey = await _key();
      if (folderKey != null) {
        final sealed = await encryptForFolder(jsonEncode(legacy), folderKey);
        final current = _stringListOrNull(prefs, key);
        if (current != null && _sameStrings(legacy, current)) {
          await prefs.setString(key, sealed);
        }
      }
      return legacy;
    }
    final stored = await _readString(key, prefs);
    if (stored == null) return null;
    try {
      final decoded = jsonDecode(stored);
      return decoded is List ? [for (final item in decoded) '$item'] : null;
    } on FormatException {
      return null;
    }
  });

  Future<void> setStringList(String key, List<String> value) =>
      setString(key, jsonEncode(value));

  static bool _sameStrings(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<String>? _stringListOrNull(SharedPreferences prefs, String key) {
    try {
      return prefs.getStringList(key);
    } on Object {
      return null;
    }
  }

  Future<void> remove(String key) => _serialized(key, () async {
    final prefs = await SharedPreferences.getInstance();
    await _persistString(key, null, prefs);
  });

  Future<bool> containsKey(String key) => _serialized(key, () async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(key);
  });

  /// Forgets the derived key. Only for tests and for a device that has
  /// just been given a different data key.
  static void forgetDerivedKey() {
    _derivedFrom = null;
    _derived = null;
  }
}
