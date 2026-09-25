import 'package:flutter_test/flutter_test.dart';
import 'package:preppsuite_flutter/features/inventory/application/prepper_recipes.dart';
import 'package:preppsuite_flutter/local_db/database.dart';

/// Whether the cupboard names what a recipe asks for.
///
/// The claim this file defends is a small one, and stating it small is
/// the point: the app compares **names**. It cannot see into a tin. Every
/// test here is about keeping that claim from quietly growing into "you
/// can cook this".
void main() {
  InventoryItem item(
    String name, {
    String category = 'food',
    double quantity = 1,
    DateTime? deletedAt,
  }) => InventoryItem(
    clientId: name,
    householdId: 'h',
    name: name,
    category: category,
    quantity: quantity,
    unit: 'kg',
    storageLocation: 'Keller',
    deletedAt: deletedAt,
    updatedAt: DateTime.utc(2026),
    dirty: false,
  );

  test('a name that contains the word counts', () {
    final matches = matchIngredients(
      ingredients: ['Kichererbsen'],
      items: [item('Kichererbsen 400 g Dose')],
    );
    expect(matches.single.isFound, isTrue);
    // The row's own name comes back, so the cook can see what was
    // matched rather than trusting a tick.
    expect(matches.single.found, ['Kichererbsen 400 g Dose']);
  });

  test('umlauts are not a trap', () {
    // The inventory is full of "Rapsoel" and "Rapsöl" in equal measure.
    expect(
      matchIngredients(
        ingredients: ['Öl'],
        items: [item('Rapsoel')],
      ).single.isFound,
      isTrue,
    );
    expect(
      matchIngredients(
        ingredients: ['Oel'],
        items: [item('Rapsöl')],
      ).single.isFound,
      isTrue,
    );
  });

  test('what is not there is said to be not there', () {
    final matches = matchIngredients(
      ingredients: ['Thunfisch'],
      items: [item('Linsen')],
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
        item('Bohnenstange', category: 'tools'),
      ],
    );
    // A row consumed down to nothing is not a stocked ingredient, a
    // tombstone is not a tin, and a bean pole is not a bean.
    expect(matches.single.isFound, isFalse);
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
        matchIngredients(ingredients: ['Reis'], items: [item('Reis')]),
      ),
      isTrue,
    );
    expect(
      namesEverything(
        matchIngredients(
          ingredients: ['Reis', 'Linsen'],
          items: [item('Reis')],
        ),
      ),
      isFalse,
    );
  });
}
