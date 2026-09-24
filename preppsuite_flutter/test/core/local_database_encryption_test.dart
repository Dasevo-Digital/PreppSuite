import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

/// A database holding one recognisable row, so that "the household came
/// back" can be asserted on its contents rather than on a file existing.
void _writeHousehold(String path, String name, {String? key}) {
  final database = sqlite3.open(path);
  try {
    if (key != null) {
      database.execute("PRAGMA cipher = 'aes256cbc'");
      database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    }
    database
      ..execute('CREATE TABLE household (name TEXT NOT NULL)')
      ..execute('INSERT INTO household VALUES (${_sqlLiteral(name)})');
  } finally {
    database.close();
  }
}

String _readHousehold(String path, {String? key}) {
  final database = sqlite3.open(path);
  try {
    if (key != null) {
      database.execute("PRAGMA cipher = 'aes256cbc'");
      database.execute('PRAGMA key = ${_sqlLiteral(key)}');
    }
    return database.select('SELECT name FROM household').single['name']
        as String;
  } finally {
    database.close();
  }
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
