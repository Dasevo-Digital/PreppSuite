/// A package an item comes in — "Glas à 370 g" — and the arithmetic
/// between packages and the item's own unit.
///
/// The stock is always stored in the item's unit, and for food that unit
/// is a measure (`food_amount.dart`): the supply calculator multiplies
/// the label's per-100 figure by it, so consuming 370 g takes 370 g worth
/// of calories off the total. The package is only a second way to *say*
/// an amount at the shelf, where nobody weighs what they took out.
library;

import '../../../local_db/database.dart';

/// One named package and what it holds, in the item's unit.
class ItemPackage {
  const ItemPackage({required this.name, required this.size});

  /// "Glas", "Dose", "Stück" — exactly as the household typed it.
  final String name;

  /// How much one package holds, in the item's unit. Always above zero.
  final double size;

  /// The package an item names, or null.
  ///
  /// A half-filled pair is treated as none: a name without a size cannot
  /// convert anything, and a size without a name cannot be shown. The
  /// form refuses both, so this only meets them in a damaged row.
  static ItemPackage? of(InventoryItem item) =>
      from(item.packageName, item.packageSize);

  /// The same rule for two loose values, as the form holds them.
  static ItemPackage? from(String? name, double? size) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty || size == null || !size.isFinite || size <= 0) {
      return null;
    }
    return ItemPackage(name: trimmed, size: size);
  }

  /// [packages] of these, in the item's unit.
  double toUnits(double packages) => packages * size;

  /// [units] of the item, in packages.
  double toPackages(double units) => units / size;
}

/// How many packages a stock is, for the inventory list: "3 × Glas" or
/// "≈ 2,5 × Glas".
///
/// Rounded to one decimal, and marked as approximate whenever that
/// rounding changed anything — 1110 g in jars of 370 g is three jars, but
/// 1000 g is 2.7 of them and saying "2,7" without the "≈" would claim a
/// precision a half-eaten jar does not have.
({double count, bool exact}) packageCount(double quantity, ItemPackage pkg) {
  final raw = pkg.toPackages(quantity);
  final rounded = (raw * 10).round() / 10;
  return (count: rounded, exact: (raw - rounded).abs() < 1e-9);
}
