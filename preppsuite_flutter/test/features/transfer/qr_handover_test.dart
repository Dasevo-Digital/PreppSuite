import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/snapshot_exchange.dart';
import 'package:preppsuite_flutter/features/transfer/application/qr_chain.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Two real databases, one handed to the other through the QR chain.
///
/// The unit tests take the chain apart; this one puts the whole road
/// together — read a household out, cut it into frames, feed the frames
/// to a receiver the way a camera would, and merge the result into a
/// second database. Nothing in between: no folder, no network.
void main() {
  const householdId = 'household-1';

  AppDatabase open() {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    return db;
  }

  Future<void> putItem(
    AppDatabase db, {
    required String id,
    required String name,
    required double quantity,
    required DateTime updatedAt,
  }) {
    return db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: id,
        householdId: householdId,
        name: name,
        category: 'Lebensmittel',
        quantity: quantity,
        unit: 'kg',
        storageLocation: 'Keller',
        updatedAt: updatedAt,
      ),
    );
  }

  /// Everything a camera pointed at [from] would eventually see, merged
  /// into [into]. Returns how many rows it learned.
  Future<int> handOver(
    AppDatabase from,
    AppDatabase into, {
    Iterable<int> Function(int total)? sees,
  }) async {
    final snapshot = await readHouseholdSnapshot(
      from,
      deviceId: 'device-a',
      householdId: householdId,
    );
    final frames = qrChainFrames(
      Uint8List.fromList(utf8.encode(snapshot.encode())),
    );

    final receiver = QrChainReceiver();
    for (final index
        in sees?.call(frames.length) ?? Iterable<int>.generate(frames.length)) {
      receiver.take(frames[index]);
    }
    if (!receiver.isComplete) return -1;

    final decoded = DeviceSnapshot.decode(utf8.decode(receiver.payload()!))!;
    return applyHouseholdSnapshot(into, decoded);
  }

  test('a household arrives on the other device', () async {
    final a = open();
    final b = open();

    await putItem(
      a,
      id: 'item-1',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );
    await putItem(
      a,
      id: 'item-2',
      name: 'Passierte Tomaten',
      quantity: 6,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );

    expect(await handOver(a, b), 2);

    final arrived = await b.watchInventoryItems(householdId).first;
    expect(arrived.map((item) => item.name), [
      'Haferflocken',
      'Passierte Tomaten',
    ]);
  });

  test('the newer row wins, whichever side it is on', () async {
    // The merge rules are the folder's, unchanged. What this checks is
    // that the road does not quietly lose the version they compare.
    final a = open();
    final b = open();

    await putItem(
      a,
      id: 'item-1',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );
    await putItem(
      b,
      id: 'item-1',
      name: 'Haferflocken',
      quantity: 9,
      updatedAt: DateTime.utc(2026, 9, 13, 18),
    );

    await handOver(a, b);

    final kept = (await b.watchInventoryItems(householdId).first).single;
    expect(kept.quantity, 9, reason: 'the later edit stands');
  });

  test('handing the same thing over twice changes nothing', () async {
    // Which is what makes it safe to do when unsure whether it worked.
    final a = open();
    final b = open();
    await putItem(
      a,
      id: 'item-1',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );

    expect(await handOver(a, b), 1);
    expect(await handOver(a, b), 0, reason: 'nothing new the second time');
  });

  test(
    'a camera that misses half the frames gets there on the next pass',
    () async {
      final a = open();
      final b = open();
      for (var index = 0; index < 120; index++) {
        await putItem(
          a,
          id: 'item-$index',
          name: 'Vorrat $index',
          quantity: index / 3,
          updatedAt: DateTime.utc(2026, 9, 13, 10),
        );
      }

      final learned = await handOver(
        a,
        b,
        // Every other frame, then round again for the rest — which is what
        // the looping sender is for.
        sees: (total) => [
          for (var index = 0; index < total; index += 2) index,
          for (var index = 0; index < total; index++) index,
        ],
      );

      expect(learned, 120);
    },
  );

  test('a snapshot from another household is recognisable as one', () async {
    // The receive screen refuses it; here it is only established that the
    // information to refuse on actually survives the trip.
    final a = open();
    await putItem(
      a,
      id: 'item-1',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );

    final snapshot = await readHouseholdSnapshot(
      a,
      deviceId: 'device-a',
      householdId: householdId,
    );
    final frames = qrChainFrames(
      Uint8List.fromList(utf8.encode(snapshot.encode())),
    );
    final receiver = QrChainReceiver();
    for (final frame in frames) {
      receiver.take(frame);
    }

    final decoded = DeviceSnapshot.decode(utf8.decode(receiver.payload()!))!;
    expect(decoded.householdId, householdId);
    expect(decoded.householdId, isNot('ein-anderer-haushalt'));
  });

  test('emergency cards travel too, and that is worth knowing', () async {
    // Health data. It goes over an unencrypted picture on a screen, which
    // is fine between two people standing together and would not be fine
    // over anything else -- see the note in qr_chain.dart.
    final a = open();
    final b = open();
    await a.upsertHouseholdMember(
      HouseholdMembersCompanion.insert(
        clientId: 'member-1',
        householdId: householdId,
        name: 'Lena',
        allergies: const Value('Penicillin'),
        updatedAt: DateTime.utc(2026, 9, 13, 10),
      ),
    );

    expect(await handOver(a, b), 1);

    final arrived = (await b.watchHouseholdMembers(householdId).first).single;
    expect(arrived.name, 'Lena');
    expect(arrived.allergies, 'Penicillin');
  });
}
