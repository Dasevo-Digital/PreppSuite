import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// Two devices sharing an encrypted folder.
///
/// The crypto is proven in `folder_crypto_test`; what is proven here is
/// that a household still works through it — and that a device without
/// the key does no damage.
void main() {
  const householdId = 'household-1';

  late InMemorySyncFolder folder;
  late AppDatabase phone;
  late AppDatabase laptop;
  late FolderKey key;

  final parameters = VaultParameters.testing;

  setUpAll(() async {
    key = await deriveFolderKey('gemeinsames-kennwort', parameters);
  });

  Future<HouseholdFile> sealedIdentity() async => HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
    vault: parameters,
    check: await buildCheckValue(key),
  );

  setUp(() async {
    folder = InMemorySyncFolder()
      ..householdFile = (await sealedIdentity()).encode();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    laptop = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await phone.close();
    await laptop.close();
  });

  Future<SharedFolderSyncService> serviceFor(
    AppDatabase db,
    String deviceId, {
    FolderKey? withKey,
  }) async => SharedFolderSyncService(
    database: db,
    folder: folder,
    deviceId: deviceId,
    identity: await sealedIdentity(),
    key: withKey,
  );

  HouseholdFile plainIdentity() => HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  Future<void> addWater(AppDatabase db, {double quantity = 6}) =>
      db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'water',
          householdId: householdId,
          name: 'Trinkwasser',
          category: 'water',
          quantity: quantity,
          unit: 'Flasche',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 2, 1),
          dirty: const Value(true),
        ),
      );

  for (final missing in [true, false]) {
    test(
      'encrypted household blocks ${missing ? 'missing' : 'plain'} metadata',
      () async {
        await addWater(phone);
        folder.householdFile = missing ? null : plainIdentity().encode();
        final result = await (await serviceFor(
          phone,
          'phone',
          withKey: key,
        )).sync();
        expect(result.error, SharedFolderSyncError.encryptionChanged);
        expect(folder.deviceFiles, isEmpty);
        expect(
          (await phone.dirtyInventoryItems(householdId)).single.dirty,
          isTrue,
        );
        expect(
          folder.householdFile,
          missing ? isNull : plainIdentity().encode(),
        );
      },
    );
  }

  test(
    'persisted encryption requirement protects a restarted locked device',
    () async {
      await addWater(phone);
      folder.householdFile = plainIdentity().encode();
      final result = await SharedFolderSyncService(
        database: phone,
        folder: folder,
        deviceId: 'phone',
        identity: plainIdentity(),
        requireEncryption: true,
      ).sync();
      expect(result.error, SharedFolderSyncError.encryptionChanged);
      expect(folder.deviceFiles, isEmpty);
    },
  );

  test(
    'a stale saved key cannot publish even into an empty encrypted folder',
    () async {
      await addWater(phone);
      final wrong = await deriveFolderKey('previous-passphrase', parameters);
      final result = await (await serviceFor(
        phone,
        'phone',
        withKey: wrong,
      )).sync();
      expect(result.error, SharedFolderSyncError.locked);
      expect(folder.deviceFiles, isEmpty);
      expect((await phone.dirtyInventoryItems(householdId)), hasLength(1));
    },
  );

  test('metadata downgrade during sync is caught before publishing', () async {
    await addWater(phone);
    final result = await SharedFolderSyncService(
      database: phone,
      folder: folder,
      deviceId: 'phone',
      identity: await sealedIdentity(),
      key: key,
      onEncryptedFolder: () async {
        folder.householdFile = plainIdentity().encode();
      },
    ).sync();
    expect(result.error, SharedFolderSyncError.encryptionChanged);
    expect(folder.deviceFiles, isEmpty);
  });

  test('a row reaches the other device through a sealed file', () async {
    await addWater(phone);
    await (await serviceFor(phone, 'phone', withKey: key)).sync();
    await (await serviceFor(laptop, 'laptop', withKey: key)).sync();

    final received = await laptop.watchInventoryItems(householdId).first;
    expect(received.single.name, 'Trinkwasser');
  });

  test('what lands in the folder is not readable', () async {
    // The point of the whole exercise. A household keeps its address, its
    // medication and how long it could hold out in these files.
    await addWater(phone);
    await (await serviceFor(phone, 'phone', withKey: key)).sync();

    final written = folder.deviceFiles['phone']!;
    expect(written.contains('Trinkwasser'), isFalse);
    expect(written.contains(householdId), isFalse);
    expect(looksEncrypted(written), isTrue);
  });

  group('a device without the key', () {
    test('is locked rather than merging nothing quietly', () async {
      final result = await (await serviceFor(laptop, 'laptop')).sync();

      expect(result.error, SharedFolderSyncError.locked);
    });

    test('never writes its rows into the folder in the clear', () async {
      // The failure that would matter: one device silently undoing the
      // encryption for every row it owns.
      await addWater(laptop);
      await (await serviceFor(laptop, 'laptop')).sync();

      expect(folder.deviceFiles, isEmpty);
    });
  });

  test('a wrong key skips the file instead of merging rubbish', () async {
    await addWater(phone);
    await (await serviceFor(phone, 'phone', withKey: key)).sync();

    final wrong = await deriveFolderKey('falsches-kennwort', parameters);
    final result = await (await serviceFor(
      laptop,
      'laptop',
      withKey: wrong,
    )).sync();

    expect(result.received, 0);
    expect(await laptop.watchInventoryItems(householdId).first, isEmpty);
  });

  test(
    'a plaintext file from a device not switched over is still read',
    () async {
      // A household does not update every device in the same minute. Until
      // it has, the folder holds both shapes, and dropping the old ones
      // would make rows disappear for everyone.
      // The folder is still plain while the old device publishes into it.
      folder.householdFile = plainIdentity().encode();
      await addWater(laptop);
      await SharedFolderSyncService(
        database: laptop,
        folder: folder,
        deviceId: 'laptop',
        identity: plainIdentity(),
      ).sync();
      expect(looksEncrypted(folder.deviceFiles['laptop']!), isFalse);

      // Now someone switches encryption on from the other device.
      folder.householdFile = (await sealedIdentity()).encode();
      await (await serviceFor(phone, 'phone', withKey: key)).sync();

      final received = await phone.watchInventoryItems(householdId).first;
      expect(received.single.name, 'Trinkwasser');
    },
  );

  test('republish seals a file that was written before the switch', () async {
    folder.householdFile = plainIdentity().encode();
    await addWater(phone);
    await SharedFolderSyncService(
      database: phone,
      folder: folder,
      deviceId: 'phone',
      identity: plainIdentity(),
    ).sync();
    expect(looksEncrypted(folder.deviceFiles['phone']!), isFalse);

    folder.householdFile = (await sealedIdentity()).encode();

    // Nothing is dirty any more, so only the explicit flag gets the
    // plaintext replaced.
    await SharedFolderSyncService(
      database: phone,
      folder: folder,
      deviceId: 'phone',
      identity: await sealedIdentity(),
      key: key,
      republish: true,
    ).sync();

    expect(looksEncrypted(folder.deviceFiles['phone']!), isTrue);
  });
}
