/// The two lamps at the top of the overview.
///
/// Every card below them answers one question well and none of them
/// answers "how are we doing". That is the question somebody actually
/// opens this screen with, and until now they had to read four cards and
/// add up.
///
/// **Two lamps and never one.** "Vorrat reicht, aber Unwetter" has no
/// common colour, and the weighting that would produce one would be
/// invented here — which is the one thing this app does not do with
/// scales. Each lamp answers its own question and says whose number it
/// is using.
///
/// **Neither lamp guesses.** The supply lamp compares against the BBK's
/// own ten days, two litres and 2200 kcal; the situation lamp shows the
/// highest severity the issuing authority has published, in the
/// authority's own ladder. Where there is nothing to compare against,
/// the lamp is grey and says so instead of picking a colour.
library;

import '../../../local_db/database.dart';
import '../../../model/categories.dart';
import '../../inventory/application/shopping_list.dart';
import '../../inventory/application/supply_calculator.dart';

/// The planning horizon both lamps and every table in the app use.
const statusLightDays = 10;

/// What the supply lamp says.
enum SupplyLight {
  /// Too little recorded to answer. Grey, because an empty database is
  /// not an empty cellar — and colouring it red would accuse a household
  /// of being unprepared when it has only not typed anything in yet.
  unknown,

  /// Recorded, and short of the ten days.
  short,

  /// Ten days of water and of calories, for everyone who lives here.
  covered,
}

/// The supply lamp, and the number behind it.
class SupplyStatus {
  const SupplyStatus({
    required this.light,
    this.daysCovered,
    this.uncounted = 0,
  });

  final SupplyLight light;

  /// How long the household lasts, as the shopping list works it out —
  /// the shorter of water and calories. Null when nothing can be said.
  final int? daysCovered;

  /// Food rows the calculation had to leave out, because their unit
  /// names no measure. A figure with this above zero covers less than
  /// the cupboard does, and the lamp has to be able to admit that.
  final int uncounted;
}

/// Where the supply lamp stands.
///
/// [unknown] is reached in exactly two ways, and both are honest: the
/// household has recorded nothing to divide, or it consumes nothing
/// because nobody is entered as living here. Neither is a shortage.
SupplyStatus supplyStatus({
  required List<InventoryItem> items,
  required SupplyHousehold household,
}) {
  final uncounted = foodWithoutMeasure(items).length;
  final recorded = items.any(
    (item) =>
        item.quantity > 0 &&
        (InventoryItemCategory.fromName(item.category) ==
                InventoryItemCategory.water ||
            InventoryItemCategory.fromName(item.category) ==
                InventoryItemCategory.food),
  );
  if (!recorded) {
    return SupplyStatus(light: SupplyLight.unknown, uncounted: uncounted);
  }

  final list = buildShoppingList(
    items: items,
    days: statusLightDays,
    household: household,
  );
  final days = list.daysCovered;
  if (days == null) {
    // Nobody eats or drinks here, so there is no reach to report. A
    // household of nought is a question this screen cannot answer.
    return SupplyStatus(light: SupplyLight.unknown, uncounted: uncounted);
  }

  return SupplyStatus(
    light: list.targetMet ? SupplyLight.covered : SupplyLight.short,
    daysCovered: days,
    uncounted: uncounted,
  );
}

/// What the situation lamp says.
///
/// There is deliberately **no green here.** An authority publishes
/// warnings, not all-clears: the absence of one means nothing has been
/// issued for this household's regions, which is not the same statement
/// as "it is safe" and must not be dressed up as one.
class SituationStatus {
  const SituationStatus({this.highest, this.count = 0});

  /// The worst severity currently in force, or null where nothing is.
  final WarningSeverity? highest;

  /// How many are in force.
  final int count;

  bool get quiet => highest == null;
}

/// The highest severity in force for this household, and how many.
///
/// [relevant] is already filtered by the same rule the banner and the
/// notifications use — passed in rather than applied here, so the
/// overview cannot claim "nothing" while the banner shows one.
SituationStatus situationStatus(List<Warning> relevant) {
  WarningSeverity? highest;
  for (final warning in relevant) {
    final severity = WarningSeverity.fromName(warning.severity);
    if (highest == null || _rank(severity) > _rank(highest)) {
      highest = severity;
    }
  }
  return SituationStatus(highest: highest, count: relevant.length);
}

int _rank(WarningSeverity severity) => switch (severity) {
  WarningSeverity.minor => 0,
  WarningSeverity.moderate => 1,
  WarningSeverity.severe => 2,
  WarningSeverity.extreme => 3,
};
