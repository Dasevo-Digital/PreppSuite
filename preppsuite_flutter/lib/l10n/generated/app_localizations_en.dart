// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get airQualityEntryHint =>
      'Particulates, ozone and nitrogen dioxide at a station near you.';

  @override
  String get airQualityTitle => 'Air quality';

  @override
  String get airQualityNoneChosen => 'No station chosen yet';

  @override
  String get airQualityChoose => 'Choose a station';

  @override
  String get airQualityChange => 'Another station';

  @override
  String get airQualityRefresh => 'Reload';

  @override
  String get airQualitySearchHint => 'Place, station or state';

  @override
  String get airQualitySearchEmpty => 'No station found.';

  @override
  String get airQualityLoadFailed =>
      'The readings cannot be reached right now.';

  @override
  String get airQualityOffline => 'Last stored reading — fetching just failed.';

  @override
  String get airQualityStale =>
      'This reading is over three hours old. The station is not reporting at the moment.';

  @override
  String get airQualityIncomplete =>
      'Not every pollutant this station measures reported this hour. The class covers what did.';

  @override
  String get airQualityComponents => 'Individual pollutants';

  @override
  String airQualityLeading(String code, String value, String unit) {
    return 'Decisive: $code at $value $unit';
  }

  @override
  String airQualitySpan(String min, String max) {
    return '$min to $max';
  }

  @override
  String airQualityMeasuredAt(String when) {
    return 'Measured on $when';
  }

  @override
  String get airQualityVeryGood => 'Very good';

  @override
  String get airQualityGood => 'Good';

  @override
  String get airQualityModerate => 'Moderate';

  @override
  String get airQualityPoor => 'Poor';

  @override
  String get airQualityVeryPoor => 'Very poor';

  @override
  String get airQualityUnknown => 'No class';

  @override
  String get airQualityNoWarning =>
      'This is a measurement, not a warning. If something is actually being warned about, the warning arrives through this app\'s warning list.';

  @override
  String get airQualityAdvice =>
      'What the UBA recommends at each class is published by the UBA itself. This app gives no health advice of its own.';

  @override
  String get airQualitySource =>
      'Source: Umweltbundesamt air quality index. The classification and thresholds are the UBA\'s.';

  @override
  String get roadClosureTitle => 'Motorway closures';

  @override
  String get roadClosureEntryHint => 'What is shut on the motorways you watch.';

  @override
  String get roadClosureNoneChosen => 'No motorway chosen yet';

  @override
  String get roadClosureWhy =>
      'When a region has to be left, “which way is open” is a more concrete question than any checklist. The service answers per road — so the roads that matter are named once.';

  @override
  String get roadClosureChoose => 'Choose motorways';

  @override
  String get roadClosureChange => 'Change the selection';

  @override
  String get roadClosureDone => 'Done';

  @override
  String get roadClosureRefresh => 'Reload';

  @override
  String get roadClosureLoadFailed =>
      'The traffic reports cannot be reached right now.';

  @override
  String get roadClosureNow => 'Now';

  @override
  String get roadClosureNothingNow =>
      'No closure and no warning at the moment.';

  @override
  String get roadClosureLater => 'Announced';

  @override
  String get roadClosureBlocked => 'Blocked';

  @override
  String roadClosureFrom(String when) {
    return 'From $when';
  }

  @override
  String get roadClosureSource =>
      'Source: Autobahn GmbH des Bundes open traffic data. Roadworks that block nothing are not listed.';

  @override
  String get appTitle => 'PreppSuite';

  @override
  String get householdNameLabel => 'Household name';

  @override
  String get countryLabel => 'Country';

  @override
  String get regionKeyLabel => 'Regional key (optional)';

  @override
  String get regionKeyHelper => 'Germany only, for more precise warnings';

  @override
  String get createButton => 'Create';

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
  String get warningDayToday => 'Today is the nationwide warning day';

  @override
  String warningDayIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: 'one day',
    );
    return 'Nationwide warning day in $_temp0';
  }

  @override
  String get warningDayBody =>
      'Test warning at 11:00, all-clear at 11:45. Sirens, Cell Broadcast, radio and the warning apps are tested together. It is the one day a year on which you can find out whether what is meant to reach you actually does – a warning that never arrives goes unnoticed otherwise.';

  @override
  String get warningDayNotificationTitle =>
      'Today is the nationwide warning day';

  @override
  String get warningDayNotificationBody =>
      'The test warning goes out at 11:00 and the all-clear at 11:45. A good moment to check that sirens, Cell Broadcast and the warning apps reach you.';

  @override
  String get pegelTitle => 'Water levels';

  @override
  String get pegelEntryHint =>
      'The level on your own river, with the gauge\'s reference values';

  @override
  String get pegelNoneChosen => 'No gauge chosen yet.';

  @override
  String get pegelUpstreamHint =>
      'Choose the gauge upstream of you. The nearest one is no help if it lies downstream – it shows what has already passed, not what is coming.';

  @override
  String get pegelChoose => 'Choose a gauge';

  @override
  String get pegelChange => 'Choose another gauge';

  @override
  String get pegelSearchHint => 'Search for a gauge or waterway';

  @override
  String get pegelSearchEmpty => 'No gauge found.';

  @override
  String get pegelLoadFailed =>
      'The gauge list could not be loaded. It needs a connection once.';

  @override
  String get pegelOffline => 'No connection – this is the last value fetched.';

  @override
  String get pegelStale =>
      'More than an hour old. Inland gauges report every 15 minutes, so what is missing is the connection and not the water.';

  @override
  String pegelMeasuredAt(String time) {
    return 'Measured $time';
  }

  @override
  String get pegelRefresh => 'Refresh';

  @override
  String pegelKilometre(String km) {
    return 'River kilometre $km';
  }

  @override
  String get pegelReferences => 'This gauge\'s reference values';

  @override
  String get pegelNoReferences =>
      'No reference values are published for this gauge, so the number stands without a scale.';

  @override
  String get pegelNoMeldestufe =>
      'No warning level: those are set by the states and are not in this data. Official flood warnings are in the warning list.';

  @override
  String get pegelSource =>
      'Source: PEGELONLINE, run by Germany\'s waterways administration. Federal waterways only – the brook that floods a village is not in here.';

  @override
  String get pegelBandRecordLow => 'Lower than ever measured';

  @override
  String get pegelBandLow => 'Low water';

  @override
  String get pegelBandOrdinary => 'Within the ordinary range';

  @override
  String get pegelBandElevated => 'Above the mean';

  @override
  String get pegelBandFlood => 'Flood';

  @override
  String get pegelBandRecordHigh => 'Higher than ever measured';

  @override
  String get pegelBandUnknown => 'Cannot be placed';

  @override
  String pegelTrendRising(String change) {
    return 'Rising, $change cm in 24 hours';
  }

  @override
  String pegelTrendFalling(String change) {
    return 'Falling, $change cm in 24 hours';
  }

  @override
  String get pegelTrendSteady => 'Barely changed in 24 hours';

  @override
  String get pegelTrendUnknown => 'History not available';

  @override
  String get pegelRefMean => 'Mean level';

  @override
  String get pegelRefMeanFlood => 'Mean flood level';

  @override
  String get pegelRefHighest => 'Highest level measured';

  @override
  String get pegelRefMeanLow => 'Mean low level';

  @override
  String get pegelRefLowest => 'Lowest level measured';

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
  String get languageLabel => 'Language';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageGermanOption => 'Deutsch';

  @override
  String get languageEnglishOption => 'English';

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
  String get householdPlanContactPoint => 'The municipality\'s contact point';

  @override
  String get householdPlanContactPointHint =>
      'The building on emergency power that opens when the power has been out for a long time – it gives information, and an emergency call can be handed over there when no phone works. Its name changes with the state; the municipality knows where the nearest one is. Not a meeting point – this is where you go for help, not to find each other.';

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
  String get emergencyCardRemoved => 'Card removed.';

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
  String get downloadResumingLabel => 'Connection dropped — resuming…';

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
  String mapDownloadDeepestPossible(String count, String level) {
    return 'At level 14 that would be $count tiles — too many. Level $level is the deepest this area goes.';
  }

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
  String get budgetEntryDeleted => 'Expense deleted';

  @override
  String emergencyRadioChannels(int count) {
    return '$count channels';
  }

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
  String get knowledgeLibraryTitle => 'Your archives';

  @override
  String get knowledgeLibraryEmpty => 'No archives left in the library.';

  @override
  String get knowledgeManageArchives => 'Manage archives';

  @override
  String knowledgeArchiveCount(int count) {
    return '$count archives on this device';
  }

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
  String get backupPassphraseWarning =>
      'Without this passphrase the file cannot be opened again – not by you either. There is no way back and no back door. Write it down where the passports are kept, and not on the device this backup is meant to replace.';

  @override
  String backupPassphraseInvalid(int count) {
    return 'Enter at least $count characters; both entries have to match.';
  }

  @override
  String get warningInstructionsTitle => 'Recommended actions';

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
  String get emergencySirenTitle => 'Siren signals';

  @override
  String get emergencySirenHint =>
      'Recommended nationwide but not regulated the same everywhere – when in doubt, what your own municipality announced is what counts. Every warning is followed by the same thing: get inside, close the windows, turn on the radio.';

  @override
  String get emergencySirenWarning => 'Rising and falling wail, one minute';

  @override
  String get emergencySirenWarningMeaning =>
      'Warning. Danger nearby. Get into a building, close windows and doors, turn on the radio and wait for announcements.';

  @override
  String get emergencySirenAllClear => 'Steady continuous tone, one minute';

  @override
  String get emergencySirenAllClearMeaning =>
      'All clear. The danger has passed. It arrives by the same route the warning did.';

  @override
  String get emergencySirenFire => 'Tone interrupted twice, one minute';

  @override
  String get emergencySirenFireMeaning =>
      'Fire brigade alert. It calls the responders and is not addressed to the public – no reason to do anything.';

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
      'PMR446, Freenet, CB and amateur radio: frequencies, rules and guidance';

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

  @override
  String get settingsRegionUnknownKey => 'Unknown key — please check';

  @override
  String get settingsRegionKeyInvalid =>
      'Enter five or twelve digits (for example 03101).';

  @override
  String get shelterOverpassBusyMessage =>
      'OpenStreetMap/Overpass is busy right now (request limit). Try again in a few seconds.';

  @override
  String shelterSourceFailureReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get kiwixLanguageSearchHint => 'Search language';

  @override
  String kiwixLanguageCount(int count) {
    return '$count languages';
  }

  @override
  String get kiwixLanguageNoMatch => 'No language found.';

  @override
  String kiwixLanguageArchives(int count) {
    return '$count archives';
  }

  @override
  String downloadRemainingHours(int hours, int minutes) {
    return '$hours h $minutes min left';
  }

  @override
  String downloadRemainingMinutes(int minutes) {
    return '$minutes min left';
  }

  @override
  String downloadRemainingSeconds(int seconds) {
    return '$seconds s left';
  }

  @override
  String get articleLoadFailed => 'The page could not be loaded.';

  @override
  String articleHttpStatus(String status) {
    return 'The archive answered with $status.';
  }

  @override
  String get articleReload => 'Reload';

  @override
  String get knowledgeArchiveNoCover => 'No cover in this archive';

  @override
  String get radiationTitle => 'Gamma radiation';

  @override
  String get radiationEntryHint =>
      'Ambient dose rate at a BfS monitoring station';

  @override
  String get radiationNoneChosen => 'No station chosen yet';

  @override
  String get radiationChoose => 'Choose a station';

  @override
  String get radiationChange => 'Another station';

  @override
  String get radiationRefresh => 'Refresh';

  @override
  String get radiationSearchHint => 'Place or postal code';

  @override
  String get radiationSearchEmpty => 'No station found.';

  @override
  String get radiationLoadFailed => 'The readings could not be loaded.';

  @override
  String get radiationOffline =>
      'Last known value. The BfS service could not be reached.';

  @override
  String get radiationStale =>
      'More than two hours old. The network reports hourly, so this is a missing connection and not a standing value.';

  @override
  String get radiationUnvalidated =>
      'Unchecked raw value. BfS publishes hourly readings unchecked at first; a technical fault looks like a measurement.';

  @override
  String radiationMeasuredAt(String time) {
    return 'Measured until $time';
  }

  @override
  String radiationHeight(String metres) {
    return '$metres m above sea level';
  }

  @override
  String radiationPostalCode(String code) {
    return 'Postal code $code';
  }

  @override
  String radiationBaseline(String value) {
    return 'Usual at this station: $value µSv/h';
  }

  @override
  String radiationNoBaseline(String floor, String ceiling) {
    return 'This station has no baseline of its own yet, so the reading is judged against the national natural range of $floor to $ceiling µSv/h, which is coarser — in the Black Forest 0.16 µSv/h is perfectly ordinary.';
  }

  @override
  String radiationSplit(String terrestrial, String cosmic) {
    return 'Of which $terrestrial µSv/h from the ground and $cosmic µSv/h from space';
  }

  @override
  String get radiationBandOrdinary => 'Ordinary for this station';

  @override
  String get radiationBandWeather =>
      'Raised — which is the normal case after rain';

  @override
  String get radiationBandUnusual => 'Beyond what weather explains';

  @override
  String get radiationBandUnknown =>
      'Above the natural range, with no baseline of its own';

  @override
  String get radiationWeatherExplained =>
      'Rain washes radon decay products out of the air and lifts the reading by up to a factor of three for a few hours. This is harmless and falls back on its own; the half-life is about 30 minutes. Fresh snow does the same, while lying snow shields the ground and lowers the reading.';

  @override
  String get radiationUnusualExplained =>
      'Per BfS, a radiological event only comes into question when a clearly raised reading persists for a day or longer or goes beyond that factor of three — or when the probe is faulty. A single value is not a warning: an official warning would arrive through this app’s warnings.';

  @override
  String get radiationNoWarning =>
      'This is the reading and its context, not a warning. Official warnings arrive through this app’s warnings.';

  @override
  String get radiationSource =>
      'Source: Bundesamt für Strahlenschutz (BfS), ODL network. Datenlizenz Deutschland – Namensnennung 2.0.';

  @override
  String get fireDangerTitle => 'Forest fire danger';

  @override
  String get fireDangerEntryHint =>
      'The DWD forest fire danger index for one station';

  @override
  String get fireDangerNoneChosen => 'No station chosen yet';

  @override
  String get fireDangerChoose => 'Choose a station';

  @override
  String get fireDangerChange => 'Another station';

  @override
  String get fireDangerRefresh => 'Refresh';

  @override
  String get fireDangerSearchHint => 'Place or state';

  @override
  String get fireDangerSearchEmpty => 'No station found.';

  @override
  String get fireDangerLoadFailed =>
      'The forest fire danger index could not be loaded.';

  @override
  String get fireDangerOffline =>
      'Last known state. The DWD server could not be reached.';

  @override
  String fireDangerStale(String date) {
    return 'This is from $date and not from today. The DWD issues the index only during the fire season, roughly March to October — outside it nothing new arrives.';
  }

  @override
  String fireDangerStep(int step) {
    return 'Level $step of 5';
  }

  @override
  String fireDangerIssuedFor(String date) {
    return 'Issued for $date';
  }

  @override
  String get fireDangerLevel1 => 'Very low danger';

  @override
  String get fireDangerLevel2 => 'Low danger';

  @override
  String get fireDangerLevel3 => 'Moderate danger';

  @override
  String get fireDangerLevel4 => 'High danger';

  @override
  String get fireDangerLevel5 => 'Very high danger';

  @override
  String get fireDangerAhead => 'The days ahead';

  @override
  String fireDangerPeak(int step, int days) {
    return 'Rises to level $step in $days days';
  }

  @override
  String fireDangerPeakTomorrow(int step) {
    return 'Rises to level $step tomorrow';
  }

  @override
  String get fireDangerToday => 'Today';

  @override
  String fireDangerInDays(int days) {
    return 'In $days days';
  }

  @override
  String get fireDangerTomorrow => 'Tomorrow';

  @override
  String get fireDangerNoWarning =>
      'The index describes the meteorological potential for forest fire. It is not a warning and not a ban on entering a forest; bans are issued by the states, and official warnings arrive through this app’s warnings.';

  @override
  String get fireDangerSource =>
      'Source: Deutscher Wetterdienst (DWD), forest fire danger index WBI.';

  @override
  String fireDangerState(String state) {
    return 'State $state';
  }

  @override
  String get nearbyTitle => 'Nearby';

  @override
  String get nearbyEntryHint =>
      'Pharmacy, water, fuel — from the downloaded map, without a network.';

  @override
  String nearbySearchFrom(String place) {
    return 'Searching around $place';
  }

  @override
  String get nearbyMapCentre => 'the map centre';

  @override
  String get nearbyMyPosition => 'your position';

  @override
  String get nearbyUseMyLocation => 'Use my location';

  @override
  String get nearbyNoCentre => 'No point chosen yet';

  @override
  String get nearbyNoCentreWhy =>
      'This search needs somewhere to start from. Take your position — or open the map, move it to the area and search from there.';

  @override
  String get nearbyOpenMap => 'Open the map';

  @override
  String get nearbyRadius => 'Radius';

  @override
  String nearbyRadiusKm(int km) {
    return '$km km';
  }

  @override
  String nearbySearching(int done, int total) {
    return '$done of $total tiles read';
  }

  @override
  String get nearbyNothingFound => 'Nothing found.';

  @override
  String get nearbyNothingFoundWhy =>
      'The map carries none of these points within this radius. A wider radius may help — or the area was only downloaded coarsely.';

  @override
  String get nearbyNoArchive => 'No map downloaded';

  @override
  String get nearbyNoArchiveWhy =>
      'This search reads the map that is on this device. Without a downloaded map there is nothing to search.';

  @override
  String get nearbyDownloadMap => 'Download a map';

  @override
  String get nearbyTooShallow => 'The map does not go deep enough';

  @override
  String get nearbyTooShallowWhy =>
      'Individual points first appear at zoom level 14. This archive stops short of it: it draws a perfectly good map and holds not one pharmacy. Download the area again at a greater level of detail.';

  @override
  String get nearbyOutsideArchive => 'Outside the downloaded area';

  @override
  String get nearbyOutsideArchiveWhy =>
      'This point is not inside what was downloaded. The map knows nothing here — including that anything is missing.';

  @override
  String get nearbyCaveats =>
      'Only what was downloaded and what volunteers entered into OpenStreetMap can be found. A point being on the map is no promise that it is open, stocked or staffed.';

  @override
  String get nearbyShelterNote =>
      'In OpenStreetMap a “shelter” is nearly always a bus shelter or a hiking hut, not a protective shelter. That is why the kind is not listed here.';

  @override
  String get nearbyKindWater => 'Water';

  @override
  String get nearbyKindHealth => 'Health';

  @override
  String get nearbyKindFood => 'Food';

  @override
  String get nearbyKindFuel => 'Fuel and power';

  @override
  String get nearbyKindHardware => 'Tools and materials';

  @override
  String get nearbyKindHelp => 'Help and authorities';

  @override
  String get poiDrinkingWater => 'Drinking water';

  @override
  String get poiPharmacy => 'Pharmacy';

  @override
  String get poiHospital => 'Hospital';

  @override
  String get poiClinic => 'Clinic';

  @override
  String get poiDoctors => 'Doctor\'s surgery';

  @override
  String get poiSupermarket => 'Supermarket';

  @override
  String get poiConvenience => 'Convenience store';

  @override
  String get poiBakery => 'Bakery';

  @override
  String get poiButcher => 'Butcher';

  @override
  String get poiGreengrocer => 'Greengrocer';

  @override
  String get poiMarketplace => 'Marketplace';

  @override
  String get poiDeli => 'Delicatessen';

  @override
  String get poiFuel => 'Filling station';

  @override
  String get poiChargingStation => 'Charging point';

  @override
  String get poiDoityourself => 'DIY store';

  @override
  String get poiHardware => 'Hardware shop';

  @override
  String get poiFireStation => 'Fire station';

  @override
  String get poiPolice => 'Police';

  @override
  String get poiTownhall => 'Town hall';

  @override
  String get poiCommunityCentre => 'Community centre';

  @override
  String get daylightTitle => 'Daylight and moon';

  @override
  String get daylightEntryHint =>
      'Sun, twilight and moon — worked out on the device, without a network.';

  @override
  String get daylightNoPlace => 'No place set yet';

  @override
  String get daylightNoPlaceWhy =>
      'Where the sun and moon stand depends on where you are. Set the place once — it is remembered and never needed again.';

  @override
  String get daylightSetPlace => 'Set the place';

  @override
  String get daylightChangePlace => 'Change the place';

  @override
  String get daylightCoordinates => 'Coordinates';

  @override
  String get daylightCoordinatesHint => '52.2689, 10.5268';

  @override
  String get daylightCoordinatesBad =>
      'Two numbers, latitude and longitude — for example 52.2689, 10.5268.';

  @override
  String get daylightPlaceName => 'Name (optional)';

  @override
  String get daylightToday => 'Today';

  @override
  String get daylightTomorrow => 'Tomorrow';

  @override
  String get daylightSunrise => 'Sunrise';

  @override
  String get daylightSunset => 'Sunset';

  @override
  String get daylightSolarNoon => 'Solar noon';

  @override
  String get daylightCivilDawn => 'First light';

  @override
  String get daylightCivilDusk => 'Last light';

  @override
  String get daylightNauticalDawn => 'Twilight begins';

  @override
  String get daylightNauticalDusk => 'Twilight ends';

  @override
  String daylightDayLength(String duration) {
    return 'Day length $duration';
  }

  @override
  String daylightEveningTwilight(String duration) {
    return 'Then $duration of usable light';
  }

  @override
  String get daylightAlwaysUp => 'The sun does not set today.';

  @override
  String get daylightAlwaysDown => 'The sun does not rise today.';

  @override
  String get daylightMoon => 'Moon';

  @override
  String get daylightMoonrise => 'Moonrise';

  @override
  String get daylightMoonset => 'Moonset';

  @override
  String daylightMoonIllumination(int percent) {
    return '$percent % lit';
  }

  @override
  String get daylightMoonUpAllDay =>
      'The moon stays above the horizon all day.';

  @override
  String get daylightMoonDownAllDay =>
      'The moon does not come above the horizon today.';

  @override
  String get daylightMoonNoRise =>
      'No moonrise today — the moon rises about 50 minutes later each day.';

  @override
  String get daylightMoonNoSet => 'No moonset today.';

  @override
  String get daylightWhy =>
      'Without a light switch the sun is the working day, and whether the moon is up decides whether moving at night is possible. Both are questions with exact answers, and neither can be looked up without a network unless the answer is already in the device.';

  @override
  String get daylightAccuracy =>
      'Everything here is computed on the device, nothing is fetched. Checked against the US Naval Observatory\'s tables: over 112 compared times, sun and moon are at most one minute out. The times assume a clear horizon — hills, trees and buildings shift them.';

  @override
  String get moonPhaseNew => 'New moon';

  @override
  String get moonPhaseWaxingCrescent => 'Waxing crescent';

  @override
  String get moonPhaseFirstQuarter => 'First quarter';

  @override
  String get moonPhaseWaxingGibbous => 'Waxing gibbous';

  @override
  String get moonPhaseFull => 'Full moon';

  @override
  String get moonPhaseWaningGibbous => 'Waning gibbous';

  @override
  String get moonPhaseLastQuarter => 'Last quarter';

  @override
  String get moonPhaseWaningCrescent => 'Waning crescent';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get radioEverydayTitle => 'Licence-free radio: PMR446 and Freenet';

  @override
  String get radioEverydayIntro =>
      'The two bands many households actually own. They need no registration and no examination — and no infrastructure: device to device, one to a few kilometres. That is exactly why they belong here beside CB and amateur radio.';

  @override
  String get radioPmrTitle => 'PMR446';

  @override
  String get radioPmrRange => '446.0–446.2 MHz';

  @override
  String get radioPmrChannels => '16 analogue channels, 12.5 kHz spacing';

  @override
  String get radioPmrPower => 'At most 0.5 W ERP';

  @override
  String get radioPmrAntenna => 'Built-in antennas only';

  @override
  String get radioPmrPeerToPeer =>
      'Device to device only. No fixed station, no repeater, no linking into a network.';

  @override
  String get radioPmrSource =>
      'Bundesnetzagentur, Vfg. 91/2025 (collective allocation for short-range devices), band 83. Replaces Vfg. 46/2020, valid until 31 December 2035. The channel plan itself is in the harmonised standard, not in the allocation.';

  @override
  String get radioFreenetTitle => 'Freenet Deutschland';

  @override
  String get radioFreenetRange => '149.01875–149.11875 MHz';

  @override
  String get radioFreenetAnalogue =>
      '6 channels at 12.5 kHz, analogue or digital';

  @override
  String get radioFreenetDigital =>
      'Plus 12 channels at 6.25 kHz, digital only';

  @override
  String get radioFreenetPower =>
      'At most 1 W ERP. Within 10 km of the Belgian and Polish borders, only 0.5 W.';

  @override
  String get radioFreenetHandheld =>
      'Handheld radios with their own power supply, operable in one hand. Fixed stations are not permitted.';

  @override
  String get radioFreenetAntenna =>
      'Only the built-in antenna or an exchangeable one on the radio itself. An antenna on a coaxial cable or a mast is not allowed.';

  @override
  String get radioFreenetPeerToPeer =>
      'Device to device only. No repeater, no relay, no gateway to the internet.';

  @override
  String get radioFreenetDuration =>
      'No continuous transmission. The standard cuts off after 180 seconds; below that too, transmit only as long as needed.';

  @override
  String get radioFreenetGermanyOnly =>
      'This allocation applies in Germany only.';

  @override
  String get radioFreenetExtras => 'VOX and CTCSS are expressly permitted.';

  @override
  String get radioFreenetSource =>
      'Bundesnetzagentur, Vfg. 45/2025, corrected by Mitt. 193/2025. In force since 1 October 2025, valid until 30 September 2035; replaces Vfg. 60/2019.';

  @override
  String get radioCallingChannelTitle => 'There is no official calling channel';

  @override
  String get radioCallingChannelNone =>
      'Neither PMR446 nor Freenet has an emergency or calling channel laid down by the regulator. What exists are conventions among operators — and they are not uniform.';

  @override
  String get radioCallingChannelThree =>
      'The most widespread is the private “Channel 3” initiative: PMR446 446.03125 MHz, Freenet 149.0500 MHz, CB 26.985 MHz. One number for all three bands. Elsewhere channel 1 is used instead.';

  @override
  String get radioCallingChannelNoListener =>
      'Do not count on anybody listening. Nobody is obliged to monitor any of these channels.';

  @override
  String get energyTitle => 'Energy and fuel';

  @override
  String get energyEntryHint => 'How long power, gas, fuel and light last.';

  @override
  String get energyIntro =>
      'The app works out how long the food and water last. This is the same sum for what you cook, heat and light with.';

  @override
  String get energyNothingYet => 'Nothing entered yet';

  @override
  String get energyNothingYetWhy =>
      'Enter what you have — and what uses it. Both figures are printed on the thing itself: “160 g/h” on the stove, “230 g” on the cartridge. Nothing here is estimated for you.';

  @override
  String get energyReserves => 'Stored';

  @override
  String get energyDraws => 'Used by';

  @override
  String get energyAddReserve => 'Add a reserve';

  @override
  String get energyAddDraw => 'Add a consumer';

  @override
  String get energyEditReserve => 'Change the reserve';

  @override
  String get energyEditDraw => 'Change the consumer';

  @override
  String get energyDelete => 'Delete';

  @override
  String get energyLabel => 'Name';

  @override
  String get energyKind => 'Kind';

  @override
  String get energyAmount => 'Amount';

  @override
  String get energyPerHour => 'Uses per hour';

  @override
  String get energyHoursPerDay => 'Hours a day';

  @override
  String get energyNumberNeeded => 'A number greater than zero.';

  @override
  String get energyLabelNeeded =>
      'A name, so the row still says something later.';

  @override
  String energyDays(int days) {
    return '$days days';
  }

  @override
  String get energyOneDay => '1 day';

  @override
  String get energyZeroDays => 'Does not last a day';

  @override
  String energyPerDayIs(String amount, String unit, String stored) {
    return '$amount $unit a day out of $stored $unit';
  }

  @override
  String get energyUnused =>
      'Stored, but nothing uses it. Enter the consumer, or there is nothing to divide.';

  @override
  String get energyEmpty => 'Something uses it and there is none.';

  @override
  String energyShortest(String kind, String days) {
    return 'First to run out: $kind – $days';
  }

  @override
  String get energyShortestWhy =>
      'That is the household\'s range. Four reserves each with a reassuring number are not four answers — the smallest one counts.';

  @override
  String get energyNoAnswer =>
      'No range yet: every reserve needs a consumer, or there is nothing to divide.';

  @override
  String get energySources =>
      'Every figure here is your own. This app estimates no consumption — what a stove uses is written on the stove, and what a device draws is written on its power supply. All it does is the arithmetic.';

  @override
  String get energyKindElectricity => 'Electricity';

  @override
  String get energyKindGas => 'Gas';

  @override
  String get energyKindLiquidFuel => 'Liquid fuel';

  @override
  String get energyKindSolidFuel => 'Solid fuel';

  @override
  String get energyKindCandles => 'Candlelight';

  @override
  String get energyKindElectricityHint =>
      'Power banks, batteries, a solar day\'s work — in watt-hours.';

  @override
  String get energyKindGasHint =>
      'Cartridges and cylinders — in grams, the way a stove states its consumption.';

  @override
  String get energyKindLiquidFuelHint =>
      'Petrol, diesel, paraffin, lamp oil, spirit — in litres.';

  @override
  String get energyKindSolidFuelHint =>
      'Firewood, briquettes, coal, pellets — in kilograms.';

  @override
  String get energyKindCandlesHint =>
      'In burning hours: pieces times the burn time per piece from the packet.';

  @override
  String get energyUnitWattHours => 'Wh';

  @override
  String get energyUnitGrams => 'g';

  @override
  String get energyUnitLiters => 'l';

  @override
  String get energyUnitKilograms => 'kg';

  @override
  String get energyUnitHours => 'h';

  @override
  String get energyHelperTitle => 'Converting';

  @override
  String get energyHelperGasBottle =>
      'Cylinder in kilograms? Times 1000 gives grams — 5 kg is 5000 g.';

  @override
  String get energyHelperCandles =>
      'Candles? Pieces times the burn time each. 40 tea lights at 4 hours is 160 hours.';

  @override
  String get energyHelperPowerbank =>
      'Power bank in mAh? Times 3.7 V, divided by 1000, gives watt-hours: 20000 mAh is 74 Wh. Careful — that is the cell, not the socket. Stepping up to 5 V loses something; how much depends on the device, which is why no percentage is given here.';

  @override
  String get portableTitle => 'Data folder';

  @override
  String get portableInstalled => 'On this machine';

  @override
  String get portableInstalledHint =>
      'Household, stock, photos and settings sit where this operating system keeps them for programs.';

  @override
  String get portableCarried => 'On a disk you carry';

  @override
  String portableSourceBeside(String folder) {
    return 'Found as a folder named “$folder” beside the program.';
  }

  @override
  String get portableSourceChosen => 'Chosen once and remembered.';

  @override
  String portableSourceEnvironment(String variable) {
    return 'Named by the environment variable $variable.';
  }

  @override
  String portableExplain(String folder) {
    return 'Create a folder called “$folder” beside the program and the next launch uses it. Nothing is created on its own: an installed copy behaves exactly as it always has.';
  }

  @override
  String get portableExplainMac =>
      'On macOS the app runs sandboxed — deliberately, because that is what stops the system asking for folder access again after every update. A sandboxed app may not read a folder beside the program. So here the folder is chosen once per Mac instead of being found.';

  @override
  String get portableChoose => 'Choose a folder';

  @override
  String get portableForget => 'Back to this machine';

  @override
  String get portableRestartNeeded => 'Takes effect at the next start.';

  @override
  String get portableTakeover =>
      'The first time a new folder is used, the app takes over once what is on this machine — copied, not moved. The installation here is left untouched.';

  @override
  String get portableRelativeNote =>
      'Maps, archives and documents that sit on the same disk are remembered relative to it. They are found again even when the disk comes up under a different letter on the next machine.';

  @override
  String get portableFolderUnusable => 'This folder cannot be written to.';

  @override
  String get portableUnsupported =>
      'A carried data folder is possible on computers only, not on phones: there the system decides where an app\'s data lives.';

  @override
  String get articleReaderSimple => 'Simple view';

  @override
  String get articleReaderWhy =>
      'This page is shown without the system\'s browser component: text, headings, lists, links and pictures. Scripts, typeset formulas and finer styling are missing.';

  @override
  String get articleReaderLoading => 'Loading …';

  @override
  String get articleReaderFailed => 'The article could not be read.';

  @override
  String get articleReaderEmpty => 'This page holds no readable text.';

  @override
  String get articleReaderImageMissing => 'Picture unavailable';

  @override
  String get articleReaderExternal =>
      'Leads out of the archive and was not opened.';

  @override
  String get articleReaderOpenInBrowser => 'Open in a browser';

  @override
  String get articleViewerChoiceTitle => 'Showing an article';

  @override
  String get articleViewerChoiceWhy =>
      'On Linux and Windows this app has no embedded browser component available. An article therefore opens either in a window of the system\'s own — or the app draws it itself.';

  @override
  String get articleViewerChoiceWindow => 'A window of its own';

  @override
  String get articleViewerChoiceWindowWhy =>
      'Shows the article in full: scripts, typeset formulas, the page\'s own layout. Needs the system\'s browser component — WebKitGTK on Linux, the WebView2 runtime on Windows.';

  @override
  String get articleViewerChoiceBuiltIn => 'Inside the app';

  @override
  String get articleViewerChoiceBuiltInWhy =>
      'Needs nothing from the system and stays in the same window. The app\'s text size and colours apply to the article too. No scripts, no typeset formulas, no floated infoboxes.';

  @override
  String get articleViewerChoiceFallbackNote =>
      'If the system\'s component is missing, the app draws the article itself in any case — this choice only changes what is tried first.';
}
