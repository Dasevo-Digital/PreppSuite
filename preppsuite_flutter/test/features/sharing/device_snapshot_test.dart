import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  Map<String, Object?> water({Map<String, Object?> overrides = const {}}) => {
    'clientId': 'water',
    'householdId': 'household-1',
    'name': 'Trinkwasser',
    'category': 'water',
    'quantity': 6.5,
    'unit': 'Flasche',
    'storageLocation': 'Keller',
    'expirationDate': '2027-03-01T00:00:00.000Z',
    'minQuantity': 3.0,
    'calories': 0,
    'notes': 'Hinten links',
    'updatedAt': '2026-01-01T00:00:00.000Z',
    ...overrides,
  };

  group('inventory rows', () {
    test('every field the folder carries survives a decode', () {
      final companion = decodeInventoryItem(water())!;

      expect(companion.clientId.value, 'water');
      expect(companion.name.value, 'Trinkwasser');
      expect(companion.quantity.value, 6.5);
      expect(companion.minQuantity.value, 3.0);
      expect(companion.notes.value, 'Hinten links');
      expect(companion.expirationDate.value, DateTime.utc(2027, 3));
      expect(companion.updatedAt.value, DateTime.utc(2026));
    });

    test('the macronutrients travel between devices', () {
      // Added to the format after it was already in use, so both halves
      // matter: a device that has them must send them, and one that never
      // saw the columns must still be readable.
      final companion = decodeInventoryItem(
        water(
          overrides: {
            'proteinGrams': 42.5,
            'carbohydrateGrams': 300.0,
            'fatGrams': 8.0,
            'fiberGrams': 15.0,
          },
        ),
      )!;

      expect(companion.proteinGrams.value, 42.5);
      expect(companion.carbohydrateGrams.value, 300.0);
      expect(companion.fatGrams.value, 8.0);
      expect(companion.fiberGrams.value, 15.0);
    });

    test('a snapshot written before those columns still decodes', () {
      final companion = decodeInventoryItem(water())!;

      expect(companion.proteinGrams.value, isNull);
      expect(companion.fiberGrams.value, isNull);
    });

    group('the package (#90)', () {
      InventoryItem jarRow({String? name = 'Glas', double? size = 370}) =>
          InventoryItem(
            clientId: 'beans',
            householdId: 'household-1',
            name: 'Bohnen',
            category: 'food',
            quantity: 1110,
            unit: 'g',
            storageLocation: 'Keller',
            packageName: name,
            packageSize: size,
            updatedAt: DateTime.utc(2026),
            dirty: true,
          );

      test('travels between devices', () {
        final companion = decodeInventoryItem(encodeInventoryItem(jarRow()))!;

        expect(companion.packageName.value, 'Glas');
        expect(companion.packageSize.value, 370);
      });

      test('a cleared package is written as cleared', () {
        final json = encodeInventoryItem(jarRow(name: null, size: null));
        final companion = decodeInventoryItem(json)!;

        expect(json.containsKey('packageName'), isTrue);
        expect(companion.packageName, const Value<String?>(null));
        expect(companion.packageSize, const Value<double?>(null));
      });

      // An app before schema 21 writes no package keys -- also for a row
      // it edited and wrote back. Decoded as null, that edit would strip
      // the jar size typed on a newer device.
      test('an older device leaves it alone', () async {
        final db = AppDatabase.forTesting(NativeDatabase.memory());
        addTearDown(db.close);
        await db.upsertInventoryItem(jarRow().toCompanion(false));

        final fromOlder = Map.of(encodeInventoryItem(jarRow()))
          ..remove('packageName')
          ..remove('packageSize')
          ..['quantity'] = 740.0
          ..['updatedAt'] = '2026-02-01T00:00:00.000Z';
        final companion = decodeInventoryItem(fromOlder)!;
        expect(companion.packageName.present, isFalse);
        await db.into(db.inventoryItems).insertOnConflictUpdate(companion);

        final stored =
            (await db.watchInventoryItems('household-1').first).single;
        expect(stored.quantity, 740);
        expect(stored.packageName, 'Glas');
        expect(stored.packageSize, 370);
      });
    });

    test('a row that arrived from elsewhere is not marked for publishing', () {
      // Otherwise every device would republish everything it received on
      // the next run, forever, and the folder would never go quiet.
      expect(decodeInventoryItem(water())!.dirty.value, isFalse);
    });

    test('a whole number decodes into a double column', () {
      // JSON has one number type: a quantity of exactly 6 comes back as an
      // int and would throw on a plain cast.
      final companion = decodeInventoryItem(
        water(overrides: {'quantity': 6}),
      )!;

      expect(companion.quantity.value, 6.0);
    });

    test('a row missing something required is skipped, not thrown on', () {
      for (final missing in [
        'clientId',
        'householdId',
        'name',
        'category',
        'quantity',
        'updatedAt',
      ]) {
        final broken = water()..remove(missing);
        expect(decodeInventoryItem(broken), isNull, reason: missing);
      }
    });

    test('the photo path is never written into the folder', () {
      // It points into one device's documents directory and the picture
      // itself does not travel, so carrying it would only produce broken
      // references on the other device.
      final encoded = encodeInventoryItem(
        InventoryItem(
          clientId: 'water',
          householdId: 'household-1',
          name: 'Trinkwasser',
          category: 'water',
          quantity: 6,
          unit: 'Flasche',
          storageLocation: 'Keller',
          photoPath: 'photos/water.jpg',
          updatedAt: DateTime.utc(2026),
          dirty: true,
        ),
      );

      expect(encoded.containsKey('photoPath'), isFalse);
      expect(encoded.values, isNot(contains('photos/water.jpg')));
      expect(encoded['clientId'], 'water');
    });
  });

  group('snapshots', () {
    test('an encoded snapshot decodes back to the same rows', () {
      final encoded = DeviceSnapshot(
        deviceId: 'phone',
        householdId: 'household-1',
        writtenAt: DateTime.utc(2026, 6),
        inventoryItems: [water()],
      ).encode();

      final decoded = DeviceSnapshot.decode(encoded)!;

      expect(decoded.deviceId, 'phone');
      expect(decoded.householdId, 'household-1');
      expect(decoded.writtenAt, DateTime.utc(2026, 6));
      expect(decoded.inventoryItems.single['clientId'], 'water');
      expect(decoded.checklistItems, isEmpty);
    });

    test(
      'a snapshot from a newer version is refused rather than guessed at',
      () {
        final encoded =
            '{"version": ${DeviceSnapshot.currentVersion + 1}, '
            '"deviceId": "phone", "householdId": "household-1"}';

        expect(DeviceSnapshot.decode(encoded), isNull);
      },
    );

    test('a truncated file decodes to null', () {
      expect(DeviceSnapshot.decode('{"version": 1, "deviceId"'), isNull);
    });
  });
}
