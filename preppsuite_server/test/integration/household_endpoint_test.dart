import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Household endpoint', (sessionBuilder, endpoints) {
    Future<String> createAuthUser() async {
      final user = await const AuthUsers().create(sessionBuilder.build());
      return user.id.toString();
    }

    test(
      'when creating a household then the caller becomes its owner',
      () async {
        final ownerSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );

        final household = await endpoints.household.createHousehold(
          ownerSession,
          name: 'Alice-Haushalt',
          countryCode: 'DE',
          regionKey: '08111000',
          displayName: 'Alice',
        );

        expect(household.name, 'Alice-Haushalt');
        expect(household.inviteCode, hasLength(8));

        final members = await endpoints.household.listMembers(
          ownerSession,
          household.id!,
        );
        expect(members, hasLength(1));
        expect(members.single.role, HouseholdRole.owner);
        expect(members.single.displayName, 'Alice');
      },
    );

    test(
      'when a second user joins via invite code then both are members',
      () async {
        final ownerSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );
        final memberSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );

        final household = await endpoints.household.createHousehold(
          ownerSession,
          name: 'Bob-Haushalt',
          countryCode: 'AT',
          regionKey: null,
          displayName: 'Owner',
        );

        final joined = await endpoints.household.joinHousehold(
          memberSession,
          inviteCode: household.inviteCode,
          displayName: 'Bob',
        );
        expect(joined.id, household.id);

        final members = await endpoints.household.listMembers(
          ownerSession,
          household.id!,
        );
        expect(members, hasLength(2));
        expect(
          members.map((m) => m.displayName),
          containsAll(['Owner', 'Bob']),
        );
      },
    );

    test(
      'when joining with an invalid invite code then it throws',
      () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );

        await expectLater(
          endpoints.household.joinHousehold(
            session,
            inviteCode: 'NOTREAL1',
            displayName: 'Nobody',
          ),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.reason,
              'reason',
              HouseholdExceptionReason.invalidInviteCode,
            ),
          ),
        );
      },
    );

    test(
      'when a user already has a household then creating another throws',
      () async {
        final session = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );

        await endpoints.household.createHousehold(
          session,
          name: 'Erster-Haushalt',
          countryCode: 'DE',
          regionKey: null,
          displayName: 'Erst-Nutzer',
        );

        await expectLater(
          endpoints.household.createHousehold(
            session,
            name: 'Zweiter-Haushalt',
            countryCode: 'DE',
            regionKey: null,
            displayName: 'Erst-Nutzer',
          ),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.reason,
              'reason',
              HouseholdExceptionReason.alreadyInHousehold,
            ),
          ),
        );
      },
    );

    test(
      'when a non-owner rotates the invite code then it throws',
      () async {
        final ownerSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );
        final memberSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            await createAuthUser(),
            {},
          ),
        );

        final household = await endpoints.household.createHousehold(
          ownerSession,
          name: 'Rotier-Haushalt',
          countryCode: 'DE',
          regionKey: null,
          displayName: 'Owner',
        );
        await endpoints.household.joinHousehold(
          memberSession,
          inviteCode: household.inviteCode,
          displayName: 'Member',
        );

        await expectLater(
          endpoints.household.rotateInviteCode(
            memberSession,
            household.id!,
          ),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.reason,
              'reason',
              HouseholdExceptionReason.notOwner,
            ),
          ),
        );

        final rotated = await endpoints.household.rotateInviteCode(
          ownerSession,
          household.id!,
        );
        expect(rotated.inviteCode, isNot(household.inviteCode));
      },
    );
  });
}
