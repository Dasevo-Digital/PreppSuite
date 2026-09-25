import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/prepper_recipes.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Whether the cupboard names what a recipe asks for.
///
/// The claim this file defends is a small one, and stating it small is
/// the point: the app compares **names**. It cannot see into a tin. Every
/// test here is about keeping that claim from quietly growing into "you
/// can cook this" — and, since the comparison stopped being a plain
/// substring, about keeping it from shrinking into "you cannot" either.
void main() {
  InventoryItem item(
    String name, {
    String category = 'food',
    double quantity = 1,
    String? foodGroup,
    DateTime? deletedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    unit: 'kg',
    storageLocation: 'Keller',
    foodGroup: foodGroup,
    deletedAt: deletedAt,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  List<String> foundFor(
    String ingredient,
    List<InventoryItem> items, {
    String language = 'de',
  }) => matchIngredients(
    ingredients: [ingredient],
    items: items,
    language: language,
  ).single.found;

  test('a row whose name carries the word counts', () {
    final matches = matchIngredients(
      ingredients: ['Kichererbsen'],
      items: [item('Kichererbsen 400 g Dose')],
      language: 'de',
    );
    expect(matches.single.isFound, isTrue);
    // The row's own name comes back, so the cook can see what was
    // matched rather than trusting a tick.
    expect(matches.single.found, ['Kichererbsen 400 g Dose']);
  });

  test('umlauts are not a trap', () {
    // The inventory is full of "Rapsoel" and "Rapsöl" in equal measure.
    expect(foundFor('Öl', [item('Rapsoel')]), ['Rapsoel']);
    expect(foundFor('Oel', [item('Rapsöl')]), ['Rapsöl']);
  });

  test('what is not there is said to be not there', () {
    final matches = matchIngredients(
      ingredients: ['Thunfisch'],
      items: [item('Linsen')],
      language: 'de',
    );
    expect(matches.single.isFound, isFalse);
    expect(matches.single.found, isEmpty);
  });

  test('an emptied, a deleted and a non-food row do not count', () {
    final matches = matchIngredients(
      ingredients: ['Bohnen'],
      items: [
        item('Bohnen', quantity: 0),
        item('Bohnen aus dem Garten', deletedAt: DateTime.utc(2026)),
        item('Bohnen', category: 'tools'),
      ],
      language: 'de',
    );
    expect(matches.single.isFound, isFalse);
  });

  group('a German compound is what it ends in', () {
    test('and not what it begins with', () {
      // Every one of these was a tick before: `schokolade` carries the
      // letters `ol`, `gemusebruhe` carries `gemuse`.
      expect(foundFor('Öl', [item('Schokolade 100 g')]), isEmpty);
      expect(foundFor('Öl', [item('Vollmilch 1 l')]), isEmpty);
      expect(foundFor('Gemüse', [item('Gemüsebrühe Würfel')]), isEmpty);
      expect(foundFor('Mais', [item('Maisstärke 400 g')]), isEmpty);
      expect(foundFor('Tomaten', [item('Tomatenmark 200 g')]), isEmpty);
      expect(foundFor('Bohnen', [item('Bohnenkraut getrocknet')]), isEmpty);
    });

    test('so the head of the compound still answers', () {
      expect(foundFor('Brühe', [item('Gemüsebrühe Würfel')]), [
        'Gemüsebrühe Würfel',
      ]);
      expect(foundFor('Öl', [item('Olivenöl 750 ml')]), ['Olivenöl 750 ml']);
      expect(foundFor('Milch', [item('Vollmilch 1 l')]), ['Vollmilch 1 l']);
    });

    test('and singular meets plural in both directions', () {
      // "Kartoffel 2,5 kg" on the shelf used to be reported as no
      // potatoes at all, which hid a dish that was perfectly possible.
      expect(foundFor('Kartoffeln', [item('Kartoffel 2,5 kg')]), [
        'Kartoffel 2,5 kg',
      ]);
      expect(foundFor('Zwiebel', [item('Zwiebeln 1 kg')]), ['Zwiebeln 1 kg']);
    });

    test('except where the compound is a different plant', () {
      expect(foundFor('Erbsen', [item('Kichererbsen 400 g Dose')]), isEmpty);
      // The named exception must not cost the honest match beside it.
      expect(foundFor('Erbsen', [item('Erbsen 400 g Dose')]), [
        'Erbsen 400 g Dose',
      ]);
    });
  });

  group('English matches whole words', () {
    test('because English does not build compounds that way', () {
      expect(
        foundFor('ham', [item('Graham crackers')], language: 'en'),
        isEmpty,
      );
      expect(
        foundFor('rice', [item('Liquorice sticks')], language: 'en'),
        isEmpty,
      );
      expect(
        foundFor('stock', [item('Stockfish fillet')], language: 'en'),
        isEmpty,
      );
    });

    test('and the word itself still answers', () {
      expect(foundFor('stock', [item('Chicken stock cubes')], language: 'en'), [
        'Chicken stock cubes',
      ]);
      expect(foundFor('ham', [item('Cooked ham 200 g')], language: 'en'), [
        'Cooked ham 200 g',
      ]);
    });

    test('an ingredient of two words needs both', () {
      expect(
        foundFor('split peas', [item('Peas, dried')], language: 'en'),
        isEmpty,
      );
      expect(
        foundFor('split peas', [item('Split peas 500 g')], language: 'en'),
        [
          'Split peas 500 g',
        ],
      );
    });
  });

  group('a generic ingredient asks the supply group', () {
    test('because the word is on almost no tin', () {
      // Nothing here is called "Gemüse"; the household said so itself by
      // tagging the row, and that tag is what answers.
      expect(
        foundFor('Gemüse', [item('Erbsen 400 g', foodGroup: 'vegetables')]),
        [
          'Erbsen 400 g',
        ],
      );
    });

    test('and only the group it really is', () {
      expect(
        foundFor('Gemüse', [item('H-Milch 1 l', foodGroup: 'dairy')]),
        isEmpty,
      );
      // An untagged row is not guessed at.
      expect(foundFor('Gemüse', [item('Erbsen 400 g')]), isEmpty);
    });

    test('while a specific ingredient is not widened to its group', () {
      // Cheese must not answer for milk, and butter must not answer for
      // oil: mapping those would be the app substituting for the cook.
      expect(
        foundFor('Milch', [item('Gouda 400 g', foodGroup: 'dairy')]),
        isEmpty,
      );
      expect(
        foundFor('Öl', [item('Butter 250 g', foodGroup: 'fats')]),
        isEmpty,
      );
    });
  });

  test('every shipped recipe lists what it is made of', () {
    for (final list in [prepperRecipesDe, prepperRecipesEn]) {
      for (final recipe in list) {
        expect(recipe.ingredients, isNotEmpty, reason: recipe.id);
        for (final ingredient in recipe.ingredients) {
          expect(ingredient.trim(), isNotEmpty, reason: recipe.id);
        }
      }
    }
  });

  test('naming everything is not the same as having nothing', () {
    // An empty ingredient list must never read as "you can cook this",
    // which is what `every` on an empty list would otherwise say.
    expect(namesEverything(const []), isFalse);
    expect(
      namesEverything(
        matchIngredients(
          ingredients: ['Reis'],
          items: [item('Reis')],
          language: 'de',
        ),
      ),
      isTrue,
    );
    expect(
      namesEverything(
        matchIngredients(
          ingredients: ['Reis', 'Linsen'],
          items: [item('Reis')],
          language: 'de',
        ),
      ),
      isFalse,
    );
  });
}
