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
  String get errorGeneric => 'An unexpected error occurred. Please try again.';

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
  String get errorDiskFull =>
      'The disk is full. Free up some space and try again.';

  @override
  String get errorLocalDataLocked =>
      'The local data is locked. Restart the app and read the notice on the first screen.';

  @override
  String get errorLocalDataBusy =>
      'The databases are being encrypted. Please wait until that has finished.';

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
  String caloriesTotalHint(Object total) {
    return 'Comes to $total kcal in stock.';
  }

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
  String get cameraDeniedTitle => 'Camera not allowed';

  @override
  String get cameraDeniedBody =>
      'PreppSuite is not allowed to use the camera. Allow it in the system settings, then open this screen again.';

  @override
  String get cameraUnsupportedTitle => 'No camera';

  @override
  String get cameraUnsupportedBody => 'This device cannot scan with a camera.';

  @override
  String get cameraFailedTitle => 'The camera did not come';

  @override
  String get cameraFailedBody => 'The viewfinder would not start.';

  @override
  String get cameraAlternativeBarcode =>
      'Without a camera, by hand: go back and type the name, quantity and unit yourself.';

  @override
  String get cameraAlternativeTransfer =>
      'Without a camera, a household travels through the shared folder or through a file.';

  @override
  String get hazardReleaseTitle => 'Hazardous material in the air';

  @override
  String get hazardReleaseEntryHint =>
      'What to do when something has been released — indoors, outdoors, in the car.';

  @override
  String get hazardReleaseIntro =>
      'When a warning says hazardous material has been released, the first minutes decide. What follows is the instruction of the German Federal Office of Civil Protection and Disaster Assistance (BBK), reproduced and not interpreted.';

  @override
  String get hazardReleaseHomeTitle => 'If you are at home';

  @override
  String get hazardReleaseHomeStay =>
      'Stay in the building. Take in passers-by who are at risk, and tell the other residents.';

  @override
  String get hazardReleaseHomeWindows => 'Close windows and doors.';

  @override
  String get hazardReleaseHomeVent =>
      'Switch off fans and air conditioning, close the ventilation slots in the window frames.';

  @override
  String get hazardReleaseHomeRoom =>
      'Go to a sheltered inner room, ideally one with no outside window.';

  @override
  String get hazardReleaseHomeCandles =>
      'No candles or anything like them — they use up oxygen for nothing.';

  @override
  String get hazardReleaseHomeRadio =>
      'Switch on the radio, FM and the regional station, or the television. Follow the announcements from the authorities and emergency services.';

  @override
  String get hazardReleaseHomePhone =>
      'Use the telephone only in an emergency.';

  @override
  String get hazardReleaseHomeMask =>
      'If the material gets in: use whatever breathing protection you have, improvise a mask if you must.';

  @override
  String get hazardReleaseHomeWait =>
      'Wait for the all-clear before leaving the building or opening a window.';

  @override
  String get hazardReleaseOutsideTitle => 'If you are outdoors';

  @override
  String get hazardReleaseOutsideCross =>
      'Move across the wind, neither with it nor against it. Breathe through protection, through a handkerchief if that is all there is.';

  @override
  String get hazardReleaseOutsideBuilding =>
      'Get to the nearest closed building and ask to be let in.';

  @override
  String get hazardReleaseOutsideClothes =>
      'After contact, change outer clothing and shoes as you enter, bag them in plastic and leave them out of the living area, in front of the building if you can.';

  @override
  String get hazardReleaseOutsideWash =>
      'Wash in this order: hands thoroughly first, then face and hair, then nose and ears — with soap and water.';

  @override
  String get hazardReleaseOutsideBio =>
      'For biological material, disinfect your hands as well.';

  @override
  String get hazardReleaseCarTitle => 'If you are in the car';

  @override
  String get hazardReleaseCarVent =>
      'Switch off the ventilation and close the windows.';

  @override
  String get hazardReleaseCarRadio =>
      'Listen to the radio, FM and the regional station, and follow the instructions.';

  @override
  String get hazardReleaseCarBuilding =>
      'Get to the nearest closed building, unless the authorities say otherwise.';

  @override
  String get hazardReleaseCellarTitle =>
      'Cellar or upper floor? That depends on the material';

  @override
  String get hazardReleaseCellarChemical =>
      'With chemicals, avoid the cellar. Most gases and vapours are heavier than air and collect in hollows and cellars.';

  @override
  String get hazardReleaseCellarRadio =>
      'With radioactive material it is the other way round: go to a cellar room by preference. Ionising radiation is attenuated as it passes through matter, and in a cellar the attenuation by the surrounding earth and the floors above is particularly large.';

  @override
  String get hazardReleaseCellarNote =>
      'This is not a contradiction but the same thought twice: gas sinks, radiation is slowed by mass. Which case it is, the warning says.';

  @override
  String get hazardReleaseIodineLink =>
      'Radioactive iodine: what iodine tablets do';

  @override
  String get hazardReleaseSource =>
      'Source: Federal Office of Civil Protection and Disaster Assistance (BBK), \"Handeln bei Gefahrstoff-Freisetzung\".';

  @override
  String get iodineTitle => 'Iodine tablets';

  @override
  String get iodineEntryHint =>
      'Who takes them, when — and why only when told to.';

  @override
  String get iodineIntro =>
      'A nuclear accident can release radioactive iodine. It gathers in the thyroid and can cause cancer there later. A high-dose iodine tablet saturates the thyroid with non-radioactive iodine beforehand, so that it takes up no more. This is called thyroid blocking.';

  @override
  String get iodineOnlyOnOrderTitle => 'Only when explicitly told to';

  @override
  String get iodineOnlyOnOrderBody =>
      'High-dose iodine tablets should be taken only when the civil protection authorities explicitly call for it — and only at the dose they name. The BfS strongly advises against taking them on your own judgement, because the side effects can reach acute cardiovascular failure.';

  @override
  String get iodineOnlyThyroidTitle =>
      'They protect the thyroid and nothing else';

  @override
  String get iodineOnlyThyroidBody =>
      'And only against radioactive iodine. Against every other radioactive substance they do nothing. Having taken one is not protection and does not replace following the instructions.';

  @override
  String get iodineWhoTitle => 'Who';

  @override
  String get iodineWhoUnder45 =>
      'Everybody up to 45, in the affected areas. The dose depends on age and is named by the authorities.';

  @override
  String get iodineWhoChildren =>
      'Particularly important for children and adolescents up to 18 — their thyroid is especially sensitive.';

  @override
  String get iodineWhoPregnant =>
      'Pregnant women as well, there above all to protect the unborn child.';

  @override
  String get iodineWhoOver45 =>
      'Over 45 it is advised against. There the risk of side effects outweighs the thyroid cancer avoided.';

  @override
  String get iodineWhoThyroid =>
      'Anybody with a thyroid condition takes them only after talking to their own doctor.';

  @override
  String get iodineWhenTitle => 'When';

  @override
  String get iodineWhenBody =>
      'The timing decides whether they work. About an hour before contact with the air carrying the radioactive iodine is ideal. Taken too early, the iodine has already been broken down; taken too late, the thyroid has already taken up the radioactive kind. The civil protection authorities announce the moment through the media.';

  @override
  String get iodineHowOftenTitle => 'How often';

  @override
  String get iodineHowOftenBody =>
      'Once is generally enough. A further tablet only if the authority recommends it.';

  @override
  String get iodineWhereTitle => 'Where from';

  @override
  String get iodineWhereBody =>
      'The federal states are responsible. Around nuclear power stations the tablets are either pre-distributed to households or held locally, in town halls and fire stations. Beyond that, more than 180 million tablets are stored across the country; in an event they are handed out at fire stations, town halls, pharmacies or well-known polling stations, after a call in the media.';

  @override
  String get iodineRangeTitle => 'How far';

  @override
  String get iodineRangeBody =>
      'In an accident with substantial release, taking them can be recommended for adults up to 100 kilometres away — and for children across the whole of Germany.';

  @override
  String get iodineHazardLink =>
      'What else to do: hazardous material in the air';

  @override
  String get iodineSource =>
      'Source: Federal Office for Radiation Protection (BfS), \"Einnahme und Wirkung von Jodtabletten\".';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get navChecklists => 'Checklists';

  @override
  String get checklistsTitle => 'Checklists';

  @override
  String get checklistKindPreparation => 'Preparation';

  @override
  String get checklistKindResponse => 'When it happens';

  @override
  String get checklistKindPreparationIntro =>
      'What has to be there before anything happens.';

  @override
  String get checklistKindResponseIntro => 'What to do while it is happening.';

  @override
  String get checklistKindLabel => 'Kind of list';

  @override
  String get checklistKindEmpty => 'Nothing in this part yet.';

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
  String get settingsCategoryWarnings => 'Warnings and places';

  @override
  String get settingsCategoryWarningsBody =>
      'Notifications, monitored places and refresh status';

  @override
  String get settingsCategoryReminders => 'Reminders';

  @override
  String get settingsCategoryRemindersBody =>
      'Batteries, equipment and expiry dates';

  @override
  String get settingsCategoryAppearance => 'Appearance and language';

  @override
  String get settingsCategoryAppearanceBody => 'Colour scheme and app language';

  @override
  String get settingsCategoryData => 'Data and security';

  @override
  String get settingsCategoryDataBody => 'Lock, sharing, backup and reset';

  @override
  String get settingsCategoryOffline => 'Offline and storage';

  @override
  String get settingsCategoryOfflineBody =>
      'Maps, archives and storage locations';

  @override
  String get settingsCategoryAbout => 'About PreppSuite';

  @override
  String get settingsCategoryAboutBody =>
      'Versions of the app and local modules';

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
  String get settingsWarningReadinessTitle => 'Warning readiness';

  @override
  String get settingsWarningReadinessBody =>
      'Checks the local setup. The operating system schedules background refreshes and does not guarantee them.';

  @override
  String get settingsWarningReadinessNotifications => 'Warning notifications';

  @override
  String get settingsWarningReadinessRegions => 'Monitored regions';

  @override
  String get settingsWarningReadinessRefresh => 'Last complete refresh';

  @override
  String get settingsWarningReadinessEnabled => 'Enabled';

  @override
  String get settingsWarningReadinessDisabled => 'Not enabled';

  @override
  String settingsWarningReadinessRegionsSet(int count) {
    return 'Primary place and $count additional regions';
  }

  @override
  String get settingsWarningReadinessRegionsMissing =>
      'No primary place configured yet';

  @override
  String get settingsWarningReadinessNeverUpdated => 'No complete refresh yet';

  @override
  String get settingsWarningReadinessJustNow => 'Updated just now';

  @override
  String settingsWarningReadinessMinutesAgo(int minutes) {
    return 'Updated $minutes minutes ago';
  }

  @override
  String settingsWarningReadinessHoursAgo(int hours) {
    return 'Updated $hours hours ago';
  }

  @override
  String settingsWarningReadinessDaysAgo(int days) {
    return 'Updated $days days ago';
  }

  @override
  String get settingsWarningReadinessBlockedTitle =>
      'Background refresh skipped';

  @override
  String get settingsWarningReadinessBlockedBody =>
      'The last scheduled refresh could not open the local data. Open the app once after unlocking the device.';

  @override
  String get settingsLocalEncryptionTitle => 'Local encryption';

  @override
  String get settingsLocalEncryptionStateEncrypted => 'Encrypted';

  @override
  String get settingsLocalEncryptionStatePlain => 'Not encrypted';

  @override
  String settingsLocalEncryptionStatePartial(int count) {
    return '$count databases still unencrypted';
  }

  @override
  String get settingsLocalEncryptionStateRecovery => 'Key unavailable';

  @override
  String get settingsLocalEncryptionUnsupported =>
      'This build ships without an encryption library.';

  @override
  String get settingsLocalEncryptionPortable =>
      'A carried data folder is not encrypted: the key would stay on this computer and the folder would open nowhere else.';

  @override
  String get settingsLocalEncryptionNoKeyStore =>
      'This device does not grant access to a key store. On macOS the app needs a signature for that; without one the local data stays unencrypted.';

  @override
  String get settingsLocalEncryptionScope =>
      'Not covered: PDFs, maps, ZIM archives, photos and anything you export.';

  @override
  String get settingsLocalEncryptionTestBackup => 'Test a backup';

  @override
  String get settingsLocalEncryptionTestBackupHint =>
      'Reads a backup file back. Nothing is changed.';

  @override
  String settingsLocalEncryptionBackupVerified(int rows) {
    return 'Backup read: $rows records.';
  }

  @override
  String get settingsLocalEncryptionBackupUnreadable =>
      'This file could not be read as a backup of this household.';

  @override
  String get settingsLocalEncryptionBackupNever => 'No backup tested yet.';

  @override
  String get settingsLocalEncryptionBackupStale =>
      'The last test is more than a day old.';

  @override
  String get settingsLocalEncryptionStart => 'Encrypt local data now';

  @override
  String get settingsLocalEncryptionConfirmTitle => 'Encrypt now?';

  @override
  String get settingsLocalEncryptionConfirmBody =>
      'Every local database is rewritten. It temporarily needs as much free space as the largest one takes. Keep the device powered and the app open while it runs. PreppSuite has to be restarted afterwards.';

  @override
  String get settingsLocalEncryptionRunning =>
      'Encrypting the databases. Please leave the app open.';

  @override
  String get settingsLocalEncryptionDoneTitle => 'Encryption finished';

  @override
  String get settingsLocalEncryptionDoneBody =>
      'Close PreppSuite now and open it again.';

  @override
  String get settingsLocalEncryptionFailed =>
      'The upgrade stopped. The data is readable and unchanged.';

  @override
  String get localDataRecoveryTitle => 'Local data locked';

  @override
  String get localDataRecoveryBody =>
      'This device can no longer find the key for its local databases. The files are still there, but unreadable without it. The way back is a backup.';

  @override
  String get localDataRecoveryRetry => 'Try again';

  @override
  String get localDataRecoveryStartOver => 'Set up again';

  @override
  String get localDataRecoveryStartOverBody =>
      'The unreadable files are renamed, not deleted, and stay where they are. PreppSuite then asks from the beginning, where \"Restore from a backup\" brings the household back under the id it had.';

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
  String get shelterLegendTitle => 'Marker guide';

  @override
  String shelterLegendSummary(int green, int yellow, int red) {
    return 'Green $green · Yellow $yellow · Red $red';
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
  String get itemExpiryRemindersLabel => 'Reminders for this item';

  @override
  String get itemExpiryRemindersTitle => 'Lead time for this item';

  @override
  String get itemExpiryRemindersHint =>
      'Applies to this entry only. Without one of its own, what counts is the setting made for the whole household.';

  @override
  String get itemExpiryRemindersDefault => 'As set for the household';

  @override
  String get itemExpiryRemindersOwn => 'Its own lead times';

  @override
  String get itemExpiryRemindersNever => 'Never remind me about this item';

  @override
  String get itemExpiryRemindersNone => 'None';

  @override
  String get itemExpiryRemindersDefaultNone => 'As the household: no reminder';

  @override
  String itemExpiryRemindersDefaultWith(String days) {
    return 'As the household: $days';
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
  String get emergencyCardDoctors => 'Doctors';

  @override
  String get emergencyCardDoctorAdd => 'Add a doctor';

  @override
  String get emergencyCardSpecialty => 'Speciality';

  @override
  String get emergencyCardSpecialtyHint => 'GP, cardiologist';

  @override
  String get emergencyCardContacts => 'Who to call about this person';

  @override
  String get emergencyCardContactAdd => 'Add a contact';

  @override
  String get emergencyCardRelation => 'Relationship';

  @override
  String get emergencyCardRelationHint => 'Partner, son, neighbour';

  @override
  String get emergencyCardPhone => 'Phone number';

  @override
  String get emergencyCardPersonRemove => 'Remove entry';

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
  String knowledgeIndexStorage(String size) {
    return 'Search index: $size';
  }

  @override
  String get knowledgeIndexCompactHint =>
      'This index uses an older format. Rebuilding it in compact form saves storage without changing normal full-text search.';

  @override
  String get knowledgeIndexCompactAction => 'Rebuild compact index';

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
  String get distressTitle => 'Distress signal';

  @override
  String get distressIntro =>
      'For when there is no network left but somebody might still see you. The screen flashes in a rhythm rescuers know — hold it up, towards the slope or the valley.';

  @override
  String get distressBattery =>
      'This costs brightness, and so battery. Switch it on when somebody might be there, not on the off chance.';

  @override
  String get distressStart => 'Start signalling';

  @override
  String get distressStop => 'Stop';

  @override
  String get distressPause => 'Pause — this is where the answer goes';

  @override
  String distressFlash(int number, int total) {
    return 'Signal $number of $total';
  }

  @override
  String get distressSos => 'SOS';

  @override
  String get distressSosHint =>
      'Three short, three long, three short — as one character, not as three letters.';

  @override
  String get distressAlpine => 'Alpine distress signal';

  @override
  String get distressAlpineHint =>
      'Six signals inside a minute, then a minute of nothing, then again. The pause is part of it: it tells the signal apart from somebody walking about with a torch.';

  @override
  String get distressAlpineAnswer => 'Answer to a distress signal';

  @override
  String get distressAlpineAnswerHint =>
      'Three signals inside a minute, into the other one’s pause: I have seen you.';

  @override
  String get myPositionAction => 'Pass on my position';

  @override
  String get myPositionTitle => 'My position';

  @override
  String get myPositionIntro =>
      'Read out whatever is asked for. A control room usually wants degrees and minutes, and reads them back.';

  @override
  String get myPositionOffline =>
      'The app works this out itself. It needs no network — which is when it is wanted.';

  @override
  String get myPositionMeasure => 'Measure again';

  @override
  String get myPositionCopied => 'Copied.';

  @override
  String myPositionAccuracy(int metres) {
    return 'The receiver reports ±$metres m.';
  }

  @override
  String get myPositionAccuracyPoor =>
      'That will not reach a house number. Measure again under open sky, and tell the control room how rough it is.';

  @override
  String myPositionStale(int minutes) {
    return 'This fix is $minutes minutes old. The device could not get a fresh one just now — measure again under open sky before passing it on.';
  }

  @override
  String nearbyStale(int minutes) {
    return 'Worked out from the last known position, $minutes minutes old.';
  }

  @override
  String get myPositionDms => 'Degrees, minutes, seconds';

  @override
  String get myPositionDmsHint =>
      'What a control room asks for on the telephone — and what survives being read aloud and written down.';

  @override
  String get myPositionUtm => 'UTM';

  @override
  String get myPositionUtmHint =>
      'Metres on a grid. Emergency services and the technical relief service work in these.';

  @override
  String get myPositionMgrs => 'MGRS';

  @override
  String get myPositionMgrsHint =>
      'The same grid as one short reference, the way a gridded map labels it.';

  @override
  String get myPositionPlusCode => 'Plus Code';

  @override
  String get myPositionPlusCodeHint =>
      'Ten characters and no map at all, for somebody who is going to type it in.';

  @override
  String get myPositionDecimal => 'Decimal degrees';

  @override
  String get myPositionDecimalHint => 'What goes into a map app.';

  @override
  String get mapMyLocationAction => 'My location';

  @override
  String get mapCoverageMissing =>
      'The offline map does not reach this far. Nothing was ever downloaded for this area.';

  @override
  String mapCoverageIncomplete(int present, int total) {
    return 'The offline map only covers part of this view — roughly $present tiles out of $total. The rest stays empty because it was never downloaded.';
  }

  @override
  String get mapCoverageUseOnline => 'Use the online map';

  @override
  String get mapCoverageUseOffline => 'Use the offline map';

  @override
  String get mapTilesUnavailable =>
      'Some tiles never arrived from the tile server. What is missing is the connection, not the app.';

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
  String get waterTreatmentTitle => 'Making water drinkable';

  @override
  String get waterTreatmentIntro =>
      'The stock is one thing. When it runs low, or the tap is no longer safe, what counts is what can be done with what is there — and what cannot.';

  @override
  String get waterTreatmentChemistryTitle =>
      'No method helps against chemistry';

  @override
  String get waterTreatmentChemistryBody =>
      'Fuel, chemicals and radioactive material come out of water by none of these methods. Water from a flooded street, or from near a heating oil tank that has floated loose, does not become drinkable by boiling. That water stays where it is.';

  @override
  String get waterTreatmentBoilTitle => 'Boiling';

  @override
  String get waterTreatmentBoilCloudy =>
      'Cloudy water first through a clean cloth, paper towel or coffee filter — or let it settle and draw off the clear water.';

  @override
  String get waterTreatmentBoilStep =>
      'Bring clear water to a rolling boil. The WHO holds a rolling boil to be enough to inactivate bacteria, viruses and parasites; the CDC recommends one minute at a rolling boil, three minutes at high altitude above about 2000 metres.';

  @override
  String get waterTreatmentBoilStore =>
      'Let it cool and keep it in clean containers with tight covers.';

  @override
  String get waterTreatmentChlorineTitle => 'Disinfectant';

  @override
  String get waterTreatmentChlorineStep =>
      'Dose as the label says, stir well, and let it stand for at least 30 minutes before drinking.';

  @override
  String get waterTreatmentChlorineLimit =>
      'Works against bacteria and viruses, but less well than boiling against the parasites Cryptosporidium and Giardia — chlorine and iodine tablets do not kill Cryptosporidium. Where you can boil, boil.';

  @override
  String get waterTreatmentFilterTitle => 'Filtering';

  @override
  String get waterTreatmentFilterBody =>
      'A filter takes out the cloudiness and, depending on the filter, germs as well. What it does is written on it — not every one holds back viruses. It replaces boiling only where it says so.';

  @override
  String get waterTreatmentSources =>
      'Sources: WHO Guidelines for Drinking-water Quality and \"Boil water\"; CDC, making water safe in an emergency.';

  @override
  String get waterTreatmentOpen => 'Making water drinkable';

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
      'Per 100 g each — or per 100 ml for drinks — exactly as the label states them. Scanning a barcode fills in what it says; the app does the multiplying.';

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
  String get warningWhatToDoNow => 'What to do now';

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
  String get knowledgeDocumentOpenExternal => 'Open externally';

  @override
  String get knowledgeDocumentContinue => 'Continue reading';

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
  String get emergencyContactEdit => 'Edit contact';

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
      'Too large for the index (256 MB maximum)';

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
  String get statusSupplyTitle => 'Supplies';

  @override
  String statusSupplyCovered(int days) {
    return 'Lasts $days days';
  }

  @override
  String statusSupplyShort(int days, int target) {
    return 'Lasts $days of $target days';
  }

  @override
  String get statusSupplyUnknown => 'Nothing recorded yet';

  @override
  String statusSupplyBasis(int target) {
    return 'Against the BBK’s own figures: $target days, 2 l and 2200 kcal per person per day.';
  }

  @override
  String statusSupplyUncounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries are not counted',
      one: 'One entry is not counted',
    );
    return '$_temp0 — its unit names no measure.';
  }

  @override
  String get statusSituationTitle => 'Situation';

  @override
  String get statusSituationQuiet => 'No official warning';

  @override
  String get statusSituationQuietHint =>
      'Authorities publish warnings, not all-clears. That none is in force is not a statement that nothing is wrong.';

  @override
  String statusSituationActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count warnings',
      one: 'One warning',
    );
    return '$_temp0 for your area';
  }

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Screen, supply, checklist entry …';

  @override
  String get searchStartHint =>
      'Type to search the whole app: screens, supplies, checklist entries and the household inventory.';

  @override
  String searchNothingFound(String query) {
    return 'Nothing found for “$query”.';
  }

  @override
  String get searchAction => 'Search';

  @override
  String get searchGroupScreens => 'Screens';

  @override
  String get searchGroupInventory => 'Supplies';

  @override
  String get searchGroupChecklists => 'Checklists';

  @override
  String get searchGroupPossessions => 'Household inventory';

  @override
  String get settingsVersionInfoFirstAid => 'First aid content';

  @override
  String get settingsVersionInfoFirstAidValue =>
      'ERC 2025 source status (GRC edition)';

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
  String shelterCachedAt(Object date, Object time) {
    return 'Showing cached shelter data from $date, $time because at least one source is currently unavailable.';
  }

  @override
  String get appLockTitle => 'App lock';

  @override
  String get appLockDisabledHint =>
      'Protects the app with a separate passphrase after you leave it.';

  @override
  String get appLockEnabledHint =>
      'The passphrase is required when you return to the app.';

  @override
  String get appLockSetTitle => 'Set up app lock';

  @override
  String get appLockDisableTitle => 'Turn off app lock';

  @override
  String get appLockDialogHint =>
      'The passphrase is not stored. It protects access to the open app.';

  @override
  String get appLockPassphraseLabel => 'Passphrase';

  @override
  String get appLockConfirmLabel => 'Repeat passphrase';

  @override
  String get appLockPassphraseTooShort =>
      'The passphrase must contain at least 12 characters.';

  @override
  String get appLockPassphraseMismatch => 'The passphrases do not match.';

  @override
  String get appLockEnableButton => 'Turn on lock';

  @override
  String get appLockDisableButton => 'Turn off lock';

  @override
  String get appLockUnlockTitle => 'Unlock PreppSuite';

  @override
  String get appLockUnlockButton => 'Unlock';

  @override
  String get appLockIncorrectPassphrase => 'The passphrase is incorrect.';

  @override
  String get appLockEnabled => 'The app lock is active.';

  @override
  String get appLockDisabled => 'The app lock is turned off.';

  @override
  String get appLockStatusUnavailableTitle => 'Lock status unavailable';

  @override
  String get appLockStatusUnavailableBody =>
      'The lock status cannot be read safely right now. The app stays closed until it is available again.';

  @override
  String get appLockSettingsUnavailable =>
      'The lock status cannot be read safely right now.';

  @override
  String get appLockRetry => 'Try again';

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
  String get transferTitle => 'Transfer without a network';

  @override
  String get transferIntro =>
      'One device shows a run of images, the other films them. No network, no shared folder, no pairing — the two devices only have to be next to each other.';

  @override
  String get transferSend => 'Show household';

  @override
  String get transferReceive => 'Film household';

  @override
  String get transferSendTitle => 'Show household';

  @override
  String get transferSendHint =>
      'Point the other device\'s camera at this screen. The images run in a loop — one that is missed comes round again on its own.';

  @override
  String transferFrameOf(int index, int total) {
    return 'Image $index of $total';
  }

  @override
  String get transferSendNothing =>
      'This household has nothing in it yet that could be transferred.';

  @override
  String get transferSlower => 'Slower';

  @override
  String get transferFaster => 'Faster';

  @override
  String get transferReceiveTitle => 'Film household';

  @override
  String get transferReceiveHint =>
      'Hold it at the other device\'s screen and leave it there until it is full.';

  @override
  String transferProgress(int received, int total) {
    return '$received of $total images';
  }

  @override
  String get transferWaiting => 'No image recognised yet.';

  @override
  String transferDone(int rows) {
    return 'Complete. $rows rows taken in.';
  }

  @override
  String get transferNothingNew => 'Complete. All of it was already known.';

  @override
  String get transferBroken => 'The images do not fit together. Film it again.';

  @override
  String get transferWrongHousehold =>
      'That is a different household. Only what belongs to this one is taken in.';

  @override
  String get transferCameraNeeded => 'Filming needs the camera.';

  @override
  String get transferSendOverNetwork => 'Over the network (fast)';

  @override
  String get transferSendOverNetworkHint =>
      'Both devices are on the same network — home wifi, a hotspot, a campsite. The code here is the key: only whoever films it gets in. The whole household crosses in one go, in both directions.';

  @override
  String get transferSendWaiting => 'Waiting for the other device …';

  @override
  String get transferSendNoNetwork =>
      'This device is on no network. That leaves the run of images.';

  @override
  String get transferUseChain => 'Show without a network instead';

  @override
  String get transferUseNetwork => 'Use the network instead';

  @override
  String get transferSendChainHint =>
      'Without a network: point the other device\'s camera at this screen. The images run in a loop — one that is missed comes round again on its own.';

  @override
  String transferHandoverDone(int rows) {
    return 'Synced. $rows rows taken in.';
  }

  @override
  String transferHandoverPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pictures came with it.',
      one: 'One picture came with it.',
    );
    return '$_temp0';
  }

  @override
  String get transferHandoverNothing =>
      'Synced. Both devices were already at the same point.';

  @override
  String get transferUnreachable =>
      'The other device cannot be reached. Are both on the same network?';

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
  String get portableChoiceMissingTitle => 'The chosen data folder is missing';

  @override
  String get portableChoiceMissingBody =>
      'You picked a data folder once and it cannot be reached right now. Until it is back, the app is working with the data on this machine — a different household. Anything you enter now is not in the folder you chose.';

  @override
  String portableChoiceMissingWhere(String path) {
    return 'You chose: $path';
  }

  @override
  String get portableChoiceMissingHint =>
      'Usually the disk is not plugged in. Plug it in and start the app again.';

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

  @override
  String get outageTitle => 'Power outage';

  @override
  String get outageEntryHint =>
      'How long the fridge and the freezer still hold.';

  @override
  String get outageIntro =>
      'While the power is off, the cold runs out. Tap when it starts and the app keeps counting, even if you close it.';

  @override
  String get outageStart => 'The power just went out';

  @override
  String get outageEnded => 'The power is back';

  @override
  String outageRunningSince(String time) {
    return 'Running since $time';
  }

  @override
  String get outageChangeStart => 'Different time';

  @override
  String get outageStoreRefrigerator => 'Refrigerator';

  @override
  String get outageStoreFreezer => 'Freezer';

  @override
  String outageRemaining(String left) {
    return '$left left';
  }

  @override
  String outageRemainingHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String outageRemainingMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String outageUntil(String time) {
    return 'Until $time';
  }

  @override
  String outageGrace(String left) {
    return 'Window over — discard in $left';
  }

  @override
  String get outageSpoilt => 'Discard perishable food';

  @override
  String get outageFreezerFill => 'Freezer';

  @override
  String get outageFreezerFull => 'Well filled';

  @override
  String get outageFreezerHalf => 'Half full or less';

  @override
  String get outageFreezerWhy =>
      'A full freezer holds for about 48 hours, a half-full one for about 24. The cold is in the food itself, not in the appliance.';

  @override
  String get outageRulesTitle => 'Rules';

  @override
  String get outageRuleClosed =>
      'Keep the door shut. Every opening costs hours, and the figures here only hold for a closed door.';

  @override
  String outageRuleTwoHours(int degrees) {
    return 'Anything that spent two hours above $degrees °C goes — meat, fish, eggs, dairy, leftovers.';
  }

  @override
  String get outageRuleTaste =>
      'Never taste food to decide. You cannot taste it.';

  @override
  String get outageRuleRefreeze =>
      'Refreezing is allowed while ice crystals remain. Quality suffers, safety does not.';

  @override
  String get outageRuleGenerator =>
      'Run a generator outdoors only, at least 6 metres from windows, doors and an attached garage.';

  @override
  String get outageRuleUnplug =>
      'Unplug appliances: the power comes back as a surge.';

  @override
  String get outageSource =>
      'The hour figures come from FEMA (ready.gov) and the USDA (FSIS). No German authority publishes figures for this, which is why the source is named here.';

  @override
  String get dailyDoseLabel => 'Taken per day';

  @override
  String get dailyDoseHelper =>
      'In the same unit as the stock: with 60 tablets and 2 a day, enter “2”. Leave empty if it is not taken daily.';

  @override
  String get medicationTitle => 'Medication';

  @override
  String get medicationEntryHint => 'How long the medication lasts.';

  @override
  String get medicationIntro =>
      'The same arithmetic as for supplies and fuel, applied to the medicine cabinet: stock divided by what is taken per day. Both figures are yours — the app never guesses a dose.';

  @override
  String get medicationNothingYet => 'No medication entered yet';

  @override
  String get medicationNothingYetWhy =>
      'Enter a medicine as a supply item in the “medical” category and give what is taken per day. Only then is there something to work out.';

  @override
  String get medicationNoAnswer =>
      'No medicine has a daily amount entered — without one there is nothing to divide.';

  @override
  String medicationShortest(String name, String days) {
    return 'Runs out first: $name — $days';
  }

  @override
  String get medicationShortestWhy =>
      'That is the reach of the medicine cabinet. A refill needs a practice and a pharmacy, and in an emergency neither is available at once.';

  @override
  String medicationRunsOut(String date) {
    return 'Gone on $date';
  }

  @override
  String medicationDays(int days) {
    return '$days days';
  }

  @override
  String get medicationOneDay => '1 day';

  @override
  String get medicationZeroDays => 'Less than a day';

  @override
  String medicationStock(String quantity, String unit, String dose) {
    return '$quantity $unit in stock, $dose a day';
  }

  @override
  String get medicationWithoutDoseTitle => 'Without a daily amount';

  @override
  String get medicationWithoutDoseWhy =>
      'These are in the stores but not counted. They are named here instead of being quietly skipped — otherwise the figure above would read as covering the whole cabinet.';

  @override
  String get medicationSource =>
      'FEMA and the CDC both advise keeping a supply of prescription medication and knowing how long it lasts. How large that supply may be is a matter for the practice — the app only counts what is there.';

  @override
  String get possessionsTitle => 'Household inventory';

  @override
  String get possessionsEntryHint =>
      'What the household owns — for the insurer.';

  @override
  String get possessionsEmpty => 'Nothing entered yet';

  @override
  String get possessionsWhy =>
      'After a fire, a flood or a break-in the insurer asks what was there. Nobody answers that from memory. This list is not the supply store — it is what would have to be replaced.';

  @override
  String get possessionsNoRoom => 'No room given';

  @override
  String possessionsTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String possessionsWithoutPrice(int count) {
    return '$count entries without a price are not in the total.';
  }

  @override
  String get possessionsExport => 'Export as PDF';

  @override
  String get possessionsPdfTitle => 'Household inventory';

  @override
  String get possessionsKeepElsewhere =>
      'This list does not belong only in the home it describes. Print it and keep it elsewhere, or mail it to yourself. The photos are not in this file — they are only on the device that took them.';

  @override
  String get possessionAdd => 'Entry';

  @override
  String get possessionAddTitle => 'New entry';

  @override
  String get possessionEditTitle => 'Edit entry';

  @override
  String get possessionNameLabel => 'Item';

  @override
  String get possessionNameNeeded =>
      'A name, or the row will say nothing later.';

  @override
  String get possessionRoomLabel => 'Room';

  @override
  String get possessionRoomHelper =>
      'Living room, cellar, garage — however you walk through it.';

  @override
  String get possessionSerialLabel => 'Serial number';

  @override
  String get possessionSerialHelper =>
      'The one field that cannot be reconstructed afterwards. Usually on the back or underneath.';

  @override
  String get possessionPriceLabel => 'Purchase price';

  @override
  String get possessionCurrencyLabel => 'Currency';

  @override
  String get possessionAcquiredLabel => 'Bought on';

  @override
  String get possessionAcquiredNone => 'No date';

  @override
  String get possessionPhotoTitle => 'Photo';

  @override
  String get possessionPhotoWhy =>
      'A picture convinces an insurer more than any description. It stays on this device and does not go into the shared folder.';

  @override
  String get possessionPhotoCamera => 'Take photo';

  @override
  String get possessionPhotoGallery => 'Choose photo';

  @override
  String get possessionPhotoRemove => 'Remove photo';

  @override
  String get possessionRemoveTitle => 'Delete entry?';

  @override
  String possessionRemoveBody(String name) {
    return '“$name” will be removed on every device in the household.';
  }

  @override
  String possessionsCount(int count) {
    return '$count items';
  }

  @override
  String get firstAidTitle => 'First aid';

  @override
  String get firstAidContentVersionTitle => 'Where these guides come from';

  @override
  String get firstAidContentVersionBody =>
      'Content follows the 2025 Guidelines of the European Resuscitation Council. The pages under \"Mental distress\" follow the IFRC International first aid, resuscitation and education guidelines 2025. What a first aid course teaches is agreed jointly by the aid organisations; in a course, what is said there applies.';

  @override
  String get firstAidEntryHint =>
      'Instructions, drawings and a pacer for chest compressions. No network, no download.';

  @override
  String get firstAidSearchHint => 'What are you looking for?';

  @override
  String get firstAidSearchEmpty => 'There is no guide here for that.';

  @override
  String get firstAidDisclaimer =>
      'These guides replace neither a first aid course nor an emergency call. In doubt: call 112 and stay on the line — the dispatcher will talk you through it.';

  @override
  String get firstAidGroupBasics => 'First of all';

  @override
  String get firstAidGroupLifeThreatening => 'Life-threatening';

  @override
  String get firstAidGroupInjury => 'Injuries';

  @override
  String get firstAidGroupIllness => 'Sudden illness';

  @override
  String get firstAidGroupEnvironment => 'Cold, heat, poison';

  @override
  String get firstAidGroupMental => 'Mental distress';

  @override
  String get firstAidCallNow => 'Call 112';

  @override
  String get firstAidCallFirst => 'Here you call first and help second.';

  @override
  String get firstAidSteps => 'Steps';

  @override
  String get firstAidReadAloud => 'Read the steps aloud';

  @override
  String get firstAidStopReading => 'Stop reading';

  @override
  String get firstAidCautions => 'Do not';

  @override
  String firstAidSource(String source) {
    return 'Source: $source';
  }

  @override
  String get firstAidOpenPacer => 'Start the pacer';

  @override
  String get firstAidVideos => 'Videos';

  @override
  String get firstAidVideosNone => 'No video is installed for this guide.';

  @override
  String get firstAidVideoManage => 'Manage the video pack';

  @override
  String get firstAidVideoMissing =>
      'The video file is gone. Fetch the pack again.';

  @override
  String get firstAidVideoRestart => 'From the start';

  @override
  String get firstAidVideoSystemPlayer =>
      'This system cannot play video inside the app. The button below opens the file in the computer\'s own player.';

  @override
  String get firstAidVideoOpenExternal => 'Open in the system player';

  @override
  String get firstAidVideoNotACourse =>
      'A video is not a course. The movements only stick once you have done them yourself.';

  @override
  String get firstAidVideoPackTitle => 'Video pack';

  @override
  String get firstAidVideoPackWhy =>
      'The guides need no video: the text, the figures and the drawings are complete and always there. Videos are an extra for the evening you sit down to learn the movements properly — and they are a separate download, because ten films weigh more than the whole app.';

  @override
  String get firstAidVideoPackWhereTitle => 'Where to get one';

  @override
  String get firstAidVideoPackWhereBody =>
      'There are no ready-made packs, and this app points at none. Every usable German first aid video is somebody’s copyright — the aid organisations’ material entirely. Freely licensed material exists mainly on Wikimedia Commons, but little of it: on 22 September 2026 the category “Videos of cardiopulmonary resuscitation” held eight files, mostly not in German, one of them a dog being resuscitated. Each licence is on its own file page and has to be checked one by one.';

  @override
  String get firstAidVideoPackWhereHow =>
      'To build your own pack, see docs/erste-hilfe.md in the source. The credit and licence of each clip are shown under the video later.';

  @override
  String get firstAidVideoPackFromNetwork => 'Over the network';

  @override
  String get firstAidVideoPackUrlLabel => 'Address of the pack description';

  @override
  String get firstAidVideoPackUrlHelper =>
      'The address of a paket.json. This app ships none — enter the address where you published your pack.';

  @override
  String get firstAidVideoPackFetch => 'Fetch the description';

  @override
  String get firstAidVideoPackFromFile => 'From a file';

  @override
  String get firstAidVideoPackFromFileWhy =>
      'A pack as a zip, from a memory stick or from the shared folder. This is the way that works without a network — that is, in the situation this app is built for.';

  @override
  String get firstAidVideoPackImport => 'Choose a pack file';

  @override
  String get firstAidVideoPackNone => 'No video pack installed yet.';

  @override
  String firstAidVideoPackInstalled(int present, int total, String size) {
    return '$present of $total videos present, $size on disk';
  }

  @override
  String get firstAidVideoPackRemove => 'Delete the video pack';

  @override
  String get firstAidVideoPackRemoveBody =>
      'The video files and the pack description are removed from the device. The guides themselves are untouched.';

  @override
  String firstAidVideoPackOffer(int count, String size) {
    return '$count videos, $size in all';
  }

  @override
  String get firstAidVideoPackStart => 'Fetch them all';

  @override
  String firstAidVideoPackProgress(int done, int total) {
    return '$done of $total done';
  }

  @override
  String firstAidVideoPackDone(int done, int total) {
    return '$done of $total videos fetched';
  }

  @override
  String get firstAidVideoPackLicenceNote =>
      'Every video names its author and its licence. Only fetch packs whose films may be passed on.';

  @override
  String get firstAidVideoPackBadUrl => 'That is not a complete address.';

  @override
  String get firstAidVideoPackClose => 'Close';

  @override
  String get pacerTitle => 'Pacer';

  @override
  String get pacerStart => 'Start';

  @override
  String get pacerStop => 'Stop';

  @override
  String get pacerIdle =>
      'Sets the beat for chest compressions — as a tone, as a flash and, on a phone, as a vibration. The screen stays on while it runs.';

  @override
  String pacerElapsed(String time) {
    return 'Running $time';
  }

  @override
  String get pacerDepth =>
      '5–6 cm deep · vertically from above · let the chest come all the way back up';

  @override
  String get pacerNoSound =>
      'No sound on this device. The beat keeps flashing.';

  @override
  String pacerPerMinute(int rate) {
    return '$rate/min';
  }

  @override
  String pacerOfCycle(int total, int cycle) {
    return 'of $total · round $cycle';
  }

  @override
  String get pacerBreathe => 'Now 2 breaths';

  @override
  String get pacerSwapNow => 'Swap over if there are two of you';

  @override
  String get pacerPushOnly => 'Push without stopping';

  @override
  String get pacerPushOnlyShort => 'Push only';

  @override
  String get warningSituationMapTitle => 'Warning situation map';

  @override
  String get warningSituationMapEmpty =>
      'There are no active warnings for this selection.';

  @override
  String get warningSituationMapNoGeometry =>
      'The active warnings do not include map areas. Their complete guidance remains available offline in the warning list.';

  @override
  String get warningSituationMapFailed =>
      'The stored warning situation could not be read.';

  @override
  String get warningSituationMapTapHint =>
      'Tap the map to see what applies at a spot.';

  @override
  String get warningSituationMapAtPoint => 'At this spot';

  @override
  String get warningSituationMapNothingHere =>
      'None of the areas shown covers this spot.';

  @override
  String get knowledgeApolloPackagesTitle => 'APOLLO package status';

  @override
  String knowledgeApolloPackageSummary(int installed, int total) {
    return '$installed of $total recommended sources available';
  }

  @override
  String get knowledgeApolloPackageInstalled =>
      'Downloaded and registered in the library';

  @override
  String get knowledgeApolloPackageMissing => 'Not yet in the library';

  @override
  String get readinessEquipment => 'Equipment and batteries checked';

  @override
  String get readinessEquipmentOff => 'The check routine is switched off';

  @override
  String get readinessEquipmentNotChecked => 'No check has been confirmed yet';

  @override
  String get readinessEquipmentDue => 'A check is due';

  @override
  String get readinessEquipmentChecked =>
      'A check was confirmed within the chosen interval';

  @override
  String get transferNearbyTitle => 'Devices on the local network';

  @override
  String get transferNearbyHint =>
      'Only random, short-lived availability signals are searched for. Select a device, then scan its visible QR code; nothing is transferred without that code.';

  @override
  String get transferNearbyEmpty =>
      'No transfer-ready PreppSuite device has been found on this network yet.';

  @override
  String get transferNearbyUnavailable =>
      'Device discovery is not available on this network right now. You can still scan the QR code directly.';

  @override
  String get transferNearbyDevice => 'PreppSuite device ready';

  @override
  String get transferNearbyScanHint =>
      'Scan this device\'s QR code for the secure handover';

  @override
  String get settingsRegionLabel => 'Label (optional)';

  @override
  String get settingsRegionLabelHelper =>
      'For example home, work or a relative.';

  @override
  String get knowledgeCheckTitle => 'Check your knowledge';

  @override
  String get knowledgeCheckIntro =>
      'First aid goes quiet without telling you. A few questions show what still holds — and what does not.';

  @override
  String knowledgeCheckProgress(int number, int total) {
    return 'Question $number of $total';
  }

  @override
  String get knowledgeCheckRight => 'Right.';

  @override
  String get knowledgeCheckWrong => 'Not quite.';

  @override
  String get knowledgeCheckReadGuide => 'Read the guide';

  @override
  String get knowledgeCheckNext => 'Next';

  @override
  String get knowledgeCheckFinish => 'Done';

  @override
  String knowledgeCheckResult(int right, int total) {
    return '$right of $total right.';
  }

  @override
  String knowledgeCheckHeld(int held, int total) {
    return '$held of $total questions hold.';
  }

  @override
  String get knowledgeCheckComeBack =>
      'Come back in a few months. Not tomorrow — that is not what this is for.';

  @override
  String get knowledgeCheckReview => 'Worth reading again';

  @override
  String get knowledgeCheckAgain => 'Another round';

  @override
  String get mapPlacesImport => 'Read places in';

  @override
  String get mapPlacesExport => 'Hand places over';

  @override
  String get mapPlacesExportGpx => 'Hand over as GPX';

  @override
  String get mapPlacesExportKml => 'Hand over as KML';

  @override
  String get mapPlacesExportFailed => 'The file could not be written.';

  @override
  String get mapPlacesImportNothing =>
      'There is no place in this file that the app can read.';

  @override
  String mapPlacesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count places were added.',
      one: 'One place was added.',
      zero: 'Every place was already here.',
    );
    return '$_temp0';
  }

  @override
  String get mapPlacesTitle => 'My places';

  @override
  String get mapPlacesIntro =>
      'Personal places appear as markers on the map. They stay on this device only.';

  @override
  String get mapPlacesEmpty =>
      'No personal places yet. Save meeting points, distribution points, or important supplies.';

  @override
  String get mapPlaceAdd => 'Add place';

  @override
  String get mapPlaceEdit => 'Edit place';

  @override
  String get mapPlacePrivacy =>
      'These location details stay local to this device and are not shared with the household.';

  @override
  String get mapPlaceLabel => 'Label';

  @override
  String get mapPlaceLatitude => 'Latitude';

  @override
  String get mapPlaceLongitude => 'Longitude';

  @override
  String get mapPlaceNote => 'Note (optional)';

  @override
  String get mapPlaceNoteHint =>
      'For example access, supplies, or meeting time';

  @override
  String get mapPlaceCoordinatesInvalid =>
      'Enter a label and valid coordinates.';

  @override
  String mapPlaceDeleteConfirm(Object label) {
    return 'Remove “$label”?';
  }

  @override
  String drillsLastCompleted(String date) {
    return 'last completed: $date';
  }

  @override
  String get hubTitle => 'Crisis organisation';

  @override
  String get hubPrivacyNote =>
      'Everything here stays on this device. If you export an incident log, you decide who receives it.';

  @override
  String get hubNotCheckedYet => 'not checked yet';

  @override
  String get hubAutonomyTitle => 'Self-sufficiency';

  @override
  String get hubAutonomyHint =>
      'Range in days, worked out from your stock and your energy plan. The lowest figure is the next bottleneck.';

  @override
  String hubAutonomyIncomplete(String resources) {
    return 'Self-sufficiency not yet complete. Open: $resources.';
  }

  @override
  String hubAutonomyKnownSoFar(int days, String resource) {
    return 'Of what is known: $days days, bottleneck $resource.';
  }

  @override
  String hubAutonomyRange(int days, String resource) {
    return '$days days on your own – bottleneck: $resource';
  }

  @override
  String get hubAutonomyOpen => 'open';

  @override
  String hubAutonomyDays(int days) {
    return '$days days';
  }

  @override
  String get hubAutonomyAddByHand => 'Fill in by hand';

  @override
  String get hubAutonomyDialogTitle => 'Range in days';

  @override
  String get hubAutonomyDialogHint =>
      'What the app can work out from your stock and energy plan is already on the screen. This is only for what it cannot divide.';

  @override
  String hubAutonomyDaysField(String label) {
    return '$label – days';
  }

  @override
  String get hubAutonomyFromStock => 'Worked out from your stock';

  @override
  String hubAutonomyByHandWith(String reason) {
    return 'Entered by hand – $reason';
  }

  @override
  String hubAutonomyNotCounted(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries not counted: $reason',
      one: 'One entry not counted: $reason',
    );
    return '$_temp0';
  }

  @override
  String get hubResourceWater => 'Water';

  @override
  String get hubResourceFood => 'Food';

  @override
  String get hubResourceMedicine => 'Medicines';

  @override
  String get hubResourceEnergy => 'Energy';

  @override
  String get hubResourceHygiene => 'Hygiene';

  @override
  String get hubGapOnlyByHand => 'the app does not count this';

  @override
  String get hubGapNoEnergyPlan => 'no energy plan yet';

  @override
  String get hubGapNothingRecorded => 'nothing recorded in your stock yet';

  @override
  String get hubGapNoLiters => 'not recorded in litres';

  @override
  String get hubGapNoCalories => 'without a calorie figure';

  @override
  String get hubGapNoDose => 'without a daily dose';

  @override
  String get hubGapNoDraw => 'nothing draws on it';

  @override
  String get hubWaterHygieneTitle => 'Water and hygiene';

  @override
  String get hubWaterHygieneHint =>
      'Plan drinking water, service water, treatment, canister rotation, toilet and waste separately.';

  @override
  String get hubWaterHygieneLabel => 'Water and hygiene plan';

  @override
  String get hubWaterHygieneTemplate =>
      'Drinking water: …\nService water: …\nSources and treatment: …\nCanister rotation: …\nToilet, waste and cleaning supplies: …';

  @override
  String get hubPowerOutageTitle => 'Power cut plan';

  @override
  String get hubPowerOutageHint =>
      'Prepare the start time, the cold chain, charging priorities, light, information and safe warmth.';

  @override
  String get hubPowerOutageTemplate =>
      'Note the start time. Keep fridge and freezer shut. Write down charging priorities, radio, light, safe warmth and who to contact.';

  @override
  String get hubCookingTitle => 'Cooking from stock';

  @override
  String get hubCookingHint =>
      'Plan meals around the stock, the water and the fuel they need.';

  @override
  String get hubCookingLabel => 'Cooking-from-stock plan';

  @override
  String get hubCookingTemplate =>
      'Dish: …\nIngredients from stock: …\nWater: …\nFuel and cooking time: …\nSafe place to cook: …';

  @override
  String get hubCookingRecipes => 'Open offline recipes';

  @override
  String get hubRedundancyTitle => 'Second ways';

  @override
  String get hubRedundancyHint =>
      'Write down a second way to get water, light, cooking, information and communication.';

  @override
  String get hubRedundancyTemplate =>
      'Water: main way / fallback\nLight: main way / fallback\nCooking: main way / fallback\nInformation and communication: main way / fallback';

  @override
  String get hubClimateRoomTitle => 'Room for cold and heat';

  @override
  String get hubClimateRoomHint =>
      'Decide in advance which room to use, what to wear, how to ventilate and how to warm or cool it safely.';

  @override
  String get hubClimateRoomLabel => 'Room for cold and heat';

  @override
  String get hubClimateRoomTemplate =>
      'Room: …\nWarmth/cooling: …\nBlankets and clothing: …\nVentilation: …\nCO alarm and safe appliances: …';

  @override
  String get hubRadioTitle => 'Radio reception plan';

  @override
  String get hubRadioHint =>
      'Write down local FM and DAB stations, the receivers and how they are powered.';

  @override
  String get hubRadioAdd => 'Add a station';

  @override
  String get hubRadioDialogTitle => 'Add radio reception';

  @override
  String get hubRadioStation => 'Station';

  @override
  String get hubRadioBand => 'Band';

  @override
  String get hubRadioFrequency => 'Frequency or channel';

  @override
  String get hubRadioReceiver => 'Receiver';

  @override
  String get hubRadioPower => 'Power supply';

  @override
  String hubRadioDetails(
    String band,
    String frequency,
    String receiver,
    String power,
    String checked,
  ) {
    return '$band · $frequency\n$receiver · $power\nTested: $checked';
  }

  @override
  String get hubFolderTitle => 'Emergency folder';

  @override
  String get hubFolderHint =>
      'Keep track of the folder itself — no contents and no personal details.';

  @override
  String get hubFolderLocation => 'Where it is kept';

  @override
  String get hubFolderLocationHint => 'e.g. a lockable cupboard';

  @override
  String get hubFolderNotSet => 'not set';

  @override
  String get hubFolderCopies => 'Copies of important papers are ready';

  @override
  String get hubFolderTakeAlong => 'Take it when evacuating';

  @override
  String get hubFolderCheckedToday => 'Checked today';

  @override
  String get hubCommunicationTitle => 'Communication plan';

  @override
  String get hubCommunicationHint =>
      'Who is contacted in what order, who coordinates from outside, and short status messages for overloaded networks.';

  @override
  String get hubCommunicationTemplate =>
      'Who is contacted, and in what order? Who coordinates from outside?\n\nTemplate: We are safe. Next contact at …';

  @override
  String get hubStatusSafe => 'We are safe. Next contact at …';

  @override
  String get hubStatusHelp => 'We need help with … Meeting point: …';

  @override
  String get hubSupportTitle => 'Support plan';

  @override
  String get hubSupportHint =>
      'Personal support, medicines, aids and transport during an evacuation.';

  @override
  String get hubSupportTemplate =>
      'Only what is needed: the help required, medicines, aids, reliable support and transport.';

  @override
  String get hubPetsTitle => 'Pet emergency plan';

  @override
  String get hubPetsHint =>
      'Prepare transport, food, medicines, care and somewhere else to stay for the animals.';

  @override
  String get hubPetsTemplate =>
      'Carrier, supplies, vet, care, pet-friendly accommodation and copies of the papers.';

  @override
  String get hubMobilityTitle => 'Vehicle and getting about';

  @override
  String get hubMobilityHint =>
      'A kit in the vehicle, a fuel or charge reserve, other ways to travel, and who collects whom.';

  @override
  String get hubMobilityLabel => 'Mobility plan';

  @override
  String get hubMobilityTemplate =>
      'Vehicle, charge or fuel target, kit, alternative route, public transport and collection.';

  @override
  String get hubUtilitiesTitle => 'Utilities cut off';

  @override
  String get hubUtilitiesHint =>
      'Where the shut-offs are, and manual alternatives for power, water, gas, heating and telephony.';

  @override
  String get hubUtilitiesLabel => 'Utilities plan';

  @override
  String get hubUtilitiesTemplate =>
      'Shut-off points, who to call, backup power, where to draw water, heating and ways to communicate without contact.';

  @override
  String get hubMaintenanceTitle => 'Maintenance';

  @override
  String get hubMaintenanceHint =>
      'Check regularly, so the equipment that matters works when it is needed.';

  @override
  String hubMaintenanceLastChecked(String date) {
    return 'Last checked: $date';
  }

  @override
  String get hubEvacuationTitle => 'Evacuation cards';

  @override
  String get hubEvacuationHint =>
      'Meeting points and safe routes, written down so they can be read offline.';

  @override
  String get hubEvacuationAdd => 'Add a card';

  @override
  String get hubEvacuationRemove => 'Remove card';

  @override
  String get hubEvacuationDialogTitle => 'Evacuation card';

  @override
  String get hubEvacuationLabel => 'Name, e.g. Home';

  @override
  String get hubEvacuationStart => 'Starting point';

  @override
  String get hubEvacuationDestination => 'Meeting point or destination';

  @override
  String get hubEvacuationRoute => 'Route and alternatives';

  @override
  String get hubEvacuationPlaces => 'Important places on the way';

  @override
  String get hubEvacuationStartOpen => 'Start not set';

  @override
  String get hubEvacuationDestinationOpen => 'Destination not set';

  @override
  String hubEvacuationSummary(
    String start,
    String destination,
    String checked,
  ) {
    return '$start → $destination\nChecked: $checked';
  }

  @override
  String hubEvacuationStartLine(String value) {
    return 'Start: $value';
  }

  @override
  String hubEvacuationDestinationLine(String value) {
    return 'Destination: $value';
  }

  @override
  String get hubEvacuationPlacesLine => 'Important places';

  @override
  String get hubEventsTitle => 'Incident log';

  @override
  String get hubEventsHint =>
      'Record observations and what was done, with the time, and export them as a PDF if needed.';

  @override
  String get hubEventsAdd => 'Add an entry';

  @override
  String get hubEventsExport => 'Export as PDF';

  @override
  String get hubEventsDialogTitle => 'Record an incident';

  @override
  String get hubEventsKind => 'Kind';

  @override
  String get hubEventsKindHint => 'Incident';

  @override
  String get hubEventsNote => 'Observation or damage';

  @override
  String get hubEventsAction => 'What was done';

  @override
  String hubEventsObservationLine(String text) {
    return 'Observation: $text';
  }

  @override
  String hubEventsActionLine(String text) {
    return 'Action: $text';
  }

  @override
  String get hubEventsPdfTitle => 'PreppSuite – incident log';

  @override
  String get hubEventsPdfFile => 'preppsuite-incident-log.pdf';

  @override
  String get hubActionsTitle => 'What to do, and when';

  @override
  String get hubActionsHint =>
      'Preparation by how much warning there is: right now, within 48 hours, and several days ahead.';

  @override
  String get hubActionNowTitle => 'Right now';

  @override
  String get hubActionNowBody =>
      'Read the official message, keep out of danger, switch the radio on and tell your family briefly.';

  @override
  String get hubActionTwoDaysTitle => 'Within 24–48 hours';

  @override
  String get hubActionTwoDaysBody =>
      'Check water, stock, medicines, batteries and the vehicle. Get the house and the kit ready.';

  @override
  String get hubActionDaysTitle => 'Several days ahead';

  @override
  String get hubActionDaysBody =>
      'Go over the evacuation card, arrange support, check the pet and utilities plans.';

  @override
  String hubActionDone(String date) {
    return 'Done: $date';
  }

  @override
  String get hubCrisisTitle => 'Crisis mode and briefing';

  @override
  String get hubCrisisHint =>
      'A larger display for this page, and a printable briefing for the household or the kit.';

  @override
  String get hubCrisisSwitch => 'Simplified, larger display';

  @override
  String get hubCrisisSwitchHint =>
      'Makes the text and controls in the crisis organisation larger.';

  @override
  String get hubBriefingButton => 'Emergency briefing as PDF';

  @override
  String get hubBriefingPdfTitle => 'PreppSuite – emergency briefing';

  @override
  String hubBriefingCreated(String date) {
    return 'Created: $date';
  }

  @override
  String get hubBriefingRadio => 'Radio';

  @override
  String hubBriefingRadioLine(
    String station,
    String band,
    String frequency,
    String receiver,
  ) {
    return '$station: $band $frequency · $receiver';
  }

  @override
  String get hubBriefingEvacuation => 'Evacuation';

  @override
  String hubBriefingEvacuationLine(
    String label,
    String start,
    String destination,
  ) {
    return '$label: $start -> $destination';
  }

  @override
  String get hubBriefingPdfFile => 'preppsuite-emergency-briefing.pdf';

  @override
  String get hubAnalogTitle => 'On paper';

  @override
  String get hubAnalogHint =>
      'Keep printouts, maps, notes and spare keys available without a battery or a network.';

  @override
  String get hubAnalogTemplate =>
      'Printed maps, a phone list, instructions, cash, spare keys and where they are kept.';

  @override
  String get hubMutualAidTitle => 'Helping each other';

  @override
  String get hubMutualAidHint =>
      'Plan skills, equipment and safe ways to get in touch locally. Nothing is published.';

  @override
  String get hubMutualAidLabel => 'Help and exchange card';

  @override
  String get hubMutualAidTemplate =>
      'Your own skills and equipment, the support you need, people you trust, and where to hand things over.';

  @override
  String get hubPracticeTitle => 'Practice and upkeep';

  @override
  String get hubPracticeHint =>
      'Regularly practise with the water filter, cooking, the radio, the kit and the paper routines.';

  @override
  String get hubPracticeLabel => 'Practice and upkeep plan';

  @override
  String get hubPracticeTemplate =>
      'Next practice: …\nTest the water filter: …\nCook without power: …\nCheck the radio and the kit: …';

  @override
  String get hubNoteEmpty => 'Not written down yet.';

  @override
  String hubNoteUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get hubNoteCreate => 'Write a plan';

  @override
  String get hubNoteEdit => 'Edit';

  @override
  String get hubNoteCopyTemplate => 'Copy template';

  @override
  String get hubEntryRemove => 'Remove entry';

  @override
  String get hubClose => 'Close';

  @override
  String get hubCancel => 'Cancel';

  @override
  String get hubSave => 'Save';

  @override
  String hubDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get hubTaskBatteriesTitle => 'Batteries and power banks';

  @override
  String get hubTaskBatteriesHint => 'Check the charge and the spares';

  @override
  String get hubTaskRadioTitle => 'Radio and reception plan';

  @override
  String get hubTaskRadioHint =>
      'Test the stations, the aerial and the power supply';

  @override
  String get hubTaskWaterFilterTitle => 'Water filter and canisters';

  @override
  String get hubTaskWaterFilterHint =>
      'Check the filter, the seals and the stock';

  @override
  String get hubTaskKitTitle => 'Emergency kit';

  @override
  String get hubTaskKitHint => 'Check clothing, light and personal needs';

  @override
  String get hubTaskMedicineTitle => 'Medicine cabinet';

  @override
  String get hubTaskMedicineHint => 'Check expiry dates and personal medicines';

  @override
  String get hubTaskExtinguisherTitle => 'Extinguisher and smoke alarms';

  @override
  String get hubTaskExtinguisherHint =>
      'Check the service date and the batteries';

  @override
  String get hubTaskVehicleTitle => 'Vehicle and getting about';

  @override
  String get hubTaskVehicleHint => 'Check fuel, tyres and alternative routes';

  @override
  String hubFolderCheckedTodayWith(String date) {
    return 'Checked today · last $date';
  }

  @override
  String get hubBriefingCommunication => 'Communication';

  @override
  String get hubBriefingSupport => 'Support';

  @override
  String get hubBriefingPets => 'Pets';

  @override
  String get hubBriefingMobility => 'Getting about';

  @override
  String get hubBriefingUtilities => 'Utilities';

  @override
  String get hubBriefingPowerOutage => 'Power cut';

  @override
  String get hubBriefingRedundancy => 'Second ways';

  @override
  String get hubBriefingClimate => 'Cold and heat';

  @override
  String get hubRadioPowerExample => 'Batteries';

  @override
  String get hubEventsNoteHint => 'Observation';

  @override
  String hubEventSummary(String when, String text) {
    return '$when\n$text';
  }

  @override
  String get hubSituationTitle => 'Something is happening';

  @override
  String hubSituationOutage(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Power cut for $hours hours',
      one: 'Power cut for an hour',
      zero: 'Power cut, just started',
    );
    return '$_temp0';
  }

  @override
  String hubSituationMoreWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'And $count more warnings',
      one: 'And one more warning',
    );
    return '$_temp0';
  }

  @override
  String get hubSituationCrisisMode => 'Switch to the larger display';

  @override
  String get hubSituationLog => 'Record it in the log';

  @override
  String get hubSituationOutageKind => 'Power cut';

  @override
  String get hubFolderReportButton => 'Emergency folder as PDF';

  @override
  String get hubFolderReportTitle => 'Emergency folder';

  @override
  String get hubFolderReportIntro =>
      'Print this and keep it away from the home: with relatives, in the vehicle or in the kit. It does not replace the original documents.';

  @override
  String get hubFolderReportFile => 'preppsuite-emergency-folder.pdf';

  @override
  String get hubFolderReportRoute => 'Route';

  @override
  String get hubFolderReportPlaces => 'Important places';

  @override
  String get hubFolderReportAutonomy => 'Self-sufficiency';

  @override
  String get mapWaterTitle => 'Drinking water affected';

  @override
  String mapWaterStock(String value) {
    return 'Your own drinking water: $value';
  }

  @override
  String mapWaterStockUnknown(String reason) {
    return 'How far your own supply reaches is still open: $reason.';
  }

  @override
  String get mapWaterNearby => 'Drinking water nearby';

  @override
  String get mapWaterAdviceNote =>
      'What to do with the water is in the warning itself. This app publishes no figures of its own on that.';

  @override
  String get setupChoiceTitle => 'Set up a household';

  @override
  String get setupChoiceIntro =>
      'Does this household already exist on another device? Then bring it over instead of starting a new one — otherwise you end up with two households side by side that never merge.';

  @override
  String get setupChoiceNewTitle => 'Start a new household';

  @override
  String get setupChoiceNewBody =>
      'The first device. Everything else can be handed over from here later.';

  @override
  String get setupChoiceFolderTitle => 'Choose a shared folder';

  @override
  String get setupChoiceFolderBody =>
      'If the household lives in a folder both devices can see — iCloud, Nextcloud, a stick, or a folder some sync app keeps in step — this device joins it and stays up to date by itself.';

  @override
  String get setupChoiceScanTitle => 'Take it from another device';

  @override
  String get setupChoiceScanBody =>
      'The other device shows a QR code and this one reads it. Over the local network the whole household goes across in one go; with no network, as a sequence of images.';

  @override
  String get setupChoiceSafeNote =>
      'Now is the safest moment for this: this device has no data of its own yet that would have to be re-stamped.';

  @override
  String get setupChoiceRestoreTitle => 'Restore from a backup';

  @override
  String get setupChoiceRestoreBody =>
      'Read a password-protected backup file. The household comes back under the id it had.';

  @override
  String setupRestoreDone(int count) {
    return '$count records restored.';
  }

  @override
  String get setupRestoreFailed =>
      'This file could not be read. Wrong password, or not a PreppSuite backup.';

  @override
  String get setupRestoreDefaultName => 'Restored household';

  @override
  String get setupFolderSearching => 'Reading the folder …';

  @override
  String setupFolderFound(String name) {
    return 'Household found: $name';
  }

  @override
  String get setupFolderFoundBody =>
      'This device will join it. Name and country come from the folder; region and household size stay with this device.';

  @override
  String get setupFolderEmpty =>
      'There is no household in this folder yet. A new one will be created and written into it.';

  @override
  String get setupScanHint =>
      'First fill in what belongs to this device. Then read the other device\'s QR code, and the household is taken over.';

  @override
  String get setupScanContinue => 'Continue to the scan';

  @override
  String setupJoinFailed(String reason) {
    return 'Could not join: $reason';
  }

  @override
  String get setupDoneFolder =>
      'Folder connected. The household keeps itself in step from now on.';

  @override
  String setupDoneScan(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows entries arrived.',
      one: 'One entry arrived.',
      zero: 'Nothing new was in it.',
    );
    return 'Household taken over. $_temp0';
  }

  @override
  String get setupScanCancelled => 'Cancelled — no household was taken over.';

  @override
  String setupAdopted(String name) {
    return 'Household “$name” taken over.';
  }

  @override
  String get transferAdoptHousehold => 'Take over this code\'s household';

  @override
  String get transferConflictTitle => 'Two different households';

  @override
  String transferConflictBody(String mine) {
    return 'This device belongs to “$mine”, the code belongs to a different household. What happens next cannot be undone: two merged sets of data cannot be separated again.';
  }

  @override
  String get transferConflictMerge => 'Merge them';

  @override
  String transferConflictMergeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'The $count entries of its own move into the other household, and that household\'s data comes here. Nothing is lost.',
      one:
          'The one entry of its own moves into the other household, and that household\'s data comes here. Nothing is lost.',
      zero:
          'This device has nothing to bring and simply joins the other household.',
    );
    return '$_temp0';
  }

  @override
  String get transferConflictReplace => 'Discard this device\'s data';

  @override
  String transferConflictReplaceBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'The $count entries of its own are deleted.',
      one: 'The one entry of its own is deleted.',
    );
    return '$_temp0 Only the other household remains here afterwards.';
  }

  @override
  String get transferConflictKeep => 'Change nothing';

  @override
  String get transferConflictKeepBody =>
      'Nothing is taken over. If the other device should join this one instead, show the code there and read it there.';

  @override
  String get transferConflictCancelled => 'Cancelled. Nothing was changed.';

  @override
  String get transferConflictReplaced =>
      'This device\'s data discarded, the other household taken over.';

  @override
  String get backupShare => 'Share the backup';

  @override
  String get backupShareHint =>
      'Hand it to another app — a cloud the file picker cannot reach, for instance. The file is encrypted with your passphrase; whoever gets it without that passphrase can do nothing with it.';

  @override
  String get backupShareSubject => 'PreppSuite backup';

  @override
  String get toolsHubTitle => 'Crisis organisation';

  @override
  String get toolsHubBody =>
      'Radio, emergency folder, upkeep, evacuation cards and incident log';

  @override
  String get toolsLearnTitle => 'A quick round';

  @override
  String get toolsLearnBody =>
      'Short offline refreshers, alongside the drills and the knowledge archive.';

  @override
  String toolsAnswerRight(String explanation) {
    return 'Correct. $explanation';
  }

  @override
  String toolsAnswerWrong(String explanation) {
    return 'Have another look: $explanation';
  }

  @override
  String toolsDrillDuration(int minutes) {
    return 'Preparation: $minutes minutes';
  }

  @override
  String toolsDrillMeta(String duration, String completed) {
    return '$duration · $completed';
  }

  @override
  String get toolsLessonCommunicationTitle => 'Communication';

  @override
  String get toolsLessonCommunicationSummary =>
      'Take load off the networks and coordinate contacts.';

  @override
  String get toolsLessonCommunicationQuestion =>
      'Which way usually works best when the mobile network is overloaded?';

  @override
  String get toolsLessonCommunicationAnswerA => 'A long call';

  @override
  String get toolsLessonCommunicationAnswerB =>
      'A short message naming a time to reply';

  @override
  String get toolsLessonCommunicationAnswerC => 'Redialling over and over';

  @override
  String get toolsLessonCommunicationExplanation =>
      'Short messages need less network capacity and spare the battery.';

  @override
  String get toolsLessonEvacuationTitle => 'Evacuation';

  @override
  String get toolsLessonEvacuationSummary =>
      'Keep the plan, the kit and the meeting point ready.';

  @override
  String get toolsLessonEvacuationQuestion =>
      'What should be checked before an evacuation?';

  @override
  String get toolsLessonEvacuationAnswerA =>
      'Meeting point, route and the support anyone needs';

  @override
  String get toolsLessonEvacuationAnswerB => 'Only the weather app';

  @override
  String get toolsLessonEvacuationAnswerC => 'Only the fuel gauge';

  @override
  String get toolsLessonEvacuationExplanation =>
      'A clear meeting point, the route and individual needs prevent stress and bad decisions.';

  @override
  String get toolsLessonPowerTitle => 'Power cut';

  @override
  String get toolsLessonPowerSummary => 'Secure light, information and energy.';

  @override
  String get toolsLessonPowerQuestion =>
      'What is the battery or wind-up radio for?';

  @override
  String get toolsLessonPowerAnswerA =>
      'As a replacement for official warnings';

  @override
  String get toolsLessonPowerAnswerB =>
      'As an additional channel for information';

  @override
  String get toolsLessonPowerAnswerC => 'Only for listening to music';

  @override
  String get toolsLessonPowerExplanation =>
      'Radio adds to the system\'s warnings and works when the internet does not.';

  @override
  String get toolsDrillPowerTitle => '72 hours without power';

  @override
  String get toolsDrillPowerStepA => 'Put out light, radio and a power bank';

  @override
  String get toolsDrillPowerStepB => 'Check water, stove and supplies';

  @override
  String get toolsDrillPowerStepC => 'Keep fridge and freezer shut';

  @override
  String get toolsDrillEvacuationTitle => 'Evacuation in 15 minutes';

  @override
  String get toolsDrillEvacuationStepA => 'Pack documents and medicines';

  @override
  String get toolsDrillEvacuationStepB =>
      'Check the meeting point and route on the offline map';

  @override
  String get toolsDrillEvacuationStepC =>
      'Go over who is in the household and how to reach them';

  @override
  String get toolsDrillCommunicationTitle => 'Communication is down';

  @override
  String get toolsDrillCommunicationStepA =>
      'Check local radio and the warnings';

  @override
  String get toolsDrillCommunicationStepB =>
      'Keep nearby contacts and the meeting point at hand';

  @override
  String get toolsDrillCommunicationStepC =>
      'Use a radio only on a service you are allowed to use';

  @override
  String get recipeOnlyInGerman => 'Only available in German';

  @override
  String get recipeOnlyInEnglish => 'Only available in English';

  @override
  String get emergencyMapReady => 'Opened and ready to use';

  @override
  String get emergencyMapMissing => 'No checked map package yet';

  @override
  String get emergencyKnowledgeReady => 'Archive opened and ready to use';

  @override
  String get emergencyKnowledgeMissing => 'No checked knowledge archive yet';

  @override
  String get knowledgeNoBookmarks =>
      'No bookmarks yet. Open an article and tap the bookmark symbol.';

  @override
  String get knowledgeInOpenArchive => 'In the archive that is open';

  @override
  String get knowledgeOpenArchiveFirst =>
      'Open the archive in the library first';

  @override
  String get radioCbCallingChannel =>
      'The usual calling and distress channel on CB radio.';

  @override
  String get radioCbRoadChannel =>
      'A channel widely used on the road and by lorry drivers.';

  @override
  String caloriesPer100Label(String basis) {
    return 'Calories per $basis (kcal, optional)';
  }

  @override
  String get unitInfoAction => 'Why a measure?';

  @override
  String get unitInfoTitle => 'Why g, kg, ml or l?';

  @override
  String get unitInfoWhy =>
      'Nutrition is printed on every packet per 100 g or per 100 ml. A stock only becomes a day’s ration if the amount can be said in grams too — and what six tins weigh is on the tin, not in this app.';

  @override
  String get unitInfoAccepted =>
      'These with one tap, and spelled out works as well: gram, kilo, millilitre, litre.';

  @override
  String get unitInfoExempt =>
      'This applies to food and water only. Medicines are still counted in tablets, or the reach per daily dose stops adding up; tools are counted in pieces.';

  @override
  String get unitInfoKept =>
      'A stock counted in tins or jars is left exactly as it is. It simply stays out of the supply calculator until the unit names a measure.';

  @override
  String get unitMeasureRequired => 'This needs a measure: g, kg, ml or l.';

  @override
  String nutritionPer100Label(String nutrient, String basis) {
    return '$nutrient per $basis';
  }

  @override
  String get foodWithoutMeasureTitle => 'Not counted: a unit with no measure';

  @override
  String foodWithoutMeasureBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count foods are',
      one: 'One food is',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'They do',
      one: 'It does',
    );
    return '$_temp0 counted in a unit no label can be applied to — a tin, a jar. $_temp1 not count towards the supply calculator until the unit is g, kg, ml or l.';
  }

  @override
  String get transferInterrupted =>
      'The connection was made but the transfer did not finish. Keep both devices awake and try again — with a lot of photos it takes a moment.';

  @override
  String transferLastSeen(int frame) {
    return 'Last read: frame $frame';
  }

  @override
  String transferLastSeenMixed(int frame, int discarded) {
    return 'Last read: frame $frame · $discarded frames belonged to a different transfer';
  }

  @override
  String get operationsTitle => 'Situation now';

  @override
  String get operationsWarning => 'Active warning for your places';

  @override
  String get operationsQuiet => 'Your followed places are quiet';

  @override
  String get operationsOpenWarnings => 'Check warnings';

  @override
  String get operationsOpenReadiness => 'Open readiness';

  @override
  String operationsNextTask(String task) {
    return 'Next: $task';
  }

  @override
  String get operationsChargeDue => 'Check batteries and equipment';

  @override
  String get operationsInventoryMissing => 'Set up supplies';

  @override
  String get operationsReady =>
      'Core preparation is in place – check details when needed';

  @override
  String get followedPlacesTitle => 'My warning places';

  @override
  String get followedPlacesIntro =>
      'Warnings for home and other important regions. Labels for additional places stay on this device.';

  @override
  String get followedPlacesPrimary => 'Primary place';

  @override
  String get followedPlacesAdditional => 'Additional places';

  @override
  String get followedPlacesOpen => 'Manage warning places';

  @override
  String get householdPlanShareSafety => 'Share safety message';

  @override
  String householdPlanSafetyMessage(String meetingPoint) {
    return 'We are safe.\\nMeeting point: $meetingPoint\\nNext update: …';
  }

  @override
  String get toolsDrillEquipmentTitle => 'Check batteries and equipment';

  @override
  String get toolsDrillEquipmentStepA =>
      'Charge and label power banks, lights and spare batteries';

  @override
  String get toolsDrillEquipmentStepB =>
      'Test radio, chargers and cables from mains or a power bank';

  @override
  String get toolsDrillEquipmentStepC => 'Set the due date for the next check';

  @override
  String get toolsDrillRadioTitle => 'Radio and information check';

  @override
  String get toolsDrillRadioStepA =>
      'Check batteries, antenna and reception on the radio';

  @override
  String get toolsDrillRadioStepB =>
      'Write down local stations, warning channels and agreed frequencies';

  @override
  String get toolsDrillRadioStepC =>
      'Only transmit in an authorised radio service and record a short reception check';

  @override
  String get operationsWarningDetail =>
      'Open details, affected areas and recommended actions';

  @override
  String get navGroupNow => 'Now';

  @override
  String get navGroupPrepare => 'Prepare';

  @override
  String get navGroupOffline => 'Offline';

  @override
  String get navGroupProfile => 'Profile and settings';

  @override
  String get emergencyCardCareTitle => 'Support and dependencies';

  @override
  String get emergencyCardCareHint =>
      'For power needs, assistive devices, care or transport, write a short concrete note here, for example “wheelchair – spare battery in hall; transport: …”. This information is sensitive.';

  @override
  String get shareFailed => 'The share sheet could not be opened.';

  @override
  String get householdPlanSafetyHint =>
      'Adjust the message and the time of the next update before sharing.';

  @override
  String get hubResilienceTitle => 'Warning paths and network';

  @override
  String get hubResilienceHint =>
      'Prepare warning channels, personal support, sources, learning and nearby help locally.';

  @override
  String get resilienceWarningTitle => 'Check warning paths';

  @override
  String get resilienceWarningHint =>
      'Mark a route successful only after it has actually been tested on this device or in the household.';

  @override
  String get resilienceWarningNina => 'NINA warning app set up and tested';

  @override
  String get resilienceWarningCell => 'Cell Broadcast checked on this device';

  @override
  String get resilienceWarningSiren =>
      'Siren or municipal warning route clarified';

  @override
  String get resilienceWarningRadio => 'Radio and local warning station tested';

  @override
  String get resilienceSupportTitle => 'Personal support';

  @override
  String get resilienceSupportHint =>
      'Optional plan for dependencies during an outage or evacuation. Do not store a medical diagnosis.';

  @override
  String get resilienceSupportPower =>
      'Power-dependent aids and backup power reviewed';

  @override
  String get resilienceSupportEvacuation => 'Help leaving the home clarified';

  @override
  String get resilienceSupportTransport => 'Transport or pickup arranged';

  @override
  String get resilienceSupportMedicine => 'Medication plan and supply reviewed';

  @override
  String get resilienceSupportAssistance =>
      'Care, assistance or animal needs clarified';

  @override
  String get resilienceSupportNote => 'Short personal plan';

  @override
  String get resilienceSourcesTitle => 'Source compass';

  @override
  String get resilienceSourcesHint =>
      'Only record sources whose information you verify yourself. Always add a route without internet.';

  @override
  String get resilienceSourcesEmpty => 'No local source recorded yet.';

  @override
  String get resilienceSourceAdd => 'Add source';

  @override
  String get resilienceSourceLabel => 'Organisation or topic';

  @override
  String get resilienceSourceChannel => 'Access route';

  @override
  String get resilienceSourceFallback => 'Offline fallback';

  @override
  String get resilienceLearningTitle => 'APOLLO learning paths';

  @override
  String get resilienceLearningHint =>
      'Only mark a path after downloading it and doing a short offline test.';

  @override
  String get resilienceLearningOpen => 'Open APOLLO';

  @override
  String get resilienceLearningMedical => 'First aid and medical basics';

  @override
  String get resilienceLearningWater => 'Water, hygiene and cooking';

  @override
  String get resilienceLearningRepair => 'Repair and energy';

  @override
  String get resilienceLearningNavigation =>
      'Navigation, radio and communication';

  @override
  String get resilienceLearningSchool => 'Basics and learning with children';

  @override
  String get resilienceNeighborhoodTitle => 'Neighbourhood help';

  @override
  String get resilienceNeighborhoodHint =>
      'Voluntary skills and safe contact paths. An alias is enough; real names are not needed.';

  @override
  String get resilienceNeighborhoodEmpty =>
      'No nearby capability recorded yet.';

  @override
  String get resilienceNeighborhoodAdd => 'Add capability';

  @override
  String get resilienceNeighborAlias => 'Alias or role';

  @override
  String get resilienceNeighborSkill => 'Skill or equipment';

  @override
  String get resilienceNeighborContact => 'Agreed contact path';

  @override
  String get resilienceNeighborMeeting => 'Meeting point';

  @override
  String get resilienceMaintenanceSchedule => 'Check interval';

  @override
  String get resilienceMaintenanceOff => 'Not scheduled';

  @override
  String get resilienceMaintenanceDue => 'Check due';

  @override
  String resilienceMaintenanceEveryDays(int days) {
    return 'Every $days days';
  }

  @override
  String get statusSupplyLimitWater => 'Limiting factor: drinking water.';

  @override
  String get statusSupplyLimitCalories =>
      'Limiting factor: available calories.';

  @override
  String get statusSupplyLimitBoth =>
      'Limiting factors: drinking water and available calories.';
}
