/// What a stretch without power and water is short of, as a shopping
/// file (#149) -- the same format as the shopping list, with `origin`
/// `scenario`. See `docs/einkaufsliste-format.md`.
library;

import '../../energy/application/energy_range.dart';
import '../../inventory/application/shopping_list_export.dart';
import 'scenario_gaps.dart';

/// Writes the gaps in [gaps] that a shop can close.
///
/// Here the water is a line of its own, unlike in the minimums list: the
/// stretch's water is the thing to buy, and no item line counts towards
/// it. Calories stay beside the lines under `scenario`, because which
/// food closes that gap is the household's choice.
///
/// An energy line is named after what the household stores it as
/// ("Gaskartuschen") where it said, else after the kind; [energyName]
/// and [energyUnit] supply the words.
String buildScenarioFile(
  ScenarioGaps gaps, {
  required String waterName,
  required String Function(EnergyKind kind) energyName,
  required String Function(EnergyKind kind) energyUnit,
  required DateTime now,
  required String language,
  required String Function(double amount) formatAmount,
}) => buildShoppingFile(
  origin: 'scenario',
  lines: [
    if (gaps.waterMissing > 0)
      ShoppingFileLine(
        name: waterName,
        amount: gaps.waterMissing,
        unit: 'l',
        supplyCategory: 'water',
      ),
    for (final medicine in gaps.medicines)
      if (medicine.missing > 0)
        ShoppingFileLine(
          name: medicine.item.name,
          amount: medicine.missing,
          unit: medicine.item.unit,
          supplyCategory: medicine.item.category,
        ),
    for (final energy in gaps.energy)
      if (energy.missing > 0)
        ShoppingFileLine(
          name: energy.reserves.isEmpty
              ? energyName(energy.kind)
              : energy.reserves.join(', '),
          amount: energy.missing,
          unit: energyUnit(energy.kind),
          supplyCategory: 'energy',
        ),
  ],
  now: now,
  language: language,
  formatAmount: formatAmount,
  extra: {
    'scenario': {'days': gaps.days, 'kcal': gaps.kcalMissing},
  },
);
