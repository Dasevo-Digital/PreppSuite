import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite'**
  String get appTitle;

  /// No description provided for @householdNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Household name'**
  String get householdNameLabel;

  /// No description provided for @countryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// No description provided for @regionKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Regional key (optional)'**
  String get regionKeyLabel;

  /// No description provided for @regionKeyHelper.
  ///
  /// In en, this message translates to:
  /// **'Germany only, for more precise warnings'**
  String get regionKeyHelper;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {error}'**
  String errorGeneric(String error);

  /// No description provided for @errorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check the network and try again.'**
  String get errorNoConnection;

  /// No description provided for @errorArchiveUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The archive could not be read. The file may have moved, or the disk it is on is not attached.'**
  String get errorArchiveUnreadable;

  /// No description provided for @errorFileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file could not be reached.'**
  String get errorFileUnreadable;

  /// No description provided for @errorDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download stopped. Starting it again picks up where it left off.'**
  String get errorDownloadFailed;

  /// No description provided for @errorServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The service did not answer. That is not on you — try again later.'**
  String get errorServiceUnavailable;

  /// No description provided for @errorDatabase.
  ///
  /// In en, this message translates to:
  /// **'The app\'s database reported a problem. Restarting usually clears it.'**
  String get errorDatabase;

  /// No description provided for @errorPlatformRefused.
  ///
  /// In en, this message translates to:
  /// **'The system refused. Check in the settings whether PreppSuite has permission for it.'**
  String get errorPlatformRefused;

  /// No description provided for @navInventory.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get navInventory;

  /// No description provided for @navHousehold.
  ///
  /// In en, this message translates to:
  /// **'Household'**
  String get navHousehold;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navShelters.
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get navShelters;

  /// No description provided for @inventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Inventory'**
  String get inventoryTitle;

  /// No description provided for @inventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No items yet. Tap + to add your first one.'**
  String get inventoryEmpty;

  /// No description provided for @addItemButton.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemButton;

  /// No description provided for @editItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get editItemTitle;

  /// No description provided for @addItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItemTitle;

  /// No description provided for @itemNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get itemNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @categoryWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get categoryWater;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get categoryMedical;

  /// No description provided for @categoryTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get categoryTools;

  /// No description provided for @categoryDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get categoryDocuments;

  /// No description provided for @categoryEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get categoryEnergy;

  /// No description provided for @categoryHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene'**
  String get categoryHygiene;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @storageLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Storage location'**
  String get storageLocationLabel;

  /// No description provided for @expirationDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Expiration date (optional)'**
  String get expirationDateLabel;

  /// No description provided for @minQuantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum quantity (optional)'**
  String get minQuantityLabel;

  /// No description provided for @caloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories, total kcal (optional)'**
  String get caloriesLabel;

  /// No description provided for @supplyCalculatorDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'Supplies for {days} days'**
  String supplyCalculatorDaysLabel(int days);

  /// No description provided for @supplyCalculatorWaterLabel.
  ///
  /// In en, this message translates to:
  /// **'Drinking water'**
  String get supplyCalculatorWaterLabel;

  /// No description provided for @supplyCalculatorCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get supplyCalculatorCaloriesLabel;

  /// No description provided for @supplyCalculatorProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {target} {unit}'**
  String supplyCalculatorProgress(String current, String target, String unit);

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get notesLabel;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @lowStockBadge.
  ///
  /// In en, this message translates to:
  /// **'Low stock'**
  String get lowStockBadge;

  /// No description provided for @expiredBadge.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expiredBadge;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number.'**
  String get invalidNumber;

  /// No description provided for @clearDateButton.
  ///
  /// In en, this message translates to:
  /// **'Clear date'**
  String get clearDateButton;

  /// No description provided for @scanBarcodeButton.
  ///
  /// In en, this message translates to:
  /// **'Scan barcode'**
  String get scanBarcodeButton;

  /// No description provided for @scannedBarcodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Barcode: {barcode}'**
  String scannedBarcodeLabel(String barcode);

  /// No description provided for @productNotFound.
  ///
  /// In en, this message translates to:
  /// **'Product not found — fill in the details by hand.'**
  String get productNotFound;

  /// No description provided for @itemPhotoLabel.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get itemPhotoLabel;

  /// No description provided for @addPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhotoButton;

  /// No description provided for @takePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhotoButton;

  /// No description provided for @chooseFromGalleryButton.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGalleryButton;

  /// No description provided for @removePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoButton;

  /// No description provided for @csvImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get csvImportButton;

  /// No description provided for @csvImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get csvImportTitle;

  /// No description provided for @csvImportInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Expected format'**
  String get csvImportInstructionsTitle;

  /// No description provided for @csvImportInstructionsBody.
  ///
  /// In en, this message translates to:
  /// **'The first row must be a header row. Required columns: name, category, quantity, unit, storageLocation. Optional columns: expirationDate, minQuantity, notes. German column names are also recognized (Name, Kategorie, Menge, Einheit, Lagerort, Ablaufdatum, Mindestbestand, Notizen).\n\nCategory: water, food, medical, tools, documents, energy, hygiene, or other (German names also work, e.g. Wasser, Lebensmittel).\nDates: YYYY-MM-DD or DD.MM.YYYY.\nNumbers: \".\" or \",\" as the decimal separator.\nDelimiter: \",\" or \";\", detected automatically.'**
  String get csvImportInstructionsBody;

  /// No description provided for @csvImportPickFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV file…'**
  String get csvImportPickFileButton;

  /// No description provided for @csvImportChangeFileButton.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file…'**
  String get csvImportChangeFileButton;

  /// No description provided for @csvImportParsing.
  ///
  /// In en, this message translates to:
  /// **'Reading file…'**
  String get csvImportParsing;

  /// No description provided for @csvImportSummary.
  ///
  /// In en, this message translates to:
  /// **'{valid} of {total} rows can be imported.'**
  String csvImportSummary(int valid, int total);

  /// No description provided for @csvImportRowError.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {reason}'**
  String csvImportRowError(int row, String reason);

  /// No description provided for @csvImportReasonMissingColumns.
  ///
  /// In en, this message translates to:
  /// **'Missing required columns (name, category, quantity, unit, storage location).'**
  String get csvImportReasonMissingColumns;

  /// No description provided for @csvImportReasonNameMissing.
  ///
  /// In en, this message translates to:
  /// **'Name is missing.'**
  String get csvImportReasonNameMissing;

  /// No description provided for @csvImportReasonUnknownCategory.
  ///
  /// In en, this message translates to:
  /// **'Unknown category \"{value}\".'**
  String csvImportReasonUnknownCategory(String value);

  /// No description provided for @csvImportReasonInvalidQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid quantity \"{value}\".'**
  String csvImportReasonInvalidQuantity(String value);

  /// No description provided for @csvImportReasonUnitMissing.
  ///
  /// In en, this message translates to:
  /// **'Unit is missing.'**
  String get csvImportReasonUnitMissing;

  /// No description provided for @csvImportReasonStorageLocationMissing.
  ///
  /// In en, this message translates to:
  /// **'Storage location is missing.'**
  String get csvImportReasonStorageLocationMissing;

  /// No description provided for @csvImportReasonInvalidDate.
  ///
  /// In en, this message translates to:
  /// **'Invalid date \"{value}\".'**
  String csvImportReasonInvalidDate(String value);

  /// No description provided for @csvImportReasonInvalidMinQuantity.
  ///
  /// In en, this message translates to:
  /// **'Invalid minimum quantity \"{value}\".'**
  String csvImportReasonInvalidMinQuantity(String value);

  /// No description provided for @csvImportImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import {count} rows'**
  String csvImportImportButton(int count);

  /// No description provided for @csvImportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} items imported.'**
  String csvImportSuccessMessage(int count);

  /// No description provided for @csvImportNoValidRows.
  ///
  /// In en, this message translates to:
  /// **'No valid rows found in this file.'**
  String get csvImportNoValidRows;

  /// No description provided for @csvImportFileReadError.
  ///
  /// In en, this message translates to:
  /// **'Could not read this file: {error}'**
  String csvImportFileReadError(String error);

  /// No description provided for @csvImportRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Row {row}'**
  String csvImportRowLabel(int row);

  /// No description provided for @csvImportEditRowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get csvImportEditRowTooltip;

  /// No description provided for @csvImportRemoveRowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from import'**
  String get csvImportRemoveRowTooltip;

  /// No description provided for @csvImportEditRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit row'**
  String get csvImportEditRowTitle;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @navChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get navChecklists;

  /// No description provided for @checklistsTitle.
  ///
  /// In en, this message translates to:
  /// **'Checklists'**
  String get checklistsTitle;

  /// No description provided for @checklistsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No checklists yet. Tap + to create your first one.'**
  String get checklistsEmpty;

  /// No description provided for @createTemplateButton.
  ///
  /// In en, this message translates to:
  /// **'New checklist'**
  String get createTemplateButton;

  /// No description provided for @createTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'New checklist'**
  String get createTemplateTitle;

  /// No description provided for @templateTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Checklist name'**
  String get templateTitleLabel;

  /// No description provided for @checklistCategoryFirstAid.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get checklistCategoryFirstAid;

  /// No description provided for @checklistCategoryCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get checklistCategoryCustom;

  /// No description provided for @builtInBadge.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtInBadge;

  /// No description provided for @duplicateTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateTemplateAction;

  /// No description provided for @deleteTemplateAction.
  ///
  /// In en, this message translates to:
  /// **'Delete checklist'**
  String get deleteTemplateAction;

  /// No description provided for @addChecklistItemHint.
  ///
  /// In en, this message translates to:
  /// **'Add an item…'**
  String get addChecklistItemHint;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @checklistProgress.
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total}'**
  String checklistProgress(int checked, int total);

  /// No description provided for @budgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetTitle;

  /// No description provided for @budgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'No spending recorded yet. Tap + to add your first entry.'**
  String get budgetEmpty;

  /// No description provided for @addBudgetEntryButton.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addBudgetEntryButton;

  /// No description provided for @addBudgetEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addBudgetEntryTitle;

  /// No description provided for @editBudgetEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editBudgetEntryTitle;

  /// No description provided for @budgetLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get budgetLabelLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @currencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currencyLabel;

  /// No description provided for @purchaseDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase date (optional)'**
  String get purchaseDateLabel;

  /// No description provided for @budgetTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get budgetTotalLabel;

  /// No description provided for @warningsTitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get warningsTitle;

  /// No description provided for @warningsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No warnings for your region right now.'**
  String get warningsEmpty;

  /// No description provided for @warningsNinaHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Warnings while the app is closed'**
  String get warningsNinaHintTitle;

  /// No description provided for @warningsNinaHintBody.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite polls the official warning feeds every 15 minutes and shows them as an overview. For immediate alerts that reach you with the app closed, use NINA from Germany\'s Federal Office of Civil Protection — the same official source, in seconds rather than minutes.'**
  String get warningsNinaHintBody;

  /// No description provided for @warningDayToday.
  ///
  /// In en, this message translates to:
  /// **'Today is the nationwide warning day'**
  String get warningDayToday;

  /// No description provided for @warningDayIn.
  ///
  /// In en, this message translates to:
  /// **'Nationwide warning day in {days, plural, =1{one day} other{{days} days}}'**
  String warningDayIn(int days);

  /// No description provided for @warningDayBody.
  ///
  /// In en, this message translates to:
  /// **'Test warning at 11:00, all-clear at 11:45. Sirens, Cell Broadcast, radio and the warning apps are tested together. It is the one day a year on which you can find out whether what is meant to reach you actually does – a warning that never arrives goes unnoticed otherwise.'**
  String get warningDayBody;

  /// No description provided for @warningDayNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Today is the nationwide warning day'**
  String get warningDayNotificationTitle;

  /// No description provided for @warningDayNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'The test warning goes out at 11:00 and the all-clear at 11:45. A good moment to check that sirens, Cell Broadcast and the warning apps reach you.'**
  String get warningDayNotificationBody;

  /// No description provided for @pegelTitle.
  ///
  /// In en, this message translates to:
  /// **'Water levels'**
  String get pegelTitle;

  /// No description provided for @pegelEntryHint.
  ///
  /// In en, this message translates to:
  /// **'The level on your own river, with the gauge\'s reference values'**
  String get pegelEntryHint;

  /// No description provided for @pegelNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'No gauge chosen yet.'**
  String get pegelNoneChosen;

  /// No description provided for @pegelUpstreamHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the gauge upstream of you. The nearest one is no help if it lies downstream – it shows what has already passed, not what is coming.'**
  String get pegelUpstreamHint;

  /// No description provided for @pegelChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a gauge'**
  String get pegelChoose;

  /// No description provided for @pegelChange.
  ///
  /// In en, this message translates to:
  /// **'Choose another gauge'**
  String get pegelChange;

  /// No description provided for @pegelSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a gauge or waterway'**
  String get pegelSearchHint;

  /// No description provided for @pegelSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No gauge found.'**
  String get pegelSearchEmpty;

  /// No description provided for @pegelLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The gauge list could not be loaded. It needs a connection once.'**
  String get pegelLoadFailed;

  /// No description provided for @pegelOffline.
  ///
  /// In en, this message translates to:
  /// **'No connection – this is the last value fetched.'**
  String get pegelOffline;

  /// No description provided for @pegelStale.
  ///
  /// In en, this message translates to:
  /// **'More than an hour old. Inland gauges report every 15 minutes, so what is missing is the connection and not the water.'**
  String get pegelStale;

  /// No description provided for @pegelMeasuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured {time}'**
  String pegelMeasuredAt(String time);

  /// No description provided for @pegelRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get pegelRefresh;

  /// No description provided for @pegelKilometre.
  ///
  /// In en, this message translates to:
  /// **'River kilometre {km}'**
  String pegelKilometre(String km);

  /// No description provided for @pegelReferences.
  ///
  /// In en, this message translates to:
  /// **'This gauge\'s reference values'**
  String get pegelReferences;

  /// No description provided for @pegelNoReferences.
  ///
  /// In en, this message translates to:
  /// **'No reference values are published for this gauge, so the number stands without a scale.'**
  String get pegelNoReferences;

  /// No description provided for @pegelNoMeldestufe.
  ///
  /// In en, this message translates to:
  /// **'No warning level: those are set by the states and are not in this data. Official flood warnings are in the warning list.'**
  String get pegelNoMeldestufe;

  /// No description provided for @pegelSource.
  ///
  /// In en, this message translates to:
  /// **'Source: PEGELONLINE, run by Germany\'s waterways administration. Federal waterways only – the brook that floods a village is not in here.'**
  String get pegelSource;

  /// No description provided for @pegelBandRecordLow.
  ///
  /// In en, this message translates to:
  /// **'Lower than ever measured'**
  String get pegelBandRecordLow;

  /// No description provided for @pegelBandLow.
  ///
  /// In en, this message translates to:
  /// **'Low water'**
  String get pegelBandLow;

  /// No description provided for @pegelBandOrdinary.
  ///
  /// In en, this message translates to:
  /// **'Within the ordinary range'**
  String get pegelBandOrdinary;

  /// No description provided for @pegelBandElevated.
  ///
  /// In en, this message translates to:
  /// **'Above the mean'**
  String get pegelBandElevated;

  /// No description provided for @pegelBandFlood.
  ///
  /// In en, this message translates to:
  /// **'Flood'**
  String get pegelBandFlood;

  /// No description provided for @pegelBandRecordHigh.
  ///
  /// In en, this message translates to:
  /// **'Higher than ever measured'**
  String get pegelBandRecordHigh;

  /// No description provided for @pegelBandUnknown.
  ///
  /// In en, this message translates to:
  /// **'Cannot be placed'**
  String get pegelBandUnknown;

  /// No description provided for @pegelTrendRising.
  ///
  /// In en, this message translates to:
  /// **'Rising, {change} cm in 24 hours'**
  String pegelTrendRising(String change);

  /// No description provided for @pegelTrendFalling.
  ///
  /// In en, this message translates to:
  /// **'Falling, {change} cm in 24 hours'**
  String pegelTrendFalling(String change);

  /// No description provided for @pegelTrendSteady.
  ///
  /// In en, this message translates to:
  /// **'Barely changed in 24 hours'**
  String get pegelTrendSteady;

  /// No description provided for @pegelTrendUnknown.
  ///
  /// In en, this message translates to:
  /// **'History not available'**
  String get pegelTrendUnknown;

  /// No description provided for @pegelRefMean.
  ///
  /// In en, this message translates to:
  /// **'Mean level'**
  String get pegelRefMean;

  /// No description provided for @pegelRefMeanFlood.
  ///
  /// In en, this message translates to:
  /// **'Mean flood level'**
  String get pegelRefMeanFlood;

  /// No description provided for @pegelRefHighest.
  ///
  /// In en, this message translates to:
  /// **'Highest level measured'**
  String get pegelRefHighest;

  /// No description provided for @pegelRefMeanLow.
  ///
  /// In en, this message translates to:
  /// **'Mean low level'**
  String get pegelRefMeanLow;

  /// No description provided for @pegelRefLowest.
  ///
  /// In en, this message translates to:
  /// **'Lowest level measured'**
  String get pegelRefLowest;

  /// No description provided for @warningSeverityMinor.
  ///
  /// In en, this message translates to:
  /// **'Minor'**
  String get warningSeverityMinor;

  /// No description provided for @warningSeverityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get warningSeverityModerate;

  /// No description provided for @warningSeveritySevere.
  ///
  /// In en, this message translates to:
  /// **'Severe'**
  String get warningSeveritySevere;

  /// No description provided for @warningSeverityExtreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get warningSeverityExtreme;

  /// No description provided for @warningBannerMore.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String warningBannerMore(int count);

  /// No description provided for @warningExpiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get warningExpiredLabel;

  /// No description provided for @warningSourceBbk.
  ///
  /// In en, this message translates to:
  /// **'German Federal Office for Civil Protection (BBK)'**
  String get warningSourceBbk;

  /// No description provided for @warningSourceMeteoalarm.
  ///
  /// In en, this message translates to:
  /// **'MeteoAlarm'**
  String get warningSourceMeteoalarm;

  /// No description provided for @exportPdfButton.
  ///
  /// In en, this message translates to:
  /// **'Export missing equipment'**
  String get exportPdfButton;

  /// No description provided for @pdfReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Missing Equipment Report'**
  String get pdfReportTitle;

  /// No description provided for @pdfGeneratedOn.
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String pdfGeneratedOn(String date);

  /// No description provided for @pdfChecklistSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Open checklist items'**
  String get pdfChecklistSectionTitle;

  /// No description provided for @pdfNoMissingChecklistItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing open — every checklist is complete.'**
  String get pdfNoMissingChecklistItems;

  /// No description provided for @pdfInventorySectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Low-stock inventory items'**
  String get pdfInventorySectionTitle;

  /// No description provided for @pdfNoLowStockItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing below its minimum quantity.'**
  String get pdfNoLowStockItems;

  /// No description provided for @pdfColumnItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get pdfColumnItem;

  /// No description provided for @pdfColumnQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get pdfColumnQuantity;

  /// No description provided for @pdfColumnMinQuantity.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get pdfColumnMinQuantity;

  /// No description provided for @pdfColumnUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get pdfColumnUnit;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @languageSystemOption.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystemOption;

  /// No description provided for @languageGermanOption.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGermanOption;

  /// No description provided for @languageEnglishOption.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglishOption;

  /// No description provided for @inventoryAttentionTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} item(s) low on stock or expired'**
  String inventoryAttentionTooltip(int count);

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceTitle;

  /// No description provided for @themeSystemOption.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystemOption;

  /// No description provided for @themeLightOption.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLightOption;

  /// No description provided for @themeDarkOption.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDarkOption;

  /// No description provided for @settingsMyRegionTitle.
  ///
  /// In en, this message translates to:
  /// **'My region'**
  String get settingsMyRegionTitle;

  /// No description provided for @settingsNoRegionSet.
  ///
  /// In en, this message translates to:
  /// **'No region set'**
  String get settingsNoRegionSet;

  /// No description provided for @settingsAdditionalRegionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Additional regions'**
  String get settingsAdditionalRegionsTitle;

  /// No description provided for @settingsNoAdditionalRegions.
  ///
  /// In en, this message translates to:
  /// **'No additional regions added yet.'**
  String get settingsNoAdditionalRegions;

  /// No description provided for @settingsAddRegionButton.
  ///
  /// In en, this message translates to:
  /// **'Add region'**
  String get settingsAddRegionButton;

  /// No description provided for @settingsAddRegionDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add region'**
  String get settingsAddRegionDialogTitle;

  /// No description provided for @settingsRegionTypeKreis.
  ///
  /// In en, this message translates to:
  /// **'District (Kreis)'**
  String get settingsRegionTypeKreis;

  /// No description provided for @settingsRegionTypeBundesland.
  ///
  /// In en, this message translates to:
  /// **'State (Bundesland)'**
  String get settingsRegionTypeBundesland;

  /// No description provided for @settingsKreisSchluesselLabel.
  ///
  /// In en, this message translates to:
  /// **'Kreisschlüssel (5 digits)'**
  String get settingsKreisSchluesselLabel;

  /// No description provided for @settingsKreisSchluesselInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 5-digit Kreisschlüssel.'**
  String get settingsKreisSchluesselInvalid;

  /// No description provided for @settingsKreisSchluesselHelper.
  ///
  /// In en, this message translates to:
  /// **'Five digits, e.g. 03241 for the Hannover region.'**
  String get settingsKreisSchluesselHelper;

  /// No description provided for @settingsBundeslandLabel.
  ///
  /// In en, this message translates to:
  /// **'Federal state'**
  String get settingsBundeslandLabel;

  /// No description provided for @settingsBundeslandRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose a federal state.'**
  String get settingsBundeslandRequired;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsToggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Notify me about new warnings'**
  String get settingsNotificationsToggleLabel;

  /// No description provided for @settingsNotificationsToggleHint.
  ///
  /// In en, this message translates to:
  /// **'Local notifications only, while the app is running — no push server.'**
  String get settingsNotificationsToggleHint;

  /// No description provided for @settingsUseLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Determine state via location'**
  String get settingsUseLocationButton;

  /// No description provided for @settingsLocationNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t match your location to a German state.'**
  String get settingsLocationNoMatchMessage;

  /// No description provided for @shelterMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Shelters'**
  String get shelterMapTitle;

  /// No description provided for @shelterInfoLine.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap and WWBOTA/DLBOTA loaded within {radius} km.'**
  String shelterInfoLine(int radius);

  /// No description provided for @shelterLegendGreenLabel.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get shelterLegendGreenLabel;

  /// No description provided for @shelterLegendGreenDescription.
  ///
  /// In en, this message translates to:
  /// **'officially confirmed as a usable shelter'**
  String get shelterLegendGreenDescription;

  /// No description provided for @shelterLegendYellowLabel.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get shelterLegendYellowLabel;

  /// No description provided for @shelterLegendYellowDescription.
  ///
  /// In en, this message translates to:
  /// **'possible shelter, access/use unconfirmed'**
  String get shelterLegendYellowDescription;

  /// No description provided for @shelterLegendRedLabel.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get shelterLegendRedLabel;

  /// No description provided for @shelterLegendRedDescription.
  ///
  /// In en, this message translates to:
  /// **'not released, historical, or informational only'**
  String get shelterLegendRedDescription;

  /// No description provided for @shelterDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'This map does not replace an official warning, evacuation, or emergency-response instruction.'**
  String get shelterDisclaimer;

  /// No description provided for @shelterNoConfirmedShelters.
  ///
  /// In en, this message translates to:
  /// **'No currently released public shelters are known in Germany in the loaded official data. If that changes, they\'ll appear here in green.'**
  String get shelterNoConfirmedShelters;

  /// No description provided for @shelterFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String shelterFilterAll(int count);

  /// No description provided for @shelterFilterCount.
  ///
  /// In en, this message translates to:
  /// **'{label} {count}'**
  String shelterFilterCount(String label, int count);

  /// No description provided for @shelterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Postal code or place'**
  String get shelterSearchHint;

  /// No description provided for @shelterSearchButton.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get shelterSearchButton;

  /// No description provided for @shelterSearchNoResult.
  ///
  /// In en, this message translates to:
  /// **'No result found.'**
  String get shelterSearchNoResult;

  /// No description provided for @shelterUseLocationButton.
  ///
  /// In en, this message translates to:
  /// **'Investigate current location'**
  String get shelterUseLocationButton;

  /// No description provided for @shelterRefreshButton.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get shelterRefreshButton;

  /// No description provided for @shelterWwbotaErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'WWBOTA/DLBOTA could not be loaded.'**
  String get shelterWwbotaErrorMessage;

  /// No description provided for @shelterOverpassErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap/Overpass could not be loaded.'**
  String get shelterOverpassErrorMessage;

  /// No description provided for @shelterEmptyPrompt.
  ///
  /// In en, this message translates to:
  /// **'No location loaded yet. Use your current location or search for a place.'**
  String get shelterEmptyPrompt;

  /// No description provided for @shelterListHeading.
  ///
  /// In en, this message translates to:
  /// **'Shelters found'**
  String get shelterListHeading;

  /// No description provided for @shelterListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this radius. Try a wider one, or a different place.'**
  String get shelterListEmpty;

  /// No description provided for @shelterDistanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters} m {direction}'**
  String shelterDistanceMeters(int meters, String direction);

  /// No description provided for @shelterDistanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{km} km {direction}'**
  String shelterDistanceKilometers(String km, String direction);

  /// No description provided for @shelterListSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{distance} · {confidence} · {source}'**
  String shelterListSubtitle(String distance, String confidence, String source);

  /// No description provided for @shelterDirectionNorth.
  ///
  /// In en, this message translates to:
  /// **'north'**
  String get shelterDirectionNorth;

  /// No description provided for @shelterDirectionNorthEast.
  ///
  /// In en, this message translates to:
  /// **'north-east'**
  String get shelterDirectionNorthEast;

  /// No description provided for @shelterDirectionEast.
  ///
  /// In en, this message translates to:
  /// **'east'**
  String get shelterDirectionEast;

  /// No description provided for @shelterDirectionSouthEast.
  ///
  /// In en, this message translates to:
  /// **'south-east'**
  String get shelterDirectionSouthEast;

  /// No description provided for @shelterDirectionSouth.
  ///
  /// In en, this message translates to:
  /// **'south'**
  String get shelterDirectionSouth;

  /// No description provided for @shelterDirectionSouthWest.
  ///
  /// In en, this message translates to:
  /// **'south-west'**
  String get shelterDirectionSouthWest;

  /// No description provided for @shelterDirectionWest.
  ///
  /// In en, this message translates to:
  /// **'west'**
  String get shelterDirectionWest;

  /// No description provided for @shelterDirectionNorthWest.
  ///
  /// In en, this message translates to:
  /// **'north-west'**
  String get shelterDirectionNorthWest;

  /// No description provided for @shelterShowOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show {name} on the map'**
  String shelterShowOnMap(String name);

  /// No description provided for @shelterMarkerTooltip.
  ///
  /// In en, this message translates to:
  /// **'{name} · {confidence} · {source}'**
  String shelterMarkerTooltip(String name, String confidence, String source);

  /// No description provided for @shelterAttribution.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors'**
  String get shelterAttribution;

  /// No description provided for @expiryReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Supply expiring soon'**
  String get expiryReminderTitle;

  /// No description provided for @expiryReminderBody.
  ///
  /// In en, this message translates to:
  /// **'{name} expires in {days} days.'**
  String expiryReminderBody(String name, int days);

  /// No description provided for @expiryReminderBodyTomorrow.
  ///
  /// In en, this message translates to:
  /// **'{name} expires tomorrow.'**
  String expiryReminderBodyTomorrow(String name);

  /// No description provided for @settingsExpiryRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Expiry reminders'**
  String get settingsExpiryRemindersTitle;

  /// No description provided for @settingsExpiryRemindersUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Linux has no scheduled notifications — the desktop standard only knows immediate ones. Warnings still arrive.'**
  String get settingsExpiryRemindersUnsupported;

  /// No description provided for @settingsExpiryRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'A reminder before a supply expires. Choose how many days ahead.'**
  String get settingsExpiryRemindersHint;

  /// No description provided for @settingsExpiryRemindersDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications above so reminders can be scheduled.'**
  String get settingsExpiryRemindersDisabledHint;

  /// No description provided for @settingsExpiryRemindersNoneHint.
  ///
  /// In en, this message translates to:
  /// **'No lead time selected — no reminders will be scheduled.'**
  String get settingsExpiryRemindersNoneHint;

  /// No description provided for @settingsScheduledRemindersUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Linux does not support scheduled notifications.'**
  String get settingsScheduledRemindersUnsupported;

  /// No description provided for @settingsChargeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Check batteries and devices'**
  String get settingsChargeReminderTitle;

  /// No description provided for @settingsChargeReminderHint.
  ///
  /// In en, this message translates to:
  /// **'Reminds you to charge and test power banks, rechargeable batteries, torches and emergency radios.'**
  String get settingsChargeReminderHint;

  /// No description provided for @settingsChargeReminderDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on notifications above to schedule the charging reminder.'**
  String get settingsChargeReminderDisabledHint;

  /// No description provided for @settingsChargeReminderNoneHint.
  ///
  /// In en, this message translates to:
  /// **'No charging reminder is scheduled.'**
  String get settingsChargeReminderNoneHint;

  /// No description provided for @settingsChargeReminderCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get settingsChargeReminderCustom;

  /// No description provided for @settingsChargeReminderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Own interval'**
  String get settingsChargeReminderCustomTitle;

  /// No description provided for @settingsChargeReminderCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'Days between checks'**
  String get settingsChargeReminderCustomLabel;

  /// No description provided for @settingsChargeReminderCustomInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number between {min} and {max}.'**
  String settingsChargeReminderCustomInvalid(int min, int max);

  /// No description provided for @settingsChargeReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get settingsChargeReminderOff;

  /// No description provided for @chargeReminderInterval.
  ///
  /// In en, this message translates to:
  /// **'every {days} days'**
  String chargeReminderInterval(int days);

  /// No description provided for @chargeReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Check batteries and devices'**
  String get chargeReminderTitle;

  /// No description provided for @chargeReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Charge and test power banks, rechargeable batteries, torches and emergency radios.'**
  String get chargeReminderBody;

  /// No description provided for @expiryLeadDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String expiryLeadDaysLabel(int days);

  /// No description provided for @expiryLeadDayOneLabel.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get expiryLeadDayOneLabel;

  /// No description provided for @consumeAction.
  ///
  /// In en, this message translates to:
  /// **'Use up'**
  String get consumeAction;

  /// No description provided for @consumeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Use up {name}'**
  String consumeDialogTitle(String name);

  /// No description provided for @consumeDialogAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get consumeDialogAmountLabel;

  /// No description provided for @consumeDialogRemaining.
  ///
  /// In en, this message translates to:
  /// **'In stock: {quantity} {unit}'**
  String consumeDialogRemaining(String quantity, String unit);

  /// No description provided for @consumeDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Deduct'**
  String get consumeDialogConfirm;

  /// No description provided for @consumeDialogAll.
  ///
  /// In en, this message translates to:
  /// **'Used up entirely'**
  String get consumeDialogAll;

  /// No description provided for @consumeInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than 0 and at most the stock on hand.'**
  String get consumeInvalidAmount;

  /// No description provided for @syncAgeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes'**
  String syncAgeMinutes(int count);

  /// No description provided for @syncAgeHours.
  ///
  /// In en, this message translates to:
  /// **'{count} hours'**
  String syncAgeHours(int count);

  /// No description provided for @syncAgeDays.
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String syncAgeDays(int count);

  /// No description provided for @csvExportButton.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get csvExportButton;

  /// No description provided for @csvExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Save supplies as CSV'**
  String get csvExportDialogTitle;

  /// No description provided for @csvExportSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{count} items exported'**
  String csvExportSuccessMessage(int count);

  /// No description provided for @csvExportEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'There are no items to export yet.'**
  String get csvExportEmptyMessage;

  /// No description provided for @csvExportErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'The file could not be written.'**
  String get csvExportErrorMessage;

  /// No description provided for @profileSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your household'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupIntro.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite runs entirely on this device. There is no account and no server — just these details, so warnings and supply targets match your situation.'**
  String get profileSetupIntro;

  /// No description provided for @profileSetupSubmit.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get profileSetupSubmit;

  /// Screen-reader name of the minus button beside a counter.
  ///
  /// In en, this message translates to:
  /// **'One fewer: {label}'**
  String stepperDecrease(String label);

  /// Screen-reader name of the plus button beside a counter.
  ///
  /// In en, this message translates to:
  /// **'One more: {label}'**
  String stepperIncrease(String label);

  /// Spoken form of a counter, so the number is not read on its own.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String stepperValue(String label, int value);

  /// No description provided for @deleteItemAction.
  ///
  /// In en, this message translates to:
  /// **'Delete “{item}”'**
  String deleteItemAction(String item);

  /// No description provided for @mapDownloadSearchAction.
  ///
  /// In en, this message translates to:
  /// **'Search for this place'**
  String get mapDownloadSearchAction;

  /// Banner line, so severity is a word and not only a colour.
  ///
  /// In en, this message translates to:
  /// **'{severity}: {headline}'**
  String warningBannerSeverity(String severity, String headline);

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get shoppingListTitle;

  /// No description provided for @shoppingListTargetHeading.
  ///
  /// In en, this message translates to:
  /// **'Against the target for {days} days'**
  String shoppingListTargetHeading(int days);

  /// No description provided for @shoppingListTargetMet.
  ///
  /// In en, this message translates to:
  /// **'Water and energy are covered for {days} days.'**
  String shoppingListTargetMet(int days);

  /// No description provided for @shoppingListWaterGap.
  ///
  /// In en, this message translates to:
  /// **'{liters} l of water still to buy'**
  String shoppingListWaterGap(String liters);

  /// No description provided for @shoppingListEnergyGap.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal of food still to buy'**
  String shoppingListEnergyGap(String kcal);

  /// No description provided for @shoppingListDaysCovered.
  ///
  /// In en, this message translates to:
  /// **'The stores currently last {covered} of {days} days.'**
  String shoppingListDaysCovered(int covered, int days);

  /// No description provided for @shoppingListDaysUnknown.
  ///
  /// In en, this message translates to:
  /// **'No people in the household, so there is nothing to work out.'**
  String get shoppingListDaysUnknown;

  /// No description provided for @shoppingListItemsHeading.
  ///
  /// In en, this message translates to:
  /// **'Below the minimum'**
  String get shoppingListItemsHeading;

  /// No description provided for @shoppingListItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing is below its minimum.'**
  String get shoppingListItemsEmpty;

  /// No description provided for @shoppingListNoMinimums.
  ///
  /// In en, this message translates to:
  /// **'Only items you gave a minimum quantity appear here. Set one on an item and it will be watched.'**
  String get shoppingListNoMinimums;

  /// No description provided for @shoppingListShortfall.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} short of {minimum}'**
  String shoppingListShortfall(String amount, String unit, String minimum);

  /// No description provided for @shoppingListCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy list'**
  String get shoppingListCopy;

  /// No description provided for @shoppingListCopied.
  ///
  /// In en, this message translates to:
  /// **'Shopping list copied.'**
  String get shoppingListCopied;

  /// No description provided for @rotationTitle.
  ///
  /// In en, this message translates to:
  /// **'Use next'**
  String get rotationTitle;

  /// No description provided for @rotationExpiredHeading.
  ///
  /// In en, this message translates to:
  /// **'Past its date'**
  String get rotationExpiredHeading;

  /// No description provided for @rotationSoonHeading.
  ///
  /// In en, this message translates to:
  /// **'Use soon'**
  String get rotationSoonHeading;

  /// No description provided for @rotationLaterHeading.
  ///
  /// In en, this message translates to:
  /// **'Keeps for now'**
  String get rotationLaterHeading;

  /// No description provided for @rotationExpiredSince.
  ///
  /// In en, this message translates to:
  /// **'{days} days past'**
  String rotationExpiredSince(int days);

  /// No description provided for @rotationExpiresToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get rotationExpiresToday;

  /// No description provided for @rotationDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days} days left'**
  String rotationDaysLeft(int days);

  /// No description provided for @rotationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here to rotate. Only items with a date and something left in them are listed.'**
  String get rotationEmpty;

  /// No description provided for @rotationHint.
  ///
  /// In en, this message translates to:
  /// **'Salt and the like carry no date and are left out on purpose — they would bury the rows that do have one.'**
  String get rotationHint;

  /// No description provided for @consumeScanAction.
  ///
  /// In en, this message translates to:
  /// **'Scan to use'**
  String get consumeScanAction;

  /// No description provided for @consumeScanNotFound.
  ///
  /// In en, this message translates to:
  /// **'No item with barcode {barcode} in this household.'**
  String consumeScanNotFound(String barcode);

  /// No description provided for @sharingErrorLocked.
  ///
  /// In en, this message translates to:
  /// **'This folder is encrypted and this device does not have the passphrase. Nothing is being read or written until you enter it.'**
  String get sharingErrorLocked;

  /// No description provided for @folderEncryptionOff.
  ///
  /// In en, this message translates to:
  /// **'Off. Everything in the folder is readable by anyone who can see it — including your sync provider.'**
  String get folderEncryptionOff;

  /// No description provided for @folderEncryptionOn.
  ///
  /// In en, this message translates to:
  /// **'On. The folder holds only sealed files.'**
  String get folderEncryptionOn;

  /// No description provided for @folderEncryptionEnable.
  ///
  /// In en, this message translates to:
  /// **'Turn on encryption'**
  String get folderEncryptionEnable;

  /// No description provided for @folderEncryptionUnlock.
  ///
  /// In en, this message translates to:
  /// **'Enter passphrase'**
  String get folderEncryptionUnlock;

  /// No description provided for @folderEncryptionPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Passphrase'**
  String get folderEncryptionPassphrase;

  /// No description provided for @folderEncryptionRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat passphrase'**
  String get folderEncryptionRepeat;

  /// No description provided for @folderEncryptionMismatch.
  ///
  /// In en, this message translates to:
  /// **'The two entries are not the same.'**
  String get folderEncryptionMismatch;

  /// No description provided for @folderEncryptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters. This is the only thing standing between the folder and whoever can read it.'**
  String folderEncryptionTooShort(int count);

  /// No description provided for @folderEncryptionWrong.
  ///
  /// In en, this message translates to:
  /// **'That passphrase does not open this folder.'**
  String get folderEncryptionWrong;

  /// No description provided for @folderEncryptionNoRecovery.
  ///
  /// In en, this message translates to:
  /// **'There is no way back in without it. PreppSuite cannot reset it, and neither can anyone else — write it down somewhere safe before you continue.'**
  String get folderEncryptionNoRecovery;

  /// No description provided for @folderEncryptionOtherDevices.
  ///
  /// In en, this message translates to:
  /// **'Every other device in this household has to be updated and given the same passphrase. Until it is, it stops seeing new rows.'**
  String get folderEncryptionOtherDevices;

  /// No description provided for @folderEncryptionEnabled.
  ///
  /// In en, this message translates to:
  /// **'The shared folder is now encrypted.'**
  String get folderEncryptionEnabled;

  /// No description provided for @folderEncryptionUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Folder unlocked.'**
  String get folderEncryptionUnlocked;

  /// No description provided for @householdPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency plan'**
  String get householdPlanTitle;

  /// No description provided for @householdPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'Agreed before it is needed. Everyone in the household should know these by heart, so write down only what you would actually say out loud.'**
  String get householdPlanIntro;

  /// No description provided for @householdPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing agreed yet.'**
  String get householdPlanEmpty;

  /// No description provided for @householdPlanMeetingNear.
  ///
  /// In en, this message translates to:
  /// **'Meeting point nearby'**
  String get householdPlanMeetingNear;

  /// No description provided for @householdPlanMeetingNearHint.
  ///
  /// In en, this message translates to:
  /// **'Reachable on foot, without a plan — the corner, the neighbour\'s drive.'**
  String get householdPlanMeetingNearHint;

  /// No description provided for @householdPlanMeetingFar.
  ///
  /// In en, this message translates to:
  /// **'Meeting point further out'**
  String get householdPlanMeetingFar;

  /// No description provided for @householdPlanMeetingFarHint.
  ///
  /// In en, this message translates to:
  /// **'For when the whole area is cleared and the near one cannot be reached.'**
  String get householdPlanMeetingFarHint;

  /// No description provided for @householdPlanContactName.
  ///
  /// In en, this message translates to:
  /// **'Out-of-area contact'**
  String get householdPlanContactName;

  /// No description provided for @householdPlanContactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Someone outside the region everyone rings. Local lines are the first to congest; a call to the next county often gets through when one across the street does not.'**
  String get householdPlanContactNameHint;

  /// No description provided for @householdPlanContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Their number'**
  String get householdPlanContactPhone;

  /// No description provided for @householdPlanKitLocation.
  ///
  /// In en, this message translates to:
  /// **'Where the emergency luggage is'**
  String get householdPlanKitLocation;

  /// No description provided for @householdPlanKitLocationHint.
  ///
  /// In en, this message translates to:
  /// **'So nobody searches for it in the dark.'**
  String get householdPlanKitLocationHint;

  /// No description provided for @householdPlanShutoff.
  ///
  /// In en, this message translates to:
  /// **'Where water, gas and power are shut off'**
  String get householdPlanShutoff;

  /// No description provided for @householdPlanContactPoint.
  ///
  /// In en, this message translates to:
  /// **'The municipality\'s contact point'**
  String get householdPlanContactPoint;

  /// No description provided for @householdPlanContactPointHint.
  ///
  /// In en, this message translates to:
  /// **'The building on emergency power that opens when the power has been out for a long time – it gives information, and an emergency call can be handed over there when no phone works. Its name changes with the state; the municipality knows where the nearest one is. Not a meeting point – this is where you go for help, not to find each other.'**
  String get householdPlanContactPointHint;

  /// No description provided for @householdPlanNotes.
  ///
  /// In en, this message translates to:
  /// **'Anything else'**
  String get householdPlanNotes;

  /// No description provided for @householdPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Plan saved.'**
  String get householdPlanSaved;

  /// No description provided for @householdPlanCleared.
  ///
  /// In en, this message translates to:
  /// **'Plan removed.'**
  String get householdPlanCleared;

  /// No description provided for @householdPlanClear.
  ///
  /// In en, this message translates to:
  /// **'Remove plan'**
  String get householdPlanClear;

  /// No description provided for @householdPlanClearConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the plan for every device in this household?'**
  String get householdPlanClearConfirm;

  /// No description provided for @householdPlanShared.
  ///
  /// In en, this message translates to:
  /// **'This plan reaches every device in the household through the shared folder.'**
  String get householdPlanShared;

  /// No description provided for @householdPlanNothingEntered.
  ///
  /// In en, this message translates to:
  /// **'Write down at least one thing before saving.'**
  String get householdPlanNothingEntered;

  /// No description provided for @drillsEmergencyMode.
  ///
  /// In en, this message translates to:
  /// **'Emergency mode'**
  String get drillsEmergencyMode;

  /// No description provided for @drillsCallEmergency.
  ///
  /// In en, this message translates to:
  /// **'Call 112'**
  String get drillsCallEmergency;

  /// No description provided for @drillsHarmless.
  ///
  /// In en, this message translates to:
  /// **'A drill changes no supplies and sends no messages.'**
  String get drillsHarmless;

  /// No description provided for @drillsReset.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get drillsReset;

  /// No description provided for @drillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency mode and drills'**
  String get drillsTitle;

  /// No description provided for @drillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A card to work through, and realistic household drills'**
  String get drillsSubtitle;

  /// No description provided for @drillsImmediateDanger.
  ///
  /// In en, this message translates to:
  /// **'In immediate danger, call 112 first. Then check the official warnings, tell your family what the household plan says, and save power.'**
  String get drillsImmediateDanger;

  /// No description provided for @drillsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Drill mode'**
  String get drillsSectionTitle;

  /// No description provided for @emergencyCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency cards'**
  String get emergencyCardsTitle;

  /// No description provided for @emergencyCardsIntro.
  ///
  /// In en, this message translates to:
  /// **'What an ambulance would want to know, for each person in the household. Only the name is needed — a card that says nothing but a name and an allergy is worth having.'**
  String get emergencyCardsIntro;

  /// No description provided for @emergencyCardsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No cards yet.'**
  String get emergencyCardsEmpty;

  /// No description provided for @emergencyCardsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String emergencyCardsCount(int count);

  /// No description provided for @emergencyCardAdd.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get emergencyCardAdd;

  /// No description provided for @emergencyCardEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get emergencyCardEdit;

  /// No description provided for @emergencyCardName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emergencyCardName;

  /// No description provided for @emergencyCardBirthYear.
  ///
  /// In en, this message translates to:
  /// **'Year of birth'**
  String get emergencyCardBirthYear;

  /// No description provided for @emergencyCardBirthYearHint.
  ///
  /// In en, this message translates to:
  /// **'The year only. A paramedic needs roughly who they are treating, not a birthday.'**
  String get emergencyCardBirthYearHint;

  /// No description provided for @emergencyCardBloodType.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get emergencyCardBloodType;

  /// No description provided for @emergencyCardAllergies.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get emergencyCardAllergies;

  /// No description provided for @emergencyCardMedication.
  ///
  /// In en, this message translates to:
  /// **'Regular medication'**
  String get emergencyCardMedication;

  /// No description provided for @emergencyCardMedicationHint.
  ///
  /// In en, this message translates to:
  /// **'The thing to keep in the stores, and the thing nobody should have to guess at.'**
  String get emergencyCardMedicationHint;

  /// No description provided for @emergencyCardConditions.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get emergencyCardConditions;

  /// No description provided for @emergencyCardInsurance.
  ///
  /// In en, this message translates to:
  /// **'Health insurance'**
  String get emergencyCardInsurance;

  /// No description provided for @emergencyCardDoctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get emergencyCardDoctor;

  /// No description provided for @emergencyCardContact.
  ///
  /// In en, this message translates to:
  /// **'Who to call about this person'**
  String get emergencyCardContact;

  /// No description provided for @emergencyCardNotes.
  ///
  /// In en, this message translates to:
  /// **'Anything else'**
  String get emergencyCardNotes;

  /// No description provided for @emergencyCardNameRequired.
  ///
  /// In en, this message translates to:
  /// **'A card needs a name.'**
  String get emergencyCardNameRequired;

  /// No description provided for @emergencyCardRemoved.
  ///
  /// In en, this message translates to:
  /// **'Card removed.'**
  String get emergencyCardRemoved;

  /// No description provided for @emergencyCardRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove the card for {name} from every device in this household?'**
  String emergencyCardRemoveConfirm(String name);

  /// No description provided for @emergencyCardsHealthWarning.
  ///
  /// In en, this message translates to:
  /// **'This is health data, and it travels through the shared folder to every device. Encrypt the folder before you put it in.'**
  String get emergencyCardsHealthWarning;

  /// No description provided for @emergencyCardsHealthEncrypted.
  ///
  /// In en, this message translates to:
  /// **'This is health data. The shared folder it travels through is encrypted.'**
  String get emergencyCardsHealthEncrypted;

  /// No description provided for @emergencyCardBirthYearInvalid.
  ///
  /// In en, this message translates to:
  /// **'That is not a year.'**
  String get emergencyCardBirthYearInvalid;

  /// No description provided for @settingsSharingTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared folder'**
  String get settingsSharingTitle;

  /// No description provided for @sharingIntro.
  ///
  /// In en, this message translates to:
  /// **'Supplies, checklists and spending live in a folder several devices can see — a Nextcloud, Syncthing, iCloud Drive or Dropbox directory. PreppSuite only writes files there. What carries them is your choice.'**
  String get sharingIntro;

  /// No description provided for @sharingInactive.
  ///
  /// In en, this message translates to:
  /// **'This device shares nothing. Everything stays here.'**
  String get sharingInactive;

  /// No description provided for @sharingActiveFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder: {path}'**
  String sharingActiveFolder(String path);

  /// No description provided for @sharingChooseFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get sharingChooseFolderAction;

  /// No description provided for @sharingChangeFolderAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a different folder'**
  String get sharingChangeFolderAction;

  /// No description provided for @sharingLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get sharingLeaveAction;

  /// No description provided for @sharingSyncNowAction.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get sharingSyncNowAction;

  /// No description provided for @sharingSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing …'**
  String get sharingSyncing;

  /// No description provided for @sharingNeverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced yet.'**
  String get sharingNeverSynced;

  /// No description provided for @sharingLastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced {age} ago.'**
  String sharingLastSynced(String age);

  /// No description provided for @sharingDeviceCount.
  ///
  /// In en, this message translates to:
  /// **'{count} devices share this folder.'**
  String sharingDeviceCount(int count);

  /// No description provided for @sharingDeviceCountOne.
  ///
  /// In en, this message translates to:
  /// **'Only this device uses the folder so far.'**
  String get sharingDeviceCountOne;

  /// No description provided for @sharingReceived.
  ///
  /// In en, this message translates to:
  /// **'Took {count} entries from other devices.'**
  String sharingReceived(int count);

  /// No description provided for @sharingUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Everything is up to date.'**
  String get sharingUpToDate;

  /// No description provided for @sharingErrorUnwritable.
  ///
  /// In en, this message translates to:
  /// **'This folder cannot be written to. On Android the permission is lost on reinstall and can be revoked in the system settings — just pick the folder again. Otherwise check that it is still there and writable.'**
  String get sharingErrorUnwritable;

  /// No description provided for @sharingErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'There is already a household in this folder, and it cannot be read. It probably comes from a newer version of PreppSuite.'**
  String get sharingErrorUnreadable;

  /// No description provided for @sharingErrorVersion.
  ///
  /// In en, this message translates to:
  /// **'The files in this folder come from a newer version. Nothing was changed.'**
  String get sharingErrorVersion;

  /// No description provided for @sharingErrorFailed.
  ///
  /// In en, this message translates to:
  /// **'The sync failed. The next attempt runs on its own.'**
  String get sharingErrorFailed;

  /// No description provided for @sharingJoinedOther.
  ///
  /// In en, this message translates to:
  /// **'This device now belongs to the household “{name}”. Its existing entries came along.'**
  String sharingJoinedOther(String name);

  /// No description provided for @sharingLeaveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing?'**
  String get sharingLeaveDialogTitle;

  /// No description provided for @sharingLeaveDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This device will stop syncing. Nothing is deleted — not here and not in the folder.'**
  String get sharingLeaveDialogBody;

  /// No description provided for @sharingLeaveDialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get sharingLeaveDialogConfirm;

  /// No description provided for @sharingErrorDifferentHousehold.
  ///
  /// In en, this message translates to:
  /// **'This folder belongs to a different household. Nothing was merged — two unrelated sets of data cannot be pulled apart again.'**
  String get sharingErrorDifferentHousehold;

  /// No description provided for @mapAttributionOffline.
  ///
  /// In en, this message translates to:
  /// **'© OpenStreetMap contributors · © OpenMapTiles'**
  String get mapAttributionOffline;

  /// No description provided for @settingsOfflineMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline map'**
  String get settingsOfflineMapTitle;

  /// No description provided for @offlineMapIntro.
  ///
  /// In en, this message translates to:
  /// **'Without a map of your own the app fetches tiles from OpenStreetMap, so it needs a connection. A PMTiles file on the device replaces that entirely.'**
  String get offlineMapIntro;

  /// No description provided for @offlineMapInactive.
  ///
  /// In en, this message translates to:
  /// **'No map chosen. Tiles come from the network.'**
  String get offlineMapInactive;

  /// No description provided for @offlineMapActive.
  ///
  /// In en, this message translates to:
  /// **'{name}'**
  String offlineMapActive(String name);

  /// No description provided for @offlineMapZoomRange.
  ///
  /// In en, this message translates to:
  /// **'Zoom levels {min} to {max}.'**
  String offlineMapZoomRange(int min, int max);

  /// No description provided for @offlineMapChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a map'**
  String get offlineMapChooseAction;

  /// No description provided for @offlineMapChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a different map'**
  String get offlineMapChangeAction;

  /// No description provided for @offlineMapForgetAction.
  ///
  /// In en, this message translates to:
  /// **'Back online'**
  String get offlineMapForgetAction;

  /// No description provided for @offlineMapErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file cannot be read. A PMTiles version 3 archive is expected.'**
  String get offlineMapErrorUnreadable;

  /// No description provided for @offlineMapErrorNotVector.
  ///
  /// In en, this message translates to:
  /// **'The archive holds finished image tiles rather than vector data. PreppSuite draws the map itself and needs vector tiles.'**
  String get offlineMapErrorNotVector;

  /// No description provided for @offlineMapErrorSchema.
  ///
  /// In en, this message translates to:
  /// **'The archive uses a different schema than the built-in map style. An OpenMapTiles-schema archive is needed — see docs/karte-offline.md.'**
  String get offlineMapErrorSchema;

  /// No description provided for @navKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get navKnowledge;

  /// No description provided for @knowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge'**
  String get knowledgeTitle;

  /// No description provided for @knowledgeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No knowledge file yet'**
  String get knowledgeEmptyTitle;

  /// No description provided for @knowledgeEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'A ZIM file on the device — Kiwix\'s Wikipedia, for instance — makes looking things up independent of the network. Where to get one is in docs/wissen-offline.md.'**
  String get knowledgeEmptyBody;

  /// No description provided for @knowledgeChooseAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get knowledgeChooseAction;

  /// No description provided for @knowledgeChangeAction.
  ///
  /// In en, this message translates to:
  /// **'Choose a different file'**
  String get knowledgeChangeAction;

  /// No description provided for @articleLinkLeavesArchive.
  ///
  /// In en, this message translates to:
  /// **'That link points outside the archive. PreppSuite only shows what is in the file.'**
  String get articleLinkLeavesArchive;

  /// No description provided for @knowledgeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search titles'**
  String get knowledgeSearchHint;

  /// No description provided for @knowledgeSearchNote.
  ///
  /// In en, this message translates to:
  /// **'Searches titles, not the text of the articles.'**
  String get knowledgeSearchNote;

  /// No description provided for @knowledgeNoResults.
  ///
  /// In en, this message translates to:
  /// **'No title starts with “{query}”.'**
  String knowledgeNoResults(String query);

  /// No description provided for @knowledgeSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Where to start'**
  String get knowledgeSuggestionsTitle;

  /// No description provided for @knowledgeSuggestionsBody.
  ///
  /// In en, this message translates to:
  /// **'You can keep several archives side by side and switch with one tap. The files stay where they are.'**
  String get knowledgeSuggestionsBody;

  /// No description provided for @knowledgeSuggestionWikibooks.
  ///
  /// In en, this message translates to:
  /// **'Textbooks, including a full secondary-school maths course.'**
  String get knowledgeSuggestionWikibooks;

  /// No description provided for @knowledgeSuggestionKlexikon.
  ///
  /// In en, this message translates to:
  /// **'An encyclopedia written for primary-school children.'**
  String get knowledgeSuggestionKlexikon;

  /// No description provided for @knowledgeSuggestionPhet.
  ///
  /// In en, this message translates to:
  /// **'Interactive physics, chemistry and maths experiments.'**
  String get knowledgeSuggestionPhet;

  /// No description provided for @knowledgeSuggestionWikiversity.
  ///
  /// In en, this message translates to:
  /// **'Course and teaching material.'**
  String get knowledgeSuggestionWikiversity;

  /// No description provided for @knowledgeSuggestionWikipedia.
  ///
  /// In en, this message translates to:
  /// **'Everything else. The largest of these by far.'**
  String get knowledgeSuggestionWikipedia;

  /// No description provided for @knowledgeSuggestionMedicine.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia\'s medical articles alone, at a fraction of the size.'**
  String get knowledgeSuggestionMedicine;

  /// No description provided for @knowledgeSuggestionIfixit.
  ///
  /// In en, this message translates to:
  /// **'Repair instructions for appliances and electronics, with pictures.'**
  String get knowledgeSuggestionIfixit;

  /// No description provided for @knowledgeSuggestionKhan.
  ///
  /// In en, this message translates to:
  /// **'The school curriculum end to end — English only, no German archive exists.'**
  String get knowledgeSuggestionKhan;

  /// No description provided for @knowledgeAddAction.
  ///
  /// In en, this message translates to:
  /// **'Add another archive'**
  String get knowledgeAddAction;

  /// No description provided for @knowledgeRemoveAction.
  ///
  /// In en, this message translates to:
  /// **'Remove this archive'**
  String get knowledgeRemoveAction;

  /// No description provided for @knowledgeSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} cannot be opened. The file may have moved.'**
  String knowledgeSwitchFailed(String name);

  /// No description provided for @knowledgeErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'The file cannot be read. A ZIM archive is expected, of the kind Kiwix publishes.'**
  String get knowledgeErrorUnreadable;

  /// No description provided for @knowledgeArticleUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Articles cannot be shown on this platform — the browser component is missing. Searching works, reading does not.'**
  String get knowledgeArticleUnsupported;

  /// No description provided for @knowledgeArticleNoEngine.
  ///
  /// In en, this message translates to:
  /// **'The system\'s browser component is missing. On Linux that is WebKitGTK (package libwebkit2gtk-4.1), on Windows the WebView2 runtime.'**
  String get knowledgeArticleNoEngine;

  /// No description provided for @knowledgeSource.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String knowledgeSource(String name);

  /// No description provided for @knowledgeModeTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get knowledgeModeTitles;

  /// No description provided for @knowledgeModeFullText.
  ///
  /// In en, this message translates to:
  /// **'Full text'**
  String get knowledgeModeFullText;

  /// No description provided for @knowledgeFullTextNote.
  ///
  /// In en, this message translates to:
  /// **'Searches the text of the articles.'**
  String get knowledgeFullTextNote;

  /// No description provided for @knowledgeIndexMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'No full-text index'**
  String get knowledgeIndexMissingTitle;

  /// No description provided for @knowledgeIndexMissingBody.
  ///
  /// In en, this message translates to:
  /// **'Searching the text needs an index. The app builds it once — after that it answers instantly.'**
  String get knowledgeIndexMissingBody;

  /// No description provided for @knowledgeIndexCountAction.
  ///
  /// In en, this message translates to:
  /// **'Count articles'**
  String get knowledgeIndexCountAction;

  /// No description provided for @knowledgeIndexBuildAction.
  ///
  /// In en, this message translates to:
  /// **'Build index'**
  String get knowledgeIndexBuildAction;

  /// No description provided for @knowledgeIndexContinueAction.
  ///
  /// In en, this message translates to:
  /// **'Keep building'**
  String get knowledgeIndexContinueAction;

  /// No description provided for @knowledgeIndexCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get knowledgeIndexCancelAction;

  /// No description provided for @knowledgeIndexDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard index'**
  String get knowledgeIndexDiscardAction;

  /// No description provided for @knowledgeIndexArticles.
  ///
  /// In en, this message translates to:
  /// **'{count} articles in this file.'**
  String knowledgeIndexArticles(int count);

  /// No description provided for @knowledgeIndexLargeWarning.
  ///
  /// In en, this message translates to:
  /// **'That is a lot. Expect an hour or more and several gigabytes on disk. You can stop at any time and keep what was done.'**
  String get knowledgeIndexLargeWarning;

  /// No description provided for @knowledgeIndexScanning.
  ///
  /// In en, this message translates to:
  /// **'Counting articles: {done} of {total}.'**
  String knowledgeIndexScanning(int done, int total);

  /// No description provided for @knowledgeIndexIndexing.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} articles.'**
  String knowledgeIndexIndexing(int done, int total);

  /// No description provided for @knowledgeIndexPartial.
  ///
  /// In en, this message translates to:
  /// **'Stopped at {done} of {total} articles. Searches what is already in there.'**
  String knowledgeIndexPartial(int done, int total);

  /// No description provided for @knowledgeIndexReady.
  ///
  /// In en, this message translates to:
  /// **'{count} articles indexed.'**
  String knowledgeIndexReady(int count);

  /// No description provided for @knowledgeIndexBuiltInTitle.
  ///
  /// In en, this message translates to:
  /// **'The archive brings its own index'**
  String get knowledgeIndexBuiltInTitle;

  /// No description provided for @knowledgeIndexBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'{count} articles, searchable right away. The archive carries its own full-text index, so there is nothing to build.'**
  String knowledgeIndexBuiltIn(int count);

  /// No description provided for @knowledgeIndexBuiltInStemming.
  ///
  /// In en, this message translates to:
  /// **'Queries match word stems: \"supplies\" also finds \"supply\".'**
  String get knowledgeIndexBuiltInStemming;

  /// No description provided for @downloadFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Download folder'**
  String get downloadFolderTitle;

  /// No description provided for @downloadFolderChange.
  ///
  /// In en, this message translates to:
  /// **'Choose folder'**
  String get downloadFolderChange;

  /// No description provided for @downloadFolderReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get downloadFolderReset;

  /// No description provided for @downloadRunningLabel.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}'**
  String downloadRunningLabel(String name);

  /// No description provided for @downloadCancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get downloadCancelAction;

  /// No description provided for @downloadFailedLabel.
  ///
  /// In en, this message translates to:
  /// **'Download stopped: {error}'**
  String downloadFailedLabel(String error);

  /// No description provided for @downloadFinishedLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} has finished downloading.'**
  String downloadFinishedLabel(String name);

  /// No description provided for @downloadNotOpenedLabel.
  ///
  /// In en, this message translates to:
  /// **'{name} has downloaded, but cannot be opened: {reason}'**
  String downloadNotOpenedLabel(String name, String reason);

  /// No description provided for @downloadRetryAction.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get downloadRetryAction;

  /// No description provided for @downloadDismissAction.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get downloadDismissAction;

  /// No description provided for @downloadOfSize.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String downloadOfSize(String done, String total);

  /// No description provided for @progressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String progressPercent(int percent);

  /// No description provided for @downloadBusyMessage.
  ///
  /// In en, this message translates to:
  /// **'A download is already running. Only one goes at a time.'**
  String get downloadBusyMessage;

  /// No description provided for @downloadStartAction.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadStartAction;

  /// No description provided for @downloadConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Download?'**
  String get downloadConfirmTitle;

  /// No description provided for @downloadConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'{name} is {size} and will be saved to {folder}. It keeps going while the app stays open, and can be resumed later.'**
  String downloadConfirmBody(String name, String size, String folder);

  /// No description provided for @knowledgeDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download an archive'**
  String get knowledgeDownloadAction;

  /// No description provided for @kiwixTitle.
  ///
  /// In en, this message translates to:
  /// **'Kiwix library'**
  String get kiwixTitle;

  /// No description provided for @kiwixIntro.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia and other collections as a ZIM file, free and without an account. Pick a language and download what you want offline.'**
  String get kiwixIntro;

  /// No description provided for @kiwixLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get kiwixLanguageLabel;

  /// No description provided for @kiwixSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search collections'**
  String get kiwixSearchHint;

  /// No description provided for @kiwixNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Another language, or another search term?'**
  String get kiwixNoResults;

  /// No description provided for @kiwixLoadError.
  ///
  /// In en, this message translates to:
  /// **'The library could not be reached: {error}'**
  String kiwixLoadError(String error);

  /// No description provided for @kiwixArticleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} articles'**
  String kiwixArticleCount(String count);

  /// No description provided for @kiwixFullTextTag.
  ///
  /// In en, this message translates to:
  /// **'full-text index'**
  String get kiwixFullTextTag;

  /// No description provided for @kiwixFlavourMaxi.
  ///
  /// In en, this message translates to:
  /// **'complete'**
  String get kiwixFlavourMaxi;

  /// No description provided for @kiwixFlavourMini.
  ///
  /// In en, this message translates to:
  /// **'introductions only'**
  String get kiwixFlavourMini;

  /// No description provided for @kiwixFlavourNopic.
  ///
  /// In en, this message translates to:
  /// **'without pictures'**
  String get kiwixFlavourNopic;

  /// No description provided for @kiwixResultCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total}'**
  String kiwixResultCount(String shown, String total);

  /// No description provided for @kiwixLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get kiwixLoadMore;

  /// No description provided for @mapDownloadAction.
  ///
  /// In en, this message translates to:
  /// **'Download a map'**
  String get mapDownloadAction;

  /// No description provided for @mapDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Download map area'**
  String get mapDownloadTitle;

  /// No description provided for @mapDownloadZoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get mapDownloadZoomLabel;

  /// No description provided for @mapDownloadZoomHint.
  ///
  /// In en, this message translates to:
  /// **'Level 12 shows towns and main roads, level 14 individual streets and buildings.'**
  String get mapDownloadZoomHint;

  /// No description provided for @mapDownloadTileCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tiles, roughly {size}'**
  String mapDownloadTileCount(String count, String size);

  /// No description provided for @mapDownloadTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{count} tiles is too many. Shrink the area or the detail level.'**
  String mapDownloadTooLarge(String count);

  /// No description provided for @mapDownloadRunning.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tiles, {size} downloaded'**
  String mapDownloadRunning(String done, String total, String size);

  /// No description provided for @mapDownloadFinished.
  ///
  /// In en, this message translates to:
  /// **'The map is ready and now in use.'**
  String get mapDownloadFinished;

  /// No description provided for @mapDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'The download failed: {error}'**
  String mapDownloadFailed(String error);

  /// No description provided for @mapDownloadSourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Map source'**
  String get mapDownloadSourceLabel;

  /// No description provided for @mapDownloadSourceOpenFreeMap.
  ///
  /// In en, this message translates to:
  /// **'OpenFreeMap (free, no key)'**
  String get mapDownloadSourceOpenFreeMap;

  /// No description provided for @mapDownloadSourceMapTiler.
  ///
  /// In en, this message translates to:
  /// **'MapTiler (needs an account and a key)'**
  String get mapDownloadSourceMapTiler;

  /// No description provided for @mapDownloadApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API key'**
  String get mapDownloadApiKeyLabel;

  /// No description provided for @mapDownloadApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'From your MapTiler account. Stays on this device.'**
  String get mapDownloadApiKeyHint;

  /// No description provided for @mapDownloadPolite.
  ///
  /// In en, this message translates to:
  /// **'The tiles come from a public server other people use too. Take no more than you need.'**
  String get mapDownloadPolite;

  /// No description provided for @mapDownloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Own area, level {zoom}'**
  String mapDownloadLabel(String zoom);

  /// No description provided for @mapDownloadSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Town, district, state or country'**
  String get mapDownloadSearchHint;

  /// No description provided for @mapDownloadSearchNoResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Another name?'**
  String get mapDownloadSearchNoResults;

  /// No description provided for @mapDownloadSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'The place search could not be reached: {error}'**
  String mapDownloadSearchFailed(String error);

  /// No description provided for @mapDownloadAreaViewport.
  ///
  /// In en, this message translates to:
  /// **'Visible area'**
  String get mapDownloadAreaViewport;

  /// No description provided for @mapDownloadAreaPlace.
  ///
  /// In en, this message translates to:
  /// **'{name} · {kind}'**
  String mapDownloadAreaPlace(String name, String kind);

  /// No description provided for @mapDownloadDetailAuto.
  ///
  /// In en, this message translates to:
  /// **'The deepest level this area still fits at.'**
  String get mapDownloadDetailAuto;

  /// No description provided for @mapDownloadDeepestPossible.
  ///
  /// In en, this message translates to:
  /// **'At level 14 that would be {count} tiles — too many. Level {level} is the deepest this area goes.'**
  String mapDownloadDeepestPossible(String count, String level);

  /// No description provided for @mapDownloadScopePlace.
  ///
  /// In en, this message translates to:
  /// **'This place only'**
  String get mapDownloadScopePlace;

  /// No description provided for @mapDownloadScopeRegion.
  ///
  /// In en, this message translates to:
  /// **'With the state'**
  String get mapDownloadScopeRegion;

  /// No description provided for @mapDownloadScopeCountry.
  ///
  /// In en, this message translates to:
  /// **'Whole country'**
  String get mapDownloadScopeCountry;

  /// Label for the whole-planet base band of a map download
  ///
  /// In en, this message translates to:
  /// **'World'**
  String get mapDownloadWorldBase;

  /// Download scope covering the continent the place sits in
  ///
  /// In en, this message translates to:
  /// **'Whole continent'**
  String get mapDownloadScopeContinent;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'Europe'**
  String get mapContinentEurope;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'Africa'**
  String get mapContinentAfrica;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'Asia'**
  String get mapContinentAsia;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'North America'**
  String get mapContinentNorthAmerica;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'South America'**
  String get mapContinentSouthAmerica;

  /// Continent name
  ///
  /// In en, this message translates to:
  /// **'Oceania'**
  String get mapContinentOceania;

  /// No description provided for @mapDownloadStaggered.
  ///
  /// In en, this message translates to:
  /// **'Staggered: coarser further out, full detail in the middle.'**
  String get mapDownloadStaggered;

  /// No description provided for @mapDownloadStep.
  ///
  /// In en, this message translates to:
  /// **'{label}: level {from} to {to}, {count} tiles'**
  String mapDownloadStep(String label, String from, String to, String count);

  /// No description provided for @mapDownloadNoPlan.
  ///
  /// In en, this message translates to:
  /// **'Even staggered this does not fit. Choose somewhere smaller.'**
  String get mapDownloadNoPlan;

  /// No description provided for @mapDownloadEstimatedTime.
  ///
  /// In en, this message translates to:
  /// **'Takes roughly {minutes} minutes.'**
  String mapDownloadEstimatedTime(String minutes);

  /// No description provided for @mapDownloadResolving.
  ///
  /// In en, this message translates to:
  /// **'Working out the surroundings …'**
  String get mapDownloadResolving;

  /// No description provided for @mapDownloadUnfinishedTitle.
  ///
  /// In en, this message translates to:
  /// **'Unfinished download'**
  String get mapDownloadUnfinishedTitle;

  /// No description provided for @mapDownloadUnfinishedBody.
  ///
  /// In en, this message translates to:
  /// **'{label} — {done} of {total} tiles are already here.'**
  String mapDownloadUnfinishedBody(String label, String done, String total);

  /// No description provided for @mapDownloadResumeAction.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get mapDownloadResumeAction;

  /// No description provided for @mapDownloadDiscardAction.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get mapDownloadDiscardAction;

  /// No description provided for @settingsLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are switched off. Turn them on in the system settings.'**
  String get settingsLocationServicesOff;

  /// No description provided for @settingsLocationDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is denied for PreppSuite. The system will not ask again — allow it in the system settings.'**
  String get settingsLocationDeniedForever;

  /// No description provided for @settingsLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'This needs access to your location. Pick the federal state from the list instead.'**
  String get settingsLocationDenied;

  /// No description provided for @settingsLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Location is not available on this device: {detail}'**
  String settingsLocationUnavailable(String detail);

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @mapMyLocationAction.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocationAction;

  /// No description provided for @mapSourceOffline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get mapSourceOffline;

  /// No description provided for @mapSourceOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get mapSourceOnline;

  /// No description provided for @mapSourceOfflineDetail.
  ///
  /// In en, this message translates to:
  /// **'Drawing from {name}, zoom {min} to {max}.'**
  String mapSourceOfflineDetail(String name, int min, int max);

  /// No description provided for @mapSourceOnlineDetail.
  ///
  /// In en, this message translates to:
  /// **'Drawing tiles from OpenStreetMap. Needs a connection.'**
  String get mapSourceOnlineDetail;

  /// No description provided for @mapSourceNoArchive.
  ///
  /// In en, this message translates to:
  /// **'No map on this device yet. Until one is downloaded, the tiles come from OpenStreetMap and need a connection.'**
  String get mapSourceNoArchive;

  /// No description provided for @mapZoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get mapZoomIn;

  /// No description provided for @mapZoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get mapZoomOut;

  /// No description provided for @supplyCalculatorHouseholdLine.
  ///
  /// In en, this message translates to:
  /// **'{who} — from the household'**
  String supplyCalculatorHouseholdLine(String who);

  /// No description provided for @supplyCalculatorAdults.
  ///
  /// In en, this message translates to:
  /// **'{count} adults'**
  String supplyCalculatorAdults(String count);

  /// No description provided for @supplyCalculatorChildren.
  ///
  /// In en, this message translates to:
  /// **'{count} children'**
  String supplyCalculatorChildren(String count);

  /// No description provided for @supplyCalculatorDogs.
  ///
  /// In en, this message translates to:
  /// **'{count} dogs'**
  String supplyCalculatorDogs(String count);

  /// No description provided for @supplyCalculatorCats.
  ///
  /// In en, this message translates to:
  /// **'{count} cats'**
  String supplyCalculatorCats(String count);

  /// No description provided for @supplyCalculatorPetFoodNote.
  ///
  /// In en, this message translates to:
  /// **'Pet food is not counted in the calories — dogs and cats need a supply of their own. Their drinking water is included.'**
  String get supplyCalculatorPetFoodNote;

  /// No description provided for @supplyCalculatorSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the numbers come from'**
  String get supplyCalculatorSourceTitle;

  /// No description provided for @supplyCalculatorSourceBody.
  ///
  /// In en, this message translates to:
  /// **'For adults the BBK states 1.5 litres of fluid a day plus 0.5 litres for cooking, and around 2200 kcal. For children the BBK itself states nothing, but points at the Federal Office for Agriculture and Food, whose stockpiling table says it in a footnote: children up to 12 (not infants) need an average of 1 litre a day, per the DGE and the Max Rubner Institute. The app uses that — 1 litre plus the same 0.5 litres for cooking. From 65 the same footnote recommends 2 litres a day; age is not in the household profile, so that appears only as a note on the inventory screen. The 1400 kcal for a child remain this app\'s own cautious estimate — there is no official figure. For dogs and cats only water is counted, at the veterinary rule of thumb of roughly 60 ml per kilogram: 1.2 litres for a 20 kg dog, 0.25 litres for a 4 kg cat. For anything exact, the BMEL\'s Vorratskalkulator.'**
  String get supplyCalculatorSourceBody;

  /// No description provided for @householdChildrenLabel.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get householdChildrenLabel;

  /// No description provided for @householdDogsLabel.
  ///
  /// In en, this message translates to:
  /// **'Dogs'**
  String get householdDogsLabel;

  /// No description provided for @householdCatsLabel.
  ///
  /// In en, this message translates to:
  /// **'Cats'**
  String get householdCatsLabel;

  /// No description provided for @householdAdultsLabel.
  ///
  /// In en, this message translates to:
  /// **'Adults'**
  String get householdAdultsLabel;

  /// No description provided for @storageTipsTitle.
  ///
  /// In en, this message translates to:
  /// **'Storage tips'**
  String get storageTipsTitle;

  /// No description provided for @storageTipsIntro.
  ///
  /// In en, this message translates to:
  /// **'The BBK recommends a ten-day supply and, for the amounts, points at the stockpiling tables of the Federal Office for Agriculture and Food. They are here — scaled to your household.'**
  String get storageTipsIntro;

  /// No description provided for @storagePeopleLine.
  ///
  /// In en, this message translates to:
  /// **'For {count} people — from the household'**
  String storagePeopleLine(Object count);

  /// No description provided for @storageDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String storageDaysLabel(Object days);

  /// No description provided for @storageFewerDays.
  ///
  /// In en, this message translates to:
  /// **'One day fewer'**
  String get storageFewerDays;

  /// No description provided for @storageMoreDays.
  ///
  /// In en, this message translates to:
  /// **'One day more'**
  String get storageMoreDays;

  /// No description provided for @storageScaledNote.
  ///
  /// In en, this message translates to:
  /// **'The table is printed for one person and ten days. Every amount here is converted.'**
  String get storageScaledNote;

  /// No description provided for @storageDietMixed.
  ///
  /// In en, this message translates to:
  /// **'Mixed diet'**
  String get storageDietMixed;

  /// No description provided for @storageDietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get storageDietVegetarian;

  /// No description provided for @storageAmountGrams.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String storageAmountGrams(Object value);

  /// No description provided for @storageAmountKilograms.
  ///
  /// In en, this message translates to:
  /// **'{value} kg'**
  String storageAmountKilograms(Object value);

  /// No description provided for @storageAmountLiters.
  ///
  /// In en, this message translates to:
  /// **'{value} l'**
  String storageAmountLiters(Object value);

  /// No description provided for @storageAmountPieces.
  ///
  /// In en, this message translates to:
  /// **'{count} pcs'**
  String storageAmountPieces(Object count);

  /// No description provided for @storageKcal.
  ///
  /// In en, this message translates to:
  /// **'{kcal} kcal'**
  String storageKcal(Object kcal);

  /// No description provided for @storageVariantLine.
  ///
  /// In en, this message translates to:
  /// **'or {name}: {kcal} kcal'**
  String storageVariantLine(Object kcal, Object name);

  /// No description provided for @storageAddToInventory.
  ///
  /// In en, this message translates to:
  /// **'Add to inventory'**
  String get storageAddToInventory;

  /// No description provided for @storageFromTableNote.
  ///
  /// In en, this message translates to:
  /// **'Taken from the BLE stockpiling table.'**
  String get storageFromTableNote;

  /// No description provided for @storageUnitGram.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get storageUnitGram;

  /// No description provided for @storageUnitLiter.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get storageUnitLiter;

  /// No description provided for @storageUnitPiece.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get storageUnitPiece;

  /// No description provided for @storageNutrientProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get storageNutrientProtein;

  /// No description provided for @storageNutrientFiber.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get storageNutrientFiber;

  /// No description provided for @storageNutrientIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get storageNutrientIron;

  /// No description provided for @storageNutrientVitaminB12.
  ///
  /// In en, this message translates to:
  /// **'Vitamin B12'**
  String get storageNutrientVitaminB12;

  /// No description provided for @storageNutrientHealthyFats.
  ///
  /// In en, this message translates to:
  /// **'Healthy fats'**
  String get storageNutrientHealthyFats;

  /// No description provided for @storageNutrientFluid.
  ///
  /// In en, this message translates to:
  /// **'Fluid'**
  String get storageNutrientFluid;

  /// No description provided for @storageNutrientLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'What the markers mean'**
  String get storageNutrientLegendTitle;

  /// No description provided for @storageNutrientLegendBody.
  ///
  /// In en, this message translates to:
  /// **'The markers on the foods are not in the official table — they are this app\'s own reading. They show what a food is mainly there for, so you can see what leaves with a group you drop. Orientation, not dietary advice.'**
  String get storageNutrientLegendBody;

  /// No description provided for @storageTipsGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General tips'**
  String get storageTipsGeneralTitle;

  /// No description provided for @storageTipRotate.
  ///
  /// In en, this message translates to:
  /// **'Rotate the stock: always use the oldest first and replace it. Then nothing expires and nothing was bought for the bin.'**
  String get storageTipRotate;

  /// No description provided for @storageTipCoolDryDark.
  ///
  /// In en, this message translates to:
  /// **'Store cool, dry and dark, ideally in tightly closing containers.'**
  String get storageTipCoolDryDark;

  /// No description provided for @storageTipEatWhatYouStore.
  ///
  /// In en, this message translates to:
  /// **'Only store what you actually eat. A supply nobody likes is never used up and eventually thrown away.'**
  String get storageTipEatWhatYouStore;

  /// No description provided for @storageTipNoPower.
  ///
  /// In en, this message translates to:
  /// **'Count on a power cut: plan nothing that has to be refrigerated or frozen.'**
  String get storageTipNoPower;

  /// No description provided for @storageTipReadyToEat.
  ///
  /// In en, this message translates to:
  /// **'Choose part of it so that it can be eaten without cooking — in case the gas or the hob goes too.'**
  String get storageTipReadyToEat;

  /// No description provided for @storageTipCanOpener.
  ///
  /// In en, this message translates to:
  /// **'Remember a tin opener that works without electricity.'**
  String get storageTipCanOpener;

  /// No description provided for @storageTipSpecialNeeds.
  ///
  /// In en, this message translates to:
  /// **'Small children, pets, medication and special diets belong on the list too. The table does not cover them.'**
  String get storageTipSpecialNeeds;

  /// No description provided for @storageVeganTitle.
  ///
  /// In en, this message translates to:
  /// **'Vegan?'**
  String get storageVeganTitle;

  /// No description provided for @storageVeganBody.
  ///
  /// In en, this message translates to:
  /// **'There is no official vegan table — the BLE publishes these two and no third, and the app does not invent one. On a vegan diet, two lines of the vegetarian table are replaced: 2.5 kg of milk and dairy, and the five eggs. Fortified plant drinks and soy products cover protein and calcium. For vitamin B12, iodine, iron and omega-3 the DGE issues an explicit warning on a vegan diet — B12 can only be covered reliably by a supplement, and that then belongs in the supply like everything else.'**
  String get storageVeganBody;

  /// No description provided for @storageSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Where the numbers come from'**
  String get storageSourceTitle;

  /// No description provided for @storageSourceBody.
  ///
  /// In en, this message translates to:
  /// **'On its \"Bevorraten\" page the BBK gives ten days and 1.5 litres of fluid plus 0.5 litres for cooking a day; for the amounts it points at the stockpiling tables of the Federal Office for Agriculture and Food (BLE, 2024, ernaehrungsvorsorge.de). Every line here comes from there: a basic supply for one person and ten days at an average 2,200 kcal a day, once as a mixed diet and once ovo-lacto-vegetarian. The energy figures are from the Bundeslebensmittelschlüssel 3.02 of the Max Rubner Institute; the amounts follow the DGE, ÖGE and SGE reference values. Scaling is linear in people and days. The markers on the foods are this app\'s addition and appear in no official table.'**
  String get storageSourceBody;

  /// No description provided for @nutritionSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionSectionTitle;

  /// No description provided for @nutritionSectionHint.
  ///
  /// In en, this message translates to:
  /// **'For the whole amount, not per 100 g. Scanning a barcode fills in whatever the label states.'**
  String get nutritionSectionHint;

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @carbohydrateLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbohydrates'**
  String get carbohydrateLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @fiberLabel.
  ///
  /// In en, this message translates to:
  /// **'Fibre'**
  String get fiberLabel;

  /// No description provided for @supplyCalculatorSeniorNote.
  ///
  /// In en, this message translates to:
  /// **'From 65 the DGE recommends 2 litres of drinking a day rather than 1.5 — so plan half a litre more per person and day for older people in the household.'**
  String get supplyCalculatorSeniorNote;

  /// No description provided for @warningFilterSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Place, region or keyword'**
  String get warningFilterSearchHint;

  /// No description provided for @warningFilterSearchClear.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get warningFilterSearchClear;

  /// No description provided for @warningFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get warningFilterActive;

  /// No description provided for @warningFilterExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get warningFilterExpired;

  /// No description provided for @warningFilterMyRegions.
  ///
  /// In en, this message translates to:
  /// **'My regions'**
  String get warningFilterMyRegions;

  /// No description provided for @warningFilterSevere.
  ///
  /// In en, this message translates to:
  /// **'Severe and up'**
  String get warningFilterSevere;

  /// No description provided for @warningFilterResultCount.
  ///
  /// In en, this message translates to:
  /// **'{shown} of {total} warnings'**
  String warningFilterResultCount(Object shown, Object total);

  /// No description provided for @warningFilterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear filter'**
  String get warningFilterClear;

  /// No description provided for @warningsEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'None of the {total} warnings match the filter.'**
  String warningsEmptyFiltered(Object total);

  /// No description provided for @checklistCategoryInformation.
  ///
  /// In en, this message translates to:
  /// **'Staying informed'**
  String get checklistCategoryInformation;

  /// No description provided for @checklistCategoryEvacuation.
  ///
  /// In en, this message translates to:
  /// **'Emergency luggage'**
  String get checklistCategoryEvacuation;

  /// No description provided for @checklistCategorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety at home'**
  String get checklistCategorySafety;

  /// No description provided for @checklistCategoryHazards.
  ///
  /// In en, this message translates to:
  /// **'Natural hazards'**
  String get checklistCategoryHazards;

  /// No description provided for @checklistCategoryWellbeing.
  ///
  /// In en, this message translates to:
  /// **'Fears and worries'**
  String get checklistCategoryWellbeing;

  /// No description provided for @checklistCategoryPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get checklistCategoryPets;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navWarnings.
  ///
  /// In en, this message translates to:
  /// **'Warnings'**
  String get navWarnings;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @overviewSupplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Supply for {days} days'**
  String overviewSupplyTitle(Object days);

  /// No description provided for @overviewSupplyWater.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} L'**
  String overviewSupplyWater(Object current, Object target);

  /// No description provided for @overviewSupplyCalories.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} kcal'**
  String overviewSupplyCalories(int current, int target);

  /// No description provided for @overviewAttentionTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get overviewAttentionTitle;

  /// No description provided for @overviewNothingStored.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been added to the inventory yet.'**
  String get overviewNothingStored;

  /// No description provided for @overviewChargeDue.
  ///
  /// In en, this message translates to:
  /// **'Check the rechargeable equipment'**
  String get overviewChargeDue;

  /// No description provided for @overviewChargeOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue by {days, plural, =1{one day} other{{days} days}}'**
  String overviewChargeOverdue(int days);

  /// No description provided for @overviewChargeDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get overviewChargeDueToday;

  /// No description provided for @overviewChargeNext.
  ///
  /// In en, this message translates to:
  /// **'Next check in {days, plural, =1{one day} other{{days} days}}'**
  String overviewChargeNext(int days);

  /// No description provided for @overviewChargeNeverChecked.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed yet'**
  String get overviewChargeNeverChecked;

  /// No description provided for @overviewChargeDone.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get overviewChargeDone;

  /// No description provided for @overviewExpired.
  ///
  /// In en, this message translates to:
  /// **'expired'**
  String get overviewExpired;

  /// No description provided for @overviewLowStock.
  ///
  /// In en, this message translates to:
  /// **'below minimum'**
  String get overviewLowStock;

  /// No description provided for @overviewExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'expires within 30 days'**
  String get overviewExpiringSoon;

  /// No description provided for @overviewNoWarnings.
  ///
  /// In en, this message translates to:
  /// **'No warnings for your regions right now.'**
  String get overviewNoWarnings;

  /// No description provided for @overviewChecklistLists.
  ///
  /// In en, this message translates to:
  /// **'{complete} of {total} lists complete'**
  String overviewChecklistLists(Object complete, Object total);

  /// No description provided for @overviewResourcesTitle.
  ///
  /// In en, this message translates to:
  /// **'Resources'**
  String get overviewResourcesTitle;

  /// No description provided for @overviewItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count} entries'**
  String overviewItemCount(Object count);

  /// No description provided for @photoEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get photoEditTitle;

  /// No description provided for @photoEditHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the frame onto the part you want to keep.'**
  String get photoEditHint;

  /// No description provided for @photoEditRotateLeft.
  ///
  /// In en, this message translates to:
  /// **'Rotate left'**
  String get photoEditRotateLeft;

  /// No description provided for @photoEditRotateRight.
  ///
  /// In en, this message translates to:
  /// **'Rotate right'**
  String get photoEditRotateRight;

  /// No description provided for @photoEditReset.
  ///
  /// In en, this message translates to:
  /// **'Whole picture'**
  String get photoEditReset;

  /// No description provided for @photoEditFailed.
  ///
  /// In en, this message translates to:
  /// **'This picture cannot be edited. It stays as it is.'**
  String get photoEditFailed;

  /// No description provided for @editPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get editPhotoButton;

  /// No description provided for @sharingErrorEncryptionChanged.
  ///
  /// In en, this message translates to:
  /// **'Sync stopped: encryption metadata is missing or was reset. Restore the encrypted household.json from a backup. No unencrypted household data was written.'**
  String get sharingErrorEncryptionChanged;

  /// No description provided for @searchUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Search is currently unavailable. Please try again.'**
  String get searchUnavailable;

  /// No description provided for @inventoryFilters.
  ///
  /// In en, this message translates to:
  /// **'Filter and sort'**
  String get inventoryFilters;

  /// No description provided for @inventoryFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get inventoryFilterCategory;

  /// No description provided for @inventoryFilterLocation.
  ///
  /// In en, this message translates to:
  /// **'Storage location'**
  String get inventoryFilterLocation;

  /// No description provided for @inventoryFilterStatus.
  ///
  /// In en, this message translates to:
  /// **'Stock status'**
  String get inventoryFilterStatus;

  /// No description provided for @inventoryFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get inventoryFilterAll;

  /// No description provided for @inventoryNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No storage location'**
  String get inventoryNoLocation;

  /// No description provided for @inventoryExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expires in the next 7 days'**
  String get inventoryExpiringSoon;

  /// No description provided for @inventorySortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get inventorySortLabel;

  /// No description provided for @inventorySortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get inventorySortName;

  /// No description provided for @inventorySortExpiry.
  ///
  /// In en, this message translates to:
  /// **'Expiry date'**
  String get inventorySortExpiry;

  /// No description provided for @inventorySortAttention.
  ///
  /// In en, this message translates to:
  /// **'Needs attention'**
  String get inventorySortAttention;

  /// No description provided for @inventoryApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get inventoryApplyFilters;

  /// No description provided for @inventoryResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get inventoryResetFilters;

  /// No description provided for @inventoryFiltersActive.
  ///
  /// In en, this message translates to:
  /// **'Filters active'**
  String get inventoryFiltersActive;

  /// No description provided for @inventorySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search supplies'**
  String get inventorySearchHint;

  /// No description provided for @inventoryClearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get inventoryClearSearch;

  /// No description provided for @inventoryNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching supplies. Adjust your search or filters.'**
  String get inventoryNoMatches;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'Your changes have not been saved yet.'**
  String get unsavedChangesMessage;

  /// No description provided for @keepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get keepEditing;

  /// No description provided for @discardChanges.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// No description provided for @inventoryItemDeleted.
  ///
  /// In en, this message translates to:
  /// **'Supply deleted'**
  String get inventoryItemDeleted;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undoAction;

  /// No description provided for @budgetEntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Expense deleted'**
  String get budgetEntryDeleted;

  /// No description provided for @emergencyRadioChannels.
  ///
  /// In en, this message translates to:
  /// **'{count} channels'**
  String emergencyRadioChannels(int count);

  /// No description provided for @overviewStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first step towards preparedness'**
  String get overviewStartTitle;

  /// No description provided for @overviewStartHint.
  ///
  /// In en, this message translates to:
  /// **'Add water or food to see how long your household supplies will last.'**
  String get overviewStartHint;

  /// No description provided for @overviewAddFirst.
  ///
  /// In en, this message translates to:
  /// **'Add your first supply'**
  String get overviewAddFirst;

  /// No description provided for @overviewOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get overviewOpen;

  /// No description provided for @warningMoreInformation.
  ///
  /// In en, this message translates to:
  /// **'More information from the warning source'**
  String get warningMoreInformation;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More actions'**
  String get moreActions;

  /// No description provided for @checklistLinkStockAction.
  ///
  /// In en, this message translates to:
  /// **'Link to stock'**
  String get checklistLinkStockAction;

  /// No description provided for @checklistLinkStockTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose stock item'**
  String get checklistLinkStockTitle;

  /// No description provided for @checklistUnlinkStockAction.
  ///
  /// In en, this message translates to:
  /// **'Remove link'**
  String get checklistUnlinkStockAction;

  /// No description provided for @checklistNoStockToLink.
  ///
  /// In en, this message translates to:
  /// **'There is no stock item to link yet.'**
  String get checklistNoStockToLink;

  /// No description provided for @checklistLinkedStock.
  ///
  /// In en, this message translates to:
  /// **'{name}: {quantity} {unit} available'**
  String checklistLinkedStock(String name, num quantity, String unit);

  /// No description provided for @navEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get navEmergency;

  /// No description provided for @emergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency & readiness'**
  String get emergencyTitle;

  /// No description provided for @emergencyCall112.
  ///
  /// In en, this message translates to:
  /// **'Emergency 112'**
  String get emergencyCall112;

  /// No description provided for @emergencyCall110.
  ///
  /// In en, this message translates to:
  /// **'Police 110'**
  String get emergencyCall110;

  /// No description provided for @emergencyCurrentWarnings.
  ///
  /// In en, this message translates to:
  /// **'Current warnings'**
  String get emergencyCurrentWarnings;

  /// No description provided for @emergencyNoWarnings.
  ///
  /// In en, this message translates to:
  /// **'No relevant active warnings'**
  String get emergencyNoWarnings;

  /// No description provided for @readinessTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline readiness'**
  String get readinessTitle;

  /// No description provided for @readinessReady.
  ///
  /// In en, this message translates to:
  /// **'ready'**
  String get readinessReady;

  /// No description provided for @readinessNeedsWork.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get readinessNeedsWork;

  /// No description provided for @readinessInventory.
  ///
  /// In en, this message translates to:
  /// **'Stock recorded'**
  String get readinessInventory;

  /// No description provided for @readinessChecklists.
  ///
  /// In en, this message translates to:
  /// **'Checklists started'**
  String get readinessChecklists;

  /// No description provided for @readinessPlan.
  ///
  /// In en, this message translates to:
  /// **'Emergency plan completed'**
  String get readinessPlan;

  /// No description provided for @readinessCards.
  ///
  /// In en, this message translates to:
  /// **'Emergency cards recorded'**
  String get readinessCards;

  /// No description provided for @readinessMap.
  ///
  /// In en, this message translates to:
  /// **'Offline map available'**
  String get readinessMap;

  /// No description provided for @readinessKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Offline knowledge available'**
  String get readinessKnowledge;

  /// No description provided for @emergencyPlanMissing.
  ///
  /// In en, this message translates to:
  /// **'Emergency plan has not been completed'**
  String get emergencyPlanMissing;

  /// No description provided for @emergencyPlanHeading.
  ///
  /// In en, this message translates to:
  /// **'Important details'**
  String get emergencyPlanHeading;

  /// No description provided for @knowledgeManageArchives.
  ///
  /// In en, this message translates to:
  /// **'Manage archives'**
  String get knowledgeManageArchives;

  /// No description provided for @knowledgeArchiveCount.
  ///
  /// In en, this message translates to:
  /// **'{count} archives on this device'**
  String knowledgeArchiveCount(int count);

  /// No description provided for @knowledgeArchiveSelected.
  ///
  /// In en, this message translates to:
  /// **'Currently open'**
  String get knowledgeArchiveSelected;

  /// No description provided for @backupTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup & restore'**
  String get backupTitle;

  /// No description provided for @backupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create data backup'**
  String get backupCreate;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore data backup'**
  String get backupRestore;

  /// No description provided for @backupHint.
  ///
  /// In en, this message translates to:
  /// **'Stock, checklists, emergency plan and emergency cards. The file contains personal data and should be stored securely.'**
  String get backupHint;

  /// No description provided for @backupCreated.
  ///
  /// In en, this message translates to:
  /// **'Data backup saved.'**
  String get backupCreated;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Backup restored: {count} newer records applied.'**
  String backupRestored(int count);

  /// No description provided for @backupInvalid.
  ///
  /// In en, this message translates to:
  /// **'This backup belongs to a different household or is damaged.'**
  String get backupInvalid;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'The data backup could not be processed.'**
  String get backupFailed;

  /// No description provided for @backupPassphraseTitle.
  ///
  /// In en, this message translates to:
  /// **'Encrypt backup'**
  String get backupPassphraseTitle;

  /// No description provided for @backupPassphrase.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get backupPassphrase;

  /// No description provided for @backupPassphraseRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat password'**
  String get backupPassphraseRepeat;

  /// No description provided for @backupPassphraseWarning.
  ///
  /// In en, this message translates to:
  /// **'Without this passphrase the file cannot be opened again – not by you either. There is no way back and no back door. Write it down where the passports are kept, and not on the device this backup is meant to replace.'**
  String get backupPassphraseWarning;

  /// No description provided for @backupPassphraseInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter at least {count} characters; both entries have to match.'**
  String backupPassphraseInvalid(int count);

  /// No description provided for @warningInstructionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended actions'**
  String get warningInstructionsTitle;

  /// No description provided for @warningShowMap.
  ///
  /// In en, this message translates to:
  /// **'Show area on map'**
  String get warningShowMap;

  /// No description provided for @warningDetailsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Alert from: {start} – {end}'**
  String warningDetailsPeriod(String start, String end);

  /// No description provided for @warningDetailsUntilFurtherNotice.
  ///
  /// In en, this message translates to:
  /// **'until further notice'**
  String get warningDetailsUntilFurtherNotice;

  /// No description provided for @warningDetailsLevel.
  ///
  /// In en, this message translates to:
  /// **'Alert level: {severity}'**
  String warningDetailsLevel(String severity);

  /// No description provided for @warningDetailsAffectedRegions.
  ///
  /// In en, this message translates to:
  /// **'Affected region(s)'**
  String get warningDetailsAffectedRegions;

  /// No description provided for @warningDetailsNoInstructions.
  ///
  /// In en, this message translates to:
  /// **'No recommended actions were provided for this alert.'**
  String get warningDetailsNoInstructions;

  /// No description provided for @warningDetailsNoArea.
  ///
  /// In en, this message translates to:
  /// **'The warning source did not specify the affected area further.'**
  String get warningDetailsNoArea;

  /// No description provided for @warningDetailsSource.
  ///
  /// In en, this message translates to:
  /// **'Warning source and publication'**
  String get warningDetailsSource;

  /// No description provided for @warningDetailsPublished.
  ///
  /// In en, this message translates to:
  /// **'Published: {time}'**
  String warningDetailsPublished(String time);

  /// No description provided for @warningDetailsOfflineHint.
  ///
  /// In en, this message translates to:
  /// **'The map, area and recommended actions were saved with this alert and remain readable offline.'**
  String get warningDetailsOfflineHint;

  /// No description provided for @knowledgeBrowseTitle.
  ///
  /// In en, this message translates to:
  /// **'Browse archive'**
  String get knowledgeBrowseTitle;

  /// No description provided for @knowledgeBrowseBody.
  ///
  /// In en, this message translates to:
  /// **'Open the main page, choose an initial letter, or discover a random article.'**
  String get knowledgeBrowseBody;

  /// No description provided for @knowledgeMainPageAction.
  ///
  /// In en, this message translates to:
  /// **'Main page'**
  String get knowledgeMainPageAction;

  /// No description provided for @knowledgeRandomAction.
  ///
  /// In en, this message translates to:
  /// **'Random article'**
  String get knowledgeRandomAction;

  /// No description provided for @knowledgeArchiveStats.
  ///
  /// In en, this message translates to:
  /// **'{articles} entries · approximately {size}'**
  String knowledgeArchiveStats(int articles, String size);

  /// No description provided for @knowledgeTotalSize.
  ///
  /// In en, this message translates to:
  /// **'Total size: approximately {size}'**
  String knowledgeTotalSize(String size);

  /// No description provided for @knowledgeDocumentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal documents'**
  String get knowledgeDocumentsTitle;

  /// No description provided for @knowledgeDocumentsIntro.
  ///
  /// In en, this message translates to:
  /// **'PDF, EPUB and Markdown files remain in their original location and are not duplicated.'**
  String get knowledgeDocumentsIntro;

  /// No description provided for @knowledgeDocumentAdd.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get knowledgeDocumentAdd;

  /// No description provided for @knowledgeDocumentsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No personal documents have been added yet.'**
  String get knowledgeDocumentsEmpty;

  /// No description provided for @knowledgeDocumentRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from library'**
  String get knowledgeDocumentRemove;

  /// No description provided for @knowledgeDocumentOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'The document could not be opened.'**
  String get knowledgeDocumentOpenFailed;

  /// No description provided for @emergencyDirectoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency calls, contacts & radio'**
  String get emergencyDirectoryTitle;

  /// No description provided for @emergencyMedicalService.
  ///
  /// In en, this message translates to:
  /// **'Non-emergency medical service 116117'**
  String get emergencyMedicalService;

  /// No description provided for @emergencyPoisonTitle.
  ///
  /// In en, this message translates to:
  /// **'Poison control centres'**
  String get emergencyPoisonTitle;

  /// No description provided for @emergencyPoisonHint.
  ///
  /// In en, this message translates to:
  /// **'For life-threatening symptoms, call 112 first. The responsible poison control centre advises in suspected poisoning cases.'**
  String get emergencyPoisonHint;

  /// No description provided for @emergencyRadioTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio frequency ranges'**
  String get emergencyRadioTitle;

  /// No description provided for @emergencyRadioHint.
  ///
  /// In en, this message translates to:
  /// **'Local station frequencies change. Run a station scan during an incident and follow official announcements. Transmit only where the relevant radio service permits it.'**
  String get emergencyRadioHint;

  /// No description provided for @emergencySirenTitle.
  ///
  /// In en, this message translates to:
  /// **'Siren signals'**
  String get emergencySirenTitle;

  /// No description provided for @emergencySirenHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended nationwide but not regulated the same everywhere – when in doubt, what your own municipality announced is what counts. Every warning is followed by the same thing: get inside, close the windows, turn on the radio.'**
  String get emergencySirenHint;

  /// No description provided for @emergencySirenWarning.
  ///
  /// In en, this message translates to:
  /// **'Rising and falling wail, one minute'**
  String get emergencySirenWarning;

  /// No description provided for @emergencySirenWarningMeaning.
  ///
  /// In en, this message translates to:
  /// **'Warning. Danger nearby. Get into a building, close windows and doors, turn on the radio and wait for announcements.'**
  String get emergencySirenWarningMeaning;

  /// No description provided for @emergencySirenAllClear.
  ///
  /// In en, this message translates to:
  /// **'Steady continuous tone, one minute'**
  String get emergencySirenAllClear;

  /// No description provided for @emergencySirenAllClearMeaning.
  ///
  /// In en, this message translates to:
  /// **'All clear. The danger has passed. It arrives by the same route the warning did.'**
  String get emergencySirenAllClearMeaning;

  /// No description provided for @emergencySirenFire.
  ///
  /// In en, this message translates to:
  /// **'Tone interrupted twice, one minute'**
  String get emergencySirenFire;

  /// No description provided for @emergencySirenFireMeaning.
  ///
  /// In en, this message translates to:
  /// **'Fire brigade alert. It calls the responders and is not addressed to the public – no reason to do anything.'**
  String get emergencySirenFireMeaning;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby emergency contacts'**
  String get emergencyContactsTitle;

  /// No description provided for @emergencyContactsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No nearby contacts saved yet.'**
  String get emergencyContactsEmpty;

  /// No description provided for @emergencyContactAdd.
  ///
  /// In en, this message translates to:
  /// **'Add contact'**
  String get emergencyContactAdd;

  /// No description provided for @emergencyContactName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get emergencyContactName;

  /// No description provided for @emergencyContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get emergencyContactPhone;

  /// No description provided for @emergencyContactAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get emergencyContactAddress;

  /// No description provided for @emergencyContactCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates (latitude, longitude)'**
  String get emergencyContactCoordinates;

  /// No description provided for @emergencyContactDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete contact'**
  String get emergencyContactDelete;

  /// No description provided for @emergencyOpenMapAction.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get emergencyOpenMapAction;

  /// No description provided for @prepperRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency recipes'**
  String get prepperRecipesTitle;

  /// No description provided for @prepperRecipesIntro.
  ///
  /// In en, this message translates to:
  /// **'Simple meals from shelf-stable supplies using little water and energy. Adjust quantities to the household.'**
  String get prepperRecipesIntro;

  /// No description provided for @preservationTitle.
  ///
  /// In en, this message translates to:
  /// **'Preserving food'**
  String get preservationTitle;

  /// No description provided for @preservationIntro.
  ///
  /// In en, this message translates to:
  /// **'Established methods for food on hand. Work cleanly, observe safe processing times, and discard swollen or suspicious jars.'**
  String get preservationIntro;

  /// No description provided for @storageOfficialCalculator.
  ///
  /// In en, this message translates to:
  /// **'Open official stock calculator'**
  String get storageOfficialCalculator;

  /// No description provided for @storageOfficialTips.
  ///
  /// In en, this message translates to:
  /// **'More food preparedness tips'**
  String get storageOfficialTips;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTitle;

  /// No description provided for @resetSettings.
  ///
  /// In en, this message translates to:
  /// **'Reset app settings'**
  String get resetSettings;

  /// No description provided for @resetSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Restore defaults for language, appearance, notifications, reminders and map provider. Data and downloads remain.'**
  String get resetSettingsHint;

  /// No description provided for @resetHousehold.
  ///
  /// In en, this message translates to:
  /// **'Delete household and local data'**
  String get resetHousehold;

  /// No description provided for @resetHouseholdHint.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete this household’s inventory, checklists, emergency plan and emergency cards from this device.'**
  String get resetHouseholdHint;

  /// No description provided for @resetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset now?'**
  String get resetConfirmTitle;

  /// No description provided for @resetConfirmHousehold.
  ///
  /// In en, this message translates to:
  /// **'Local household data will be permanently deleted. Create a backup first if needed.'**
  String get resetConfirmHousehold;

  /// No description provided for @resetDone.
  ///
  /// In en, this message translates to:
  /// **'Reset completed.'**
  String get resetDone;

  /// No description provided for @knowledgeDocumentIndexTitle.
  ///
  /// In en, this message translates to:
  /// **'Offline search'**
  String get knowledgeDocumentIndexTitle;

  /// No description provided for @knowledgeDocumentIndexOption.
  ///
  /// In en, this message translates to:
  /// **'Make this document searchable'**
  String get knowledgeDocumentIndexOption;

  /// No description provided for @knowledgeDocumentIndexPrivacy.
  ///
  /// In en, this message translates to:
  /// **'The text index stays only on this device. The original file is not copied.'**
  String get knowledgeDocumentIndexPrivacy;

  /// No description provided for @knowledgeDocumentIndexed.
  ///
  /// In en, this message translates to:
  /// **'Ready for offline search'**
  String get knowledgeDocumentIndexed;

  /// No description provided for @knowledgeDocumentIndexing.
  ///
  /// In en, this message translates to:
  /// **'Building index …'**
  String get knowledgeDocumentIndexing;

  /// No description provided for @knowledgeDocumentNotIndexed.
  ///
  /// In en, this message translates to:
  /// **'Not in search'**
  String get knowledgeDocumentNotIndexed;

  /// No description provided for @knowledgeDocumentNoText.
  ///
  /// In en, this message translates to:
  /// **'No readable text (possibly a scan)'**
  String get knowledgeDocumentNoText;

  /// No description provided for @knowledgeDocumentTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Too large for the index (48 MB maximum)'**
  String get knowledgeDocumentTooLarge;

  /// No description provided for @knowledgeDocumentIndexFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not build index'**
  String get knowledgeDocumentIndexFailed;

  /// No description provided for @knowledgeDocumentReindex.
  ///
  /// In en, this message translates to:
  /// **'Rebuild search index'**
  String get knowledgeDocumentReindex;

  /// No description provided for @knowledgeDocumentClearIndex.
  ///
  /// In en, this message translates to:
  /// **'Delete search index'**
  String get knowledgeDocumentClearIndex;

  /// No description provided for @knowledgeDocumentClearIndexBody.
  ///
  /// In en, this message translates to:
  /// **'The search data for all personal documents will be deleted. Original files remain untouched.'**
  String get knowledgeDocumentClearIndexBody;

  /// No description provided for @knowledgeDocumentIndexSummary.
  ///
  /// In en, this message translates to:
  /// **'{indexed} of {total} documents searchable'**
  String knowledgeDocumentIndexSummary(int indexed, int total);

  /// No description provided for @knowledgePersonalResults.
  ///
  /// In en, this message translates to:
  /// **'Personal documents'**
  String get knowledgePersonalResults;

  /// No description provided for @knowledgePersonalResultHint.
  ///
  /// In en, this message translates to:
  /// **'Results from the local document index'**
  String get knowledgePersonalResultHint;

  /// No description provided for @radioEmergencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency radio frequencies'**
  String get radioEmergencyTitle;

  /// No description provided for @radioEmergencyEntryHint.
  ///
  /// In en, this message translates to:
  /// **'CB and amateur radio: frequencies, rules and guidance'**
  String get radioEmergencyEntryHint;

  /// No description provided for @radioEmergencyIntro.
  ///
  /// In en, this message translates to:
  /// **'112 remains the first route for emergencies. Radio frequencies are a possible fallback when approved equipment is available; they are not permanently monitored.'**
  String get radioEmergencyIntro;

  /// No description provided for @radioCbTitle.
  ///
  /// In en, this message translates to:
  /// **'CB radio: calling and assistance channels'**
  String get radioCbTitle;

  /// No description provided for @radioCbHintsTitle.
  ///
  /// In en, this message translates to:
  /// **'CB radio guidance'**
  String get radioCbHintsTitle;

  /// No description provided for @radioCbRule.
  ///
  /// In en, this message translates to:
  /// **'CB radio is generally allocated in Germany. Use approved equipment only and observe power, mode and antenna requirements.'**
  String get radioCbRule;

  /// No description provided for @radioAmateurTitle.
  ///
  /// In en, this message translates to:
  /// **'Amateur radio: IARU emergency centres of activity'**
  String get radioAmateurTitle;

  /// No description provided for @radioLegalTitle.
  ///
  /// In en, this message translates to:
  /// **'Legal notice'**
  String get radioLegalTitle;

  /// No description provided for @radioAmateurLegal.
  ///
  /// In en, this message translates to:
  /// **'Amateur radio may only be operated in Germany with a valid amateur radio licence. These frequencies are information and activity centres, not guaranteed emergency services.'**
  String get radioAmateurLegal;

  /// No description provided for @radioNoGuaranteedMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Do not wait for a reply: always call 112 first when it is reachable.'**
  String get radioNoGuaranteedMonitoring;

  /// No description provided for @radioListenFirst.
  ///
  /// In en, this message translates to:
  /// **'Listen for an extended period before transmitting. Do not interfere with ongoing emergency traffic.'**
  String get radioListenFirst;

  /// No description provided for @radioEmergencyCall.
  ///
  /// In en, this message translates to:
  /// **'Call only in a genuine emergency. State location, hazard and required help first; keep it brief and clear.'**
  String get radioEmergencyCall;

  /// No description provided for @radioUseHintsTitle.
  ///
  /// In en, this message translates to:
  /// **'Usage guidance'**
  String get radioUseHintsTitle;

  /// No description provided for @radioBriefMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the lowest possible transmit power, confirm receipt, and agree fixed check-in times when energy is scarce.'**
  String get radioBriefMessage;

  /// No description provided for @radioOfficialRules.
  ///
  /// In en, this message translates to:
  /// **'Open Federal Network Agency rules'**
  String get radioOfficialRules;

  /// No description provided for @radioIaruSource.
  ///
  /// In en, this message translates to:
  /// **'Open DARC / IARU emergency frequencies'**
  String get radioIaruSource;

  /// No description provided for @knowledgeApolloTitle.
  ///
  /// In en, this message translates to:
  /// **'APOLLO knowledge base'**
  String get knowledgeApolloTitle;

  /// No description provided for @knowledgeApolloMissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Knowledge for exceptional circumstances'**
  String get knowledgeApolloMissionTitle;

  /// No description provided for @knowledgeApolloMissionBody.
  ///
  /// In en, this message translates to:
  /// **'Build a local library for practical action, core knowledge and learning at home. Archives stay on your device and can be read without an internet connection.'**
  String get knowledgeApolloMissionBody;

  /// No description provided for @knowledgeApolloReady.
  ///
  /// In en, this message translates to:
  /// **'Offline library opened and ready'**
  String get knowledgeApolloReady;

  /// No description provided for @knowledgeApolloNotReady.
  ///
  /// In en, this message translates to:
  /// **'No archive opened yet'**
  String get knowledgeApolloNotReady;

  /// No description provided for @knowledgeApolloStatus.
  ///
  /// In en, this message translates to:
  /// **'{count} archives registered · known size: {size}'**
  String knowledgeApolloStatus(int count, String size);

  /// No description provided for @knowledgeApolloStatusHint.
  ///
  /// In en, this message translates to:
  /// **'The bar is a guide for eight recommended core archives; you choose the size and selection.'**
  String get knowledgeApolloStatusHint;

  /// No description provided for @knowledgeApolloDownloadedTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloaded content'**
  String get knowledgeApolloDownloadedTitle;

  /// No description provided for @knowledgeApolloDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get knowledgeApolloDownloaded;

  /// No description provided for @knowledgeApolloOpened.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get knowledgeApolloOpened;

  /// No description provided for @knowledgeApolloStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Practical knowledge first'**
  String get knowledgeApolloStartTitle;

  /// No description provided for @knowledgeApolloStartBody.
  ///
  /// In en, this message translates to:
  /// **'Start with topics that directly help during a disruption. Add schooling and fundamentals afterwards.'**
  String get knowledgeApolloStartBody;

  /// No description provided for @knowledgeApolloMedicalTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine & first aid'**
  String get knowledgeApolloMedicalTitle;

  /// No description provided for @knowledgeApolloMedicalBody.
  ///
  /// In en, this message translates to:
  /// **'Use WikiMed to look up medical basics and first aid directly. It does not replace emergency or professional medical care.'**
  String get knowledgeApolloMedicalBody;

  /// No description provided for @knowledgeApolloSurvivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Survival, bushcraft & self-reliance'**
  String get knowledgeApolloSurvivalTitle;

  /// No description provided for @knowledgeApolloSurvivalBody.
  ///
  /// In en, this message translates to:
  /// **'Wikibooks and iFixit cover water, shelter, fire, navigation, food, hygiene and repairs as understandable foundations.'**
  String get knowledgeApolloSurvivalBody;

  /// No description provided for @knowledgeApolloRepairTitle.
  ///
  /// In en, this message translates to:
  /// **'Craft, energy & repair'**
  String get knowledgeApolloRepairTitle;

  /// No description provided for @knowledgeApolloRepairBody.
  ///
  /// In en, this message translates to:
  /// **'Tools, repairs, simple technology and practical craft: knowledge that keeps equipment and supplies usable longer.'**
  String get knowledgeApolloRepairBody;

  /// No description provided for @knowledgeApolloFoundationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fundamentals & education'**
  String get knowledgeApolloFoundationsTitle;

  /// No description provided for @knowledgeApolloBasicsTitle.
  ///
  /// In en, this message translates to:
  /// **'Nature, society & core knowledge'**
  String get knowledgeApolloBasicsTitle;

  /// No description provided for @knowledgeApolloBasicsBody.
  ///
  /// In en, this message translates to:
  /// **'Mathematics, language, science, history and dependable background articles for reference.'**
  String get knowledgeApolloBasicsBody;

  /// No description provided for @knowledgeApolloSchoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning at home'**
  String get knowledgeApolloSchoolTitle;

  /// No description provided for @knowledgeApolloSchoolBody.
  ///
  /// In en, this message translates to:
  /// **'Child-friendly explanations, books, exercises and simulations for structured learning without a network.'**
  String get knowledgeApolloSchoolBody;

  /// No description provided for @knowledgeApolloAdvancedTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced study & curriculum'**
  String get knowledgeApolloAdvancedTitle;

  /// No description provided for @knowledgeApolloAdvancedBody.
  ///
  /// In en, this message translates to:
  /// **'More extensive courses for advanced topics. English-language resources are marked as a supplement.'**
  String get knowledgeApolloAdvancedBody;

  /// No description provided for @knowledgeApolloPersonalTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your own material'**
  String get knowledgeApolloPersonalTitle;

  /// No description provided for @knowledgeApolloPersonalBody.
  ///
  /// In en, this message translates to:
  /// **'Add local PDF, EPUB and Markdown files and make readable text available to offline full-text search.'**
  String get knowledgeApolloPersonalBody;

  /// No description provided for @knowledgeApolloDownloadHint.
  ///
  /// In en, this message translates to:
  /// **'Opens the Kiwix library with a matching search. Check language, edition and storage need before downloading.'**
  String get knowledgeApolloDownloadHint;

  /// No description provided for @settingsVersionInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Version information'**
  String get settingsVersionInfoTitle;

  /// No description provided for @settingsVersionInfoApp.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite app'**
  String get settingsVersionInfoApp;

  /// No description provided for @settingsVersionInfoAppValue.
  ///
  /// In en, this message translates to:
  /// **'{version} · build {build}'**
  String settingsVersionInfoAppValue(String version, String build);

  /// No description provided for @settingsVersionInfoDatabase.
  ///
  /// In en, this message translates to:
  /// **'Household database'**
  String get settingsVersionInfoDatabase;

  /// No description provided for @settingsVersionInfoKnowledgeIndex.
  ///
  /// In en, this message translates to:
  /// **'Knowledge archive full-text index'**
  String get settingsVersionInfoKnowledgeIndex;

  /// No description provided for @settingsVersionInfoDocumentsIndex.
  ///
  /// In en, this message translates to:
  /// **'Document full-text index'**
  String get settingsVersionInfoDocumentsIndex;

  /// No description provided for @settingsVersionInfoSchema.
  ///
  /// In en, this message translates to:
  /// **'Schema {version}'**
  String settingsVersionInfoSchema(int version);

  /// No description provided for @settingsVersionInfoOfflineMap.
  ///
  /// In en, this message translates to:
  /// **'Offline map format'**
  String get settingsVersionInfoOfflineMap;

  /// No description provided for @settingsVersionInfoPmtiles.
  ///
  /// In en, this message translates to:
  /// **'PMTiles v3'**
  String get settingsVersionInfoPmtiles;

  /// No description provided for @settingsVersionInfoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get settingsVersionInfoUnavailable;

  /// No description provided for @readinessOpenDashboard.
  ///
  /// In en, this message translates to:
  /// **'Check readiness'**
  String get readinessOpenDashboard;

  /// No description provided for @readinessDashboardHint.
  ///
  /// In en, this message translates to:
  /// **'Offline packages and freshness of warning data'**
  String get readinessDashboardHint;

  /// No description provided for @readinessSummary.
  ///
  /// In en, this message translates to:
  /// **'{ready} of {total} areas ready'**
  String readinessSummary(int ready, int total);

  /// No description provided for @readinessSummaryHint.
  ///
  /// In en, this message translates to:
  /// **'Resolve missing items before an event and repeat the check after changes to the device.'**
  String get readinessSummaryHint;

  /// No description provided for @readinessOfflinePackages.
  ///
  /// In en, this message translates to:
  /// **'Offline packages'**
  String get readinessOfflinePackages;

  /// No description provided for @readinessPackageReady.
  ///
  /// In en, this message translates to:
  /// **'Opened and readable'**
  String get readinessPackageReady;

  /// No description provided for @readinessPackageMissing.
  ///
  /// In en, this message translates to:
  /// **'Not configured or unreadable'**
  String get readinessPackageMissing;

  /// No description provided for @readinessArchivesReady.
  ///
  /// In en, this message translates to:
  /// **'{count} archives registered; selected archive opened'**
  String readinessArchivesReady(int count);

  /// No description provided for @readinessWarningData.
  ///
  /// In en, this message translates to:
  /// **'Official warning data'**
  String get readinessWarningData;

  /// No description provided for @readinessWarningNeverUpdated.
  ///
  /// In en, this message translates to:
  /// **'No complete refresh on this device yet'**
  String get readinessWarningNeverUpdated;

  /// No description provided for @readinessWarningUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last complete refresh: {age}'**
  String readinessWarningUpdated(String age);

  /// No description provided for @readinessJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get readinessJustNow;

  /// No description provided for @readinessMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String readinessMinutesAgo(int minutes);

  /// No description provided for @readinessHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String readinessHoursAgo(int hours);

  /// No description provided for @readinessDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String readinessDaysAgo(int days);

  /// No description provided for @emergencyPlanExport.
  ///
  /// In en, this message translates to:
  /// **'Emergency plan as PDF'**
  String get emergencyPlanExport;

  /// No description provided for @emergencyPlanPdfCards.
  ///
  /// In en, this message translates to:
  /// **'Emergency cards'**
  String get emergencyPlanPdfCards;

  /// No description provided for @emergencyPlanPdfCardsWarning.
  ///
  /// In en, this message translates to:
  /// **'This sheet names health details: blood group, allergies, medication and conditions. Anyone who picks it up can read them, and no lock protects a piece of paper. Keep it where you keep your documents, take it with you rather than leaving it behind, and shred it instead of binning it.'**
  String get emergencyPlanPdfCardsWarning;

  /// No description provided for @emergencyPlanCardsAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Print the emergency cards as well?'**
  String get emergencyPlanCardsAskTitle;

  /// No description provided for @emergencyPlanCardsAskBody.
  ///
  /// In en, this message translates to:
  /// **'On paper the cards work when the phone is dead or gone — which is the reason to have them. It also means a loose sheet naming blood group, allergies, medication and conditions for {count, plural, =1{one person} other{{count} people}}. Nothing on paper can be revoked, wiped remotely or password-protected.'**
  String emergencyPlanCardsAskBody(int count);

  /// No description provided for @emergencyPlanCardsAskWithout.
  ///
  /// In en, this message translates to:
  /// **'Plan only'**
  String get emergencyPlanCardsAskWithout;

  /// No description provided for @emergencyPlanCardsAskWith.
  ///
  /// In en, this message translates to:
  /// **'Include the cards'**
  String get emergencyPlanCardsAskWith;

  /// No description provided for @emergencyPlanPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal emergency plan'**
  String get emergencyPlanPdfTitle;

  /// No description provided for @emergencyPlanPdfMeetingPoints.
  ///
  /// In en, this message translates to:
  /// **'Meeting points'**
  String get emergencyPlanPdfMeetingPoints;

  /// No description provided for @emergencyPlanPdfContact.
  ///
  /// In en, this message translates to:
  /// **'Contact outside the area'**
  String get emergencyPlanPdfContact;

  /// No description provided for @emergencyPlanPdfEquipment.
  ///
  /// In en, this message translates to:
  /// **'Emergency kit and shut-off points'**
  String get emergencyPlanPdfEquipment;

  /// No description provided for @emergencyPlanPdfEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not entered'**
  String get emergencyPlanPdfEmpty;

  /// No description provided for @settingsRegionUnknownKey.
  ///
  /// In en, this message translates to:
  /// **'Unknown key — please check'**
  String get settingsRegionUnknownKey;

  /// No description provided for @settingsRegionKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter five or twelve digits (for example 03101).'**
  String get settingsRegionKeyInvalid;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
