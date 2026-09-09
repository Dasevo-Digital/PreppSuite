import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

class PrepperRecipesScreen extends StatelessWidget {
  const PrepperRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final german = Localizations.localeOf(context).languageCode == 'de';
    final recipes = german ? _recipesDe : _recipesEn;
    final methods = german ? _methodsDe : _methodsEn;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepperRecipesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.prepperRecipesIntro),
          const SizedBox(height: 12),
          for (final recipe in recipes)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.soup_kitchen_outlined),
                title: Text(recipe.$1),
                subtitle: Text(recipe.$2),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(recipe.$3),
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
          for (final method in methods)
            ListTile(
              leading: const Icon(Icons.kitchen_outlined),
              title: Text(method.$1),
              subtitle: Text(method.$2),
            ),
        ],
      ),
    );
  }
}

const _recipesDe = [
  (
    'Couscous mit Kichererbsen',
    'Kein langes Kochen',
    'Couscous mit heißem Wasser quellen lassen. Kichererbsen, Dosentomaten, Öl und Gewürze unterheben.',
  ),
  (
    'Linsen-Tomaten-Topf',
    'Ein Topf',
    'Rote Linsen mit Dosentomaten und wenig Wasser 12–15 Minuten garen. Mit Brühe und getrockneten Kräutern würzen.',
  ),
  (
    'Hafer-Porridge',
    'Warm oder kalt',
    'Haferflocken mit H-Milch, Pflanzengetränk oder Wasser anrühren. Trockenobst, Nüsse und Zimt ergänzen.',
  ),
  (
    'Bohnen-Mais-Salat',
    'Ohne Kochen',
    'Bohnen und Mais abgießen, mit Öl, Essig, Salz und Kräutern mischen. Abtropfwasser soweit sinnvoll weiterverwenden.',
  ),
  (
    'Thunfisch-Nudel-Topf',
    'Ein Topf',
    'Nudeln in knapp bemessenem Wasser garen. Thunfisch, Erbsen aus der Dose und Gewürze untermischen.',
  ),
];

const _recipesEn = [
  (
    'Couscous with chickpeas',
    'No prolonged cooking',
    'Soak couscous in hot water. Fold in chickpeas, canned tomatoes, oil and spices.',
  ),
  (
    'Lentil tomato pot',
    'One pot',
    'Cook red lentils with canned tomatoes and little water for 12–15 minutes. Season with stock and dried herbs.',
  ),
  (
    'Oat porridge',
    'Hot or cold',
    'Mix oats with long-life milk, plant drink or water. Add dried fruit, nuts and cinnamon.',
  ),
  (
    'Bean and corn salad',
    'No cooking',
    'Drain beans and corn and mix with oil, vinegar, salt and herbs. Reuse the liquid where appropriate.',
  ),
  (
    'Tuna pasta pot',
    'One pot',
    'Cook pasta in a measured amount of water. Mix in tuna, canned peas and seasoning.',
  ),
];

const _methodsDe = [
  (
    'Kühlen und Einfrieren',
    'Portionieren, beschriften und Kühlkette einhalten. Aufgetaute Lebensmittel nicht ohne Erhitzen erneut einfrieren.',
  ),
  (
    'Einkochen',
    'Nur geeignete, geprüfte Rezepte sowie passende Zeit und Temperatur verwenden; säurearme Lebensmittel benötigen besondere Sorgfalt.',
  ),
  (
    'Fermentieren',
    'Lebensmittel vollständig unter Lake halten und saubere Gefäße verwenden.',
  ),
  (
    'Trocknen',
    'Dünn schneiden, vollständig durchtrocknen und anschließend luftdicht, kühl und dunkel lagern.',
  ),
  (
    'Einlegen, Salzen und Zuckern',
    'Konzentration und Rezept einhalten; Aussehen, Geruch und Verschluss vor dem Verzehr prüfen.',
  ),
];

const _methodsEn = [
  (
    'Chilling and freezing',
    'Portion, label and maintain the cold chain. Do not refreeze thawed food without cooking it first.',
  ),
  (
    'Canning',
    'Use tested recipes with the specified time and temperature; low-acid food needs particular care.',
  ),
  ('Fermenting', 'Keep food fully below the brine and use clean vessels.'),
  (
    'Drying',
    'Cut thinly, dry completely, then store airtight in a cool and dark place.',
  ),
  (
    'Pickling, salting and sugaring',
    'Follow the recipe and concentration; inspect appearance, smell and seal before eating.',
  ),
];
