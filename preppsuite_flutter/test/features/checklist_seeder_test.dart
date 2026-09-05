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
