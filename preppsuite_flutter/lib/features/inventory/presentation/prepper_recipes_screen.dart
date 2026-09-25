import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../local_db/database.dart';
import '../application/inventory_providers.dart';
import '../application/prepper_recipes.dart';

/// Cooking out of the store cupboard.
///
/// What is shown follows the language the app is set to — which is the
/// system's unless somebody chose otherwise in the settings. The recipes
/// are written per language rather than translated, so each locale gets a
/// whole list of its own. The preservation methods below them *are*
/// translations, and one that exists in only one language is shown in that
/// language and said to be, rather than quietly left out; see
/// `prepper_recipes.dart`.
class PrepperRecipesScreen extends ConsumerStatefulWidget {
  const PrepperRecipesScreen({super.key, required this.householdId});

  final String householdId;

  @override
  ConsumerState<PrepperRecipesScreen> createState() =>
      _PrepperRecipesScreenState();
}

class _PrepperRecipesScreenState extends ConsumerState<PrepperRecipesScreen> {
  bool _onlyCookable = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final items =
        ref.watch(inventoryItemsProvider(widget.householdId)).value ??
        const <InventoryItem>[];
    final all = recipesFor(language);
    final matches = {
      for (final entry in all)
        entry.value.id: matchIngredients(
          ingredients: entry.value.ingredients,
          items: items,
        ),
    };
    final recipes = _onlyCookable
        ? [
            for (final entry in all)
              if (namesEverything(matches[entry.value.id]!)) entry,
          ]
        : all;
    final methods = preservationMethodsFor(language);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepperRecipesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.prepperRecipesIntro),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.recipeOnlyCookable),
            // The limit is on the switch and not in a legend further
            // down: somebody who turns this on is about to believe a
            // list, and the sentence that says what the list means has
            // to be where they turn it on.
            subtitle: Text(l10n.recipeMatchNote),
            isThreeLine: true,
            value: _onlyCookable,
            onChanged: (value) => setState(() => _onlyCookable = value),
          ),
          if (recipes.isEmpty) Text(l10n.recipeNoneCookable),
          for (final entry in recipes)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.soup_kitchen_outlined),
                title: Text(entry.value.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.value.hint),
                    ?_fallbackNote(context, l10n, entry),
                  ],
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.value.steps),
                  ),
                  if (matches[entry.value.id] case final found?
                      when found.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.recipeIngredientsTitle,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final match in found)
                      _Ingredient(match: match, l10n: l10n),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            l10n.preservationTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.preservationIntro),
          const SizedBox(height: 8),
          for (final entry in methods)
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: Text(entry.value.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.value.body),
                  ?_fallbackNote(context, l10n, entry),
                ],
              ),
              isThreeLine: true,
            ),
        ],
      ),
    );
  }

  /// Said on the entry itself, not in a legend somewhere: a cook who sees
  /// a German recipe in an English app needs to know why before they read
  /// it, not after.
  Widget? _fallbackNote(
    BuildContext context,
    AppLocalizations l10n,
    LocalisedRecipe<Object> entry,
  ) {
    final language = entry.fallbackLanguage;
    if (language == null) return null;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        language == 'de' ? l10n.recipeOnlyInGerman : l10n.recipeOnlyInEnglish,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One ingredient, and what the inventory calls it.
///
/// A tick where a row's name contains the word, and the row's own name
/// underneath — not a bare tick. "Bohnen" matching "Bohnenkraut" is the
/// kind of thing the cook has to be able to see for themselves, and only
/// the name shows it.
class _Ingredient extends StatelessWidget {
  const _Ingredient({required this.match, required this.l10n});

  final RecipeIngredientMatch match;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            match.isFound
                ? Icons.check_circle_outline
                : Icons.remove_circle_outline,
            size: 18,
            color: match.isFound
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.ingredient),
                Text(
                  match.isFound
                      ? l10n.recipeInStock(match.found.join(', '))
                      : l10n.recipeNotInStock,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
