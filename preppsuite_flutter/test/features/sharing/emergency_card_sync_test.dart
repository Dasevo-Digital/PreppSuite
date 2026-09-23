import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// Emergency cards across devices.
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

  Future<void> writeCard(
    AppDatabase db, {
    String clientId = 'm1',
    String name = 'Lena',
    String? allergies,
    String? medication,
    String? careNeeds,
    required DateTime updatedAt,
  }) => db.upsertHouseholdMember(
    HouseholdMembersCompanion.insert(
      clientId: clientId,
      householdId: householdId,
      name: name,
      allergies: Value(allergies),
      medication: Value(medication),
      careNeeds: Value(careNeeds),
      updatedAt: updatedAt,
      dirty: const Value(true),
    ),
  );

  test('a card reaches the other device', () async {
    await writeCard(
      phone,
      allergies: 'Penicillin',
      careNeeds: 'Benötigt im Alltag Unterstützung bei Medikamenten',
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    final card = (await laptop.watchHouseholdMembers(householdId).first).single;
    expect(card.name, 'Lena');
    expect(card.allergies, 'Penicillin');
    expect(card.careNeeds, 'Benötigt im Alltag Unterstützung bei Medikamenten');
  });

  test('two devices each adding a person end up with both', () async {
    // Unlike the plan, these are ordinary rows with generated ids, so two
    // people added at once are two people and not a conflict.
    await writeCard(
      phone,
      clientId: 'm1',
      name: 'Lena',
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    await writeCard(
      laptop,
      clientId: 'm2',
      name: 'Anton',
      updatedAt: DateTime.utc(2026, 3, 2),
    );

    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    await serviceFor(phone, 'phone').sync();

    final onPhone = await phone.watchHouseholdMembers(householdId).first;
    expect(onPhone.map((m) => m.name).toSet(), {'Lena', 'Anton'});
  });

  test('an edit wins over the older copy', () async {
    await writeCard(
      phone,
      medication: 'Keine',
      updatedAt: DateTime.utc(2026, 3, 1),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    await writeCard(
      laptop,
      medication: 'L-Thyroxin 75',
      updatedAt: DateTime.utc(2026, 4, 1),
    );
    await serviceFor(laptop, 'laptop').sync();
    await serviceFor(phone, 'phone').sync();

    final card = (await phone.watchHouseholdMembers(householdId).first).single;
    expect(card.medication, 'L-Thyroxin 75');
  });

  test('a removal travels instead of coming back', () async {
    await writeCard(phone, updatedAt: DateTime.utc(2026, 3, 1));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();
    expect(await laptop.watchHouseholdMembers(householdId).first, hasLength(1));

    await phone.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'm1',
        householdId: householdId,
        name: 'Lena',
        updatedAt: DateTime.utc(2026, 5, 1),
        deletedAt: Value(DateTime.utc(2026, 5, 1)),
        dirty: const Value(true),
      ),
    );
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    expect(await laptop.watchHouseholdMembers(householdId).first, isEmpty);
  });

  test('joining a household brings the cards along', () async {
    // Ordinary re-stamping, unlike the plan: the client ids are generated,
    // so only the household column moves.
    await laptop.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'm9',
        householdId: 'own-household',
        name: 'Zeynep',
        updatedAt: DateTime.utc(2026, 6, 1),
        dirty: const Value(true),
      ),
    );

    await laptop.adoptHouseholdId(from: 'own-household', to: householdId);

    final cards = await laptop.watchHouseholdMembers(householdId).first;
    expect(cards.single.name, 'Zeynep');
    expect(await laptop.dirtyHouseholdMembers(householdId), hasLength(1));
  });

  test('a card without a name is refused rather than half-merged', () async {
    // A card is a person; a nameless one is a row nobody can act on.
    await serviceFor(phone, 'phone').sync();
    folder.deviceFiles['ghost'] =
        '{"version":1,"deviceId":"ghost","householdId":"$householdId",'
        '"writtenAt":"2026-03-01T00:00:00Z","householdMembers":'
        '[{"clientId":"x","householdId":"$householdId",'
        '"updatedAt":"2026-03-01T00:00:00Z"}]}';

    await serviceFor(laptop, 'laptop').sync();

    expect(await laptop.watchHouseholdMembers(householdId).first, isEmpty);
  });
}
