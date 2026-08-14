import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Inventory endpoint', (sessionBuilder, endpoints) {
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

    InventoryItem draftItem(
      UuidValue householdId, {
      UuidValue? id,
      required UuidValue clientId,
      String name = 'Trinkwasser 6x1.5L',
      double quantity = 6,
      DateTime? updatedAt,
      DateTime? deletedAt,
    }) {
      return InventoryItem(
        id: id,
        householdId: householdId,
        clientId: clientId,
        name: name,
        category: InventoryItemCategory.water,
        quantity: quantity,
        unit: 'Flasche',
        storageLocation: 'Keller',
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        deletedAt: deletedAt,
      );
    }

    test(
      'when pushing a new item without a server id then it is inserted and '
      'assigned one',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);
        final clientId = const Uuid().v4obj();

        final result = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [draftItem(householdId, clientId: clientId)],
        );

        expect(result, hasLength(1));
        expect(result.single.id, isNotNull);
        expect(result.single.clientId, clientId);
        expect(result.single.name, 'Trinkwasser 6x1.5L');
      },
    );

    test(
      'when pushing the same clientId twice then it upserts instead of '
      'duplicating',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);
        final clientId = const Uuid().v4obj();

        final first = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [draftItem(householdId, clientId: clientId)],
        );

        final second = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [
            draftItem(
              householdId,
              clientId: clientId,
              quantity: 12,
              updatedAt: first.single.updatedAt.add(
                const Duration(seconds: 1),
              ),
            ),
          ],
        );

        expect(second.single.id, first.single.id);
        expect(second.single.quantity, 12);

        final all = await endpoints.inventory.pullInventoryChanges(
          session,
          householdId,
          DateTime.utc(2000),
        );
        expect(all, hasLength(1));
      },
    );

    test(
      'when an older edit is pushed after a newer one then it is dropped '
      '(last-write-wins)',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);
        final clientId = const Uuid().v4obj();

        final created = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [draftItem(householdId, clientId: clientId, quantity: 1)],
        );
        final serverId = created.single.id;
        final serverUpdatedAt = created.single.updatedAt;

        // A stale edit, timestamped before the row was created server-side.
        final staleResult = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [
            draftItem(
              householdId,
              id: serverId,
              clientId: clientId,
              quantity: 999,
              updatedAt: serverUpdatedAt.subtract(const Duration(minutes: 1)),
            ),
          ],
        );

        expect(staleResult.single.quantity, 1);
      },
    );

    test(
      'when pulling since a timestamp then only later changes are returned, '
      'including tombstones',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);

        final before = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [draftItem(householdId, clientId: const Uuid().v4obj())],
        );
        final cursor = before.single.updatedAt.add(
          const Duration(milliseconds: 1),
        );
        await Future<void>.delayed(const Duration(milliseconds: 5));

        final afterCreate = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [draftItem(householdId, clientId: const Uuid().v4obj())],
        );

        final deleted = await endpoints.inventory.pushInventoryChanges(
          session,
          householdId,
          [
            draftItem(
              householdId,
              id: afterCreate.single.id,
              clientId: afterCreate.single.clientId,
              updatedAt: afterCreate.single.updatedAt.add(
                const Duration(milliseconds: 1),
              ),
              deletedAt: DateTime.now().toUtc(),
            ),
          ],
        );

        final pulled = await endpoints.inventory.pullInventoryChanges(
          session,
          householdId,
          cursor,
        );

        expect(pulled, hasLength(1));
        expect(pulled.single.id, deleted.single.id);
        expect(pulled.single.deletedAt, isNotNull);
      },
    );

    test(
      'when a non-member pulls or pushes then it throws',
      () async {
        final ownerSession = await memberSession();
        final householdId = await createHousehold(ownerSession);
        final outsiderSession = await memberSession();

        await expectLater(
          endpoints.inventory.pullInventoryChanges(
            outsiderSession,
            householdId,
            DateTime.utc(2000),
          ),
          throwsA(isA<HouseholdException>()),
        );

        await expectLater(
          endpoints.inventory.pushInventoryChanges(
            outsiderSession,
            householdId,
            [draftItem(householdId, clientId: const Uuid().v4obj())],
          ),
          throwsA(isA<HouseholdException>()),
        );
      },
    );
  });
}
