import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqlite3/sqlite3.dart'
    show Database, OpenMode, SqliteException, sqlite3;

import 'app_database_directory.dart';
import 'error_log.dart';
import 'secure_storage.dart';
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

/// The cipher every encrypted database is created with (#419).
///
/// ChaCha20-Poly1305, SQLite3MultipleCiphers' own default. Every page
/// carries a tag, so a page that changed on the disk -- a flipped bit, a
/// torn write -- is reported as damage rather than read as data.
const _cipher = 'chacha20';

/// What 3.0.3 and earlier encrypted with, still read.
///
/// AES-256 in CBC mode keeps no tag: a changed page decrypts to other
/// contents, and even `PRAGMA integrity_check` said ok. The household's
/// own databases are moved off it at the next start
/// ([LocalDatabaseEncryption._upgradeCipher]); a knowledge index keeps it
/// until it is rebuilt.
const _legacyCipher = 'aes256cbc';

/// The two files the move to chacha20 can leave beside a database: the
/// copy being re-encrypted, and the aes256cbc original, kept until the
/// copy has opened under its name.
const _rekeyingSuffix = '.rekeying';
const _legacyRecoverySuffix = '.aes256cbc-recovery';

/// Every name a migration gives a database while it is in flight.
const _inFlightSuffixes = [
  _recoverySuffix,
  _encryptingSuffix,
  _rekeyingSuffix,
  _legacyRecoverySuffix,
];

/// The lock beside the databases (see [_UseLock]). Not called
/// `preppsuite…`: nothing that lists the databases may take it for one.
const _useLockName = '.preppsuite-in-use';

/// A knowledge index: derived from a public archive, and gigabytes.
bool _isKnowledgeIndex(File file) =>
    file.uri.pathSegments.last.startsWith('preppsuite_knowledge');

enum LocalDatabaseEncryptionMode { plaintext, encrypted, recoveryRequired }

/// What [LocalDatabaseEncryption.readInstallationKey] found.
typedef InstallationKey = ({String? key, bool upgrading});

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
  const SecureLocalDatabaseKeyStorage([this._storage = appSecureStorage]);

  final FlutterSecureStorage _storage;

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  /// Swallowed here, and deliberately not in `app_lock.dart`.
  ///
  /// The asymmetry is the point. A lock whose state cannot be read must
  /// never read as "no lock", because that opens the app. A *key* that
  /// cannot be read reads as "no key", and what that means is then
  /// decided by the files on the disk: encrypted ones without a key end
  /// in recovery, plain ones simply stay plain. Nothing is opened that
  /// should have stayed shut, and the app starts.
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

/// Startup state for the at-rest encryption migration.
///
/// A new household gets an encrypted database from its first write.  An
/// existing household remains readable in transitional mode until it has made
/// a backup and explicitly starts the upgrade in Settings.  This distinction
/// avoids the destructive failure mode where an interrupted app update leaves
/// existing data behind a new key without a recoverable copy.
class LocalDatabaseEncryption {
  LocalDatabaseEncryption({
    LocalDatabaseKeyStorage? storage,
    this.holdAgainstOtherInstances = false,
    this.upgradeWait = const Duration(seconds: 30),
    @visibleForTesting this.cipherUpgradeStop,
  }) : _storage = storage ?? const SecureLocalDatabaseKeyStorage();

  /// The app's one instance.
  ///
  /// Settable so that a test can install one with a key in it: the stores
  /// that keep private values reach this through `PrivatePreferences`
  /// rather than being handed an instance, and a device keychain is not
  /// something a test has. Nothing in the app assigns to it.
  static LocalDatabaseEncryption instance = LocalDatabaseEncryption(
    holdAgainstOtherInstances:
        Platform.isMacOS || Platform.isLinux || Platform.isWindows,
  );

  static const _modeKey = 'preppsuite.localDatabaseEncryption.mode.v1';
  static const _keyKey = 'preppsuite.localDatabaseEncryption.key.v1';

  /// Whether this instance keeps the databases from being re-encrypted by
  /// another instance of the app for as long as it runs (#419).
  ///
  /// On a desktop a second window is a second process with the same
  /// files. Its start must neither move a file another one has open, nor
  /// open one while another start is moving it. A telephone has one
  /// process; the background poll there holds the files for its run
  /// instead (see [initialize]).
  final bool holdAgainstOtherInstances;

  /// How long a background run, or a second window, waits for a start
  /// that is re-encrypting a database: the run then gives up with
  /// [LocalDataBusy], the window comes up in recovery, where "try again"
  /// asks once more.
  final Duration upgradeWait;

  /// For tests: called after each step of the move to chacha20 with the
  /// database and the step. Answering true stops there as if the process
  /// had ended, and throwing fails the step. Runs the move on this isolate.
  final bool Function(String path, String step)? cipherUpgradeStop;

  final LocalDatabaseKeyStorage _storage;
  Directory? _directory;
  LocalDatabaseEncryptionMode? _mode;
  String? _key;
  bool _migrating = false;

  /// Set once [open] has handed out a connection. From then on a file can
  /// be held open by this process, and none may be moved at a start.
  bool _opened = false;
  _UseLock? _runHold;
  _UseLock? _instanceHold;

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
  ///
  /// With a carried folder this is the key of this computer's
  /// installation, for opening what an earlier version sealed in the
  /// folder with it. Nothing new is sealed there (#392).
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

  /// Whether this installation can actually keep a key.
  ///
  /// Not "is there one" — whether the platform will take one at all. On
  /// macOS the key store belongs to the signed application, and a build
  /// without a certificate is refused; the app then works, unencrypted,
  /// and the settings card has to be able to say why rather than offering
  /// an upgrade that fails at its first step.
  ///
  /// Probed by writing a throwaway value and reading it back, because
  /// asking is not the same as being allowed: the writes appear to
  /// succeed on some platforms and nothing comes back.
  Future<bool> keyStoreAccepts() async {
    const probeKey = 'preppsuite.localDatabaseEncryption.probe.v1';
    final token = base64UrlEncode(
      List<int>.generate(8, (_) => Random.secure().nextInt(256)),
    );
    try {
      await _storage.write(probeKey, token);
      final back = await _storage.read(probeKey);
      await _storage.delete(probeKey);
      return back == token;
    } on Object {
      return false;
    }
  }

  /// Must run before a database is opened.  It is safe to call repeatedly.
  ///
  /// The background warning isolate passes [repairInterruptedMigration]
  /// false, and gets [LocalDataBusy] where a migration is marked as running
  /// (#334). From another isolate a migration in progress looks exactly
  /// like one that was interrupted, and the repair deletes the copy being
  /// written: the migration then went on with a new, empty file under that
  /// name, passed its check and replaced the household with it. Only the
  /// app's own start may repair, because only there can nothing else be
  /// running.
  ///
  /// The app's start also moves the household's own databases from
  /// aes256cbc to chacha20, once (#419; see [_upgradeCipher]). It does so
  /// only while it holds the lock beside the databases alone, and before
  /// this process has opened any of them. The background run holds that
  /// lock shared until [finishBackgroundRun]: a start that finds it held
  /// leaves the files as they are for this time, and a background run
  /// that finds a start moving them gets [LocalDataBusy] after
  /// [upgradeWait]. A connection left open across the move would write
  /// into the original after the swap, and its journal, which SQLite
  /// finds by name, would lie beside the new file.
  Future<void> initialize({
    Directory? directory,
    bool repairInterruptedMigration = true,
  }) async {
    if (!repairInterruptedMigration) await _holdForRun(directory);
    if (_mode != null) return;

    final resolvedDirectory = directory ?? await appDatabaseDirectory();
    _directory = resolvedDirectory;
    if (portableLocation.isPortable) {
      await _initializeCarried(resolvedDirectory);
      return;
    }

    _UseLock? alone;
    if (repairInterruptedMigration &&
        !_opened &&
        (holdAgainstOtherInstances ||
            await _cipherUpgradeDue(resolvedDirectory))) {
      _releaseInstanceHold();
      alone = _UseLock.exclusive(resolvedDirectory);
    }
    try {
      // Another window may be moving the files right now: this one waits
      // until it is done rather than open one in the middle.
      if (alone == null && !await _holdForInstance(resolvedDirectory)) {
        _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        return;
      }
      if (alone != null) await _settleCipherUpgrade(resolvedDirectory);
      await _initializeInstallation(
        resolvedDirectory,
        repairInterruptedMigration: repairInterruptedMigration,
      );
      final key = _key;
      if (alone != null &&
          key != null &&
          _mode == LocalDatabaseEncryptionMode.encrypted) {
        await _upgradeCipher(resolvedDirectory, key);
      }
    } finally {
      alone?.release();
    }
    if (alone != null && !await _holdForInstance(resolvedDirectory)) {
      _mode = LocalDatabaseEncryptionMode.recoveryRequired;
    }
  }

  /// Everything [initialize] decides for an installation, as before #419.
  Future<void> _initializeInstallation(
    Directory resolvedDirectory, {
    required bool repairInterruptedMigration,
  }) async {
    final savedMode = await _storage.read(_modeKey);
    final interrupted = savedMode == 'migrating';

    // A copy left beside a database that is not there is a migration
    // that stopped between its renames, whatever the key store says
    // (#393): the marker can be gone while the household still lies under
    // the copy's name.
    if (interrupted || await _hasStrandedCopies(resolvedDirectory)) {
      if (!repairInterruptedMigration) {
        if (interrupted) throw const LocalDataBusy();
        _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        return;
      }
      await _recoverInterruptedMigration(
        resolvedDirectory,
        recordMode: interrupted,
      );
    }
    // What the repair could not put back is still the household. Opening
    // anything beside it would start an empty one under its name.
    if (await _hasStrandedCopies(resolvedDirectory)) {
      _mode = LocalDatabaseEncryptionMode.recoveryRequired;
      return;
    }

    var effectiveMode = interrupted ? await _storage.read(_modeKey) : savedMode;
    // 'plaintext' says how the household that is here was kept. With no
    // database here at all it says nothing, and taken at its word it set
    // up the next household unencrypted: 3.0.3 wrote it from a carried
    // copy into the key store this installation shares (#392). Such a
    // folder starts like a new one.
    if (effectiveMode == 'plaintext' &&
        !await _hasExistingDatabases(resolvedDirectory)) {
      effectiveMode = null;
    }
    switch (effectiveMode) {
      // 'recoveryRequired' is what 3.0.3 and earlier stored after an
      // interrupted upgrade without a readable key (#393). It is read as
      // what it stood for: encrypted files and a key to be looked for
      // again on every start, never a verdict for ever.
      case 'encrypted' || 'recoveryRequired':
        final key = await _storage.read(_keyKey);
        if (_isValidKey(key) && cipherAvailable) {
          _key = key;
          _mode = LocalDatabaseEncryptionMode.encrypted;
          if (effectiveMode == 'recoveryRequired') {
            try {
              await _storage.write(_modeKey, 'encrypted');
            } on Object {
              // Read the same way on the next start.
            }
          }
        } else {
          _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        }
      case 'plaintext':
        _key = await _storage.read(_keyKey);
        _mode = LocalDatabaseEncryptionMode.plaintext;
      default:
        if (await _holdsEncryptedDatabase(resolvedDirectory)) {
          // Nothing here says how to open this, and the files say they
          // are encrypted. The ordinary way to arrive at that is a folder
          // carried to a second computer, or an installation restored
          // without its keychain. Opening them plainly would fail one
          // screen later with SQLite's own words.
          _mode = LocalDatabaseEncryptionMode.recoveryRequired;
        } else if (await _hasExistingDatabases(resolvedDirectory)) {
          // An existing household stays readable until it is upgraded on
          // purpose, after a backup.
          await _storage.write(_modeKey, 'plaintext');
          _mode = LocalDatabaseEncryptionMode.plaintext;
        } else {
          // A key that is still there is taken rather than replaced: it
          // can be the one "start over" could not set aside, and the
          // settings and pictures sealed with it open only with it.
          _key = await _storedKey() ?? await _createAndStoreKey();
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
      //
      // An upgrade that was cut off and could not be repaired just now is
      // not "plain files" either (#393). A rename refused by a virus
      // scanner left the household under its recovery name, and a plain
      // start opened an empty database beside it; the next upgrade then
      // deleted the only copy. It waits in recovery instead, where
      // "try again" runs the repair once more.
      final folder = _directory;
      try {
        _mode =
            folder == null ||
                await _holdsEncryptedDatabase(folder) ||
                await _hasStrandedCopies(folder) ||
                await _markedAsMigrating()
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

  /// How a carried folder is opened: by its own files, never by the mode in
  /// this computer's key store, and nothing is written there (#392).
  ///
  /// That mode is the installation's. Read from here, an installation's
  /// `encrypted` had every new file on the disk created under this
  /// computer's key, so the next computer found the whole disk locked; and
  /// a `plaintext` written from here had the installation set up its next
  /// household unencrypted. Neither the repair of an interrupted upgrade
  /// nor its mark is the folder's business either: an upgrade never runs
  /// on a carried folder.
  ///
  /// The key is read, for what an earlier version encrypted or sealed in
  /// the folder with it. That opens on this computer, and on no other one,
  /// which goes to recovery like any folder that arrives without its key.
  /// New files are never encrypted (see [open]).
  Future<void> _initializeCarried(Directory directory) async {
    _key = await _storedKey();
    if (await _hasStrandedCopies(directory)) {
      _mode = LocalDatabaseEncryptionMode.recoveryRequired;
      return;
    }
    final encrypted = [
      for (final file in await _databaseBaseFiles(directory))
        if (await _isEncryptedFile(file)) file,
    ];
    if (encrypted.isEmpty) {
      _mode = LocalDatabaseEncryptionMode.plaintext;
      return;
    }
    final key = _key;
    _mode =
        key != null &&
            cipherAvailable &&
            encrypted.every((file) => _opensWithKey(file.path, key))
        ? LocalDatabaseEncryptionMode.encrypted
        : LocalDatabaseEncryptionMode.recoveryRequired;
  }

  static Future<bool> _holdsEncryptedDatabase(Directory directory) async {
    for (final file in await _databaseBaseFiles(directory)) {
      if (await _isEncryptedFile(file)) return true;
    }
    return false;
  }

  /// Whether a migration copy lies where its database is missing.
  ///
  /// Between the two renames of an upgrade the household is called
  /// `.plaintext-recovery`, and nothing is called by its own name. A start
  /// that took that for an empty folder created a new database there.
  static Future<bool> _hasStrandedCopies(Directory directory) async {
    for (final base in await _databaseBaseFiles(directory)) {
      if (await base.exists()) continue;
      for (final suffix in _inFlightSuffixes) {
        if (await File('${base.path}$suffix').exists()) return true;
      }
    }
    return false;
  }

  /// Holds the databases shared for a run outside the app's start, the
  /// background poll (#419). Throws [LocalDataBusy] while a start is
  /// moving them to chacha20 after [upgradeWait].
  ///
  /// A lock that cannot be had for another reason -- a folder that is not
  /// there yet, a file that is not a database -- is not a start at work,
  /// and a warning that is not polled for is the worse outcome: the run
  /// goes on without it.
  Future<void> _holdForRun(Directory? directory) async {
    if (_runHold != null || portableLocation.isPortable) return;
    final folder = directory ?? _directory ?? await appDatabaseDirectory();
    final (:lock, :busy) = await _UseLock.shared(folder, wait: upgradeWait);
    if (busy) throw const LocalDataBusy();
    _runHold = lock;
  }

  /// Ends what [initialize] began for a background run: from here on a
  /// start may move the files again. Called once its databases are closed.
  void finishBackgroundRun() {
    _runHold?.release();
    _runHold = null;
  }

  /// Takes the hold of [holdAgainstOtherInstances], waiting for another
  /// instance that is moving the files. False when that took too long: a
  /// file opened now could be swapped under the connection.
  Future<bool> _holdForInstance(Directory directory) async {
    if (!holdAgainstOtherInstances || _instanceHold != null) return true;
    final (:lock, :busy) = await _UseLock.shared(directory, wait: upgradeWait);
    _instanceHold = lock;
    return !busy;
  }

  void _releaseInstanceHold() {
    _instanceHold?.release();
    _instanceHold = null;
  }

  /// Lets go of this instance's hold on the databases, for the quit.
  void releaseForExit() => _releaseInstanceHold();

  /// Whether the start has something to do for #419: a database of the
  /// household's own still written with aes256cbc, or what an interrupted
  /// move left beside one. Asked before the lock is taken, so that an
  /// installation with nothing to move does not take it at all.
  static Future<bool> _cipherUpgradeDue(Directory directory) async {
    for (final base in await _databaseBaseFiles(directory)) {
      if (await File('${base.path}$_rekeyingSuffix').exists() ||
          await File('${base.path}$_legacyRecoverySuffix').exists()) {
        return true;
      }
      if (!_isKnowledgeIndex(base) &&
          _isEncryptedFileSync(base) &&
          _cipherOfFileSync(base.path) == _legacyCipher) {
        return true;
      }
    }
    return false;
  }

  /// Puts back what a move to chacha20 left half done, before anything
  /// else looks at the files (#419). Needs no key.
  ///
  /// A copy beside its database is only a copy: the original is the one
  /// in use. Without its database, the original under its recovery name
  /// is the household, and gets its name back; a rename that fails throws,
  /// and the start goes to recovery. A re-encrypted copy with neither
  /// beside it stays, and so does the start in recovery.
  static Future<void> _settleCipherUpgrade(Directory directory) async {
    for (final base in await _databaseBaseFiles(directory)) {
      final copy = File('${base.path}$_rekeyingSuffix');
      final original = File('${base.path}$_legacyRecoverySuffix');
      if (await base.exists()) {
        _discardSync(copy);
        continue;
      }
      if (await original.exists()) {
        await original.rename(base.path);
        _discardSync(copy);
      }
    }
  }

  /// Moves the household's own databases from aes256cbc to chacha20 (#419).
  ///
  /// Each on a copy, checked and then swapped in, the original kept under
  /// [_legacyRecoverySuffix] until the copy has opened under its name (see
  /// [_upgradeCipherSync]). A file that fails stays as it was and in use,
  /// the failure goes to the error log, and the next start tries again: a
  /// file that cannot be re-encrypted is no reason to keep anybody out of
  /// their household. Only what could not be put back sends the start to
  /// recovery.
  ///
  /// Not the knowledge indexes: they hold public text and can be
  /// gigabytes, and they keep aes256cbc until they are rebuilt. On its own
  /// isolate, like the encryption upgrade.
  Future<void> _upgradeCipher(Directory directory, String key) async {
    final stop = cipherUpgradeStop;
    _migrating = true;
    try {
      for (final base in await _databaseBaseFiles(directory)) {
        if (_isKnowledgeIndex(base)) continue;
        final path = base.path;
        if (!File('$path$_legacyRecoverySuffix').existsSync() &&
            !(_isEncryptedFileSync(base) &&
                _cipherOfFileSync(path) == _legacyCipher)) {
          continue;
        }
        try {
          final finished = stop == null
              ? await Isolate.run(() => _upgradeCipherSync(path, key))
              : _upgradeCipherSync(
                  path,
                  key,
                  stopAfter: (step) => stop(path, step),
                );
          if (!finished) return;
        } on Object catch (error, stack) {
          ErrorLog.instance.record(error, stack, context: 'chacha20 upgrade');
        }
      }
    } finally {
      _migrating = false;
    }
    if (await _hasStrandedCopies(directory)) {
      _mode = LocalDatabaseEncryptionMode.recoveryRequired;
    }
  }

  /// Whether the key store says an upgrade is under way, asked where
  /// nothing else could be read.
  ///
  /// Never for a carried folder: the mark is the installation's.
  Future<bool> _markedAsMigrating() async {
    if (portableLocation.isPortable) return false;
    try {
      return await _storage.read(_modeKey) == 'migrating';
    } on Object {
      return false;
    }
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
  /// A key this installation can still read is kept the same way, under
  /// its own name with the same stamp.
  /// What this buys is a usable app today, and something to restore a
  /// backup into.
  Future<void> startOverKeepingUnreadableFiles() async {
    final directory = _directory;
    if (directory == null) return;
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    for (final base in await _databaseBaseFiles(directory)) {
      for (final file in [
        base,
        for (final suffix in _inFlightSuffixes) File('${base.path}$suffix'),
        File('${base.path}-wal'),
        File('${base.path}-shm'),
      ]) {
        if (await file.exists()) {
          await file.rename('${file.path}.locked-$stamp');
        }
      }
    }
    // The key goes the same way as the files: set aside under their stamp,
    // never deleted (#393). Recovery is also where a key that could not be
    // read once leads, and then it is the one key that opens what was just
    // set aside. Only a key that is safely kept under its new name is
    // taken off the old one; one that cannot be read is left where it is.
    //
    // A key store that cannot be read usually cannot be written either,
    // and that must not stop the files from being moved out of the way --
    // the whole point of this is to get somebody a usable app back.
    //
    // Not at all for a carried folder: the key store is the installation's
    // on this computer, and its key opens that household (#392).
    if (!portableLocation.isPortable) {
      await _setKeyAside(stamp);
    }
    _mode = null;
    _key = null;
    await initializeOrMarkUnavailable(directory: directory);
  }

  Future<void> _setKeyAside(String stamp) async {
    try {
      final old = await _storage.read(_keyKey);
      var kept = false;
      if (_isValidKey(old)) {
        final aside = '$_keyKey.locked-$stamp';
        await _storage.write(aside, old!);
        kept = await _storage.read(aside) == old;
      }
      await _storage.delete(_modeKey);
      if (kept || (old != null && !_isValidKey(old))) {
        await _storage.delete(_keyKey);
      }
    } on Object {
      // Nothing to clear if the device will not talk to us.
    }
  }

  /// The file [name].sqlite lives in, once [initialize] has run.
  File databaseFile(String name) {
    final directory = _directory;
    if (directory == null) {
      throw StateError('Local database encryption has not been initialized.');
    }
    return File(
      '${directory.path}${Platform.pathSeparator}$name$_databaseExtension',
    );
  }

  /// Whether [file] opens under this installation's key and passes
  /// SQLite's quick check (#140).
  ///
  /// Asked of an automatic snapshot before it is put back: one written
  /// before the household was encrypted, or damaged itself, must not take
  /// the place of the file it was meant to rescue. Read-only, so asking
  /// changes nothing.
  bool opensCleanly(File file) {
    final key = _key;
    try {
      final database = sqlite3.open(file.path, mode: OpenMode.readOnly);
      try {
        if (_mode == LocalDatabaseEncryptionMode.encrypted && key != null) {
          _configureCipherForFile(database, file.path, key);
        }
        final result = database.select('PRAGMA quick_check');
        return result.isNotEmpty && result.first.values.first == 'ok';
      } finally {
        database.close();
      }
    } on Object {
      return false;
    }
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
    _opened = true;
    final key = _key;
    if (_mode == LocalDatabaseEncryptionMode.encrypted && key != null) {
      final path = file.path;
      // In a carried folder only a file that already is encrypted gets
      // the key; a new one is created plain (#392).
      final carried = portableLocation.isPortable;
      return NativeDatabase.createInBackground(
        file,
        setup: (database) {
          if (carried) {
            if (_isEncryptedFileSync(File(path))) {
              _configureCipherForFile(database, path, key);
            }
          } else {
            _configureCipherForFile(database, path, key);
          }
          _waitForOtherConnections(database);
        },
      );
    }
    return NativeDatabase.createInBackground(
      file,
      setup: _waitForOtherConnections,
    );
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
    final directory = _directory!;
    // Refused before the mark is set, so that nothing is left to repair: a
    // recovery copy that is still there may be the household (#393).
    for (final base in await _databaseBaseFiles(directory)) {
      if (await File('${base.path}$_recoverySuffix').exists()) {
        throw StateError('A recovery copy of ${base.path} is still there.');
      }
    }
    // Set before anything is touched, including the key: from here on no
    // part of the app may open one of these files.
    _migrating = true;
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

  /// The databases in [directory], by the name each has when nothing is
  /// in flight -- including one only there under a migration copy's name.
  static Future<List<File>> databaseFilesIn(Directory directory) =>
      _databaseBaseFiles(directory);

  /// Whether [file] is a database that does not start like a plain one.
  static Future<bool> isEncryptedDatabase(File file) => _isEncryptedFile(file);

  /// Whether [name] is a database under a name a migration gives it while
  /// it is in flight: the household may be under either name.
  static bool isMigrationCopy(String name) => _inFlightSuffixes.any(
    (suffix) => name.endsWith('$_databaseExtension$suffix'),
  );

  /// The key of the installation on this computer, for a carried copy
  /// taking its household over (#392). Read, never written.
  ///
  /// [InstallationKey.upgrading] when that installation is in the middle
  /// of its upgrade: its files are then not in a state to be copied.
  static Future<InstallationKey> readInstallationKey([
    LocalDatabaseKeyStorage storage = const SecureLocalDatabaseKeyStorage(),
  ]) async {
    String? mode;
    String? key;
    try {
      mode = await storage.read(_modeKey);
      key = await storage.read(_keyKey);
    } on Object {
      // Nothing to read: whatever is sealed stays where it is.
    }
    return (key: _isValidKey(key) ? key : null, upgrading: mode == 'migrating');
  }

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
        continue;
      }
      for (final suffix in _inFlightSuffixes) {
        if (name.endsWith('$_databaseExtension$suffix')) {
          paths.add(path.substring(0, path.length - suffix.length));
          break;
        }
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

  /// Puts the folder back into a state a start can open.
  ///
  /// [recordMode] when the key store marked the upgrade as running: the
  /// mark is then replaced by what the folder now is. A copy found without
  /// that mark is put back without touching the mode.
  Future<void> _recoverInterruptedMigration(
    Directory directory, {
    bool recordMode = true,
  }) async {
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

      if (!await base.exists()) {
        // Renamed aside, and the process stopped before the encrypted file
        // took its name: the readable copy is the plaintext one. A rename
        // that fails here throws, and the start goes to recovery rather
        // than past the household (#393).
        if (await recovery.exists()) {
          await recovery.rename(base.path);
          if (await temporary.exists()) await temporary.delete();
        }
        // An encrypted copy with neither its original nor its recovery
        // beside it is whatever is left of the household. It stays, and
        // the start goes to recovery.
        continue;
      }

      // A plaintext database under its own name. Beside a recovery copy
      // that is not the state any upgrade leaves behind: 3.0.3 opened an
      // empty database there after a rename had failed. Which of the two
      // is the household nobody here can say, so both stay, and so does
      // the encrypted copy.
      if (await recovery.exists()) continue;
      // Otherwise the upgrade stopped before the copy was finished.
      if (await temporary.exists()) await temporary.delete();
    }

    if (!recordMode) return;
    // A half-finished run leaves both kinds of file in the folder, which
    // is `encrypted`: `open` decides per file. Never `recoveryRequired`
    // (#393). Whether the key can be read is asked again by every start;
    // stored, a key store that failed one read kept the household locked
    // for good, and "start over" then set aside the key that opens it.
    await _storage.write(
      _modeKey,
      encrypted == 0 ? 'plaintext' : 'encrypted',
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

/// Copies the database at [source] to [target] as a plain file (#392).
///
/// For a carried folder taking over the household of an installation on
/// this computer: the folder is opened on other computers, which do not
/// have this one's key. [key] opens [source] where it is encrypted.
///
/// Through SQLite rather than as a file: `VACUUM INTO` takes one
/// consistent state of the database, whatever its journal holds, so no
/// journal travels without its database or the other way round. An
/// encrypted copy is then decrypted with an empty `PRAGMA rekey`. Throws
/// unless the copy is plain and holds the original's tables and row
/// counts; the original is only read.
///
/// On its own isolate: a knowledge index can be gigabytes.
Future<void> copyDatabaseAsPlaintext(
  String source,
  String target, {
  String? key,
}) => Isolate.run(() => _copyAsPlaintextSync(source, target, key));

void _copyAsPlaintextSync(String source, String target, String? key) {
  final encrypted = _isEncryptedFileSync(File(source));
  if (encrypted && key == null) {
    throw StateError('$source is encrypted, and there is no key.');
  }
  final partial = File('$target.part');
  if (partial.existsSync()) partial.deleteSync();

  // Read and write, as the installation itself opens it: a journal left
  // by a write that was cut off is rolled back first, which is what the
  // installation does at its next start anyway.
  final original = sqlite3.open(source, mode: OpenMode.readWrite);
  try {
    if (encrypted) _configureCipherForFile(original, source, key!);
    _waitForOtherConnections(original);
    original.execute('VACUUM INTO ${_sqlLiteral(partial.path)}');
  } finally {
    original.close();
  }

  try {
    // `VACUUM INTO` keeps the cipher: the copy is as encrypted as its
    // original, with the same one, until it is rekeyed to nothing.
    if (encrypted) {
      final copy = sqlite3.open(partial.path);
      try {
        _configureCipherForFile(copy, partial.path, key!);
        copy.execute("PRAGMA rekey = ''");
      } finally {
        copy.close();
      }
    }
    if (!_isPlaintextFileSync(partial)) {
      throw StateError('The copy of $source is not plain.');
    }

    final from = sqlite3.open(source, mode: OpenMode.readOnly);
    final copy = sqlite3.open(partial.path, mode: OpenMode.readOnly);
    try {
      if (encrypted) _configureCipherForFile(from, source, key!);
      _waitForOtherConnections(from);
      if (!_sameRowCounts(_rowCounts(from), _rowCounts(copy))) {
        throw StateError('The copy of $source does not match it.');
      }
    } finally {
      copy.close();
      from.close();
    }
    partial.renameSync(target);
  } on Object {
    if (partial.existsSync()) partial.deleteSync();
    rethrow;
  }
}

/// The blocking half of [LocalDatabaseEncryption._encryptFile], written so
/// that everything it touches is a String and it can run on its own isolate.
@visibleForTesting
void encryptDatabaseFileForTesting(
  String path,
  String key, {
  void Function()? afterCopy,
}) => _encryptFileSync(path, key, afterCopy: afterCopy);

void _encryptFileSync(String path, String key, {void Function()? afterCopy}) {
  final source = File(path);
  final temporary = File('$path$_encryptingSuffix');
  final recovery = File('$path$_recoverySuffix');
  // A recovery copy already there may be the household itself (#393).
  // Deleting it to make room was how an upgrade after a failed repair
  // removed the only copy. The upgrade stops instead, before touching
  // anything.
  if (recovery.existsSync()) {
    throw StateError('A recovery copy of $path is still there.');
  }
  if (temporary.existsSync()) temporary.deleteSync();

  final sourceDatabase = sqlite3.open(path);
  try {
    _waitForOtherConnections(sourceDatabase);
    sourceDatabase.execute('PRAGMA wal_checkpoint(TRUNCATE)');
    sourceDatabase.execute('VACUUM INTO ${_sqlLiteral(temporary.path)}');
  } finally {
    sourceDatabase.close();
  }
  afterCopy?.call();

  // `PRAGMA key` announces that the file already is encrypted, and on a
  // plaintext one it leaves nothing readable behind -- not even for the
  // rekey that was meant to encrypt it. The copy is opened plainly, the
  // cipher is only selected, and `PRAGMA rekey` does the encrypting.
  final encrypting = sqlite3.open(temporary.path);
  try {
    encrypting.execute('PRAGMA cipher = ${_sqlLiteral(_cipher)}');
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
    // That it opens is not enough: an empty file opens as well (#334).
    _expectSameContents(path, verify);
  } finally {
    verify.close();
  }

  source.renameSync(recovery.path);
  temporary.renameSync(path);
  recovery.deleteSync();
  for (final suffix in ['-wal', '-shm']) {
    final journal = File('$path$suffix');
    if (journal.existsSync()) journal.deleteSync();
  }
}

/// Moves the database at [path] from aes256cbc to chacha20 (#419), and
/// answers false where [stopAfter] stopped it.
///
/// The order is what makes every stop harmless, and the start puts back
/// whatever it finds ([LocalDatabaseEncryption._settleCipherUpgrade]):
///
/// 1. `VACUUM INTO` the copy, through a read-write connection with the
///    original's key, so that a hot journal is rolled back first. The copy
///    keeps the cipher and the key.
/// 2. `PRAGMA cipher = 'chacha20'` and `PRAGMA rekey` with the same key
///    re-encrypt the copy where it is.
/// 3. The copy must say chacha20 in its header, pass `quick_check` (every
///    page's tag), and hold the original's `user_version`, schema and rows.
/// 4. Nothing may have written into the original since step 1: no journal
///    beside it, the same size and time.
/// 5. The original is renamed aside, the copy takes its name.
/// 6. Once the copy opens under that name, the original is deleted. If it
///    does not, nothing has used it yet, and the original is put back.
///
/// Any failure up to step 5 leaves the original where it was and removes
/// the copy. Never with a recovery copy there already: that is kept,
/// whatever else is wrong, until the file under its name opens cleanly.
bool _upgradeCipherSync(
  String path,
  String key, {
  bool Function(String step)? stopAfter,
}) {
  bool stopped(String step) => stopAfter?.call(step) ?? false;
  final database = File(path);
  final copy = File('$path$_rekeyingSuffix');
  final original = File('$path$_legacyRecoverySuffix');

  if (original.existsSync()) {
    // Swapped, and stopped before the original went. Beside anything that
    // is not the re-encrypted file opening cleanly it is not a state this
    // leaves, and which of the two is the household nobody here can say.
    if (database.existsSync() &&
        _isEncryptedFileSync(database) &&
        _cipherOfFileSync(path) == _cipher &&
        _opensCleanlySync(path, key)) {
      _discardSync(copy);
      original.deleteSync();
    }
    return true;
  }
  if (!_isEncryptedFileSync(database) ||
      _cipherOfFileSync(path) != _legacyCipher) {
    return true;
  }

  _discardSync(copy);
  try {
    final source = sqlite3.open(path);
    try {
      _configureCipher(source, key, cipher: _legacyCipher);
      _waitForOtherConnections(source);
      source.execute('VACUUM INTO ${_sqlLiteral(copy.path)}');
    } finally {
      source.close();
    }
    final copied = database.statSync();
    if (stopped('copied')) return false;

    final rekeying = sqlite3.open(copy.path);
    try {
      _configureCipher(rekeying, key, cipher: _legacyCipher);
      rekeying.execute('PRAGMA cipher = ${_sqlLiteral(_cipher)}');
      rekeying.execute('PRAGMA rekey = ${_sqlLiteral(key)}');
    } finally {
      rekeying.close();
    }
    if (stopped('rekeyed')) return false;

    if (_cipherOfFileSync(copy.path) != _cipher) {
      throw StateError('The copy of $path was not re-encrypted.');
    }
    _expectSameDatabase(path, copy.path, key);
    if (stopped('verified')) return false;

    // The use lock keeps this version of the app out. A journal or a
    // change here is something else writing, and the copy would not hold
    // what it wrote.
    final now = database.statSync();
    if (now.modified != copied.modified ||
        now.size != copied.size ||
        [
          for (final suffix in const ['-journal', '-wal']) File('$path$suffix'),
          for (final suffix in const ['-journal', '-wal'])
            File('${copy.path}$suffix'),
        ].any((journal) => journal.existsSync())) {
      throw StateError('$path was written to while it was re-encrypted.');
    }
    database.renameSync(original.path);
  } on Object {
    _discardSync(copy);
    rethrow;
  }
  if (stopped('set aside')) return false;

  try {
    copy.renameSync(path);
  } on Object {
    // Whatever stays named as the original is put back by the next start;
    // until then the start goes to recovery.
    original.renameSync(path);
    _discardSync(copy);
    rethrow;
  }
  if (stopped('swapped')) return false;

  if (_cipherOfFileSync(path) != _cipher || !_opensWithKey(path, key)) {
    // Nothing has opened it yet, and the original is untouched.
    database.renameSync(copy.path);
    original.renameSync(path);
    _discardSync(copy);
    throw StateError('The re-encrypted $path did not open.');
  }
  if (stopped('opened')) return false;

  original.deleteSync();
  return true;
}

/// Removes a copy and whatever journals SQLite left beside it. Quietly: a
/// copy that will not go now goes at the next start.
void _discardSync(File file) {
  for (final path in [
    file.path,
    '${file.path}-journal',
    '${file.path}-wal',
    '${file.path}-shm',
  ]) {
    try {
      final leftover = File(path);
      if (leftover.existsSync()) leftover.deleteSync();
    } on FileSystemException {
      // Next start.
    }
  }
}

/// Whether the database at [path] opens with [key] and passes
/// `quick_check`, which under chacha20 reads every page's tag.
bool _opensCleanlySync(String path, String key) {
  try {
    final database = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      _configureCipherForFile(database, path, key);
      _waitForOtherConnections(database);
      final result = database.select('PRAGMA quick_check');
      return result.length == 1 && result.first.values.first == 'ok';
    } finally {
      database.close();
    }
  } on Object {
    return false;
  }
}

/// Throws unless the database at [copyPath] holds what the one at [path]
/// holds: a sound file, the same `user_version` (Drift's schema version,
/// which a copy without it would migrate from nothing), the same schema,
/// and the same rows in every table, compared value by value.
///
/// Rows are read in the order the table keeps them, which `VACUUM INTO`
/// keeps as well. A rowid that is not a column may be renumbered by it and
/// is not compared.
void _expectSameDatabase(String path, String copyPath, String key) {
  final original = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    final copy = sqlite3.open(copyPath, mode: OpenMode.readOnly);
    try {
      _configureCipherForFile(original, path, key);
      _configureCipherForFile(copy, copyPath, key);
      _waitForOtherConnections(original);
      final check = copy.select('PRAGMA quick_check');
      if (check.length != 1 || check.first.values.first != 'ok') {
        throw StateError('The copy of $path is damaged.');
      }
      if (_userVersion(original) != _userVersion(copy) ||
          !_sameValues(_schema(original), _schema(copy)) ||
          !_sameRowCounts(_rowCounts(original), _rowCounts(copy))) {
        throw StateError('The copy of $path does not match it.');
      }
      for (final table in _storedTables(original)) {
        final select =
            'SELECT * FROM "${table.replaceAll('"', '""')}" '
            'NOT INDEXED';
        final from = original.prepare(select);
        final to = copy.prepare(select);
        try {
          final expected = from.selectCursor();
          final actual = to.selectCursor();
          while (expected.moveNext()) {
            if (!actual.moveNext() ||
                !_sameValues(expected.current.values, actual.current.values)) {
              throw StateError('The copy of $path differs in $table.');
            }
          }
          if (actual.moveNext()) {
            throw StateError('The copy of $path differs in $table.');
          }
        } finally {
          to.close();
          from.close();
        }
      }
    } finally {
      copy.close();
    }
  } finally {
    original.close();
  }
}

int _userVersion(Database database) =>
    database.select('PRAGMA user_version').first.values.first as int;

List<Object?> _schema(Database database) => [
  for (final row in database.select(
    'SELECT type, name, tbl_name, sql FROM sqlite_master ORDER BY type, name',
  ))
    row.values,
];

/// Every table that keeps its own rows: virtual tables are read through
/// their shadow tables, which are listed themselves.
List<String> _storedTables(Database database) => [
  for (final row in database.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND sql NOT LIKE 'CREATE VIRTUAL%' ORDER BY name",
  ))
    row['name'] as String,
];

bool _sameValues(Object? a, Object? b) {
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameValues(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}

/// Who has the databases in use, kept by SQLite itself (#419).
///
/// An empty database of its own beside them, held through a transaction:
/// shared by whatever uses the databases outside the app's start -- the
/// background poll for its run, a desktop window for as long as it is
/// open -- and alone by a start that moves a file to chacha20. SQLite
/// keeps these locks between the isolates of one process as well as
/// between processes, and the system ends them with the process: a run
/// that was killed leaves nothing to clear up. A lock on a file of the
/// databases themselves would not do: a connection that is open but idle
/// holds none.
final class _UseLock {
  _UseLock._(this._database);

  final Database _database;

  static File _fileIn(Directory directory) =>
      File('${directory.path}${Platform.pathSeparator}$_useLockName');

  /// Held by nobody else, or null. Never waits: a start does not keep a
  /// window from appearing over a file that can be moved next time.
  static _UseLock? exclusive(Directory directory) {
    final attempt = _take(directory, alone: true);
    if (attempt.lock != null || attempt.busy) return attempt.lock;
    // A file that is not a database at all cannot be held by anybody, and
    // would keep every start from moving anything. It is replaced once.
    final file = _fileIn(directory);
    try {
      if (!file.existsSync() ||
          file.lengthSync() == 0 ||
          _isPlaintextFileSync(file)) {
        return null;
      }
      file.deleteSync();
    } on FileSystemException {
      return null;
    }
    return _take(directory, alone: true).lock;
  }

  /// Held alongside others, waiting up to [wait] while it is held alone.
  /// [busy] when it still was.
  static Future<({_UseLock? lock, bool busy})> shared(
    Directory directory, {
    required Duration wait,
  }) async {
    final until = DateTime.now().add(wait);
    while (true) {
      final attempt = _take(directory, alone: false);
      if (!attempt.busy || !DateTime.now().isBefore(until)) return attempt;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  static ({_UseLock? lock, bool busy}) _take(
    Directory directory, {
    required bool alone,
  }) {
    Database? database;
    try {
      database = sqlite3.open(_fileIn(directory).path);
      database.execute('PRAGMA busy_timeout = 0');
      if (alone) {
        database.execute('BEGIN EXCLUSIVE');
      } else {
        database.execute('BEGIN');
        database.select('SELECT count(*) FROM sqlite_master');
      }
      return (lock: _UseLock._(database), busy: false);
    } on Object catch (error) {
      try {
        database?.close();
      } on Object {
        // Nothing held.
      }
      const sqliteBusy = 5;
      return (
        lock: null,
        busy: error is SqliteException && error.resultCode == sqliteBusy,
      );
    }
  }

  void release() {
    try {
      _database.execute('ROLLBACK');
    } on Object {
      // Closing ends it as well.
    }
    try {
      _database.close();
    } on Object {
      // The process ends it at the latest.
    }
  }
}

/// Applies the key to everything except a file that is readable plaintext,
/// with the cipher that file was written with.
///
/// A `PRAGMA key` on a plaintext database does not leave it readable -- it
/// fails to open at all.  Deciding per file rather than per installation is
/// what keeps a half-finished migration harmless: the encrypted files open
/// with the key, the ones it did not reach yet open without it, and a file
/// that does not exist yet is created encrypted, with chacha20 (#419). The
/// cipher is decided per file as well: an aes256cbc file the move to
/// chacha20 has not reached, a daily copy taken before it, and a knowledge
/// index from 3.0.3 all still open.
void _configureCipherForFile(dynamic database, String path, String key) {
  if (_isPlaintextFileSync(File(path))) return;
  _configureCipher(database, key, cipher: _cipherOfFileSync(path));
}

/// Whether [file] holds a database and it does not start like a plain one.
///
/// The question a carried folder asks: a file that is missing, or still
/// empty, is a new one and stays plain.
bool _isEncryptedFileSync(File file) {
  try {
    final handle = file.openSync();
    try {
      final bytes = handle.readSync(_sqliteHeader.length);
      return bytes.length == _sqliteHeader.length &&
          utf8.decode(bytes, allowMalformed: true) != _sqliteHeader;
    } finally {
      handle.closeSync();
    }
  } on FileSystemException {
    return false;
  }
}

/// Whether the database at [path] opens with [key], read-only.
bool _opensWithKey(String path, String key) {
  try {
    final database = sqlite3.open(path, mode: OpenMode.readOnly);
    try {
      _configureCipherForFile(database, path, key);
      database.select('SELECT count(*) FROM sqlite_master');
      return true;
    } finally {
      database.close();
    }
  } on Object {
    return false;
  }
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

/// Throws unless [copy] holds the tables and row counts of the file at
/// [path], the last moment at which that file can still be kept.
///
/// Virtual tables are left out: they are read through their shadow tables,
/// which are counted, and some of them cannot be counted at all.
void _expectSameContents(String path, dynamic copy) {
  final original = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (!_sameRowCounts(_rowCounts(original), _rowCounts(copy))) {
      throw StateError('The encrypted copy does not match the original.');
    }
  } finally {
    original.close();
  }
}

bool _sameRowCounts(Map<String, int> expected, Map<String, int> copied) =>
    expected.length == copied.length &&
    expected.entries.every((table) => copied[table.key] == table.value);

Map<String, int> _rowCounts(dynamic database) {
  final tables = database.select(
    "SELECT name FROM sqlite_master WHERE type = 'table' "
    "AND name NOT LIKE 'sqlite_%' "
    "AND sql NOT LIKE 'CREATE VIRTUAL%'",
  );
  return {
    for (final row in tables)
      row['name'] as String:
          database
                  .select(
                    'SELECT count(*) AS n FROM '
                    '"${(row['name'] as String).replaceAll('"', '""')}"',
                  )
                  .first['n']
              as int,
  };
}

/// How long a connection waits for another before it gives up (#334).
///
/// Each database has its connection here and, on a telephone, the
/// background worker's beside it, and two desktop windows can be open.
/// Without a wait the loser of two writes fails at once with "database is
/// locked", which reached the person as a raw error on saving.
void _waitForOtherConnections(dynamic database) {
  database.execute('PRAGMA busy_timeout = 5000');
}

/// Selects [cipher] and applies [key], before anything is read.
///
/// Always named, never left to the library: its default is chacha20 now,
/// and 3.0.3 wrote aes256cbc under a comment that called that the default
/// (#419). A connection set to the wrong one of the two is not merely
/// refused -- see [_cipherOfFileSync].
void _configureCipher(dynamic database, String key, {String cipher = _cipher}) {
  database.execute('PRAGMA cipher = ${_sqlLiteral(cipher)}');
  database.execute('PRAGMA key = ${_sqlLiteral(key)}');
}

/// The cipher the encrypted database at [path] was written with (#419).
///
/// Read from its header, not found out by trying. SQLite3MultipleCiphers
/// keeps bytes 16 to 23 of the file in the clear under every cipher, so
/// that SQLite can learn the page size before anything is decrypted, and
/// byte 20 is the space each page keeps free at its end. chacha20 keeps
/// 32 bytes there for its nonce and tag; aes256cbc keeps none, which is
/// also why it cannot tell a changed page.
///
/// Trying is what suggests itself, and it can destroy the file. A
/// read-write connection set to the wrong cipher rolls a hot journal back
/// through it: an aes256cbc key on a chacha20 file left with a journal by
/// a crash wrote the journal's pages back as garbage, and deleted the
/// journal. A read-only try cannot tell either; it stops at the journal.
///
/// A file too short for a header is a new one, and gets chacha20. So does
/// one that keeps a reserve neither cipher keeps: whatever it is, the
/// cipher with a tag refuses it rather than writing into it.
String _cipherOfFileSync(String path) {
  try {
    final handle = File(path).openSync();
    try {
      final header = handle.readSync(24);
      if (header.length < 24) return _cipher;
      return header[20] == 0 ? _legacyCipher : _cipher;
    } finally {
      handle.closeSync();
    }
  } on FileSystemException {
    return _cipher;
  }
}

String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";
