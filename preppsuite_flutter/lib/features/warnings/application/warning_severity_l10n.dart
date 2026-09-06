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

/// A background for a severity and the foreground that is legible on it.
typedef WarningSeverityColors = ({Color background, Color foreground});

/// The colours a severity is shown in.
///
/// Both halves together, deliberately. This used to hand out a background
/// alone and leave the text to inherit `onSurface`, which works for the
/// three container roles and fails badly for the fourth: `error` is a
/// saturated red, and `onSurface` on it measures 2.64:1 in light mode and
/// 1.32:1 in dark — against the 4.5:1 that text has to clear. The one
/// unreadable case was the highest severity there is. A pair cannot be
/// half-used.
WarningSeverityColors warningSeverityColors(
  BuildContext context,
  WarningSeverity severity,
) {
  final scheme = Theme.of(context).colorScheme;
  return switch (severity) {
    WarningSeverity.minor => (
      background: scheme.secondaryContainer,
      foreground: scheme.onSecondaryContainer,
    ),
    WarningSeverity.moderate => (
      background: scheme.tertiaryContainer,
      foreground: scheme.onTertiaryContainer,
    ),
    WarningSeverity.severe => (
      background: scheme.errorContainer,
      foreground: scheme.onErrorContainer,
    ),
    WarningSeverity.extreme => (
      background: scheme.error,
      foreground: scheme.onError,
    ),
  };
}
