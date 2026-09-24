import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/portable_data.dart';
import 'package:preppsuite_flutter/core/private_preferences.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';

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

class _NoKeyStorage implements LocalDatabaseKeyStorage {
  @override
  Future<void> delete(String key) async => throw StateError('no key store');

  @override
  Future<String?> read(String key) async => throw StateError('no key store');

  @override
  Future<void> write(String key, String value) async =>
      throw StateError('no key store');
}

void main() {
  late Directory directory;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('preppsuite-private-');
    SharedPreferences.setMockInitialValues({});
    PrivatePreferences.forgetDerivedKey();
  });

  tearDown(() async {
    resetPortableData();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<LocalDatabaseEncryption> withKey() async {
    final encryption = LocalDatabaseEncryption(storage: _MemoryKeyStorage());
    await encryption.initialize(directory: directory);
    return encryption;
  }

  Future<String?> raw(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);

  test('a stored value is not readable in the preferences file', () async {
    final store = PrivatePreferences(await withKey());

    await store.setString('warningRegion', '05334');

    expect(await raw('warningRegion'), isNot('05334'));
    expect(readEnvelope((await raw('warningRegion'))!), isNotNull);
    expect(await store.getString('warningRegion'), '05334');
  }, skip: _skip);

  test('a value from an older version still reads', () async {
    SharedPreferences.setMockInitialValues({'warningRegion': '05334'});
    final store = PrivatePreferences(await withKey());

    expect(await store.getString('warningRegion'), '05334');
  }, skip: _skip);

  test('and is put away properly on the way out', () async {
    // No migration step to run and none to interrupt: reading it once is
    // what moves it.
    SharedPreferences.setMockInitialValues({'warningRegion': '05334'});
    final store = PrivatePreferences(await withKey());

    await store.getString('warningRegion');

    expect(readEnvelope((await raw('warningRegion'))!), isNotNull);
    expect(await store.getString('warningRegion'), '05334');
  }, skip: _skip);

  test('a device without a key store keeps storing as before', () async {
    final encryption = LocalDatabaseEncryption(storage: _NoKeyStorage());
    await encryption.initializeOrMarkUnavailable(directory: directory);
    final store = PrivatePreferences(encryption);

    await store.setString('warningRegion', '05334');

    // Plainly, exactly as yesterday. Refusing to remember somebody's
    // region because the keyring is missing would be the worse answer.
    expect(await raw('warningRegion'), '05334');
    expect(await store.getString('warningRegion'), '05334');
  });

  test('another installation cannot read it', () async {
    final store = PrivatePreferences(await withKey());
    await store.setString('warningRegion', '05334');
    final envelope = await raw('warningRegion');

    PrivatePreferences.forgetDerivedKey();
    final other = await Directory.systemTemp.createTemp('preppsuite-other-');
    final stranger = LocalDatabaseEncryption(storage: _MemoryKeyStorage());
    await stranger.initialize(directory: other);
    SharedPreferences.setMockInitialValues({'warningRegion': envelope!});

    expect(await PrivatePreferences(stranger).getString('warningRegion'), null);
    await other.delete(recursive: true);
  }, skip: _skip);

  test('the key is derived, not the data key itself', () async {
    // One secret, two uses. A key that opens the databases must not also
    // be the key to the values beside them.
    final encryption = await withKey();
    final store = PrivatePreferences(encryption);
    await store.setString('warningRegion', '05334');

    final asDataKey = FolderKey(encryption.dataKeyBytes!);
    expect(
      await decryptFromFolder((await raw('warningRegion'))!, asDataKey),
      isNull,
    );
  }, skip: _skip);

  test('a carried folder is never sealed with this machine key', () async {
    // The folder is meant to be opened on the next computer, and the key
    // stays in this one's keychain. Sealing it here would lose the
    // household at exactly the moment the stick is plugged in elsewhere.
    final encryption = await withKey();
    await startPortableData(
      environment: {'PREPPSUITE_DATA': directory.path},
      executablePath: '${directory.path}/PreppSuite',
    );
    expect(portableLocation.isPortable, isTrue);

    await PrivatePreferences(encryption).setString('warningRegion', '05334');

    expect(await raw('warningRegion'), '05334');
  }, skip: _skip);
}

/// Without a cipher the installation never reaches encrypted mode and
/// there is no data key to derive from.
final _skip = LocalDatabaseEncryption.cipherAvailable
    ? null
    : 'The SQLite library in this build has no cipher.';
