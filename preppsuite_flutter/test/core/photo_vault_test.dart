import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/photo_vault.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryKeyStorage implements LocalDatabaseKeyStorage {
  final values = <String, String>{};

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

/// The pictures beside the encrypted databases.
///
/// The possessions list photographs valuables with their serial numbers;
/// a copied data folder handed those over in the clear while the database
/// next to them gave away nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late LocalDatabaseEncryption original;
  late LocalDatabaseEncryption encryption;

  // The start of a JPEG and something after it.
  final picture = Uint8List.fromList([
    0xff, 0xd8, 0xff, 0xe0, //
    ...List.generate(4096, (i) => i % 251),
  ]);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PhotoVault.forgetDerivedKey();
    directory = await Directory.systemTemp.createTemp('preppsuite-vault-');
    original = LocalDatabaseEncryption.instance;
    encryption = LocalDatabaseEncryption(storage: _MemoryKeyStorage());
    await encryption.initialize(directory: directory);
    LocalDatabaseEncryption.instance = encryption;
  });

  tearDown(() async {
    LocalDatabaseEncryption.instance = original;
    PhotoVault.forgetDerivedKey();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  File file(String name) => File('${directory.path}/$name');

  test('what is written is sealed, and reads back as it went in', () async {
    final target = file('photo.jpg');

    await const PhotoVault().write(target, picture);

    final stored = target.readAsBytesSync();
    expect(PhotoVault.isSealed(stored), isTrue);
    expect(stored.sublist(0, 4), isNot([0xff, 0xd8, 0xff, 0xe0]));
    expect(await const PhotoVault().read(target), picture);
  });

  test('a plain picture is read as it is, and sealed by the read', () async {
    final target = file('old.jpg')..writeAsBytesSync(picture);

    expect(await const PhotoVault().read(target), picture);

    expect(PhotoVault.isSealed(target.readAsBytesSync()), isTrue);
    expect(await const PhotoVault().read(target), picture);
  });

  test('the start-up sweep seals what nobody opened', () async {
    file('a.jpg').writeAsBytesSync(picture);
    file('b.jpg').writeAsBytesSync(picture);
    await const PhotoVault().write(file('c.jpg'), picture);

    expect(await const PhotoVault().sealDirectory(directory), 2);

    for (final name in ['a.jpg', 'b.jpg', 'c.jpg']) {
      expect(PhotoVault.isSealed(file(name).readAsBytesSync()), isTrue);
    }
    expect(
      directory.listSync().where((e) => e.path.endsWith('.tmp')),
      isEmpty,
    );
  });

  test('another installation\'s key opens nothing', () async {
    final target = file('photo.jpg');
    await const PhotoVault().write(target, picture);

    final other = LocalDatabaseEncryption(storage: _MemoryKeyStorage());
    final otherDirectory = await Directory.systemTemp.createTemp('vault-b-');
    addTearDown(() => otherDirectory.delete(recursive: true));
    await other.initialize(directory: otherDirectory);
    PhotoVault.forgetDerivedKey();

    expect(await PhotoVault(other).read(target), isNull);
  });

  test('a missing picture is null, not an error', () async {
    expect(await const PhotoVault().read(file('nothing.jpg')), isNull);
  });
}
