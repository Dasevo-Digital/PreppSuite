import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_code.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_controller.dart';
import 'package:preppsuite_flutter/features/sharing/application/household_file.dart';
import 'package:preppsuite_flutter/features/sharing/application/shared_folder_sync_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

import '../sharing/in_memory_sync_folder.dart';

/// One notice on the stairs, filmed by two of the household's phones
/// (#399). Each kept it under a random id, and the folder carried both
/// rows to every device: the offer stood in the list twice.
void main() {
  const householdId = 'household-1';

  late InMemorySyncFolder folder;
  late AppDatabase phone;
  late AppDatabase tablet;

  final identity = HouseholdFile(
    householdId: householdId,
    name: 'Familie',
    countryCode: 'DE',
    createdAt: DateTime.utc(2026),
  );

  final notice = NeighbourOfferCode(
    kind: NeighbourOfferKind.water,
    body: '20 l Trinkwasser, abzugeben',
    contact: 'Haus 4, 2. Stock',
    offeredOn: DateTime.utc(2026, 10, 10),
  );

  setUp(() {
    folder = InMemorySyncFolder()..householdFile = identity.encode();
    phone = AppDatabase.forTesting(NativeDatabase.memory());
    tablet = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await phone.close();
    await tablet.close();
  });

  NeighbourOfferController controllerFor(AppDatabase db) =>
      NeighbourOfferController(database: db, householdId: householdId);

  Future<void> sync(AppDatabase db, String deviceId) => SharedFolderSyncService(
    database: db,
    folder: folder,
    deviceId: deviceId,
    identity: identity,
  ).sync();

  test('two phones that scan the same notice keep one offer', () async {
    expect(await controllerFor(phone).receive(notice), isTrue);
    expect(await controllerFor(tablet).receive(notice), isTrue);

    await sync(phone, 'phone');
    await sync(tablet, 'tablet');
    await sync(phone, 'phone');

    for (final db in [phone, tablet]) {
      expect(await db.watchNeighbourOffers(householdId).first, hasLength(1));
    }
  });

  test('the id follows what the code says, and the household', () {
    final same = NeighbourOfferController.receivedOfferClientId(
      householdId,
      notice,
    );
    expect(
      NeighbourOfferController.receivedOfferClientId(householdId, notice),
      same,
    );
    expect(
      NeighbourOfferController.receivedOfferClientId('next-door', notice),
      isNot(same),
    );
    expect(
      NeighbourOfferController.receivedOfferClientId(
        householdId,
        NeighbourOfferCode(
          kind: notice.kind,
          body: notice.body,
          contact: notice.contact,
          offeredOn: DateTime.utc(2026, 10, 11),
        ),
      ),
      isNot(same),
      reason: 'offered again another day is another offer',
    );
  });

  test('a notice deleted here and filmed again is back', () async {
    final controller = controllerFor(phone);
    await controller.receive(notice);
    final kept = (await phone.watchNeighbourOffers(householdId).first).single;
    await controller.delete(kept);
    expect(await phone.watchNeighbourOffers(householdId).first, isEmpty);

    expect(await controller.receive(notice), isTrue);

    final back = (await phone.watchNeighbourOffers(householdId).first).single;
    expect(back.clientId, kept.clientId);
    expect(back.deletedAt, isNull);
  });
}
