import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:drift/native.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The only part of sharing that touches a real disk, and the part whose
/// failures happen on the user's machine rather than in a merge.
void main() {
  late Directory root;
  late IoSyncFolder folder;

  setUp(() {
    root = Directory.systemTemp.createTempSync('preppsuite-folder-test');
    folder = IoSyncFolder(root.path);
  });

  tearDown(() => root.deleteSync(recursive: true));

  test(
    'claims its own subdirectory rather than the folder it was given',
    () async {
      await folder.writeDeviceFile('phone', '{}');

      expect(
        File(
          p.join(root.path, preppSuiteFolderName, 'devices', 'phone.json'),
        ).existsSync(),
        isTrue,
      );
      expect(
        root.listSync().map((e) => p.basename(e.path)),
        [preppSuiteFolderName],
      );
    },
  );

  test('a write probe leaves nothing behind', () async {
    expect(await folder.isWritable(), isTrue);

    final leftovers = Directory(
      p.join(root.path, preppSuiteFolderName),
    ).listSync().map((e) => p.basename(e.path));
    expect(leftovers, ['devices']);
  });

  test('a folder that cannot be created is not writable', () async {
    // A path under a regular file can never become a directory.
    final blocker = File(p.join(root.path, 'blocker'))..writeAsStringSync('x');

    expect(await IoSyncFolder(blocker.path).isWritable(), isFalse);
  });

  test('lists device ids and ignores anything else in the folder', () async {
    await folder.writeDeviceFile('phone', '{}');
    await folder.writeDeviceFile('laptop', '{}');
    File(
      p.join(root.path, preppSuiteFolderName, 'devices', 'notes.txt'),
    ).writeAsStringSync('hello');

    expect(
      (await folder.listDeviceIds())..sort(),
      ['laptop', 'phone'],
    );
  });

  test('a rewrite replaces the file and leaves no temporary behind', () async {
    // The temporary is what makes the write atomic; a leftover would be
    // uploaded by the sync engine as a second, half-valid snapshot.
    await folder.writeDeviceFile('phone', '{"first": true}');
    await folder.writeDeviceFile('phone', '{"second": true}');

    expect(await folder.readDeviceFile('phone'), '{"second": true}');
    expect(await folder.listDeviceIds(), ['phone']);
    expect(
      Directory(
        p.join(root.path, preppSuiteFolderName, 'devices'),
      ).listSync().map((e) => p.basename(e.path)),
      ['phone.json'],
    );
  });

  test(
    'reading a device or household file that is not there returns null',
    () async {
      expect(await folder.readDeviceFile('phone'), isNull);
      expect(await folder.readHouseholdFile(), isNull);
    },
  );

  test('the household file round-trips', () async {
    await folder.writeHouseholdFile('{"householdId": "abc"}');

    expect(await folder.readHouseholdFile(), '{"householdId": "abc"}');
  });

  test('two devices reach the same state through a real directory', () async {
    // The service tests run against an in-memory folder; this one checks
    // that the same thing still holds once actual files are involved.
    final identity = HouseholdFile(
      householdId: 'household-1',
      name: 'Familie',
      countryCode: 'DE',
      createdAt: DateTime.utc(2026),
    );
    final phone = AppDatabase.forTesting(NativeDatabase.memory());
    final laptop = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(phone.close);
    addTearDown(laptop.close);

    await phone.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: 'household-1',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 6,
        unit: 'Flasche',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026),
      ),
    );

    SharedFolderSyncService serviceFor(AppDatabase db, String deviceId) =>
        SharedFolderSyncService(
          database: db,
          folder: folder,
          deviceId: deviceId,
          identity: identity,
        );

    await serviceFor(phone, 'phone').sync();
    final pulled = await serviceFor(laptop, 'laptop').sync();

    expect(pulled.received, 1);
    expect(pulled.devicesSeen, 2);
    expect(
      (await laptop.inventoryItemsForSync('household-1')).single.name,
      'Trinkwasser',
    );
  });
}
