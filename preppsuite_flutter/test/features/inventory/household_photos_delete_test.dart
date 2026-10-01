import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/inventory_photo_service.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The pictures go with the household.
///
/// "Reset household" and "replace" deleted the rows and left the files:
/// shown nowhere, in no backup, and still on the disk — among them the
/// possessions list, which exists to photograph valuables with their
/// serial numbers.
void main() {
  late AppDatabase db;
  late Directory folder;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    folder = Directory.systemTemp.createTempSync('preppsuite-photos');
  });

  tearDown(() async {
    await db.close();
    folder.deleteSync(recursive: true);
  });

  File photo(String name) =>
      File('${folder.path}${Platform.pathSeparator}$name')
        ..writeAsBytesSync([0xff, 0xd8, 0xff]);

  Future<void> item(String householdId, String clientId, File? picture) =>
      db.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: clientId,
          householdId: householdId,
          name: clientId,
          category: 'water',
          quantity: 1,
          unit: 'l',
          storageLocation: 'Keller',
          photoPath: Value(picture?.path),
          updatedAt: DateTime.utc(2026),
          dirty: const Value(true),
        ),
      );

  test('every picture of the household is deleted, and no other', () async {
    final water = photo('water.jpg');
    final camera = photo('camera.jpg');
    final neighbours = photo('neighbours.jpg');
    await item('home', 'water', water);
    await item('home', 'rice', null);
    await db.upsertPossession(
      PossessionsCompanion.insert(
        clientId: 'camera',
        householdId: 'home',
        name: 'Kamera',
        photoPath: Value(camera.path),
        updatedAt: DateTime.utc(2026),
        dirty: const Value(true),
      ),
    );
    await item('elsewhere', 'theirs', neighbours);

    final deleted = await deleteHouseholdPhotos(db, householdId: 'home');

    expect(deleted, 2);
    expect(water.existsSync(), isFalse);
    expect(camera.existsSync(), isFalse);
    expect(neighbours.existsSync(), isTrue);
  });

  test('a picture already gone is not an error', () async {
    final gone = photo('gone.jpg')..deleteSync();
    await item('home', 'water', gone);

    expect(await deleteHouseholdPhotos(db, householdId: 'home'), 0);
  });
}
