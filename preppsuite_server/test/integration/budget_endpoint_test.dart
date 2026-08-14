import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Budget endpoint', (sessionBuilder, endpoints) {
    Future<TestSessionBuilder> memberSession() async {
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

    BudgetEntry draftEntry(
      UuidValue householdId, {
      UuidValue? id,
      required UuidValue clientId,
      int amountCents = 1999,
      DateTime? updatedAt,
      DateTime? deletedAt,
    }) {
      return BudgetEntry(
        id: id,
        householdId: householdId,
        clientId: clientId,
        label: 'Wasserkanister',
        amountCents: amountCents,
        currency: 'EUR',
        category: InventoryItemCategory.water,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        deletedAt: deletedAt,
      );
    }

    test(
      'when pushing a new entry without a server id then it is inserted',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);

        final result = await endpoints.budget.pushBudgetChanges(
          session,
          householdId,
          [draftEntry(householdId, clientId: const Uuid().v4obj())],
        );

        expect(result.single.id, isNotNull);
        expect(result.single.amountCents, 1999);
      },
    );

    test(
      'when pushing the same clientId twice then it upserts',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);
        final clientId = const Uuid().v4obj();

        final first = await endpoints.budget.pushBudgetChanges(
          session,
          householdId,
          [draftEntry(householdId, clientId: clientId)],
        );
        final second = await endpoints.budget.pushBudgetChanges(
          session,
          householdId,
          [
            draftEntry(
              householdId,
              clientId: clientId,
              amountCents: 2499,
              updatedAt: first.single.updatedAt.add(const Duration(seconds: 1)),
            ),
          ],
        );

        expect(second.single.id, first.single.id);
        expect(second.single.amountCents, 2499);

        final all = await endpoints.budget.pullBudgetChanges(
          session,
          householdId,
          DateTime.utc(2000),
        );
        expect(all, hasLength(1));
      },
    );

    test(
      'when a non-member pulls or pushes then it throws',
      () async {
        final ownerSession = await memberSession();
        final householdId = await createHousehold(ownerSession);
        final outsiderSession = await memberSession();

        await expectLater(
          endpoints.budget.pullBudgetChanges(
            outsiderSession,
            householdId,
            DateTime.utc(2000),
          ),
          throwsA(isA<HouseholdException>()),
        );

        await expectLater(
          endpoints.budget.pushBudgetChanges(
            outsiderSession,
            householdId,
            [draftEntry(householdId, clientId: const Uuid().v4obj())],
          ),
          throwsA(isA<HouseholdException>()),
        );
      },
    );
  });
}
