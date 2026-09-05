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
    ChecklistCategory.custom => l10n.checklistCategoryCustom,
  };
}

/// Drift stores [ChecklistCategory] as its plain enum name.
extension ChecklistCategoryX on ChecklistCategory {
  static ChecklistCategory fromName(String name) =>
      ChecklistCategory.values.byName(name);
}
