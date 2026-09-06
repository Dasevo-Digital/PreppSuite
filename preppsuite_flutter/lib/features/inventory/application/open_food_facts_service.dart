import 'package:openfoodfacts/openfoodfacts.dart';

import 'package_energy.dart';
import 'package_nutrition.dart';

/// Reads the per-100 figures off a scanned product and converts each to
/// a package total against [quantityText].
///
/// A missing package size therefore zeroes everything at once, which is
/// correct: without it there is no way from "per 100 g" to "in this tin",
/// and a per-100 number stored as a package total would be wrong by
/// whatever the package weighs.
PackageNutrition packageNutritionOf(
  Nutriments? nutriments,
  String? quantityText,
) {
  double? per100(Nutrient nutrient) =>
      nutriments?.getValue(nutrient, PerSize.oneHundredGrams);

  double? grams(Nutrient nutrient) => estimatePackageNutrientGrams(
    gramsPer100: per100(nutrient),
    quantityText: quantityText,
  );

  return PackageNutrition(
    kcal: estimatePackageKcal(
      kcalPer100: per100(Nutrient.energyKCal),
      quantityText: quantityText,
    ),
    proteinGrams: grams(Nutrient.proteins),
    carbohydrateGrams: grams(Nutrient.carbohydrates),
    fatGrams: grams(Nutrient.fat),
    fiberGrams: grams(Nutrient.fiber),
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

  /// Energy and macronutrients for the whole package, worked out from the
  /// reported per-100 g figures and [quantity] — see `package_energy.dart`.
  ///
  /// Mostly empty for non-food supplies, which carry no nutrition data at
  /// all, and for package sizes like "6 Stück" that cannot be converted.
  /// The supply calculator needs the calorie figure and nobody fills it in
  /// by hand, so getting it from the barcode is what makes that screen work
  /// at all.
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
        nutrition: packageNutritionOf(product.nutriments, product.quantity),
      );
    } catch (_) {
      // Network error, timeout, malformed response, etc. — the user can
      // always fall back to filling the form in by hand.
      return null;
    }
  }
}
