import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// Coming back to a folder this device once wrote alone (#397).
///
/// The mark that this database wrote its file in a folder lets a run skip
/// that file. It was kept under the household's id, and moving into
/// another household left it behind: a device alone in folder F with
/// household B that merged into A, and later came back to F, found its
/// mark, skipped its own file and wrote what it had then -- a few rows,
/// the built-in checklists -- over the only copy of B.
void main() {
  const folderHousehold = 'household-b';
  const otherHousehold = 'household-a';
  const device = 'phone';

  late InMemorySyncFolder folder;
  late AppDatabase phone;

  final identity = HouseholdFile(
    householdId: folderHousehold,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    folder = InMemorySyncFolder()..householdFile = identity.encode();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => phone.close());

  SharedFolderSyncService service() => SharedFolderSyncService(
    database: phone,
    folder: folder,
    deviceId: device,
    identity: identity,
  );

  InventoryItemsCompanion row(String clientId, String householdId) =>
      InventoryItemsCompanion.insert(
        clientId: clientId,
        householdId: householdId,
        name: clientId,
        category: 'water',
        quantity: 6,
        unit: 'Flasche',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 1, 1),
        dirty: const Value(true),
      );

  List<String> inFile() => [
    for (final item in DeviceSnapshot.decode(
      folder.deviceFiles[device]!,
    )!.inventoryItems)
      item['clientId']! as String,
  ];

  /// Alone in the folder with household B, its file written.
  Future<void> aloneInTheFolder() async {
    await phone.upsertInventoryItem(row('water', folderHousehold));
    await phone.upsertInventoryItem(row('rice', folderHousehold));
    expect((await service().sync()).published, isTrue);
    expect(inFile(), unorderedEquals(['water', 'rice']));
  }

  /// What the first moments back in the folder write: the seeder's lists,
  /// or anything typed before the first run.
  Future<void> somethingNew() =>
      phone.upsertInventoryItem(row('candles', folderHousehold));

  test('merged into another household and back by "replace", the own file '
      'is read and not written over', () async {
    await aloneInTheFolder();

    // "Zusammenführen" with household A: the rows move B -> A.
    await phone.adoptHouseholdId(from: folderHousehold, to: otherHousehold);

    // Back to F with "Ersetzen": A's rows are discarded inside the move,
    // and this device is in B again.
    await phone.deleteHouseholdData(otherHousehold);
    await somethingNew();

    final result = await service().sync();

    expect(result.error, isNull);
    expect(result.received, greaterThan(0), reason: 'the file was read');
    expect(inFile(), unorderedEquals(['water', 'rice', 'candles']));
    expect(
      [
        for (final item in await phone.inventoryItemsForSync(folderHousehold))
          item.clientId,
      ],
      unorderedEquals(['water', 'rice', 'candles']),
    );
  });

  test('merged into another household and back by "merge", nothing of B '
      'is lost either', () async {
    await aloneInTheFolder();
    await phone.adoptHouseholdId(from: folderHousehold, to: otherHousehold);
    await phone.adoptHouseholdId(from: otherHousehold, to: folderHousehold);
    await somethingNew();

    await service().sync();

    expect(inFile(), unorderedEquals(['water', 'rice', 'candles']));
  });

  test('a household deleted here forgets the marks of every household, an '
      'earlier one\'s too', () async {
    await aloneInTheFolder();

    // A mark an older version left behind when it moved B -> A.
    await phone.adoptHouseholdId(from: folderHousehold, to: otherHousehold);
    await phone.setLastPulledAt(
      'sharedFolderVersion2:$folderHousehold:$device',
      DateTime.utc(2026, 1, 2),
    );

    // "Haushalt löschen", then "Ordner beitreten" with F once more.
    await phone.deleteHouseholdData(otherHousehold);
    expect(
      await phone.lastPulledAt('sharedFolderVersion2:$folderHousehold:$device'),
      isNull,
    );
    await somethingNew();

    await service().sync();

    expect(inFile(), unorderedEquals(['water', 'rice', 'candles']));
  });
}
