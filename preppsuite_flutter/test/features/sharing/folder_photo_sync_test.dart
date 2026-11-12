import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/core/photo_hashes.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_controller.dart';
import 'package:preppsuite_flutter/features/inventory/application/photo_content_index.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_photos.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

import 'in_memory_photo_folder.dart';

/// One device: its database, its own photo folder and what it knows of
/// the pictures in there.
class _Device {
  _Device(this.id)
    : db = AppDatabase.forTesting(NativeDatabase.memory()),
      photos = Directory.systemTemp.createTempSync('photos-$id'),
      index = PhotoContentIndex(store: MemoryPhotoHashStore());

  final String id;
  final AppDatabase db;
  final Directory photos;
  final PhotoContentIndex index;

  InventoryController get inventory =>
      InventoryController(db, _household, photos: index);

  /// A picture taken on this device, as the photo service stores one.
  String picture(String name, List<int> bytes) {
    final file = File(p.join(photos.path, '$name.jpg'))
      ..writeAsBytesSync(bytes);
    return file.path;
  }

  Future<InventoryItem> item(String clientId) async =>
      (await db.inventoryItemsForSync(_household))
          .singleWhere((row) => row.clientId == clientId);

  Future<void> close() async {
    await db.close();
    photos.deleteSync(recursive: true);
  }
}

const _household = 'household-1';

/// The household's pictures through an encrypted folder (#376).
void main() {
  late InMemoryPhotoFolder folder;
  late _Device phone;
  late _Device laptop;
  late FolderKey key;
  final parameters = VaultParameters.testing;

  // Two pictures that are nothing alike, and nothing like valid JSON.
  final tin = Uint8List.fromList([0xFF, 0xD8, ...utf8.encode('tin'), 0xD9]);
  final jar = Uint8List.fromList([0xFF, 0xD8, ...utf8.encode('jar'), 0xD9]);

  setUpAll(() async {
    key = await deriveFolderKey('gemeinsames-kennwort', parameters);
  });

  Future<HouseholdFile> sealed() async => HouseholdFile(
    householdId: _household,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
    vault: parameters,
    check: await buildCheckValue(key),
  );

  HouseholdFile plain() => HouseholdFile(
    householdId: _household,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  setUp(() async {
    folder = InMemoryPhotoFolder()..householdFile = (await sealed()).encode();
    phone = _Device('phone');
    laptop = _Device('laptop');
  });

  tearDown(() async {
    await phone.close();
    await laptop.close();
  });

  Future<SharedFolderSyncResult> sync(
    _Device device, {
    bool locked = false,
  }) async => SharedFolderSyncService(
    database: device.db,
    folder: folder,
    deviceId: device.id,
    identity: folder.householdFile == plain().encode()
        ? plain()
        : await sealed(),
    key: folder.householdFile == plain().encode() || locked ? null : key,
    photoIndex: device.index,
    photosDirectory: device.photos,
  ).sync();

  Future<void> addTin(_Device device, {List<String> photoPaths = const []}) =>
      device.inventory.addItem(
        name: 'Ravioli',
        category: InventoryItemCategory.food,
        quantity: 4,
        unit: 'Dose',
        storageLocation: 'Keller',
        photoPaths: photoPaths,
      );

  Future<InventoryItem> only(_Device device) async =>
      (await device.db.inventoryItemsForSync(_household)).single;

  test('a picture taken on one device appears on the other', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);

    final sent = await sync(phone);
    expect(sent.photos.sent, 1);
    final fileName = folder.photoFiles.keys.single;
    expect(parseFolderPhotoFileName(fileName)?.deviceId, 'phone');
    final sealedPicture = folder.photoFiles[fileName]!;
    expect(looksEncrypted(sealedPicture), isTrue);
    expect(sealedPicture, isNot(contains(base64Encode(tin))));
    // The name is not the picture's hash: the folder does not say which
    // picture it is.
    expect(fileName, isNot(contains(photoContentHashSync(tin))));

    final received = await sync(laptop);
    expect(received.photos.fetched, 1);
    final row = await only(laptop);
    expect(row.photoPath, isNotNull);
    expect(p.isWithin(laptop.photos.path, row.photoPath!), isTrue);
    expect(File(row.photoPath!).readAsBytesSync(), tin);
    expect(row.dirty, isFalse, reason: 'a picture arriving is not an edit');
  });

  test('a picture is sent once, and a second run is quiet', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    await sync(phone);
    await sync(laptop);
    await sync(phone);
    await sync(laptop);
    expect(folder.photoWrites, 1, reason: 'the laptop already holds it');
    final quiet = await sync(laptop);
    expect(quiet.photos.fetched, 0);
    expect(quiet.photos.sent, 0);
  });

  test(
    'a replaced picture replaces it everywhere and leaves the folder',
    () async {
      await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
      await sync(phone);
      await sync(laptop);
      final before = (await only(laptop)).photoPath!;

      final existing = await only(phone);
      await phone.inventory.updateItem(
        existing,
        name: existing.name,
        category: InventoryItemCategory.food,
        quantity: existing.quantity,
        unit: existing.unit,
        storageLocation: existing.storageLocation,
        photoPaths: [phone.picture('jar', jar)],
      );
      await sync(phone);
      expect(folder.photoFiles, hasLength(1), reason: 'the old one went');

      await sync(laptop);
      final row = await only(laptop);
      expect(File(row.photoPath!).readAsBytesSync(), jar);
      expect(File(before).existsSync(), isFalse, reason: 'not kept hidden');
    },
  );

  test('a picture taken out is taken out everywhere', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    await sync(phone);
    await sync(laptop);
    final before = (await only(laptop)).photoPath!;

    final existing = await only(phone);
    await phone.inventory.updateItem(
      existing,
      name: existing.name,
      category: InventoryItemCategory.food,
      quantity: existing.quantity,
      unit: existing.unit,
      storageLocation: existing.storageLocation,
    );
    await sync(phone);
    expect(folder.photoFiles, isEmpty);

    final result = await sync(laptop);
    expect(result.photos.emptied, 1);
    expect((await only(laptop)).photoPath, isNull);
    expect(File(before).existsSync(), isFalse);
  });

  test('a device that only books an item down keeps its pictures', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    await sync(phone);
    await sync(laptop);

    // The laptop knows the list and books two tins out.
    await laptop.inventory.consumeQuantity(await only(laptop), 2);
    await sync(laptop);
    await sync(phone);

    final row = await only(phone);
    expect(row.quantity, 2);
    expect(File(row.photoPath!).readAsBytesSync(), tin);
    expect(
      decodePhotoHashes(row.photoHashes, places: 3),
      [photoContentHashSync(tin), null, null],
    );
  });

  test(
    'a plain folder carries no pictures, only which ones they are',
    () async {
      folder.householdFile = plain().encode();
      await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
      await sync(phone);
      await sync(laptop);

      expect(folder.photoFiles, isEmpty);
      final row = await only(laptop);
      expect(row.photoPath, isNull);
      expect(row.photoHashes, (await only(phone)).photoHashes);
    },
  );

  test('a device without the key sends and fetches nothing', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    final result = await sync(phone, locked: true);
    expect(result.error, SharedFolderSyncError.locked);
    expect(folder.photoFiles, isEmpty);
  });

  test('a picture renamed in the folder is not taken for another', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    await sync(phone);
    // Somebody with write access to the folder puts a different sealed
    // picture under the tin's name.
    final fileName = folder.photoFiles.keys.single;
    folder.photoFiles[fileName] = await encryptBytesForFolder(jar, key);

    final result = await sync(laptop);
    expect(result.photos.fetched, 0);
    expect((await only(laptop)).photoPath, isNull);
  });

  test('pictures from before #376 are read once and announced', () async {
    // A row as an older version left it: a picture, and no list.
    final path = phone.picture('tin', tin);
    await phone.db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'tin',
        householdId: _household,
        name: 'Ravioli',
        category: 'food',
        quantity: 4,
        unit: 'Dose',
        storageLocation: 'Keller',
        photoPath: Value(path),
        updatedAt: DateTime.utc(2026, 11, 1),
        dirty: const Value(false),
      ),
    );
    final before = await phone.item('tin');
    expect(before.photoHashes, isNull);

    await sync(phone);
    final after = await phone.item('tin');
    expect(
      decodePhotoHashes(after.photoHashes, places: 3),
      [photoContentHashSync(tin), null, null],
    );
    expect(after.updatedAt, before.updatedAt, reason: 'not an edit');
    expect(after.dirty, isFalse);

    await sync(laptop);
    expect(File((await laptop.item('tin')).photoPath!).readAsBytesSync(), tin);
  });

  test('two devices with different old pictures settle on one', () async {
    // A handover before #376 left each device the picture it had.
    Future<void> legacy(_Device device, List<int> bytes) =>
        device.db.upsertInventoryItem(
          InventoryItemsCompanion.insert(
            clientId: 'tin',
            householdId: _household,
            name: 'Ravioli',
            category: 'food',
            quantity: 4,
            unit: 'Dose',
            storageLocation: 'Keller',
            photoPath: Value(device.picture('own', bytes)),
            updatedAt: DateTime.utc(2026, 11, 1),
            dirty: const Value(false),
          ),
        );
    await legacy(phone, tin);
    await legacy(laptop, jar);

    for (var round = 0; round < 3; round++) {
      await sync(phone);
      await sync(laptop);
    }
    final onPhone = await phone.item('tin');
    final onLaptop = await laptop.item('tin');
    expect(onPhone.photoHashes, onLaptop.photoHashes);
    expect(
      File(onPhone.photoPath!).readAsBytesSync(),
      File(onLaptop.photoPath!).readAsBytesSync(),
    );
  });

  test('a run sends no more than its budget, the next one the rest', () async {
    final big = Uint8List(600 * 1024)..fillRange(0, 600 * 1024, 7);
    final other = Uint8List(600 * 1024)..fillRange(0, 600 * 1024, 9);
    await addTin(phone, photoPaths: [phone.picture('big', big)]);
    await addTin(phone, photoPaths: [phone.picture('other', other)]);

    Future<FolderPhotoResult> run() => FolderPhotoSync(
      database: phone.db,
      folder: folder,
      key: key,
      deviceId: phone.id,
      householdId: _household,
      index: phone.index,
      photosDirectory: phone.photos,
      budgetBytes: 1024 * 1024,
    ).exchange();

    expect((await run()).sent, 1);
    expect((await run()).sent, 1);
    expect((await run()).sent, 0);
    expect(folder.photoFiles, hasLength(2));
  });

  test('a run that could not read every file takes nothing out', () async {
    await addTin(phone, photoPaths: [phone.picture('tin', tin)]);
    await sync(phone);
    await sync(laptop);
    // The laptop's file is half downloaded when the phone takes its
    // picture off the item.
    folder.deviceFiles['laptop'] = await encryptForFolder(
      '{}',
      FolderKey(Uint8List(32)),
    );
    final existing = await only(phone);
    await phone.inventory.updateItem(
      existing,
      name: existing.name,
      category: InventoryItemCategory.food,
      quantity: existing.quantity,
      unit: existing.unit,
      storageLocation: existing.storageLocation,
    );
    await sync(phone);
    expect(folder.photoFiles, hasLength(1), reason: 'not until all is read');

    folder.deviceFiles.remove('laptop');
    await sync(phone);
    expect(folder.photoFiles, isEmpty);
  });
}
