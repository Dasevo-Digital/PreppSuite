import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlite3/sqlite3.dart' show sqlite3;

import 'app_database_directory.dart';
import 'portable_data.dart';

/// The database files whose contents belong to the household.
///
/// Archive indexes are derived data, but can hold searchable text from a
/// personal document.  They use the same directory and are included when an
/// existing installation is upgraded.
const localDatabaseFilePrefix = 'preppsuite';
const _databaseExtension = '.sqlite';
const _sqliteHeader = 'SQLite format 3\u0000';

/// The two files a migration can leave beside a database.
///
/// They are named rather than hidden so that an interrupted upgrade is
/// something a person can see in the data folder and hand to somebody.
const _recoverySuffix = '.plaintext-recovery';
const _encryptingSuffix = '.encrypting';

enum LocalDatabaseEncryptionMode { plaintext, encrypted, recoveryRequired }

/// This installation holds databases it cannot open.
///
/// A type of its own rather than a `StateError`, so that the screens can
/// say what it is. It reaches a screen only where something opened a
/// database without going past `LocalDataGate` first, and "an unexpected
/// error occurred" would be the least useful true sentence available.
class LocalDataUnavailable implements Exception {
  const LocalDataUnavailable();
}

/// The databases are being replaced right now, by the encryption upgrade.
class LocalDataBusy implements Exception {
  const LocalDataBusy();
}

/// Secure storage is deliberately a narrow interface.  It lets migration
/// tests exercise lost-key and interrupted-upgrade paths without a platform
/// keychain, and keeps the 256-bit database key out of preferences and logs.
abstract interface class LocalDatabaseKeyStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureLocalDatabaseKeyStorage implements LocalDatabaseKeyStorage {
  const SecureLocalDatabaseKeyStorage([
    this._storage = const FlutterSecureStorage(),
  ]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Startup state for the at-rest encryption migration.
///
/// A new household gets an encrypted database from its first write.  An
/// existing household remains readable in transitional mode until it has made
/// a backup and explicitly starts the upgrade in Settings.  This distinction
/// avoids the destructive failure mode where an interrupted app update leaves
/// existing data behind a new key without a recoverable copy.
class LocalDatabaseEncryption {
  LocalDatabaseEncryption({LocalDatabaseKeyStorage? storage})
    : _storage = storage ?? const SecureLocalDatabaseKeyStorage();

  /// The app's one instance.
  ///
  /// Settable so that a test can install one with a key in it: the stores
  /// that keep private values reach this through `PrivatePreferences`
  /// rather than being handed an instance, and a device keychain is not
  /// something a test has. Nothing in the app assigns to it.
  static LocalDatabaseEncryption instance = LocalDatabaseEncryption();

  static const _modeKey = 'preppsuite.localDatabaseEncryption.mode.v1';
  static const _keyKey = 'preppsuite.localDatabaseEncryption.key.v1';

  final LocalDatabaseKeyStorage _storage;
  Directory? _directory;
  LocalDatabaseEncryptionMode? _mode;
  String? _key;
  bool _migrating = false;

  /// True while database files are being swapped underneath.
  bool get isMigrating => _migrating;

  LocalDatabaseEncryptionMode get mode {
    final value = _mode;
    if (value == null) {
      throw StateError('Local database encryption has not been initialized.');
    }
    return value;
  }

  bool get isInitialized => _mode != null;

  /// The raw data key, for deriving other local keys from.
  ///
  /// Null when this installation has none -- a device without a key store,
  /// or one waiting for recovery. Callers derive a key of their own from
  /// this with a label of their own (see `private_preferences.dart`) and
  /// never store what they derived: one secret leaking must not hand over
  /// the others.
  Uint8List? get dataKeyBytes {
    final key = _key;
    if (key == null) return null;
    try {
      return base64Url.decode(key);
    } on FormatException {
      return null;
    }
  }

  bool get isEncrypted => mode == LocalDatabaseEncryptionMode.encrypted;

  /// Whether an upgrade can still be started or resumed.
  ///
  /// Also true once the mode is `encrypted`: a migration that stopped part
  /// way through leaves readable plaintext files behind, and the way to
  /// finish them is to run it again.  Use [pendingPlaintextDatabases] to
  /// find out whether there is anything left to do.
  bool get canMigrate =>
      mode != LocalDatabaseEncryptionMode.recoveryRequired &&
      !portableLocation.isPortable;

  /// True only when the bundled SQLite library exposes a cipher. A PRAGMA key
  /// is silently ignored by ordinary SQLite, so this check prevents a build
  /// configuration error from pretending that it encrypted a household.
  static bool get cipherAvailable => _cipherAvailable ??= _probeCipher();
  static bool? _cipherAvailable;

  static bool _probeCipher() {
    final database = sqlite3.openInMemory();
    try {
      return database.select('PRAGMA cipher').isNotEmpty;
    } on Object {
      return false;
    } finally {
      database.close();
    }
  }

  /// Must run before a database is opened.  It is safe to call repeatedly,
  /// including from the Android/iOS background warning isolate.
  Future<void> initialize({Directory? directory}) async {
    if (_mode != null) return;

    final resolvedDirectory = directory ?? await appDatabaseDirectory();
    _directory = resolvedDirectory;
    final savedMode = await _storage.read(_modeKey);

    if (savedMode == 'migrating') {
      await _recoverInterruptedMigration(resolvedDirectory);
    }

    final effectiveMode = await _storage.read(_modeKey);
    switch (effectiveMode) {
      case 'encrypted':
        final key = await _storage.read(_keyKey);
        if (_isValidKey(key) && cipherAvailable) {
          _key = key;
          _mode = LocalDatabaseEncryptionMode.encrypted;
        } else {
          _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        }
      case 'plaintext':
        _key = await _storage.read(_keyKey);
        _mode = LocalDatabaseEncryptionMode.plaintext;
      case 'recoveryRequired':
        _mode = LocalDatabaseEncryptionMode.recoveryRequired;
      default:
        if (await _holdsEncryptedDatabase(resolvedDirectory)) {
          // Nothing here says how to open this, and the files say they
          // are encrypted. The ordinary way to arrive at that is a folder
          // carried to a second computer, or an installation restored
          // without its keychain. Opening them plainly would fail one
          // screen later with SQLite's own words.
          _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        } else if (portableLocation.isPortable ||
            await _hasExistingDatabases(resolvedDirectory)) {
          // A carried folder is never encrypted on its own: the key would
          // stay behind on this machine and the folder would open nowhere
          // else.
          await _storage.write(_modeKey, 'plaintext');
          _mode = LocalDatabaseEncryptionMode.plaintext;
        } else {
          _key = await _createAndStoreKey();
          if (cipherAvailable) {
            await _storage.write(_modeKey, 'encrypted');
            _mode = LocalDatabaseEncryptionMode.encrypted;
          } else {
            // Retain the key in device secure storage for the compatible
            // release, but never label a plaintext file as encrypted.
            await _storage.write(_modeKey, 'plaintext');
            _mode = LocalDatabaseEncryptionMode.plaintext;
          }
        }
    }
  }

  /// Establishes a state even where the device refuses to answer.
  ///
  /// A key store can be unreachable: a Linux session without a keyring, a
  /// keychain that has not been unlocked yet, a plugin that failed to
  /// load. That must not keep the app from starting at all -- this is the
  /// app somebody opens when something is already wrong, and a window
  /// that never appears is the worst of the available answers. It comes
  /// up in recovery instead, which is a screen that explains itself.
  Future<void> initializeOrMarkUnavailable({Directory? directory}) async {
    try {
      await initialize(directory: directory);
    } on Object {
      if (_mode != null) return;

      // What a missing key store means depends entirely on what is on the
      // disk. With an encrypted database in the folder it means a locked
      // household and there is nothing to do but say so. With nothing, or
      // with plain files, it means a device that cannot keep a secret --
      // a Linux session without `libsecret`, a keychain that never came
      // up. Refusing to start there would take a working offline app away
      // from somebody over a key it does not need yet. It runs
      // unencrypted, and the settings card says so in those words.
      final folder = _directory;
      try {
        _mode = folder == null || await _holdsEncryptedDatabase(folder)
            ? LocalDatabaseEncryptionMode.recoveryRequired
            : LocalDatabaseEncryptionMode.plaintext;
      } on Object {
        // This is the last line of defence for startup.  A failing platform
        // key store can coincide with a temporarily inaccessible application
        // folder (for example while a macOS container is first created).
        // Keep the app visible and protect the household until its state can
        // be checked again; never turn an infrastructure failure into a
        // blank window before runApp().
        _mode = LocalDatabaseEncryptionMode.recoveryRequired;
      }
    }
  }

  static Future<bool> _holdsEncryptedDatabase(Directory directory) async {
    for (final file in await _databaseBaseFiles(directory)) {
      if (await _isEncryptedFile(file)) return true;
    }
    return false;
  }

  /// Asks the device again, for a key store that may have come back.
  ///
  /// A keyring started after the app, a keychain unlocked on the second
  /// attempt, a device restored mid-session: all of them are reasons why
  /// the answer at startup need not be the final one, and none of them is
  /// worth making somebody restart to find out.
  Future<void> retryInitialization({Directory? directory}) async {
    _mode = null;
    _key = null;
    await initializeOrMarkUnavailable(directory: directory ?? _directory);
  }

  /// Moves databases this installation cannot open aside and starts over.
  ///
  /// Nothing is deleted. Each file keeps its own name with `.locked-` and
  /// a timestamp appended, so a key that turns up later -- a restored
  /// keychain, a device that comes back -- still has something to open.
  /// What this buys is a usable app today, and something to restore a
  /// backup into.
  Future<void> startOverKeepingUnreadableFiles() async {
    final directory = _directory;
    if (directory == null) return;
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    for (final base in await _databaseBaseFiles(directory)) {
      for (final file in [
        base,
        File('${base.path}$_recoverySuffix'),
        File('${base.path}$_encryptingSuffix'),
        File('${base.path}-wal'),
        File('${base.path}-shm'),
      ]) {
        if (await file.exists()) {
          await file.rename('${file.path}.locked-$stamp');
        }
      }
    }
    // A key store that cannot be read usually cannot be written either,
    // and that must not stop the files from being moved out of the way --
    // the whole point of this is to get somebody a usable app back.
    try {
      await _storage.delete(_modeKey);
      await _storage.delete(_keyKey);
    } on Object {
      // Nothing to clear if the device will not talk to us.
    }
    _mode = null;
    _key = null;
    await initializeOrMarkUnavailable(directory: directory);
  }

  /// Opens [name].sqlite after [initialize] has established its mode.
  ///
  /// The key is captured as an immutable String by the setup callback, which
  /// Drift transfers to its background isolate.  The callback never consults
  /// secure storage there, so it also works for background warning polls.
  QueryExecutor open(String name) {
    final directory = _directory;
    if (directory == null || _mode == null) {
      throw StateError('Local database encryption has not been initialized.');
    }
    if (_mode == LocalDatabaseEncryptionMode.recoveryRequired) {
      throw const LocalDataUnavailable();
    }
    // Nothing may open a file that is being replaced under a rename. A
    // connection made now would keep the old file alive after the swap and
    // write into something that is about to be deleted -- silently, and
    // only for the rows somebody added in those seconds. Failing loudly is
    // the cheaper of the two.
    if (_migrating) {
      throw const LocalDataBusy();
    }

    final file = File(
      '${directory.path}${Platform.pathSeparator}$name$_databaseExtension',
    );
    final key = _key;
    if (_mode == LocalDatabaseEncryptionMode.encrypted && key != null) {
      final path = file.path;
      return NativeDatabase.createInBackground(
        file,
        setup: (database) => _configureCipherForFile(database, path, key),
      );
    }
    return NativeDatabase.createInBackground(file);
  }

  /// The databases that still hold readable plaintext.
  ///
  /// Empty once an upgrade has finished.  A non-empty list after a migration
  /// is not damage — those files open normally — but it is the honest answer
  /// to "is my data encrypted", and the reason the settings card can offer to
  /// carry on.
  Future<List<String>> pendingPlaintextDatabases() async {
    final directory = _directory;
    if (directory == null) return const [];
    final pending = <String>[];
    for (final file in await _databaseBaseFiles(directory)) {
      if (!await file.exists()) continue;
      if (await _isEncryptedFile(file)) continue;
      final name = file.uri.pathSegments.last;
      pending.add(name.substring(0, name.length - _databaseExtension.length));
    }
    pending.sort();
    return pending;
  }

  /// Encrypts every PreppSuite database file that is still plaintext.
  ///
  /// Call only after an independent backup was successfully written.  Each
  /// file is copied with `VACUUM INTO`, encrypted in a sibling temporary file,
  /// and then swapped.  A process interruption leaves either the untouched
  /// plaintext original or an explicit `.plaintext-recovery` file; startup
  /// restores the readable version before any database is opened.
  ///
  /// Running it again after an interruption resumes where it stopped: files
  /// that are already encrypted are skipped, and the key is the one already
  /// in secure storage.  Generating a second key here would orphan whatever
  /// the first run had encrypted.
  Future<void> migrateExistingDatabases() async {
    if (!canMigrate) return;
    if (!cipherAvailable) {
      throw UnsupportedError(
        'The bundled SQLite library has no encryption cipher.',
      );
    }
    // Set before anything is touched, including the key: from here on no
    // part of the app may open one of these files.
    _migrating = true;
    final directory = _directory!;
    final key = _key ?? await _storedKey() ?? await _createAndStoreKey();
    if (_key == null) await _storage.write(_keyKey, key);
    await _storage.write(_modeKey, 'migrating');

    try {
      for (final file in await _databaseBaseFiles(directory)) {
        if (!await file.exists()) continue;
        if (await _isEncryptedFile(file)) continue;
        await _encryptFile(file, key);
      }
      await _storage.write(_modeKey, 'encrypted');
      _key = key;
      _mode = LocalDatabaseEncryptionMode.encrypted;
    } catch (_) {
      // Whatever went wrong, the folder must be left in a state the next
      // start can read.  A failure to tidy up must not replace the reason
      // the migration stopped.
      try {
        await _recoverInterruptedMigration(directory);
        // And take the result on: recovery decides what the folder now is,
        // and this object was still carrying what it was before the run.
        // Holding `plaintext` over a folder that is half encrypted would
        // open the encrypted half without a key -- the very state the
        // recovery just went to the trouble of making readable.
        _mode = null;
        _key = null;
        await initialize(directory: directory);
      } on Object {
        // Deliberately ignored; the original error is the one that matters.
      }
      rethrow;
    } finally {
      _migrating = false;
    }
  }

  Future<String?> _storedKey() async {
    final stored = await _storage.read(_keyKey);
    return _isValidKey(stored) ? stored : null;
  }

  Future<String> _createAndStoreKey() async {
    final random = Random.secure();
    final bytes = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final key = base64UrlEncode(bytes);
    await _storage.write(_keyKey, key);
    return key;
  }

  static bool _isValidKey(String? value) {
    if (value == null) return false;
    try {
      return base64Url.decode(value).length == 32;
    } on FormatException {
      return false;
    }
  }

  Future<bool> _hasExistingDatabases(Directory directory) async =>
      (await _databaseBaseFiles(directory)).isNotEmpty;

  /// Every database this installation owns, named by the file it would have
  /// when nothing is in flight.
  ///
  /// A migration renames files, so a listing of what happens to be called
  /// `.sqlite` right now is not the same question.  The two migration
  /// suffixes are folded back onto the name they belong to, which is what
  /// makes an interrupted upgrade recoverable at all: in the moment between
  /// the two renames the database exists under neither its own name nor any
  /// name ending in `.sqlite`.
  static Future<List<File>> _databaseBaseFiles(Directory directory) async {
    if (!await directory.exists()) return const [];
    final paths = <String>{};
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (!name.startsWith(localDatabaseFilePrefix)) continue;
      final path = entity.path;
      if (name.endsWith(_databaseExtension)) {
        paths.add(path);
      } else if (name.endsWith('$_databaseExtension$_recoverySuffix')) {
        paths.add(path.substring(0, path.length - _recoverySuffix.length));
      } else if (name.endsWith('$_databaseExtension$_encryptingSuffix')) {
        paths.add(path.substring(0, path.length - _encryptingSuffix.length));
      }
    }
    final files = [for (final path in paths) File(path)];
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Rewrites one database encrypted.
  ///
  /// On its own isolate: `VACUUM INTO` copies the whole file, and the
  /// knowledge indexes can be gigabytes.  On the UI isolate that is a frozen
  /// app for as long as it takes, on a screen that is telling somebody not
  /// to close it.
  static Future<void> _encryptFile(File source, String key) async {
    final path = source.path;
    await Isolate.run(() => _encryptFileSync(path, key));
  }

  Future<void> _recoverInterruptedMigration(Directory directory) async {
    var encrypted = 0;
    for (final base in await _databaseBaseFiles(directory)) {
      final recovery = File('${base.path}$_recoverySuffix');
      final temporary = File('${base.path}$_encryptingSuffix');

      if (await base.exists() && await _isEncryptedFile(base)) {
        // The swap completed for this file.  The journals beside it were
        // written for the plaintext database that has just been renamed
        // away, and SQLite would read them against the wrong file.
        encrypted++;
        await _deleteJournals(base);
        if (await recovery.exists()) await recovery.delete();
        if (await temporary.exists()) await temporary.delete();
        continue;
      }

      // Anything else: the readable copy is the plaintext one.  It is either
      // still in place, or it was renamed aside and the process stopped
      // before the encrypted file took its name.
      if (!await base.exists() && await recovery.exists()) {
        await recovery.rename(base.path);
      }
      if (await temporary.exists()) await temporary.delete();
    }

    // A half-finished run leaves both kinds of file in the folder.  That is
    // recoverable as long as the key is there -- `open` decides per file --
    // but claiming `encrypted` without a key would hide a household behind
    // something nobody has.
    final usable = _isValidKey(await _storage.read(_keyKey)) && cipherAvailable;
    await _storage.write(
      _modeKey,
      encrypted == 0
          ? 'plaintext'
          : usable
          ? 'encrypted'
          : 'recoveryRequired',
    );
  }

  static Future<void> _deleteJournals(File database) async {
    for (final suffix in ['-wal', '-shm']) {
      final journal = File('${database.path}$suffix');
      if (await journal.exists()) await journal.delete();
    }
  }

  static Future<bool> _isEncryptedFile(File file) async {
    if (!await file.exists()) return false;
    final handle = await file.open();
    try {
      final bytes = await handle.read(_sqliteHeader.length);
      return bytes.length == _sqliteHeader.length &&
          utf8.decode(bytes, allowMalformed: true) != _sqliteHeader;
    } finally {
      await handle.close();
    }
  }
}

/// The blocking half of [LocalDatabaseEncryption._encryptFile], written so
/// that everything it touches is a String and it can run on its own isolate.
void _encryptFileSync(String path, String key) {
  final source = File(path);
  final temporary = File('$path$_encryptingSuffix');
  final recovery = File('$path$_recoverySuffix');
  if (temporary.existsSync()) temporary.deleteSync();

  final sourceDatabase = sqlite3.open(path);
  try {
    sourceDatabase.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    sourceDatabase.execute('VACUUM INTO ${_sqlLiteral(temporary.path)}');
  } finally {
    sourceDatabase.close();
  }

  // `PRAGMA key` announces that the file already is encrypted, and on a
  // plaintext one it leaves nothing readable behind -- not even for the
  // rekey that was meant to encrypt it. The copy is opened plainly, the
  // cipher is only selected, and `PRAGMA rekey` does the encrypting.
  final encrypting = sqlite3.open(temporary.path);
  try {
    encrypting.execute("PRAGMA cipher = 'aes256cbc'");
    encrypting.execute('PRAGMA rekey = ${_sqlLiteral(key)}');
  } finally {
    encrypting.close();
  }

  // Read it back through the same door the app will use. An encrypted file
  // that cannot be opened with the key is worse than no migration at all,
  // and this is the last moment where the plaintext original is still the
  // file under its own name.
  final verify = sqlite3.open(temporary.path);
  try {
    _configureCipher(verify, key);
    verify.select('SELECT count(*) FROM sqlite_master').first;
  } finally {
    verify.close();
  }

  if (recovery.existsSync()) recovery.deleteSync();
  source.renameSync(recovery.path);
  temporary.renameSync(path);
  recovery.deleteSync();
  for (final suffix in ['-wal', '-shm']) {
    final journal = File('$path$suffix');
    if (journal.existsSync()) journal.deleteSync();
  }
}

/// Applies the key to everything except a file that is readable plaintext.
///
/// A `PRAGMA key` on a plaintext database does not leave it readable -- it
/// fails to open at all.  Deciding per file rather than per installation is
/// what keeps a half-finished migration harmless: the encrypted files open
/// with the key, the ones it did not reach yet open without it, and a file
/// that does not exist yet is created encrypted.
void _configureCipherForFile(dynamic database, String path, String key) {
  if (_isPlaintextFileSync(File(path))) return;
  _configureCipher(database, key);
}

bool _isPlaintextFileSync(File file) {
  try {
    final handle = file.openSync();
    try {
      final bytes = handle.readSync(_sqliteHeader.length);
      return bytes.length == _sqliteHeader.length &&
          utf8.decode(bytes, allowMalformed: true) == _sqliteHeader;
    } finally {
      handle.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

void _configureCipher(dynamic database, String key) {
  // SQLite3MultipleCiphers uses aes256cbc as its supported default cipher;
  // setting it explicitly makes a future library default change harmless.
  database.execute("PRAGMA cipher = 'aes256cbc'");
  database.execute('PRAGMA key = ${_sqlLiteral(key)}');
}

String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";
