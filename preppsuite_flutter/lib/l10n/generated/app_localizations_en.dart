// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'PreppSuite';

  @override
  String get signOutButton => 'Sign out';

  @override
  String get onboardingChooseTitle => 'Welcome to PreppSuite';

  @override
  String get onboardingChooseSubtitle =>
      'Create a new household or join an existing one.';

  @override
  String get createHouseholdButton => 'Create household';

  @override
  String get joinHouseholdButton => 'Join household';

  @override
  String get createHouseholdTitle => 'Create household';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get countryLabel => 'Country';

  @override
  String get regionKeyLabel => 'Regional key (optional)';

  @override
  String get regionKeyHelper => 'Germany only, for more precise warnings';

  @override
  String get displayNameLabel => 'Your display name';

  @override
  String get createButton => 'Create';

  @override
  String get joinHouseholdTitle => 'Join household';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get joinButton => 'Join';

  @override
  String get householdOverviewTitle => 'My household';

  @override
  String get inviteCodeSectionTitle => 'Invite code';

  @override
  String get rotateInviteCodeButton => 'Generate new code';

  @override
  String get membersSectionTitle => 'Members';

  @override
  String get roleOwner => 'Owner';

  @override
  String get roleMember => 'Member';

  @override
  String get loadingHousehold => 'Loading household…';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String errorGeneric(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get errorInvalidInviteCode => 'This invite code is not valid.';

  @override
  String get errorAlreadyInHousehold => 'You already belong to a household.';

  @override
  String get errorNotOwner => 'Only the household\'s owner can do this.';

  @override
  String get errorNotAMember => 'You are not a member of this household.';

  @override
  String get navInventory => 'Inventory';

  @override
  String get navHousehold => 'Household';

  @override
  String get inventoryTitle => 'Inventory';

  @override
  String get inventoryEmpty => 'No items yet. Tap + to add your first one.';

  @override
  String get addItemButton => 'Add item';

  @override
  String get editItemTitle => 'Edit item';

  @override
  String get addItemTitle => 'Add item';

  @override
  String get itemNameLabel => 'Name';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryWater => 'Water';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryMedical => 'Medical';

  @override
  String get categoryTools => 'Tools';

  @override
  String get categoryDocuments => 'Documents';

  @override
  String get categoryEnergy => 'Energy';

  @override
  String get categoryHygiene => 'Hygiene';

  @override
  String get categoryOther => 'Other';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get unitLabel => 'Unit';

  @override
  String get storageLocationLabel => 'Storage location';

  @override
  String get expirationDateLabel => 'Expiration date (optional)';

  @override
  String get minQuantityLabel => 'Minimum quantity (optional)';

  @override
  String get notesLabel => 'Notes (optional)';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteButton => 'Delete';

  @override
  String get lowStockBadge => 'Low stock';

  @override
  String get expiredBadge => 'Expired';

  @override
  String get invalidNumber => 'Enter a valid number.';

  @override
  String get clearDateButton => 'Clear date';

  @override
  String get scanBarcodeButton => 'Scan barcode';

  @override
  String scannedBarcodeLabel(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String get productNotFound =>
      'Product not found — fill in the details by hand.';

  @override
  String get navChecklists => 'Checklists';

  @override
  String get navBudget => 'Budget';

  @override
  String get checklistsTitle => 'Checklists';

  @override
  String get checklistsEmpty =>
      'No checklists yet. Tap + to create your first one.';

  @override
  String get createTemplateButton => 'New checklist';

  @override
  String get createTemplateTitle => 'New checklist';

  @override
  String get templateTitleLabel => 'Checklist name';

  @override
  String get checklistCategoryFirstAid => 'First aid';

  @override
  String get checklistCategoryCustom => 'Custom';

  @override
  String get builtInBadge => 'Built-in';

  @override
  String get duplicateTemplateAction => 'Duplicate';

  @override
  String get deleteTemplateAction => 'Delete checklist';

  @override
  String get checklistItemTitleLabel => 'Item';

  @override
  String get addChecklistItemHint => 'Add an item…';

  @override
  String get addButton => 'Add';

  @override
  String checklistProgress(int checked, int total) {
    return '$checked of $total';
  }

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetEmpty =>
      'No spending recorded yet. Tap + to add your first entry.';

  @override
  String get addBudgetEntryButton => 'Add entry';

  @override
  String get addBudgetEntryTitle => 'Add entry';

  @override
  String get editBudgetEntryTitle => 'Edit entry';

  @override
  String get budgetLabelLabel => 'Label';

  @override
  String get amountLabel => 'Amount';

  @override
  String get currencyLabel => 'Currency';

  @override
  String get purchaseDateLabel => 'Purchase date (optional)';

  @override
  String get budgetTotalLabel => 'Total';

  @override
  String get warningsTitle => 'Warnings';

  @override
  String get warningsEmpty => 'No warnings for your region right now.';

  @override
  String get warningSeverityMinor => 'Minor';

  @override
  String get warningSeverityModerate => 'Moderate';

  @override
  String get warningSeveritySevere => 'Severe';

  @override
  String get warningSeverityExtreme => 'Extreme';

  @override
  String warningBannerMore(int count) {
    return '+$count more';
  }

  @override
  String get viewAllWarningsAction => 'View all';

  @override
  String get warningExpiredLabel => 'Expired';

  @override
  String get warningSourceBbk =>
      'German Federal Office for Civil Protection (BBK)';

  @override
  String get warningSourceMeteoalarm => 'MeteoAlarm';

  @override
  String get exportPdfButton => 'Export missing equipment';

  @override
  String get pdfReportTitle => 'Missing Equipment Report';

  @override
  String pdfGeneratedOn(String date) {
    return 'Generated on $date';
  }

  @override
  String get pdfChecklistSectionTitle => 'Open checklist items';

  @override
  String get pdfNoMissingChecklistItems =>
      'Nothing open — every checklist is complete.';

  @override
  String get pdfInventorySectionTitle => 'Low-stock inventory items';

  @override
  String get pdfNoLowStockItems => 'Nothing below its minimum quantity.';

  @override
  String get pdfColumnItem => 'Item';

  @override
  String get pdfColumnQuantity => 'Quantity';

  @override
  String get pdfColumnMinQuantity => 'Minimum';

  @override
  String get pdfColumnUnit => 'Unit';

  @override
  String get settingsSectionTitle => 'Settings';

  @override
  String get languageLabel => 'Language';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageGermanOption => 'Deutsch';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get serverAddressLabel => 'Server address';

  @override
  String inventoryAttentionTooltip(int count) {
    return '$count item(s) low on stock or expired';
  }
}
