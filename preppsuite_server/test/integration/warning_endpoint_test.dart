import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Warning endpoint', (sessionBuilder, endpoints) {
    Future<TestSessionBuilder> memberSession() async {
      final user = await const AuthUsers().create(sessionBuilder.build());
      return sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          user.id.toString(),
          {},
        ),
      );
    }

    Future<UuidValue> createHousehold(
      TestSessionBuilder session, {
      required String countryCode,
      String? regionKey,
    }) async {
      final household = await endpoints.household.createHousehold(
        session,
        name: 'Test-Haushalt',
        countryCode: countryCode,
        regionKey: regionKey,
        displayName: 'Tester',
      );
      return household.id!;
    }

    Future<void> insertWarning(
      Session dbSession, {
      required String externalId,
      required String countryCode,
      String? regionKey,
    }) async {
      await Warning.db.insertRow(
        dbSession,
        Warning(
          source: WarningSource.bbk,
          externalId: externalId,
          countryCode: countryCode,
          regionKey: regionKey,
          severity: WarningSeverity.moderate,
          eventType: 'Test event',
          headline: 'Test warning',
          effective: DateTime.now().toUtc(),
          sent: DateTime.now().toUtc(),
          rawPayload: '{}',
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }

    test(
      "when pulling then only the household's own country warnings are "
      'returned',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session, countryCode: 'DE');

        await insertWarning(
          sessionBuilder.build(),
          externalId: 'de-1',
          countryCode: 'DE',
        );
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'at-1',
          countryCode: 'AT',
        );

        final pulled = await endpoints.warning.pullWarnings(
          session,
          householdId,
          DateTime.utc(2000),
        );

        expect(pulled.map((w) => w.externalId), ['de-1']);
      },
    );

    test('when a non-member pulls then it throws', () async {
      final ownerSession = await memberSession();
      final householdId = await createHousehold(
        ownerSession,
        countryCode: 'DE',
      );
      final outsiderSession = await memberSession();

      await expectLater(
        endpoints.warning.pullWarnings(
          outsiderSession,
          householdId,
          DateTime.utc(2000),
        ),
        throwsA(isA<HouseholdException>()),
      );
    });

    test(
      'when pulling since a timestamp then only later warnings are returned',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session, countryCode: 'DE');

        await insertWarning(
          sessionBuilder.build(),
          externalId: 'old',
          countryCode: 'DE',
        );
        final cursor = DateTime.now().toUtc().add(const Duration(seconds: 1));
        await Future<void>.delayed(const Duration(seconds: 1));
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'new',
          countryCode: 'DE',
        );

        final pulled = await endpoints.warning.pullWarnings(
          session,
          householdId,
          cursor,
        );

        expect(pulled.map((w) => w.externalId), ['new']);
      },
    );

    test(
      "when a household has a region set then only warnings in its own "
      'Kreis/state or an added subscription are returned',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(
          session,
          countryCode: 'DE',
          regionKey: '053340000000', // Städteregion Aachen (NW)
        );
        await endpoints.household.addWarningRegion(
          session,
          householdId,
          kind: WarningRegionKind.bundesland,
          value: 'BY',
          label: 'Bayern',
        );

        await insertWarning(
          sessionBuilder.build(),
          externalId: 'own-kreis',
          countryCode: 'DE',
          regionKey: '05334',
        );
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'own-state',
          countryCode: 'DE',
          regionKey: 'NW',
        );
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'subscribed-state',
          countryCode: 'DE',
          regionKey: 'BY',
        );
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'unrelated-state',
          countryCode: 'DE',
          regionKey: 'SN',
        );
        await insertWarning(
          sessionBuilder.build(),
          externalId: 'nationwide',
          countryCode: 'DE',
          regionKey: null,
        );

        final pulled = await endpoints.warning.pullWarnings(
          session,
          householdId,
          DateTime.utc(2000),
        );

        expect(
          pulled.map((w) => w.externalId).toSet(),
          {'own-kreis', 'own-state', 'subscribed-state', 'nationwide'},
        );
      },
    );
  });
}
