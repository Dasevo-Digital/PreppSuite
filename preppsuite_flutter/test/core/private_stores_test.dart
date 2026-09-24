import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:preppsuite_flutter/core/local_database_encryption.dart';
import 'package:preppsuite_flutter/core/private_preferences.dart';
import 'package:preppsuite_flutter/features/maps/application/personal_place.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_key_store.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_store.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';

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

/// What the stores actually leave on the disk.
///
/// The container is tested on its own elsewhere. This asks the other
/// question, the one that decides whether any of it matters: does the code
/// that keeps the household's private values go through it.
void main() {
  late Directory directory;
  late LocalDatabaseEncryption original;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    directory = await Directory.systemTemp.createTemp('preppsuite-stores-');
    SharedPreferences.setMockInitialValues({});
    PrivatePreferences.forgetDerivedKey();

    original = LocalDatabaseEncryption.instance;
    final encryption = LocalDatabaseEncryption(storage: _MemoryKeyStorage());
    await encryption.initialize(directory: directory);
    LocalDatabaseEncryption.instance = encryption;
  });

  tearDown(() async {
    LocalDatabaseEncryption.instance = original;
    PrivatePreferences.forgetDerivedKey();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<void> expectSealed(String key, {required String clear}) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);
    expect(stored, isNotNull, reason: '$key was not written at all');
    expect(
      readEnvelope(stored!),
      isNotNull,
      reason: '$key is lying in the preferences file as it was',
    );
    expect(stored, isNot(contains(clear)));
  }

  test('the key to the shared folder', () async {
    // The one that used to be plain text on the argument that the
    // database beside it was plain too.
    await const FolderKeyStore().write('h1', FolderKey.decode(_aKey)!);

    await expectSealed('folderKey.h1', clear: _aKey);
    expect((await const FolderKeyStore().read('h1'))!.encode(), _aKey);
  }, skip: _skip);

  test('who lives here', () async {
    await const HouseholdProfileStore().save(
      const HouseholdProfile(
        id: 'h1',
        name: 'Familie Günther',
        countryCode: 'DE',
        personCount: 2,
      ),
    );

    await expectSealed('householdProfile', clear: 'Günther');
    expect(
      (await const HouseholdProfileStore().load())!.name,
      'Familie Günther',
    );
  }, skip: _skip);

  test('where they live', () async {
    await const WarningRegionStore().save(
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '053340000000',
      ),
    );

    await expectSealed('warningRegionKey', clear: '053340000000');
    expect(
      (await const WarningRegionStore().load())!.ownRegionKey,
      '053340000000',
    );
  }, skip: _skip);

  test('the places they marked', () async {
    await const PersonalPlaceStore().save([
      PersonalPlace(
        id: 'p1',
        label: 'Mutter',
        latitude: 52.1,
        longitude: 10.5,
      ),
    ]);

    await expectSealed('personalMapPlaces.v1', clear: 'Mutter');
    expect((await const PersonalPlaceStore().load()).single.label, 'Mutter');
  }, skip: _skip);

  test('the crisis plan', () async {
    await const PreparednessHubStore().save(
      const PreparednessHubData(
        communication: PlanNote(text: 'Treffpunkt bei der alten Eiche'),
      ),
    );

    await expectSealed('preparednessHubV1', clear: 'Eiche');
    expect(
      (await const PreparednessHubStore().load()).communication.text,
      'Treffpunkt bei der alten Eiche',
    );
  }, skip: _skip);

  test('a handover carries the value, not this device envelope', () async {
    // The far side has a different key. Carrying the envelope would hand
    // it something it can make nothing of -- and the journey is encrypted
    // on its own account, whichever road it takes.
    await const PreparednessHubStore().save(
      const PreparednessHubData(
        communication: PlanNote(text: 'Treffpunkt bei der alten Eiche'),
      ),
    );

    final carried = await readCarriedSettings();

    expect(carried['preparednessHubV1'], contains('Eiche'));
  }, skip: _skip);
}

const _aKey = 'bxTPeHfz7tHvVJFM5wTSTOdPLXFGUVxJ4A5vXDYKNfg=';

final _skip = LocalDatabaseEncryption.cipherAvailable
    ? null
    : 'The SQLite library in this build has no cipher.';
