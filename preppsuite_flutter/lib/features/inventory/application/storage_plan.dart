/// The official German stockpiling tables, transcribed.
///
/// The BBK's own "Bevorraten" page gives two numbers — ten days, and 1.5 +
/// 0.5 litres of water a day — and then points at the BLE's
/// *Vorratstabellen* for everything else. Those tables are the source
/// here: one basic supply for one person and ten days at an average
/// 2,200 kcal a day, once as a mixed diet and once ovo-lacto-vegetarian.
///
/// The rows below are a citation, not the app's advice. Amounts and
/// energy figures are exactly as printed; nothing is rounded, averaged or
/// filled in where the table is silent. The one thing the app adds is
/// [StorageNutrient], and it says so on screen.
///
/// There is no official vegan table. The BLE publishes these two and no
/// third, so the app does not print one; the screen names the rows a
/// vegan household has to replace instead of inventing amounts for them.
///
/// Source: Bundesanstalt für Landwirtschaft und Ernährung (BLE), 2024,
/// "Vorratstabelle" and "Vorratstabelle vegetarisch"
/// (ernaehrungsvorsorge.de). Energy values from the
/// Bundeslebensmittelschlüssel (BLS) 3.02, Max Rubner-Institut, 2014;
/// amounts derived from the DGE/ÖGE/SGE reference values (2015).
library;

/// The two diets the BLE publishes a table for.
enum StorageDiet { mixed, vegetarian }

/// How an amount is measured. The tables mix all three, and the
/// difference matters when scaling: five eggs for two people is ten eggs,
/// not "10 g".
enum StorageUnit { gram, liter, piece }

/// What a food contributes, in the terms a household actually plans in.
///
/// **This is the app's own tagging, not the BLE's.** Their table has no
/// nutrient column; these mark the well-known main contribution of each
/// food so that someone leaving out a whole group — meat, or milk and
/// eggs — can see what leaves with it. They are orientation, not
/// nutritional advice, and the screen says so.
enum StorageNutrient { protein, fiber, iron, vitaminB12, healthyFats, fluid }

/// One line of a table. [amount] and [totalKcal] are per person and ten
/// days, as printed.
class StorageFood {
  const StorageFood({
    required this.name,
    required this.nameEn,
    required this.amount,
    required this.unit,
    this.kcalPer100,
    this.totalKcal,
    this.note,
    this.noteEn,
    this.nutrients = const {},
    this.variants = const [],
  });

  final String name;
  final String nameEn;
  final double amount;
  final StorageUnit unit;

  /// Energy per 100 g or 100 ml. Null where the table leaves it blank
  /// (coffee powder and tea, which are brewed rather than eaten) or where
  /// the row is only a heading for its [variants].
  final int? kcalPer100;

  /// Energy for the whole [amount], as printed. Deliberately taken from
  /// the table rather than recomputed: the printed value is what the
  /// source stands behind.
  final int? totalKcal;

  /// The table's own "Bemerkung" column — "Abtropfgewicht", "geschält".
  final String? note;
  final String? noteEn;

  final Set<StorageNutrient> nutrients;

  /// Interchangeable choices for the same row, each with its own energy —
  /// the table prints one amount of "Frischobst" and then four fruits it
  /// could be. Picking one is the household's business, so they are
  /// offered rather than summed.
  final List<StorageVariant> variants;
}

/// One of the interchangeable options under a [StorageFood].
class StorageVariant {
  const StorageVariant({
    required this.name,
    required this.nameEn,
    required this.kcalPer100,
    required this.totalKcal,
    this.nutrients = const {},
  });

  final String name;
  final String nameEn;
  final int kcalPer100;
  final int totalKcal;
  final Set<StorageNutrient> nutrients;
}

/// A food group with the total the table gives it.
class StorageGroup {
  const StorageGroup({
    required this.name,
    required this.nameEn,
    required this.totalAmount,
    required this.totalUnit,
    required this.foods,
    this.footnote,
    this.footnoteEn,
  });

  final String name;
  final String nameEn;

  /// The group total as printed — "3,3 kg", "4,0 kg", "20 l". Kept
  /// separate from the sum of [foods], and not derived from it, because
  /// the two do **not** agree: the BLE rounds its group totals to the
  /// hundred grams while the rows are given to the ten, so the grain
  /// group's rows come to 3,310 g under a printed 3,300 and the fruit
  /// group's to 2,460 under 2,500.
  ///
  /// That is the source's own rounding and not a transcription error, but
  /// it is also exactly why a computed sum would be wrong to show: it
  /// would quietly replace the citation with this app's arithmetic, and a
  /// real mistyped row would then look like more of the same rounding.
  final double totalAmount;
  final StorageUnit totalUnit;

  final List<StorageFood> foods;

  /// The table's own footnote for this group, where it has one.
  final String? footnote;
  final String? footnoteEn;
}

/// A whole table: one person, ten days.
class StoragePlan {
  const StoragePlan({required this.diet, required this.groups});

  final StorageDiet diet;
  final List<StorageGroup> groups;

  /// What the table is built for. Scaling multiplies against these.
  static const basePeople = 1;
  static const baseDays = 10;

  /// Energy the whole table adds up to, for the "≈ 2,200 kcal a day"
  /// claim on screen. Rows without a printed total (coffee, tea, water)
  /// contribute nothing; rows that are only a heading contribute their
  /// first variant, which is the table's own leading example.
  int get totalKcal => groups.fold(
    0,
    (sum, group) =>
        sum +
        group.foods.fold(
          0,
          (inner, food) =>
              inner +
              (food.totalKcal ?? food.variants.firstOrNull?.totalKcal ?? 0),
        ),
  );
}

/// Scales an amount from one person and ten days to a real household.
///
/// Linear, which is what the table itself invites — it is a per-person
/// daily ration written out ten times. Piece counts are rounded up: half
/// an egg is not a thing you can put on a shelf, and rounding down would
/// quietly under-stock.
double scaleAmount(double amount, StorageUnit unit, int people, int days) {
  final scaled =
      amount * people * days / (StoragePlan.basePeople * StoragePlan.baseDays);
  return unit == StorageUnit.piece ? scaled.ceilToDouble() : scaled;
}

/// Groups shared by both tables. The two BLE tables are identical except
/// for the protein group, so keeping one copy is also what guarantees
/// they cannot drift apart in a later edit.
const _sharedGroups = <StorageGroup>[
  StorageGroup(
    name: 'Getreideprodukte, Brot, Kartoffeln',
    nameEn: 'Grain products, bread, potatoes',
    totalAmount: 3300,
    totalUnit: StorageUnit.gram,
    foods: [
      StorageFood(
        name: 'Vollkornbrot, abgepackt',
        nameEn: 'Wholemeal bread, packaged',
        amount: 710,
        unit: StorageUnit.gram,
        kcalPer100: 213,
        totalKcal: 1512,
        nutrients: {StorageNutrient.fiber},
      ),
      StorageFood(
        name: 'Zwieback',
        nameEn: 'Rusk',
        amount: 180,
        unit: StorageUnit.gram,
        kcalPer100: 385,
        totalKcal: 693,
      ),
      StorageFood(
        name: 'Knäckebrot',
        nameEn: 'Crispbread',
        amount: 710,
        unit: StorageUnit.gram,
        kcalPer100: 349,
        totalKcal: 2478,
        nutrients: {StorageNutrient.fiber},
      ),
      StorageFood(
        name: 'Nudeln, roh',
        nameEn: 'Pasta, uncooked',
        amount: 280,
        unit: StorageUnit.gram,
        kcalPer100: 357,
        totalKcal: 1000,
      ),
      StorageFood(
        name: 'Reis, roh',
        nameEn: 'Rice, uncooked',
        amount: 180,
        unit: StorageUnit.gram,
        kcalPer100: 355,
        totalKcal: 639,
      ),
      StorageFood(
        name: 'Hafer-/Getreideflocken',
        nameEn: 'Oat and cereal flakes',
        amount: 540,
        unit: StorageUnit.gram,
        kcalPer100: 373,
        totalKcal: 2014,
        nutrients: {
          StorageNutrient.fiber,
          StorageNutrient.iron,
          StorageNutrient.protein,
        },
      ),
      StorageFood(
        name: 'Kartoffeln, roh',
        nameEn: 'Potatoes, raw',
        amount: 710,
        unit: StorageUnit.gram,
        kcalPer100: 76,
        totalKcal: 540,
        note: 'geschält',
        noteEn: 'peeled',
      ),
    ],
  ),
  StorageGroup(
    name: 'Gemüse, Pilze',
    nameEn: 'Vegetables, mushrooms',
    totalAmount: 4000,
    totalUnit: StorageUnit.gram,
    footnote:
        'Statt Bohnen und Erbsen gehen auch andere Hülsenfrüchte, '
        'zum Beispiel Kichererbsen, Linsen oder Lupinen.',
    footnoteEn:
        'Other pulses work in place of beans and peas — chickpeas, '
        'lentils or lupins, for instance.',
    foods: [
      StorageFood(
        name: 'Bohnen grün, Konserve',
        nameEn: 'Green beans, canned',
        amount: 570,
        unit: StorageUnit.gram,
        kcalPer100: 21,
        totalKcal: 120,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
        nutrients: {StorageNutrient.fiber, StorageNutrient.protein},
      ),
      StorageFood(
        name: 'Erbsen/Möhren, Konserve',
        nameEn: 'Peas and carrots, canned',
        amount: 640,
        unit: StorageUnit.gram,
        kcalPer100: 55,
        totalKcal: 352,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
        nutrients: {
          StorageNutrient.fiber,
          StorageNutrient.protein,
          StorageNutrient.iron,
        },
      ),
      StorageFood(
        name: 'Rotkohl, Konserve',
        nameEn: 'Red cabbage, canned',
        amount: 500,
        unit: StorageUnit.gram,
        kcalPer100: 60,
        totalKcal: 300,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
        nutrients: {StorageNutrient.fiber},
      ),
      StorageFood(
        name: 'Sauerkraut, Konserve',
        nameEn: 'Sauerkraut, canned',
        amount: 500,
        unit: StorageUnit.gram,
        kcalPer100: 21,
        totalKcal: 105,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
        nutrients: {StorageNutrient.fiber},
      ),
      StorageFood(
        name: 'Spargel, Konserve',
        nameEn: 'Asparagus, canned',
        amount: 290,
        unit: StorageUnit.gram,
        kcalPer100: 18,
        totalKcal: 52,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Mais, Konserve',
        nameEn: 'Sweetcorn, canned',
        amount: 290,
        unit: StorageUnit.gram,
        kcalPer100: 81,
        totalKcal: 235,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
        nutrients: {StorageNutrient.fiber},
      ),
      StorageFood(
        name: 'Pilze, Konserve',
        nameEn: 'Mushrooms, canned',
        amount: 290,
        unit: StorageUnit.gram,
        kcalPer100: 36,
        totalKcal: 104,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Saure Gurken, Konserve',
        nameEn: 'Pickled gherkins, jarred',
        amount: 290,
        unit: StorageUnit.gram,
        kcalPer100: 11,
        totalKcal: 32,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Rote Bete, Konserve',
        nameEn: 'Beetroot, canned',
        amount: 290,
        unit: StorageUnit.gram,
        kcalPer100: 36,
        totalKcal: 104,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Zwiebeln, frisch',
        nameEn: 'Onions, fresh',
        amount: 360,
        unit: StorageUnit.gram,
        kcalPer100: 30,
        totalKcal: 108,
      ),
    ],
  ),
  StorageGroup(
    name: 'Obst',
    nameEn: 'Fruit',
    totalAmount: 2500,
    totalUnit: StorageUnit.gram,
    foods: [
      StorageFood(
        name: 'Kirschen, Konserve',
        nameEn: 'Cherries, canned',
        amount: 400,
        unit: StorageUnit.gram,
        kcalPer100: 87,
        totalKcal: 348,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Birnen, Konserve',
        nameEn: 'Pears, canned',
        amount: 180,
        unit: StorageUnit.gram,
        kcalPer100: 69,
        totalKcal: 124,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Aprikosen, Konserve',
        nameEn: 'Apricots, canned',
        amount: 180,
        unit: StorageUnit.gram,
        kcalPer100: 70,
        totalKcal: 126,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Mandarinen, Konserve',
        nameEn: 'Mandarins, canned',
        amount: 250,
        unit: StorageUnit.gram,
        kcalPer100: 86,
        totalKcal: 215,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Ananas, Konserve',
        nameEn: 'Pineapple, canned',
        amount: 250,
        unit: StorageUnit.gram,
        kcalPer100: 69,
        totalKcal: 173,
        note: 'Abtropfgewicht',
        noteEn: 'drained weight',
      ),
      StorageFood(
        name: 'Rosinen',
        nameEn: 'Raisins',
        amount: 140,
        unit: StorageUnit.gram,
        kcalPer100: 314,
        totalKcal: 440,
        nutrients: {StorageNutrient.fiber, StorageNutrient.iron},
      ),
      StorageFood(
        name: 'Haselnusskerne',
        nameEn: 'Hazelnut kernels',
        amount: 100,
        unit: StorageUnit.gram,
        kcalPer100: 664,
        totalKcal: 664,
        nutrients: {
          StorageNutrient.healthyFats,
          StorageNutrient.protein,
          StorageNutrient.fiber,
        },
      ),
      StorageFood(
        name: 'Trockenpflaumen',
        nameEn: 'Prunes',
        amount: 250,
        unit: StorageUnit.gram,
        kcalPer100: 252,
        totalKcal: 630,
        nutrients: {StorageNutrient.fiber, StorageNutrient.iron},
      ),
      StorageFood(
        name: 'Frischobst',
        nameEn: 'Fresh fruit',
        amount: 710,
        unit: StorageUnit.gram,
        variants: [
          StorageVariant(
            name: 'Apfel, roh',
            nameEn: 'Apple, raw',
            kcalPer100: 65,
            totalKcal: 462,
          ),
          StorageVariant(
            name: 'Birne, roh',
            nameEn: 'Pear, raw',
            kcalPer100: 58,
            totalKcal: 412,
          ),
          StorageVariant(
            name: 'Banane, roh',
            nameEn: 'Banana, raw',
            kcalPer100: 93,
            totalKcal: 660,
          ),
          StorageVariant(
            name: 'Orange, roh',
            nameEn: 'Orange, raw',
            kcalPer100: 47,
            totalKcal: 334,
          ),
        ],
      ),
    ],
  ),
  StorageGroup(
    name: 'Getränke',
    nameEn: 'Drinks',
    totalAmount: 20,
    totalUnit: StorageUnit.liter,
    footnote:
        'In den 20 Litern stecken 1,5 Liter Trinken am Tag und 0,5 Liter '
        'zum Kochen von Nudeln, Kartoffeln und Reis. Ab 65 Jahren '
        'empfiehlt die DGE 2 Liter am Tag, Kinder bis 12 Jahre '
        '(keine Säuglinge) brauchen im Schnitt 1 Liter.',
    footnoteEn:
        'The 20 litres are 1.5 litres of drinking a day plus 0.5 litres '
        'for cooking the pasta, potatoes and rice above. From 65 the DGE '
        'recommends 2 litres a day; children up to 12 (not infants) '
        'average 1 litre.',
    foods: [
      StorageFood(
        name: 'Mineralwasser',
        nameEn: 'Mineral water',
        amount: 20,
        unit: StorageUnit.liter,
        kcalPer100: 0,
        totalKcal: 0,
        nutrients: {StorageNutrient.fluid},
      ),
      StorageFood(
        name: 'Zitronensaft',
        nameEn: 'Lemon juice',
        amount: 0.14,
        unit: StorageUnit.liter,
        kcalPer100: 38,
        totalKcal: 53,
        nutrients: {StorageNutrient.fluid},
      ),
      StorageFood(
        name: 'Kaffee (Pulver), Instantkaffee',
        nameEn: 'Coffee (ground), instant coffee',
        amount: 180,
        unit: StorageUnit.gram,
        note: 'zubereitet 150 ml ≈ 3 kcal',
        noteEn: 'brewed, 150 ml ≈ 3 kcal',
      ),
      StorageFood(
        name: 'Tee schwarz, trocken',
        nameEn: 'Black tea, dry',
        amount: 90,
        unit: StorageUnit.gram,
        note: 'zubereitet 150 ml ≈ 0 kcal',
        noteEn: 'brewed, 150 ml ≈ 0 kcal',
      ),
    ],
  ),
  StorageGroup(
    name: 'Milch und Milcherzeugnisse',
    nameEn: 'Milk and dairy',
    totalAmount: 2500,
    totalUnit: StorageUnit.gram,
    foods: [
      StorageFood(
        name: 'H-Milch, 3,5 % Fett',
        nameEn: 'UHT milk, 3.5% fat',
        amount: 2,
        unit: StorageUnit.liter,
        kcalPer100: 66,
        totalKcal: 1320,
        nutrients: {
          StorageNutrient.protein,
          StorageNutrient.vitaminB12,
          StorageNutrient.fluid,
        },
      ),
      StorageFood(
        name: 'Hartkäse',
        nameEn: 'Hard cheese',
        amount: 500,
        unit: StorageUnit.gram,
        kcalPer100: 378,
        totalKcal: 1890,
        nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
      ),
    ],
  ),
];

const _fatsGroup = StorageGroup(
  name: 'Fette, Öl',
  nameEn: 'Fats, oil',
  totalAmount: 330,
  totalUnit: StorageUnit.gram,
  foods: [
    StorageFood(
      name: 'Streichfett',
      nameEn: 'Spreadable fat',
      amount: 180,
      unit: StorageUnit.gram,
      variants: [
        StorageVariant(
          name: 'Butter',
          nameEn: 'Butter',
          kcalPer100: 741,
          totalKcal: 1334,
        ),
        StorageVariant(
          name: 'Margarine',
          nameEn: 'Margarine',
          kcalPer100: 709,
          totalKcal: 1276,
        ),
      ],
    ),
    StorageFood(
      name: 'Speiseöl (z. B. Rapsöl)',
      nameEn: 'Cooking oil (e.g. rapeseed)',
      amount: 0.15,
      unit: StorageUnit.liter,
      kcalPer100: 884,
      totalKcal: 1326,
      nutrients: {StorageNutrient.healthyFats},
    ),
  ],
);

const _mixedProteinGroup = StorageGroup(
  name: 'Eier, Fleisch, Wurst und Fisch',
  nameEn: 'Eggs, meat, sausage and fish',
  totalAmount: 1200,
  totalUnit: StorageUnit.gram,
  foods: [
    StorageFood(
      name: 'Thunfisch, Konserve ohne Öl',
      nameEn: 'Tuna, canned without oil',
      amount: 165,
      unit: StorageUnit.gram,
      kcalPer100: 100,
      totalKcal: 165,
      note: 'Abtropfgewicht',
      noteEn: 'drained weight',
      nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
    ),
    StorageFood(
      name: 'Ölsardinen, Konserve',
      nameEn: 'Sardines in oil, canned',
      amount: 50,
      unit: StorageUnit.gram,
      kcalPer100: 221,
      totalKcal: 111,
      note: 'Abtropfgewicht',
      noteEn: 'drained weight',
      nutrients: {
        StorageNutrient.protein,
        StorageNutrient.vitaminB12,
        StorageNutrient.healthyFats,
      },
    ),
    StorageFood(
      name: 'Heringsfilet in Soße, Konserve',
      nameEn: 'Herring fillet in sauce, canned',
      amount: 50,
      unit: StorageUnit.gram,
      kcalPer100: 204,
      totalKcal: 102,
      note: 'Abtropfgewicht',
      noteEn: 'drained weight',
      nutrients: {
        StorageNutrient.protein,
        StorageNutrient.vitaminB12,
        StorageNutrient.healthyFats,
      },
    ),
    StorageFood(
      name: 'Corned Beef, Konserve',
      nameEn: 'Corned beef, canned',
      amount: 160,
      unit: StorageUnit.gram,
      kcalPer100: 141,
      totalKcal: 226,
      nutrients: {
        StorageNutrient.protein,
        StorageNutrient.vitaminB12,
        StorageNutrient.iron,
      },
    ),
    StorageFood(
      name: 'Kalbsleberwurst, Konserve',
      nameEn: 'Veal liver sausage, canned',
      amount: 160,
      unit: StorageUnit.gram,
      kcalPer100: 345,
      totalKcal: 552,
      nutrients: {
        StorageNutrient.protein,
        StorageNutrient.vitaminB12,
        StorageNutrient.iron,
      },
    ),
    StorageFood(
      name: 'Dauerwurst (z. B. Salami)',
      nameEn: 'Cured sausage (e.g. salami)',
      amount: 160,
      unit: StorageUnit.gram,
      kcalPer100: 371,
      totalKcal: 594,
      nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
    ),
    StorageFood(
      name: 'Bockwürstchen, Konserve',
      nameEn: 'Bockwurst sausages, canned',
      amount: 160,
      unit: StorageUnit.gram,
      kcalPer100: 271,
      totalKcal: 434,
      note: 'Abtropfgewicht',
      noteEn: 'drained weight',
      nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
    ),
    StorageFood(
      name: 'Eier (Gewichtsklasse M)',
      nameEn: 'Eggs (size M)',
      amount: 5,
      unit: StorageUnit.piece,
      kcalPer100: 137,
      totalKcal: 363,
      note: 'je Ei etwa 53 g ohne Schale',
      noteEn: 'about 53 g each without the shell',
      nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
    ),
  ],
);

const _vegetarianProteinGroup = StorageGroup(
  name: 'Eier, Ersatzprodukte für Fleisch, Wurst und Fisch',
  nameEn: 'Eggs and substitutes for meat, sausage and fish',
  totalAmount: 1300,
  totalUnit: StorageUnit.gram,
  foods: [
    StorageFood(
      name: 'Tofu',
      nameEn: 'Tofu',
      amount: 200,
      unit: StorageUnit.gram,
      kcalPer100: 167,
      totalKcal: 334,
      nutrients: {StorageNutrient.protein, StorageNutrient.iron},
    ),
    StorageFood(
      name: 'Vegetarische Bratlinge',
      nameEn: 'Vegetarian patties',
      amount: 150,
      unit: StorageUnit.gram,
      kcalPer100: 230,
      totalKcal: 345,
      nutrients: {StorageNutrient.protein},
    ),
    StorageFood(
      name: 'Vegetarische Wurst und Würstchen',
      nameEn: 'Vegetarian sausages',
      amount: 230,
      unit: StorageUnit.gram,
      kcalPer100: 222,
      totalKcal: 511,
      nutrients: {StorageNutrient.protein},
    ),
    StorageFood(
      name: 'Vegetarischer pikanter Brotaufstrich',
      nameEn: 'Vegetarian savoury spread',
      amount: 250,
      unit: StorageUnit.gram,
      kcalPer100: 228,
      totalKcal: 570,
      nutrients: {StorageNutrient.protein},
    ),
    StorageFood(
      name: 'Vegetarische Salami',
      nameEn: 'Vegetarian salami',
      amount: 200,
      unit: StorageUnit.gram,
      kcalPer100: 257,
      totalKcal: 514,
      nutrients: {StorageNutrient.protein},
    ),
    StorageFood(
      name: 'Eier (Gewichtsklasse M)',
      nameEn: 'Eggs (size M)',
      amount: 5,
      unit: StorageUnit.piece,
      kcalPer100: 137,
      totalKcal: 363,
      note: 'je Ei etwa 53 g ohne Schale',
      noteEn: 'about 53 g each without the shell',
      nutrients: {StorageNutrient.protein, StorageNutrient.vitaminB12},
    ),
  ],
);

/// The table for [diet], in the order the BLE prints it.
StoragePlan storagePlanFor(StorageDiet diet) => StoragePlan(
  diet: diet,
  groups: [
    ..._sharedGroups,
    switch (diet) {
      StorageDiet.mixed => _mixedProteinGroup,
      StorageDiet.vegetarian => _vegetarianProteinGroup,
    },
    _fatsGroup,
  ],
);
