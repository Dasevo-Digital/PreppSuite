import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';
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
    CarriedHousehold offering = const CarriedHousehold(),
  }) async {
    final host = await LocalHandoverHost.start(
      db: db,
      deviceId: 'device-a',
      householdId: household ?? householdId,
      addresses: const ['127.0.0.1'],
      maxRequestBytes: maxRequestBytes ?? localHandoverMaxRequestBytes,
      offering: offering,
    );
    addTearDown(host.stop);
    return host;
  }

  /// A directory that stands in for one device's photo folder.
  Future<Directory> folder(String name) async {
    final dir = await Directory.systemTemp.createTemp('preppsuite-$name');
    addTearDown(() => dir.delete(recursive: true));
    return dir;
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

  group('what rides along beside the rows', () {
    test('the household setup comes back from the host', () async {
      // Only the host offers it: a guest being set up is the one device
      // with nothing of its own to lose, and it is never the host.
      final host = await hostOn(
        open(),
        offering: const CarriedHousehold(
          profile: HouseholdProfile(
            id: householdId,
            name: 'Zuhause',
            countryCode: 'DE',
            personCount: 4,
            children: 2,
          ),
          settings: {'pegelStation': 'DRESDEN', 'expiryLeadDays': 21},
        ),
      );

      final result = await joinLocalHandover(
        db: open(),
        deviceId: 'device-b',
        householdId: householdId,
        invitation: host.invitation,
      );

      expect(result.household.profile?.name, 'Zuhause');
      expect(result.household.profile?.personCount, 4);
      expect(result.household.profile?.children, 2);
      expect(result.household.settings['pegelStation'], 'DRESDEN');
    });

    test('a photograph crosses the socket with its row', () async {
      final a = open();
      final b = open();
      final theirs = await folder('host');
      final mine = await folder('guest');

      final file = File(p.join(theirs.path, 'a3f2.jpg'));
      await file.writeAsBytes(Uint8List.fromList(List.filled(256, 42)));
      await a.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'item-a',
          householdId: householdId,
          name: 'Haferflocken',
          category: 'Lebensmittel',
          quantity: 2,
          unit: 'kg',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 13, 10),
          photoPath: Value(file.path),
        ),
      );

      final host = await hostOn(a);
      final result = await joinLocalHandover(
        db: b,
        deviceId: 'device-b',
        householdId: householdId,
        invitation: host.invitation,
        into: mine,
      );

      // The row arrived, and so did its picture — which is the half that
      // was missing until now, because what the row stores is a path into
      // the *other* machine's folder.
      expect(result.received, 1);
      expect(result.photos, 1);

      final row = (await b.inventoryItemsForSync(householdId)).single;
      expect(p.dirname(row.photoPath!), mine.path);
      expect(await File(row.photoPath!).readAsBytes(), List.filled(256, 42));
    });

    test('a second handover does not carry the same picture twice', () async {
      final a = open();
      final b = open();
      final theirs = await folder('host');
      final mine = await folder('guest');

      final file = File(p.join(theirs.path, 'a3f2.jpg'));
      await file.writeAsBytes(Uint8List.fromList(List.filled(256, 42)));
      await a.upsertInventoryItem(
        InventoryItemsCompanion.insert(
          clientId: 'item-a',
          householdId: householdId,
          name: 'Haferflocken',
          category: 'Lebensmittel',
          quantity: 2,
          unit: 'kg',
          storageLocation: 'Keller',
          updatedAt: DateTime.utc(2026, 9, 13, 10),
          photoPath: Value(file.path),
        ),
      );

      final host = await hostOn(a);
      Future<LocalHandoverResult> run() => joinLocalHandover(
        db: b,
        deviceId: 'device-b',
        householdId: householdId,
        invitation: host.invitation,
        into: mine,
      );

      expect((await run()).photos, 1);
      // The guest now names what it holds, so the host leaves it out.
      expect((await run()).photos, 0);
    });
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
          connectTimeout: const Duration(milliseconds: 400),
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
          connectTimeout: const Duration(milliseconds: 600),
        );

        expect(result.received, 0, reason: 'it got through on the second');
      },
    );
  });
  group('a connection that was made and then did not finish', () {
    test('is not reported as a device that could not be reached', () async {
      // The report this pins: "kein Geraet gefunden, obwohl im gleichen
      // Netz". The socket opened, the exchange ran out of time, the
      // timeout was caught by the same `continue` that steps over a dead
      // address, and the loop ended in "are you both on the same
      // network?" -- pointing a household at the one thing that was
      // demonstrably fine.
      //
      // A server that accepts the connection and then says nothing has
      // exactly that shape, and is far quicker to arrange than twenty
      // megabytes of photographs.
      final silent = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => silent.close(force: true));
      silent.listen((request) {
        // Accepted, read, and deliberately never answered.
      });

      final guest = open();
      await expectLater(
        joinLocalHandover(
          db: guest,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: LocalHandoverInvitation(
            addresses: const ['127.0.0.1'],
            port: silent.port,
            householdId: householdId,
            key: FolderKey(Uint8List(32)),
          ),
          exchangeTimeout: const Duration(milliseconds: 300),
        ),
        throwsA(
          isA<LocalHandoverException>().having(
            (error) => error.reason,
            'reason',
            LocalHandoverFailure.interrupted,
          ),
        ),
      );
    });

    test('while nothing listening at all still is', () async {
      // The other half of the distinction, so that widening the first one
      // has not swallowed the case it was carved out of.
      final guest = open();
      await expectLater(
        joinLocalHandover(
          db: guest,
          deviceId: 'device-b',
          householdId: householdId,
          invitation: LocalHandoverInvitation(
            // Reserved for documentation, so nothing answers here.
            addresses: const ['192.0.2.1'],
            port: 9,
            householdId: householdId,
            key: FolderKey(Uint8List(32)),
          ),
          connectTimeout: const Duration(milliseconds: 300),
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

  group('how long an exchange may take', () {
    test('grows with the body rather than staying at eight seconds', () {
      // The ceiling that caused this. A body of rows is small and gets
      // the floor; a body carrying the photo budget needs minutes, and
      // eight seconds is about what the upload alone costs.
      final rows = exchangeTimeoutFor(200 * 1024);
      final withPhotos = exchangeTimeoutFor(localHandoverMaxRequestBytes);

      expect(rows.inSeconds, greaterThanOrEqualTo(30));
      expect(withPhotos, greaterThan(rows));
      expect(
        withPhotos.inSeconds,
        greaterThan(60),
        reason: 'thirty megabytes cannot cross in under a minute',
      );
    });

    test('and never drops below the far side own work', () {
      // An empty body still has a household to decrypt, rows to apply and
      // pictures to write before it can answer.
      expect(exchangeTimeoutFor(0).inSeconds, greaterThanOrEqualTo(30));
    });
  });
}

/// A well-formed key that is not the host's.
const base64FolderKeyOfZeroes = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
