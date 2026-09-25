/// Cooking out of the store cupboard, in the language that was asked for.
///
/// Two things live in this file and they are localised differently, on
/// purpose.
///
/// **The recipes are not translations of each other.** A dish is not a
/// string: "H-Milch" is a German pantry and "long-life milk" is not quite
/// the same shelf, and a household that stocks baked beans does not cook
/// from a list built around Dosentomaten. So each language carries the
/// dishes its own store cupboard actually holds. Neither list is short of
/// anything, so there is nothing to fall back to and the two are free to
/// differ in length.
///
/// **The preservation methods are translations of each other**, because
/// drying is drying. There a gap is a real gap, so [mergeByLanguage] still
/// shows what only one language has and labels it. Translating on the
/// device is not an option: there is no translator here, and inventing one
/// would be the invented content this app does not ship. A cook who reads
/// "only available in German" can decide; a cook who is shown four methods
/// instead of five cannot.
library;

import '../../../local_db/database.dart';
import '../../search/application/app_search.dart' show foldForSearch;
import 'supply_groups.dart';

/// One dish.
class PrepperRecipe {
  const PrepperRecipe({
    required this.id,
    required this.title,
    required this.hint,
    required this.steps,
    this.ingredients = const [],
  });

  /// Stable across languages, and never shown.
  final String id;

  final String title;

  /// The one thing that decides whether it fits right now: whether it
  /// needs cooking, one pot, or none.
  final String hint;

  final String steps;

  /// What it is made of, as short words to look for in the inventory.
  ///
  /// Deliberately without amounts. A portion size would have to be
  /// invented — the steps say "Kichererbsen", not "240 g Kichererbsen",
  /// and picking a number would be this app stating something no recipe
  /// here states. So the comparison below answers "is there any" and
  /// never "is there enough", and the screen says so.
  final List<String> ingredients;
}

/// One ingredient beside what the inventory calls it.
class RecipeIngredientMatch {
  const RecipeIngredientMatch(this.ingredient, this.found);

  final String ingredient;

  /// The names of the rows that matched, or empty.
  final List<String> found;

  bool get isFound => found.isNotEmpty;
}

/// Whether the cupboard names what a recipe asks for.
///
/// **This compares names and nothing else**, which is the honest limit of
/// what the app can do here and is said on the screen too. A row called
/// "Kichererbsen 400 g Dose" answers "Kichererbsen"; an empty tin
/// somebody forgot to write off does not.
///
/// The comparison used to be a plain substring, and a substring is not a
/// word. "Öl" found "Schokolade", because `schokolade` carries the
/// letters `ol`; "Gemüse" found "Gemüsebrühe"; "Mais" found
/// "Maisstärke". It missed in the other direction too: a shelf holding
/// "Kartoffel 2,5 kg" was reported as having no "Kartoffeln", so the
/// filter hid a dish that was perfectly possible.
///
/// What replaces it is one fact about German: **the head of a compound
/// sits at the end.** A Gemüsebrühe is a Brühe. A Vollmilch is a Milch.
/// An Olivenöl is an Öl, and a Schokolade is not. So a shelf word counts
/// when it *ends* in the ingredient — never when it merely contains it.
///
/// English does not build words that way, so there the rule is plain word
/// equality. It is the same fact seen from the other side: without it
/// "ham" finds *Graham crackers*, "rice" finds *Liquorice* and "stock"
/// finds *Stockfish*.
///
/// Both sides are folded through [foldForSearch] plus the spelled-out
/// umlauts, so "Öl" still finds "Rapsoel", and both sides are stemmed, so
/// "Kartoffeln" meets "Kartoffel" and "Zwiebel" meets "Zwiebeln".
///
/// The app's search folds "Öl" to "ol" — right for a search box, where
/// the reader sees the results and corrects themselves. Here nobody sees
/// the miss: a cupboard that holds "Rapsoel" would simply be reported as
/// having no oil. So "ae", "oe" and "ue" collapse the same way the umlaut
/// does, applied to **both** sides, which is what keeps it safe:
/// "Sauerkraut" becomes "saurkraut" on the shelf and in the recipe alike,
/// so the pair still meets. Local to this file on purpose — the search box
/// wants the other behaviour, and one rule cannot be both.
String _foldPantry(String text) => foldForSearch(
  text,
).replaceAll('ae', 'a').replaceAll('oe', 'o').replaceAll('ue', 'u');

/// The folded words of [text]. Digits and units fall out on their own:
/// "400" and "g" are words here, they simply never match an ingredient.
List<String> _wordsOf(String text) => [
  for (final word in _foldPantry(text).split(RegExp(r'[^a-z0-9]+')))
    if (word.isNotEmpty) word,
];

/// [word] and the shorter forms inflection leaves behind.
///
/// Not a stemmer: four endings, cut only when enough word is left to
/// still mean something. A real stemmer lives in
/// `features/knowledge/german_stemmer.dart` and is far too eager for this
/// — it is built to make a search box generous, and a generous match here
/// is a tick beside food that is not in the house.
Set<String> _stems(String word) => {
  word,
  for (final ending in const ['en', 'n', 'e', 's'])
    if (word.endsWith(ending) && word.length - ending.length >= 4)
      word.substring(0, word.length - ending.length),
};

/// Compounds that are not what they end in.
///
/// The rule above is right about German far more often than not, and
/// where it is wrong it is wrong for a reason that no rule can see: a
/// Kichererbse is a different plant from an Erbse, and Alkohol is not an
/// Öl. Naming the handful of exceptions is honest; guessing at them with
/// a longer rule would not be.
const _notACompoundOf = <String, Set<String>>{
  'kichererbsen': {'erbsen'},
  'kichererbse': {'erbse'},
  'alkohol': {'ol'},
};

/// The ingredients that name a kind of food rather than a product.
///
/// "Gemüse" is written on almost no tin, so after the rule above it would
/// match nothing at all — and the two dishes that ask for it would never
/// be cookable. The way out is not a longer word list but the tagging
/// that is already there: since the supply groups came in, a row can
/// carry the BLE group it belongs to, and that tag is the household's own
/// statement rather than a guess by the app.
///
/// Kept deliberately short. "Milch" is not mapped to the dairy group —
/// that would let cheese answer for milk — and "Öl" is not mapped to
/// fats, which would let butter do it. Only where the ingredient really
/// is the category does the category answer.
const _ingredientGroups = <String, SupplyGroup>{
  'gemuse': SupplyGroup.vegetables,
};

/// Whether the shelf word [shelf] names the ingredient word [ingredient].
bool _wordNames(String ingredient, String shelf, bool german) {
  if (_notACompoundOf[shelf]?.contains(ingredient) ?? false) return false;
  final wanted = _stems(ingredient);
  for (final form in _stems(shelf)) {
    for (final want in wanted) {
      if (form == want) return true;
      if (german && form.endsWith(want)) return true;
    }
  }
  return false;
}

List<RecipeIngredientMatch> matchIngredients({
  required List<String> ingredients,
  required List<InventoryItem> items,
  required String language,
}) {
  // The recipe lists never fall back into the other language, so the
  // language of the screen is the language of the ingredient words.
  final german = language == 'de';
  final pantry = [
    for (final item in items)
      if (item.deletedAt == null &&
          (item.category == 'food' || item.category == 'water') &&
          item.quantity > 0)
        (
          name: item.name,
          words: _wordsOf(item.name),
          group: supplyGroupFromName(item.foodGroup),
        ),
  ];

  return [
    for (final ingredient in ingredients)
      RecipeIngredientMatch(ingredient, [
        for (final row in pantry)
          if (_rowNames(ingredient, row.words, row.group, german)) row.name,
      ]),
  ];
}

/// An ingredient of several words needs all of them — "split peas" is not
/// answered by a bag of peas alone.
bool _rowNames(
  String ingredient,
  List<String> shelfWords,
  SupplyGroup? shelfGroup,
  bool german,
) {
  final group = _ingredientGroups[_foldPantry(ingredient)];
  if (group != null && shelfGroup == group) return true;
  final wanted = _wordsOf(ingredient);
  if (wanted.isEmpty) return false;
  return wanted.every(
    (word) => shelfWords.any((shelf) => _wordNames(word, shelf, german)),
  );
}

/// Whether every ingredient was found. Used only for the filter, and
/// named for what it is: the cupboard has the words, which is not the
/// same as the meal being possible.
bool namesEverything(List<RecipeIngredientMatch> matches) =>
    matches.isNotEmpty && matches.every((match) => match.isFound);

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

/// The recipes for [languageCode].
///
/// Each list is whole, so nothing is appended from the other language and
/// no entry is ever marked. Anything that is not German is served English,
/// which is what the rest of the app does.
List<LocalisedRecipe<PrepperRecipe>> recipesFor(String languageCode) => [
  for (final recipe
      in languageCode == 'de' ? prepperRecipesDe : prepperRecipesEn)
    LocalisedRecipe(recipe),
];

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
/// The preservation methods use this and the recipes deliberately do not:
/// techniques are the same everywhere, so one missing in a language is a
/// gap rather than a difference.
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
    ingredients: ['Couscous', 'Kichererbsen', 'Tomaten', 'Öl'],
  ),
  PrepperRecipe(
    id: 'lentil-tomato',
    title: 'Linsen-Tomaten-Topf',
    hint: 'Ein Topf',
    steps:
        'Rote Linsen mit Dosentomaten und wenig Wasser 12–15 Minuten '
        'garen. Mit Brühe und getrockneten Kräutern würzen.',
    ingredients: ['Linsen', 'Tomaten', 'Brühe'],
  ),
  PrepperRecipe(
    id: 'porridge',
    title: 'Hafer-Porridge',
    hint: 'Warm oder kalt',
    steps:
        'Haferflocken mit H-Milch, Pflanzengetränk oder Wasser anrühren. '
        'Trockenobst, Nüsse und Zimt ergänzen.',
    ingredients: ['Haferflocken', 'Milch', 'Trockenobst'],
  ),
  PrepperRecipe(
    id: 'bean-corn-salad',
    title: 'Bohnen-Mais-Salat',
    hint: 'Ohne Kochen',
    steps:
        'Bohnen und Mais abgießen, mit Öl, Essig, Salz und Kräutern '
        'mischen. Abtropfwasser soweit sinnvoll weiterverwenden.',
    ingredients: ['Bohnen', 'Mais', 'Öl', 'Essig'],
  ),
  PrepperRecipe(
    id: 'tuna-pasta',
    title: 'Thunfisch-Nudel-Topf',
    hint: 'Ein Topf',
    steps:
        'Nudeln in knapp bemessenem Wasser garen. Thunfisch, Erbsen aus '
        'der Dose und Gewürze untermischen.',
    ingredients: ['Nudeln', 'Thunfisch', 'Erbsen'],
  ),
  // Die vier hier sind nach den Vorratsgruppen der BLE ausgesucht und
  // nicht nach Geschmack: die fuenf darueber decken Getreide, Gemuese
  // und Eiweiss ab und lassen Obst und Milch fast leer. Ein
  // Rezeptvorschlag, der dreimal dasselbe Regal leerraeumt, hilft dem
  // Vorrat nicht.
  PrepperRecipe(
    id: 'milk-rice',
    title: 'Milchreis mit Trockenobst',
    hint: 'Kaum Hitze',
    steps:
        'Milchreis aus der Dose erwärmen oder kalt löffeln. Rosinen, '
        'getrocknete Aprikosen oder Apfelmus unterrühren, Zimt darüber.',
    ingredients: ['Milchreis', 'Trockenobst', 'Zimt'],
  ),
  PrepperRecipe(
    id: 'potato-veg-pan',
    title: 'Kartoffel-Gemüse-Pfanne',
    hint: 'Eine Pfanne',
    steps:
        'Kartoffeln aus dem Glas abgießen und würfeln. Mit Öl anbraten, '
        'Dosengemüse dazugeben, mit Salz, Pfeffer und Kräutern würzen.',
    ingredients: ['Kartoffeln', 'Gemüse', 'Öl'],
  ),
  PrepperRecipe(
    id: 'canned-stew',
    title: 'Dosen-Eintopf mit Wurst',
    hint: 'Ein Topf',
    steps:
        'Gemüsekonserven mit ihrem Sud erwärmen. Dosenwurst in Scheiben '
        'dazugeben und ziehen lassen. Mit Brühe abschmecken.',
    ingredients: ['Gemüse', 'Wurst', 'Brühe'],
  ),
  PrepperRecipe(
    id: 'bread-soup',
    title: 'Brotsuppe',
    hint: 'Ein Topf, verwertet altes Brot',
    steps:
        'Altbackenes Brot in Würfel schneiden. In heißer Brühe einweichen, '
        'Zwiebel und Öl dazu, kurz ziehen lassen.',
    ingredients: ['Brot', 'Brühe', 'Zwiebel', 'Öl'],
  ),
];

/// Not the German list in English: the same question asked of a store
/// cupboard that holds baked beans, corned beef and split peas.
///
/// The hint says what it costs to cook, because in a power cut that is
/// what decides between two dishes.
const prepperRecipesEn = [
  PrepperRecipe(
    id: 'beans-on-toast',
    title: 'Beans on toast',
    hint: 'One pan, or none',
    steps:
        'Warm a tin of baked beans. Toast bread over whatever heat there '
        'is, or spoon the beans straight onto crackers or flatbread.',
    ingredients: ['baked beans', 'bread'],
  ),
  PrepperRecipe(
    id: 'corned-beef-hash',
    title: 'Corned beef hash',
    hint: 'One pan',
    steps:
        'Fry drained tinned potatoes until they colour, break in tinned '
        'corned beef and press flat. Pepper and a dash of Worcestershire '
        'sauce; tinned peas alongside.',
    ingredients: ['corned beef', 'potato', 'onion'],
  ),
  PrepperRecipe(
    id: 'curried-chickpeas',
    title: 'Curried chickpeas with rice',
    hint: 'One pot',
    steps:
        'Let curry powder sizzle in oil for a moment, add chickpeas and '
        'chopped tomatoes with the juice from the tin, simmer ten minutes. '
        'Rice cooked in measured water alongside.',
    ingredients: ['chickpeas', 'rice', 'curry'],
  ),
  PrepperRecipe(
    id: 'tuna-sweetcorn',
    title: 'Tuna and sweetcorn on crackers',
    hint: 'No cooking',
    steps:
        'Drain tuna and sweetcorn, mix with mayonnaise or oil and plenty '
        'of black pepper. An opened jar of mayonnaise needs cold storage, '
        'so use oil when the power is out.',
    ingredients: ['tuna', 'sweetcorn', 'crackers'],
  ),
  PrepperRecipe(
    id: 'soda-bread',
    title: 'Soda bread in a pan',
    hint: 'Needs steady heat',
    steps:
        'Mix flour, bicarbonate of soda and salt with long-life buttermilk, '
        'or with milk soured by a spoon of vinegar. Shape flat, cut a '
        'cross, bake in a covered heavy pan over low heat and turn once. '
        'No yeast and no proving time.',
    ingredients: ['flour', 'bicarbonate of soda', 'milk'],
  ),
  PrepperRecipe(
    id: 'pea-ham-soup',
    title: 'Split pea and ham soup',
    hint: 'One pot, long simmer',
    steps:
        'Simmer dried split peas in plenty of water until they collapse, '
        'about an hour. Stir in tinned ham and a stock cube. The hour costs '
        'fuel, so cook enough for two meals at once.',
    ingredients: ['split peas', 'ham', 'stock'],
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
