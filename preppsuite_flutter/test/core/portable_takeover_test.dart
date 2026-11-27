import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/photo_vault.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/core/portable_preferences.dart';
import 'package:preppsuite_flutter/core/portable_takeover.dart';
import 'package:preppsuite_flutter/core/private_preferences.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_photo_service.dart';

class _MemoryKeyStorage implements LocalDatabaseKeyStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

const _keyKey = 'preppsuite.localDatabaseEncryption.key.v1';
const _modeKey = 'preppsuite.localDatabaseEncryption.mode.v1';

String _sqlLiteral(String value) => "'${value.replaceAll("'", "''")}'";

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
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
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

bool _plain(String path) {
  final handle = File(path).openSync();
  try {
    return utf8.decode(handle.readSync(16), allowMalformed: true) ==
        'SQLite format 3\u0000';
  } finally {
    handle.closeSync();
  }
}

final _picture = Uint8List.fromList([
  0xff, 0xd8, 0xff, 0xe0, //
  ...List.generate(2048, (i) => i % 251),
]);

/// A carried folder's first start beside an installation (#392).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final noCipher = LocalDatabaseEncryption.cipherAvailable
      ? null
      : 'The SQLite library in this build has no cipher.';

  late Directory workspace;
  late Directory installation;
  late Directory folder;
  late SharedPreferencesStorePlatform platform;

  setUp(() async {
    workspace = Directory.systemTemp.createTempSync('takeover');
    installation = Directory(p.join(workspace.path, 'installiert'))
      ..createSync();
    folder = Directory(p.join(workspace.path, 'PreppSuite-Daten'))
      ..createSync();
    SharedPreferences.setMockInitialValues({});
    platform = SharedPreferencesStorePlatform.instance;
    PrivatePreferences.forgetDerivedKey();
    PhotoVault.forgetDerivedKey();
  });

  tearDown(() {
    SharedPreferencesStorePlatform.instance = platform;
    resetPortableData();
    workspace.deleteSync(recursive: true);
  });

  /// An installation set up encrypted, as a new one is since 3.0.3 on a
  /// Mac: database, sealed settings and sealed pictures, all under its key.
  Future<({String key, InMemorySharedPreferencesStore settings, String sealed})>
  encryptedInstallation() async {
    final storage = _MemoryKeyStorage();
    final encryption = LocalDatabaseEncryption(storage: storage);
    await encryption.initialize(directory: installation);
    final key = storage.values[_keyKey]!;
    _writeHousehold(
      p.join(installation.path, 'preppsuite.sqlite'),
      'Beispielhaushalt',
      key: key,
    );
    _writeHousehold(
      p.join(installation.path, 'preppsuite_personal_documents.sqlite'),
      'Unterlagen',
      key: key,
    );
    final photos = Directory(p.join(installation.path, 'inventory_photos'))
      ..createSync();
    await PhotoVault(
      encryption,
    ).write(File(p.join(photos.path, 'versiegelt.jpg')), _picture);
    File(p.join(photos.path, 'alt.jpg')).writeAsBytesSync(_picture);

    await PrivatePreferences(
      encryption,
    ).setString('householdProfile', '{"name":"Beispielhaushalt"}');
    final sealed = (await SharedPreferences.getInstance()).getString(
      'householdProfile',
    )!;
    return (
      key: key,
      sealed: sealed,
      settings: InMemorySharedPreferencesStore.withData({
        'flutter.householdProfile': sealed,
        'flutter.localeOverride': 'de',
      }),
    );
  }

  Future<PortableTakeover> takeOver({
    required SharedPreferencesStorePlatform? settings,
    String? key,
    bool upgrading = false,
  }) async => takeOverInstallation(
    folder: folder,
    installation: installation,
    preferences: await PortablePreferencesStore.open(folder),
    installedPreferences: settings,
    installationKey: () async => (key: key, upgrading: upgrading),
  );

  Future<Map<String, Object>> folderSettings() async =>
      (await PortablePreferencesStore.open(folder)).getAll();

  List<String> namesIn(Directory directory) =>
      directory.listSync().map((entity) => p.basename(entity.path)).toList()
        ..sort();

  group('an encrypted installation', () {
    test('arrives whole and plain', () async {
      final source = await encryptedInstallation();

      final outcome = await takeOver(
        settings: source.settings,
        key: source.key,
      );

      expect(outcome, PortableTakeover.taken);
      final household = p.join(folder.path, 'preppsuite.sqlite');
      expect(_plain(household), isTrue);
      expect(_readHousehold(household), 'Beispielhaushalt');
      expect(
        _readHousehold(
          p.join(folder.path, 'preppsuite_personal_documents.sqlite'),
        ),
        'Unterlagen',
      );
      for (final name in ['versiegelt.jpg', 'alt.jpg']) {
        expect(
          File(p.join(folder.path, 'inventory_photos', name)).readAsBytesSync(),
          _picture,
        );
      }
      final settings = await folderSettings();
      expect(
        settings['flutter.householdProfile'],
        '{"name":"Beispielhaushalt"}',
      );
      expect(settings['flutter.localeOverride'], 'de');

      // Nothing left over, and no journal beside the database.
      expect(namesIn(folder), [
        'einstellungen.json',
        'inventory_photos',
        'preppsuite.sqlite',
        'preppsuite_personal_documents.sqlite',
      ]);
    }, skip: noCipher);

    test('is only read', () async {
      final source = await encryptedInstallation();
      final before = {
        for (final file
            in installation.listSync(recursive: true).whereType<File>())
          file.path: file.readAsBytesSync(),
      };

      await takeOver(settings: source.settings, key: source.key);

      for (final MapEntry(:key, :value) in before.entries) {
        expect(File(key).readAsBytesSync(), value, reason: key);
      }
      expect(
        installation.listSync(recursive: true).whereType<File>().length,
        before.length,
      );
    }, skip: noCipher);

    test('without its key copies nothing, and says so', () async {
      final source = await encryptedInstallation();

      final outcome = await takeOver(settings: source.settings);

      expect(outcome, PortableTakeover.locked);
      expect(namesIn(folder), ['einstellungen.json']);
      expect(await folderSettings(), {
        'flutter.portableTakeover.v1': 'locked',
      });
    }, skip: noCipher);

    test('in the middle of its upgrade is not copied', () async {
      final source = await encryptedInstallation();

      expect(
        await takeOver(
          settings: source.settings,
          key: source.key,
          upgrading: true,
        ),
        PortableTakeover.failed,
      );
      expect(namesIn(folder), ['einstellungen.json']);
    }, skip: noCipher);

    test('with an upgrade cut off between its renames is not copied', () async {
      _writeHousehold(
        p.join(installation.path, 'preppsuite.sqlite.plaintext-recovery'),
        'Beispielhaushalt',
      );

      expect(
        await takeOver(settings: InMemorySharedPreferencesStore.empty()),
        PortableTakeover.failed,
      );
      expect(
        File(p.join(folder.path, 'preppsuite.sqlite')).existsSync(),
        isFalse,
      );
    });

    for (final leftover in [
      'preppsuite.sqlite.aes256cbc-recovery',
      'preppsuite.sqlite.rekeying',
    ]) {
      test(
        'nor with a move to chacha20 left half done: $leftover (#419)',
        () async {
          _writeHousehold(p.join(installation.path, leftover), 'Beispiel');

          expect(
            await takeOver(settings: InMemorySharedPreferencesStore.empty()),
            PortableTakeover.failed,
          );
          expect(
            File(p.join(folder.path, 'preppsuite.sqlite')).existsSync(),
            isFalse,
          );
        },
      );
    }
  });

  group('all or nothing', () {
    test('a database that does not copy takes everything back', () async {
      final source = await encryptedInstallation();
      File(
        p.join(installation.path, 'preppsuite_knowledge_kaputt.sqlite'),
      ).writeAsStringSync('keine Datenbank, nur Text');

      final outcome = await takeOver(
        settings: source.settings,
        key: source.key,
      );

      expect(outcome, PortableTakeover.failed);
      expect(namesIn(folder), ['einstellungen.json']);
      expect(await folderSettings(), {
        'flutter.portableTakeover.v1': 'failed',
      });
    }, skip: noCipher);

    test('a takeover cut off while moving in is finished first', () async {
      // Everything gathered, the household's database not yet in place.
      final staging = Directory(p.join(folder.path, portableTakeoverStaging))
        ..createSync();
      _writeHousehold(
        p.join(staging.path, 'preppsuite.sqlite'),
        'Beispielhaushalt',
      );
      File(
        p.join(staging.path, 'einstellungen.json'),
      ).writeAsStringSync(jsonEncode({'flutter.localeOverride': 'de'}));
      File(p.join(staging.path, 'vollstaendig')).writeAsStringSync('');

      final outcome = await takeOver(
        settings: InMemorySharedPreferencesStore.withData({
          'flutter.localeOverride': 'es',
        }),
      );

      expect(outcome, PortableTakeover.taken);
      expect(
        _readHousehold(p.join(folder.path, 'preppsuite.sqlite')),
        'Beispielhaushalt',
      );
      expect((await folderSettings())['flutter.localeOverride'], 'de');
      expect(staging.existsSync(), isFalse);
    });

    test('a takeover cut off while gathering begins again', () async {
      final staging = Directory(p.join(folder.path, portableTakeoverStaging))
        ..createSync();
      File(p.join(staging.path, 'preppsuite.sqlite')).writeAsStringSync('halb');
      _writeHousehold(
        p.join(installation.path, 'preppsuite.sqlite'),
        'Beispielhaushalt',
      );

      final outcome = await takeOver(
        settings: InMemorySharedPreferencesStore.withData({
          'flutter.localeOverride': 'de',
        }),
      );

      expect(outcome, PortableTakeover.taken);
      expect(
        _readHousehold(p.join(folder.path, 'preppsuite.sqlite')),
        'Beispielhaushalt',
      );
      expect(staging.existsSync(), isFalse);
    });
  });

  group('once', () {
    test('a folder with a household of its own takes nothing', () async {
      _writeHousehold(
        p.join(folder.path, 'preppsuite.sqlite'),
        'Auf dem Stick',
      );
      _writeHousehold(
        p.join(installation.path, 'preppsuite.sqlite'),
        'Auf dem Rechner',
      );
      _writeHousehold(
        p.join(installation.path, 'preppsuite_knowledge_fremd.sqlite'),
        'Fremder Index',
      );
      Directory(p.join(installation.path, 'inventory_photos')).createSync();
      File(
        p.join(installation.path, 'inventory_photos', 'fremd.jpg'),
      ).writeAsBytesSync(_picture);
      File(
        p.join(installation.path, 'preppsuite.sqlite-journal'),
      ).writeAsStringSync('');

      final outcome = await takeOver(
        settings: InMemorySharedPreferencesStore.withData({
          'flutter.localeOverride': 'de',
        }),
      );

      expect(outcome, PortableTakeover.none);
      expect(namesIn(folder), ['preppsuite.sqlite']);
      expect(
        _readHousehold(p.join(folder.path, 'preppsuite.sqlite')),
        'Auf dem Stick',
      );
      expect(await folderSettings(), isEmpty);
    });

    test('and never again after it', () async {
      _writeHousehold(
        p.join(installation.path, 'preppsuite.sqlite'),
        'Beispielhaushalt',
      );
      final settings = InMemorySharedPreferencesStore.withData({
        'flutter.localeOverride': 'de',
      });
      expect(await takeOver(settings: settings), PortableTakeover.taken);

      Directory(p.join(installation.path, 'inventory_photos')).createSync();
      File(
        p.join(installation.path, 'inventory_photos', 'neu.jpg'),
      ).writeAsBytesSync(_picture);
      expect(await takeOver(settings: settings), PortableTakeover.none);

      expect(
        Directory(p.join(folder.path, 'inventory_photos')).existsSync(),
        isFalse,
      );
    });
  });

  group('starting a carried copy', () {
    test('takes the household over once', () async {
      final source = await encryptedInstallation();
      SharedPreferencesStorePlatform.instance = source.settings;
      final keys = _MemoryKeyStorage()
        ..values[_modeKey] = 'encrypted'
        ..values[_keyKey] = source.key;

      await startPortableData(
        environment: {portableEnvironmentVariable: folder.path},
        installationDirectory: () async => installation,
        installationKeys: keys,
      );
      expect(portableTakeover, PortableTakeover.taken);
      expect(
        _readHousehold(p.join(folder.path, 'preppsuite.sqlite')),
        'Beispielhaushalt',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      expect(
        prefs.getString('householdProfile'),
        '{"name":"Beispielhaushalt"}',
      );

      // And the next start leaves it as it is.
      SharedPreferencesStorePlatform.instance = source.settings;
      await startPortableData(
        environment: {portableEnvironmentVariable: folder.path},
        installationDirectory: () async => installation,
        installationKeys: keys,
      );
      expect(portableTakeover, PortableTakeover.none);
    }, skip: noCipher);

    test('a refusal is still said at the next start', () async {
      final source = await encryptedInstallation();
      final elsewhere = _MemoryKeyStorage();

      for (var start = 0; start < 2; start++) {
        SharedPreferencesStorePlatform.instance = source.settings;
        await startPortableData(
          environment: {portableEnvironmentVariable: folder.path},
          installationDirectory: () async => installation,
          installationKeys: elsewhere,
        );
        expect(portableTakeover, PortableTakeover.locked);
      }
      expect(
        File(p.join(folder.path, 'preppsuite.sqlite')).existsSync(),
        isFalse,
      );
    }, skip: noCipher);
  });

  test('a taken-over row reads the folder\'s picture, never the '
      'installation\'s', () async {
    // The row names the picture by the installation's path, and on the
    // same computer that file is there: read, and deleted with the
    // household, from the carried copy.
    final theirs = File(p.join(installation.path, 'inventory_photos', 'a.jpg'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(_picture);
    await startPortableData(
      environment: {portableEnvironmentVariable: folder.path},
      installationDirectory: () async => workspace,
    );

    final ours = p.join(folder.path, 'inventory_photos', 'a.jpg');
    expect(InventoryPhotoService.resolvePhotoPath(theirs.path), ours);
    File(ours)
      ..createSync(recursive: true)
      ..writeAsBytesSync(_picture);
    expect(InventoryPhotoService.resolvePhotoPath(theirs.path), ours);
    expect(
      InventoryPhotoService.resolvePhotoPath('daten:inventory_photos/a.jpg'),
      ours,
    );
  });
}
