import '../../../l10n/generated/app_localizations.dart';
import 'energy_range.dart';

String localizeEnergyKind(AppLocalizations l10n, EnergyKind kind) =>
    switch (kind) {
      EnergyKind.electricity => l10n.energyKindElectricity,
      EnergyKind.gas => l10n.energyKindGas,
      EnergyKind.liquidFuel => l10n.energyKindLiquidFuel,
      EnergyKind.solidFuel => l10n.energyKindSolidFuel,
      EnergyKind.candles => l10n.energyKindCandles,
    };

/// What the kind covers and what unit it is counted in, in words.
///
/// On the form rather than in a help text: choosing "Gas" and then
/// guessing whether the box wants grams or kilograms is exactly the way
/// this feature would produce an answer that is wrong by a factor of a
/// thousand.
String localizeEnergyKindHint(AppLocalizations l10n, EnergyKind kind) =>
    switch (kind) {
      EnergyKind.electricity => l10n.energyKindElectricityHint,
      EnergyKind.gas => l10n.energyKindGasHint,
      EnergyKind.liquidFuel => l10n.energyKindLiquidFuelHint,
      EnergyKind.solidFuel => l10n.energyKindSolidFuelHint,
      EnergyKind.candles => l10n.energyKindCandlesHint,
    };

String localizeEnergyUnit(AppLocalizations l10n, EnergyUnit unit) =>
    switch (unit) {
      EnergyUnit.wattHours => l10n.energyUnitWattHours,
      EnergyUnit.grams => l10n.energyUnitGrams,
      EnergyUnit.liters => l10n.energyUnitLiters,
      EnergyUnit.kilograms => l10n.energyUnitKilograms,
      EnergyUnit.hours => l10n.energyUnitHours,
    };

/// A range in words. Null where there is no range to state.
String? localizeEnergyDays(AppLocalizations l10n, int? days) => switch (days) {
  null => null,
  0 => l10n.energyZeroDays,
  1 => l10n.energyOneDay,
  _ => l10n.energyDays(days),
};
