import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/preparedness/application/preparedness_hub_store.dart';
import 'package:preppsuite_flutter/features/settings/application/backup_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_filter.dart';
import 'package:preppsuite_flutter/features/warnings/application/warning_region_store.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
import 'package:preppsuite_flutter/model/household_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // A backup carries the crisis plan alongside the household, and that
  // plan lives in the platform's own store.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a household backup restores its inventory into an empty database',
    () async {
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);

      await source.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'water',
          householdId: 'home',
          name: 'Trinkwasser',
          category: 'water',
          quantity: 12,
          unit: 'l',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 8),
          dirty: const Value(true),
        ),
      );

      final raw = await BackupService(source).exportHousehold(
        'home',
        'secret-123',
      );
      expect(
        await BackupService(target).restore(raw, 'home', 'secret-123'),
        1,
      );

      final restored = (await target.watchInventoryItems('home').first).single;
      expect(restored.name, 'Trinkwasser');
      expect(restored.quantity, 12);
    },
  );

  test('a backup carries every table, not only the oldest ones', () async {
    // The point of routing this through `snapshot_exchange.dart`: a table
    // added later must not be silently absent from every backup, which
    // nobody would notice until the day somebody restores one.
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await source.upsertPossession(
      PossessionsCompanion.insert(
        clientId: 'washer',
        householdId: 'home',
        name: 'Waschmaschine',
        room: const Value('Keller'),
        serialNumber: const Value('WM-4711'),
        purchasePriceCents: const Value(59900),
        currency: const Value('EUR'),
        updatedAt: DateTime.utc(2026, 9, 14),
      ),
    );
    await source.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'lena',
        householdId: 'home',
        name: 'Lena',
        allergies: const Value('Penicillin'),
        updatedAt: DateTime.utc(2026, 9, 14),
      ),
    );

    final raw = await BackupService(source).exportHousehold(
      'home',
      'secret-123',
    );
    expect(await BackupService(target).restore(raw, 'home', 'secret-123'), 2);

    final owned = (await target.watchPossessions('home').first).single;
    expect(owned.name, 'Waschmaschine');
    expect(owned.serialNumber, 'WM-4711');
    expect(owned.purchasePriceCents, 59900);
    expect(
      (await target.watchHouseholdMembers('home').first).single.name,
      'Lena',
    );
  });

  test('a backup from another household is rejected', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final raw = await BackupService(db).exportHousehold('one', 'secret-123');
    expect(
      await BackupService(db).restore(raw, 'two', 'secret-123'),
      isNull,
    );
  });

  test('a backup cannot be opened with a wrong password', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final raw = await BackupService(db).exportHousehold('home', 'secret-123');
    expect(
      await BackupService(db).restore(raw, 'home', 'wrong-pass'),
      isNull,
    );
  });

  test('a backup carries the crisis plan, not only the household', () async {
    // The plan does not live in the database and is deliberately not
    // synced, which for months meant it was in no backup either: a lost
    // phone took every evacuation card with it.
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    const hub = PreparednessHubStore();
    await hub.save(
      PreparednessHubData(
        evacuationCards: [
          EvacuationCard(
            id: 'route',
            label: 'Zuhause',
            start: 'Wohnung',
            destination: 'Treffpunkt Sporthalle',
            route: 'Nebenstrassen',
            locations: 'Apotheke',
            checkedAt: DateTime(2026, 9, 14),
          ),
        ],
        utilities: PlanNote(
          text: 'Hauptabsperrhahn im Keller',
          checkedAt: DateTime(2026, 9, 14),
        ),
      ),
    );

    final raw = await BackupService(source).exportHousehold(
      'home',
      'secret-123',
    );

    // A device that knows nothing about this household yet.
    SharedPreferences.setMockInitialValues({});
    expect((await hub.load()).evacuationCards, isEmpty);

    await BackupService(target).restore(raw, 'home', 'secret-123');

    final restored = await hub.load();
    expect(
      restored.evacuationCards.single.destination,
      'Treffpunkt Sporthalle',
    );
    expect(restored.utilities.text, 'Hauptabsperrhahn im Keller');
  });

  test('restoring an older backup does not wind a newer plan back', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const hub = PreparednessHubStore();

    await hub.save(
      PreparednessHubData(
        utilities: PlanNote(text: 'alt', checkedAt: DateTime(2026, 3, 1)),
      ),
    );
    final raw = await BackupService(db).exportHousehold('home', 'secret-123');

    await hub.save(
      PreparednessHubData(
        utilities: PlanNote(text: 'neu', checkedAt: DateTime(2026, 9, 14)),
      ),
    );
    await BackupService(db).restore(raw, 'home', 'secret-123');

    expect((await hub.load()).utilities.text, 'neu');
  });

  test('a backup written before the plan section still restores', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final raw = await BackupService(db).exportHousehold('home', 'secret-123');
    final envelope = jsonDecode(raw) as Map<String, Object?>..remove('device');

    expect(
      await BackupService(
        db,
      ).restore(jsonEncode(envelope), 'home', 'secret-123'),
      0,
    );
  });

  test('carries the profile and the settings, and brings them back', () async {
    // Format 2. Without these a restored household knew its whole stock
    // and not how many people it had to last, nor which district to
    // watch -- and now that both are encrypted on the device, a backup is
    // the only way they survive a lost keychain.
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await const HouseholdProfileStore().save(
      const HouseholdProfile(
        id: 'home',
        name: 'Familie Günther',
        countryCode: 'DE',
        regionKey: '053340000000',
        personCount: 4,
      ),
    );
    await const WarningRegionStore().save(
      const WarningRegionFilter(
        countryCode: 'DE',
        ownRegionKey: '053340000000',
      ),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pegelStation', '48900237');

    final raw = await BackupService(source).exportHousehold('home', 'passwort');

    // A different device: nothing of its own beyond the household id.
    SharedPreferences.setMockInitialValues({});

    final restored = await BackupService(target).restore(
      raw,
      'home',
      'passwort',
    );

    expect(restored, isNotNull);
    final profile = await const HouseholdProfileStore().load();
    expect(profile?.name, 'Familie Günther');
    expect(profile?.personCount, 4);
    expect(
      (await SharedPreferences.getInstance()).getString('pegelStation'),
      '48900237',
    );
  });

  test(
    'a restored profile reaches the background poll and the caller',
    () async {
      // Restoring used to write the profile store and nothing else: the
      // background poll kept asking for the old regions, and the provider —
      // still holding the old profile — wrote it back on the next change.
      final source = AppDatabase.forTesting(NativeDatabase.memory());
      final target = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(source.close);
      addTearDown(target.close);

      await const HouseholdProfileStore().save(
        const HouseholdProfile(
          id: 'home',
          name: 'Familie',
          countryCode: 'DE',
          regionKey: '031010000000',
          children: 2,
        ),
      );
      final raw = await BackupService(
        source,
      ).exportHousehold('home', 'passwort');
      SharedPreferences.setMockInitialValues({});

      await BackupService(target).restore(raw, 'home', 'passwort');
      expect(
        (await const WarningRegionStore().load())?.ownRegionKey,
        '031010000000',
      );

      HouseholdProfile? handed;
      await BackupService(target).restore(
        raw,
        'home',
        'passwort',
        saveProfile: (profile) async => handed = profile,
      );
      expect(handed?.id, 'home');
      expect(handed?.children, 2);
    },
  );

  test('a backup in the older format still restores', () async {
    // Format 1 files are out there and have to keep working.
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    final raw = await BackupService(source).exportHousehold('home', 'passwort');
    final envelope = jsonDecode(raw) as Map<String, Object?>;
    envelope['preppsuiteBackup'] = 1;
    envelope.remove('household');

    expect(
      await BackupService(
        target,
      ).restore(jsonEncode(envelope), 'home', 'passwort'),
      isNotNull,
    );
  });

  test('a device with nothing takes the household id from the file', () async {
    // The way back after a lost key: "set up again" gives the household a
    // new id, and its own backup would then be turned away as somebody
    // else's.
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    await source.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: 'water',
        householdId: 'home',
        name: 'Trinkwasser',
        category: 'water',
        quantity: 12,
        unit: 'l',
        storageLocation: 'Keller',
        updatedAt: DateTime.utc(2026, 9, 8),
        dirty: const Value(true),
      ),
    );
    await const HouseholdProfileStore().save(
      const HouseholdProfile(
        id: 'home',
        name: 'Familie Günther',
        countryCode: 'DE',
      ),
    );

    final raw = await BackupService(source).exportHousehold('home', 'passwort');
    SharedPreferences.setMockInitialValues({});

    final restored = await BackupService(
      target,
    ).restoreAsNewHousehold(raw, 'passwort');

    expect(restored, isNotNull);
    expect(restored!.householdId, 'home');
    expect(restored.rows, greaterThan(0));
    expect(restored.profile?.name, 'Familie Günther');
  });

  test('and still refuses the wrong password', () async {
    final source = AppDatabase.forTesting(NativeDatabase.memory());
    final target = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(source.close);
    addTearDown(target.close);

    final raw = await BackupService(source).exportHousehold('home', 'passwort');

    expect(
      await BackupService(target).restoreAsNewHousehold(raw, 'falsch'),
      isNull,
    );
  });
}
