import 'package:openfoodfacts/openfoodfacts.dart';

import 'package_energy.dart';

/// A minimal, prefill-only view of an Open Food Facts product — just enough
/// to seed the inventory item form. The user can freely edit any field
/// afterward, so this deliberately doesn't try to map more than name/brand.
class OpenFoodFactsProduct {
  const OpenFoodFactsProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.quantity,
    this.totalKcal,
  });

  final String barcode;
  final String name;
  final String? brand;

  /// Free-text package quantity as reported by Open Food Facts (e.g.
  /// "1.5 l", "500g") — informational only, not parsed into a number/unit.
  final String? quantity;

  /// Kilocalories for the whole package, worked out from the reported
  /// energy per 100 g and [quantity] — see `package_energy.dart`.
  ///
  /// Null whenever either part is missing or unreadable, which is common:
  /// non-food supplies carry no nutrition data at all, and package sizes
  /// like "6 Stück" cannot be converted. The supply calculator needs this
  /// number, and nobody fills it in by hand, so getting it from the
  /// barcode is what makes that screen work at all.
  final int? totalKcal;
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
        totalKcal: estimatePackageKcal(
          kcalPer100: product.nutriments?.getValue(
            Nutrient.energyKCal,
            PerSize.oneHundredGrams,
          ),
          quantityText: product.quantity,
        ),
      );
    } catch (_) {
      // Network error, timeout, malformed response, etc. — the user can
      // always fall back to filling the form in by hand.
      return null;
    }
  }
}
