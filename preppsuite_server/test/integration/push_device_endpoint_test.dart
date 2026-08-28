import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given PushDevice endpoint', (sessionBuilder, endpoints) {
    Future<TestSessionBuilder> userSession() async {
      final user = await const AuthUsers().create(sessionBuilder.build());
      return sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          user.id.toString(),
          {},
        ),
      );
    }

    Future<UuidValue> createHousehold(TestSessionBuilder session) async {
      final household = await endpoints.household.createHousehold(
        session,
        name: 'Test-Haushalt',
        countryCode: 'DE',
        regionKey: null,
        displayName: 'Tester',
      );
      return household.id!;
    }

    test(
      'when registering then the device is stored for the household',
      () async {
        final session = await userSession();
        final householdId = await createHousehold(session);

        final device = await endpoints.pushDevice.registerDevice(
          session,
          householdId,
          'token-1',
          PushPlatform.android,
        );

        expect(device.householdId, householdId);
        expect(device.token, 'token-1');
        expect(device.platform, PushPlatform.android);
      },
    );

    test(
      'when registering the same token twice then it is not duplicated',
      () async {
        // The client re-registers on every launch and FCM hands back the same
        // token until it rotates, so this is the common path, not an edge
        // case — a row per launch would mean a notification per launch.
        final session = await userSession();
        final householdId = await createHousehold(session);

        await endpoints.pushDevice.registerDevice(
          session,
          householdId,
          'token-1',
          PushPlatform.android,
        );
        await endpoints.pushDevice.registerDevice(
          session,
          householdId,
          'token-1',
          PushPlatform.android,
        );

        final stored = await PushDevice.db.find(sessionBuilder.build());
        expect(stored, hasLength(1));
      },
    );

    test(
      'when a token reappears under another household then it moves',
      () async {
        // A phone handed on, or a user who left one household and joined
        // another. Leaving the old row behind would keep delivering the
        // previous household's warnings to a device that is no longer theirs.
        final first = await userSession();
        final firstHousehold = await createHousehold(first);
        await endpoints.pushDevice.registerDevice(
          first,
          firstHousehold,
          'shared-token',
          PushPlatform.ios,
        );

        final second = await userSession();
        final secondHousehold = await createHousehold(second);
        await endpoints.pushDevice.registerDevice(
          second,
          secondHousehold,
          'shared-token',
          PushPlatform.ios,
        );

        final stored = await PushDevice.db.find(sessionBuilder.build());
        expect(stored, hasLength(1));
        expect(stored.single.householdId, secondHousehold);
      },
    );

    test('when unregistering then the device is gone', () async {
      final session = await userSession();
      final householdId = await createHousehold(session);
      await endpoints.pushDevice.registerDevice(
        session,
        householdId,
        'token-1',
        PushPlatform.android,
      );

      await endpoints.pushDevice.unregisterDevice(session, 'token-1');

      expect(await PushDevice.db.find(sessionBuilder.build()), isEmpty);
    });

    test(
      'when registering for a household one is not in then it is rejected',
      () async {
        final owner = await userSession();
        final householdId = await createHousehold(owner);
        final outsider = await userSession();

        await expectLater(
          endpoints.pushDevice.registerDevice(
            outsider,
            householdId,
            'token-1',
            PushPlatform.android,
          ),
          throwsA(isA<HouseholdException>()),
        );
      },
    );
  });
}
