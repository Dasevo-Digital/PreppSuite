import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';
import 'package:preppsuite_flutter/model/categories.dart';

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

  test(
    'an item added to a template that already exists does not arrive',
    () async {
      // Documented on purpose, because it is the reason "Hausapotheke" is a
      // list of its own instead of nine more lines under "Erste Hilfe": the
      // seeder skips a template it finds, so an item added to one that
      // shipped earlier reaches fresh installs only. If this ever starts
      // passing the other way, the comment on `builtInTemplates` needs
      // revisiting -- and so does the question of resurrecting items the
      // user deleted.
      await ChecklistSeeder(db).seed(householdId);

      final template = builtInTemplates.first;
      final item = template.items.first;
      await db.customStatement(
        "DELETE FROM checklist_items WHERE client_id = '${item.clientId}'",
      );

      await ChecklistSeeder(db).seed(householdId);

      final items = await db.watchChecklistItems(template.clientId).first;
      expect(
        items.where((row) => row.clientId == item.clientId),
        isEmpty,
        reason: 'the template was found, so its items were not revisited',
      );
    },
  );

  group('Hausapotheke', () {
    /// The medicine cabinet the BBK checklist enumerates and this app was
    /// missing: it listed thirteen entries where the app had four, and the
    /// four were equipment rather than medicines.
    late BuiltInTemplate cabinet;

    setUp(() {
      cabinet = builtInTemplates.firstWhere((t) => t.title == 'Hausapotheke');
    });

    test('carries the medicines the official list names', () {
      final titles = cabinet.items.map((i) => i.title).join(' | ');

      for (final wanted in [
        'Schmerz',
        'Erkältung',
        'Durchfall',
        'Elektrolyte',
        'Nasen',
        'desinfektion',
        'Sonnenbrand',
      ]) {
        expect(
          titles.toLowerCase(),
          contains(wanted.toLowerCase()),
          reason: '$wanted fehlt in der Hausapotheke',
        );
      }
    });

    test('does not ask again for what the first-aid kit contains', () {
      // A DIN 13157 kit holds plasters, scissors, tweezers, gloves and a
      // burn dressing, and the "Erste Hilfe" list already asks for the
      // kit. Asking for its contents a second time is how a checklist
      // loses the reader's trust.
      final titles = cabinet.items
          .map((i) => i.title)
          .join(' | ')
          .toLowerCase();

      for (final covered in [
        'pflaster',
        'schere',
        'pinzette',
        'handschuh',
        'verbandtuch',
        'fieberthermometer',
      ]) {
        expect(titles, isNot(contains(covered)));
      }
    });
  });

  group('Falschmeldungen erkennen', () {
    /// The chapter the revised BBK guide gained and the app had nothing
    /// on. The three questions are the BBK's own, and so is the threshold
    /// it puts on them.
    late BuiltInTemplate list;

    setUp(() {
      list = builtInTemplates.firstWhere(
        (t) => t.title == 'Falschmeldungen erkennen',
      );
    });

    test('asks the three official questions', () {
      final titles = list.items.map((i) => i.title).join(' | ').toLowerCase();

      expect(titles, contains('zuerst veröffentlicht'));
      expect(titles, contains('quellen genannt'));
      expect(titles, contains('zweite verlässliche quelle'));
    });

    test('carries the threshold, not just the questions', () {
      // Three checks without a rule for the answers leave the reader to
      // invent one, and the invented one is usually "two out of three".
      final titles = list.items.map((i) => i.title).join(' | ').toLowerCase();

      expect(titles, contains('ein einziges "nein"'));
    });

    test('points at the app\'s own warnings as the checkable copy', () {
      // The app already holds official warnings with their source named.
      // A list about verifying claims that does not mention what the
      // reader is holding would send them back to the group chat.
      final titles = list.items.map((i) => i.title).join(' | ');

      expect(titles, contains('PreppSuite'));
    });
  });

  group('preparation and acting are separate lists', () {
    BuiltInTemplate byId(String suffix) => builtInTemplates.firstWhere(
      (template) => template.clientId.endsWith(suffix),
    );

    test('the hazard lists are filed as preparation', () async {
      // They ask to check the backflow valve, the roof, the insurance and
      // the grit. Filed under "while it happens", the first thing somebody
      // read with the water rising was a reminder to review their policy.
      expect(byId('000000000011').kind, ChecklistKind.preparation);
      expect(byId('000000000013').kind, ChecklistKind.preparation);
    });

    test('and the acute steps have lists of their own', () async {
      expect(byId('000000000020').kind, ChecklistKind.response);
      expect(byId('000000000021').kind, ChecklistKind.response);
      expect(
        byId('000000000020').items.first.title,
        contains('Nicht in den Keller'),
      );
    });

    test('nothing stands in both', () async {
      // The same instruction with a tick box in two lists is two pieces of
      // bookkeeping, and one of them is always the stale one.
      final titles = <String, String>{};
      for (final template in builtInTemplates) {
        for (final item in template.items) {
          final earlier = titles[item.title];
          expect(
            earlier,
            isNull,
            reason:
                '"${item.title}" steht in $earlier und '
                '${template.title}',
          );
          titles[item.title] = template.title;
        }
      }
    });

    test('the moved steps are taken out of the preparation lists', () async {
      // A retired item is soft-deleted rather than skipped, so a household
      // seeded long ago loses it too -- otherwise it would sit in the old
      // list forever beside its copy in the new one.
      await ChecklistSeeder(db).seed(householdId);

      final flood = await db
          .watchChecklistItems('00000000-0000-4000-8000-000000000011')
          .first;
      expect(
        flood.map((i) => i.title),
        isNot(anyElement(contains('Keller nicht betreten'))),
      );

      final storm = await db
          .watchChecklistItems('00000000-0000-4000-8000-000000000013')
          .first;
      expect(
        storm.map((i) => i.title),
        isNot(anyElement(contains('Nach dem Sturm'))),
      );
    });
  });
}
