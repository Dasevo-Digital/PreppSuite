import '../../../l10n/generated/app_localizations.dart';
import 'supply_groups.dart';

/// The BLE's own group names, in the language being read.
///
/// A separate file for the same reason the categories have one: the enum
/// is stored in the database and must never move, while the words on the
/// screen are free to.
String localizeSupplyGroup(AppLocalizations l10n, SupplyGroup group) =>
    switch (group) {
      SupplyGroup.grain => l10n.supplyGroupGrain,
      SupplyGroup.vegetables => l10n.supplyGroupVegetables,
      SupplyGroup.fruit => l10n.supplyGroupFruit,
      SupplyGroup.drinks => l10n.supplyGroupDrinks,
      SupplyGroup.dairy => l10n.supplyGroupDairy,
      SupplyGroup.protein => l10n.supplyGroupProtein,
      SupplyGroup.fats => l10n.supplyGroupFats,
    };
