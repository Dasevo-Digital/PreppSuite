import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// The household plan across devices.
///
/// It is the one table whose `clientId` is the household id rather than a
/// generated one, which is what makes two devices edit a single record.
/// That decision is what these tests are actually about.
void main() {
  const householdId = 'household-1';

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

  SharedFolderSyncService serviceFor(AppDatabase db, String deviceId) =>
      SharedFolderSyncService(
        database: db,
        folder: folder,
        deviceId: deviceId,
        identity: identity,
      );

  Future<void> writePlan(
    AppDatabase db, {
    String household = householdId,
    String? near,
    String? contact,
    required DateTime updatedAt,
  }) => db.upsertHouseholdPlan(
    HouseholdPlansCompanion.insert(
      clientId: household,
      householdId: household,
      meetingPointNear: Value(near),
      contactName: Value(contact),
      updatedAt: updatedAt,
      dirty: const Value(true),
    ),
  );

  test('a plan written on one device reaches the other', () async {
    await writePlan(
      phone,
      near: 'Die Ecke bei der Bäckerei',
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    final plan = await laptop.watchHouseholdPlan(householdId).first;
    expect(plan?.meetingPointNear, 'Die Ecke bei der Bäckerei');
  });

  test('both devices edit one record, not one each', () async {
    // The whole reason the clientId is the household id. With a generated
    // one there would be two plans here and neither would ever win.
    await writePlan(phone, near: 'Ecke', updatedAt: DateTime.utc(2026, 3, 1));
    await writePlan(
      laptop,
      contact: 'Tante Erika',
      updatedAt: DateTime.utc(2026, 3, 2),
    );

    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    await serviceFor(phone, 'phone').sync();

    final onPhone = await phone.householdPlansForSync(householdId);
    expect(onPhone, hasLength(1));
    // Last writer wins, whole record: the laptop's save is newer.
    expect(onPhone.single.contactName, 'Tante Erika');
  });

  test('an older plan does not overwrite a newer one', () async {
    await writePlan(laptop, near: 'Neu', updatedAt: DateTime.utc(2026, 5, 1));
    await writePlan(phone, near: 'Alt', updatedAt: DateTime.utc(2026, 1, 1));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    expect(
      (await laptop.watchHouseholdPlan(householdId).first)?.meetingPointNear,
      'Neu',
    );
  });

  test('a deletion travels instead of coming back', () async {
    await writePlan(phone, near: 'Ecke', updatedAt: DateTime.utc(2026, 3, 1));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    await phone.upsertHouseholdPlan(
      HouseholdPlansCompanion.insert(
        clientId: householdId,
        householdId: householdId,
        updatedAt: DateTime.utc(2026, 4, 1),
        deletedAt: Value(DateTime.utc(2026, 4, 1)),
        dirty: const Value(true),
      ),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    expect(await laptop.watchHouseholdPlan(householdId).first, isNull);
  });

  group('joining a folder that already has a household', () {
    test('the plan is re-keyed instead of being orphaned', () async {
      // Every other table is re-stamped in place. This one cannot be: its
      // key *is* the household id, so a plan left behind would sync
      // forever under an id nothing reads.
      await writePlan(
        laptop,
        household: 'own-household',
        near: 'Eigener Treffpunkt',
        updatedAt: DateTime.utc(2026, 6, 1),
      );

      await laptop.adoptHouseholdId(from: 'own-household', to: householdId);

      final plan = await laptop.watchHouseholdPlan(householdId).first;
      expect(plan?.meetingPointNear, 'Eigener Treffpunkt');
      expect(await laptop.watchHouseholdPlan('own-household').first, isNull);
      // And it goes out again, or the folder never learns about it.
      expect(await laptop.dirtyHouseholdPlans(householdId), hasLength(1));
    });

    test(
      'the re-keyed plan keeps its date so the folder can still win',
      () async {
        // Stamping "now" on it would make a plan someone wrote alone last
        // year beat the household's real one.
        await writePlan(
          laptop,
          household: 'own-household',
          near: 'Alt und allein',
          updatedAt: DateTime.utc(2026, 1, 1),
        );
        await writePlan(
          phone,
          near: 'Der echte Treffpunkt',
          updatedAt: DateTime.utc(2026, 5, 1),
        );
        await serviceFor(phone, 'phone').sync();

        await laptop.adoptHouseholdId(from: 'own-household', to: householdId);
        await serviceFor(laptop, 'laptop').sync();

        expect(
          (await laptop.watchHouseholdPlan(householdId).first)
              ?.meetingPointNear,
          'Der echte Treffpunkt',
        );
      },
    );

    test('joining with no plan of its own changes nothing', () async {
      await laptop.adoptHouseholdId(from: 'own-household', to: householdId);

      expect(await laptop.watchHouseholdPlan(householdId).first, isNull);
    });
  });
}
