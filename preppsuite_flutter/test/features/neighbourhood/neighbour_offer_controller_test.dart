import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/app_database_providers.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_code.dart';
import 'package:preppsuite_flutter/features/neighbourhood/application/neighbour_offer_controller.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  const householdId = 'household-1';
  late AppDatabase db;
  late ProviderContainer container;
  late NeighbourOfferController controller;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    controller = container.read(neighbourOfferControllerProvider(householdId));
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<List<NeighbourOffer>> offers() =>
      db.watchNeighbourOffers(householdId).first;

  final scanned = NeighbourOfferCode(
    kind: NeighbourOfferKind.energy,
    body: 'Powerbank laden, Solarpanel im Garten',
    contact: 'Klingel Meier',
    offeredOn: DateTime.utc(2026, 10, 9),
  );

  test('an own offer is one clean line, dated today', () async {
    await controller.saveOwn(
      kind: NeighbourOfferKind.water,
      body: '  20 l\nTrinkwasser ',
      contact: '   ',
      now: DateTime(2026, 10, 10, 23, 30),
    );

    final offer = (await offers()).single;
    expect(offer.received, isFalse);
    expect(offer.body, '20 l Trinkwasser');
    expect(offer.contact, isNull, reason: 'blank is no contact');
    expect(offer.code.offeredOn, DateTime.utc(2026, 10, 10));
    expect(offer.dirty, isTrue);
  });

  test('a scanned offer is kept, once', () async {
    expect(await controller.receive(scanned), isTrue);
    expect(await controller.receive(scanned), isFalse);

    final offer = (await offers()).single;
    expect(offer.received, isTrue);
    expect(offer.offerKind, NeighbourOfferKind.energy);
    expect(offer.code.offeredOn, DateTime.utc(2026, 10, 9));
  });

  test('the same text offered again on another day is another offer', () {
    // Water offered last week may be gone; offered again today, it is
    // there again. Both are what the neighbour said, on the day they
    // said it.
    return () async {
      await controller.receive(scanned);
      final later = NeighbourOfferCode(
        kind: scanned.kind,
        body: scanned.body,
        contact: scanned.contact,
        offeredOn: DateTime.utc(2026, 10, 16),
      );
      expect(await controller.receive(later), isTrue);
      expect(await offers(), hasLength(2));
    }();
  });

  test('an edit is waiting to be published again', () async {
    await controller.saveOwn(kind: NeighbourOfferKind.water, body: '20 l');
    final first = (await offers()).single;
    await db.markHouseholdPublished(
      householdId,
      offers: [(clientId: first.clientId, updatedAt: first.updatedAt)],
    );
    expect(await db.dirtyNeighbourOffers(householdId), isEmpty);

    await controller.saveOwn(
      kind: NeighbourOfferKind.water,
      body: '10 l',
      existing: first,
    );

    expect((await offers()).single.body, '10 l');
    expect(await db.dirtyNeighbourOffers(householdId), hasLength(1));
  });

  test('deleting leaves a tombstone for the other devices', () async {
    await controller.receive(scanned);
    await controller.delete((await offers()).single);

    expect(await offers(), isEmpty);
    final rows = await db.neighbourOffersForSync(householdId);
    expect(rows.single.deletedAt, isNotNull);
    expect(rows.single.dirty, isTrue);
  });
}
