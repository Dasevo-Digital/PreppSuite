import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/core/photo_hashes.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Which pictures a row has follows a rule of its own in the merge (#376):
/// a newer version brings its list when it has one, a device that knows
/// nothing says nothing, and two lists for one version settle the same
/// way on every device.
void main() {
  const household = 'household-1';
  final a = 'a' * 64;
  final b = 'b' * 64;
  final version = DateTime.utc(2026, 11, 1, 12);
  final later = DateTime.utc(2026, 11, 2, 12);

  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Map<String, Object?> row({
    required DateTime at,
    double quantity = 4,
    Object? photoHashes = const _Missing(),
    List<String?>? seen,
  }) => {
    'clientId': 'tin',
    'householdId': household,
    'name': 'Ravioli',
    'category': 'food',
    'quantity': quantity,
    'unit': 'Dose',
    'storageLocation': 'Keller',
    // Every key a device file carries, as encodeInventoryItem writes them:
    // a row missing some would differ from the stored one in its contents
    // and win or lose on those.
    for (final key in const [
      'barcode',
      'offProductId',
      'expirationDate',
      'minQuantity',
      'calories',
      'proteinGrams',
      'carbohydrateGrams',
      'fatGrams',
      'fiberGrams',
      'dailyDose',
      'expiryLeadDays',
      'foodGroup',
      'packageName',
      'packageSize',
      'memberId',
      'refillLeadDays',
      'stockCountedAt',
      'chargeEveryDays',
      'chargeCheckedAt',
      'notes',
    ])
      key: null,
    'updatedAt': at.toIso8601String(),
    'deletedAt': null,
    if (photoHashes is! _Missing) 'photoHashes': photoHashes,
    'photoHashesSeen': ?seen,
  };

  Future<int> apply(Map<String, Object?> json) => applyHouseholdSnapshot(
    db,
    DeviceSnapshot(
      deviceId: 'other',
      householdId: household,
      writtenAt: DateTime.utc(2026, 11, 3),
      inventoryItems: [json],
    ),
  );

  Future<InventoryItem> stored() async =>
      (await db.inventoryItemsForSync(household)).single;

  PhotoList? listOf(InventoryItem row) =>
      decodePhotoList(row.photoHashes, places: 3);
  PhotoList set(List<String?> places) => PhotoList(places);
  PhotoList seenList(List<String?> places) => PhotoList(places, seen: true);

  test('a newer version brings its list', () async {
    await apply(row(at: version, photoHashes: [a, null, null]));
    await apply(row(at: later, quantity: 2, photoHashes: [b, null, null]));
    expect(listOf(await stored()), set([b, null, null]));
    expect((await stored()).quantity, 2);
  });

  test('a newer version that knows no pictures keeps the list', () async {
    await apply(row(at: version, photoHashes: [a, null, null]));
    // An older app writes no key at all; a newer one that never held the
    // pictures writes null. Neither empties them.
    await apply(row(at: later, quantity: 3));
    expect(listOf(await stored()), set([a, null, null]));
    await apply(
      row(
        at: later.add(const Duration(hours: 1)),
        quantity: 2,
        photoHashes: null,
      ),
    );
    expect(listOf(await stored()), set([a, null, null]));
    expect((await stored()).quantity, 2);
  });

  test('three empty places do empty the pictures', () async {
    await apply(row(at: version, photoHashes: [a, null, null]));
    await apply(row(at: later, photoHashes: [null, null, null]));
    expect(listOf(await stored()), set([null, null, null]));
  });

  test('the same version fills an unknown list, without an edit', () async {
    await apply(row(at: version));
    expect((await stored()).photoHashes, isNull);
    final changed = await apply(row(at: version, photoHashes: [a, null, null]));
    expect(changed, 1, reason: 'learned, so it is published again');
    final after = await stored();
    expect(listOf(after), set([a, null, null]));
    expect(after.updatedAt.isAtSameMomentAs(version), isTrue);
    expect(after.dirty, isFalse);
    expect(await apply(row(at: version, photoHashes: [a, null, null])), 0);
  });

  test('two seen lists for one version join, the same in any order', () async {
    final second = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(second.close);
    Future<void> into(AppDatabase target, List<String?> seen) =>
        applyHouseholdSnapshot(
          target,
          DeviceSnapshot(
            deviceId: 'other',
            householdId: household,
            writtenAt: DateTime.utc(2026, 11, 3),
            inventoryItems: [row(at: version, seen: seen)],
          ),
        );
    // Two devices that each got one picture of the item by a handover.
    await into(db, [a, null, null]);
    await into(db, [null, b, null]);
    await into(second, [null, b, null]);
    await into(second, [a, null, null]);
    expect(listOf(await stored()), seenList([a, b, null]));
    expect(
      decodePhotoList(
        (await second.inventoryItemsForSync(household)).single.photoHashes,
        places: 3,
      ),
      seenList([a, b, null]),
    );
  });

  test('a seen list never empties what an edit set', () async {
    await apply(row(at: version, photoHashes: [a, null, null]));
    // A device that has none of the pictures, at the same version and at
    // a newer one: nothing it says takes the picture out.
    await apply(row(at: version, seen: [null, null, null]));
    await apply(row(at: later, quantity: 2, seen: [null, b, null]));
    expect(listOf(await stored()), set([a, null, null]));
    expect((await stored()).quantity, 2);
  });

  test('an edit set at the same version beats what was only seen', () async {
    await apply(row(at: version, seen: [a, b, null]));
    await apply(row(at: version, photoHashes: [b, null, null]));
    expect(listOf(await stored()), set([b, null, null]));
  });

  test('a list alone never wins a row', () async {
    await apply(row(at: version, quantity: 4, seen: [a, null, null]));
    // The same second, the same contents, another list: only the list can
    // move, and only by its own rule.
    await apply(row(at: version, quantity: 4, seen: [null, b, null]));
    final after = await stored();
    expect(after.quantity, 4);
    expect(listOf(after), seenList([a, b, null]));
  });

  test(
    'a sibling of the same second that wins its row keeps the set list',
    () async {
      await apply(row(at: version, quantity: 4, photoHashes: [b, a, null]));
      // Other contents that sort higher win the row; the list they bring
      // was only seen and does not replace the one an edit set.
      await apply(row(at: version, quantity: 9, seen: [a, null, null]));
      final after = await stored();
      expect(after.quantity, 9);
      expect(listOf(after), set([b, a, null]));
    },
  );

  group('a local edit', () {
    Future<void> local(InventoryItemsCompanion change) =>
        db.upsertInventoryItem(change);

    InventoryItemsCompanion tin({
      Value<String?> photoPath = const Value.absent(),
      Value<String?> photoHashes = const Value.absent(),
      double quantity = 4,
    }) => InventoryItemsCompanion.insert(
      clientId: 'tin',
      householdId: household,
      name: 'Ravioli',
      category: 'food',
      quantity: quantity,
      unit: 'Dose',
      storageLocation: 'Keller',
      photoPath: photoPath,
      photoHashes: photoHashes,
      updatedAt: DateTime.now().toUtc(),
    );

    test(
      'that moves a picture without saying which forgets the list',
      () async {
        await local(
          tin(
            photoPath: const Value('/photos/one.jpg'),
            photoHashes: Value(encodePhotoList(PhotoList([a, null, null]))),
          ),
        );
        await local(tin(photoPath: const Value('/photos/two.jpg')));
        expect((await stored()).photoHashes, isNull);
      },
    );

    test('that leaves the pictures where they were keeps the list', () async {
      await local(
        tin(
          photoPath: const Value('/photos/one.jpg'),
          photoHashes: Value(encodePhotoList(PhotoList([a, null, null]))),
        ),
      );
      await local(tin(photoPath: const Value('/photos/one.jpg'), quantity: 3));
      await local(tin(quantity: 2));
      expect(listOf(await stored()), set([a, null, null]));
    });

    test('of a possession follows the same rule', () async {
      PossessionsCompanion lamp(String path, {String? hashes}) =>
          PossessionsCompanion.insert(
            clientId: 'lamp',
            householdId: household,
            name: 'Lampe',
            photoPath: Value(path),
            photoHashes: hashes == null ? const Value.absent() : Value(hashes),
            updatedAt: DateTime.now().toUtc(),
          );
      await db.upsertPossession(
        lamp('/photos/l.jpg', hashes: encodePhotoList(PhotoList([a]))),
      );
      await db.upsertPossession(lamp('/photos/l.jpg'));
      expect(
        (await db.possessionsForSync(household)).single.photoHashes,
        encodePhotoList(PhotoList([a])),
      );
      await db.upsertPossession(lamp('/photos/m.jpg'));
      expect(
        (await db.possessionsForSync(household)).single.photoHashes,
        isNull,
      );
    });
  });

  test('the list goes out with the row, an unknown one as null', () async {
    await apply(row(at: version, seen: [a, null, null]));
    final seenJson = encodeInventoryItem(await stored());
    expect(seenJson['photoHashesSeen'], [a, null, null]);
    expect(seenJson.containsKey('photoHashes'), isFalse);
    await apply(row(at: later, photoHashes: [a, null, null]));
    expect(encodeInventoryItem(await stored())['photoHashes'], [a, null, null]);
    await db.customStatement('UPDATE inventory_items SET photo_hashes = NULL');
    final json = encodeInventoryItem(await stored());
    expect(json.containsKey('photoHashes'), isTrue);
    expect(json['photoHashes'], isNull);
  });
}

class _Missing {
  const _Missing();
}
