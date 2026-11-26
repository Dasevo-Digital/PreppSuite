/// What the briefing card at the top of the overview says, worked out
/// away from the widget tree.
library;

import '../../warnings/application/warning_freshness.dart';

/// The one answer the briefing card gives, in the order it is looked for.
enum OperationalBriefing {
  /// A warning for this household's places is in force.
  warning,

  /// None is stored, and the feeds have not answered lately -- or never
  /// have on this device. The absence of a warning says nothing then,
  /// and the card must not say "no warning" (#394).
  unheard,

  /// Nothing recorded in the supply yet.
  inventoryMissing,

  /// The rechargeable equipment is due for its check.
  chargeDue,

  /// None of the above.
  ready,
}

/// The briefing for [warnings] relevant warnings in force, the
/// [freshness] of the household's feed (null while it is being read),
/// and the household's own state.
///
/// A warning in force is named even when the feeds have gone quiet since:
/// what is stored is still the best there is, and the situation lamp
/// does the same. Only the absence of one needs the feeds to have been
/// heard from -- the rule `StatusLightsRow` has followed since #138, and
/// this card did not until #394.
OperationalBriefing operationalBriefing({
  required int warnings,
  required WarningFreshness? freshness,
  required bool inventoryEmpty,
  required bool chargeDue,
}) {
  if (warnings > 0) return OperationalBriefing.warning;
  if (freshness != null && freshness != WarningFreshness.current) {
    return OperationalBriefing.unheard;
  }
  if (inventoryEmpty) return OperationalBriefing.inventoryMissing;
  if (chargeDue) return OperationalBriefing.chargeDue;
  return OperationalBriefing.ready;
}
