import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

const householdId = 'household-1';

class _Folder implements SyncFolder {
  final Map<String, String> deviceFiles = {};
  String? householdFile;
  Future<void> Function()? onReadOwn;

  @override
  Future<bool> isWritable() async => true;
  @override
  Future<List<String>> listDeviceIds() async => deviceFiles.keys.toList();
  @override
  Future<String?> readDeviceFile(String deviceId) async {
    final hook = onReadOwn;
    onReadOwn = null;
    await hook?.call();
    return deviceFiles[deviceId];
  }

  @override
  Future<void> writeDeviceFile(String deviceId, String contents) async =>
      deviceFiles[deviceId] = contents;
  @override
  Future<String?> readHouseholdFile() async => householdFile;
  @override
  Future<void> writeHouseholdFile(String contents) async =>
      householdFile = contents;
}

/// "Delete household" can land in the middle of a folder run (#336).
///
/// The run had read the mark that it wrote its own file, so it did not
/// read the file. The deletion took the rows and the mark. The run then
/// found the mark gone, took that for a repair and wrote the empty
/// household over what, for a device alone in the folder, was the only
/// copy.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  InventoryItemsCompanion water() => InventoryItemsCompanion.insert(
    clientId: 'water',
    householdId: householdId,
    name: 'Trinkwasser',
    category: 'water',
    quantity: 6,
    unit: 'Flasche',
    storageLocation: 'Keller',
    updatedAt: DateTime.utc(2026, 1, 1),
    dirty: const Value(true),
  );

  test(
    'a household deleted under a run is not written over its file',
    () async {
      SharedPreferences.setMockInitialValues({});
      final folder = _Folder()..householdFile = identity.encode();
      final phone = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(phone.close);
      SharedFolderSyncService service() => SharedFolderSyncService(
        database: phone,
        folder: folder,
        deviceId: 'phone',
        identity: identity,
      );

      await phone.upsertInventoryItem(water());
      await service().sync();

      folder.onReadOwn = () => phone.deleteHouseholdData(householdId);
      final result = await service().sync();

      expect(result.published, isFalse);
      expect(
        DeviceSnapshot.decode(folder.deviceFiles['phone']!)!.inventoryItems,
        hasLength(1),
        reason: 'the only copy stays where it was',
      );

      // And the next run, the mark being gone, reads the file back first.
      final again = await service().sync();
      expect(again.received, greaterThan(0));
      expect(await phone.inventoryItemsForSync(householdId), hasLength(1));
    },
  );
}
