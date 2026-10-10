import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_template_l10n.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates_en.dart';
import 'package:preppsuite_flutter/features/checklists/application/built_in_templates_es.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_controller.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_providers.dart';
import 'package:preppsuite_flutter/features/checklists/application/checklist_seeder.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// The built-in lists in English and Spanish (#108).
///
/// Two promises: every shipped German text has a translation, carrying
/// the same numbers -- an emergency number or a paragraph of the StVZO
/// that goes missing in translation is the worst kind of mistake here,
/// because nobody reading the translation can see it -- and a row is only
/// ever translated on the screen, never in the database, and only while
/// it still says what was shipped.
void main() {
  /// Every shipped German text, by clientId.
  final german = {
    for (final template in builtInTemplates) ...{
      template.clientId: template.title,
      for (final item in template.items) item.clientId: item.title,
    },
  };

  const translations = {'en': builtInChecklistsEn, 'es': builtInChecklistsEs};

  /// The numbers in [text], in order, with "3,5" and "3.5" alike.
  List<String> numbers(String text) =>
      RegExp(r'\d+').allMatches(text).map((m) => m[0]!).toList();

  for (final MapEntry(key: language, value: translated)
      in translations.entries) {
    group(language, () {
      test('every built-in list and entry has a translation', () {
        expect(
          german.keys.toSet().difference(translated.keys.toSet()),
          isEmpty,
        );
      });

      test('and nothing is translated that is not shipped', () {
        expect(
          translated.keys.toSet().difference(german.keys.toSet()),
          isEmpty,
        );
      });

      test('no translation is empty or left in German', () {
        for (final MapEntry(:key, :value) in translated.entries) {
          expect(value.trim(), isNotEmpty, reason: key);
          // A list name may be the same word in both languages
          // ("Hygiene"); an entry of several words never is.
          if (german[key]!.contains(' ')) {
            expect(value, isNot(german[key]), reason: key);
          }
        }
      });

      test('every number survives the translation, in order', () {
        for (final MapEntry(:key, :value) in german.entries) {
          expect(numbers(translated[key]!), numbers(value), reason: value);
        }
      });
    });
  }

  group('what the screen shows', () {
    final template = builtInTemplates.first;
    final item = template.items.first;

    test("a shipped row is shown in the reader's language", () {
      expect(
        builtInChecklistText(template.clientId, template.title, 'es'),
        builtInChecklistsEs[template.clientId],
      );
      expect(
        builtInChecklistText(item.clientId, item.title, 'en'),
        builtInChecklistsEn[item.clientId],
      );
    });

    test('German, and a language nobody translated, see the row', () {
      expect(builtInChecklistText(item.clientId, item.title, 'de'), item.title);
      expect(builtInChecklistText(item.clientId, item.title, 'fr'), item.title);
    });

    test('a row the household changed is shown as it stands', () {
      // Also the row seeded long ago with an older wording: it is not
      // the text the translation was made from, so it is not replaced.
      expect(
        builtInChecklistText(item.clientId, 'Unser Kanister im Keller', 'es'),
        'Unser Kanister im Keller',
      );
    });

    test("a list of the household's own is never translated", () {
      expect(
        builtInChecklistText('own-list', template.title, 'es'),
        template.title,
      );
    });
  });

  group('in the database', () {
    const householdId = 'household-1';
    late AppDatabase db;
    late ProviderContainer container;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      await ChecklistSeeder(db).seed(householdId);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    Future<ChecklistTemplate> water() async =>
        (await db.watchChecklistTemplates(householdId).first).firstWhere(
          (t) => t.clientId == builtInTemplates.first.clientId,
        );

    test('the seeded rows stay German, whatever the reader reads', () async {
      final list = await water();

      expect(list.title, builtInTemplates.first.title);
      expect(list.titleIn('es'), builtInChecklistsEs[list.clientId]);
    });

    test('a copy is made in the words the reader saw', () async {
      // The copy is the household's own list from then on, and its own
      // lists are never translated -- so it has to start out in the
      // language it was copied in, not in German.
      final list = await water();

      await container
          .read(checklistControllerProvider(householdId))
          .duplicateTemplate(list, languageCode: 'es');

      final copy =
          (await db
                  .watchChecklistTemplates(
                    householdId,
                  )
                  .first)
              .firstWhere((t) => !t.isBuiltIn);
      expect(copy.title, builtInChecklistsEs[list.clientId]);
      final items = await db.watchChecklistItems(copy.clientId).first;
      expect(items.map((i) => i.title).toSet(), {
        for (final item in builtInTemplates.first.items)
          builtInChecklistsEs[item.clientId],
      });
    });
  });
}
