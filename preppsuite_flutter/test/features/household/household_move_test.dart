import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/core/platform_storage.dart';
import 'package:preppsuite_flutter/features/household/application/household_providers.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/sharing_providers.dart';
import 'package:preppsuite_flutter/features/sharing/application/sync_folder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Moving this device into another household.
///
/// Every road in — a shared folder, a QR chain, a local handover — goes
/// through `HouseholdProfileController.moveInto`. The copies it replaced
/// drifted apart: the folder's left the children and the pets behind, and
/// "replace" deleted this device's rows before anything had arrived, so a
/// join or a handover that then failed left the device with nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const mine = HouseholdProfile(
    id: 'mine',
    name: 'Wohnung',
    countryCode: 'DE',
    regionKey: '03101',
    personCount: 2,
    children: 2,
    dogs: 1,
    cats: 3,
  );

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await const HouseholdProfileStore().save(mine);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    await container.read(householdProfileProvider.future);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> addWater() => db.upsertInventoryItem(
    InventoryItemsCompanion.insert(
      clientId: 'water',
      householdId: mine.id,
      name: 'Trinkwasser',
      category: 'water',
      quantity: 6,
      unit: 'Flasche',
      storageLocation: 'Keller',
      updatedAt: DateTime.utc(2026, 2, 1),
      dirty: const Value(true),
    ),
  );

  Future<List<String>> names(String householdId) async => [
    for (final item in await db.watchInventoryItems(householdId).first)
      item.name,
  ];

  HouseholdProfileController profiles() =>
      container.read(householdProfileProvider.notifier);

  group('moveInto', () {
    test('keeps whom this device plans for', () async {
      final moved = await profiles().moveInto(
        mine,
        'theirs',
        name: 'Familie',
        countryCode: 'AT',
      );

      for (final profile in [
        moved,
        (await const HouseholdProfileStore().load())!,
      ]) {
        expect(profile.id, 'theirs');
        expect(profile.name, 'Familie');
        expect(profile.countryCode, 'AT');
        expect(profile.regionKey, '03101');
        expect(profile.personCount, 2);
        expect(profile.children, 2);
        expect(profile.dogs, 1);
        expect(profile.cats, 3);
      }
      expect(container.read(householdProfileProvider).value?.id, 'theirs');
    });

    test('re-stamps this device\'s rows onto the new id', () async {
      await addWater();

      await profiles().moveInto(mine, 'theirs');

      expect(await names('theirs'), ['Trinkwasser']);
      expect(await names(mine.id), isEmpty);
    });

    test('discards them instead when asked to', () async {
      await addWater();

      await profiles().moveInto(mine, 'theirs', discardOwnRows: true);

      expect(await names('theirs'), isEmpty);
      expect(await names(mine.id), isEmpty);
    });

    test('leaves rows already under the new id alone', () async {
      // What a replacing handover relies on: the other device's rows are
      // applied first, under its id, and only then are this device's own
      // discarded.
      await addWater();
      await db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'rice',
          householdId: 'theirs',
          name: 'Reis',
          category: 'food',
          quantity: 2,
          unit: 'kg',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 2, 1),
          dirty: const Value(true),
        ),
      );

      await profiles().moveInto(mine, 'theirs', discardOwnRows: true);

      expect(await names('theirs'), ['Reis']);
    });
  });

  group('joining a folder that holds another household', () {
    late Directory root;

    setUp(() {
      root = Directory.systemTemp.createTempSync('preppsuite-move');
    });

    tearDown(() => root.deleteSync(recursive: true));

    PickedStorage location() =>
        PickedStorage(value: root.path, label: 'Ordner');

    Future<void> seedFolder(String contents) =>
        IoSyncFolder(root.path).writeHouseholdFile(contents);

    final theirs = HouseholdFile(
      householdId: 'theirs',
      name: 'Familie',
      countryCode: 'DE',
      createdAt: DateTime.utc(2026),
    );

    test('brings the children and the pets along', () async {
      await seedFolder(theirs.encode());

      final error = await container
          .read(sharedFolderProvider.notifier)
          .joinFolder(location(), profile: mine);

      expect(error, isNull);
      final profile = container.read(householdProfileProvider).value!;
      expect(profile.id, 'theirs');
      expect(profile.name, 'Familie');
      expect(profile.personCount, 2);
      expect(profile.children, 2);
      expect(profile.dogs, 1);
      expect(profile.cats, 3);
    });

    test('replacing discards this device\'s rows once it is in', () async {
      await addWater();
      await seedFolder(theirs.encode());

      await container
          .read(sharedFolderProvider.notifier)
          .joinFolder(location(), profile: mine, discardOwnRows: true);

      expect(await names('theirs'), isEmpty);
      expect(await names(mine.id), isEmpty);
    });

    test('replacing deletes nothing when the join fails', () async {
      await addWater();
      await seedFolder('{"version": 99}');

      final error = await container
          .read(sharedFolderProvider.notifier)
          .joinFolder(location(), profile: mine, discardOwnRows: true);

      expect(error, SharedFolderJoinError.unreadable);
      expect(await names(mine.id), ['Trinkwasser']);
      expect(container.read(householdProfileProvider).value?.id, mine.id);
    });
  });
}
