/// The BLE tables' words in Spanish (#108), keyed by the German original.
///
/// A map beside the tables rather than a third name on every row: the
/// rows in `storage_plan.dart` are a transcription to be checked against
/// the printed source, and every field added to them is one more thing in
/// the way of that check. Keyed by the German text, so a test can hold
/// this list against every name, remark and footnote the tables carry —
/// a row added there without a Spanish name here fails, rather than
/// quietly showing up in English.
///
/// Amounts, units and energy values are not in here: they are numbers,
/// formatted for the reader's locale, and nothing about them changes in
/// translation.
library;

const storagePlanSpanish = <String, String>{
  // Groups.
  'Getreideprodukte, Brot, Kartoffeln': 'Cereales, pan, patatas',
  'Gemüse, Pilze': 'Verduras, setas',
  'Obst': 'Fruta',
  'Getränke': 'Bebidas',
  'Milch und Milcherzeugnisse': 'Leche y lácteos',
  'Fette, Öl': 'Grasas, aceite',
  'Eier, Fleisch, Wurst und Fisch': 'Huevos, carne, embutido y pescado',
  'Eier, Ersatzprodukte für Fleisch, Wurst und Fisch':
      'Huevos y sustitutos de carne, embutido y pescado',

  // Grain products, bread, potatoes.
  'Vollkornbrot, abgepackt': 'Pan integral, envasado',
  'Zwieback': 'Biscotes',
  'Knäckebrot': 'Pan crujiente de centeno',
  'Nudeln, roh': 'Pasta, cruda',
  'Reis, roh': 'Arroz, crudo',
  'Hafer-/Getreideflocken': 'Copos de avena o de cereales',
  'Kartoffeln, roh': 'Patatas, crudas',

  // Vegetables, mushrooms.
  'Bohnen grün, Konserve': 'Judías verdes, en conserva',
  'Erbsen/Möhren, Konserve': 'Guisantes y zanahorias, en conserva',
  'Rotkohl, Konserve': 'Lombarda, en conserva',
  'Sauerkraut, Konserve': 'Chucrut, en conserva',
  'Spargel, Konserve': 'Espárragos, en conserva',
  'Mais, Konserve': 'Maíz dulce, en conserva',
  'Pilze, Konserve': 'Setas, en conserva',
  'Saure Gurken, Konserve': 'Pepinillos en vinagre, en tarro',
  'Rote Bete, Konserve': 'Remolacha, en conserva',
  'Zwiebeln, frisch': 'Cebollas, frescas',

  // Fruit.
  'Kirschen, Konserve': 'Cerezas, en conserva',
  'Birnen, Konserve': 'Peras, en conserva',
  'Aprikosen, Konserve': 'Albaricoques, en conserva',
  'Mandarinen, Konserve': 'Mandarinas, en conserva',
  'Ananas, Konserve': 'Piña, en conserva',
  'Rosinen': 'Pasas',
  'Haselnusskerne': 'Avellanas peladas',
  'Trockenpflaumen': 'Ciruelas pasas',
  'Frischobst': 'Fruta fresca',
  'Apfel, roh': 'Manzana, cruda',
  'Birne, roh': 'Pera, cruda',
  'Banane, roh': 'Plátano, crudo',
  'Orange, roh': 'Naranja, cruda',

  // Drinks.
  'Mineralwasser': 'Agua mineral',
  'Zitronensaft': 'Zumo de limón',
  'Kaffee (Pulver), Instantkaffee': 'Café (molido), café soluble',
  'Tee schwarz, trocken': 'Té negro, seco',

  // Milk and dairy.
  'H-Milch, 3,5 % Fett': 'Leche UHT, 3,5 % de grasa',
  'Hartkäse': 'Queso duro',

  // Fats, oil.
  'Streichfett': 'Grasa para untar',
  'Butter': 'Mantequilla',
  'Margarine': 'Margarina',
  'Speiseöl (z. B. Rapsöl)': 'Aceite de cocina (p. ej. de colza)',

  // Eggs, meat, sausage and fish.
  'Thunfisch, Konserve ohne Öl': 'Atún, en conserva al natural',
  'Ölsardinen, Konserve': 'Sardinas en aceite, en conserva',
  'Heringsfilet in Soße, Konserve': 'Filetes de arenque en salsa, en conserva',
  'Corned Beef, Konserve': 'Corned beef, en conserva',
  'Kalbsleberwurst, Konserve': 'Paté de hígado de ternera, en conserva',
  'Dauerwurst (z. B. Salami)': 'Embutido curado (p. ej. salami)',
  'Bockwürstchen, Konserve': 'Salchichas tipo Bockwurst, en conserva',
  'Eier (Gewichtsklasse M)': 'Huevos (talla M)',

  // The vegetarian table's own rows.
  'Tofu': 'Tofu',
  'Vegetarische Bratlinge': 'Hamburguesas vegetarianas',
  'Vegetarische Wurst und Würstchen': 'Embutido y salchichas vegetarianos',
  'Vegetarischer pikanter Brotaufstrich': 'Paté vegetal salado para untar',
  'Vegetarische Salami': 'Salami vegetariano',

  // The "Bemerkung" column.
  'geschält': 'peladas',
  'Abtropfgewicht': 'peso escurrido',
  'zubereitet 150 ml ≈ 3 kcal': 'preparado, 150 ml ≈ 3 kcal',
  'zubereitet 150 ml ≈ 0 kcal': 'preparado, 150 ml ≈ 0 kcal',
  'je Ei etwa 53 g ohne Schale': 'unos 53 g por huevo, sin cáscara',

  // Footnotes.
  'Statt Bohnen und Erbsen gehen auch andere Hülsenfrüchte, zum Beispiel '
          'Kichererbsen, Linsen oder Lupinen.':
      'En lugar de judías y guisantes sirven también otras legumbres, por '
      'ejemplo garbanzos, lentejas o altramuces.',
  'In den 20 Litern stecken 1,5 Liter Trinken am Tag und 0,5 Liter zum '
          'Kochen von Nudeln, Kartoffeln und Reis. Ab 65 Jahren empfiehlt die '
          'DGE 2 Liter am Tag, Kinder bis 12 Jahre (keine Säuglinge) brauchen '
          'im Schnitt 1 Liter.':
      'Los 20 litros son 1,5 litros para beber al día y 0,5 litros para '
      'cocer la pasta, las patatas y el arroz. A partir de los 65 años la '
      'DGE (Sociedad Alemana de Nutrición) recomienda 2 litros al día; los '
      'niños de hasta 12 años (no los lactantes) necesitan de media 1 litro.',
};
