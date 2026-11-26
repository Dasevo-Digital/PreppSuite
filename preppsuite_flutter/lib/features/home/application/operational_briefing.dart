/// What the briefing card at the top of the overview says, worked out
/// away from the widget tree.
library;

import '../../warnings/application/warning_freshness.dart';
import 'status_lights.dart';

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

  /// Something in the supply has expired or is below its own minimum.
  inventoryAttention,

  /// Recorded, but no water or food with an amount the lamp can count.
  supplyUnknown,

  /// Water and food recorded, and short of the BBK's ten days.
  supplyShort,

  /// The rechargeable equipment is due for its check.
  chargeDue,

  /// None of the above: the supply reaches the ten days, nothing in it
  /// has expired or run low, and the equipment check is not due.
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
///
/// "Grundlagen angelegt" is [ready], and [ready] is earned (#394): it
/// used to follow from a single entry in the supply, so one candle read
/// "basics in place" above "lasts 0 of 10 days" and three expired tins.
/// It now needs what the supply lamp calls covered, the attention card
/// nothing to show, and the equipment check done.
OperationalBriefing operationalBriefing({
  required int warnings,
  required WarningFreshness? freshness,
  required bool inventoryEmpty,
  required int inventoryAttention,
  required SupplyLight supply,
  required bool chargeDue,
}) {
  if (warnings > 0) return OperationalBriefing.warning;
  if (freshness != null && freshness != WarningFreshness.current) {
    return OperationalBriefing.unheard;
  }
  if (inventoryEmpty) return OperationalBriefing.inventoryMissing;
  if (inventoryAttention > 0) return OperationalBriefing.inventoryAttention;
  switch (supply) {
    case SupplyLight.unknown:
      return OperationalBriefing.supplyUnknown;
    case SupplyLight.short:
      return OperationalBriefing.supplyShort;
    case SupplyLight.covered:
      break;
  }
  if (chargeDue) return OperationalBriefing.chargeDue;
  return OperationalBriefing.ready;
}
