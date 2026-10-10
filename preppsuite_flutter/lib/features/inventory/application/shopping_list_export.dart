/// The shopping list as a file another app can read (#155).
///
/// Copying the list gives text for a person. A family shopping app wants
/// the lines one by one, each with its amount, to put on a list of its
/// own and sort into aisles -- something it can only guess back out of
/// prose. This is that file; `docs/einkaufsliste-format.md` describes it
/// for whoever reads it.
///
/// Two lists write it: the items under their minimum (`origin`
/// `minimums`), and what a stretch without power and water is short of
/// (`scenario`, #149; see `scenario_export.dart`).
library;

import 'dart:convert';

import 'shopping_list.dart';

/// What the file calls itself, so a reader can tell it from any other
/// JSON before trusting a single field.
const shoppingListFileFormat = 'preppsuite-einkaufsliste';

/// Raised only for a change a reader of version 1 would misread. Fields
/// may be added without it.
const shoppingListFileVersion = 1;

/// The file's name, dated so that two exports do not overwrite each other
/// in a downloads folder and the older one can be told apart.
String shoppingListFileName(DateTime now) {
  String two(int value) => value.toString().padLeft(2, '0');
  return 'preppsuite-einkaufsliste-'
      '${now.year}-${two(now.month)}-${two(now.day)}.json';
}

/// One line to buy, whatever list it came from.
class ShoppingFileLine {
  const ShoppingFileLine({
    required this.name,
    required this.amount,
    required this.unit,
    required this.supplyCategory,
    this.minimum,
  });

  final String name;

  /// How much is missing, in [unit].
  final double amount;
  final String unit;

  /// An `InventoryItemCategory` name.
  final String supplyCategory;

  /// The minimum the amount was worked out against, where there is one.
  final double? minimum;
}

/// Writes [lines] as JSON.
///
/// Each line carries its amount twice: as `amount` and `unit` for a
/// program that computes, and as `quantity`, already formatted with
/// [formatAmount] in the language the app is showing, for a program that
/// only displays it -- a shopping app's quantity field is usually free
/// text, and "1,5 kg" is what belongs there in German.
///
/// [extra] goes in beside the lines: what is true of the whole list
/// rather than of one line.
String buildShoppingFile({
  required String origin,
  required List<ShoppingFileLine> lines,
  required DateTime now,
  required String language,
  required String Function(double amount) formatAmount,
  Map<String, Object?> extra = const {},
}) {
  final document = <String, Object?>{
    'format': shoppingListFileFormat,
    'version': shoppingListFileVersion,
    'origin': origin,
    'created': now.toUtc().toIso8601String(),
    'language': language,
    'items': [
      for (final line in lines)
        {
          'name': line.name,
          'quantity': _quantity(formatAmount(line.amount), line.unit),
          'amount': plainNumber(line.amount),
          'unit': line.unit,
          if (line.minimum != null) 'minimum': plainNumber(line.minimum!),
          'supplyCategory': line.supplyCategory,
        },
    ],
    ...extra,
  };
  return '${const JsonEncoder.withIndent('  ').convert(document)}\n';
}

/// Writes [list] -- the items under their minimum.
///
/// The household target goes along under `target`, apart from the lines.
/// "12 l of water still missing" is true of the household, not of any one
/// item, and an item short of its own minimum already counts towards it:
/// adding both to a basket would buy the same water twice.
String buildShoppingListFile(
  ShoppingList list, {
  required DateTime now,
  required String language,
  required String Function(double amount) formatAmount,
}) => buildShoppingFile(
  origin: 'minimums',
  lines: [
    for (final entry in list.entries)
      ShoppingFileLine(
        name: entry.item.name,
        amount: entry.shortfall,
        unit: entry.item.unit,
        minimum: entry.item.minQuantity,
        supplyCategory: entry.item.category,
      ),
  ],
  now: now,
  language: language,
  formatAmount: formatAmount,
  extra: {
    'target': {
      'days': list.days,
      'met': list.targetMet,
      'waterLiters': plainNumber(list.waterShortfallLiters),
      'kcal': list.calorieShortfall,
    },
  },
);

String _quantity(String amount, String unit) =>
    unit.trim().isEmpty ? amount : '$amount ${unit.trim()}';

/// A whole number as an integer, so a reader sees `6` and not `6.0`;
/// anything else to two places, which is finer than any unit a household
/// buys in and keeps float noise like 0.30000000000000004 out of the file.
num plainNumber(double value) {
  final rounded = (value * 100).roundToDouble() / 100;
  return rounded == rounded.roundToDouble() ? rounded.round() : rounded;
}
