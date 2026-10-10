import 'package:flutter/material.dart';

import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Drift stores [InventoryItemCategory] as its plain enum name (see
/// `InventoryItems.category` in the local database); this converts back.
///
/// A name this version does not know reads as `other` rather than
/// throwing. It used to throw, and a category added later -- `petFood`,
/// #151 -- would then have taken down the overview, the supply calculator
/// and the inventory list of a device one version behind. The snapshot
/// keeps those older apps safe for `petFood` (see `device_snapshot.dart`);
/// this keeps this version safe for whatever comes after it.
extension InventoryItemCategoryX on InventoryItemCategory {
  static InventoryItemCategory fromName(String name) =>
      InventoryItemCategory.fromName(name);
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
    InventoryItemCategory.petFood => l10n.categoryPetFood,
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
    InventoryItemCategory.petFood => Icons.pets_outlined,
  };
}
