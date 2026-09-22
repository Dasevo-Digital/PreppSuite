import 'package:openfoodfacts/openfoodfacts.dart';

import 'package_nutrition.dart';

/// Reads the per-100 figures off a scanned product, and does nothing else
/// to them.
///
/// This used to convert all five to package totals against the free-text
/// package size, and that conversion was the source of every nutrition
/// bug the app has had: a size it could not read zeroed the whole label,
/// a multipack undercounted by the pack size, and the figure it produced
/// meant something different depending on what the household counted in.
///
/// The column holds per 100 now, which is what the label already says, so
/// there is nothing left to convert. The arithmetic happens once, in
/// `supply_calculator.dart`, where the quantity is actually known.
PackageNutrition packageNutritionOf(Nutriments? nutriments) {
  double? per100(Nutrient nutrient) =>
      nutriments?.getValue(nutrient, PerSize.oneHundredGrams);

  return PackageNutrition(
    kcal: per100(Nutrient.energyKCal),
    proteinGrams: per100(Nutrient.proteins),
    carbohydrateGrams: per100(Nutrient.carbohydrates),
    fatGrams: per100(Nutrient.fat),
    fiberGrams: per100(Nutrient.fiber),
  );
}

/// A minimal, prefill-only view of an Open Food Facts product — just enough
/// to seed the inventory item form. The user can freely edit any field
/// afterward, so this deliberately doesn't try to map more than name/brand
/// and what the label says is inside.
class OpenFoodFactsProduct {
  const OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity,
    this.nutrition = const PackageNutrition(),
  });

  final String barcode;
  final String name;
  final String? brand;

  /// Free-text package quantity as reported by Open Food Facts (e.g.
  /// "1.5 l", "500g") — informational only, not parsed into a number/unit.
  final String? quantity;

  /// Energy and macronutrients per 100 g, or per 100 ml on a drink,
  /// exactly as the label states them.
  ///
  /// There used to be a second field beside this holding the raw per-100
  /// energy, because this one carried package totals and the screen had
  /// to redo the conversion from the raw figure. Both the field and the
  /// conversion are gone: this *is* the raw figure, and the inventory
  /// stores it unchanged.
  ///
  /// Mostly empty for non-food supplies, which carry no nutrition data at
  /// all. The supply calculator needs the calorie figure and nobody fills
  /// it in by hand, so getting it from the barcode is what makes that
  /// screen work at all.
  final PackageNutrition nutrition;
}

/// Thin wrapper around the `openfoodfacts` package. Configure once via
/// [configure] at app start.
class OpenFoodFactsService {
  const OpenFoodFactsService();

  static void configure() {
    OpenFoodAPIConfiguration.userAgent = UserAgent(
      name: 'PreppSuite',
      url: 'https://github.com',
    );
    OpenFoodAPIConfiguration.globalLanguages = [OpenFoodFactsLanguage.GERMAN];
  }

  /// Returns `null` if the barcode isn't found (a normal outcome — plenty
  /// of non-food supplies won't be in Open Food Facts at all) or the lookup
  /// fails.
  Future<OpenFoodFactsProduct?> lookup(String barcode) async {
    try {
      final result = await OpenFoodAPIClient.getProductV3(
        ProductQueryConfiguration(
          barcode,
          version: ProductQueryVersion.v3,
          fields: [
            ProductField.NAME,
            ProductField.BRANDS,
            ProductField.QUANTITY,
            ProductField.NUTRIMENTS,
          ],
        ),
      );

      final product = result.product;
      final name = product?.productName;
      if (product == null || name == null || name.isEmpty) return null;

      return OpenFoodFactsProduct(
        barcode: barcode,
        name: name,
        brand: product.brands,
        quantity: product.quantity,
        nutrition: packageNutritionOf(product.nutriments),
      );
    } catch (_) {
      // Network error, timeout, malformed response, etc. — the user can
      // always fall back to filling the form in by hand.
      return null;
    }
  }
}
