import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/prepper_recipes.dart';

/// The recipes are prose in three lists, and a compiler cannot check prose.
///
/// What it can be held to is the rule the two halves of this file follow
/// differently: the **recipes** are independent lists, each whole, so
/// nobody is ever shown a dish in a language they did not ask for; the
/// **preservation methods** are translations of one another, so a gap
/// there is a real gap and has to be *shown* rather than quietly dropped.
/// The second is the part that matters — a cook seeing four methods where
/// there are five has no way to notice.
void main() {
  test('every id is unique, in every language', () {
    for (final list in [prepperRecipesDe, prepperRecipesEn, prepperRecipesEs]) {
      final ids = list.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length);
    }
    for (final list in [
      preservationMethodsDe,
      preservationMethodsEn,
      preservationMethodsEs,
    ]) {
      final ids = list.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    }
  });

  test('the recipe lists are independent, not translations', () {
    // Deliberate: an English store cupboard holds baked beans and corned
    // beef, a German one holds Dosentomaten and H-Milch, a Spanish one
    // lentejas de bote and pan duro. Sharing an id would mean somebody
    // went back to treating one list as another's translation, and the
    // fallback would start firing on every dish.
    final german = prepperRecipesDe.map((r) => r.id).toSet();
    final english = prepperRecipesEn.map((r) => r.id).toSet();
    final spanish = prepperRecipesEs.map((r) => r.id).toSet();

    expect(german.intersection(english), isEmpty);
    expect(german.intersection(spanish), isEmpty);
    expect(english.intersection(spanish), isEmpty);
    expect(german, isNotEmpty);
    expect(english, isNotEmpty);
    expect(spanish, isNotEmpty);
  });

  test('the preservation methods stay translations, in order', () {
    final german = preservationMethodsDe.map((m) => m.id).toList();
    expect(preservationMethodsEn.map((m) => m.id).toList(), german);
    expect(preservationMethodsEs.map((m) => m.id).toList(), german);
  });

  test('nothing is empty', () {
    for (final recipe in [
      ...prepperRecipesDe,
      ...prepperRecipesEn,
      ...prepperRecipesEs,
    ]) {
      expect(recipe.title.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.hint.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.steps.trim(), isNotEmpty, reason: recipe.id);
      expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
    }
    for (final method in [
      ...preservationMethodsDe,
      ...preservationMethodsEn,
      ...preservationMethodsEs,
    ]) {
      expect(method.title.trim(), isNotEmpty, reason: method.id);
      expect(method.body.trim(), isNotEmpty, reason: method.id);
    }
  });

  group('choosing by language', () {
    test('German gets the German list, whole and unmarked', () {
      final chosen = recipesFor('de');

      expect(chosen.map((e) => e.value.id), prepperRecipesDe.map((r) => r.id));
      expect(chosen.every((e) => !e.isFallback), isTrue);
    });

    test('English gets the English list, whole and unmarked', () {
      final chosen = recipesFor('en');

      expect(chosen.map((e) => e.value.id), prepperRecipesEn.map((r) => r.id));
      expect(chosen.first.value.title, 'Beans on toast');
      expect(chosen.every((e) => !e.isFallback), isTrue);
    });

    test('Spanish gets the Spanish list, whole and unmarked', () {
      final chosen = recipesFor('es');

      expect(chosen.map((e) => e.value.id), prepperRecipesEs.map((r) => r.id));
      expect(chosen.every((e) => !e.isFallback), isTrue);
    });

    test('a language nobody wrote for is served English', () {
      // The rest of the app does the same, and a Dutch household reading
      // English recipes is better off than one reading none.
      expect(
        recipesFor('nl').map((e) => e.value.id),
        prepperRecipesEn.map((r) => r.id),
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
      expect(
        preservationMethodsFor('nl').first.value.title,
        'Chilling and freezing',
      );
      expect(
        preservationMethodsFor('es').first.value.title,
        'Refrigerar y congelar',
      );
    });

    test('nothing in either language is ever labelled today', () {
      for (final language in ['de', 'en', 'es', 'nl']) {
        expect(
          [
            ...recipesFor(language),
            ...preservationMethodsFor(language),
          ].where((e) => e.isFallback),
          isEmpty,
          reason: language,
        );
      }
    });
  });

  group('when a preservation method exists in one language only', () {
    // The shipped lists agree, so the fallback is exercised against a
    // made-up pair rather than against a gap somebody has to remember to
    // leave in the app.
    const onlyGerman = PreservationMethod(
      id: 'smoking',
      title: 'Räuchern',
      body: 'Kalt oder heiß, immer über sauberem Holz.',
    );

    test('it is shown, marked, and last', () {
      final chosen = mergeByLanguage(
        'en',
        de: [...preservationMethodsDe, onlyGerman],
        en: preservationMethodsEn,
        idOf: (item) => item.id,
      );

      expect(chosen, hasLength(preservationMethodsEn.length + 1));
      // The reader's own language first, in its own order.
      expect(chosen.first.value.title, 'Chilling and freezing');
      expect(chosen.first.isFallback, isFalse);
      // And the untranslated one arrives as what it is.
      expect(chosen.last.value.title, 'Räuchern');
      expect(chosen.last.fallbackLanguage, 'de');
    });

    test('the other direction works the same', () {
      final chosen = mergeByLanguage(
        'de',
        de: preservationMethodsDe,
        en: [
          ...preservationMethodsEn,
          const PreservationMethod(
            id: 'smoking',
            title: 'Smoking',
            body: 'Cold or hot, always over clean wood.',
          ),
        ],
        idOf: (item) => item.id,
      );

      expect(chosen.last.value.title, 'Smoking');
      expect(chosen.last.fallbackLanguage, 'en');
    });

    test('Spanish looks to English first, then to German', () {
      final chosen = mergeByLanguage(
        'es',
        de: [...preservationMethodsDe, onlyGerman],
        en: [
          ...preservationMethodsEn,
          const PreservationMethod(
            id: 'salting-fish',
            title: 'Salting fish',
            body: 'Dry salt, cool, turned daily.',
          ),
        ],
        es: preservationMethodsEs,
        idOf: (item) => item.id,
      );

      expect(chosen.first.value.title, 'Refrigerar y congelar');
      expect(chosen, hasLength(preservationMethodsEs.length + 2));
      expect(chosen[chosen.length - 2].fallbackLanguage, 'en');
      expect(chosen.last.value.title, 'Räuchern');
      expect(chosen.last.fallbackLanguage, 'de');
    });

    test('nothing is dropped in either direction', () {
      final ids = mergeByLanguage(
        'en',
        de: [...preservationMethodsDe, onlyGerman],
        en: preservationMethodsEn,
        idOf: (item) => item.id,
      ).map((e) => e.value.id).toSet();

      expect(ids, contains('smoking'));
      for (final method in preservationMethodsEn) {
        expect(ids, contains(method.id));
      }
    });
  });
}
