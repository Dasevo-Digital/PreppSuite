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
  String get errorNoConnection =>
      'No connection. Check the network and try again.';

  @override
  String get errorArchiveUnreadable =>
      'The archive could not be read. The file may have moved, or the disk it is on is not attached.';

  @override
  String get errorFileUnreadable => 'The file could not be reached.';

  @override
  String get errorDownloadFailed =>
      'The download stopped. Starting it again picks up where it left off.';

  @override
  String get errorServiceUnavailable =>
      'The service did not answer. That is not on you — try again later.';

  @override
  String get errorDatabase =>
      'The app\'s database reported a problem. Restarting usually clears it.';

  @override
  String get errorPlatformRefused =>
      'The system refused. Check in the settings whether PreppSuite has permission for it.';

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
  String get settingsKreisSchluesselHelper =>
      'Five digits, e.g. 03241 for the Hannover region.';

  @override
  String get settingsBundeslandLabel => 'Federal state';

  @override
  String get settingsBundeslandRequired => 'Choose a federal state.';

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
  String get shelterListHeading => 'Shelters found';

  @override
  String get shelterListEmpty =>
      'Nothing in this radius. Try a wider one, or a different place.';

  @override
  String shelterDistanceMeters(int meters, String direction) {
    return '$meters m $direction';
  }

  @override
  String shelterDistanceKilometers(String km, String direction) {
    return '$km km $direction';
  }

  @override
  String shelterListSubtitle(
    String distance,
    String confidence,
    String source,
  ) {
    return '$distance · $confidence · $source';
  }

  @override
  String get shelterDirectionNorth => 'north';

  @override
  String get shelterDirectionNorthEast => 'north-east';

  @override
  String get shelterDirectionEast => 'east';

  @override
  String get shelterDirectionSouthEast => 'south-east';

  @override
  String get shelterDirectionSouth => 'south';

  @override
  String get shelterDirectionSouthWest => 'south-west';

  @override
  String get shelterDirectionWest => 'west';

  @override
  String get shelterDirectionNorthWest => 'north-west';

  @override
  String shelterShowOnMap(String name) {
    return 'Show $name on the map';
  }

  @override
  String shelterMarkerTooltip(String name, String confidence, String source) {
    return '$name · $confidence · $source';
  }

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
  String get settingsExpiryRemindersUnsupported =>
      'Linux has no scheduled notifications — the desktop standard only knows immediate ones. Warnings still arrive.';

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
  String get settingsScheduledRemindersUnsupported =>
      'Linux does not support scheduled notifications.';

  @override
  String get settingsChargeReminderTitle => 'Check batteries and devices';

  @override
  String get settingsChargeReminderHint =>
      'Reminds you to charge and test power banks, rechargeable batteries, torches and emergency radios.';

  @override
  String get settingsChargeReminderDisabledHint =>
      'Turn on notifications above to schedule the charging reminder.';

  @override
  String get settingsChargeReminderNoneHint =>
      'No charging reminder is scheduled.';

  @override
  String get settingsChargeReminderCustom => 'Custom…';

  @override
  String get settingsChargeReminderCustomTitle => 'Own interval';

  @override
  String get settingsChargeReminderCustomLabel => 'Days between checks';

  @override
  String settingsChargeReminderCustomInvalid(int min, int max) {
    return 'Enter a whole number between $min and $max.';
  }

  @override
  String get settingsChargeReminderOff => 'Off';

  @override
  String chargeReminderInterval(int days) {
    return 'every $days days';
  }

  @override
  String get chargeReminderTitle => 'Check batteries and devices';

  @override
  String get chargeReminderBody =>
      'Charge and test power banks, rechargeable batteries, torches and emergency radios.';

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
  String stepperDecrease(String label) {
    return 'One fewer: $label';
  }

  @override
  String stepperIncrease(String label) {
    return 'One more: $label';
  }

  @override
  String stepperValue(String label, int value) {
    return '$label: $value';
  }

  @override
  String deleteItemAction(String item) {
    return 'Delete “$item”';
  }

  @override
  String get mapDownloadSearchAction => 'Search for this place';

  @override
  String warningBannerSeverity(String severity, String headline) {
    return '$severity: $headline';
  }

  @override
  String get shoppingListTitle => 'Shopping list';

  @override
  String shoppingListTargetHeading(int days) {
    return 'Against the target for $days days';
  }

  @override
  String shoppingListTargetMet(int days) {
    return 'Water and energy are covered for $days days.';
  }

  @override
  String shoppingListWaterGap(String liters) {
    return '$liters l of water still to buy';
  }

  @override
  String shoppingListEnergyGap(String kcal) {
    return '$kcal kcal of food still to buy';
  }

  @override
  String shoppingListDaysCovered(int covered, int days) {
    return 'The stores currently last $covered of $days days.';
  }

  @override
  String get shoppingListDaysUnknown =>
      'No people in the household, so there is nothing to work out.';

  @override
  String get shoppingListItemsHeading => 'Below the minimum';

  @override
  String get shoppingListItemsEmpty => 'Nothing is below its minimum.';

  @override
  String get shoppingListNoMinimums =>
      'Only items you gave a minimum quantity appear here. Set one on an item and it will be watched.';

  @override
  String shoppingListShortfall(String amount, String unit, String minimum) {
    return '$amount $unit short of $minimum';
  }

  @override
  String get shoppingListCopy => 'Copy list';

  @override
  String get shoppingListCopied => 'Shopping list copied.';

  @override
  String get shoppingListEmpty =>
      'Nothing to buy: the target is met and every item is above its minimum.';

  @override
  String get rotationTitle => 'Use next';

  @override
  String get rotationExpiredHeading => 'Past its date';

  @override
  String get rotationSoonHeading => 'Use soon';

  @override
  String get rotationLaterHeading => 'Keeps for now';

  @override
  String rotationExpiredSince(int days) {
    return '$days days past';
  }

  @override
  String get rotationExpiresToday => 'Today';

  @override
  String rotationDaysLeft(int days) {
    return '$days days left';
  }

  @override
  String get rotationEmpty =>
      'Nothing here to rotate. Only items with a date and something left in them are listed.';

  @override
  String get rotationHint =>
      'Salt and the like carry no date and are left out on purpose — they would bury the rows that do have one.';

  @override
  String get consumeScanAction => 'Scan to use';

  @override
  String consumeScanNotFound(String barcode) {
    return 'No item with barcode $barcode in this household.';
  }

  @override
  String get sharingErrorLocked =>
      'This folder is encrypted and this device does not have the passphrase. Nothing is being read or written until you enter it.';

  @override
  String get folderEncryptionTitle => 'Encrypt the shared folder';

  @override
  String get folderEncryptionOff =>
      'Off. Everything in the folder is readable by anyone who can see it — including your sync provider.';

  @override
  String get folderEncryptionOn => 'On. The folder holds only sealed files.';

  @override
  String get folderEncryptionEnable => 'Turn on encryption';

  @override
  String get folderEncryptionUnlock => 'Enter passphrase';

  @override
  String get folderEncryptionPassphrase => 'Passphrase';

  @override
  String get folderEncryptionRepeat => 'Repeat passphrase';

  @override
  String get folderEncryptionMismatch => 'The two entries are not the same.';

  @override
  String folderEncryptionTooShort(int count) {
    return 'At least $count characters. This is the only thing standing between the folder and whoever can read it.';
  }

  @override
  String get folderEncryptionWrong =>
      'That passphrase does not open this folder.';

  @override
  String get folderEncryptionNoRecovery =>
      'There is no way back in without it. PreppSuite cannot reset it, and neither can anyone else — write it down somewhere safe before you continue.';

  @override
  String get folderEncryptionOtherDevices =>
      'Every other device in this household has to be updated and given the same passphrase. Until it is, it stops seeing new rows.';

  @override
  String get folderEncryptionEnabled => 'The shared folder is now encrypted.';

  @override
  String get folderEncryptionUnlocked => 'Folder unlocked.';

  @override
  String get folderEncryptionWorking =>
      'Deriving the key. This takes a moment on purpose.';

  @override
  String get householdPlanTitle => 'Emergency plan';

  @override
  String get householdPlanIntro =>
      'Agreed before it is needed. Everyone in the household should know these by heart, so write down only what you would actually say out loud.';

  @override
  String get householdPlanEmpty => 'Nothing agreed yet.';

  @override
  String get householdPlanMeetingNear => 'Meeting point nearby';

  @override
  String get householdPlanMeetingNearHint =>
      'Reachable on foot, without a plan — the corner, the neighbour\'s drive.';

  @override
  String get householdPlanMeetingFar => 'Meeting point further out';

  @override
  String get householdPlanMeetingFarHint =>
      'For when the whole area is cleared and the near one cannot be reached.';

  @override
  String get householdPlanContactName => 'Out-of-area contact';

  @override
  String get householdPlanContactNameHint =>
      'Someone outside the region everyone rings. Local lines are the first to congest; a call to the next county often gets through when one across the street does not.';

  @override
  String get householdPlanContactPhone => 'Their number';

  @override
  String get householdPlanKitLocation => 'Where the emergency luggage is';

  @override
  String get householdPlanKitLocationHint =>
      'So nobody searches for it in the dark.';

  @override
  String get householdPlanShutoff => 'Where water, gas and power are shut off';

  @override
  String get householdPlanNotes => 'Anything else';

  @override
  String get householdPlanSaved => 'Plan saved.';

  @override
  String get householdPlanCleared => 'Plan removed.';

  @override
  String get householdPlanClear => 'Remove plan';

  @override
  String get householdPlanClearConfirm =>
      'Remove the plan for every device in this household?';

  @override
  String get householdPlanShared =>
      'This plan reaches every device in the household through the shared folder.';

  @override
  String get householdPlanNothingEntered =>
      'Write down at least one thing before saving.';

  @override
  String get drillsEmergencyMode => 'Emergency mode';

  @override
  String get drillsCallEmergency => 'Call 112';

  @override
  String get drillsHarmless =>
      'A drill changes no supplies and sends no messages.';

  @override
  String get drillsReset => 'Start over';

  @override
  String get drillsTitle => 'Emergency mode and drills';

  @override
  String get drillsSubtitle =>
      'A card to work through, and realistic household drills';

  @override
  String get drillsImmediateDanger =>
      'In immediate danger, call 112 first. Then check the official warnings, tell your family what the household plan says, and save power.';

  @override
  String get drillsSectionTitle => 'Drill mode';

  @override
  String get emergencyCardsTitle => 'Emergency cards';

  @override
  String get emergencyCardsIntro =>
      'What an ambulance would want to know, for each person in the household. Only the name is needed — a card that says nothing but a name and an allergy is worth having.';

  @override
  String get emergencyCardsEmpty => 'No cards yet.';

  @override
  String emergencyCardsCount(int count) {
    return '$count people';
  }

  @override
  String get emergencyCardAdd => 'Add person';

  @override
  String get emergencyCardEdit => 'Edit card';

  @override
  String get emergencyCardName => 'Name';

  @override
  String get emergencyCardBirthYear => 'Year of birth';

  @override
  String get emergencyCardBirthYearHint =>
      'The year only. A paramedic needs roughly who they are treating, not a birthday.';

  @override
  String get emergencyCardBloodType => 'Blood type';

  @override
  String get emergencyCardAllergies => 'Allergies';

  @override
  String get emergencyCardMedication => 'Regular medication';

  @override
  String get emergencyCardMedicationHint =>
      'The thing to keep in the stores, and the thing nobody should have to guess at.';

  @override
  String get emergencyCardConditions => 'Conditions';

  @override
  String get emergencyCardInsurance => 'Health insurance';

  @override
  String get emergencyCardDoctor => 'Doctor';

  @override
  String get emergencyCardContact => 'Who to call about this person';

  @override
  String get emergencyCardNotes => 'Anything else';

  @override
  String get emergencyCardNameRequired => 'A card needs a name.';

  @override
  String get emergencyCardSaved => 'Card saved.';

  @override
  String get emergencyCardRemoved => 'Card removed.';

  @override
  String get emergencyCardRemove => 'Remove card';

  @override
  String emergencyCardRemoveConfirm(String name) {
    return 'Remove the card for $name from every device in this household?';
  }

  @override
  String get emergencyCardsHealthWarning =>
      'This is health data, and it travels through the shared folder to every device. Encrypt the folder before you put it in.';

  @override
  String get emergencyCardsHealthEncrypted =>
      'This is health data. The shared folder it travels through is encrypted.';

  @override
  String get emergencyCardsGoToEncryption => 'Folder settings';

  @override
  String get emergencyCardBirthYearInvalid => 'That is not a year.';

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

  @override
  String get navKnowledge => 'Knowledge';

  @override
  String get knowledgeTitle => 'Knowledge';

  @override
  String get knowledgeEmptyTitle => 'No knowledge file yet';

  @override
  String get knowledgeEmptyBody =>
      'A ZIM file on the device — Kiwix\'s Wikipedia, for instance — makes looking things up independent of the network. Where to get one is in docs/wissen-offline.md.';

  @override
  String get knowledgeChooseAction => 'Choose a file';

  @override
  String get knowledgeChangeAction => 'Choose a different file';

  @override
  String get knowledgeForgetAction => 'Remove file';

  @override
  String get articleLinkLeavesArchive =>
      'That link points outside the archive. PreppSuite only shows what is in the file.';

  @override
  String get knowledgeSearchHint => 'Search titles';

  @override
  String get knowledgeSearchNote =>
      'Searches titles, not the text of the articles.';

  @override
  String knowledgeNoResults(String query) {
    return 'No title starts with “$query”.';
  }

  @override
  String get knowledgeSearchPrompt => 'Type a beginning to search.';

  @override
  String get knowledgeSuggestionsTitle => 'Where to start';

  @override
  String get knowledgeSuggestionsBody =>
      'You can keep several archives side by side and switch with one tap. The files stay where they are.';

  @override
  String get knowledgeSuggestionWikibooks =>
      'Textbooks, including a full secondary-school maths course.';

  @override
  String get knowledgeSuggestionKlexikon =>
      'An encyclopedia written for primary-school children.';

  @override
  String get knowledgeSuggestionPhet =>
      'Interactive physics, chemistry and maths experiments.';

  @override
  String get knowledgeSuggestionWikiversity => 'Course and teaching material.';

  @override
  String get knowledgeSuggestionWikipedia =>
      'Everything else. The largest of these by far.';

  @override
  String get knowledgeSuggestionMedicine =>
      'Wikipedia\'s medical articles alone, at a fraction of the size.';

  @override
  String get knowledgeSuggestionIfixit =>
      'Repair instructions for appliances and electronics, with pictures.';

  @override
  String get knowledgeSuggestionKhan =>
      'The school curriculum end to end — English only, no German archive exists.';

  @override
  String get knowledgeAddAction => 'Add another archive';

  @override
  String get knowledgeRemoveAction => 'Remove this archive';

  @override
  String get knowledgeLibraryLabel => 'Archives on this device';

  @override
  String knowledgeSwitchFailed(String name) {
    return '$name cannot be opened. The file may have moved.';
  }

  @override
  String get knowledgeErrorUnreadable =>
      'The file cannot be read. A ZIM archive is expected, of the kind Kiwix publishes.';

  @override
  String get knowledgeArticleUnsupported =>
      'Articles cannot be shown on this platform — the browser component is missing. Searching works, reading does not.';

  @override
  String get knowledgeArticleNoEngine =>
      'The system\'s browser component is missing. On Linux that is WebKitGTK (package libwebkit2gtk-4.1), on Windows the WebView2 runtime.';

  @override
  String knowledgeSource(String name) {
    return 'From $name';
  }

  @override
  String get knowledgeModeTitles => 'Titles';

  @override
  String get knowledgeModeFullText => 'Full text';

  @override
  String get knowledgeFullTextNote => 'Searches the text of the articles.';

  @override
  String get knowledgeIndexMissingTitle => 'No full-text index';

  @override
  String get knowledgeIndexMissingBody =>
      'Searching the text needs an index. The app builds it once — after that it answers instantly.';

  @override
  String get knowledgeIndexCountAction => 'Count articles';

  @override
  String get knowledgeIndexBuildAction => 'Build index';

  @override
  String get knowledgeIndexContinueAction => 'Keep building';

  @override
  String get knowledgeIndexCancelAction => 'Stop';

  @override
  String get knowledgeIndexDiscardAction => 'Discard index';

  @override
  String knowledgeIndexArticles(int count) {
    return '$count articles in this file.';
  }

  @override
  String get knowledgeIndexLargeWarning =>
      'That is a lot. Expect an hour or more and several gigabytes on disk. You can stop at any time and keep what was done.';

  @override
  String knowledgeIndexScanning(int done, int total) {
    return 'Counting articles: $done of $total.';
  }

  @override
  String knowledgeIndexIndexing(int done, int total) {
    return '$done of $total articles.';
  }

  @override
  String knowledgeIndexPartial(int done, int total) {
    return 'Stopped at $done of $total articles. Searches what is already in there.';
  }

  @override
  String knowledgeIndexReady(int count) {
    return '$count articles indexed.';
  }

  @override
  String get knowledgeIndexBuiltInTitle => 'The archive brings its own index';

  @override
  String knowledgeIndexBuiltIn(int count) {
    return '$count articles, searchable right away. The archive carries its own full-text index, so there is nothing to build.';
  }

  @override
  String get knowledgeIndexBuiltInStemming =>
      'Queries match word stems: \"supplies\" also finds \"supply\".';

  @override
  String get downloadFolderTitle => 'Download folder';

  @override
  String get downloadFolderChange => 'Choose folder';

  @override
  String get downloadFolderReset => 'Reset';

  @override
  String downloadRunningLabel(String name) {
    return 'Downloading $name';
  }

  @override
  String get downloadCancelAction => 'Cancel';

  @override
  String downloadFailedLabel(String error) {
    return 'Download stopped: $error';
  }

  @override
  String downloadFinishedLabel(String name) {
    return '$name has finished downloading.';
  }

  @override
  String downloadNotOpenedLabel(String name, String reason) {
    return '$name has downloaded, but cannot be opened: $reason';
  }

  @override
  String get downloadRetryAction => 'Try again';

  @override
  String get downloadDismissAction => 'Dismiss';

  @override
  String downloadOfSize(String done, String total) {
    return '$done of $total';
  }

  @override
  String progressPercent(int percent) {
    return '$percent%';
  }

  @override
  String get downloadBusyMessage =>
      'A download is already running. Only one goes at a time.';

  @override
  String get downloadStartAction => 'Download';

  @override
  String get downloadConfirmTitle => 'Download?';

  @override
  String downloadConfirmBody(String name, String size, String folder) {
    return '$name is $size and will be saved to $folder. It keeps going while the app stays open, and can be resumed later.';
  }

  @override
  String get knowledgeDownloadAction => 'Download an archive';

  @override
  String get kiwixTitle => 'Kiwix library';

  @override
  String get kiwixIntro =>
      'Wikipedia and other collections as a ZIM file, free and without an account. Pick a language and download what you want offline.';

  @override
  String get kiwixLanguageLabel => 'Language';

  @override
  String get kiwixSearchHint => 'Search collections';

  @override
  String get kiwixNoResults =>
      'Nothing found. Another language, or another search term?';

  @override
  String kiwixLoadError(String error) {
    return 'The library could not be reached: $error';
  }

  @override
  String kiwixArticleCount(String count) {
    return '$count articles';
  }

  @override
  String get kiwixFullTextTag => 'full-text index';

  @override
  String get kiwixFlavourMaxi => 'complete';

  @override
  String get kiwixFlavourMini => 'introductions only';

  @override
  String get kiwixFlavourNopic => 'without pictures';

  @override
  String kiwixResultCount(String shown, String total) {
    return '$shown of $total';
  }

  @override
  String get kiwixLoadMore => 'Load more';

  @override
  String get mapDownloadAction => 'Download a map';

  @override
  String get mapDownloadTitle => 'Download map area';

  @override
  String get mapDownloadIntro =>
      'Move the map to the area you need offline. Exactly what you can see is what gets downloaded.';

  @override
  String get mapDownloadZoomLabel => 'Detail';

  @override
  String get mapDownloadZoomHint =>
      'Level 12 shows towns and main roads, level 14 individual streets and buildings.';

  @override
  String mapDownloadTileCount(String count, String size) {
    return '$count tiles, roughly $size';
  }

  @override
  String mapDownloadTooLarge(String count) {
    return '$count tiles is too many. Shrink the area or the detail level.';
  }

  @override
  String mapDownloadRunning(String done, String total, String size) {
    return '$done of $total tiles, $size downloaded';
  }

  @override
  String get mapDownloadFinished => 'The map is ready and now in use.';

  @override
  String mapDownloadFailed(String error) {
    return 'The download failed: $error';
  }

  @override
  String get mapDownloadSourceLabel => 'Map source';

  @override
  String get mapDownloadSourceOpenFreeMap => 'OpenFreeMap (free, no key)';

  @override
  String get mapDownloadSourceMapTiler =>
      'MapTiler (needs an account and a key)';

  @override
  String get mapDownloadApiKeyLabel => 'API key';

  @override
  String get mapDownloadApiKeyHint =>
      'From your MapTiler account. Stays on this device.';

  @override
  String get mapDownloadApiKeyMissing => 'This source needs a key.';

  @override
  String get mapDownloadPolite =>
      'The tiles come from a public server other people use too. Take no more than you need.';

  @override
  String mapDownloadLabel(String zoom) {
    return 'Own area, level $zoom';
  }

  @override
  String get mapDownloadSearchHint => 'Town, district, state or country';

  @override
  String get mapDownloadSearchNoResults => 'Nothing found. Another name?';

  @override
  String mapDownloadSearchFailed(String error) {
    return 'The place search could not be reached: $error';
  }

  @override
  String get mapDownloadAreaViewport => 'Visible area';

  @override
  String mapDownloadAreaPlace(String name, String kind) {
    return '$name · $kind';
  }

  @override
  String get mapDownloadDetailAuto =>
      'The deepest level this area still fits at.';

  @override
  String mapDownloadPlaceTooLarge(String name) {
    return '$name is too large even at the coarsest level. Choose somewhere smaller.';
  }

  @override
  String mapDownloadDeepestPossible(String count, String level) {
    return 'At level 14 that would be $count tiles — too many. Level $level is the deepest this area goes.';
  }

  @override
  String get mapDownloadScopeLabel => 'Scope';

  @override
  String get mapDownloadScopePlace => 'This place only';

  @override
  String get mapDownloadScopeRegion => 'With the state';

  @override
  String get mapDownloadScopeCountry => 'Whole country';

  @override
  String get mapDownloadWorldBase => 'World';

  @override
  String get mapDownloadScopeContinent => 'Whole continent';

  @override
  String get mapContinentEurope => 'Europe';

  @override
  String get mapContinentAfrica => 'Africa';

  @override
  String get mapContinentAsia => 'Asia';

  @override
  String get mapContinentNorthAmerica => 'North America';

  @override
  String get mapContinentSouthAmerica => 'South America';

  @override
  String get mapContinentOceania => 'Oceania';

  @override
  String get mapDownloadStaggered =>
      'Staggered: coarser further out, full detail in the middle.';

  @override
  String mapDownloadStep(String label, String from, String to, String count) {
    return '$label: level $from to $to, $count tiles';
  }

  @override
  String get mapDownloadNoPlan =>
      'Even staggered this does not fit. Choose somewhere smaller.';

  @override
  String mapDownloadEstimatedTime(String minutes) {
    return 'Takes roughly $minutes minutes.';
  }

  @override
  String get mapDownloadResolving => 'Working out the surroundings …';

  @override
  String get mapDownloadUnfinishedTitle => 'Unfinished download';

  @override
  String mapDownloadUnfinishedBody(String label, String done, String total) {
    return '$label — $done of $total tiles are already here.';
  }

  @override
  String get mapDownloadResumeAction => 'Resume';

  @override
  String get mapDownloadDiscardAction => 'Discard';

  @override
  String get settingsLocationServicesOff =>
      'Location services are switched off. Turn them on in the system settings.';

  @override
  String get settingsLocationDeniedForever =>
      'Location access is denied for PreppSuite. The system will not ask again — allow it in the system settings.';

  @override
  String get settingsLocationDenied =>
      'This needs access to your location. Pick the federal state from the list instead.';

  @override
  String settingsLocationUnavailable(String detail) {
    return 'Location is not available on this device: $detail';
  }

  @override
  String get navMap => 'Map';

  @override
  String get mapMyLocationAction => 'My location';

  @override
  String get mapSourceOffline => 'Offline';

  @override
  String get mapSourceOnline => 'Online';

  @override
  String mapSourceOfflineDetail(String name, int min, int max) {
    return 'Drawing from $name, zoom $min to $max.';
  }

  @override
  String get mapSourceOnlineDetail =>
      'Drawing tiles from OpenStreetMap. Needs a connection.';

  @override
  String get mapSourceNoArchive =>
      'No map on this device yet. Until one is downloaded, the tiles come from OpenStreetMap and need a connection.';

  @override
  String get mapZoomIn => 'Zoom in';

  @override
  String get mapZoomOut => 'Zoom out';

  @override
  String supplyCalculatorHouseholdLine(String who) {
    return '$who — from the household';
  }

  @override
  String get supplyCalculatorEditHousehold => 'Change in the household';

  @override
  String supplyCalculatorAdults(String count) {
    return '$count adults';
  }

  @override
  String supplyCalculatorChildren(String count) {
    return '$count children';
  }

  @override
  String supplyCalculatorDogs(String count) {
    return '$count dogs';
  }

  @override
  String supplyCalculatorCats(String count) {
    return '$count cats';
  }

  @override
  String get supplyCalculatorPetFoodNote =>
      'Pet food is not counted in the calories — dogs and cats need a supply of their own. Their drinking water is included.';

  @override
  String get supplyCalculatorSourceTitle => 'Where the numbers come from';

  @override
  String get supplyCalculatorSourceBody =>
      'For adults the BBK states 1.5 litres of fluid a day plus 0.5 litres for cooking, and around 2200 kcal. For children the BBK itself states nothing, but points at the Federal Office for Agriculture and Food, whose stockpiling table says it in a footnote: children up to 12 (not infants) need an average of 1 litre a day, per the DGE and the Max Rubner Institute. The app uses that — 1 litre plus the same 0.5 litres for cooking. From 65 the same footnote recommends 2 litres a day; age is not in the household profile, so that appears only as a note on the inventory screen. The 1400 kcal for a child remain this app\'s own cautious estimate — there is no official figure. For dogs and cats only water is counted, at the veterinary rule of thumb of roughly 60 ml per kilogram: 1.2 litres for a 20 kg dog, 0.25 litres for a 4 kg cat. For anything exact, the BMEL\'s Vorratskalkulator.';

  @override
  String get householdChildrenLabel => 'Children';

  @override
  String get householdDogsLabel => 'Dogs';

  @override
  String get householdCatsLabel => 'Cats';

  @override
  String get householdAdultsLabel => 'Adults';

  @override
  String get storageTipsTitle => 'Storage tips';

  @override
  String get storageTipsIntro =>
      'The BBK recommends a ten-day supply and, for the amounts, points at the stockpiling tables of the Federal Office for Agriculture and Food. They are here — scaled to your household.';

  @override
  String storagePeopleLine(Object count) {
    return 'For $count people — from the household';
  }

  @override
  String storageDaysLabel(Object days) {
    return '$days days';
  }

  @override
  String get storageFewerDays => 'One day fewer';

  @override
  String get storageMoreDays => 'One day more';

  @override
  String get storageScaledNote =>
      'The table is printed for one person and ten days. Every amount here is converted.';

  @override
  String get storageDietMixed => 'Mixed diet';

  @override
  String get storageDietVegetarian => 'Vegetarian';

  @override
  String storageAmountGrams(Object value) {
    return '$value g';
  }

  @override
  String storageAmountKilograms(Object value) {
    return '$value kg';
  }

  @override
  String storageAmountLiters(Object value) {
    return '$value l';
  }

  @override
  String storageAmountPieces(Object count) {
    return '$count pcs';
  }

  @override
  String storageKcal(Object kcal) {
    return '$kcal kcal';
  }

  @override
  String storageVariantLine(Object kcal, Object name) {
    return 'or $name: $kcal kcal';
  }

  @override
  String get storageAddToInventory => 'Add to inventory';

  @override
  String get storageFromTableNote => 'Taken from the BLE stockpiling table.';

  @override
  String get storageUnitGram => 'g';

  @override
  String get storageUnitLiter => 'l';

  @override
  String get storageUnitPiece => 'pcs';

  @override
  String get storageNutrientProtein => 'Protein';

  @override
  String get storageNutrientFiber => 'Fibre';

  @override
  String get storageNutrientIron => 'Iron';

  @override
  String get storageNutrientVitaminB12 => 'Vitamin B12';

  @override
  String get storageNutrientHealthyFats => 'Healthy fats';

  @override
  String get storageNutrientFluid => 'Fluid';

  @override
  String get storageNutrientLegendTitle => 'What the markers mean';

  @override
  String get storageNutrientLegendBody =>
      'The markers on the foods are not in the official table — they are this app\'s own reading. They show what a food is mainly there for, so you can see what leaves with a group you drop. Orientation, not dietary advice.';

  @override
  String get storageTipsGeneralTitle => 'General tips';

  @override
  String get storageTipRotate =>
      'Rotate the stock: always use the oldest first and replace it. Then nothing expires and nothing was bought for the bin.';

  @override
  String get storageTipCoolDryDark =>
      'Store cool, dry and dark, ideally in tightly closing containers.';

  @override
  String get storageTipEatWhatYouStore =>
      'Only store what you actually eat. A supply nobody likes is never used up and eventually thrown away.';

  @override
  String get storageTipNoPower =>
      'Count on a power cut: plan nothing that has to be refrigerated or frozen.';

  @override
  String get storageTipReadyToEat =>
      'Choose part of it so that it can be eaten without cooking — in case the gas or the hob goes too.';

  @override
  String get storageTipCanOpener =>
      'Remember a tin opener that works without electricity.';

  @override
  String get storageTipSpecialNeeds =>
      'Small children, pets, medication and special diets belong on the list too. The table does not cover them.';

  @override
  String get storageVeganTitle => 'Vegan?';

  @override
  String get storageVeganBody =>
      'There is no official vegan table — the BLE publishes these two and no third, and the app does not invent one. On a vegan diet, two lines of the vegetarian table are replaced: 2.5 kg of milk and dairy, and the five eggs. Fortified plant drinks and soy products cover protein and calcium. For vitamin B12, iodine, iron and omega-3 the DGE issues an explicit warning on a vegan diet — B12 can only be covered reliably by a supplement, and that then belongs in the supply like everything else.';

  @override
  String get storageSourceTitle => 'Where the numbers come from';

  @override
  String get storageSourceBody =>
      'On its \"Bevorraten\" page the BBK gives ten days and 1.5 litres of fluid plus 0.5 litres for cooking a day; for the amounts it points at the stockpiling tables of the Federal Office for Agriculture and Food (BLE, 2024, ernaehrungsvorsorge.de). Every line here comes from there: a basic supply for one person and ten days at an average 2,200 kcal a day, once as a mixed diet and once ovo-lacto-vegetarian. The energy figures are from the Bundeslebensmittelschlüssel 3.02 of the Max Rubner Institute; the amounts follow the DGE, ÖGE and SGE reference values. Scaling is linear in people and days. The markers on the foods are this app\'s addition and appear in no official table.';

  @override
  String get nutritionSectionTitle => 'Nutrition';

  @override
  String get nutritionSectionHint =>
      'For the whole amount, not per 100 g. Scanning a barcode fills in whatever the label states.';

  @override
  String get proteinLabel => 'Protein';

  @override
  String get carbohydrateLabel => 'Carbohydrates';

  @override
  String get fatLabel => 'Fat';

  @override
  String get fiberLabel => 'Fibre';

  @override
  String get supplyCalculatorSeniorNote =>
      'From 65 the DGE recommends 2 litres of drinking a day rather than 1.5 — so plan half a litre more per person and day for older people in the household.';

  @override
  String get warningFilterSearchHint => 'Place, region or keyword';

  @override
  String get warningFilterSearchClear => 'Clear search';

  @override
  String get warningFilterActive => 'Active';

  @override
  String get warningFilterExpired => 'Expired';

  @override
  String get warningFilterMyRegions => 'My regions';

  @override
  String get warningFilterSevere => 'Severe and up';

  @override
  String warningFilterResultCount(Object shown, Object total) {
    return '$shown of $total warnings';
  }

  @override
  String get warningFilterClear => 'Clear filter';

  @override
  String warningsEmptyFiltered(Object total) {
    return 'None of the $total warnings match the filter.';
  }

  @override
  String get checklistCategoryInformation => 'Staying informed';

  @override
  String get checklistCategoryEvacuation => 'Emergency luggage';

  @override
  String get checklistCategorySafety => 'Safety at home';

  @override
  String get checklistCategoryHazards => 'Natural hazards';

  @override
  String get checklistCategoryWellbeing => 'Fears and worries';

  @override
  String get checklistCategoryPets => 'Pets';

  @override
  String get navOverview => 'Overview';

  @override
  String get navWarnings => 'Warnings';

  @override
  String get navMore => 'More';

  @override
  String overviewSupplyTitle(Object days) {
    return 'Supply for $days days';
  }

  @override
  String overviewSupplyWater(Object current, Object target) {
    return '$current of $target L';
  }

  @override
  String overviewSupplyCalories(int current, int target) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$currentString of $targetString kcal';
  }

  @override
  String get overviewAttentionTitle => 'Needs attention';

  @override
  String get overviewNothingStored =>
      'Nothing has been added to the inventory yet.';

  @override
  String get overviewChargeDue => 'Check the rechargeable equipment';

  @override
  String overviewChargeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'one day',
    );
    return 'Overdue by $_temp0';
  }

  @override
  String get overviewChargeDueToday => 'Due today';

  @override
  String overviewChargeNext(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'one day',
    );
    return 'Next check in $_temp0';
  }

  @override
  String get overviewChargeNeverChecked => 'Not confirmed yet';

  @override
  String get overviewChargeDone => 'Checked';

  @override
  String get overviewExpired => 'expired';

  @override
  String get overviewLowStock => 'below minimum';

  @override
  String get overviewExpiringSoon => 'expires within 30 days';

  @override
  String get overviewNoWarnings => 'No warnings for your regions right now.';

  @override
  String overviewChecklistLists(Object complete, Object total) {
    return '$complete of $total lists complete';
  }

  @override
  String get overviewResourcesTitle => 'Resources';

  @override
  String overviewItemCount(Object count) {
    return '$count entries';
  }

  @override
  String get photoEditTitle => 'Crop photo';

  @override
  String get photoEditHint => 'Drag the frame onto the part you want to keep.';

  @override
  String get photoEditRotateLeft => 'Rotate left';

  @override
  String get photoEditRotateRight => 'Rotate right';

  @override
  String get photoEditReset => 'Whole picture';

  @override
  String get photoEditFailed =>
      'This picture cannot be edited. It stays as it is.';

  @override
  String get editPhotoButton => 'Crop photo';

  @override
  String get sharingErrorEncryptionChanged =>
      'Sync stopped: encryption metadata is missing or was reset. Restore the encrypted household.json from a backup. No unencrypted household data was written.';

  @override
  String get searchUnavailable =>
      'Search is currently unavailable. Please try again.';

  @override
  String get inventoryFilters => 'Filter and sort';

  @override
  String get inventoryFilterCategory => 'Category';

  @override
  String get inventoryFilterLocation => 'Storage location';

  @override
  String get inventoryFilterStatus => 'Stock status';

  @override
  String get inventoryFilterAll => 'All';

  @override
  String get inventoryNoLocation => 'No storage location';

  @override
  String get inventoryExpiringSoon => 'Expires in the next 7 days';

  @override
  String get inventorySortLabel => 'Sort by';

  @override
  String get inventorySortName => 'Name';

  @override
  String get inventorySortExpiry => 'Expiry date';

  @override
  String get inventorySortAttention => 'Needs attention';

  @override
  String get inventoryApplyFilters => 'Apply';

  @override
  String get inventoryResetFilters => 'Reset filters';

  @override
  String get inventoryFiltersActive => 'Filters active';

  @override
  String get inventorySearchHint => 'Search supplies';

  @override
  String get inventoryClearSearch => 'Clear search';

  @override
  String get inventoryNoMatches =>
      'No matching supplies. Adjust your search or filters.';

  @override
  String get unsavedChangesTitle => 'Discard changes?';

  @override
  String get unsavedChangesMessage => 'Your changes have not been saved yet.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discardChanges => 'Discard';

  @override
  String get inventoryItemDeleted => 'Supply deleted';

  @override
  String get undoAction => 'Undo';

  @override
  String get overviewStartTitle => 'Your first step towards preparedness';

  @override
  String get overviewStartHint =>
      'Add water or food to see how long your household supplies will last.';

  @override
  String get overviewAddFirst => 'Add your first supply';

  @override
  String get overviewOpen => 'Open';

  @override
  String get warningMoreInformation =>
      'More information from the warning source';

  @override
  String get moreActions => 'More actions';

  @override
  String get checklistLinkStockAction => 'Link to stock';

  @override
  String get checklistLinkStockTitle => 'Choose stock item';

  @override
  String get checklistUnlinkStockAction => 'Remove link';

  @override
  String get checklistNoStockToLink => 'There is no stock item to link yet.';

  @override
  String checklistLinkedStock(String name, num quantity, String unit) {
    return '$name: $quantity $unit available';
  }

  @override
  String get navEmergency => 'Emergency';

  @override
  String get emergencyTitle => 'Emergency & readiness';

  @override
  String get emergencyCall112 => 'Emergency 112';

  @override
  String get emergencyCall110 => 'Police 110';

  @override
  String get emergencyCurrentWarnings => 'Current warnings';

  @override
  String get emergencyNoWarnings => 'No relevant active warnings';

  @override
  String get readinessTitle => 'Offline readiness';

  @override
  String get readinessReady => 'ready';

  @override
  String get readinessNeedsWork => 'open';

  @override
  String get readinessInventory => 'Stock recorded';

  @override
  String get readinessChecklists => 'Checklists started';

  @override
  String get readinessPlan => 'Emergency plan completed';

  @override
  String get readinessCards => 'Emergency cards recorded';

  @override
  String get readinessMap => 'Offline map available';

  @override
  String get readinessKnowledge => 'Offline knowledge available';

  @override
  String get emergencyPlanMissing => 'Emergency plan has not been completed';

  @override
  String get emergencyPlanHeading => 'Important details';

  @override
  String get knowledgeManageArchives => 'Manage archives';

  @override
  String knowledgeArchiveCount(int count) {
    return '$count archives on this device';
  }

  @override
  String get knowledgeArchiveSelected => 'Currently open';

  @override
  String get backupTitle => 'Backup & restore';

  @override
  String get backupCreate => 'Create data backup';

  @override
  String get backupRestore => 'Restore data backup';

  @override
  String get backupHint =>
      'Stock, checklists, emergency plan and emergency cards. The file contains personal data and should be stored securely.';

  @override
  String get backupCreated => 'Data backup saved.';

  @override
  String backupRestored(int count) {
    return 'Backup restored: $count newer records applied.';
  }

  @override
  String get backupInvalid =>
      'This backup belongs to a different household or is damaged.';

  @override
  String get backupFailed => 'The data backup could not be processed.';

  @override
  String get backupPassphraseTitle => 'Encrypt backup';

  @override
  String get backupPassphrase => 'Password';

  @override
  String get backupPassphraseRepeat => 'Repeat password';

  @override
  String get backupPassphraseInvalid =>
      'Enter at least 12 characters; both entries must match.';

  @override
  String get warningInstructionsTitle => 'Recommended actions';

  @override
  String get warningAreaTitle => 'Affected area';

  @override
  String get warningContactTitle => 'Publisher and contact';

  @override
  String get warningShowMap => 'Show area on map';

  @override
  String warningDetailsPeriod(String start, String end) {
    return 'Alert from: $start – $end';
  }

  @override
  String get warningDetailsUntilFurtherNotice => 'until further notice';

  @override
  String warningDetailsLevel(String severity) {
    return 'Alert level: $severity';
  }

  @override
  String get warningDetailsAffectedRegions => 'Affected region(s)';

  @override
  String get warningDetailsNoInstructions =>
      'No recommended actions were provided for this alert.';

  @override
  String get warningDetailsNoArea =>
      'The warning source did not specify the affected area further.';

  @override
  String get warningDetailsSource => 'Warning source and publication';

  @override
  String warningDetailsPublished(String time) {
    return 'Published: $time';
  }

  @override
  String get warningDetailsOfflineHint =>
      'The map, area and recommended actions were saved with this alert and remain readable offline.';

  @override
  String get knowledgeBrowseTitle => 'Browse archive';

  @override
  String get knowledgeBrowseBody =>
      'Open the main page, choose an initial letter, or discover a random article.';

  @override
  String get knowledgeMainPageAction => 'Main page';

  @override
  String get knowledgeRandomAction => 'Random article';

  @override
  String knowledgeArchiveStats(int articles, String size) {
    return '$articles entries · approximately $size';
  }

  @override
  String knowledgeTotalSize(String size) {
    return 'Total size: approximately $size';
  }

  @override
  String get knowledgeDocumentsTitle => 'Personal documents';

  @override
  String get knowledgeDocumentsIntro =>
      'PDF, EPUB and Markdown files remain in their original location and are not duplicated.';

  @override
  String get knowledgeDocumentAdd => 'Add document';

  @override
  String get knowledgeDocumentsEmpty =>
      'No personal documents have been added yet.';

  @override
  String get knowledgeDocumentOpen => 'Open';

  @override
  String get knowledgeDocumentRemove => 'Remove from library';

  @override
  String get knowledgeDocumentOpenFailed => 'The document could not be opened.';

  @override
  String get emergencyDirectoryTitle => 'Emergency calls, contacts & radio';

  @override
  String get emergencyMedicalService => 'Non-emergency medical service 116117';

  @override
  String get emergencyPoisonTitle => 'Poison control centres';

  @override
  String get emergencyPoisonHint =>
      'For life-threatening symptoms, call 112 first. The responsible poison control centre advises in suspected poisoning cases.';

  @override
  String get emergencyRadioTitle => 'Radio frequency ranges';

  @override
  String get emergencyRadioHint =>
      'Local station frequencies change. Run a station scan during an incident and follow official announcements. Transmit only where the relevant radio service permits it.';

  @override
  String get emergencyContactsTitle => 'Nearby emergency contacts';

  @override
  String get emergencyContactsEmpty => 'No nearby contacts saved yet.';

  @override
  String get emergencyContactAdd => 'Add contact';

  @override
  String get emergencyContactName => 'Name';

  @override
  String get emergencyContactPhone => 'Phone number';

  @override
  String get emergencyContactAddress => 'Address';

  @override
  String get emergencyContactCoordinates => 'Coordinates (latitude, longitude)';

  @override
  String get emergencyContactDelete => 'Delete contact';

  @override
  String get emergencyCallAction => 'Call';

  @override
  String get emergencyOpenMapAction => 'Open on map';

  @override
  String get prepperRecipesTitle => 'Emergency recipes';

  @override
  String get prepperRecipesIntro =>
      'Simple meals from shelf-stable supplies using little water and energy. Adjust quantities to the household.';

  @override
  String get preservationTitle => 'Preserving food';

  @override
  String get preservationIntro =>
      'Established methods for food on hand. Work cleanly, observe safe processing times, and discard swollen or suspicious jars.';

  @override
  String get storageOfficialCalculator => 'Open official stock calculator';

  @override
  String get storageOfficialTips => 'More food preparedness tips';

  @override
  String get resetTitle => 'Reset';

  @override
  String get resetSettings => 'Reset app settings';

  @override
  String get resetSettingsHint =>
      'Restore defaults for language, appearance, notifications, reminders and map provider. Data and downloads remain.';

  @override
  String get resetHousehold => 'Delete household and local data';

  @override
  String get resetHouseholdHint =>
      'Permanently delete this household’s inventory, checklists, emergency plan and emergency cards from this device.';

  @override
  String get resetConfirmTitle => 'Reset now?';

  @override
  String get resetConfirmHousehold =>
      'Local household data will be permanently deleted. Create a backup first if needed.';

  @override
  String get resetDone => 'Reset completed.';

  @override
  String get knowledgeDocumentIndexTitle => 'Offline search';

  @override
  String get knowledgeDocumentIndexOption => 'Make this document searchable';

  @override
  String get knowledgeDocumentIndexPrivacy =>
      'The text index stays only on this device. The original file is not copied.';

  @override
  String get knowledgeDocumentIndexed => 'Ready for offline search';

  @override
  String get knowledgeDocumentIndexing => 'Building index …';

  @override
  String get knowledgeDocumentNotIndexed => 'Not in search';

  @override
  String get knowledgeDocumentNoText => 'No readable text (possibly a scan)';

  @override
  String get knowledgeDocumentTooLarge =>
      'Too large for the index (48 MB maximum)';

  @override
  String get knowledgeDocumentIndexFailed => 'Could not build index';

  @override
  String get knowledgeDocumentReindex => 'Rebuild search index';

  @override
  String get knowledgeDocumentClearIndex => 'Delete search index';

  @override
  String get knowledgeDocumentClearIndexBody =>
      'The search data for all personal documents will be deleted. Original files remain untouched.';

  @override
  String knowledgeDocumentIndexSummary(int indexed, int total) {
    return '$indexed of $total documents searchable';
  }

  @override
  String get knowledgePersonalResults => 'Personal documents';

  @override
  String get knowledgePersonalResultHint =>
      'Results from the local document index';

  @override
  String get radioEmergencyTitle => 'Emergency radio frequencies';

  @override
  String get radioEmergencyEntryHint =>
      'CB and amateur radio: frequencies, rules and guidance';

  @override
  String get radioEmergencyIntro =>
      '112 remains the first route for emergencies. Radio frequencies are a possible fallback when approved equipment is available; they are not permanently monitored.';

  @override
  String get radioCbTitle => 'CB radio: calling and assistance channels';

  @override
  String get radioCbHintsTitle => 'CB radio guidance';

  @override
  String get radioCbRule =>
      'CB radio is generally allocated in Germany. Use approved equipment only and observe power, mode and antenna requirements.';

  @override
  String get radioAmateurTitle =>
      'Amateur radio: IARU emergency centres of activity';

  @override
  String get radioLegalTitle => 'Legal notice';

  @override
  String get radioAmateurLegal =>
      'Amateur radio may only be operated in Germany with a valid amateur radio licence. These frequencies are information and activity centres, not guaranteed emergency services.';

  @override
  String get radioNoGuaranteedMonitoring =>
      'Do not wait for a reply: always call 112 first when it is reachable.';

  @override
  String get radioListenFirst =>
      'Listen for an extended period before transmitting. Do not interfere with ongoing emergency traffic.';

  @override
  String get radioEmergencyCall =>
      'Call only in a genuine emergency. State location, hazard and required help first; keep it brief and clear.';

  @override
  String get radioUseHintsTitle => 'Usage guidance';

  @override
  String get radioBriefMessage =>
      'Use the lowest possible transmit power, confirm receipt, and agree fixed check-in times when energy is scarce.';

  @override
  String get radioOfficialRules => 'Open Federal Network Agency rules';

  @override
  String get radioIaruSource => 'Open DARC / IARU emergency frequencies';

  @override
  String get knowledgeApolloTitle => 'APOLLO knowledge base';

  @override
  String get knowledgeApolloMissionTitle =>
      'Knowledge for exceptional circumstances';

  @override
  String get knowledgeApolloMissionBody =>
      'Build a local library for practical action, core knowledge and learning at home. Archives stay on your device and can be read without an internet connection.';

  @override
  String get knowledgeApolloReady => 'Offline library opened and ready';

  @override
  String get knowledgeApolloNotReady => 'No archive opened yet';

  @override
  String knowledgeApolloStatus(int count, String size) {
    return '$count archives registered · known size: $size';
  }

  @override
  String get knowledgeApolloStatusHint =>
      'The bar is a guide for eight recommended core archives; you choose the size and selection.';

  @override
  String get knowledgeApolloDownloadedTitle => 'Downloaded content';

  @override
  String get knowledgeApolloDownloaded => 'Downloaded';

  @override
  String get knowledgeApolloOpened => 'Open';

  @override
  String get knowledgeApolloStartTitle => 'Practical knowledge first';

  @override
  String get knowledgeApolloStartBody =>
      'Start with topics that directly help during a disruption. Add schooling and fundamentals afterwards.';

  @override
  String get knowledgeApolloMedicalTitle => 'Medicine & first aid';

  @override
  String get knowledgeApolloMedicalBody =>
      'Use WikiMed to look up medical basics and first aid directly. It does not replace emergency or professional medical care.';

  @override
  String get knowledgeApolloSurvivalTitle =>
      'Survival, bushcraft & self-reliance';

  @override
  String get knowledgeApolloSurvivalBody =>
      'Wikibooks and iFixit cover water, shelter, fire, navigation, food, hygiene and repairs as understandable foundations.';

  @override
  String get knowledgeApolloRepairTitle => 'Craft, energy & repair';

  @override
  String get knowledgeApolloRepairBody =>
      'Tools, repairs, simple technology and practical craft: knowledge that keeps equipment and supplies usable longer.';

  @override
  String get knowledgeApolloFoundationsTitle => 'Fundamentals & education';

  @override
  String get knowledgeApolloBasicsTitle => 'Nature, society & core knowledge';

  @override
  String get knowledgeApolloBasicsBody =>
      'Mathematics, language, science, history and dependable background articles for reference.';

  @override
  String get knowledgeApolloSchoolTitle => 'Learning at home';

  @override
  String get knowledgeApolloSchoolBody =>
      'Child-friendly explanations, books, exercises and simulations for structured learning without a network.';

  @override
  String get knowledgeApolloAdvancedTitle => 'Advanced study & curriculum';

  @override
  String get knowledgeApolloAdvancedBody =>
      'More extensive courses for advanced topics. English-language resources are marked as a supplement.';

  @override
  String get knowledgeApolloPersonalTitle => 'Add your own material';

  @override
  String get knowledgeApolloPersonalBody =>
      'Add local PDF, EPUB and Markdown files and make readable text available to offline full-text search.';

  @override
  String get knowledgeApolloDownloadHint =>
      'Opens the Kiwix library with a matching search. Check language, edition and storage need before downloading.';

  @override
  String get settingsVersionInfoTitle => 'Version information';

  @override
  String get settingsVersionInfoApp => 'PreppSuite app';

  @override
  String settingsVersionInfoAppValue(String version, String build) {
    return '$version · build $build';
  }

  @override
  String get settingsVersionInfoDatabase => 'Household database';

  @override
  String get settingsVersionInfoKnowledgeIndex =>
      'Knowledge archive full-text index';

  @override
  String get settingsVersionInfoDocumentsIndex => 'Document full-text index';

  @override
  String settingsVersionInfoSchema(int version) {
    return 'Schema $version';
  }

  @override
  String get settingsVersionInfoOfflineMap => 'Offline map format';

  @override
  String get settingsVersionInfoPmtiles => 'PMTiles v3';

  @override
  String get settingsVersionInfoUnavailable => 'Unavailable';

  @override
  String get readinessOpenDashboard => 'Check readiness';

  @override
  String get readinessDashboardHint =>
      'Offline packages and freshness of warning data';

  @override
  String readinessSummary(int ready, int total) {
    return '$ready of $total areas ready';
  }

  @override
  String get readinessSummaryHint =>
      'Resolve missing items before an event and repeat the check after changes to the device.';

  @override
  String get readinessOfflinePackages => 'Offline packages';

  @override
  String get readinessPackageReady => 'Opened and readable';

  @override
  String get readinessPackageMissing => 'Not configured or unreadable';

  @override
  String readinessArchivesReady(int count) {
    return '$count archives registered; selected archive opened';
  }

  @override
  String get readinessWarningData => 'Official warning data';

  @override
  String get readinessWarningNeverUpdated =>
      'No complete refresh on this device yet';

  @override
  String readinessWarningUpdated(String age) {
    return 'Last complete refresh: $age';
  }

  @override
  String get readinessJustNow => 'just now';

  @override
  String readinessMinutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String readinessHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String readinessDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get emergencyPlanExport => 'Emergency plan as PDF';

  @override
  String get emergencyPlanPdfCards => 'Emergency cards';

  @override
  String get emergencyPlanPdfCardsWarning =>
      'This sheet names health details: blood group, allergies, medication and conditions. Anyone who picks it up can read them, and no lock protects a piece of paper. Keep it where you keep your documents, take it with you rather than leaving it behind, and shred it instead of binning it.';

  @override
  String get emergencyPlanCardsAskTitle => 'Print the emergency cards as well?';

  @override
  String emergencyPlanCardsAskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: 'one person',
    );
    return 'On paper the cards work when the phone is dead or gone — which is the reason to have them. It also means a loose sheet naming blood group, allergies, medication and conditions for $_temp0. Nothing on paper can be revoked, wiped remotely or password-protected.';
  }

  @override
  String get emergencyPlanCardsAskWithout => 'Plan only';

  @override
  String get emergencyPlanCardsAskWith => 'Include the cards';

  @override
  String get emergencyPlanPdfTitle => 'Personal emergency plan';

  @override
  String get emergencyPlanPdfMeetingPoints => 'Meeting points';

  @override
  String get emergencyPlanPdfContact => 'Contact outside the area';

  @override
  String get emergencyPlanPdfEquipment => 'Emergency kit and shut-off points';

  @override
  String get emergencyPlanPdfEmpty => 'Not entered';
}
