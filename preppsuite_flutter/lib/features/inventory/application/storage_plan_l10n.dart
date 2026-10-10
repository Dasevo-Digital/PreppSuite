import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/generated/app_localizations.dart';
import 'storage_plan.dart';
import 'storage_plan_es.dart';

/// Names inside the BLE tables are data, not app copy.
///
/// They live in `storage_plan.dart` with an English name beside each,
/// rather than in the `.arb` files, for the same reason the built-in
/// checklist templates do: they are the content of a document the app
/// reproduces, and splitting one table across sixty translation keys
/// makes a transcription impossible to check against the original. The
/// screen's own words — headings, buttons, explanations — go through
/// `AppLocalizations` as usual.
///
/// Spanish (#108) comes from `storage_plan_es.dart`, keyed by the German
/// text; a test holds it against every row, so the English fallback
/// below is a guard and not a path anything takes.
String _pick(AppLocalizations l10n, String german, String english) {
  final language = l10n.localeName;
  if (language.startsWith('de')) return german;
  if (language.startsWith('es')) return storagePlanSpanish[german] ?? english;
  return english;
}

String? _pickOptional(
  AppLocalizations l10n,
  String? german,
  String? english,
) => german == null ? english : _pick(l10n, german, english ?? german);

String storageGroupName(AppLocalizations l10n, StorageGroup group) =>
    _pick(l10n, group.name, group.nameEn);

String storageGroupFootnote(AppLocalizations l10n, StorageGroup group) =>
    _pickOptional(l10n, group.footnote, group.footnoteEn) ?? '';

String storageFoodName(AppLocalizations l10n, StorageFood food) =>
    _pick(l10n, food.name, food.nameEn);

String? storageFoodNote(AppLocalizations l10n, StorageFood food) =>
    _pickOptional(l10n, food.note, food.noteEn);

String storageVariantName(AppLocalizations l10n, StorageVariant variant) =>
    _pick(l10n, variant.name, variant.nameEn);

String localizeDiet(AppLocalizations l10n, StorageDiet diet) => switch (diet) {
  StorageDiet.mixed => l10n.storageDietMixed,
  StorageDiet.vegetarian => l10n.storageDietVegetarian,
};

String localizeNutrient(AppLocalizations l10n, StorageNutrient nutrient) =>
    switch (nutrient) {
      StorageNutrient.protein => l10n.storageNutrientProtein,
      StorageNutrient.fiber => l10n.storageNutrientFiber,
      StorageNutrient.iron => l10n.storageNutrientIron,
      StorageNutrient.vitaminB12 => l10n.storageNutrientVitaminB12,
      StorageNutrient.healthyFats => l10n.storageNutrientHealthyFats,
      StorageNutrient.fluid => l10n.storageNutrientFluid,
    };

IconData nutrientIcon(StorageNutrient nutrient) => switch (nutrient) {
  StorageNutrient.protein => Icons.egg_outlined,
  StorageNutrient.fiber => Icons.grass_outlined,
  StorageNutrient.iron => Icons.bloodtype_outlined,
  StorageNutrient.vitaminB12 => Icons.science_outlined,
  StorageNutrient.healthyFats => Icons.water_drop_outlined,
  StorageNutrient.fluid => Icons.local_drink_outlined,
};

/// Renders an amount the way a shopping list would.
///
/// Grams switch to kilograms above a kilo — "4,0 kg" rather than
/// "4000 g" — which is also how the source prints its group totals. The
/// number itself goes through [NumberFormat] so a German build reads
/// "1,5" and an English one "1.5".
String formatStorageAmount(
  AppLocalizations l10n,
  double amount,
  StorageUnit unit,
) {
  switch (unit) {
    case StorageUnit.piece:
      return l10n.storageAmountPieces(amount.round());
    case StorageUnit.liter:
      return l10n.storageAmountLiters(_number(l10n, amount, 2));
    case StorageUnit.gram:
      if (amount >= 1000) {
        return l10n.storageAmountKilograms(_number(l10n, amount / 1000, 1));
      }
      return l10n.storageAmountGrams(_number(l10n, amount, 0));
  }
}

/// At most [decimals] places, and no trailing zeros beyond the first —
/// "20 l" rather than "20,00 l", but "1,5 kg" rather than "2 kg".
String _number(AppLocalizations l10n, double value, int decimals) {
  final format = NumberFormat.decimalPatternDigits(
    locale: l10n.localeName,
    decimalDigits: decimals,
  );
  final text = format.format(value);
  if (decimals == 0) return text;

  final separator = NumberFormat.decimalPattern(
    l10n.localeName,
  ).symbols.DECIMAL_SEP;
  if (!text.contains(separator)) return text;

  final trimmed = text
      .replaceFirst(RegExp('0+\$'), '')
      .replaceFirst(RegExp(RegExp.escape(separator) + r'$'), '');
  return trimmed;
}
