import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'in_memory_sync_folder.dart';

const householdId = 'household-1';

/// Counts how often another device's rows are merged in.
class _CountingDatabase extends AppDatabase {
  _CountingDatabase() : super.forTesting(NativeDatabase.memory());

  var merges = 0;

  @override
  Future<int> mergeIncomingRows({
    List<IncomingRow<InventoryItemsCompanion>> inventory = const [],
    List<IncomingRow<ChecklistTemplatesCompanion>> templates = const [],
    List<IncomingRow<ChecklistItemsCompanion>> items = const [],
    List<IncomingRow<BudgetEntriesCompanion>> budget = const [],
    List<IncomingRow<HouseholdPlansCompanion>> plans = const [],
    List<IncomingRow<HouseholdMembersCompanion>> members = const [],
    List<IncomingRow<PossessionsCompanion>> owned = const [],
    List<IncomingRow<NeighbourOffersCompanion>> offers = const [],
  }) {
    merges++;
    return super.mergeIncomingRows(
      inventory: inventory,
      templates: templates,
      items: items,
      budget: budget,
      plans: plans,
      members: members,
      owned: owned,
      offers: offers,
    );
  }
}

void main() {
  late InMemorySyncFolder folder;
  late AppDatabase laptop;
  late _CountingDatabase phone;

  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    folder = InMemorySyncFolder()..householdFile = identity.encode();
    laptop = AppDatabase.forTesting(NativeDatabase.memory());
    phone = _CountingDatabase();
  });

  tearDown(() async {
    await laptop.close();
    await phone.close();
  });

  SharedFolderSyncService serviceFor(AppDatabase db, String deviceId) =>
      SharedFolderSyncService(
        database: db,
        folder: folder,
        deviceId: deviceId,
        identity: identity,
      );

  InventoryItemsCompanion water({double quantity = 6, DateTime? updatedAt}) =>
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: householdId,
        name: 'Trinkwasser',
        category: 'water',
        quantity: quantity,
        unit: 'l',
        storageLocation: 'Keller',
        updatedAt: updatedAt ?? DateTime.utc(2026, 1, 1),
        dirty: const Value(true),
      );

  group('a setting changed on its own (#253)', () {
    test('is published, and only once', () async {
      await phone.upsertInventoryItem(water());
      await serviceFor(phone, 'phone').sync();
      final quiet = await serviceFor(phone, 'phone').sync();
      expect(quiet.published, isFalse, reason: 'nothing changed yet');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'fireDangerStation',
        '{"id":"10147","name":"Hamburg-Fuhlsbüttel"}',
      );
      final changed = await serviceFor(phone, 'phone').sync();

      expect(changed.published, isTrue);
      final file = DeviceSnapshot.decode(
        (await folder.readDeviceFile('phone'))!,
      )!;
      expect(file.settings['fireDangerStation']?.value, contains('10147'));

      final again = await serviceFor(phone, 'phone').sync();
      expect(again.published, isFalse, reason: 'said once is said');
    });

    test('a setting removed here is published as removed', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fireDangerStation', '{"id":"1","name":"A"}');
      await phone.upsertInventoryItem(water());
      await serviceFor(phone, 'phone').sync();

      await prefs.remove('fireDangerStation');
      final result = await serviceFor(phone, 'phone').sync();

      expect(result.published, isTrue);
      final file = DeviceSnapshot.decode(
        (await folder.readDeviceFile('phone'))!,
      )!;
      final entry = file.settings['fireDangerStation'];
      expect(entry, isNotNull);
      expect(entry!.value, isNull, reason: 'a versioned deletion travels');
    });
  });

  group('an unchanged file of another device (#254)', () {
    test('is merged once, not every round', () async {
      await laptop.upsertInventoryItem(water());
      await serviceFor(laptop, 'laptop').sync();

      await serviceFor(phone, 'phone').sync();
      expect(phone.merges, 1);
      await serviceFor(phone, 'phone').sync();
      await serviceFor(phone, 'phone').sync();
      expect(phone.merges, 1, reason: 'the laptop said nothing new');

      // The laptop says something new.
      await laptop.upsertInventoryItem(
        water(quantity: 9, updatedAt: DateTime.utc(2026, 1, 2)),
      );
      await serviceFor(laptop, 'laptop').sync();
      await serviceFor(phone, 'phone').sync();
      expect(phone.merges, 2);
      final rows = await phone.inventoryItemsForSync(householdId);
      expect(rows.single.quantity, 9);
    });

    test('is read again when this device has lost its rows', () async {
      await laptop.upsertInventoryItem(water());
      await serviceFor(laptop, 'laptop').sync();
      await serviceFor(phone, 'phone').sync();
      expect(await phone.inventoryItemsForSync(householdId), hasLength(1));

      await phone.deleteHouseholdData(householdId);
      await serviceFor(phone, 'phone').sync();

      // The first sync, then the laptop's file and its own: having deleted
      // the household it no longer knows that it wrote that one (#336).
      expect(phone.merges, 3);
      expect(await phone.inventoryItemsForSync(householdId), hasLength(1));
    });
  });
}
