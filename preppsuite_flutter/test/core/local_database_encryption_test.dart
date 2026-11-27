import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

class _MemoryKeyStorage implements LocalDatabaseKeyStorage {
  final values = <String, String>{};

  /// Lets a test look at the world in the middle of a migration.
  void Function(String key, String value)? onWrite;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
    onWrite?.call(key, value);
  }
}

const _modeKey = 'preppsuite.localDatabaseEncryption.mode.v1';
const _keyKey = 'preppsuite.localDatabaseEncryption.key.v1';

String _freshKey() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)));
}

String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";

/// What the app encrypts with since #419, and what 3.0.3 encrypted with.
const _chacha20 = 'chacha20';
const _aes256cbc = 'aes256cbc';

/// A database holding one recognisable row, so that "the household came
/// back" can be asserted on its contents rather than on a file existing.
void _writeHousehold(
  String path,
  String name, {
  String? key,
  String cipher = _chacha20,
}) {
  final database = sqlite3.open(path);
  try {
    if (key != null) {
      database.execute("PRAGMA cipher = '$cipher'");
      database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    }
    database
      ..execute('CREATE TABLE household (name TEXT NOT NULL)')
      ..execute('INSERT INTO household VALUES (${_sqlLiteral(name)})');
  } finally {
    database.close();
  }
}

/// Reads with the cipher the file says it was written with, or with
/// [cipher] where a test wants to know whether that one opens it.
String _readHousehold(String path, {String? key, String? cipher}) {
  final database = sqlite3.open(path);
  try {
    if (key != null) {
      database.execute("PRAGMA cipher = '${cipher ?? _cipherOf(path)}'");
      database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    }
    return database.select('SELECT name FROM household').single['name']
        as String;
  } finally {
    database.close();
  }
}

/// Byte 20 of the header, which every cipher keeps in the clear: the
/// space each page keeps free, 32 for chacha20's nonce and tag, none for
/// aes256cbc.
String _cipherOf(String path) {
  final handle = File(path).openSync();
  try {
    return handle.readSync(24)[20] == 0 ? _aes256cbc : _chacha20;
  } finally {
    handle.closeSync();
  }
}

/// Whether the encrypted database at [path] still reads as sound after
/// one bit of one of its later pages was flipped on the disk.
bool _changedPageGoesUnnoticed(String path, String key) {
  final bytes = File(path).readAsBytesSync();
  expect(bytes.length, greaterThan(4 * 4096), reason: 'needs a few pages');
  bytes[3 * 4096 + 1000] ^= 0x01;
  File(path).writeAsBytesSync(bytes, flush: true);
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    database.execute("PRAGMA cipher = '${_cipherOf(path)}'");
    database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    final check = database.select('PRAGMA integrity_check');
    database.select('SELECT * FROM pages');
    return check.length == 1 && check.single.values.first == 'ok';
  } on SqliteException {
    return false;
  } finally {
    database.close();
  }
}

/// Fills a table across several pages.
void _fillPages(Database database) {
  database.execute('CREATE TABLE IF NOT EXISTS pages (text TEXT NOT NULL)');
  for (var i = 0; i < 300; i++) {
    database.execute(
      'INSERT INTO pages VALUES (?)',
      ['Seite $i ${'x' * 120}'],
    );
  }
}

/// Leaves [path] as a crash in the middle of a write leaves it: a database
/// with pages already changed on the disk, and the hot journal that puts
/// them back.
void _leaveHotJournal(String path, String key, String cipher) {
  final source = '$path.source';
  final database = sqlite3.open(source);
  try {
    database.execute("PRAGMA cipher = '$cipher'");
    database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    database.execute('CREATE TABLE household (name TEXT NOT NULL)');
    database.execute("INSERT INTO household VALUES ('Beispielperson')");
    _fillPages(database);
    // A cache too small to hold the transaction spills its pages into the
    // file before the commit.
    database.execute('PRAGMA cache_size = 2');
    database.execute('BEGIN');
    database.execute("UPDATE pages SET text = 'geaendert'");
    File(source).copySync(path);
    File('$source-journal').copySync('$path-journal');
    database.execute('ROLLBACK');
  } finally {
    database.close();
  }
  File(source).deleteSync();
}

bool _looksLikePlaintext(File file) {
  final handle = file.openSync();
  try {
    return utf8.decode(handle.readSync(16), allowMalformed: true) ==
        'SQLite format 3\u0000';
  } finally {
    handle.closeSync();
  }
}

void main() {
  late Directory directory;
  late _MemoryKeyStorage storage;

  String pathTo(String name) =>
      '${directory.path}${Platform.pathSeparator}$name.sqlite';

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('preppsuite-encryption-');
    storage = _MemoryKeyStorage();
  });

  tearDown(() async {
    resetPortableData();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  // Skipped rather than silently passed where the build has no cipher: a
  // test that quietly asserts nothing is worse than one that is missing,
  // because the report says it ran.
  final noCipher = LocalDatabaseEncryption.cipherAvailable
      ? null
      : 'The SQLite library in this build has no cipher.';

  group('LocalDatabaseEncryption', () {
    test('keeps a device-held 256-bit key for a compatible cipher', () async {
      final encryption = LocalDatabaseEncryption(storage: storage);

      await encryption.initialize(directory: directory);

      expect(
        encryption.mode,
        LocalDatabaseEncryption.cipherAvailable
            ? LocalDatabaseEncryptionMode.encrypted
            : LocalDatabaseEncryptionMode.plaintext,
      );
      expect(base64Url.decode(storage.values[_keyKey]!), hasLength(32));
    });

    test('an existing plaintext household is left alone at first', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
      expect(await encryption.pendingPlaintextDatabases(), ['preppsuite']);
    });

    test(
      'refuses an upgrade when the running SQLite lacks a cipher',
      () async {
        _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

        final encryption = LocalDatabaseEncryption(storage: storage);
        await encryption.initialize(directory: directory);
        expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);

        await expectLater(
          encryption.migrateExistingDatabases(),
          throwsA(isA<UnsupportedError>()),
        );
        expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
      },
      skip: LocalDatabaseEncryption.cipherAvailable ? 'Has a cipher.' : null,
    );
  });

  group('upgrading an existing household', () {
    test('encrypts every database and keeps every row', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');
      _writeHousehold(pathTo('preppsuite_personal_documents'), 'Unterlagen');

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      await encryption.migrateExistingDatabases();

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(await encryption.pendingPlaintextDatabases(), isEmpty);

      final key = storage.values[_keyKey]!;
      expect(_looksLikePlaintext(File(pathTo('preppsuite'))), isFalse);
      expect(_readHousehold(pathTo('preppsuite'), key: key), 'Beispielperson');
      expect(
        _readHousehold(pathTo('preppsuite_personal_documents'), key: key),
        'Unterlagen',
      );
    }, skip: noCipher);

    test('the encrypted file does not open without the key', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      await encryption.migrateExistingDatabases();

      expect(() => _readHousehold(pathTo('preppsuite')), throwsA(anything));
    }, skip: noCipher);

    test('leaves nothing behind to be picked up as a second run', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      await encryption.migrateExistingDatabases();
      await encryption.migrateExistingDatabases();

      expect(
        directory.listSync().map((e) => e.uri.pathSegments.last).toList(),
        ['preppsuite.sqlite'],
      );
      expect(
        _readHousehold(pathTo('preppsuite'), key: storage.values[_keyKey]!),
        'Beispielperson',
      );
    }, skip: noCipher);
  });

  group('while it runs', () {
    test('a background isolate never repairs a migration (#334)', () async {
      // From there a migration under way looks like an interrupted one,
      // and the repair deletes the copy that is being written.
      final path = pathTo('preppsuite');
      _writeHousehold(path, 'Ours');
      final copy = File('$path.encrypting')..writeAsStringSync('half written');
      storage.values[_modeKey] = 'migrating';
      storage.values[_keyKey] = _freshKey();

      await expectLater(
        LocalDatabaseEncryption(storage: storage).initialize(
          directory: directory,
          repairInterruptedMigration: false,
        ),
        throwsA(isA<LocalDataBusy>()),
      );

      expect(copy.existsSync(), isTrue);
      expect(storage.values[_modeKey], 'migrating');
    });

    test('a copy without the household never replaces it (#334)', () {
      final path = pathTo('preppsuite');
      _writeHousehold(path, 'Ours');

      expect(
        () => encryptDatabaseFileForTesting(
          path,
          _freshKey(),
          afterCopy: () => File('$path.encrypting').deleteSync(),
        ),
        throwsStateError,
      );

      expect(_readHousehold(path), 'Ours');
    }, skip: noCipher);

    test('a connection waits for another before it gives up (#334)', () async {
      for (final encrypted in [true, false]) {
        final folder = await directory.createTemp('mode');
        final store = _MemoryKeyStorage();
        if (!encrypted) {
          // A plain household, kept plain: without one, `plaintext` in an
          // empty folder starts like a new installation (#392).
          store.values[_modeKey] = 'plaintext';
          _writeHousehold('${folder.path}/preppsuite.sqlite', 'Beispiel');
        }
        final encryption = LocalDatabaseEncryption(storage: store);
        await encryption.initialize(directory: folder);
        expect(
          encryption.mode,
          encrypted
              ? LocalDatabaseEncryptionMode.encrypted
              : LocalDatabaseEncryptionMode.plaintext,
        );

        final database = AppDatabase.forTesting(encryption.open('preppsuite'));
        addTearDown(database.close);
        final row = await database
            .customSelect('PRAGMA busy_timeout')
            .getSingle();

        expect(row.read<int>('timeout'), 5000);
      }
    }, skip: noCipher);

    test('nothing may open a database while it is being replaced', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      Object? refusal;
      storage.onWrite = (key, value) {
        if (value != 'migrating') return;
        try {
          encryption.open('preppsuite');
        } on Object catch (error) {
          refusal = error;
        }
      };

      await encryption.migrateExistingDatabases();

      expect(refusal, isA<LocalDataBusy>());
      expect(encryption.isMigrating, isFalse);
      expect(() => encryption.open('preppsuite'), returnsNormally);
    }, skip: noCipher);
  });

  group('an upgrade interrupted', () {
    test('between the two renames gives the household back', () async {
      // The dangerous moment: the plaintext file has been renamed aside and
      // the encrypted one has not yet taken its name. Nothing in the folder
      // is called preppsuite.sqlite.
      _writeHousehold(
        '${pathTo('preppsuite')}.plaintext-recovery',
        'Beispielperson',
      );
      storage.values[_modeKey] = 'migrating';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
      expect(
        File('${pathTo('preppsuite')}.plaintext-recovery').existsSync(),
        isFalse,
      );
    });

    test(
      'before the copy was finished discards the half-written one',
      () async {
        _writeHousehold(pathTo('preppsuite'), 'Beispielperson');
        File('${pathTo('preppsuite')}.encrypting').writeAsStringSync('half');
        storage.values[_modeKey] = 'migrating';

        final encryption = LocalDatabaseEncryption(storage: storage);
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
        expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
        expect(
          File('${pathTo('preppsuite')}.encrypting').existsSync(),
          isFalse,
        );
      },
    );

    test(
      'after the swap keeps the encrypted file and clears the copy',
      () async {
        final key = _freshKey();
        _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
        _writeHousehold(
          '${pathTo('preppsuite')}.plaintext-recovery',
          'Beispielperson',
        );
        File('${pathTo('preppsuite')}-wal').writeAsStringSync('stale');
        storage.values[_modeKey] = 'migrating';
        storage.values[_keyKey] = key;

        final encryption = LocalDatabaseEncryption(storage: storage);
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(
          _readHousehold(pathTo('preppsuite'), key: key),
          'Beispielperson',
        );
        expect(
          File('${pathTo('preppsuite')}.plaintext-recovery').existsSync(),
          isFalse,
        );
        // The journal belonged to the plaintext database that was renamed
        // away; read against the encrypted file it is nonsense.
        expect(File('${pathTo('preppsuite')}-wal').existsSync(), isFalse);
      },
      skip: noCipher,
    );

    test('part way through can be finished later', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      _writeHousehold(pathTo('preppsuite_personal_documents'), 'Unterlagen');
      storage.values[_modeKey] = 'migrating';
      storage.values[_keyKey] = key;

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      // Both are readable in this state -- the encrypted one with the key,
      // the untouched one without it -- which is what makes it safe to
      // report and finish rather than to panic about.
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(await encryption.pendingPlaintextDatabases(), [
        'preppsuite_personal_documents',
      ]);

      await encryption.migrateExistingDatabases();

      expect(await encryption.pendingPlaintextDatabases(), isEmpty);
      expect(_readHousehold(pathTo('preppsuite'), key: key), 'Beispielperson');
      expect(
        _readHousehold(pathTo('preppsuite_personal_documents'), key: key),
        'Unterlagen',
      );
    }, skip: noCipher);

    test('resuming keeps the key the first run used', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      _writeHousehold(pathTo('preppsuite_personal_documents'), 'Unterlagen');
      storage.values[_modeKey] = 'migrating';
      storage.values[_keyKey] = key;

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      await encryption.migrateExistingDatabases();

      expect(storage.values[_keyKey], key);
    }, skip: noCipher);

    test('without a key left to open them asks for recovery', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      storage.values[_modeKey] = 'migrating';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      // No key in storage: the file is not lost, but this installation
      // cannot open it, and saying `plaintext` here would start a second,
      // empty household beside it.
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
      expect(
        () => encryption.open('preppsuite'),
        throwsA(isA<LocalDataUnavailable>()),
      );
    }, skip: noCipher);
  });

  group('a key store that failed once (#393)', () {
    test('never stores recovery, and opens once the key reads again', () async {
      // The swap was done and the copy not yet cleared away when the app
      // stopped; at the next start the key store missed one read.
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      _writeHousehold(
        '${pathTo('preppsuite')}.plaintext-recovery',
        'Beispielperson',
      );
      final flaky = _FlakyKeyStorage()
        ..values[_modeKey] = 'migrating'
        ..values[_keyKey] = key
        ..failedKeyReads = 1;

      final first = LocalDatabaseEncryption(storage: flaky);
      await first.initialize(directory: directory);

      expect(first.mode, LocalDatabaseEncryptionMode.recoveryRequired);
      expect(flaky.values[_modeKey], 'encrypted');

      // The next start, and "try again" in this one, both find the key.
      final next = LocalDatabaseEncryption(storage: flaky);
      await next.initialize(directory: directory);
      expect(next.mode, LocalDatabaseEncryptionMode.encrypted);
      await first.retryInitialization();
      expect(first.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(_readHousehold(pathTo('preppsuite'), key: key), 'Beispielperson');
    }, skip: noCipher);

    test('a recovery stored by an earlier version is asked again', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      storage.values[_modeKey] = 'recoveryRequired';
      storage.values[_keyKey] = key;

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(storage.values[_modeKey], 'encrypted');
    }, skip: noCipher);

    test('starting over keeps the key beside the files it opens', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = key;
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      await encryption.startOverKeepingUnreadableFiles();

      final locked = directory
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .singleWhere((name) => name.contains('.locked-'));
      final stamp = locked.substring(locked.indexOf('.locked-'));
      expect(storage.values['$_keyKey$stamp'], key);
      expect(storage.values[_keyKey], isNot(key));
      expect(
        _readHousehold('${directory.path}/$locked', key: key),
        'Beispielperson',
      );
    }, skip: noCipher);
  });

  group('an upgrade cut off between its renames (#393)', () {
    test(
      'a rename that fails leads to recovery, not to a new household',
      () async {
        final recovery = '${pathTo('preppsuite')}.plaintext-recovery';
        _writeHousehold(recovery, 'Beispielperson');
        storage.values[_modeKey] = 'migrating';
        // A virus scanner holding the file has the same effect as a folder
        // that refuses the rename.
        Process.runSync('chmod', ['555', directory.path]);
        addTearDown(() => Process.runSync('chmod', ['755', directory.path]));

        final encryption = LocalDatabaseEncryption(storage: storage);
        await encryption.initializeOrMarkUnavailable(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
        expect(
          () => encryption.open('preppsuite'),
          throwsA(isA<LocalDataUnavailable>()),
        );
        expect(storage.values[_modeKey], 'migrating');

        // Once the file is free again, "try again" repairs it.
        Process.runSync('chmod', ['755', directory.path]);
        await encryption.retryInitialization();
        expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
        expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
      },
      skip: Platform.isWindows ? 'Needs POSIX permissions.' : null,
    );

    test('a copy without its database is kept, without the mark too', () async {
      // The mark is gone (3.0.3 wrote "plaintext" over it), the household
      // is still under its recovery name.
      final recovery = '${pathTo('preppsuite')}.plaintext-recovery';
      _writeHousehold(recovery, 'Beispielperson');
      storage.values[_modeKey] = 'plaintext';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
    });

    test('an encrypted copy left on its own is not thrown away', () async {
      final key = _freshKey();
      final copy = '${pathTo('preppsuite')}.encrypting';
      _writeHousehold(copy, 'Beispielperson', key: key);
      storage.values[_modeKey] = 'migrating';
      storage.values[_keyKey] = key;

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initializeOrMarkUnavailable(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
      expect(_readHousehold(copy, key: key), 'Beispielperson');
      expect(File(pathTo('preppsuite')).existsSync(), isFalse);
    }, skip: noCipher);

    test('the next upgrade stops rather than delete a recovery copy', () async {
      // What 3.0.3 left after a failed repair: an empty database under the
      // household's name, the household under the recovery name.
      _writeHousehold(pathTo('preppsuite'), 'Leer');
      final recovery = '${pathTo('preppsuite')}.plaintext-recovery';
      _writeHousehold(recovery, 'Beispielperson');
      final copy = File('${pathTo('preppsuite')}.encrypting')
        ..writeAsStringSync('copy');
      storage.values[_modeKey] = 'migrating';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(copy.existsSync(), isTrue);

      await expectLater(
        encryption.migrateExistingDatabases(),
        throwsStateError,
      );

      expect(_readHousehold(recovery), 'Beispielperson');
      expect(_readHousehold(pathTo('preppsuite')), 'Leer');
      expect(storage.values[_modeKey], 'plaintext');
      expect(
        () => encryptDatabaseFileForTesting(pathTo('preppsuite'), _freshKey()),
        throwsStateError,
      );
      expect(_readHousehold(recovery), 'Beispielperson');
    }, skip: noCipher);
  });

  group('a device that lost its key', () {
    test('keeps the unreadable files when it starts over', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      storage.values[_modeKey] = 'encrypted';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);

      await encryption.startOverKeepingUnreadableFiles();

      // Usable again, and the old household is still on the disk under a
      // name nothing will open by accident. A key that turns up later --
      // a restored keychain -- still has something to open.
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      final names = directory
          .listSync()
          .map((entity) => entity.uri.pathSegments.last)
          .toList();
      expect(names.where((name) => name.contains('.locked-')), hasLength(1));
      expect(names, isNot(contains('preppsuite.sqlite')));
      expect(storage.values[_keyKey], isNot(key));
    }, skip: noCipher);

    test('asks the device again rather than making anybody restart', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: key);
      storage.values[_modeKey] = 'encrypted';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);

      // The keychain comes back -- unlocked late, restored, plugin loaded
      // on the second attempt.
      storage.values[_keyKey] = key;
      await encryption.retryInitialization();

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
    }, skip: noCipher);

    test('a device with no key store and no data runs unencrypted', () async {
      // A Linux session without `libsecret` is exactly this: the plugin
      // will not load, and on a first start there is nothing to protect
      // yet. Refusing to come up would take a working offline app away
      // over a key it does not need.
      final encryption = LocalDatabaseEncryption(storage: _FailingStorage());

      await encryption.initializeOrMarkUnavailable(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(() => encryption.open('preppsuite'), returnsNormally);
    });

    test(
      'a key-store failure and not-yet-created data folder never abort startup',
      () async {
        // A sandbox container can be created while the first keychain request
        // fails. Flutter still has to reach runApp(); an absent folder has no
        // encrypted household to protect and remains usable in plain mode.
        await directory.delete(recursive: true);
        final encryption = LocalDatabaseEncryption(storage: _FailingStorage());

        await encryption.initializeOrMarkUnavailable(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      },
    );

    test('a device with no key store keeps reading its household', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');

      final encryption = LocalDatabaseEncryption(storage: _FailingStorage());
      await encryption.initializeOrMarkUnavailable(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(_readHousehold(pathTo('preppsuite')), 'Beispielperson');
    });

    test('a device with no key store and encrypted data says so', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: _freshKey());

      final encryption = LocalDatabaseEncryption(storage: _FailingStorage());
      await encryption.initializeOrMarkUnavailable(directory: directory);

      // The same missing key store, and it means something else entirely:
      // a household on the disk that this app cannot open.
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
    }, skip: noCipher);
  });

  group('opening through Drift', () {
    test('creates a new database encrypted, across the isolate', () async {
      // The setup callback is handed to Drift's background isolate. That it
      // can be sent at all is a runtime property nothing checks at compile
      // time, and a callback that fails to cross would leave a plaintext
      // file behind a mode that says otherwise.
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);

      final database = AppDatabase.forTesting(encryption.open('preppsuite'));
      await database.customSelect('SELECT 1').get();
      await database.close();

      expect(_looksLikePlaintext(File(pathTo('preppsuite'))), isFalse);
      expect(
        () => sqlite3.open(pathTo('preppsuite')).select('SELECT 1'),
        throwsA(anything),
        reason: 'and not readable without the key',
      );
    }, skip: noCipher);

    test('a file the migration has not reached yet still opens', () async {
      // The other half of the per-file decision: in a folder that is part
      // way through, the plaintext ones must open without the key.
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson');
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = _freshKey();

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);

      final database = AppDatabase.forTesting(encryption.open('preppsuite'));
      final rows = await database
          .customSelect('SELECT name FROM household')
          .get();
      await database.close();

      expect(rows.single.read<String>('name'), 'Beispielperson');
    }, skip: noCipher);
  });

  group('the cipher (#419)', () {
    test('a new database is chacha20, and a changed page is noticed', () async {
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);

      final database = AppDatabase.forTesting(
        encryption.open('preppsuite_personal_documents'),
      );
      await database.customStatement(
        'CREATE TABLE pages (text TEXT NOT NULL)',
      );
      await database.transaction(() async {
        for (var i = 0; i < 300; i++) {
          await database.customStatement('INSERT INTO pages VALUES (?)', [
            'Seite $i ${'x' * 120}',
          ]);
        }
      });
      await database.close();

      final path = pathTo('preppsuite_personal_documents');
      expect(_cipherOf(path), _chacha20);
      // aes256cbc read the changed page as data, and even
      // `integrity_check` said ok.
      expect(_changedPageGoesUnnoticed(path, storage.values[_keyKey]!), false);
    }, skip: noCipher);

    test('the upgrade of a plain household encrypts with chacha20', () async {
      final path = pathTo('preppsuite');
      _writeHousehold(path, 'Beispielperson');
      final plain = sqlite3.open(path);
      _fillPages(plain);
      plain.close();

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      await encryption.migrateExistingDatabases();

      final key = storage.values[_keyKey]!;
      expect(_cipherOf(path), _chacha20);
      expect(_readHousehold(path, key: key), 'Beispielperson');
      expect(
        () => _readHousehold(path, key: key, cipher: _aes256cbc),
        throwsA(isA<SqliteException>()),
      );
      expect(_changedPageGoesUnnoticed(path, key), isFalse);
    }, skip: noCipher);

    test('what 3.0.3 encrypted with aes256cbc still opens', () async {
      final key = _freshKey();
      final household = pathTo('preppsuite');
      final index = pathTo('preppsuite_knowledge_ab12');
      _writeHousehold(
        household,
        'Beispielperson',
        key: key,
        cipher: _aes256cbc,
      );
      _writeHousehold(index, 'Wissen', key: key, cipher: _aes256cbc);
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = key;

      // The background isolate's way in, which never changes a file.
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(
        directory: directory,
        repairInterruptedMigration: false,
      );
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);

      for (final (name, expected) in [
        ('preppsuite', 'Beispielperson'),
        ('preppsuite_knowledge_ab12', 'Wissen'),
      ]) {
        final database = AppDatabase.forTesting(encryption.open(name));
        final rows = await database
            .customSelect('SELECT name FROM household')
            .get();
        await database.close();
        expect(rows.single.read<String>('name'), expected);
      }
      expect(encryption.opensCleanly(File(household)), isTrue);
      expect(_cipherOf(household), _aes256cbc);
      expect(_cipherOf(index), _aes256cbc);
    }, skip: noCipher);

    test('a hot journal is rolled back with the cipher of its file', () async {
      // The reason the cipher is read from the header and not found out by
      // trying: a connection set to the wrong one rolls the journal back
      // through it. aes256cbc on a chacha20 file wrote garbage over the
      // pages and deleted the journal.
      for (final cipher in [_chacha20, _aes256cbc]) {
        final folder = await directory.createTemp(cipher);
        final path = '${folder.path}/preppsuite.sqlite';
        final key = _freshKey();
        _leaveHotJournal(path, key, cipher);
        final store = _MemoryKeyStorage()
          ..values[_modeKey] = 'encrypted'
          ..values[_keyKey] = key;

        final encryption = LocalDatabaseEncryption(storage: store);
        await encryption.initialize(
          directory: folder,
          repairInterruptedMigration: false,
        );
        final database = AppDatabase.forTesting(encryption.open('preppsuite'));
        final changed = await database
            .customSelect(
              "SELECT count(*) AS n FROM pages WHERE text = 'geaendert'",
            )
            .getSingle();
        final check = await database
            .customSelect('PRAGMA integrity_check')
            .get();
        await database.close();

        expect(changed.read<int>('n'), 0, reason: cipher);
        expect(check.single.data.values.single, 'ok', reason: cipher);
        expect(_readHousehold(path, key: key), 'Beispielperson');
        expect(File('$path-journal').existsSync(), isFalse);
      }
    }, skip: noCipher);

    test('a copy for a carried folder is plain from either cipher', () async {
      for (final cipher in [_chacha20, _aes256cbc]) {
        final key = _freshKey();
        final source = pathTo('preppsuite-$cipher');
        final target = p.join(directory.path, 'plain-$cipher.sqlite');
        _writeHousehold(source, 'Beispielperson', key: key, cipher: cipher);

        await copyDatabaseAsPlaintext(source, target, key: key);

        expect(_looksLikePlaintext(File(target)), isTrue, reason: cipher);
        expect(_readHousehold(target), 'Beispielperson');
        expect(_cipherOf(source), cipher);
      }
    }, skip: noCipher);
  });

  group('a folder that travels', () {
    test('is never encrypted on its own', () async {
      // The key would stay in this machine's keychain while the folder
      // goes to the next computer.
      await startPortableData(
        environment: {'PREPPSUITE_DATA': directory.path},
        executablePath: '${directory.path}/PreppSuite',
      );
      expect(portableLocation.isPortable, isTrue);

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(encryption.canMigrate, isFalse);
    });

    test('arriving somewhere without its key says so', () async {
      // An encrypted folder opened by an installation that knows nothing
      // about it: a second computer, or one restored without its
      // keychain. Reading it plainly would fail a screen later with
      // SQLite's own words.
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: _freshKey());

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
    }, skip: noCipher);
  });

  group('a carried folder and the installation beside it (#392)', () {
    Future<void> carry() => startPortableData(
      environment: {'PREPPSUITE_DATA': directory.path},
      executablePath: '${directory.path}/PreppSuite',
    );

    test('ignores the mode this computer keeps for its installation', () async {
      // The installation here is encrypted; what the carried copy creates
      // still has to open on the next computer.
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = _freshKey();
      await carry();

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);

      final database = AppDatabase.forTesting(encryption.open('preppsuite'));
      await database.customSelect('SELECT 1').get();
      await database.close();

      expect(_looksLikePlaintext(File(pathTo('preppsuite'))), isTrue);
      expect(storage.values[_modeKey], 'encrypted');
    }, skip: noCipher);

    test('writes nothing into the key store the installation reads', () async {
      await carry();
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(storage.values, isEmpty);

      // The installation started next sets its household up encrypted.
      resetPortableData();
      final installation = await directory.createTemp('installiert');
      final installed = LocalDatabaseEncryption(storage: storage);
      await installed.initialize(directory: installation);
      expect(installed.mode, LocalDatabaseEncryptionMode.encrypted);
    }, skip: noCipher);

    test('an installation 3.0.3 marked plain from a carried copy is '
        'set up encrypted', () async {
      storage.values[_modeKey] = 'plaintext';

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(storage.values[_modeKey], 'encrypted');
    }, skip: noCipher);

    test('what an earlier version encrypted here opens, and nothing new is '
        'encrypted', () async {
      final key = _freshKey();
      // 3.0.3 encrypted with aes256cbc; a carried folder is never moved
      // to chacha20 (#419).
      _writeHousehold(
        pathTo('preppsuite'),
        'Beispielperson',
        key: key,
        cipher: _aes256cbc,
      );
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = key;
      await carry();

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);

      final household = AppDatabase.forTesting(encryption.open('preppsuite'));
      final rows = await household
          .customSelect('SELECT name FROM household')
          .get();
      await household.close();
      expect(rows.single.read<String>('name'), 'Beispielperson');

      final documents = AppDatabase.forTesting(
        encryption.open('preppsuite_personal_documents'),
      );
      await documents.customSelect('SELECT 1').get();
      await documents.close();
      expect(
        _looksLikePlaintext(File(pathTo('preppsuite_personal_documents'))),
        isTrue,
      );
    }, skip: noCipher);

    test('a folder encrypted under another key goes to recovery', () async {
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: _freshKey());
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = _freshKey();
      await carry();

      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
    }, skip: noCipher);

    test('starting over leaves the installation\'s key alone', () async {
      final key = _freshKey();
      _writeHousehold(pathTo('preppsuite'), 'Beispielperson', key: _freshKey());
      storage.values[_modeKey] = 'encrypted';
      storage.values[_keyKey] = key;
      await carry();
      final encryption = LocalDatabaseEncryption(storage: storage);
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);

      await encryption.startOverKeepingUnreadableFiles();

      expect(encryption.mode, LocalDatabaseEncryptionMode.plaintext);
      expect(storage.values, {_modeKey: 'encrypted', _keyKey: key});
    }, skip: noCipher);
  });
}

/// A key store that misses a read of the key now and then, the way a
/// keyring that is still locked or a Keystore error does. Swallowed to
/// null, as `SecureLocalDatabaseKeyStorage` does.
class _FlakyKeyStorage extends _MemoryKeyStorage {
  int failedKeyReads = 0;

  @override
  Future<String?> read(String key) async {
    if (key == _keyKey && failedKeyReads > 0) {
      failedKeyReads--;
      return null;
    }
    return super.read(key);
  }
}

/// A key store that refuses, the way a Linux session without a keyring or
/// a keychain that has not been unlocked does.
class _FailingStorage implements LocalDatabaseKeyStorage {
  @override
  Future<void> delete(String key) async => throw StateError('no key store');

  @override
  Future<String?> read(String key) async => throw StateError('no key store');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('no key store');
}
