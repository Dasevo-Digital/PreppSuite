import 'package:flutter/material.dart';
import '../../../model/categories.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Drift stores [WarningSeverity] as its plain enum name.
WarningSeverity warningSeverityFromName(String name) =>
    WarningSeverity.values.byName(name);

/// Ordinal rank, low to high — for picking the "most severe" warning
/// without relying on SQL text ordering (which would sort alphabetically).
int warningSeverityRank(WarningSeverity severity) {
  return switch (severity) {
    WarningSeverity.minor => 0,
    WarningSeverity.moderate => 1,
    WarningSeverity.severe => 2,
    WarningSeverity.extreme => 3,
  };
}

String localizeWarningSeverity(
  AppLocalizations l10n,
  WarningSeverity severity,
) {
  return switch (severity) {
    WarningSeverity.minor => l10n.warningSeverityMinor,
    WarningSeverity.moderate => l10n.warningSeverityModerate,
    WarningSeverity.severe => l10n.warningSeveritySevere,
    WarningSeverity.extreme => l10n.warningSeverityExtreme,
  };
}

Color warningSeverityColor(BuildContext context, WarningSeverity severity) {
  final scheme = Theme.of(context).colorScheme;
  return switch (severity) {
    WarningSeverity.minor => scheme.secondaryContainer,
    WarningSeverity.moderate => scheme.tertiaryContainer,
    WarningSeverity.severe => scheme.errorContainer,
    WarningSeverity.extreme => scheme.error,
  };
}
