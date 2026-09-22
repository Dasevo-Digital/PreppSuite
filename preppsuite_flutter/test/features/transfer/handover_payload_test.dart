import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/sharing/application/carried_settings.dart';
import 'package:preppsuite_flutter/features/sharing/application/device_snapshot.dart';
import 'package:preppsuite_flutter/features/sharing/application/folder_crypto.dart';
import 'package:preppsuite_flutter/features/transfer/application/handover_payload.dart';
import 'package:preppsuite_flutter/features/transfer/application/handover_photos.dart';
import 'package:preppsuite_flutter/model/household_profile.dart';

/// What crosses the wire in a local handover, and why it is shaped that way.
void main() {
  final snapshot = DeviceSnapshot(
    deviceId: 'device-a',
    householdId: 'home',
    writtenAt: DateTime.utc(2026, 9, 20),
    inventoryItems: [
      {'clientId': 'beans', 'name': 'Bohnen'},
    ],
  );

  final full = HandoverPayload(
    snapshot: snapshot,
    household: const CarriedHousehold(
      profile: HouseholdProfile(
        id: 'home',
        name: 'Zuhause',
        countryCode: 'DE',
        personCount: 3,
      ),
      settings: {'pegelStation': 'DRESDEN'},
    ),
    photos: [
      HandoverPhoto(
        owner: PhotoOwner.possession,
        clientId: 'radio',
        name: 'a3f2.jpg',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      ),
    ],
    knownPhotos: {'b7c1.jpg'},
  );

  test('an older app reads it as the plain snapshot it also is', () {
    // The whole reason this is a superset of the snapshot rather than a
    // wrapper around it. A wrapper would make the first handover between
    // an old and a new install fail as "different household", which is
    // both wrong and frightening.
    final asOldAppSeesIt = DeviceSnapshot.decode(full.encode());

    expect(asOldAppSeesIt, isNotNull);
    expect(asOldAppSeesIt!.householdId, 'home');
    expect(asOldAppSeesIt.inventoryItems.single['clientId'], 'beans');
  });

  test('a newer app reads everything that rides along', () {
    final there = HandoverPayload.decode(full.encode())!;

    expect(there.snapshot.householdId, 'home');
    expect(there.household.profile?.personCount, 3);
    expect(there.household.settings, {'pegelStation': 'DRESDEN'});
    expect(there.photos.single.name, 'a3f2.jpg');
    expect(there.photos.single.owner, PhotoOwner.possession);
    expect(there.photos.single.bytes, [1, 2, 3, 4]);
    expect(there.knownPhotos, {'b7c1.jpg'});
  });

  test('a body from an older app comes back with the extras empty', () {
    // The other direction of the same compatibility: the keys are simply
    // not there, which is not an error but a description of that device.
    final there = HandoverPayload.decode(snapshot.encode())!;

    expect(there.snapshot.inventoryItems, hasLength(1));
    expect(there.household.isEmpty, isTrue);
    expect(there.photos, isEmpty);
    expect(there.knownPhotos, isEmpty);
  });

  test('without a readable snapshot there is nothing to do', () {
    expect(HandoverPayload.decode('not json at all'), isNull);
    expect(HandoverPayload.decode(jsonEncode({'settings': {}})), isNull);
  });

  test('a photo that does not decode costs that photo alone', () {
    final damaged = jsonDecode(full.encode()) as Map<String, Object?>;
    damaged['photos'] = [
      {
        'owner': 'inventory',
        'clientId': 'x',
        'name': '../out.jpg',
        'bytes': '',
      },
      (damaged['photos']! as List).first,
    ];

    final there = HandoverPayload.decode(jsonEncode(damaged))!;

    expect(there.photos, hasLength(1));
    expect(there.photos.single.name, 'a3f2.jpg');
    expect(there.snapshot.inventoryItems, hasLength(1));
  });

  group('sealing it away from the screen', () {
    // Encoding and encrypting a household with photographs is seconds of
    // work that cannot be interrupted, so it happens on an isolate. That
    // only works if everything in the payload can be sent to one -- which
    // is a runtime property, not something the compiler checks.
    final key = FolderKey(Uint8List.fromList(List.filled(32, 7)));

    test('a payload with a picture in it survives the round trip', () async {
      final there = (await HandoverPayload.unseal(
        await full.seal(key),
        key,
      )).payload!;

      expect(there.snapshot.householdId, 'home');
      expect(there.household.profile?.name, 'Zuhause');
      expect(there.photos.single.bytes, [1, 2, 3, 4]);
      expect(there.knownPhotos, {'b7c1.jpg'});
    });

    test('a body that will not open is told from one that opens wrong', () {
      // The host answers these differently: the first never saw the
      // screen, the second did and belongs to another household.
      final other = FolderKey(Uint8List.fromList(List.filled(32, 9)));

      return expectLater(
        full.seal(key).then((body) => HandoverPayload.unseal(body, other)),
        completion((opened: false, payload: null)),
      );
    });

    test('something that is not an envelope at all does not open', () async {
      expect(
        (await HandoverPayload.unseal('nicht einmal JSON', key)).opened,
        isFalse,
      );
    });
  });
}
