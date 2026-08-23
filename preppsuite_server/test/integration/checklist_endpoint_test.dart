import 'package:preppsuite_server/src/checklists/checklist_seeder.dart';
import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Checklist endpoint', (sessionBuilder, endpoints) {
    // withServerpod's test harness doesn't run server.dart's run(), so the
    // startup seed never fires here — seed explicitly, once per group.
    setUpAll(() async {
      final session = sessionBuilder.build();
      try {
        await const ChecklistSeeder().seedBuiltInTemplates(session);
      } finally {
        await session.close();
      }
    });

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

    ChecklistTemplate draftTemplate(
      UuidValue? householdId, {
      UuidValue? id,
      required UuidValue clientId,
      String title = 'Eigene Checkliste',
      DateTime? updatedAt,
      DateTime? deletedAt,
    }) {
      return ChecklistTemplate(
        id: id,
        householdId: householdId,
        clientId: clientId,
        title: title,
        category: ChecklistCategory.custom,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        deletedAt: deletedAt,
      );
    }

    ChecklistItem draftItem(
      UuidValue householdId, {
      required UuidValue templateId,
      UuidValue? id,
      required UuidValue clientId,
      String title = 'Taschenlampe',
      DateTime? updatedAt,
      DateTime? deletedAt,
    }) {
      return ChecklistItem(
        id: id,
        householdId: householdId,
        clientId: clientId,
        templateId: templateId,
        title: title,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
        deletedAt: deletedAt,
      );
    }

    test(
      'when pulling templates then built-in ones are included alongside '
      "the household's own",
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);

        await endpoints.checklist.pushChecklistTemplateChanges(
          session,
          householdId,
          [draftTemplate(householdId, clientId: const Uuid().v4obj())],
        );

        final pulled = await endpoints.checklist.pullChecklistTemplateChanges(
          session,
          householdId,
          DateTime.utc(2000),
        );

        expect(pulled.any((t) => t.isBuiltIn), isTrue);
        expect(pulled.any((t) => t.householdId == householdId), isTrue);
      },
    );

    test(
      'when pushing a template twice with the same clientId then it upserts',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);
        final clientId = const Uuid().v4obj();

        final first = await endpoints.checklist.pushChecklistTemplateChanges(
          session,
          householdId,
          [draftTemplate(householdId, clientId: clientId)],
        );
        final second = await endpoints.checklist.pushChecklistTemplateChanges(
          session,
          householdId,
          [
            draftTemplate(
              householdId,
              clientId: clientId,
              title: 'Umbenannt',
              updatedAt: first.single.updatedAt.add(
                const Duration(seconds: 1),
              ),
            ),
          ],
        );

        expect(second.single.id, first.single.id);
        expect(second.single.title, 'Umbenannt');
      },
    );

    test(
      'when a member creates an item under their own template then it '
      'succeeds',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);

        final template = await endpoints.checklist.pushChecklistTemplateChanges(
          session,
          householdId,
          [
            draftTemplate(householdId, clientId: const Uuid().v4obj()),
          ],
        );

        final items = await endpoints.checklist.pushChecklistItemChanges(
          session,
          householdId,
          [
            draftItem(
              householdId,
              templateId: template.single.id!,
              clientId: const Uuid().v4obj(),
            ),
          ],
        );

        expect(items.single.title, 'Taschenlampe');
        expect(items.single.templateId, template.single.id);
      },
    );

    test(
      'when a member adds an item under a built-in template then it '
      'succeeds (shared template, household-owned item)',
      () async {
        final session = await memberSession();
        final householdId = await createHousehold(session);

        final builtIns = await endpoints.checklist.pullChecklistTemplateChanges(
          session,
          householdId,
          DateTime.utc(2000),
        );
        final builtInTemplate = builtIns.firstWhere((t) => t.isBuiltIn);

        final items = await endpoints.checklist.pushChecklistItemChanges(
          session,
          householdId,
          [
            draftItem(
              householdId,
              templateId: builtInTemplate.id!,
              clientId: const Uuid().v4obj(),
              title: 'Zusätzliches Item',
            ),
          ],
        );

        expect(items.single.templateId, builtInTemplate.id);
      },
    );

    test(
      'when an item references a template belonging to another household '
      'then it throws',
      () async {
        final ownerSession = await memberSession();
        final ownerHouseholdId = await createHousehold(ownerSession);
        final template = await endpoints.checklist.pushChecklistTemplateChanges(
          ownerSession,
          ownerHouseholdId,
          [
            draftTemplate(ownerHouseholdId, clientId: const Uuid().v4obj()),
          ],
        );

        final outsiderSession = await memberSession();
        final outsiderHouseholdId = await createHousehold(outsiderSession);

        await expectLater(
          endpoints.checklist.pushChecklistItemChanges(
            outsiderSession,
            outsiderHouseholdId,
            [
              draftItem(
                outsiderHouseholdId,
                templateId: template.single.id!,
                clientId: const Uuid().v4obj(),
              ),
            ],
          ),
          throwsA(isA<HouseholdException>()),
        );
      },
    );
  }, rollbackDatabase: RollbackDatabase.afterAll);
}
