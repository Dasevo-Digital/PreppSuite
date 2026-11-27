import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:drift/drift.dart'
    show OpeningDetails, QueryExecutor, QueryExecutorUser;
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'package:preppsuite_flutter/core/database_snapshots.dart';
import 'package:preppsuite_flutter/core/error_log.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';

/// The move of the household's own databases from aes256cbc to chacha20
/// at the app's start (#419).

class _MemoryKeyStorage implements LocalDatabaseKeyStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

/// Opens through `LocalDatabaseEncryption.open` without the app's schema:
/// the files here carry Drift's schema version 7 and are left at it.
class _Opener implements QueryExecutorUser {
  const _Opener();

  @override
  int get schemaVersion => 7;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

const _modeKey = 'preppsuite.localDatabaseEncryption.mode.v1';
const _keyKey = 'preppsuite.localDatabaseEncryption.key.v1';
const _chacha20 = 'chacha20';
const _aes256cbc = 'aes256cbc';
const _lock = '.preppsuite-in-use';

const _household = 'preppsuite.sqlite';
const _documents = 'preppsuite_personal_documents.sqlite';

String _sql(String value) => "'${value.replaceAll("'", "''")}'";

String _freshKey() {
  final random = Random.secure();
  return base64UrlEncode(List<int>.generate(32, (_) => random.nextInt(256)));
}

/// Byte 20 of the header, in the clear under every cipher: 32 bytes kept
/// free per page for chacha20's nonce and tag, none for aes256cbc.
String _cipherOf(String path) {
  final handle = File(path).openSync();
  try {
    return handle.readSync(24)[20] == 0 ? _aes256cbc : _chacha20;
  } finally {
    handle.closeSync();
  }
}

Database _openWith(String path, String key, {String? cipher}) {
  final database = sqlite3.open(path);
  database.execute("PRAGMA cipher = '${cipher ?? _cipherOf(path)}'");
  database.execute('PRAGMA key = ${_sql(key)}');
  return database;
}

/// A database as 3.0.3 leaves one: a household row, rows over several
/// pages with text and blobs, a full-text table, Drift's schema version.
void _writeDatabase(
  String path,
  String key, {
  String cipher = _aes256cbc,
  String name = 'Beispielperson',
}) {
  final database = _openWith(path, key, cipher: cipher);
  try {
    database
      ..execute('PRAGMA user_version = 7')
      ..execute('CREATE TABLE household (name TEXT NOT NULL)')
      ..execute('INSERT INTO household VALUES (?)', [name])
      ..execute(
        'CREATE TABLE pages (id INTEGER PRIMARY KEY, text TEXT, data BLOB)',
      )
      ..execute('BEGIN');
    for (var i = 0; i < 300; i++) {
      database.execute('INSERT INTO pages (text, data) VALUES (?, ?)', [
        'Seite $i ${'x' * 120}',
        Uint8List.fromList([i % 256, 1, 2]),
      ]);
    }
    database
      ..execute('COMMIT')
      ..execute(
        'CREATE VIRTUAL TABLE documents USING fts5('
        "id UNINDEXED, label, text, tokenize='unicode61 remove_diacritics 2')",
      )
      ..execute(
        "INSERT INTO documents VALUES ('pass', 'Reisepass', 'Gültig bis 2031')",
      );
  } finally {
    database.close();
  }
}

/// Everything in a database written by [_writeDatabase], read with the
/// cipher its header names.
String _contents(String path, String key) {
  final database = _openWith(path, key);
  try {
    return jsonEncode({
      'version': database.select('PRAGMA user_version').single.values.single,
      'household': [
        for (final row in database.select('SELECT name FROM household'))
          row['name'],
      ],
      'pages': [
        for (final row in database.select(
          'SELECT id, text, hex(data) FROM pages ORDER BY id',
        ))
          row.values,
      ],
      'found': [
        for (final row in database.select(
          "SELECT id FROM documents WHERE documents MATCH 'gultig'",
        ))
          row['id'],
      ],
    });
  } finally {
    database.close();
  }
}

/// Whether the database still reads as sound after one bit of a later
/// page was flipped on the disk.
bool _changedPageGoesUnnoticed(String path, String key) {
  final bytes = File(path).readAsBytesSync();
  bytes[3 * 4096 + 1000] ^= 0x01;
  File(path).writeAsBytesSync(bytes, flush: true);
  try {
    final database = _openWith(path, key);
    try {
      final check = database.select('PRAGMA integrity_check');
      database.select('SELECT * FROM pages');
      return check.length == 1 && check.single.values.single == 'ok';
    } finally {
      database.close();
    }
  } on SqliteException {
    return false;
  }
}

Future<List<Map<String, Object?>>> _readThroughApp(
  LocalDatabaseEncryption encryption,
  String name,
  String select,
) async {
  final executor = encryption.open(name);
  try {
    await executor.ensureOpen(const _Opener());
    return await executor.runSelect(select, const []);
  } finally {
    await executor.close();
  }
}

void main() {
  late Directory directory;
  late _MemoryKeyStorage storage;
  late String key;

  String pathTo(String file) => p.join(directory.path, file);

  /// The files in the folder, without the lock.
  List<String> files() => [
    for (final entity in directory.listSync())
      if (entity is File) p.basename(entity.path),
  ].where((name) => !name.startsWith(_lock)).toList()..sort();

  LocalDatabaseEncryption start({bool Function(String, String)? stop}) =>
      LocalDatabaseEncryption(
        storage: storage,
        cipherUpgradeStop: stop,
        upgradeWait: const Duration(milliseconds: 300),
      );

  /// Stops at [step] of the household, as if the process ended there.
  bool Function(String, String) stopAt(String step) =>
      (path, at) => p.basename(path) == _household && at == step;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('preppsuite-419-');
    key = _freshKey();
    storage = _MemoryKeyStorage()
      ..values[_modeKey] = 'encrypted'
      ..values[_keyKey] = key;
    await ErrorLog.instance.clear();
  });

  tearDown(() async {
    resetPortableData();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  final noCipher = LocalDatabaseEncryption.cipherAvailable
      ? null
      : 'The SQLite library in this build has no cipher.';

  group('the start moves the household to chacha20', () {
    test('the household and its document index, every row kept', () async {
      _writeDatabase(pathTo(_household), key);
      _writeDatabase(pathTo(_documents), key, name: 'Unterlagen');
      final before = {
        for (final name in [_household, _documents])
          name: _contents(pathTo(name), key),
      };

      final encryption = start();
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      for (final name in [_household, _documents]) {
        expect(_cipherOf(pathTo(name)), _chacha20, reason: name);
        expect(_contents(pathTo(name), key), before[name], reason: name);
        expect(
          () => _openWith(
            pathTo(name),
            key,
            cipher: _aes256cbc,
          ).select('SELECT 1 FROM household'),
          throwsA(isA<SqliteException>()),
        );
      }
      expect(files(), [_household, _documents]);
      final rows = await _readThroughApp(
        encryption,
        'preppsuite',
        'SELECT name FROM household',
      );
      expect(rows.single['name'], 'Beispielperson');
      expect(await ErrorLog.instance.read(), isEmpty);
      expect(_changedPageGoesUnnoticed(pathTo(_household), key), isFalse);
    }, skip: noCipher);

    test('a household left with a hot journal is moved rolled back', () async {
      final path = pathTo(_household);
      _writeDatabase('$path.source', key);
      final before = _contents('$path.source', key);
      final writing = _openWith('$path.source', key)
        ..execute('PRAGMA cache_size = 2')
        ..execute('BEGIN')
        ..execute("UPDATE pages SET text = 'geaendert'");
      File('$path.source').copySync(path);
      File('$path.source-journal').copySync('$path-journal');
      writing
        ..execute('ROLLBACK')
        ..close();
      File('$path.source').deleteSync();

      await start().initialize(directory: directory);

      expect(_cipherOf(path), _chacha20);
      expect(_contents(path, key), before);
      expect(files(), [_household]);
    }, skip: noCipher);

    test('nothing is moved after this process opened a database', () async {
      // A restored daily copy brings aes256cbc back while the app runs.
      // Only the next start may move it: the app holds it open.
      final encryption = start();
      await encryption.initialize(directory: directory);
      await _readThroughApp(
        encryption,
        'preppsuite_personal_documents',
        'SELECT 1',
      );
      _writeDatabase(pathTo(_household), key);

      await encryption.retryInitialization();

      expect(_cipherOf(pathTo(_household)), _aes256cbc);
      await start().initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _chacha20);
    }, skip: noCipher);
  });

  group('a start stopped part way (#419)', () {
    // What a stop after each step leaves beside the document index, which
    // the stopped start never reached.
    const leftBehind = {
      'copied': [_household, '$_household.rekeying', _documents],
      'rekeyed': [_household, '$_household.rekeying', _documents],
      'verified': [_household, '$_household.rekeying', _documents],
      'set aside': [
        '$_household.aes256cbc-recovery',
        '$_household.rekeying',
        _documents,
      ],
      'swapped': [_household, '$_household.aes256cbc-recovery', _documents],
      'opened': [_household, '$_household.aes256cbc-recovery', _documents],
    };

    for (final MapEntry(key: step, value: state) in leftBehind.entries) {
      test('after "$step" leaves every database openable, and the next '
          'start finishes', () async {
        _writeDatabase(pathTo(_household), key);
        _writeDatabase(pathTo(_documents), key, name: 'Unterlagen');
        final before = {
          for (final name in [_household, _documents])
            name: _contents(pathTo(name), key),
        };

        await start(stop: stopAt(step)).initialize(directory: directory);
        expect(files(), state);

        // The background poll in that state opens what is there, or
        // nothing; never an empty household beside the real one.
        final background = start();
        await background.initialize(
          directory: directory,
          repairInterruptedMigration: false,
        );
        if (step == 'set aside') {
          expect(background.mode, LocalDatabaseEncryptionMode.recoveryRequired);
          expect(File(pathTo(_household)).existsSync(), isFalse);
        } else {
          expect(background.mode, LocalDatabaseEncryptionMode.encrypted);
          for (final (name, expected) in [
            ('preppsuite', 'Beispielperson'),
            ('preppsuite_personal_documents', 'Unterlagen'),
          ]) {
            final rows = await _readThroughApp(
              background,
              name,
              'SELECT name FROM household',
            );
            expect(rows.single['name'], expected);
          }
        }
        background.finishBackgroundRun();

        final next = start();
        await next.initialize(directory: directory);

        expect(next.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(files(), [_household, _documents]);
        for (final name in [_household, _documents]) {
          expect(_cipherOf(pathTo(name)), _chacha20, reason: name);
          expect(_contents(pathTo(name), key), before[name], reason: name);
        }
      }, skip: noCipher);
    }

    test('a copy cut off half written is thrown away', () async {
      _writeDatabase(pathTo(_household), key);
      final before = _contents(pathTo(_household), key);
      File(pathTo('$_household.rekeying')).writeAsStringSync('halb');
      File(pathTo('$_household.rekeying-journal')).writeAsStringSync('halb');

      await start().initialize(directory: directory);

      expect(files(), [_household]);
      expect(_cipherOf(pathTo(_household)), _chacha20);
      expect(_contents(pathTo(_household), key), before);
    }, skip: noCipher);

    test('an original that cannot be renamed back leads to recovery, and '
        '"try again" finishes', () async {
      _writeDatabase(pathTo('$_household.aes256cbc-recovery'), key);
      final before = _contents(pathTo('$_household.aes256cbc-recovery'), key);
      File(pathTo('$_household.rekeying')).writeAsStringSync('Kopie');
      Process.runSync('chmod', ['555', directory.path]);
      addTearDown(() => Process.runSync('chmod', ['755', directory.path]));

      final encryption = start();
      await encryption.initializeOrMarkUnavailable(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);
      expect(
        () => encryption.open('preppsuite'),
        throwsA(isA<LocalDataUnavailable>()),
      );
      expect(File(pathTo(_household)).existsSync(), isFalse);

      Process.runSync('chmod', ['755', directory.path]);
      await encryption.retryInitialization();

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(files(), [_household]);
      expect(_cipherOf(pathTo(_household)), _chacha20);
      expect(_contents(pathTo(_household), key), before);
    }, skip: Platform.isWindows ? 'Needs POSIX permissions.' : noCipher);

    test('an original beside a file it cannot vouch for is kept', () async {
      // Not a state the move leaves: an empty aes256cbc file under the
      // household's name (a version that did not know the name made one),
      // or a re-encrypted one that does not pass its check.
      for (final (what, write) in [
        (
          'aes256cbc',
          () => _writeDatabase(pathTo(_household), key, name: 'Leer'),
        ),
        (
          'damaged chacha20',
          () {
            _writeDatabase(pathTo(_household), key, cipher: _chacha20);
            _changedPageGoesUnnoticed(pathTo(_household), key);
          },
        ),
      ]) {
        final original = pathTo('$_household.aes256cbc-recovery');
        _writeDatabase(original, key);
        final kept = File(original).readAsBytesSync();
        write();

        final encryption = start();
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(File(original).readAsBytesSync(), kept, reason: what);
        expect(files(), [_household, '$_household.aes256cbc-recovery']);
        File(original).deleteSync();
        File(pathTo(_household)).deleteSync();
      }
    }, skip: noCipher);

    test('starting over sets the copies aside with the household', () async {
      _writeDatabase(pathTo(_household), key, cipher: _chacha20);
      _writeDatabase(pathTo('$_household.aes256cbc-recovery'), key);
      storage.values.remove(_keyKey);
      final encryption = start();
      await encryption.initialize(directory: directory);
      expect(encryption.mode, LocalDatabaseEncryptionMode.recoveryRequired);

      await encryption.startOverKeepingUnreadableFiles();

      expect(files().where((name) => !name.contains('.locked-')), isEmpty);
      expect(
        files().where((name) => name.startsWith('$_household.aes256cbc')),
        hasLength(1),
      );
    }, skip: noCipher);
  });

  group('a move that fails (#419)', () {
    for (final (step, what) in [
      ('copied', 'the rekey'),
      ('rekeyed', 'the check'),
    ]) {
      test('in $what keeps the aes256cbc original in place and in use, '
          'and the next start tries again', () async {
        _writeDatabase(pathTo(_household), key);
        final before = _contents(pathTo(_household), key);

        final encryption = start(
          stop: (path, at) {
            if (stopAt(step)(path, at)) throw StateError('cut off');
            return false;
          },
        );
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(files(), [_household]);
        expect(_cipherOf(pathTo(_household)), _aes256cbc);
        expect(_contents(pathTo(_household), key), before);
        final rows = await _readThroughApp(
          encryption,
          'preppsuite',
          'SELECT name FROM household',
        );
        expect(rows.single['name'], 'Beispielperson');
        expect(await ErrorLog.instance.read(), contains('chacha20 upgrade'));

        await start().initialize(directory: directory);
        expect(_cipherOf(pathTo(_household)), _chacha20);
        expect(_contents(pathTo(_household), key), before);
      }, skip: noCipher);
    }

    for (final (what, change) in [
      ('a row missing', 'DELETE FROM pages WHERE id = 7'),
      // Same counts: only comparing the rows notices.
      ('one value changed', "UPDATE pages SET text = 'anders' WHERE id = 7"),
      ('another schema version', 'PRAGMA user_version = 3'),
    ]) {
      test('a copy with $what is not swapped in', () async {
        _writeDatabase(pathTo(_household), key);
        final before = _contents(pathTo(_household), key);

        final encryption = start(
          stop: (path, at) {
            if (stopAt('rekeyed')(path, at)) {
              _openWith('$path.rekeying', key, cipher: _chacha20)
                ..execute(change)
                ..close();
            }
            return false;
          },
        );
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(files(), [_household]);
        expect(_cipherOf(pathTo(_household)), _aes256cbc);
        expect(_contents(pathTo(_household), key), before);
      }, skip: noCipher);
    }

    test('a write into the original after its copy stops the swap', () async {
      _writeDatabase(pathTo(_household), key);

      await start(
        stop: (path, at) {
          if (stopAt('verified')(path, at)) {
            _openWith(path, key)
              ..execute("INSERT INTO household VALUES ('Nachtrag')")
              ..close();
          }
          return false;
        },
      ).initialize(directory: directory);

      expect(files(), [_household]);
      expect(_cipherOf(pathTo(_household)), _aes256cbc);
      expect(
        jsonDecode(_contents(pathTo(_household), key))['household'],
        ['Beispielperson', 'Nachtrag'],
      );
    }, skip: noCipher);
  });

  group('other users of the databases (#419)', () {
    test(
      'a background run opens both ciphers and never moves a file',
      () async {
        _writeDatabase(pathTo(_household), key);
        _writeDatabase(
          pathTo(_documents),
          key,
          cipher: _chacha20,
          name: 'Unterlagen',
        );
        final bytes = File(pathTo(_household)).readAsBytesSync();

        final background = start();
        await background.initialize(
          directory: directory,
          repairInterruptedMigration: false,
        );
        for (final (name, expected) in [
          ('preppsuite', 'Beispielperson'),
          ('preppsuite_personal_documents', 'Unterlagen'),
        ]) {
          final rows = await _readThroughApp(
            background,
            name,
            'SELECT name FROM household',
          );
          expect(rows.single['name'], expected);
        }
        background.finishBackgroundRun();

        expect(File(pathTo(_household)).readAsBytesSync(), bytes);
        expect(_cipherOf(pathTo(_documents)), _chacha20);
        expect(files(), [_household, _documents]);
      },
      skip: noCipher,
    );

    test(
      'a start leaves the files to a background run that has them',
      () async {
        _writeDatabase(pathTo(_household), key);
        final background = start();
        await background.initialize(
          directory: directory,
          repairInterruptedMigration: false,
        );

        final encryption = start();
        await encryption.initialize(directory: directory);

        expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
        expect(_cipherOf(pathTo(_household)), _aes256cbc);
        expect(files(), [_household]);

        background.finishBackgroundRun();
        await start().initialize(directory: directory);
        expect(_cipherOf(pathTo(_household)), _chacha20);
      },
      skip: noCipher,
    );

    test('a background run waits for a start that is moving them, and '
        'gives up with LocalDataBusy', () async {
      _writeDatabase(pathTo(_household), key);
      Object? held;
      await start(
        stop: (path, at) {
          if (stopAt('copied')(path, at)) {
            // Taken alone for the whole move: nothing can join it.
            final probe = sqlite3.open(pathTo(_lock));
            try {
              probe
                ..execute('PRAGMA busy_timeout = 0')
                ..execute('BEGIN')
                ..select('SELECT count(*) FROM sqlite_master');
            } on SqliteException catch (error) {
              held = error.resultCode;
            } finally {
              probe.close();
            }
          }
          return false;
        },
      ).initialize(directory: directory);
      expect(held, 5, reason: 'SQLITE_BUSY');

      final moving = sqlite3.open(pathTo(_lock))..execute('BEGIN EXCLUSIVE');
      await expectLater(
        start().initialize(
          directory: directory,
          repairInterruptedMigration: false,
        ),
        throwsA(isA<LocalDataBusy>()),
      );
      moving
        ..execute('ROLLBACK')
        ..close();

      final background = start();
      await background.initialize(
        directory: directory,
        repairInterruptedMigration: false,
      );
      expect(background.mode, LocalDatabaseEncryptionMode.encrypted);
      background.finishBackgroundRun();
    }, skip: noCipher);

    test('a lock file that is not a database is replaced', () async {
      _writeDatabase(pathTo(_household), key);
      File(pathTo(_lock)).writeAsStringSync('kein Schloss ' * 10);

      await start().initialize(directory: directory);

      expect(_cipherOf(pathTo(_household)), _chacha20);
    }, skip: noCipher);

    test('a window holds the files against another window\'s start', () async {
      // Two windows on a desktop are two processes with the same files.
      _writeDatabase(pathTo(_household), key);
      final first = LocalDatabaseEncryption(
        storage: storage,
        holdAgainstOtherInstances: true,
      );
      await first.initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _chacha20);

      // The first window puts back a copy from before the move.
      _writeDatabase(pathTo('preppsuite_alt.sqlite'), key);
      File(pathTo(_household)).deleteSync();
      File(pathTo('preppsuite_alt.sqlite')).renameSync(pathTo(_household));

      await start().initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _aes256cbc);

      first.releaseForExit();
      await start().initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _chacha20);
    }, skip: noCipher);

    test('a window waits while another one moves the files', () async {
      _writeDatabase(pathTo(_household), key);
      final moving = sqlite3.open(pathTo(_lock))..execute('BEGIN EXCLUSIVE');
      final second = LocalDatabaseEncryption(
        storage: storage,
        holdAgainstOtherInstances: true,
        upgradeWait: const Duration(milliseconds: 300),
      );

      await second.initializeOrMarkUnavailable(directory: directory);

      expect(second.mode, LocalDatabaseEncryptionMode.recoveryRequired);
      moving
        ..execute('ROLLBACK')
        ..close();
      await second.retryInitialization();
      expect(second.mode, LocalDatabaseEncryptionMode.encrypted);
      expect(_cipherOf(pathTo(_household)), _chacha20);
      second.releaseForExit();
    }, skip: noCipher);

    test('a daily copy taken before the move still restores', () async {
      _writeDatabase(pathTo(_household), key);
      final before = _contents(pathTo(_household), key);
      final snapshots = DatabaseSnapshots(File(pathTo(_household)));
      final copy = (await snapshots.takeIfDue((target) async {
        _openWith(pathTo(_household), key)
          ..execute('VACUUM INTO ${_sql(target)}')
          ..close();
      }, now: DateTime.utc(2026, 11, 26, 8)))!;
      expect(_cipherOf(copy.path), _aes256cbc);

      final encryption = start();
      await encryption.initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _chacha20);
      expect(_cipherOf(copy.path), _aes256cbc, reason: 'copies are not moved');

      expect(encryption.opensCleanly(copy), isTrue);
      await snapshots.restore(copy, now: DateTime.utc(2026, 11, 27, 8));
      final rows = await _readThroughApp(
        encryption,
        'preppsuite',
        'SELECT name FROM household',
      );
      expect(rows.single['name'], 'Beispielperson');

      await start().initialize(directory: directory);
      expect(_cipherOf(pathTo(_household)), _chacha20);
      expect(_contents(pathTo(_household), key), before);
    }, skip: noCipher);

    test('a knowledge index keeps aes256cbc and opens; a new one is '
        'chacha20', () async {
      _writeDatabase(pathTo(_household), key);
      final indexes = ['preppsuite_knowledge', 'preppsuite_knowledge_ab12'];
      final bytes = {
        for (final name in indexes)
          name: () {
            _writeDatabase(pathTo('$name.sqlite'), key, name: name);
            return File(pathTo('$name.sqlite')).readAsBytesSync();
          }(),
      };

      final encryption = start();
      await encryption.initialize(directory: directory);

      expect(_cipherOf(pathTo(_household)), _chacha20);
      for (final name in indexes) {
        expect(File(pathTo('$name.sqlite')).readAsBytesSync(), bytes[name]);
        final rows = await _readThroughApp(
          encryption,
          name,
          'SELECT name FROM household',
        );
        expect(rows.single['name'], name);
      }
      final created = encryption.open('preppsuite_knowledge_cd34');
      await created.ensureOpen(const _Opener());
      await created.runCustom('CREATE TABLE terms (term TEXT)');
      await created.close();
      expect(_cipherOf(pathTo('preppsuite_knowledge_cd34.sqlite')), _chacha20);
    }, skip: noCipher);

    test('a carried folder is left as it is', () async {
      await startPortableData(
        environment: {'PREPPSUITE_DATA': directory.path},
        executablePath: '${directory.path}/PreppSuite',
      );
      _writeDatabase(pathTo(_household), key);
      final bytes = File(pathTo(_household)).readAsBytesSync();

      final encryption = start();
      await encryption.initialize(directory: directory);

      expect(encryption.mode, LocalDatabaseEncryptionMode.encrypted);
      final rows = await _readThroughApp(
        encryption,
        'preppsuite',
        'SELECT name FROM household',
      );
      expect(rows.single['name'], 'Beispielperson');
      expect(File(pathTo(_household)).readAsBytesSync(), bytes);
      expect(File(pathTo(_lock)).existsSync(), isFalse);
    }, skip: noCipher);
  });
}
