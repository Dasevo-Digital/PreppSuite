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

/// The severity ladder, as its own palette.
///
/// Deliberately not taken from the `ColorScheme`. It was, briefly: minor
/// on `secondaryContainer`, moderate on `tertiaryContainer`. Two things
/// are wrong with that. Generated from the app's green seed, the four
/// rungs came out as four shades of green-grey -- an escalation that does
/// not escalate. And those roles are simultaneously every tonal accent in
/// the app, so colouring "minor" blue for legibility turned every add
/// button in a green app pale blue. Semantic colour and accent colour are
/// two systems; entangling them means neither can be chosen freely.
///
/// The ladder reads as one sequence: informational blue, amber, red, and
/// then a rung that is a full colour rather than a container, which is
/// what makes "extreme" look different in kind rather than merely darker.
const _ladderLight = <WarningSeverity, WarningSeverityColors>{
  WarningSeverity.minor: (
    background: Color(0xFFDCE9F6),
    foreground: Color(0xFF123048),
  ),
  WarningSeverity.moderate: (
    background: Color(0xFFFFE2A8),
    foreground: Color(0xFF3A2900),
  ),
  WarningSeverity.severe: (
    background: Color(0xFFFFD8D1),
    foreground: Color(0xFF5A180E),
  ),
  WarningSeverity.extreme: (
    background: Color(0xFFB3261E),
    foreground: Color(0xFFFFFFFF),
  ),
};

const _ladderDark = <WarningSeverity, WarningSeverityColors>{
  WarningSeverity.minor: (
    background: Color(0xFF15384D),
    foreground: Color(0xFFCDE6F8),
  ),
  WarningSeverity.moderate: (
    background: Color(0xFF473406),
    foreground: Color(0xFFFFE2A6),
  ),
  WarningSeverity.severe: (
    background: Color(0xFF5C1A10),
    foreground: Color(0xFFFFDAD4),
  ),
  // A light red with dark text rather than a saturated red with white.
  // The saturated one measured 1.32:1 in dark mode, and the one
  // unreadable case was the highest severity there is.
  WarningSeverity.extreme: (
    background: Color(0xFFFFB4AB),
    foreground: Color(0xFF52130C),
  ),
};

/// The colours a severity is shown in.
///
/// Both halves together, deliberately. This used to hand out a background
/// alone and leave the text to inherit `onSurface`, and a pair cannot be
/// half-used: every one of these clears 4.5:1, which
/// `warning_severity_colors_test.dart` checks in both themes.
WarningSeverityColors warningSeverityColors(
  BuildContext context,
  WarningSeverity severity,
) {
  final ladder = Theme.of(context).brightness == Brightness.dark
      ? _ladderDark
      : _ladderLight;
  return ladder[severity]!;
}
