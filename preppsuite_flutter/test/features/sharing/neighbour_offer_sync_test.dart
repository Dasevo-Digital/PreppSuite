import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import 'in_memory_sync_folder.dart';

/// Offers to and from the neighbours across the household's devices
/// (#152): the phone that scanned a neighbour's offer is not necessarily
/// the one in somebody's hand when it is needed.
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

  Future<void> scan(AppDatabase db, {DateTime? deletedAt}) =>
      db.upsertNeighbourOffer(
        NeighbourOffersCompanion.insert(
          clientId: 'o1',
          householdId: householdId,
          received: const Value(true),
          kind: 'energy',
          body: 'Powerbank laden',
          contact: const Value('Klingel Meier'),
          offeredOn: DateTime.utc(2026, 10, 9),
          updatedAt: deletedAt ?? DateTime.utc(2026, 10, 10),
          deletedAt: Value(deletedAt),
          dirty: const Value(true),
        ),
      );

  test('a scanned offer reaches the other device', () async {
    await scan(phone);
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    final offer = (await laptop.watchNeighbourOffers(householdId).first).single;
    expect(offer.received, isTrue);
    expect(offer.kind, 'energy');
    expect(offer.body, 'Powerbank laden');
    expect(offer.contact, 'Klingel Meier');
  });

  test('and so does its deletion', () async {
    await scan(phone);
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    await scan(phone, deletedAt: DateTime.utc(2026, 10, 11));
    await serviceFor(phone, 'phone').sync();
    await serviceFor(laptop, 'laptop').sync();

    expect(await laptop.watchNeighbourOffers(householdId).first, isEmpty);
  });

  test('a published offer is no longer waiting to be published', () async {
    await scan(phone);
    expect(await phone.dirtyNeighbourOffers(householdId), hasLength(1));

    await serviceFor(phone, 'phone').sync();

    expect(await phone.dirtyNeighbourOffers(householdId), isEmpty);
  });

  test('a snapshot counts them', () {
    final snapshot = DeviceSnapshot(
      deviceId: 'd',
      householdId: householdId,
      writtenAt: DateTime.utc(2026, 10, 10),
      neighbourOffers: [{}, {}],
    );
    expect(snapshot.rowCount, 2);
  });

  test('a file from an older app, without them, reads as none', () {
    final decoded = DeviceSnapshot.decode(
      '{"version": 1, "deviceId": "d", "householdId": "$householdId", '
      '"writtenAt": "2026-10-10T00:00:00.000Z"}',
    );
    expect(decoded?.neighbourOffers, isEmpty);
  });

  test('a row missing its kind is still an offer', () {
    final row = decodeNeighbourOffer({
      'clientId': 'o1',
      'householdId': householdId,
      'body': 'Werkzeug',
      'updatedAt': '2026-10-10T00:00:00.000Z',
    });
    expect(row?.kind.value, 'other');
    expect(row?.offeredOn.value, DateTime.utc(2026, 10, 10));
  });
}
