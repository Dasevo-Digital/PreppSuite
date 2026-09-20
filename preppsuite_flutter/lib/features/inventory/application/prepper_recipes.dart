/// Cooking out of the store cupboard, in the language that was asked for.
///
/// The recipes are prose in two lists, and a compiler cannot check prose.
/// What it can be held to is that both lists describe the same dishes —
/// `prepper_recipes_test.dart` does that, the way the first-aid guides are
/// held to it.
///
/// **But the two lists are allowed to drift**, and that is the point of
/// [recipesFor]. A dish is not a string: "H-Milch" is a German pantry and
/// "long-life milk" is not quite the same shelf, so a language may one day
/// want a dish the other does not have. What must never happen is the
/// thing that happens by default — the shorter list silently being all an
/// English household ever sees.
///
/// So what is missing in the language asked for is shown all the same, in
/// the language it exists in, and **labelled as such**. Translating it on
/// the device is not an option: there is no translator here, and inventing
/// one would be the invented content this app does not ship. A cook who
/// reads "only available in German" can decide; a cook who is shown four
/// recipes instead of five cannot.
library;

/// One dish.
class PrepperRecipe {
  const PrepperRecipe({
    required this.id,
    required this.title,
    required this.hint,
    required this.steps,
  });

  /// Stable across languages, and never shown.
  final String id;

  final String title;

  /// The one thing that decides whether it fits right now: whether it
  /// needs cooking, one pot, or none.
  final String hint;

  final String steps;
}

/// One way of making food last.
class PreservationMethod {
  const PreservationMethod({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final String body;
}

/// A recipe as it will be shown, and whether it is in the wrong language.
class LocalisedRecipe<T> {
  const LocalisedRecipe(this.value, {this.fallbackLanguage});

  final T value;

  /// Null when it is in the language that was asked for. Otherwise the
  /// language it *is* in, which the screen says out loud.
  final String? fallbackLanguage;

  bool get isFallback => fallbackLanguage != null;
}

/// The recipes for [languageCode], with anything untranslated appended.
///
/// Appended rather than interleaved: the ones in the reader's own language
/// come first in their own order, and the rest arrive as what they are —
/// extras from the other language.
List<LocalisedRecipe<PrepperRecipe>> recipesFor(String languageCode) =>
    mergeByLanguage(
      languageCode,
      de: prepperRecipesDe,
      en: prepperRecipesEn,
      idOf: (item) => item.id,
    );

List<LocalisedRecipe<PreservationMethod>> preservationMethodsFor(
  String languageCode,
) => mergeByLanguage(
  languageCode,
  de: preservationMethodsDe,
  en: preservationMethodsEn,
  idOf: (item) => item.id,
);

/// Picks the list for [languageCode] and appends what only the other one
/// has, marked.
///
/// Public because it is also the only way to exercise the drift it exists
/// for: the shipped lists agree today, so a test hands it a pair that does
/// not — better than leaving a real gap in the app so a test has something
/// to find.
///
/// Anything that is not German is served English, which is what the rest
/// of the app does.
List<LocalisedRecipe<T>> mergeByLanguage<T>(
  String languageCode, {
  required List<T> de,
  required List<T> en,
  required String Function(T) idOf,
}) {
  final german = languageCode == 'de';
  final wanted = german ? de : en;
  final other = german ? en : de;
  final otherLanguage = german ? 'en' : 'de';
  final have = {for (final item in wanted) idOf(item)};
  return [
    for (final item in wanted) LocalisedRecipe(item),
    for (final item in other)
      if (!have.contains(idOf(item)))
        LocalisedRecipe(item, fallbackLanguage: otherLanguage),
  ];
}

const prepperRecipesDe = [
  PrepperRecipe(
    id: 'couscous',
    title: 'Couscous mit Kichererbsen',
    hint: 'Kein langes Kochen',
    steps:
        'Couscous mit heißem Wasser quellen lassen. Kichererbsen, '
        'Dosentomaten, Öl und Gewürze unterheben.',
  ),
  PrepperRecipe(
    id: 'lentil-tomato',
    title: 'Linsen-Tomaten-Topf',
    hint: 'Ein Topf',
    steps:
        'Rote Linsen mit Dosentomaten und wenig Wasser 12–15 Minuten '
        'garen. Mit Brühe und getrockneten Kräutern würzen.',
  ),
  PrepperRecipe(
    id: 'porridge',
    title: 'Hafer-Porridge',
    hint: 'Warm oder kalt',
    steps:
        'Haferflocken mit H-Milch, Pflanzengetränk oder Wasser anrühren. '
        'Trockenobst, Nüsse und Zimt ergänzen.',
  ),
  PrepperRecipe(
    id: 'bean-corn-salad',
    title: 'Bohnen-Mais-Salat',
    hint: 'Ohne Kochen',
    steps:
        'Bohnen und Mais abgießen, mit Öl, Essig, Salz und Kräutern '
        'mischen. Abtropfwasser soweit sinnvoll weiterverwenden.',
  ),
  PrepperRecipe(
    id: 'tuna-pasta',
    title: 'Thunfisch-Nudel-Topf',
    hint: 'Ein Topf',
    steps:
        'Nudeln in knapp bemessenem Wasser garen. Thunfisch, Erbsen aus '
        'der Dose und Gewürze untermischen.',
  ),
];

const prepperRecipesEn = [
  PrepperRecipe(
    id: 'couscous',
    title: 'Couscous with chickpeas',
    hint: 'No prolonged cooking',
    steps:
        'Soak couscous in hot water. Fold in chickpeas, canned tomatoes, '
        'oil and spices.',
  ),
  PrepperRecipe(
    id: 'lentil-tomato',
    title: 'Lentil tomato pot',
    hint: 'One pot',
    steps:
        'Cook red lentils with canned tomatoes and little water for 12–15 '
        'minutes. Season with stock and dried herbs.',
  ),
  PrepperRecipe(
    id: 'porridge',
    title: 'Oat porridge',
    hint: 'Hot or cold',
    steps:
        'Mix oats with long-life milk, plant drink or water. Add dried '
        'fruit, nuts and cinnamon.',
  ),
  PrepperRecipe(
    id: 'bean-corn-salad',
    title: 'Bean and corn salad',
    hint: 'No cooking',
    steps:
        'Drain beans and corn and mix with oil, vinegar, salt and herbs. '
        'Reuse the liquid where appropriate.',
  ),
  PrepperRecipe(
    id: 'tuna-pasta',
    title: 'Tuna pasta pot',
    hint: 'One pot',
    steps:
        'Cook pasta in a measured amount of water. Mix in tuna, canned '
        'peas and seasoning.',
  ),
];

const preservationMethodsDe = [
  PreservationMethod(
    id: 'chill-freeze',
    title: 'Kühlen und Einfrieren',
    body:
        'Portionieren, beschriften und Kühlkette einhalten. Aufgetaute '
        'Lebensmittel nicht ohne Erhitzen erneut einfrieren.',
  ),
  PreservationMethod(
    id: 'canning',
    title: 'Einkochen',
    body:
        'Nur geeignete, geprüfte Rezepte sowie passende Zeit und '
        'Temperatur verwenden; säurearme Lebensmittel benötigen besondere '
        'Sorgfalt.',
  ),
  PreservationMethod(
    id: 'fermenting',
    title: 'Fermentieren',
    body:
        'Lebensmittel vollständig unter Lake halten und saubere Gefäße '
        'verwenden.',
  ),
  PreservationMethod(
    id: 'drying',
    title: 'Trocknen',
    body:
        'Dünn schneiden, vollständig durchtrocknen und anschließend '
        'luftdicht, kühl und dunkel lagern.',
  ),
  PreservationMethod(
    id: 'pickling',
    title: 'Einlegen, Salzen und Zuckern',
    body:
        'Konzentration und Rezept einhalten; Aussehen, Geruch und '
        'Verschluss vor dem Verzehr prüfen.',
  ),
];

const preservationMethodsEn = [
  PreservationMethod(
    id: 'chill-freeze',
    title: 'Chilling and freezing',
    body:
        'Portion, label and maintain the cold chain. Do not refreeze '
        'thawed food without cooking it first.',
  ),
  PreservationMethod(
    id: 'canning',
    title: 'Canning',
    body:
        'Use tested recipes with the specified time and temperature; '
        'low-acid food needs particular care.',
  ),
  PreservationMethod(
    id: 'fermenting',
    title: 'Fermenting',
    body: 'Keep food fully below the brine and use clean vessels.',
  ),
  PreservationMethod(
    id: 'drying',
    title: 'Drying',
    body:
        'Cut thinly, dry completely, then store airtight in a cool and '
        'dark place.',
  ),
  PreservationMethod(
    id: 'pickling',
    title: 'Pickling, salting and sugaring',
    body:
        'Follow the recipe and concentration; inspect appearance, smell '
        'and seal before eating.',
  ),
];
