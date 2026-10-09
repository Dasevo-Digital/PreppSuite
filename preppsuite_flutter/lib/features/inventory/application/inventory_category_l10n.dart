import 'package:flutter/material.dart';

import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Drift stores [InventoryItemCategory] as its plain enum name (see
/// `InventoryItems.category` in the local database); this converts back.
extension InventoryItemCategoryX on InventoryItemCategory {
  static InventoryItemCategory fromName(String name) =>
      InventoryItemCategory.values.byName(name);
}

String localizeCategory(AppLocalizations l10n, InventoryItemCategory category) {
  return switch (category) {
    InventoryItemCategory.water => l10n.categoryWater,
    InventoryItemCategory.food => l10n.categoryFood,
    InventoryItemCategory.medical => l10n.categoryMedical,
    InventoryItemCategory.tools => l10n.categoryTools,
    InventoryItemCategory.documents => l10n.categoryDocuments,
    InventoryItemCategory.energy => l10n.categoryEnergy,
    InventoryItemCategory.hygiene => l10n.categoryHygiene,
    InventoryItemCategory.other => l10n.categoryOther,
  };
}

IconData categoryIcon(InventoryItemCategory category) {
  return switch (category) {
    InventoryItemCategory.water => Icons.water_drop_outlined,
    InventoryItemCategory.food => Icons.restaurant_outlined,
    InventoryItemCategory.medical => Icons.medical_services_outlined,
    InventoryItemCategory.tools => Icons.handyman_outlined,
    InventoryItemCategory.documents => Icons.description_outlined,
    InventoryItemCategory.energy => Icons.bolt_outlined,
    InventoryItemCategory.hygiene => Icons.soap_outlined,
    InventoryItemCategory.other => Icons.category_outlined,
  };
}
