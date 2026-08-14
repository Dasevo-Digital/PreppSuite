import '../../../l10n/generated/app_localizations.dart';
import 'inventory_csv_import.dart';

/// Turns an [InventoryCsvRowError]'s reason into a localized message
/// (without the row-number prefix — callers that show it inline with the
/// row already have that context; those that don't can compose
/// `l10n.csvImportRowError(row, reason)` themselves).
String localizeCsvErrorReason(
  AppLocalizations l10n,
  InventoryCsvRowError error,
) {
  return switch (error.type) {
    InventoryCsvErrorType.nameMissing => l10n.csvImportReasonNameMissing,
    InventoryCsvErrorType.unknownCategory =>
      l10n.csvImportReasonUnknownCategory(error.detail ?? ''),
    InventoryCsvErrorType.invalidQuantity =>
      l10n.csvImportReasonInvalidQuantity(error.detail ?? ''),
    InventoryCsvErrorType.unitMissing => l10n.csvImportReasonUnitMissing,
    InventoryCsvErrorType.storageLocationMissing =>
      l10n.csvImportReasonStorageLocationMissing,
    InventoryCsvErrorType.invalidDate => l10n.csvImportReasonInvalidDate(
      error.detail ?? '',
    ),
    InventoryCsvErrorType.invalidMinQuantity =>
      l10n.csvImportReasonInvalidMinQuantity(error.detail ?? ''),
  };
}
