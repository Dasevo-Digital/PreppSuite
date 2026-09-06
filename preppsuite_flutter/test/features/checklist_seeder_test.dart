import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  const householdId = 'household-1';

  test('writes every built-in template', () async {
    await ChecklistSeeder(db).seed(householdId);

    final templates = await db.watchChecklistTemplates(householdId).first;
    expect(templates, hasLength(builtInTemplates.length));
    expect(templates.every((t) => t.isBuiltIn), isTrue);
  });

  test('seeding twice does not duplicate anything', () async {
    // It runs on every launch rather than behind a "has this been seeded"
    // flag, which could go stale — so being idempotent is what makes that
    // safe.
    await ChecklistSeeder(db).seed(householdId);
    await ChecklistSeeder(db).seed(householdId);

    final templates = await db.watchChecklistTemplates(householdId).first;
    expect(templates, hasLength(builtInTemplates.length));
  });

  test('items are attached to their template in order', () async {
    await ChecklistSeeder(db).seed(householdId);

    final first = builtInTemplates.first;
    final items = await db.watchChecklistItems(first.clientId).first;

    expect(items.map((i) => i.title), first.items.map((i) => i.title));
  });

  test('every template and item has an id of its own', () async {
    // The ids are what make seeding idempotent, so a copy-paste that
    // repeats one would silently merge two lists into one — and the
    // symptom would be a missing checklist, not an error.
    final templateIds = builtInTemplates.map((t) => t.clientId).toList();
    expect(templateIds.toSet(), hasLength(templateIds.length));

    final itemIds = [
      for (final template in builtInTemplates)
        for (final item in template.items) item.clientId,
    ];
    expect(itemIds.toSet(), hasLength(itemIds.length));
    expect(templateIds.toSet().intersection(itemIds.toSet()), isEmpty);
  });

  test('no template is empty and every title says something', () async {
    for (final template in builtInTemplates) {
      expect(template.items, isNotEmpty, reason: template.title);
      expect(template.title.trim(), isNotEmpty);
      for (final item in template.items) {
        expect(item.title.trim(), isNotEmpty, reason: template.title);
      }
    }
  });

  test('a list added later reaches an install seeded long ago', () async {
    // What lets the built-in set grow: a template this install has never
    // seen appears on the next launch, and the ones it already has keep
    // whatever was ticked off in them.
    await ChecklistSeeder(db).seed(householdId);

    final missing = builtInTemplates.last;
    final kept = builtInTemplates.first;

    // Hard-deleted rather than tombstoned: a tombstone means "the user
    // threw this away", and re-seeding over that would be a bug of its
    // own. This stands in for a version that never had the template.
    await db.customStatement(
      "DELETE FROM checklist_templates WHERE client_id = '${missing.clientId}'",
    );
    await db.customStatement(
      "DELETE FROM checklist_items WHERE template_client_id = "
      "'${missing.clientId}'",
    );

    final tickable = (await db.watchChecklistItems(kept.clientId).first).first;
    await db.upsertChecklistItem(
      tickable.copyWith(isChecked: true).toCompanion(true),
    );

    await ChecklistSeeder(db).seed(householdId);

    final templates = await db.watchChecklistTemplates(householdId).first;
    expect(templates, hasLength(builtInTemplates.length));
    expect(
      (await db.watchChecklistItems(missing.clientId).first),
      hasLength(missing.items.length),
    );
    expect(
      (await db.watchChecklistItems(kept.clientId).first).first.isChecked,
      isTrue,
      reason: 'seeding again must not un-tick what was already done',
    );
  });

  test('a user-edited template is not overwritten by a later seed', () async {
    // Someone who ticks items off or renames a template must not lose that
    // on the next launch.
    await ChecklistSeeder(db).seed(householdId);
    final template =
        (await db.watchChecklistTemplates(householdId).first).first;

    await db.upsertChecklistTemplate(
      template.copyWith(title: 'Mein eigener Titel').toCompanion(true),
    );
    await ChecklistSeeder(db).seed(householdId);

    final after = await db.checklistTemplateByClientId(template.clientId);
    expect(after!.title, 'Mein eigener Titel');
  });
}
