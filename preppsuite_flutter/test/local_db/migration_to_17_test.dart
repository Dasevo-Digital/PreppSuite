import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

/// Schema 17 gives a checklist a second axis: having things ready, or
/// acting while something happens.
///
/// The column is the easy half. The hard half is the households that were
/// seeded long ago: the seeder steps over a template it already finds, so
/// nothing in the upgrade knows which of their built-in lists are really
/// response lists. That answer lives in `built_in_templates.dart` and
/// reaches them on the next launch — which is what most of this file is
/// about.
void main() {
  NativeDatabase schemaSixteenDatabase() {
    return NativeDatabase.memory(
      setup: (raw) {
        raw.execute(
          'CREATE TABLE "checklist_templates" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NULL, '
          '"title" TEXT NOT NULL, "category" TEXT NOT NULL, '
          '"is_built_in" INTEGER NOT NULL DEFAULT 0 '
          'CHECK ("is_built_in" IN (0, 1)), '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );
        raw.execute(
          'CREATE TABLE "checklist_items" ('
          '"client_id" TEXT NOT NULL, "household_id" TEXT NULL, '
          '"template_client_id" TEXT NOT NULL, "title" TEXT NOT NULL, '
          '"is_checked" INTEGER NOT NULL DEFAULT 0 '
          'CHECK ("is_checked" IN (0, 1)), '
          '"target_quantity" REAL NULL, "inventory_client_id" TEXT NULL, '
          '"sort_order" INTEGER NOT NULL DEFAULT 0, '
          '"updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, '
          '"dirty" INTEGER NOT NULL DEFAULT 1 CHECK ("dirty" IN (0, 1)), '
          'PRIMARY KEY ("client_id"))',
        );

        void put(String id, String title, String category, bool builtIn) {
          raw.execute(
            'INSERT INTO checklist_templates (client_id, household_id, '
            'title, category, is_built_in, updated_at, dirty) VALUES '
            "('$id', 'household-1', '$title', '$category', "
            '${builtIn ? 1 : 0}, 1767225600, 0)',
          );
        }

        // Two built-ins that the current declaration files differently,
        // and one list the household wrote itself.
        put(
          '00000000-0000-4000-8000-000000000001',
          'Wasser',
          'water',
          true,
        );
        put(
          '00000000-0000-4000-8000-000000000014',
          'Schutz suchen',
          'safety',
          true,
        );
        put('own-1', 'Gartenhaus', 'custom', false);

        raw.execute('PRAGMA user_version = 16');
      },
    );
  }

  Future<Map<String, String>> kindById(AppDatabase db) async {
    final templates = await db.watchChecklistTemplates('household-1').first;
    return {for (final t in templates) t.clientId: t.kind};
  }

  test('the upgrade adds the column and keeps every row', () async {
    final db = AppDatabase.forTesting(schemaSixteenDatabase());
    addTearDown(db.close);

    final kinds = await kindById(db);

    expect(kinds, hasLength(3));
    // Nothing here guesses. The upgrade knows the shape and not the
    // meaning, so everything arrives as preparation.
    expect(kinds.values, everyElement('preparation'));
  });

  test(
    'the next seeding files the built-in lists by the declaration',
    () async {
      final db = AppDatabase.forTesting(schemaSixteenDatabase());
      addTearDown(db.close);

      await ChecklistSeeder(db).seed('household-1');
      final kinds = await kindById(db);

      expect(kinds['00000000-0000-4000-8000-000000000001'], 'preparation');
      expect(kinds['00000000-0000-4000-8000-000000000014'], 'response');
      // Not the app's to decide: nobody was asked when this one was made,
      // and preparation is where the column default put it.
      expect(kinds['own-1'], 'preparation');
    },
  );

  test('and it does not touch anything else about them', () async {
    // The filing must never travel as an edit. A device that ticked half
    // a list off last month has the newer row, and a merge that handed it
    // this one would faithfully un-tick it.
    final db = AppDatabase.forTesting(schemaSixteenDatabase());
    addTearDown(db.close);

    final before = await db.watchChecklistTemplates('household-1').first;
    await ChecklistSeeder(db).seed('household-1');
    final after = {
      for (final t in await db.watchChecklistTemplates('household-1').first)
        t.clientId: t,
    };

    for (final template in before) {
      final now = after[template.clientId]!;
      expect(now.updatedAt, template.updatedAt, reason: template.clientId);
      expect(now.dirty, template.dirty, reason: template.clientId);
      expect(now.title, template.title, reason: template.clientId);
    }
  });

  test('seeding twice changes nothing the second time', () async {
    final db = AppDatabase.forTesting(schemaSixteenDatabase());
    addTearDown(db.close);

    await ChecklistSeeder(db).seed('household-1');
    final once = await kindById(db);
    await ChecklistSeeder(db).seed('household-1');

    expect(await kindById(db), once);
  });

  test('a fresh install seeds the same answer', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await ChecklistSeeder(db).seed('household-1');
    final kinds = await kindById(db);

    for (final template in builtInTemplates) {
      expect(
        kinds[template.clientId],
        template.kind.name,
        reason: template.title,
      );
    }
  });

  test('both kinds are actually used by the built-in set', () async {
    // A split with nothing on one side of it is a tab that never fills.
    final kinds = builtInTemplates.map((t) => t.kind).toSet();
    expect(kinds, ChecklistKind.values.toSet());
  });
}
