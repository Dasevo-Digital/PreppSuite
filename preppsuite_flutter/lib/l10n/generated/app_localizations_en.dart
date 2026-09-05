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
  String get regionKeyExplanationTooltip => 'What is this?';

  @override
  String get regionKeyExplanationTitle => 'Official Regional Key (ARS)';

  @override
  String get regionKeyExplanationBody =>
      'The \"amtlicher Regionalschlüssel\" (ARS) is a 12-digit code that German authorities use to uniquely identify every municipality, down to the district and locality level. It\'s issued by the national statistics office (Destatis) and used, among other things, to precisely scope official warnings (BBK/NINA) to your area instead of your entire federal state.\n\nWithout it, warnings are only filtered by country. With it, you get warnings specific to your municipality.\n\nYou can look up your municipality\'s ARS via the Federal Statistical Office\'s municipality directory (\"Gemeindeverzeichnis\") or your local BBK warning app. Leave this field empty if you don\'t know it — you can add it later in household settings.';

  @override
  String get regionKeyExplanationClose => 'Got it';

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
  String get navSettings => 'Settings';

  @override
  String get navShelters => 'Shelters';

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
  String get caloriesLabel => 'Calories, total kcal (optional)';

  @override
  String get supplyCalculatorPersonCountLabel => 'People';

  @override
  String supplyCalculatorDaysLabel(int days) {
    return 'Supplies for $days days';
  }

  @override
  String get supplyCalculatorWaterLabel => 'Drinking water';

  @override
  String get supplyCalculatorCaloriesLabel => 'Calories';

  @override
  String supplyCalculatorProgress(String current, String target, String unit) {
    return '$current / $target $unit';
  }

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
  String get itemPhotoLabel => 'Photo';

  @override
  String get addPhotoButton => 'Add photo';

  @override
  String get takePhotoButton => 'Take photo';

  @override
  String get chooseFromGalleryButton => 'Choose from gallery';

  @override
  String get removePhotoButton => 'Remove photo';

  @override
  String get csvImportButton => 'Import CSV';

  @override
  String get csvImportTitle => 'Import CSV';

  @override
  String get csvImportInstructionsTitle => 'Expected format';

  @override
  String get csvImportInstructionsBody =>
      'The first row must be a header row. Required columns: name, category, quantity, unit, storageLocation. Optional columns: expirationDate, minQuantity, notes. German column names are also recognized (Name, Kategorie, Menge, Einheit, Lagerort, Ablaufdatum, Mindestbestand, Notizen).\n\nCategory: water, food, medical, tools, documents, energy, hygiene, or other (German names also work, e.g. Wasser, Lebensmittel).\nDates: YYYY-MM-DD or DD.MM.YYYY.\nNumbers: \".\" or \",\" as the decimal separator.\nDelimiter: \",\" or \";\", detected automatically.';

  @override
  String get csvImportPickFileButton => 'Choose CSV file…';

  @override
  String get csvImportChangeFileButton => 'Choose a different file…';

  @override
  String get csvImportParsing => 'Reading file…';

  @override
  String csvImportSummary(int valid, int total) {
    return '$valid of $total rows can be imported.';
  }

  @override
  String csvImportRowError(int row, String reason) {
    return 'Row $row: $reason';
  }

  @override
  String get csvImportReasonMissingColumns =>
      'Missing required columns (name, category, quantity, unit, storage location).';

  @override
  String get csvImportReasonNameMissing => 'Name is missing.';

  @override
  String csvImportReasonUnknownCategory(String value) {
    return 'Unknown category \"$value\".';
  }

  @override
  String csvImportReasonInvalidQuantity(String value) {
    return 'Invalid quantity \"$value\".';
  }

  @override
  String get csvImportReasonUnitMissing => 'Unit is missing.';

  @override
  String get csvImportReasonStorageLocationMissing =>
      'Storage location is missing.';

  @override
  String csvImportReasonInvalidDate(String value) {
    return 'Invalid date \"$value\".';
  }

  @override
  String csvImportReasonInvalidMinQuantity(String value) {
    return 'Invalid minimum quantity \"$value\".';
  }

  @override
  String csvImportImportButton(int count) {
    return 'Import $count rows';
  }

  @override
  String csvImportSuccessMessage(int count) {
    return '$count items imported.';
  }

  @override
  String get csvImportNoValidRows => 'No valid rows found in this file.';

  @override
  String csvImportFileReadError(String error) {
    return 'Could not read this file: $error';
  }

  @override
  String get csvImportRowsSectionTitle => 'Rows';

  @override
  String csvImportRowLabel(int row) {
    return 'Row $row';
  }

  @override
  String get csvImportEditRowTooltip => 'Edit';

  @override
  String get csvImportRemoveRowTooltip => 'Remove from import';

  @override
  String get csvImportEditRowTitle => 'Edit row';

  @override
  String get cancelButton => 'Cancel';

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
  String get warningsNinaHintTitle => 'Warnings while the app is closed';

  @override
  String get warningsNinaHintBody =>
      'PreppSuite polls the official warning feeds every 15 minutes and shows them as an overview. For immediate alerts that reach you with the app closed, use NINA from Germany\'s Federal Office of Civil Protection — the same official source, in seconds rather than minutes.';

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

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get themeSystemOption => 'System';

  @override
  String get themeLightOption => 'Light';

  @override
  String get themeDarkOption => 'Dark';

  @override
  String get settingsMyRegionTitle => 'My region';

  @override
  String get settingsNoRegionSet => 'No region set';

  @override
  String get settingsAdditionalRegionsTitle => 'Additional regions';

  @override
  String get settingsNoAdditionalRegions => 'No additional regions added yet.';

  @override
  String get settingsAddRegionButton => 'Add region';

  @override
  String get settingsAddRegionDialogTitle => 'Add region';

  @override
  String get settingsRegionTypeKreis => 'District (Kreis)';

  @override
  String get settingsRegionTypeBundesland => 'State (Bundesland)';

  @override
  String get settingsKreisSchluesselLabel => 'Kreisschlüssel (5 digits)';

  @override
  String get settingsKreisSchluesselInvalid =>
      'Enter a 5-digit Kreisschlüssel.';

  @override
  String get settingsRegionLabelLabel => 'Label';

  @override
  String get settingsNotificationsTitle => 'Notifications';

  @override
  String get settingsNotificationsToggleLabel => 'Notify me about new warnings';

  @override
  String get settingsNotificationsToggleHint =>
      'Local notifications only, while the app is running — no push server.';

  @override
  String get settingsUseLocationButton => 'Determine state via location';

  @override
  String settingsLocationErrorMessage(String error) {
    return 'Couldn\'t determine your location: $error';
  }

  @override
  String get settingsLocationNoMatchMessage =>
      'Couldn\'t match your location to a German state.';

  @override
  String settingsLocationSuccessMessage(String state) {
    return '$state added as an additional region.';
  }

  @override
  String get shelterMapTitle => 'Shelters';

  @override
  String shelterInfoLine(int radius) {
    return 'OpenStreetMap and WWBOTA/DLBOTA loaded within $radius km.';
  }

  @override
  String get shelterLegendGreenLabel => 'Green';

  @override
  String get shelterLegendGreenDescription =>
      'officially confirmed as a usable shelter';

  @override
  String get shelterLegendYellowLabel => 'Yellow';

  @override
  String get shelterLegendYellowDescription =>
      'possible shelter, access/use unconfirmed';

  @override
  String get shelterLegendRedLabel => 'Red';

  @override
  String get shelterLegendRedDescription =>
      'not released, historical, or informational only';

  @override
  String get shelterDisclaimer =>
      'This map does not replace an official warning, evacuation, or emergency-response instruction.';

  @override
  String get shelterNoConfirmedShelters =>
      'No currently released public shelters are known in Germany in the loaded official data. If that changes, they\'ll appear here in green.';

  @override
  String shelterFilterAll(int count) {
    return 'All $count';
  }

  @override
  String shelterFilterCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get shelterSearchHint => 'Postal code or place';

  @override
  String get shelterSearchButton => 'Search';

  @override
  String get shelterSearchNoResult => 'No result found.';

  @override
  String get shelterUseLocationButton => 'Investigate current location';

  @override
  String get shelterRefreshButton => 'Refresh';

  @override
  String get shelterWwbotaErrorMessage => 'WWBOTA/DLBOTA could not be loaded.';

  @override
  String get shelterOverpassErrorMessage =>
      'OpenStreetMap/Overpass could not be loaded.';

  @override
  String get shelterEmptyPrompt =>
      'No location loaded yet. Use your current location or search for a place.';

  @override
  String get shelterAttribution => '© OpenStreetMap contributors';

  @override
  String get expiryReminderTitle => 'Supply expiring soon';

  @override
  String expiryReminderBody(String name, int days) {
    return '$name expires in $days days.';
  }

  @override
  String expiryReminderBodyTomorrow(String name) {
    return '$name expires tomorrow.';
  }

  @override
  String get settingsExpiryRemindersTitle => 'Expiry reminders';

  @override
  String get settingsExpiryRemindersHint =>
      'A reminder before a supply expires. Choose how many days ahead.';

  @override
  String get settingsExpiryRemindersDisabledHint =>
      'Turn on notifications above so reminders can be scheduled.';

  @override
  String get settingsExpiryRemindersNoneHint =>
      'No lead time selected — no reminders will be scheduled.';

  @override
  String expiryLeadDaysLabel(int days) {
    return '$days days';
  }

  @override
  String get expiryLeadDayOneLabel => '1 day';

  @override
  String get consumeAction => 'Use up';

  @override
  String consumeDialogTitle(String name) {
    return 'Use up $name';
  }

  @override
  String get consumeDialogAmountLabel => 'Amount';

  @override
  String consumeDialogRemaining(String quantity, String unit) {
    return 'In stock: $quantity $unit';
  }

  @override
  String get consumeDialogConfirm => 'Deduct';

  @override
  String get consumeDialogAll => 'Used up entirely';

  @override
  String get consumeInvalidAmount =>
      'Amount must be greater than 0 and at most the stock on hand.';

  @override
  String get syncRetryButton => 'Try again';

  @override
  String syncAgeMinutes(int count) {
    return '$count minutes';
  }

  @override
  String syncAgeHours(int count) {
    return '$count hours';
  }

  @override
  String syncAgeDays(int count) {
    return '$count days';
  }

  @override
  String get csvExportButton => 'Export as CSV';

  @override
  String get csvExportDialogTitle => 'Save supplies as CSV';

  @override
  String csvExportSuccessMessage(int count) {
    return '$count items exported';
  }

  @override
  String get csvExportEmptyMessage => 'There are no items to export yet.';

  @override
  String get csvExportErrorMessage => 'The file could not be written.';

  @override
  String get profileSetupTitle => 'Set up your household';

  @override
  String get profileSetupIntro =>
      'PreppSuite runs entirely on this device. There is no account and no server — just these details, so warnings and supply targets match your situation.';

  @override
  String get profileSetupSubmit => 'Get started';

  @override
  String get personCountLabel => 'People in the household';

  @override
  String get settingsSharingTitle => 'Shared folder';

  @override
  String get sharingIntro =>
      'Supplies, checklists and spending live in a folder several devices can see — a Nextcloud, Syncthing, iCloud Drive or Dropbox directory. PreppSuite only writes files there. What carries them is your choice.';

  @override
  String get sharingInactive =>
      'This device shares nothing. Everything stays here.';

  @override
  String sharingActiveFolder(String path) {
    return 'Folder: $path';
  }

  @override
  String get sharingChooseFolderAction => 'Choose folder';

  @override
  String get sharingChangeFolderAction => 'Choose a different folder';

  @override
  String get sharingLeaveAction => 'Stop sharing';

  @override
  String get sharingSyncNowAction => 'Sync now';

  @override
  String get sharingSyncing => 'Syncing …';

  @override
  String get sharingNeverSynced => 'Never synced yet.';

  @override
  String sharingLastSynced(String age) {
    return 'Last synced $age ago.';
  }

  @override
  String sharingDeviceCount(int count) {
    return '$count devices share this folder.';
  }

  @override
  String get sharingDeviceCountOne =>
      'Only this device uses the folder so far.';

  @override
  String sharingReceived(int count) {
    return 'Took $count entries from other devices.';
  }

  @override
  String get sharingUpToDate => 'Everything is up to date.';

  @override
  String get sharingErrorUnwritable =>
      'This folder cannot be written to. On Android the permission is lost on reinstall and can be revoked in the system settings — just pick the folder again. Otherwise check that it is still there and writable.';

  @override
  String get sharingErrorUnreadable =>
      'There is already a household in this folder, and it cannot be read. It probably comes from a newer version of PreppSuite.';

  @override
  String get sharingErrorVersion =>
      'The files in this folder come from a newer version. Nothing was changed.';

  @override
  String get sharingErrorFailed =>
      'The sync failed. The next attempt runs on its own.';

  @override
  String sharingJoinedOther(String name) {
    return 'This device now belongs to the household “$name”. Its existing entries came along.';
  }

  @override
  String get sharingLeaveDialogTitle => 'Stop sharing?';

  @override
  String get sharingLeaveDialogBody =>
      'This device will stop syncing. Nothing is deleted — not here and not in the folder.';

  @override
  String get sharingLeaveDialogConfirm => 'Stop';

  @override
  String get sharingErrorDifferentHousehold =>
      'This folder belongs to a different household. Nothing was merged — two unrelated sets of data cannot be pulled apart again.';

  @override
  String get mapAttributionOffline =>
      '© OpenStreetMap contributors · © OpenMapTiles';

  @override
  String get settingsOfflineMapTitle => 'Offline map';

  @override
  String get offlineMapIntro =>
      'Without a map of your own the app fetches tiles from OpenStreetMap, so it needs a connection. A PMTiles file on the device replaces that entirely.';

  @override
  String get offlineMapInactive =>
      'No map chosen. Tiles come from the network.';

  @override
  String offlineMapActive(String name) {
    return '$name';
  }

  @override
  String offlineMapZoomRange(int min, int max) {
    return 'Zoom levels $min to $max.';
  }

  @override
  String get offlineMapChooseAction => 'Choose a map';

  @override
  String get offlineMapChangeAction => 'Choose a different map';

  @override
  String get offlineMapForgetAction => 'Back online';

  @override
  String get offlineMapErrorUnreadable =>
      'The file cannot be read. A PMTiles version 3 archive is expected.';

  @override
  String get offlineMapErrorNotVector =>
      'The archive holds finished image tiles rather than vector data. PreppSuite draws the map itself and needs vector tiles.';

  @override
  String get offlineMapErrorSchema =>
      'The archive uses a different schema than the built-in map style. An OpenMapTiles-schema archive is needed — see docs/karte-offline.md.';

  @override
  String get offlineMapHelp => 'Where do I get such a file?';
}
