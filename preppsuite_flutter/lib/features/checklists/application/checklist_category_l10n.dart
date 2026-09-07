import 'package:flutter/material.dart';

import '../../../model/categories.dart';
import '../../../l10n/generated/app_localizations.dart';

String localizeChecklistCategory(
  AppLocalizations l10n,
  ChecklistCategory category,
) {
  return switch (category) {
    ChecklistCategory.water => l10n.categoryWater,
    ChecklistCategory.food => l10n.categoryFood,
    ChecklistCategory.firstAid => l10n.checklistCategoryFirstAid,
    ChecklistCategory.hygiene => l10n.categoryHygiene,
    ChecklistCategory.energy => l10n.categoryEnergy,
    ChecklistCategory.information => l10n.checklistCategoryInformation,
    ChecklistCategory.documents => l10n.categoryDocuments,
    ChecklistCategory.evacuation => l10n.checklistCategoryEvacuation,
    ChecklistCategory.safety => l10n.checklistCategorySafety,
    ChecklistCategory.hazards => l10n.checklistCategoryHazards,
    ChecklistCategory.wellbeing => l10n.checklistCategoryWellbeing,
    ChecklistCategory.pets => l10n.checklistCategoryPets,
    ChecklistCategory.custom => l10n.checklistCategoryCustom,
  };
}

IconData checklistCategoryIcon(ChecklistCategory category) {
  return switch (category) {
    ChecklistCategory.water => Icons.water_drop_outlined,
    ChecklistCategory.food => Icons.restaurant_outlined,
    ChecklistCategory.firstAid => Icons.medical_services_outlined,
    ChecklistCategory.hygiene => Icons.soap_outlined,
    ChecklistCategory.energy => Icons.bolt_outlined,
    ChecklistCategory.information => Icons.radio_outlined,
    ChecklistCategory.documents => Icons.description_outlined,
    ChecklistCategory.evacuation => Icons.backpack_outlined,
    ChecklistCategory.safety => Icons.local_fire_department_outlined,
    ChecklistCategory.hazards => Icons.storm_outlined,
    ChecklistCategory.wellbeing => Icons.psychology_outlined,
    ChecklistCategory.pets => Icons.pets_outlined,
    ChecklistCategory.custom => Icons.checklist_outlined,
  };
}

/// Drift stores [ChecklistCategory] as its plain enum name.
extension ChecklistCategoryX on ChecklistCategory {
  static ChecklistCategory fromName(String name) =>
      ChecklistCategory.values.byName(name);
}
