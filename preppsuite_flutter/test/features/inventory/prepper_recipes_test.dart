import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/prepper_recipes.dart';

/// The recipes are prose in two lists, and a compiler cannot check prose.
///
/// It can be held to two things: that the lists still describe the same
/// dishes, and that when they one day stop doing so, the one that is
/// missing is *shown* rather than quietly dropped. The second is the part
/// that matters — a cook seeing four recipes where there are five has no
/// way to notice.
void main() {
  test('every id is unique, in both languages', () {
    for (final list in [prepperRecipesDe, prepperRecipesEn]) {
      final ids = list.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    }
    for (final list in [preservationMethodsDe, preservationMethodsEn]) {
      final ids = list.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    }
  });

  test('both languages currently carry the same dishes, in order', () {
    expect(
      prepperRecipesEn.map((r) => r.id).toList(),
      prepperRecipesDe.map((r) => r.id).toList(),
    );
    expect(
      preservationMethodsEn.map((m) => m.id).toList(),
      preservationMethodsDe.map((m) => m.id).toList(),
    );
  });

  test('nothing is empty', () {
    for (final recipe in [...prepperRecipesDe, ...prepperRecipesEn]) {
      expect(recipe.title.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.hint.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.steps.trim(), isNotEmpty, reason: recipe.id);
    }
  });

  group('choosing by language', () {
    test('German gets the German list, unmarked', () {
      final chosen = recipesFor('de');

      expect(
        chosen.map((e) => e.value.title).first,
        'Couscous mit Kichererbsen',
      );
      expect(chosen.every((e) => !e.isFallback), isTrue);
    });

    test('English gets the English list, unmarked', () {
      final chosen = recipesFor('en');

      expect(chosen.map((e) => e.value.title).first, 'Couscous with chickpeas');
      expect(chosen.every((e) => !e.isFallback), isTrue);
    });

    test('a language nobody translated for is served English', () {
      // The rest of the app does the same, and a Dutch household reading
      // English recipes is better off than one reading none.
      expect(
        recipesFor('nl').map((e) => e.value.title).first,
        'Couscous with chickpeas',
      );
    });

    test('preservation methods follow the same rule', () {
      expect(
        preservationMethodsFor('de').first.value.title,
        'Kühlen und Einfrieren',
      );
      expect(
        preservationMethodsFor('en').first.value.title,
        'Chilling and freezing',
      );
    });
  });

  group('when a dish exists in one language only', () {
    // The lists agree today, so the fallback is exercised against a made-up
    // pair rather than against a gap somebody has to remember to leave.
    const onlyGerman = PrepperRecipe(
      id: 'griesbrei',
      title: 'Grießbrei',
      hint: 'Warm',
      steps: 'Grieß in Milch einrühren und aufkochen.',
    );

    test('it is shown, marked, and last', () {
      final chosen = mergeByLanguage(
        'en',
        de: [...prepperRecipesDe, onlyGerman],
        en: prepperRecipesEn,
        idOf: (item) => item.id,
      );

      expect(chosen, hasLength(prepperRecipesEn.length + 1));
      // The reader's own language first, in its own order.
      expect(chosen.first.value.title, 'Couscous with chickpeas');
      expect(chosen.first.isFallback, isFalse);
      // And the untranslated one arrives as what it is.
      expect(chosen.last.value.title, 'Grießbrei');
      expect(chosen.last.fallbackLanguage, 'de');
    });

    test('the other direction works the same', () {
      final chosen = mergeByLanguage(
        'de',
        de: prepperRecipesDe,
        en: [
          ...prepperRecipesEn,
          const PrepperRecipe(
            id: 'beans-on-toast',
            title: 'Beans on toast',
            hint: 'One pan',
            steps: 'Heat the beans, toast the bread.',
          ),
        ],
        idOf: (item) => item.id,
      );

      expect(chosen.last.value.title, 'Beans on toast');
      expect(chosen.last.fallbackLanguage, 'en');
    });

    test('nothing is dropped in either direction', () {
      final ids = mergeByLanguage(
        'en',
        de: [...prepperRecipesDe, onlyGerman],
        en: prepperRecipesEn,
        idOf: (item) => item.id,
      ).map((e) => e.value.id).toSet();

      expect(ids, contains('griesbrei'));
      for (final recipe in prepperRecipesEn) {
        expect(ids, contains(recipe.id));
      }
    });
  });
}
