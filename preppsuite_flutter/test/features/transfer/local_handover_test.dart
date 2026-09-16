import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/transfer/application/local_handover.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Two devices, a real socket between them.
///
/// Nothing is mocked here on purpose: the host binds a port, the guest
/// opens a connection to it, and the bodies really are encrypted and
/// decrypted. A handover that works against a fake and not against a
/// socket is the only kind of failure that matters in this file.
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
    String household = householdId,
  }) {
    return db.upsertInventoryItem(
      InventoryItemsCompanion.insert(
        clientId: id,
        householdId: household,
        name: name,
        category: 'Lebensmittel',
        quantity: quantity,
        unit: 'kg',
        storageLocation: 'Keller',
        updatedAt: updatedAt,
      ),
    );
  }

  /// A host bound to loopback. Only in a test does that address make
  /// sense — a real guest could never reach it, which is why
  /// `localAddresses` leaves it out.
  Future<LocalHandoverHost> hostOn(
    AppDatabase db, {
    String? household,
    int? maxRequestBytes,
  }) async {
    final host = await LocalHandoverHost.start(
      db: db,
      deviceId: 'device-a',
      householdId: household ?? householdId,
      addresses: const ['127.0.0.1'],
      maxRequestBytes: maxRequestBytes ?? localHandoverMaxRequestBytes,
    );
    addTearDown(host.stop);
    return host;
  }

  test('both sides come out agreeing, not one copied onto the other', () async {
    final a = open();
    final b = open();

    await putItem(
      a,
      id: 'item-a',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );
    await putItem(
      b,
      id: 'item-b',
      name: 'Passierte Tomaten',
      quantity: 6,
      updatedAt: DateTime.utc(2026, 9, 13, 11),
    );

    final host = await hostOn(a);
    final result = await joinLocalHandover(
      db: b,
      deviceId: 'device-b',
      householdId: householdId,
      invitation: host.invitation,
    );

    expect(result.received, 1, reason: 'the guest learned the host\'s row');

    Future<List<String>> namesIn(AppDatabase db) async => [
      for (final item in await db.watchInventoryItems(householdId).first)
        item.name,
    ];

    expect(await namesIn(a), ['Haferflocken', 'Passierte Tomaten']);
    expect(await namesIn(b), ['Haferflocken', 'Passierte Tomaten']);
  });

  test('the host is told what happened', () async {
    final a = open();
    final b = open();
    await putItem(
      b,
      id: 'item-b',
      name: 'Linsen',
      quantity: 3,
      updatedAt: DateTime.utc(2026, 9, 13, 11),
    );

    final host = await hostOn(a);
    final seen = host.handovers.first;

    await joinLocalHandover(
      db: b,
      deviceId: 'device-b',
      householdId: householdId,
      invitation: host.invitation,
    );

    expect((await seen).received, 1);
  });

  test('doing it twice changes nothing the second time', () async {
    final a = open();
    final b = open();
    await putItem(
      a,
      id: 'item-a',
      name: 'Haferflocken',
      quantity: 2,
      updatedAt: DateTime.utc(2026, 9, 13, 10),
    );

    final host = await hostOn(a);
    Future<LocalHandoverResult> run() => joinLocalHandover(
      db: b,
      deviceId: 'device-b',
      householdId: householdId,
      invitation: host.invitation,
    );

    expect((await run()).received, 1);
    expect((await run()).received, 0);
  });

  test('refuses an oversized handover before buffering it', () async {
    final host = await hostOn(open(), maxRequestBytes: 32);
    final client = HttpClient();
    addTearDown(client.close);

    final request = await client.post(
      '127.0.0.1',
      host.invitation.port,
      '/handover',
    );
    request.add(List<int>.filled(33, 0x61));
    final response = await request.close();

    expect(response.statusCode, HttpStatus.requestEntityTooLarge);
    await response.drain();
  });

  test('the later edit wins, whichever device made it', () async {
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

    final host = await hostOn(a);
    await joinLocalHandover(
      db: b,
      deviceId: 'device-b',
      householdId: householdId,
      invitation: host.invitation,
    );

    for (final db in [a, b]) {
      final kept = (await db.watchInventoryItems(householdId).first).single;
      expect(kept.quantity, 9);
    }
  });

  group('who is allowed in', () {
    test('somebody who did not see the screen is turned away', () async {
      // The whole security model in one test: the key is only on the
      // screen, so being on the same network is not enough.
      final a = open();
      final b = open();
      await putItem(
        a,
        id: 'item-a',
        name: 'Haferflocken',
        quantity: 2,
        updatedAt: DateTime.utc(2026, 9, 13, 10),
      );

      final host = await hostOn(a);
      final guessed = LocalHandoverInvitation(
        addresses: host.invitation.addresses,
        port: host.invitation.port,
        householdId: householdId,
        key: FolderKey.decode(
          // A different 32-byte key, correctly formed.
          base64FolderKeyOfZeroes,
        )!,
      );

      await expectLater(
        joinLocalHandover(
          db: b,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: guessed,
        ),
        throwsA(isA<LocalHandoverException>()),
      );
      expect(await b.watchInventoryItems(householdId).first, isEmpty);
    });

    test('a different household is refused before anything is sent', () async {
      final b = open();
      final invitation = LocalHandoverInvitation(
        addresses: const ['127.0.0.1'],
        port: 1,
        householdId: 'ein-anderer-haushalt',
        key: FolderKey.decode(base64FolderKeyOfZeroes)!,
      );

      await expectLater(
        joinLocalHandover(
          db: b,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: invitation,
        ),
        throwsA(
          isA<LocalHandoverException>().having(
            (error) => error.reason,
            'reason',
            LocalHandoverFailure.otherHousehold,
          ),
        ),
      );
    });

    test('nothing listening is reported as such', () async {
      final b = open();
      final invitation = LocalHandoverInvitation(
        // Port 1 on loopback: nothing is ever there.
        addresses: const ['127.0.0.1'],
        port: 1,
        householdId: householdId,
        key: FolderKey.decode(base64FolderKeyOfZeroes)!,
      );

      await expectLater(
        joinLocalHandover(
          db: b,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: invitation,
          timeout: const Duration(milliseconds: 400),
        ),
        throwsA(
          isA<LocalHandoverException>().having(
            (error) => error.reason,
            'reason',
            LocalHandoverFailure.unreachable,
          ),
        ),
      );
    });
  });

  group('the invitation', () {
    test('survives being written out and read back', () {
      final invitation = LocalHandoverInvitation(
        addresses: const ['192.168.10.34', '10.0.0.7'],
        port: 54321,
        householdId: householdId,
        key: FolderKey.decode(base64FolderKeyOfZeroes)!,
      );

      final read = LocalHandoverInvitation.decode(invitation.encode())!;

      expect(read.addresses, ['192.168.10.34', '10.0.0.7']);
      expect(read.port, 54321);
      expect(read.householdId, householdId);
      expect(read.key.encode(), invitation.key.encode());
    });

    test('anything else the camera sees is not one', () {
      expect(LocalHandoverInvitation.decode('4006381333931'), isNull);
      expect(LocalHandoverInvitation.decode('PS1:aabb:0:1:data'), isNull);
      expect(LocalHandoverInvitation.decode('PSL1:::'), isNull);
      expect(LocalHandoverInvitation.decode('PSL1:1.2.3.4:nope:h:k'), isNull);
    });

    test(
      'it carries every address, because only one of them may work',
      () async {
        // A laptop on cable and wireless at once has two, and which one
        // reaches the phone is not knowable from this side.
        final a = open();
        final host = await LocalHandoverHost.start(
          db: a,
          deviceId: 'device-a',
          householdId: householdId,
          addresses: const ['10.0.0.7', '127.0.0.1'],
        );
        addTearDown(host.stop);

        final b = open();
        // The first address goes nowhere; the second is the live one.
        final result = await joinLocalHandover(
          db: b,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: host.invitation,
          timeout: const Duration(milliseconds: 600),
        );

        expect(result.received, 0, reason: 'it got through on the second');
      },
    );
  });
}

/// A well-formed key that is not the host's.
const base64FolderKeyOfZeroes = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
