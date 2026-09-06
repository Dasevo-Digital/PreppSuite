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
  String get downloadRetryAction => 'Try again';

  @override
  String get downloadDismissAction => 'Dismiss';

  @override
  String downloadOfSize(String done, String total) {
    return '$done of $total';
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
      'For adults the BBK states 1.5 litres of fluid a day plus 0.5 litres for cooking, and around 2200 kcal. For children and pets it states no figures at all, only the reminder to think of them. What the app uses instead is its own conservative estimate: children get the same amount of water as adults, because running short of water is the worse mistake, and 1400 kcal. For dogs and cats only water is counted, at the veterinary rule of thumb of about 60 ml per kilogram — 1.2 litres for a 20 kg dog, 0.25 litres for a 4 kg cat. For exact planning, use the BMEL\'s Vorratskalkulator.';

  @override
  String get householdChildrenLabel => 'Children';

  @override
  String get householdDogsLabel => 'Dogs';

  @override
  String get householdCatsLabel => 'Cats';

  @override
  String get householdAdultsLabel => 'Adults';
}
