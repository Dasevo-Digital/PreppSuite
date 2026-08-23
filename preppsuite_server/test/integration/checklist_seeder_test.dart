import 'package:preppsuite_server/src/checklists/checklist_seeder.dart';
import 'package:preppsuite_server/src/generated/protocol.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ChecklistSeeder', (sessionBuilder, endpoints) {
    Future<void> seed() async {
      final session = sessionBuilder.build();
      try {
        await const ChecklistSeeder().seedBuiltInTemplates(session);
      } finally {
        await session.close();
      }
    }

    Future<List<ChecklistTemplate>> builtInTemplates() async {
      final session = sessionBuilder.build();
      try {
        return await ChecklistTemplate.db.find(
          session,
          where: (t) => t.isBuiltIn.equals(true),
        );
      } finally {
        await session.close();
      }
    }

    test('seeds the built-in templates, water and food among them', () async {
      await seed();

      final templates = await builtInTemplates();
      final titles = templates.map((t) => t.title).toList();

      expect(titles, containsAll(['Wasser', 'Erste Hilfe', 'Lebensmittel']));
      expect(
        templates.every((t) => t.householdId == null),
        isTrue,
        reason: 'built-ins belong to no household',
      );
    });

    test('seeds the food template with its items', () async {
      await seed();

      final templates = await builtInTemplates();
      final food = templates.firstWhere((t) => t.title == 'Lebensmittel');
      expect(food.category, ChecklistCategory.food);

      final session = sessionBuilder.build();
      try {
        final items = await ChecklistItem.db.find(
          session,
          where: (i) => i.templateId.equals(food.id!),
        );
        expect(items, isNotEmpty);
        expect(
          items.map((i) => i.sortOrder).toSet(),
          hasLength(items.length),
          reason: 'each item gets its own sort order',
        );
      } finally {
        await session.close();
      }
    });

    test('running twice does not duplicate anything', () async {
      await seed();
      final afterFirst = await builtInTemplates();

      await seed();
      final afterSecond = await builtInTemplates();

      expect(afterSecond, hasLength(afterFirst.length));
    });

    // The regression this guards: seeding used to bail out entirely once
    // any built-in existed, so a template added to the catalog later never
    // reached a server that had already been seeded.
    test('adds a missing template even though others already exist', () async {
      await seed();

      final session = sessionBuilder.build();
      try {
        final food = await ChecklistTemplate.db.findFirstRow(
          session,
          where: (t) => t.title.equals('Lebensmittel'),
        );
        await ChecklistItem.db.deleteWhere(
          session,
          where: (i) => i.templateId.equals(food!.id!),
        );
        await ChecklistTemplate.db.deleteRow(session, food!);
      } finally {
        await session.close();
      }

      expect(
        (await builtInTemplates()).map((t) => t.title),
        isNot(contains('Lebensmittel')),
      );

      await seed();

      expect(
        (await builtInTemplates()).map((t) => t.title),
        contains('Lebensmittel'),
      );
    });
  }, rollbackDatabase: RollbackDatabase.afterEach);
}
