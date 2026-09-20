import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../application/prepper_recipes.dart';

/// Cooking out of the store cupboard.
///
/// What is shown follows the language the app is set to — which is the
/// system's unless somebody chose otherwise in the settings. Where a
/// recipe exists in only one language it is shown in that one and said to
/// be, rather than quietly left out; see `prepper_recipes.dart`.
class PrepperRecipesScreen extends StatelessWidget {
  const PrepperRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final language = Localizations.localeOf(context).languageCode;
    final recipes = recipesFor(language);
    final methods = preservationMethodsFor(language);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepperRecipesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.prepperRecipesIntro),
          const SizedBox(height: 12),
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
