import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/features/transfer/application/handover_photos.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The pictures of the stock, crossing to a second device.
///
/// They are the one part of a household the snapshot never carried, for a
/// good reason — what is stored is a path into one machine's own folder —
/// and so a second device used to show an inventory of grey placeholders.
void main() {
  const household = 'home';
  late Directory here;
  late Directory there;

  setUp(() async {
    here = await Directory.systemTemp.createTemp('preppsuite-here');
    there = await Directory.systemTemp.createTemp('preppsuite-there');
  });

  tearDown(() async {
    await here.delete(recursive: true);
    await there.delete(recursive: true);
  });

  Future<AppDatabase> database() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  /// A file with recognisable contents, so a test can tell one picture
  /// from another without decoding anything.
  Future<String> picture(Directory dir, String name, int fill) async {
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(Uint8List.fromList(List.filled(64, fill)));
    return file.path;
  }

  Future<void> addItem(
    AppDatabase db, {
    required String clientId,
    String? photoPath,
  }) => db.upsertInventoryItem(
    InventoryItemsCompanion.insert(
      clientId: clientId,
      householdId: household,
      name: clientId,
      category: 'food',
      quantity: 1,
      unit: 'Stk',
      storageLocation: 'Keller',
      updatedAt: DateTime.utc(2026, 9, 20),
      photoPath: Value(photoPath),
    ),
  );

  Future<String?> photoOf(AppDatabase db, String clientId) async {
    final rows = await db.inventoryItemsForSync(household);
    return rows.firstWhere((row) => row.clientId == clientId).photoPath;
  }

  group('a name that came off the wire', () {
    test('a plain file name is allowed through', () {
      expect(HandoverPhoto.safeName('a3f2.jpg'), 'a3f2.jpg');
    });

    test('anything that is a path is refused', () {
      // The name goes straight into a file path on the receiving device.
      // The other side held up a QR code; that proves it was in the room,
      // not that it is this app.
      for (final hostile in [
        '../../evil.jpg',
        '/etc/passwd',
        r'..\..\evil.jpg',
        r'C:\Windows\evil.jpg',
        'sub/dir.jpg',
        '..',
        '.',
        '',
      ]) {
        expect(HandoverPhoto.safeName(hostile), isNull, reason: hostile);
      }
    });

    test('a photo whose name is a path does not decode at all', () {
      expect(
        HandoverPhoto.fromJson({
          'owner': 'inventory',
          'clientId': 'beans',
          'name': '../escape.jpg',
          'bytes': 'AAAA',
        }),
        isNull,
      );
    });
  });

  test(
    'a picture crosses and the row on the other side points at it',
    () async {
      final sender = await database();
      await addItem(
        sender,
        clientId: 'beans',
        photoPath: await picture(here, 'a.jpg', 7),
      );

      final sent = await readHouseholdPhotos(sender, householdId: household);
      expect(sent, hasLength(1));
      expect(sent.single.clientId, 'beans');
      expect(sent.single.owner, PhotoOwner.inventory);

      // The other device: the same row, no picture.
      final receiver = await database();
      await addItem(receiver, clientId: 'beans');
      expect(
        await applyHouseholdPhotos(
          receiver,
          householdId: household,
          photos: sent,
          into: there,
        ),
        1,
      );

      final stored = await photoOf(receiver, 'beans');
      expect(stored, isNotNull);
      expect(p.dirname(stored!), there.path);
      expect(await File(stored).readAsBytes(), List.filled(64, 7));
    },
  );

  test(
    'the row is pointed at the picture without being marked dirty',
    () async {
      // The stored path belongs to this machine and to no other, so taking
      // a photo in must not look like an edit — or the row would be pushed
      // straight back out carrying a path that means nothing over there.
      final receiver = await database();
      await addItem(receiver, clientId: 'beans');
      final before = (await receiver.inventoryItemsForSync(household)).single;

      await applyHouseholdPhotos(
        receiver,
        householdId: household,
        photos: [
          HandoverPhoto(
            owner: PhotoOwner.inventory,
            clientId: 'beans',
            name: 'a.jpg',
            bytes: Uint8List.fromList(List.filled(64, 7)),
          ),
        ],
        into: there,
      );

      final after = (await receiver.inventoryItemsForSync(household)).single;
      expect(after.updatedAt, before.updatedAt);
      expect(after.dirty, before.dirty);
    },
  );

  test('a picture the other side already has is not sent again', () async {
    final sender = await database();
    await addItem(
      sender,
      clientId: 'beans',
      photoPath: await picture(here, 'a.jpg', 7),
    );
    await addItem(
      sender,
      clientId: 'rice',
      photoPath: await picture(here, 'b.jpg', 9),
    );

    final asked = await readHouseholdPhotos(
      sender,
      householdId: household,
      skip: {'a.jpg'},
    );

    expect(asked.map((photo) => photo.name), ['b.jpg']);
  });

  test('a picture already here is kept, not replaced', () async {
    // Whichever device spoke last must not win: a photo somebody replaced
    // on this device would come back on the next handover.
    final receiver = await database();
    final mine = await picture(there, 'mine.jpg', 3);
    await addItem(receiver, clientId: 'beans', photoPath: mine);

    final taken = await applyHouseholdPhotos(
      receiver,
      householdId: household,
      photos: [
        HandoverPhoto(
          owner: PhotoOwner.inventory,
          clientId: 'beans',
          name: 'theirs.jpg',
          bytes: Uint8List.fromList(List.filled(64, 9)),
        ),
      ],
      into: there,
    );

    expect(taken, 0);
    expect(await photoOf(receiver, 'beans'), mine);
  });

  test('a row whose file went missing gets the incoming picture', () async {
    final receiver = await database();
    await addItem(
      receiver,
      clientId: 'beans',
      photoPath: p.join(there.path, 'gone.jpg'),
    );

    expect(
      await applyHouseholdPhotos(
        receiver,
        householdId: household,
        photos: [
          HandoverPhoto(
            owner: PhotoOwner.inventory,
            clientId: 'beans',
            name: 'theirs.jpg',
            bytes: Uint8List.fromList(List.filled(64, 9)),
          ),
        ],
        into: there,
      ),
      1,
    );
  });

  test('the budget stops a large inventory rather than the handover', () async {
    final sender = await database();
    for (var i = 0; i < 4; i++) {
      await addItem(
        sender,
        clientId: 'item-$i',
        photoPath: await picture(here, 'p$i.jpg', i),
      );
    }

    // Room for two of the four 64-byte pictures.
    final sent = await readHouseholdPhotos(
      sender,
      householdId: household,
      budgetBytes: 140,
    );

    expect(sent, hasLength(2));
    // In name order, so the next handover — which will ask for what is
    // still missing — carries on rather than starting again.
    expect(sent.map((photo) => photo.name), ['p0.jpg', 'p1.jpg']);
  });

  test('what this device holds is what it asks not to be sent', () async {
    final db = await database();
    await addItem(
      db,
      clientId: 'beans',
      photoPath: await picture(here, 'a.jpg', 7),
    );
    await addItem(
      db,
      clientId: 'gone',
      photoPath: p.join(here.path, 'missing.jpg'),
    );

    // Only the one that is really on disk: a row pointing at nothing is
    // exactly the case a handover is meant to repair.
    expect(await localPhotoNames(db, householdId: household), {'a.jpg'});
  });
}
