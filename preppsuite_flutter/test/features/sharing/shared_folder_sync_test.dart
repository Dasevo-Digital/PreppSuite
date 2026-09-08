import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

const householdId = 'household-1';

void main() {
  late InMemorySyncFolder folder;
  late AppDatabase phone;
  late AppDatabase laptop;

  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    folder = InMemorySyncFolder()..householdFile = identity.encode();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    laptop = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await phone.close();
    await laptop.close();
  });

  SharedFolderSyncService serviceFor(AppDatabase db, String deviceId) {
    return SharedFolderSyncService(
      database: db,
      folder: folder,
      deviceId: deviceId,
      identity: identity,
    );
  }

  InventoryItemsCompanion water({
    String clientId = 'water',
    double quantity = 6,
    String name = 'Trinkwasser',
    DateTime? updatedAt,
    DateTime? deletedAt,
    String? photoPath,
  }) {
    return InventoryItemsCompanion.insert(
      clientId: clientId,
      householdId: householdId,
      name: name,
      category: 'water',
      quantity: quantity,
      unit: 'Flasche',
      storageLocation: 'Keller',
      photoPath: Value(photoPath),
      updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
      deletedAt: Value(deletedAt),
      dirty: const Value(true),
    );
  }

  Future<InventoryItem?> storedWater(AppDatabase db) async {
    final rows = await db.inventoryItemsForSync(householdId);
    return rows.where((row) => row.clientId == 'water').firstOrNull;
  }

  test('an entry made on one device reaches the other', () async {
    await phone.upsertInventoryItem(water());

    final pushed = await serviceFor(phone, 'phone').sync();
    final pulled = await serviceFor(laptop, 'laptop').sync();

    expect(pushed.published, isTrue);
    expect(pulled.received, 1);
    expect((await storedWater(laptop))?.name, 'Trinkwasser');
  });

  test('the newer edit wins, whichever device syncs last', () async {
    await phone.upsertInventoryItem(water(quantity: 6));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    // Both edit the same row; the laptop's edit is the later one.
    await phone.upsertInventoryItem(
      water(quantity: 12, updatedAt: DateTime.utc(2026, 2)),
    );
    await laptop.upsertInventoryItem(
      water(quantity: 24, updatedAt: DateTime.utc(2026, 3)),
    );

    await serviceFor(laptop, 'laptop').sync();
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    expect((await storedWater(phone))?.quantity, 24);
    expect((await storedWater(laptop))?.quantity, 24);
  });

  test('equal-time edits converge independently of sync order', () async {
    final time = DateTime.utc(2026, 2);
    await phone.upsertInventoryItem(water(quantity: 12, updatedAt: time));
    await laptop.upsertInventoryItem(water(quantity: 24, updatedAt: time));
    for (var i = 0; i < 3; i++) {
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();
    }
    expect(
      (await storedWater(phone))?.quantity,
      (await storedWater(laptop))?.quantity,
    );
    final writes = folder.deviceWrites;
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    expect(folder.deviceWrites, writes);
  });

  test('a second edit in the same second reaches another device', () async {
    final time = DateTime.utc(2026, 2);
    await phone.upsertInventoryItem(water(quantity: 24, updatedAt: time));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    await phone.upsertInventoryItem(
      water(
        quantity: 12,
        updatedAt: time.add(const Duration(milliseconds: 100)),
      ),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    expect((await storedWater(laptop))?.quantity, 12);
  });

  test(
    'an edit after the clock moves backwards reaches another device',
    () async {
      await phone.upsertInventoryItem(
        water(quantity: 24, updatedAt: DateTime.utc(2026, 3)),
      );
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();
      await phone.upsertInventoryItem(
        water(quantity: 12, updatedAt: DateTime.utc(2026, 2)),
      );
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();
      expect((await storedWater(laptop))?.quantity, 12);
    },
  );

  test(
    'a tombstone wins an equal-time edit without losing the local photo',
    () async {
      final time = DateTime.utc(2026, 2);
      await phone.upsertInventoryItem(
        water(updatedAt: time, deletedAt: time, photoPath: 'phone.jpg'),
      );
      await laptop.upsertInventoryItem(
        water(updatedAt: time, name: 'Z edited', photoPath: 'laptop.jpg'),
      );
      for (var i = 0; i < 3; i++) {
        await serviceFor(laptop, 'laptop').sync();
        await serviceFor(phone, 'phone').sync();
      }
      expect((await storedWater(phone))?.deletedAt?.toUtc(), time);
      expect((await storedWater(laptop))?.deletedAt?.toUtc(), time);
      expect((await storedWater(phone))?.photoPath, 'phone.jpg');
      expect((await storedWater(laptop))?.photoPath, 'laptop.jpg');
    },
  );

  test(
    'acknowledgement preserves an edit made during the file write',
    () async {
      final editingFolder = _EditingFolder()..householdFile = identity.encode();
      folder = editingFolder;
      final time = DateTime.now().toUtc().add(const Duration(days: 2));
      await phone.upsertInventoryItem(water(quantity: 24, updatedAt: time));
      editingFolder.onWrite = () async {
        await phone.upsertInventoryItem(water(quantity: 12, updatedAt: time));
      };
      await serviceFor(phone, 'phone').sync();
      expect(await phone.dirtyInventoryItems(householdId), hasLength(1));
      await serviceFor(laptop, 'laptop').sync();
      expect((await storedWater(laptop))?.quantity, 24);
      await serviceFor(phone, 'phone').sync();
      expect(await phone.dirtyInventoryItems(householdId), isEmpty);
      await serviceFor(laptop, 'laptop').sync();
      expect((await storedWater(laptop))?.quantity, 12);
      final writes = folder.deviceWrites;
      await serviceFor(phone, 'phone').sync();
      expect(folder.deviceWrites, writes);
    },
  );

  test(
    'the first upgraded sync republishes a legacy clean edit once',
    () async {
      final time = DateTime.utc(2026, 2);
      await phone.upsertInventoryItem(water(quantity: 12, updatedAt: time));
      folder.deviceFiles['phone'] = DeviceSnapshot(
        deviceId: 'phone',
        householdId: householdId,
        writtenAt: time,
        inventoryItems: [encodeInventoryItem((await storedWater(phone))!)],
      ).encode();
      // Simulate the old write/ack race: SQLite holds the edit, but the
      // existing snapshot does not and dirty was incorrectly cleared.
      await phone
          .into(phone.inventoryItems)
          .insertOnConflictUpdate(
            water(
              quantity: 24,
              updatedAt: time,
            ).copyWith(dirty: const Value(false)),
          );
      expect((await serviceFor(phone, 'phone').sync()).published, isTrue);
      await serviceFor(laptop, 'laptop').sync();
      expect((await storedWater(laptop))?.quantity, 24);
      expect((await serviceFor(phone, 'phone').sync()).published, isFalse);
    },
  );

  test(
    'a deletion travels rather than being undone by the other device',
    () async {
      await phone.upsertInventoryItem(water());
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();

      await phone.upsertInventoryItem(
        water(
          updatedAt: DateTime.utc(2026, 2),
          deletedAt: DateTime.utc(2026, 2),
        ),
      );
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();

      expect((await storedWater(laptop))?.deletedAt, isNotNull);
      expect(await laptop.watchInventoryItems(householdId).first, isEmpty);
    },
  );

  test(
    'a device republishes what it learned, so the household survives '
    'losing the device that created a row',
    () async {
      await phone.upsertInventoryItem(water());
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();

      // The phone is lost, factory reset, or simply never opened again.
      folder.deviceFiles.remove('phone');

      final tablet = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(tablet.close);
      final result = await serviceFor(tablet, 'tablet').sync();

      expect(result.received, 1);
      expect((await storedWater(tablet))?.name, 'Trinkwasser');
    },
  );

  test('a run with nothing new writes nothing', () async {
    await phone.upsertInventoryItem(water());
    await serviceFor(phone, 'phone').sync();
    final writesAfterFirst = folder.deviceWrites;

    final second = await serviceFor(phone, 'phone').sync();

    expect(second.published, isFalse);
    expect(second.succeeded, isTrue);
    expect(folder.deviceWrites, writesAfterFirst);
  });

  test(
    'rows belonging to another household in the same folder are left alone',
    () async {
      folder.deviceFiles['stranger'] = DeviceSnapshot(
        deviceId: 'stranger',
        householdId: 'someone-else',
        writtenAt: DateTime.utc(2026),
        inventoryItems: [
          {
            'clientId': 'their-water',
            'householdId': 'someone-else',
            'name': 'Fremdes Wasser',
            'category': 'water',
            'quantity': 3,
            'unit': 'Flasche',
            'storageLocation': 'Keller',
            'updatedAt': DateTime.utc(2026).toIso8601String(),
          },
        ],
      ).encode();

      final result = await serviceFor(phone, 'phone').sync();

      expect(result.received, 0);
      expect(await phone.inventoryItemsForSync('someone-else'), isEmpty);
    },
  );

  test(
    'a folder that names a different household is refused outright',
    () async {
      folder.householdFile = HouseholdFile(
        householdId: 'someone-else',
        name: 'Nachbarn',
        countryCode: 'DE',
        createdAt: DateTime.utc(2026),
      ).encode();
      await phone.upsertInventoryItem(water());

      final result = await serviceFor(phone, 'phone').sync();

      expect(result.error, SharedFolderSyncError.differentHousehold);
      expect(folder.deviceWrites, 0, reason: 'nothing of ours was offered');
    },
  );

  test('a missing identity file is written back', () async {
    folder.householdFile = null;

    final result = await serviceFor(phone, 'phone').sync();

    expect(result.succeeded, isTrue);
    expect(
      HouseholdFile.decode(folder.householdFile!)?.householdId,
      householdId,
    );
  });

  test('an unreadable folder is reported, not merged into', () async {
    folder.writable = false;

    final result = await serviceFor(phone, 'phone').sync();

    expect(result.error, SharedFolderSyncError.unwritable);
  });

  test(
    'a remote row winning does not wipe the local photo, which never '
    'travels in the first place',
    () async {
      await phone.upsertInventoryItem(water(photoPath: 'photos/water.jpg'));
      await serviceFor(phone, 'phone').sync();
      await serviceFor(laptop, 'laptop').sync();

      await laptop.upsertInventoryItem(
        water(quantity: 24, updatedAt: DateTime.utc(2026, 5)),
      );
      await serviceFor(laptop, 'laptop').sync();
      await serviceFor(phone, 'phone').sync();

      final row = await storedWater(phone);
      expect(row?.quantity, 24, reason: 'the newer row was applied');
      expect(row?.photoPath, 'photos/water.jpg');
    },
  );

  test('a damaged snapshot costs that file, not the run', () async {
    await phone.upsertInventoryItem(water());
    await serviceFor(phone, 'phone').sync();
    folder.deviceFiles['broken'] = '{ this is not json';

    final result = await serviceFor(laptop, 'laptop').sync();

    expect(result.received, 1, reason: "the phone's rows still arrived");
    expect(result.succeeded, isTrue);
  });

  test('a folder written entirely by a newer version is reported', () async {
    folder.deviceFiles['newer'] = '{"version": 99, "deviceId": "newer"}';

    final result = await serviceFor(phone, 'phone').sync();

    expect(result.error, SharedFolderSyncError.unsupportedVersion);
  });
}

class _EditingFolder extends InMemorySyncFolder {
  Future<void> Function()? onWrite;

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) async {
    final callback = onWrite;
    onWrite = null;
    await callback?.call();
    await super.writeDeviceFile(deviceId, contents);
  }
}
