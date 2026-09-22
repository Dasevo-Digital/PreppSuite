import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../model/categories.dart';

String localizeChecklistKind(AppLocalizations l10n, ChecklistKind kind) {
  return switch (kind) {
    ChecklistKind.preparation => l10n.checklistKindPreparation,
    ChecklistKind.response => l10n.checklistKindResponse,
  };
}

/// The one sentence under the heading, which is where the difference
/// between the two actually gets explained.
String describeChecklistKind(AppLocalizations l10n, ChecklistKind kind) {
  return switch (kind) {
    ChecklistKind.preparation => l10n.checklistKindPreparationIntro,
    ChecklistKind.response => l10n.checklistKindResponseIntro,
  };
}

IconData checklistKindIcon(ChecklistKind kind) {
  return switch (kind) {
    ChecklistKind.preparation => Icons.inventory_2_outlined,
    ChecklistKind.response => Icons.bolt_outlined,
  };
}
