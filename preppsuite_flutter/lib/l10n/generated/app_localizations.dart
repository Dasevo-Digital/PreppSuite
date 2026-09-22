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

  /// No description provided for @airQualityEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Particulates, ozone and nitrogen dioxide at a station near you.'**
  String get airQualityEntryHint;

  /// No description provided for @airQualityTitle.
  ///
  /// In en, this message translates to:
  /// **'Air quality'**
  String get airQualityTitle;

  /// No description provided for @airQualityNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'No station chosen yet'**
  String get airQualityNoneChosen;

  /// No description provided for @airQualityChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a station'**
  String get airQualityChoose;

  /// No description provided for @airQualityChange.
  ///
  /// In en, this message translates to:
  /// **'Another station'**
  String get airQualityChange;

  /// No description provided for @airQualityRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get airQualityRefresh;

  /// No description provided for @airQualitySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Place, station or state'**
  String get airQualitySearchHint;

  /// No description provided for @airQualitySearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No station found.'**
  String get airQualitySearchEmpty;

  /// No description provided for @airQualityLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The readings cannot be reached right now.'**
  String get airQualityLoadFailed;

  /// No description provided for @airQualityOffline.
  ///
  /// In en, this message translates to:
  /// **'Last stored reading — fetching just failed.'**
  String get airQualityOffline;

  /// No description provided for @airQualityStale.
  ///
  /// In en, this message translates to:
  /// **'This reading is over three hours old. The station is not reporting at the moment.'**
  String get airQualityStale;

  /// No description provided for @airQualityIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Not every pollutant this station measures reported this hour. The class covers what did.'**
  String get airQualityIncomplete;

  /// No description provided for @airQualityComponents.
  ///
  /// In en, this message translates to:
  /// **'Individual pollutants'**
  String get airQualityComponents;

  /// No description provided for @airQualityLeading.
  ///
  /// In en, this message translates to:
  /// **'Decisive: {code} at {value} {unit}'**
  String airQualityLeading(String code, String value, String unit);

  /// No description provided for @airQualitySpan.
  ///
  /// In en, this message translates to:
  /// **'{min} to {max}'**
  String airQualitySpan(String min, String max);

  /// No description provided for @airQualityMeasuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured on {when}'**
  String airQualityMeasuredAt(String when);

  /// No description provided for @airQualityVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get airQualityVeryGood;

  /// No description provided for @airQualityGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get airQualityGood;

  /// No description provided for @airQualityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get airQualityModerate;

  /// No description provided for @airQualityPoor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get airQualityPoor;

  /// No description provided for @airQualityVeryPoor.
  ///
  /// In en, this message translates to:
  /// **'Very poor'**
  String get airQualityVeryPoor;

  /// No description provided for @airQualityUnknown.
  ///
  /// In en, this message translates to:
  /// **'No class'**
  String get airQualityUnknown;

  /// No description provided for @airQualityNoWarning.
  ///
  /// In en, this message translates to:
  /// **'This is a measurement, not a warning. If something is actually being warned about, the warning arrives through this app\'s warning list.'**
  String get airQualityNoWarning;

  /// No description provided for @airQualityAdvice.
  ///
  /// In en, this message translates to:
  /// **'What the UBA recommends at each class is published by the UBA itself. This app gives no health advice of its own.'**
  String get airQualityAdvice;

  /// No description provided for @airQualitySource.
  ///
  /// In en, this message translates to:
  /// **'Source: Umweltbundesamt air quality index. The classification and thresholds are the UBA\'s.'**
  String get airQualitySource;

  /// No description provided for @roadClosureTitle.
  ///
  /// In en, this message translates to:
  /// **'Motorway closures'**
  String get roadClosureTitle;

  /// No description provided for @roadClosureEntryHint.
  ///
  /// In en, this message translates to:
  /// **'What is shut on the motorways you watch.'**
  String get roadClosureEntryHint;

  /// No description provided for @roadClosureNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'No motorway chosen yet'**
  String get roadClosureNoneChosen;

  /// No description provided for @roadClosureWhy.
  ///
  /// In en, this message translates to:
  /// **'When a region has to be left, “which way is open” is a more concrete question than any checklist. The service answers per road — so the roads that matter are named once.'**
  String get roadClosureWhy;

  /// No description provided for @roadClosureChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose motorways'**
  String get roadClosureChoose;

  /// No description provided for @roadClosureChange.
  ///
  /// In en, this message translates to:
  /// **'Change the selection'**
  String get roadClosureChange;

  /// No description provided for @roadClosureDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get roadClosureDone;

  /// No description provided for @roadClosureRefresh.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get roadClosureRefresh;

  /// No description provided for @roadClosureLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The traffic reports cannot be reached right now.'**
  String get roadClosureLoadFailed;

  /// No description provided for @roadClosureNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get roadClosureNow;

  /// No description provided for @roadClosureNothingNow.
  ///
  /// In en, this message translates to:
  /// **'No closure and no warning at the moment.'**
  String get roadClosureNothingNow;

  /// No description provided for @roadClosureLater.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get roadClosureLater;

  /// No description provided for @roadClosureBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get roadClosureBlocked;

  /// No description provided for @roadClosureFrom.
  ///
  /// In en, this message translates to:
  /// **'From {when}'**
  String roadClosureFrom(String when);

  /// No description provided for @roadClosureSource.
  ///
  /// In en, this message translates to:
  /// **'Source: Autobahn GmbH des Bundes open traffic data. Roadworks that block nothing are not listed.'**
  String get roadClosureSource;

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

  /// No description provided for @caloriesTotalHint.
  ///
  /// In en, this message translates to:
  /// **'Comes to {total} kcal in stock.'**
  String caloriesTotalHint(Object total);

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

  /// No description provided for @checklistKindPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get checklistKindPreparation;

  /// No description provided for @checklistKindResponse.
  ///
  /// In en, this message translates to:
  /// **'When it happens'**
  String get checklistKindResponse;

  /// No description provided for @checklistKindPreparationIntro.
  ///
  /// In en, this message translates to:
  /// **'What has to be there before anything happens.'**
  String get checklistKindPreparationIntro;

  /// No description provided for @checklistKindResponseIntro.
  ///
  /// In en, this message translates to:
  /// **'What to do while it is happening.'**
  String get checklistKindResponseIntro;

  /// No description provided for @checklistKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind of list'**
  String get checklistKindLabel;

  /// No description provided for @checklistKindEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing in this part yet.'**
  String get checklistKindEmpty;

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

  /// No description provided for @shelterLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Marker guide'**
  String get shelterLegendTitle;

  /// No description provided for @shelterLegendSummary.
  ///
  /// In en, this message translates to:
  /// **'Green {green} · Yellow {yellow} · Red {red}'**
  String shelterLegendSummary(int green, int yellow, int red);

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

  /// No description provided for @emergencyCardDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get emergencyCardDoctors;

  /// No description provided for @emergencyCardDoctorAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a doctor'**
  String get emergencyCardDoctorAdd;

  /// No description provided for @emergencyCardSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Speciality'**
  String get emergencyCardSpecialty;

  /// No description provided for @emergencyCardSpecialtyHint.
  ///
  /// In en, this message translates to:
  /// **'GP, cardiologist'**
  String get emergencyCardSpecialtyHint;

  /// No description provided for @emergencyCardContacts.
  ///
  /// In en, this message translates to:
  /// **'Who to call about this person'**
  String get emergencyCardContacts;

  /// No description provided for @emergencyCardContactAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a contact'**
  String get emergencyCardContactAdd;

  /// No description provided for @emergencyCardRelation.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get emergencyCardRelation;

  /// No description provided for @emergencyCardRelationHint.
  ///
  /// In en, this message translates to:
  /// **'Partner, son, neighbour'**
  String get emergencyCardRelationHint;

  /// No description provided for @emergencyCardPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get emergencyCardPhone;

  /// No description provided for @emergencyCardPersonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove entry'**
  String get emergencyCardPersonRemove;

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

  /// No description provided for @downloadResumingLabel.
  ///
  /// In en, this message translates to:
  /// **'Connection dropped — resuming…'**
  String get downloadResumingLabel;

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

  /// No description provided for @distressTitle.
  ///
  /// In en, this message translates to:
  /// **'Distress signal'**
  String get distressTitle;

  /// No description provided for @distressIntro.
  ///
  /// In en, this message translates to:
  /// **'For when there is no network left but somebody might still see you. The screen flashes in a rhythm rescuers know — hold it up, towards the slope or the valley.'**
  String get distressIntro;

  /// No description provided for @distressBattery.
  ///
  /// In en, this message translates to:
  /// **'This costs brightness, and so battery. Switch it on when somebody might be there, not on the off chance.'**
  String get distressBattery;

  /// No description provided for @distressStart.
  ///
  /// In en, this message translates to:
  /// **'Start signalling'**
  String get distressStart;

  /// No description provided for @distressStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get distressStop;

  /// No description provided for @distressPause.
  ///
  /// In en, this message translates to:
  /// **'Pause — this is where the answer goes'**
  String get distressPause;

  /// No description provided for @distressFlash.
  ///
  /// In en, this message translates to:
  /// **'Signal {number} of {total}'**
  String distressFlash(int number, int total);

  /// No description provided for @distressSos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get distressSos;

  /// No description provided for @distressSosHint.
  ///
  /// In en, this message translates to:
  /// **'Three short, three long, three short — as one character, not as three letters.'**
  String get distressSosHint;

  /// No description provided for @distressAlpine.
  ///
  /// In en, this message translates to:
  /// **'Alpine distress signal'**
  String get distressAlpine;

  /// No description provided for @distressAlpineHint.
  ///
  /// In en, this message translates to:
  /// **'Six signals inside a minute, then a minute of nothing, then again. The pause is part of it: it tells the signal apart from somebody walking about with a torch.'**
  String get distressAlpineHint;

  /// No description provided for @distressAlpineAnswer.
  ///
  /// In en, this message translates to:
  /// **'Answer to a distress signal'**
  String get distressAlpineAnswer;

  /// No description provided for @distressAlpineAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Three signals inside a minute, into the other one’s pause: I have seen you.'**
  String get distressAlpineAnswerHint;

  /// No description provided for @myPositionAction.
  ///
  /// In en, this message translates to:
  /// **'Pass on my position'**
  String get myPositionAction;

  /// No description provided for @myPositionTitle.
  ///
  /// In en, this message translates to:
  /// **'My position'**
  String get myPositionTitle;

  /// No description provided for @myPositionIntro.
  ///
  /// In en, this message translates to:
  /// **'Read out whatever is asked for. A control room usually wants degrees and minutes, and reads them back.'**
  String get myPositionIntro;

  /// No description provided for @myPositionOffline.
  ///
  /// In en, this message translates to:
  /// **'The app works this out itself. It needs no network — which is when it is wanted.'**
  String get myPositionOffline;

  /// No description provided for @myPositionMeasure.
  ///
  /// In en, this message translates to:
  /// **'Measure again'**
  String get myPositionMeasure;

  /// No description provided for @myPositionCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied.'**
  String get myPositionCopied;

  /// No description provided for @myPositionAccuracy.
  ///
  /// In en, this message translates to:
  /// **'The receiver reports ±{metres} m.'**
  String myPositionAccuracy(int metres);

  /// No description provided for @myPositionAccuracyPoor.
  ///
  /// In en, this message translates to:
  /// **'That will not reach a house number. Measure again under open sky, and tell the control room how rough it is.'**
  String get myPositionAccuracyPoor;

  /// No description provided for @myPositionDms.
  ///
  /// In en, this message translates to:
  /// **'Degrees, minutes, seconds'**
  String get myPositionDms;

  /// No description provided for @myPositionDmsHint.
  ///
  /// In en, this message translates to:
  /// **'What a control room asks for on the telephone — and what survives being read aloud and written down.'**
  String get myPositionDmsHint;

  /// No description provided for @myPositionUtm.
  ///
  /// In en, this message translates to:
  /// **'UTM'**
  String get myPositionUtm;

  /// No description provided for @myPositionUtmHint.
  ///
  /// In en, this message translates to:
  /// **'Metres on a grid. Emergency services and the technical relief service work in these.'**
  String get myPositionUtmHint;

  /// No description provided for @myPositionMgrs.
  ///
  /// In en, this message translates to:
  /// **'MGRS'**
  String get myPositionMgrs;

  /// No description provided for @myPositionMgrsHint.
  ///
  /// In en, this message translates to:
  /// **'The same grid as one short reference, the way a gridded map labels it.'**
  String get myPositionMgrsHint;

  /// No description provided for @myPositionPlusCode.
  ///
  /// In en, this message translates to:
  /// **'Plus Code'**
  String get myPositionPlusCode;

  /// No description provided for @myPositionPlusCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Ten characters and no map at all, for somebody who is going to type it in.'**
  String get myPositionPlusCodeHint;

  /// No description provided for @myPositionDecimal.
  ///
  /// In en, this message translates to:
  /// **'Decimal degrees'**
  String get myPositionDecimal;

  /// No description provided for @myPositionDecimalHint.
  ///
  /// In en, this message translates to:
  /// **'What goes into a map app.'**
  String get myPositionDecimalHint;

  /// No description provided for @mapMyLocationAction.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocationAction;

  /// No description provided for @mapCoverageMissing.
  ///
  /// In en, this message translates to:
  /// **'The offline map does not reach this far. Nothing was ever downloaded for this area.'**
  String get mapCoverageMissing;

  /// No description provided for @mapCoverageIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The offline map only covers part of this view — roughly {present} tiles out of {total}. The rest stays empty because it was never downloaded.'**
  String mapCoverageIncomplete(int present, int total);

  /// No description provided for @mapCoverageUseOnline.
  ///
  /// In en, this message translates to:
  /// **'Use the online map'**
  String get mapCoverageUseOnline;

  /// No description provided for @mapCoverageUseOffline.
  ///
  /// In en, this message translates to:
  /// **'Use the offline map'**
  String get mapCoverageUseOffline;

  /// No description provided for @mapTilesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Some tiles never arrived from the tile server. What is missing is the connection, not the app.'**
  String get mapTilesUnavailable;

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
  /// **'Per 100 g each — or per 100 ml for drinks — exactly as the label states them. Scanning a barcode fills in what it says; the app does the multiplying.'**
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

  /// No description provided for @knowledgeLibraryTitle.
  ///
  /// In en, this message translates to:
  /// **'Your archives'**
  String get knowledgeLibraryTitle;

  /// No description provided for @knowledgeLibraryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archives left in the library.'**
  String get knowledgeLibraryEmpty;

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

  /// No description provided for @emergencyContactEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get emergencyContactEdit;

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
  /// **'PMR446, Freenet, CB and amateur radio: frequencies, rules and guidance'**
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

  /// No description provided for @shelterOverpassBusyMessage.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap/Overpass is busy right now (request limit). Try again in a few seconds.'**
  String get shelterOverpassBusyMessage;

  /// No description provided for @shelterSourceFailureReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String shelterSourceFailureReason(String reason);

  /// No description provided for @kiwixLanguageSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search language'**
  String get kiwixLanguageSearchHint;

  /// No description provided for @kiwixLanguageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} languages'**
  String kiwixLanguageCount(int count);

  /// No description provided for @kiwixLanguageNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No language found.'**
  String get kiwixLanguageNoMatch;

  /// No description provided for @kiwixLanguageArchives.
  ///
  /// In en, this message translates to:
  /// **'{count} archives'**
  String kiwixLanguageArchives(int count);

  /// No description provided for @downloadRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min left'**
  String downloadRemainingHours(int hours, int minutes);

  /// No description provided for @downloadRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min left'**
  String downloadRemainingMinutes(int minutes);

  /// No description provided for @downloadRemainingSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s left'**
  String downloadRemainingSeconds(int seconds);

  /// No description provided for @articleLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The page could not be loaded.'**
  String get articleLoadFailed;

  /// No description provided for @articleHttpStatus.
  ///
  /// In en, this message translates to:
  /// **'The archive answered with {status}.'**
  String articleHttpStatus(String status);

  /// No description provided for @articleReload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get articleReload;

  /// No description provided for @knowledgeArchiveNoCover.
  ///
  /// In en, this message translates to:
  /// **'No cover in this archive'**
  String get knowledgeArchiveNoCover;

  /// No description provided for @radiationTitle.
  ///
  /// In en, this message translates to:
  /// **'Gamma radiation'**
  String get radiationTitle;

  /// No description provided for @radiationEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Ambient dose rate at a BfS monitoring station'**
  String get radiationEntryHint;

  /// No description provided for @radiationNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'No station chosen yet'**
  String get radiationNoneChosen;

  /// No description provided for @radiationChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a station'**
  String get radiationChoose;

  /// No description provided for @radiationChange.
  ///
  /// In en, this message translates to:
  /// **'Another station'**
  String get radiationChange;

  /// No description provided for @radiationRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get radiationRefresh;

  /// No description provided for @radiationSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Place or postal code'**
  String get radiationSearchHint;

  /// No description provided for @radiationSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No station found.'**
  String get radiationSearchEmpty;

  /// No description provided for @radiationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The readings could not be loaded.'**
  String get radiationLoadFailed;

  /// No description provided for @radiationOffline.
  ///
  /// In en, this message translates to:
  /// **'Last known value. The BfS service could not be reached.'**
  String get radiationOffline;

  /// No description provided for @radiationStale.
  ///
  /// In en, this message translates to:
  /// **'More than two hours old. The network reports hourly, so this is a missing connection and not a standing value.'**
  String get radiationStale;

  /// No description provided for @radiationUnvalidated.
  ///
  /// In en, this message translates to:
  /// **'Unchecked raw value. BfS publishes hourly readings unchecked at first; a technical fault looks like a measurement.'**
  String get radiationUnvalidated;

  /// No description provided for @radiationMeasuredAt.
  ///
  /// In en, this message translates to:
  /// **'Measured until {time}'**
  String radiationMeasuredAt(String time);

  /// No description provided for @radiationHeight.
  ///
  /// In en, this message translates to:
  /// **'{metres} m above sea level'**
  String radiationHeight(String metres);

  /// No description provided for @radiationPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal code {code}'**
  String radiationPostalCode(String code);

  /// No description provided for @radiationBaseline.
  ///
  /// In en, this message translates to:
  /// **'Usual at this station: {value} µSv/h'**
  String radiationBaseline(String value);

  /// No description provided for @radiationNoBaseline.
  ///
  /// In en, this message translates to:
  /// **'This station has no baseline of its own yet, so the reading is judged against the national natural range of {floor} to {ceiling} µSv/h, which is coarser — in the Black Forest 0.16 µSv/h is perfectly ordinary.'**
  String radiationNoBaseline(String floor, String ceiling);

  /// No description provided for @radiationSplit.
  ///
  /// In en, this message translates to:
  /// **'Of which {terrestrial} µSv/h from the ground and {cosmic} µSv/h from space'**
  String radiationSplit(String terrestrial, String cosmic);

  /// No description provided for @radiationBandOrdinary.
  ///
  /// In en, this message translates to:
  /// **'Ordinary for this station'**
  String get radiationBandOrdinary;

  /// No description provided for @radiationBandWeather.
  ///
  /// In en, this message translates to:
  /// **'Raised — which is the normal case after rain'**
  String get radiationBandWeather;

  /// No description provided for @radiationBandUnusual.
  ///
  /// In en, this message translates to:
  /// **'Beyond what weather explains'**
  String get radiationBandUnusual;

  /// No description provided for @radiationBandUnknown.
  ///
  /// In en, this message translates to:
  /// **'Above the natural range, with no baseline of its own'**
  String get radiationBandUnknown;

  /// No description provided for @radiationWeatherExplained.
  ///
  /// In en, this message translates to:
  /// **'Rain washes radon decay products out of the air and lifts the reading by up to a factor of three for a few hours. This is harmless and falls back on its own; the half-life is about 30 minutes. Fresh snow does the same, while lying snow shields the ground and lowers the reading.'**
  String get radiationWeatherExplained;

  /// No description provided for @radiationUnusualExplained.
  ///
  /// In en, this message translates to:
  /// **'Per BfS, a radiological event only comes into question when a clearly raised reading persists for a day or longer or goes beyond that factor of three — or when the probe is faulty. A single value is not a warning: an official warning would arrive through this app’s warnings.'**
  String get radiationUnusualExplained;

  /// No description provided for @radiationNoWarning.
  ///
  /// In en, this message translates to:
  /// **'This is the reading and its context, not a warning. Official warnings arrive through this app’s warnings.'**
  String get radiationNoWarning;

  /// No description provided for @radiationSource.
  ///
  /// In en, this message translates to:
  /// **'Source: Bundesamt für Strahlenschutz (BfS), ODL network. Datenlizenz Deutschland – Namensnennung 2.0.'**
  String get radiationSource;

  /// No description provided for @fireDangerTitle.
  ///
  /// In en, this message translates to:
  /// **'Forest fire danger'**
  String get fireDangerTitle;

  /// No description provided for @fireDangerEntryHint.
  ///
  /// In en, this message translates to:
  /// **'The DWD forest fire danger index for one station'**
  String get fireDangerEntryHint;

  /// No description provided for @fireDangerNoneChosen.
  ///
  /// In en, this message translates to:
  /// **'No station chosen yet'**
  String get fireDangerNoneChosen;

  /// No description provided for @fireDangerChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a station'**
  String get fireDangerChoose;

  /// No description provided for @fireDangerChange.
  ///
  /// In en, this message translates to:
  /// **'Another station'**
  String get fireDangerChange;

  /// No description provided for @fireDangerRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get fireDangerRefresh;

  /// No description provided for @fireDangerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Place or state'**
  String get fireDangerSearchHint;

  /// No description provided for @fireDangerSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No station found.'**
  String get fireDangerSearchEmpty;

  /// No description provided for @fireDangerLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'The forest fire danger index could not be loaded.'**
  String get fireDangerLoadFailed;

  /// No description provided for @fireDangerOffline.
  ///
  /// In en, this message translates to:
  /// **'Last known state. The DWD server could not be reached.'**
  String get fireDangerOffline;

  /// No description provided for @fireDangerStale.
  ///
  /// In en, this message translates to:
  /// **'This is from {date} and not from today. The DWD issues the index only during the fire season, roughly March to October — outside it nothing new arrives.'**
  String fireDangerStale(String date);

  /// No description provided for @fireDangerStep.
  ///
  /// In en, this message translates to:
  /// **'Level {step} of 5'**
  String fireDangerStep(int step);

  /// No description provided for @fireDangerIssuedFor.
  ///
  /// In en, this message translates to:
  /// **'Issued for {date}'**
  String fireDangerIssuedFor(String date);

  /// No description provided for @fireDangerLevel1.
  ///
  /// In en, this message translates to:
  /// **'Very low danger'**
  String get fireDangerLevel1;

  /// No description provided for @fireDangerLevel2.
  ///
  /// In en, this message translates to:
  /// **'Low danger'**
  String get fireDangerLevel2;

  /// No description provided for @fireDangerLevel3.
  ///
  /// In en, this message translates to:
  /// **'Moderate danger'**
  String get fireDangerLevel3;

  /// No description provided for @fireDangerLevel4.
  ///
  /// In en, this message translates to:
  /// **'High danger'**
  String get fireDangerLevel4;

  /// No description provided for @fireDangerLevel5.
  ///
  /// In en, this message translates to:
  /// **'Very high danger'**
  String get fireDangerLevel5;

  /// No description provided for @fireDangerAhead.
  ///
  /// In en, this message translates to:
  /// **'The days ahead'**
  String get fireDangerAhead;

  /// No description provided for @fireDangerPeak.
  ///
  /// In en, this message translates to:
  /// **'Rises to level {step} in {days} days'**
  String fireDangerPeak(int step, int days);

  /// No description provided for @fireDangerPeakTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Rises to level {step} tomorrow'**
  String fireDangerPeakTomorrow(int step);

  /// No description provided for @fireDangerToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get fireDangerToday;

  /// No description provided for @fireDangerInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String fireDangerInDays(int days);

  /// No description provided for @fireDangerTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get fireDangerTomorrow;

  /// No description provided for @fireDangerNoWarning.
  ///
  /// In en, this message translates to:
  /// **'The index describes the meteorological potential for forest fire. It is not a warning and not a ban on entering a forest; bans are issued by the states, and official warnings arrive through this app’s warnings.'**
  String get fireDangerNoWarning;

  /// No description provided for @fireDangerSource.
  ///
  /// In en, this message translates to:
  /// **'Source: Deutscher Wetterdienst (DWD), forest fire danger index WBI.'**
  String get fireDangerSource;

  /// No description provided for @fireDangerState.
  ///
  /// In en, this message translates to:
  /// **'State {state}'**
  String fireDangerState(String state);

  /// No description provided for @nearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get nearbyTitle;

  /// No description provided for @nearbyEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy, water, fuel — from the downloaded map, without a network.'**
  String get nearbyEntryHint;

  /// No description provided for @nearbySearchFrom.
  ///
  /// In en, this message translates to:
  /// **'Searching around {place}'**
  String nearbySearchFrom(String place);

  /// No description provided for @nearbyMapCentre.
  ///
  /// In en, this message translates to:
  /// **'the map centre'**
  String get nearbyMapCentre;

  /// No description provided for @nearbyMyPosition.
  ///
  /// In en, this message translates to:
  /// **'your position'**
  String get nearbyMyPosition;

  /// No description provided for @nearbyUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get nearbyUseMyLocation;

  /// No description provided for @nearbyNoCentre.
  ///
  /// In en, this message translates to:
  /// **'No point chosen yet'**
  String get nearbyNoCentre;

  /// No description provided for @nearbyNoCentreWhy.
  ///
  /// In en, this message translates to:
  /// **'This search needs somewhere to start from. Take your position — or open the map, move it to the area and search from there.'**
  String get nearbyNoCentreWhy;

  /// No description provided for @nearbyOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open the map'**
  String get nearbyOpenMap;

  /// No description provided for @nearbyRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get nearbyRadius;

  /// No description provided for @nearbyRadiusKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String nearbyRadiusKm(int km);

  /// No description provided for @nearbySearching.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} tiles read'**
  String nearbySearching(int done, int total);

  /// No description provided for @nearbyNothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get nearbyNothingFound;

  /// No description provided for @nearbyNothingFoundWhy.
  ///
  /// In en, this message translates to:
  /// **'The map carries none of these points within this radius. A wider radius may help — or the area was only downloaded coarsely.'**
  String get nearbyNothingFoundWhy;

  /// No description provided for @nearbyNoArchive.
  ///
  /// In en, this message translates to:
  /// **'No map downloaded'**
  String get nearbyNoArchive;

  /// No description provided for @nearbyNoArchiveWhy.
  ///
  /// In en, this message translates to:
  /// **'This search reads the map that is on this device. Without a downloaded map there is nothing to search.'**
  String get nearbyNoArchiveWhy;

  /// No description provided for @nearbyDownloadMap.
  ///
  /// In en, this message translates to:
  /// **'Download a map'**
  String get nearbyDownloadMap;

  /// No description provided for @nearbyTooShallow.
  ///
  /// In en, this message translates to:
  /// **'The map does not go deep enough'**
  String get nearbyTooShallow;

  /// No description provided for @nearbyTooShallowWhy.
  ///
  /// In en, this message translates to:
  /// **'Individual points first appear at zoom level 14. This archive stops short of it: it draws a perfectly good map and holds not one pharmacy. Download the area again at a greater level of detail.'**
  String get nearbyTooShallowWhy;

  /// No description provided for @nearbyOutsideArchive.
  ///
  /// In en, this message translates to:
  /// **'Outside the downloaded area'**
  String get nearbyOutsideArchive;

  /// No description provided for @nearbyOutsideArchiveWhy.
  ///
  /// In en, this message translates to:
  /// **'This point is not inside what was downloaded. The map knows nothing here — including that anything is missing.'**
  String get nearbyOutsideArchiveWhy;

  /// No description provided for @nearbyCaveats.
  ///
  /// In en, this message translates to:
  /// **'Only what was downloaded and what volunteers entered into OpenStreetMap can be found. A point being on the map is no promise that it is open, stocked or staffed.'**
  String get nearbyCaveats;

  /// No description provided for @nearbyShelterNote.
  ///
  /// In en, this message translates to:
  /// **'In OpenStreetMap a “shelter” is nearly always a bus shelter or a hiking hut, not a protective shelter. That is why the kind is not listed here.'**
  String get nearbyShelterNote;

  /// No description provided for @nearbyKindWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get nearbyKindWater;

  /// No description provided for @nearbyKindHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get nearbyKindHealth;

  /// No description provided for @nearbyKindFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get nearbyKindFood;

  /// No description provided for @nearbyKindFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel and power'**
  String get nearbyKindFuel;

  /// No description provided for @nearbyKindHardware.
  ///
  /// In en, this message translates to:
  /// **'Tools and materials'**
  String get nearbyKindHardware;

  /// No description provided for @nearbyKindHelp.
  ///
  /// In en, this message translates to:
  /// **'Help and authorities'**
  String get nearbyKindHelp;

  /// No description provided for @poiDrinkingWater.
  ///
  /// In en, this message translates to:
  /// **'Drinking water'**
  String get poiDrinkingWater;

  /// No description provided for @poiPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get poiPharmacy;

  /// No description provided for @poiHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get poiHospital;

  /// No description provided for @poiClinic.
  ///
  /// In en, this message translates to:
  /// **'Clinic'**
  String get poiClinic;

  /// No description provided for @poiDoctors.
  ///
  /// In en, this message translates to:
  /// **'Doctor\'s surgery'**
  String get poiDoctors;

  /// No description provided for @poiSupermarket.
  ///
  /// In en, this message translates to:
  /// **'Supermarket'**
  String get poiSupermarket;

  /// No description provided for @poiConvenience.
  ///
  /// In en, this message translates to:
  /// **'Convenience store'**
  String get poiConvenience;

  /// No description provided for @poiBakery.
  ///
  /// In en, this message translates to:
  /// **'Bakery'**
  String get poiBakery;

  /// No description provided for @poiButcher.
  ///
  /// In en, this message translates to:
  /// **'Butcher'**
  String get poiButcher;

  /// No description provided for @poiGreengrocer.
  ///
  /// In en, this message translates to:
  /// **'Greengrocer'**
  String get poiGreengrocer;

  /// No description provided for @poiMarketplace.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get poiMarketplace;

  /// No description provided for @poiDeli.
  ///
  /// In en, this message translates to:
  /// **'Delicatessen'**
  String get poiDeli;

  /// No description provided for @poiFuel.
  ///
  /// In en, this message translates to:
  /// **'Filling station'**
  String get poiFuel;

  /// No description provided for @poiChargingStation.
  ///
  /// In en, this message translates to:
  /// **'Charging point'**
  String get poiChargingStation;

  /// No description provided for @poiDoityourself.
  ///
  /// In en, this message translates to:
  /// **'DIY store'**
  String get poiDoityourself;

  /// No description provided for @poiHardware.
  ///
  /// In en, this message translates to:
  /// **'Hardware shop'**
  String get poiHardware;

  /// No description provided for @poiFireStation.
  ///
  /// In en, this message translates to:
  /// **'Fire station'**
  String get poiFireStation;

  /// No description provided for @poiPolice.
  ///
  /// In en, this message translates to:
  /// **'Police'**
  String get poiPolice;

  /// No description provided for @poiTownhall.
  ///
  /// In en, this message translates to:
  /// **'Town hall'**
  String get poiTownhall;

  /// No description provided for @poiCommunityCentre.
  ///
  /// In en, this message translates to:
  /// **'Community centre'**
  String get poiCommunityCentre;

  /// No description provided for @daylightTitle.
  ///
  /// In en, this message translates to:
  /// **'Daylight and moon'**
  String get daylightTitle;

  /// No description provided for @daylightEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Sun, twilight and moon — worked out on the device, without a network.'**
  String get daylightEntryHint;

  /// No description provided for @daylightNoPlace.
  ///
  /// In en, this message translates to:
  /// **'No place set yet'**
  String get daylightNoPlace;

  /// No description provided for @daylightNoPlaceWhy.
  ///
  /// In en, this message translates to:
  /// **'Where the sun and moon stand depends on where you are. Set the place once — it is remembered and never needed again.'**
  String get daylightNoPlaceWhy;

  /// No description provided for @daylightSetPlace.
  ///
  /// In en, this message translates to:
  /// **'Set the place'**
  String get daylightSetPlace;

  /// No description provided for @daylightChangePlace.
  ///
  /// In en, this message translates to:
  /// **'Change the place'**
  String get daylightChangePlace;

  /// No description provided for @daylightCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get daylightCoordinates;

  /// No description provided for @daylightCoordinatesHint.
  ///
  /// In en, this message translates to:
  /// **'52.2689, 10.5268'**
  String get daylightCoordinatesHint;

  /// No description provided for @daylightCoordinatesBad.
  ///
  /// In en, this message translates to:
  /// **'Two numbers, latitude and longitude — for example 52.2689, 10.5268.'**
  String get daylightCoordinatesBad;

  /// No description provided for @daylightPlaceName.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get daylightPlaceName;

  /// No description provided for @daylightToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get daylightToday;

  /// No description provided for @daylightTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get daylightTomorrow;

  /// No description provided for @daylightSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get daylightSunrise;

  /// No description provided for @daylightSunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get daylightSunset;

  /// No description provided for @daylightSolarNoon.
  ///
  /// In en, this message translates to:
  /// **'Solar noon'**
  String get daylightSolarNoon;

  /// No description provided for @daylightCivilDawn.
  ///
  /// In en, this message translates to:
  /// **'First light'**
  String get daylightCivilDawn;

  /// No description provided for @daylightCivilDusk.
  ///
  /// In en, this message translates to:
  /// **'Last light'**
  String get daylightCivilDusk;

  /// No description provided for @daylightNauticalDawn.
  ///
  /// In en, this message translates to:
  /// **'Twilight begins'**
  String get daylightNauticalDawn;

  /// No description provided for @daylightNauticalDusk.
  ///
  /// In en, this message translates to:
  /// **'Twilight ends'**
  String get daylightNauticalDusk;

  /// No description provided for @daylightDayLength.
  ///
  /// In en, this message translates to:
  /// **'Day length {duration}'**
  String daylightDayLength(String duration);

  /// No description provided for @daylightEveningTwilight.
  ///
  /// In en, this message translates to:
  /// **'Then {duration} of usable light'**
  String daylightEveningTwilight(String duration);

  /// No description provided for @daylightAlwaysUp.
  ///
  /// In en, this message translates to:
  /// **'The sun does not set today.'**
  String get daylightAlwaysUp;

  /// No description provided for @daylightAlwaysDown.
  ///
  /// In en, this message translates to:
  /// **'The sun does not rise today.'**
  String get daylightAlwaysDown;

  /// No description provided for @daylightMoon.
  ///
  /// In en, this message translates to:
  /// **'Moon'**
  String get daylightMoon;

  /// No description provided for @daylightMoonrise.
  ///
  /// In en, this message translates to:
  /// **'Moonrise'**
  String get daylightMoonrise;

  /// No description provided for @daylightMoonset.
  ///
  /// In en, this message translates to:
  /// **'Moonset'**
  String get daylightMoonset;

  /// No description provided for @daylightMoonIllumination.
  ///
  /// In en, this message translates to:
  /// **'{percent} % lit'**
  String daylightMoonIllumination(int percent);

  /// No description provided for @daylightMoonUpAllDay.
  ///
  /// In en, this message translates to:
  /// **'The moon stays above the horizon all day.'**
  String get daylightMoonUpAllDay;

  /// No description provided for @daylightMoonDownAllDay.
  ///
  /// In en, this message translates to:
  /// **'The moon does not come above the horizon today.'**
  String get daylightMoonDownAllDay;

  /// No description provided for @daylightMoonNoRise.
  ///
  /// In en, this message translates to:
  /// **'No moonrise today — the moon rises about 50 minutes later each day.'**
  String get daylightMoonNoRise;

  /// No description provided for @daylightMoonNoSet.
  ///
  /// In en, this message translates to:
  /// **'No moonset today.'**
  String get daylightMoonNoSet;

  /// No description provided for @daylightWhy.
  ///
  /// In en, this message translates to:
  /// **'Without a light switch the sun is the working day, and whether the moon is up decides whether moving at night is possible. Both are questions with exact answers, and neither can be looked up without a network unless the answer is already in the device.'**
  String get daylightWhy;

  /// No description provided for @daylightAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Everything here is computed on the device, nothing is fetched. Checked against the US Naval Observatory\'s tables: over 112 compared times, sun and moon are at most one minute out. The times assume a clear horizon — hills, trees and buildings shift them.'**
  String get daylightAccuracy;

  /// No description provided for @moonPhaseNew.
  ///
  /// In en, this message translates to:
  /// **'New moon'**
  String get moonPhaseNew;

  /// No description provided for @moonPhaseWaxingCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waxing crescent'**
  String get moonPhaseWaxingCrescent;

  /// No description provided for @moonPhaseFirstQuarter.
  ///
  /// In en, this message translates to:
  /// **'First quarter'**
  String get moonPhaseFirstQuarter;

  /// No description provided for @moonPhaseWaxingGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waxing gibbous'**
  String get moonPhaseWaxingGibbous;

  /// No description provided for @moonPhaseFull.
  ///
  /// In en, this message translates to:
  /// **'Full moon'**
  String get moonPhaseFull;

  /// No description provided for @moonPhaseWaningGibbous.
  ///
  /// In en, this message translates to:
  /// **'Waning gibbous'**
  String get moonPhaseWaningGibbous;

  /// No description provided for @moonPhaseLastQuarter.
  ///
  /// In en, this message translates to:
  /// **'Last quarter'**
  String get moonPhaseLastQuarter;

  /// No description provided for @moonPhaseWaningCrescent.
  ///
  /// In en, this message translates to:
  /// **'Waning crescent'**
  String get moonPhaseWaningCrescent;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @radioEverydayTitle.
  ///
  /// In en, this message translates to:
  /// **'Licence-free radio: PMR446 and Freenet'**
  String get radioEverydayTitle;

  /// No description provided for @radioEverydayIntro.
  ///
  /// In en, this message translates to:
  /// **'The two bands many households actually own. They need no registration and no examination — and no infrastructure: device to device, one to a few kilometres. That is exactly why they belong here beside CB and amateur radio.'**
  String get radioEverydayIntro;

  /// No description provided for @radioPmrTitle.
  ///
  /// In en, this message translates to:
  /// **'PMR446'**
  String get radioPmrTitle;

  /// No description provided for @radioPmrRange.
  ///
  /// In en, this message translates to:
  /// **'446.0–446.2 MHz'**
  String get radioPmrRange;

  /// No description provided for @radioPmrChannels.
  ///
  /// In en, this message translates to:
  /// **'16 analogue channels, 12.5 kHz spacing'**
  String get radioPmrChannels;

  /// No description provided for @radioPmrPower.
  ///
  /// In en, this message translates to:
  /// **'At most 0.5 W ERP'**
  String get radioPmrPower;

  /// No description provided for @radioPmrAntenna.
  ///
  /// In en, this message translates to:
  /// **'Built-in antennas only'**
  String get radioPmrAntenna;

  /// No description provided for @radioPmrPeerToPeer.
  ///
  /// In en, this message translates to:
  /// **'Device to device only. No fixed station, no repeater, no linking into a network.'**
  String get radioPmrPeerToPeer;

  /// No description provided for @radioPmrSource.
  ///
  /// In en, this message translates to:
  /// **'Bundesnetzagentur, Vfg. 91/2025 (collective allocation for short-range devices), band 83. Replaces Vfg. 46/2020, valid until 31 December 2035. The channel plan itself is in the harmonised standard, not in the allocation.'**
  String get radioPmrSource;

  /// No description provided for @radioFreenetTitle.
  ///
  /// In en, this message translates to:
  /// **'Freenet Deutschland'**
  String get radioFreenetTitle;

  /// No description provided for @radioFreenetRange.
  ///
  /// In en, this message translates to:
  /// **'149.01875–149.11875 MHz'**
  String get radioFreenetRange;

  /// No description provided for @radioFreenetAnalogue.
  ///
  /// In en, this message translates to:
  /// **'6 channels at 12.5 kHz, analogue or digital'**
  String get radioFreenetAnalogue;

  /// No description provided for @radioFreenetDigital.
  ///
  /// In en, this message translates to:
  /// **'Plus 12 channels at 6.25 kHz, digital only'**
  String get radioFreenetDigital;

  /// No description provided for @radioFreenetPower.
  ///
  /// In en, this message translates to:
  /// **'At most 1 W ERP. Within 10 km of the Belgian and Polish borders, only 0.5 W.'**
  String get radioFreenetPower;

  /// No description provided for @radioFreenetHandheld.
  ///
  /// In en, this message translates to:
  /// **'Handheld radios with their own power supply, operable in one hand. Fixed stations are not permitted.'**
  String get radioFreenetHandheld;

  /// No description provided for @radioFreenetAntenna.
  ///
  /// In en, this message translates to:
  /// **'Only the built-in antenna or an exchangeable one on the radio itself. An antenna on a coaxial cable or a mast is not allowed.'**
  String get radioFreenetAntenna;

  /// No description provided for @radioFreenetPeerToPeer.
  ///
  /// In en, this message translates to:
  /// **'Device to device only. No repeater, no relay, no gateway to the internet.'**
  String get radioFreenetPeerToPeer;

  /// No description provided for @radioFreenetDuration.
  ///
  /// In en, this message translates to:
  /// **'No continuous transmission. The standard cuts off after 180 seconds; below that too, transmit only as long as needed.'**
  String get radioFreenetDuration;

  /// No description provided for @radioFreenetGermanyOnly.
  ///
  /// In en, this message translates to:
  /// **'This allocation applies in Germany only.'**
  String get radioFreenetGermanyOnly;

  /// No description provided for @radioFreenetExtras.
  ///
  /// In en, this message translates to:
  /// **'VOX and CTCSS are expressly permitted.'**
  String get radioFreenetExtras;

  /// No description provided for @radioFreenetSource.
  ///
  /// In en, this message translates to:
  /// **'Bundesnetzagentur, Vfg. 45/2025, corrected by Mitt. 193/2025. In force since 1 October 2025, valid until 30 September 2035; replaces Vfg. 60/2019.'**
  String get radioFreenetSource;

  /// No description provided for @radioCallingChannelTitle.
  ///
  /// In en, this message translates to:
  /// **'There is no official calling channel'**
  String get radioCallingChannelTitle;

  /// No description provided for @radioCallingChannelNone.
  ///
  /// In en, this message translates to:
  /// **'Neither PMR446 nor Freenet has an emergency or calling channel laid down by the regulator. What exists are conventions among operators — and they are not uniform.'**
  String get radioCallingChannelNone;

  /// No description provided for @radioCallingChannelThree.
  ///
  /// In en, this message translates to:
  /// **'The most widespread is the private “Channel 3” initiative: PMR446 446.03125 MHz, Freenet 149.0500 MHz, CB 26.985 MHz. One number for all three bands. Elsewhere channel 1 is used instead.'**
  String get radioCallingChannelThree;

  /// No description provided for @radioCallingChannelNoListener.
  ///
  /// In en, this message translates to:
  /// **'Do not count on anybody listening. Nobody is obliged to monitor any of these channels.'**
  String get radioCallingChannelNoListener;

  /// No description provided for @energyTitle.
  ///
  /// In en, this message translates to:
  /// **'Energy and fuel'**
  String get energyTitle;

  /// No description provided for @energyEntryHint.
  ///
  /// In en, this message translates to:
  /// **'How long power, gas, fuel and light last.'**
  String get energyEntryHint;

  /// No description provided for @energyIntro.
  ///
  /// In en, this message translates to:
  /// **'The app works out how long the food and water last. This is the same sum for what you cook, heat and light with.'**
  String get energyIntro;

  /// No description provided for @energyNothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing entered yet'**
  String get energyNothingYet;

  /// No description provided for @energyNothingYetWhy.
  ///
  /// In en, this message translates to:
  /// **'Enter what you have — and what uses it. Both figures are printed on the thing itself: “160 g/h” on the stove, “230 g” on the cartridge. Nothing here is estimated for you.'**
  String get energyNothingYetWhy;

  /// No description provided for @energyReserves.
  ///
  /// In en, this message translates to:
  /// **'Stored'**
  String get energyReserves;

  /// No description provided for @energyDraws.
  ///
  /// In en, this message translates to:
  /// **'Used by'**
  String get energyDraws;

  /// No description provided for @energyAddReserve.
  ///
  /// In en, this message translates to:
  /// **'Add a reserve'**
  String get energyAddReserve;

  /// No description provided for @energyAddDraw.
  ///
  /// In en, this message translates to:
  /// **'Add a consumer'**
  String get energyAddDraw;

  /// No description provided for @energyEditReserve.
  ///
  /// In en, this message translates to:
  /// **'Change the reserve'**
  String get energyEditReserve;

  /// No description provided for @energyEditDraw.
  ///
  /// In en, this message translates to:
  /// **'Change the consumer'**
  String get energyEditDraw;

  /// No description provided for @energyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get energyDelete;

  /// No description provided for @energyLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get energyLabel;

  /// No description provided for @energyKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get energyKind;

  /// No description provided for @energyAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get energyAmount;

  /// No description provided for @energyPerHour.
  ///
  /// In en, this message translates to:
  /// **'Uses per hour'**
  String get energyPerHour;

  /// No description provided for @energyHoursPerDay.
  ///
  /// In en, this message translates to:
  /// **'Hours a day'**
  String get energyHoursPerDay;

  /// No description provided for @energyNumberNeeded.
  ///
  /// In en, this message translates to:
  /// **'A number greater than zero.'**
  String get energyNumberNeeded;

  /// No description provided for @energyLabelNeeded.
  ///
  /// In en, this message translates to:
  /// **'A name, so the row still says something later.'**
  String get energyLabelNeeded;

  /// No description provided for @energyDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String energyDays(int days);

  /// No description provided for @energyOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get energyOneDay;

  /// No description provided for @energyZeroDays.
  ///
  /// In en, this message translates to:
  /// **'Does not last a day'**
  String get energyZeroDays;

  /// No description provided for @energyPerDayIs.
  ///
  /// In en, this message translates to:
  /// **'{amount} {unit} a day out of {stored} {unit}'**
  String energyPerDayIs(String amount, String unit, String stored);

  /// No description provided for @energyUnused.
  ///
  /// In en, this message translates to:
  /// **'Stored, but nothing uses it. Enter the consumer, or there is nothing to divide.'**
  String get energyUnused;

  /// No description provided for @energyEmpty.
  ///
  /// In en, this message translates to:
  /// **'Something uses it and there is none.'**
  String get energyEmpty;

  /// No description provided for @energyShortest.
  ///
  /// In en, this message translates to:
  /// **'First to run out: {kind} – {days}'**
  String energyShortest(String kind, String days);

  /// No description provided for @energyShortestWhy.
  ///
  /// In en, this message translates to:
  /// **'That is the household\'s range. Four reserves each with a reassuring number are not four answers — the smallest one counts.'**
  String get energyShortestWhy;

  /// No description provided for @energyNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No range yet: every reserve needs a consumer, or there is nothing to divide.'**
  String get energyNoAnswer;

  /// No description provided for @energySources.
  ///
  /// In en, this message translates to:
  /// **'Every figure here is your own. This app estimates no consumption — what a stove uses is written on the stove, and what a device draws is written on its power supply. All it does is the arithmetic.'**
  String get energySources;

  /// No description provided for @energyKindElectricity.
  ///
  /// In en, this message translates to:
  /// **'Electricity'**
  String get energyKindElectricity;

  /// No description provided for @energyKindGas.
  ///
  /// In en, this message translates to:
  /// **'Gas'**
  String get energyKindGas;

  /// No description provided for @energyKindLiquidFuel.
  ///
  /// In en, this message translates to:
  /// **'Liquid fuel'**
  String get energyKindLiquidFuel;

  /// No description provided for @energyKindSolidFuel.
  ///
  /// In en, this message translates to:
  /// **'Solid fuel'**
  String get energyKindSolidFuel;

  /// No description provided for @energyKindCandles.
  ///
  /// In en, this message translates to:
  /// **'Candlelight'**
  String get energyKindCandles;

  /// No description provided for @energyKindElectricityHint.
  ///
  /// In en, this message translates to:
  /// **'Power banks, batteries, a solar day\'s work — in watt-hours.'**
  String get energyKindElectricityHint;

  /// No description provided for @energyKindGasHint.
  ///
  /// In en, this message translates to:
  /// **'Cartridges and cylinders — in grams, the way a stove states its consumption.'**
  String get energyKindGasHint;

  /// No description provided for @energyKindLiquidFuelHint.
  ///
  /// In en, this message translates to:
  /// **'Petrol, diesel, paraffin, lamp oil, spirit — in litres.'**
  String get energyKindLiquidFuelHint;

  /// No description provided for @energyKindSolidFuelHint.
  ///
  /// In en, this message translates to:
  /// **'Firewood, briquettes, coal, pellets — in kilograms.'**
  String get energyKindSolidFuelHint;

  /// No description provided for @energyKindCandlesHint.
  ///
  /// In en, this message translates to:
  /// **'In burning hours: pieces times the burn time per piece from the packet.'**
  String get energyKindCandlesHint;

  /// No description provided for @energyUnitWattHours.
  ///
  /// In en, this message translates to:
  /// **'Wh'**
  String get energyUnitWattHours;

  /// No description provided for @energyUnitGrams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get energyUnitGrams;

  /// No description provided for @energyUnitLiters.
  ///
  /// In en, this message translates to:
  /// **'l'**
  String get energyUnitLiters;

  /// No description provided for @energyUnitKilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get energyUnitKilograms;

  /// No description provided for @energyUnitHours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get energyUnitHours;

  /// No description provided for @energyHelperTitle.
  ///
  /// In en, this message translates to:
  /// **'Converting'**
  String get energyHelperTitle;

  /// No description provided for @energyHelperGasBottle.
  ///
  /// In en, this message translates to:
  /// **'Cylinder in kilograms? Times 1000 gives grams — 5 kg is 5000 g.'**
  String get energyHelperGasBottle;

  /// No description provided for @energyHelperCandles.
  ///
  /// In en, this message translates to:
  /// **'Candles? Pieces times the burn time each. 40 tea lights at 4 hours is 160 hours.'**
  String get energyHelperCandles;

  /// No description provided for @energyHelperPowerbank.
  ///
  /// In en, this message translates to:
  /// **'Power bank in mAh? Times 3.7 V, divided by 1000, gives watt-hours: 20000 mAh is 74 Wh. Careful — that is the cell, not the socket. Stepping up to 5 V loses something; how much depends on the device, which is why no percentage is given here.'**
  String get energyHelperPowerbank;

  /// No description provided for @transferTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer without a network'**
  String get transferTitle;

  /// No description provided for @transferIntro.
  ///
  /// In en, this message translates to:
  /// **'One device shows a run of images, the other films them. No network, no shared folder, no pairing — the two devices only have to be next to each other.'**
  String get transferIntro;

  /// No description provided for @transferSend.
  ///
  /// In en, this message translates to:
  /// **'Show household'**
  String get transferSend;

  /// No description provided for @transferReceive.
  ///
  /// In en, this message translates to:
  /// **'Film household'**
  String get transferReceive;

  /// No description provided for @transferSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Show household'**
  String get transferSendTitle;

  /// No description provided for @transferSendHint.
  ///
  /// In en, this message translates to:
  /// **'Point the other device\'s camera at this screen. The images run in a loop — one that is missed comes round again on its own.'**
  String get transferSendHint;

  /// No description provided for @transferFrameOf.
  ///
  /// In en, this message translates to:
  /// **'Image {index} of {total}'**
  String transferFrameOf(int index, int total);

  /// No description provided for @transferSendNothing.
  ///
  /// In en, this message translates to:
  /// **'This household has nothing in it yet that could be transferred.'**
  String get transferSendNothing;

  /// No description provided for @transferSlower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get transferSlower;

  /// No description provided for @transferFaster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get transferFaster;

  /// No description provided for @transferReceiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Film household'**
  String get transferReceiveTitle;

  /// No description provided for @transferReceiveHint.
  ///
  /// In en, this message translates to:
  /// **'Hold it at the other device\'s screen and leave it there until it is full.'**
  String get transferReceiveHint;

  /// No description provided for @transferProgress.
  ///
  /// In en, this message translates to:
  /// **'{received} of {total} images'**
  String transferProgress(int received, int total);

  /// No description provided for @transferWaiting.
  ///
  /// In en, this message translates to:
  /// **'No image recognised yet.'**
  String get transferWaiting;

  /// No description provided for @transferDone.
  ///
  /// In en, this message translates to:
  /// **'Complete. {rows} rows taken in.'**
  String transferDone(int rows);

  /// No description provided for @transferNothingNew.
  ///
  /// In en, this message translates to:
  /// **'Complete. All of it was already known.'**
  String get transferNothingNew;

  /// No description provided for @transferBroken.
  ///
  /// In en, this message translates to:
  /// **'The images do not fit together. Film it again.'**
  String get transferBroken;

  /// No description provided for @transferWrongHousehold.
  ///
  /// In en, this message translates to:
  /// **'That is a different household. Only what belongs to this one is taken in.'**
  String get transferWrongHousehold;

  /// No description provided for @transferCameraNeeded.
  ///
  /// In en, this message translates to:
  /// **'Filming needs the camera.'**
  String get transferCameraNeeded;

  /// No description provided for @transferSendOverNetwork.
  ///
  /// In en, this message translates to:
  /// **'Over the network (fast)'**
  String get transferSendOverNetwork;

  /// No description provided for @transferSendOverNetworkHint.
  ///
  /// In en, this message translates to:
  /// **'Both devices are on the same network — home wifi, a hotspot, a campsite. The code here is the key: only whoever films it gets in. The whole household crosses in one go, in both directions.'**
  String get transferSendOverNetworkHint;

  /// No description provided for @transferSendWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the other device …'**
  String get transferSendWaiting;

  /// No description provided for @transferSendNoNetwork.
  ///
  /// In en, this message translates to:
  /// **'This device is on no network. That leaves the run of images.'**
  String get transferSendNoNetwork;

  /// No description provided for @transferUseChain.
  ///
  /// In en, this message translates to:
  /// **'Show without a network instead'**
  String get transferUseChain;

  /// No description provided for @transferUseNetwork.
  ///
  /// In en, this message translates to:
  /// **'Use the network instead'**
  String get transferUseNetwork;

  /// No description provided for @transferSendChainHint.
  ///
  /// In en, this message translates to:
  /// **'Without a network: point the other device\'s camera at this screen. The images run in a loop — one that is missed comes round again on its own.'**
  String get transferSendChainHint;

  /// No description provided for @transferHandoverDone.
  ///
  /// In en, this message translates to:
  /// **'Synced. {rows} rows taken in.'**
  String transferHandoverDone(int rows);

  /// No description provided for @transferHandoverPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One picture came with it.} other{{count} pictures came with it.}}'**
  String transferHandoverPhotos(int count);

  /// No description provided for @transferHandoverNothing.
  ///
  /// In en, this message translates to:
  /// **'Synced. Both devices were already at the same point.'**
  String get transferHandoverNothing;

  /// No description provided for @transferUnreachable.
  ///
  /// In en, this message translates to:
  /// **'The other device cannot be reached. Are both on the same network?'**
  String get transferUnreachable;

  /// No description provided for @portableTitle.
  ///
  /// In en, this message translates to:
  /// **'Data folder'**
  String get portableTitle;

  /// No description provided for @portableInstalled.
  ///
  /// In en, this message translates to:
  /// **'On this machine'**
  String get portableInstalled;

  /// No description provided for @portableInstalledHint.
  ///
  /// In en, this message translates to:
  /// **'Household, stock, photos and settings sit where this operating system keeps them for programs.'**
  String get portableInstalledHint;

  /// No description provided for @portableCarried.
  ///
  /// In en, this message translates to:
  /// **'On a disk you carry'**
  String get portableCarried;

  /// No description provided for @portableSourceBeside.
  ///
  /// In en, this message translates to:
  /// **'Found as a folder named “{folder}” beside the program.'**
  String portableSourceBeside(String folder);

  /// No description provided for @portableSourceChosen.
  ///
  /// In en, this message translates to:
  /// **'Chosen once and remembered.'**
  String get portableSourceChosen;

  /// No description provided for @portableSourceEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Named by the environment variable {variable}.'**
  String portableSourceEnvironment(String variable);

  /// No description provided for @portableExplain.
  ///
  /// In en, this message translates to:
  /// **'Create a folder called “{folder}” beside the program and the next launch uses it. Nothing is created on its own: an installed copy behaves exactly as it always has.'**
  String portableExplain(String folder);

  /// No description provided for @portableExplainMac.
  ///
  /// In en, this message translates to:
  /// **'On macOS the app runs sandboxed — deliberately, because that is what stops the system asking for folder access again after every update. A sandboxed app may not read a folder beside the program. So here the folder is chosen once per Mac instead of being found.'**
  String get portableExplainMac;

  /// No description provided for @portableChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a folder'**
  String get portableChoose;

  /// No description provided for @portableForget.
  ///
  /// In en, this message translates to:
  /// **'Back to this machine'**
  String get portableForget;

  /// No description provided for @portableRestartNeeded.
  ///
  /// In en, this message translates to:
  /// **'Takes effect at the next start.'**
  String get portableRestartNeeded;

  /// No description provided for @portableTakeover.
  ///
  /// In en, this message translates to:
  /// **'The first time a new folder is used, the app takes over once what is on this machine — copied, not moved. The installation here is left untouched.'**
  String get portableTakeover;

  /// No description provided for @portableRelativeNote.
  ///
  /// In en, this message translates to:
  /// **'Maps, archives and documents that sit on the same disk are remembered relative to it. They are found again even when the disk comes up under a different letter on the next machine.'**
  String get portableRelativeNote;

  /// No description provided for @portableFolderUnusable.
  ///
  /// In en, this message translates to:
  /// **'This folder cannot be written to.'**
  String get portableFolderUnusable;

  /// No description provided for @portableChoiceMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'The chosen data folder is missing'**
  String get portableChoiceMissingTitle;

  /// No description provided for @portableChoiceMissingBody.
  ///
  /// In en, this message translates to:
  /// **'You picked a data folder once and it cannot be reached right now. Until it is back, the app is working with the data on this machine — a different household. Anything you enter now is not in the folder you chose.'**
  String get portableChoiceMissingBody;

  /// No description provided for @portableChoiceMissingWhere.
  ///
  /// In en, this message translates to:
  /// **'You chose: {path}'**
  String portableChoiceMissingWhere(String path);

  /// No description provided for @portableChoiceMissingHint.
  ///
  /// In en, this message translates to:
  /// **'Usually the disk is not plugged in. Plug it in and start the app again.'**
  String get portableChoiceMissingHint;

  /// No description provided for @portableUnsupported.
  ///
  /// In en, this message translates to:
  /// **'A carried data folder is possible on computers only, not on phones: there the system decides where an app\'s data lives.'**
  String get portableUnsupported;

  /// No description provided for @articleReaderSimple.
  ///
  /// In en, this message translates to:
  /// **'Simple view'**
  String get articleReaderSimple;

  /// No description provided for @articleReaderWhy.
  ///
  /// In en, this message translates to:
  /// **'This page is shown without the system\'s browser component: text, headings, lists, links and pictures. Scripts, typeset formulas and finer styling are missing.'**
  String get articleReaderWhy;

  /// No description provided for @articleReaderLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading …'**
  String get articleReaderLoading;

  /// No description provided for @articleReaderFailed.
  ///
  /// In en, this message translates to:
  /// **'The article could not be read.'**
  String get articleReaderFailed;

  /// No description provided for @articleReaderEmpty.
  ///
  /// In en, this message translates to:
  /// **'This page holds no readable text.'**
  String get articleReaderEmpty;

  /// No description provided for @articleReaderImageMissing.
  ///
  /// In en, this message translates to:
  /// **'Picture unavailable'**
  String get articleReaderImageMissing;

  /// No description provided for @articleReaderExternal.
  ///
  /// In en, this message translates to:
  /// **'Leads out of the archive and was not opened.'**
  String get articleReaderExternal;

  /// No description provided for @articleReaderOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in a browser'**
  String get articleReaderOpenInBrowser;

  /// No description provided for @articleViewerChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Showing an article'**
  String get articleViewerChoiceTitle;

  /// No description provided for @articleViewerChoiceWhy.
  ///
  /// In en, this message translates to:
  /// **'On Linux and Windows this app has no embedded browser component available. An article therefore opens either in a window of the system\'s own — or the app draws it itself.'**
  String get articleViewerChoiceWhy;

  /// No description provided for @articleViewerChoiceWindow.
  ///
  /// In en, this message translates to:
  /// **'A window of its own'**
  String get articleViewerChoiceWindow;

  /// No description provided for @articleViewerChoiceWindowWhy.
  ///
  /// In en, this message translates to:
  /// **'Shows the article in full: scripts, typeset formulas, the page\'s own layout. Needs the system\'s browser component — WebKitGTK on Linux, the WebView2 runtime on Windows.'**
  String get articleViewerChoiceWindowWhy;

  /// No description provided for @articleViewerChoiceBuiltIn.
  ///
  /// In en, this message translates to:
  /// **'Inside the app'**
  String get articleViewerChoiceBuiltIn;

  /// No description provided for @articleViewerChoiceBuiltInWhy.
  ///
  /// In en, this message translates to:
  /// **'Needs nothing from the system and stays in the same window. The app\'s text size and colours apply to the article too. No scripts, no typeset formulas, no floated infoboxes.'**
  String get articleViewerChoiceBuiltInWhy;

  /// No description provided for @articleViewerChoiceFallbackNote.
  ///
  /// In en, this message translates to:
  /// **'If the system\'s component is missing, the app draws the article itself in any case — this choice only changes what is tried first.'**
  String get articleViewerChoiceFallbackNote;

  /// No description provided for @outageTitle.
  ///
  /// In en, this message translates to:
  /// **'Power outage'**
  String get outageTitle;

  /// No description provided for @outageEntryHint.
  ///
  /// In en, this message translates to:
  /// **'How long the fridge and the freezer still hold.'**
  String get outageEntryHint;

  /// No description provided for @outageIntro.
  ///
  /// In en, this message translates to:
  /// **'While the power is off, the cold runs out. Tap when it starts and the app keeps counting, even if you close it.'**
  String get outageIntro;

  /// No description provided for @outageStart.
  ///
  /// In en, this message translates to:
  /// **'The power just went out'**
  String get outageStart;

  /// No description provided for @outageEnded.
  ///
  /// In en, this message translates to:
  /// **'The power is back'**
  String get outageEnded;

  /// No description provided for @outageRunningSince.
  ///
  /// In en, this message translates to:
  /// **'Running since {time}'**
  String outageRunningSince(String time);

  /// No description provided for @outageChangeStart.
  ///
  /// In en, this message translates to:
  /// **'Different time'**
  String get outageChangeStart;

  /// No description provided for @outageStoreRefrigerator.
  ///
  /// In en, this message translates to:
  /// **'Refrigerator'**
  String get outageStoreRefrigerator;

  /// No description provided for @outageStoreFreezer.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get outageStoreFreezer;

  /// No description provided for @outageRemaining.
  ///
  /// In en, this message translates to:
  /// **'{left} left'**
  String outageRemaining(String left);

  /// No description provided for @outageRemainingHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String outageRemainingHours(int hours, int minutes);

  /// No description provided for @outageRemainingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String outageRemainingMinutes(int minutes);

  /// No description provided for @outageUntil.
  ///
  /// In en, this message translates to:
  /// **'Until {time}'**
  String outageUntil(String time);

  /// No description provided for @outageGrace.
  ///
  /// In en, this message translates to:
  /// **'Window over — discard in {left}'**
  String outageGrace(String left);

  /// No description provided for @outageSpoilt.
  ///
  /// In en, this message translates to:
  /// **'Discard perishable food'**
  String get outageSpoilt;

  /// No description provided for @outageFreezerFill.
  ///
  /// In en, this message translates to:
  /// **'Freezer'**
  String get outageFreezerFill;

  /// No description provided for @outageFreezerFull.
  ///
  /// In en, this message translates to:
  /// **'Well filled'**
  String get outageFreezerFull;

  /// No description provided for @outageFreezerHalf.
  ///
  /// In en, this message translates to:
  /// **'Half full or less'**
  String get outageFreezerHalf;

  /// No description provided for @outageFreezerWhy.
  ///
  /// In en, this message translates to:
  /// **'A full freezer holds for about 48 hours, a half-full one for about 24. The cold is in the food itself, not in the appliance.'**
  String get outageFreezerWhy;

  /// No description provided for @outageRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Rules'**
  String get outageRulesTitle;

  /// No description provided for @outageRuleClosed.
  ///
  /// In en, this message translates to:
  /// **'Keep the door shut. Every opening costs hours, and the figures here only hold for a closed door.'**
  String get outageRuleClosed;

  /// No description provided for @outageRuleTwoHours.
  ///
  /// In en, this message translates to:
  /// **'Anything that spent two hours above {degrees} °C goes — meat, fish, eggs, dairy, leftovers.'**
  String outageRuleTwoHours(int degrees);

  /// No description provided for @outageRuleTaste.
  ///
  /// In en, this message translates to:
  /// **'Never taste food to decide. You cannot taste it.'**
  String get outageRuleTaste;

  /// No description provided for @outageRuleRefreeze.
  ///
  /// In en, this message translates to:
  /// **'Refreezing is allowed while ice crystals remain. Quality suffers, safety does not.'**
  String get outageRuleRefreeze;

  /// No description provided for @outageRuleGenerator.
  ///
  /// In en, this message translates to:
  /// **'Run a generator outdoors only, at least 6 metres from windows, doors and an attached garage.'**
  String get outageRuleGenerator;

  /// No description provided for @outageRuleUnplug.
  ///
  /// In en, this message translates to:
  /// **'Unplug appliances: the power comes back as a surge.'**
  String get outageRuleUnplug;

  /// No description provided for @outageSource.
  ///
  /// In en, this message translates to:
  /// **'The hour figures come from FEMA (ready.gov) and the USDA (FSIS). No German authority publishes figures for this, which is why the source is named here.'**
  String get outageSource;

  /// No description provided for @dailyDoseLabel.
  ///
  /// In en, this message translates to:
  /// **'Taken per day'**
  String get dailyDoseLabel;

  /// No description provided for @dailyDoseHelper.
  ///
  /// In en, this message translates to:
  /// **'In the same unit as the stock: with 60 tablets and 2 a day, enter “2”. Leave empty if it is not taken daily.'**
  String get dailyDoseHelper;

  /// No description provided for @medicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medicationTitle;

  /// No description provided for @medicationEntryHint.
  ///
  /// In en, this message translates to:
  /// **'How long the medication lasts.'**
  String get medicationEntryHint;

  /// No description provided for @medicationIntro.
  ///
  /// In en, this message translates to:
  /// **'The same arithmetic as for supplies and fuel, applied to the medicine cabinet: stock divided by what is taken per day. Both figures are yours — the app never guesses a dose.'**
  String get medicationIntro;

  /// No description provided for @medicationNothingYet.
  ///
  /// In en, this message translates to:
  /// **'No medication entered yet'**
  String get medicationNothingYet;

  /// No description provided for @medicationNothingYetWhy.
  ///
  /// In en, this message translates to:
  /// **'Enter a medicine as a supply item in the “medical” category and give what is taken per day. Only then is there something to work out.'**
  String get medicationNothingYetWhy;

  /// No description provided for @medicationNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'No medicine has a daily amount entered — without one there is nothing to divide.'**
  String get medicationNoAnswer;

  /// No description provided for @medicationShortest.
  ///
  /// In en, this message translates to:
  /// **'Runs out first: {name} — {days}'**
  String medicationShortest(String name, String days);

  /// No description provided for @medicationShortestWhy.
  ///
  /// In en, this message translates to:
  /// **'That is the reach of the medicine cabinet. A refill needs a practice and a pharmacy, and in an emergency neither is available at once.'**
  String get medicationShortestWhy;

  /// No description provided for @medicationRunsOut.
  ///
  /// In en, this message translates to:
  /// **'Gone on {date}'**
  String medicationRunsOut(String date);

  /// No description provided for @medicationDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String medicationDays(int days);

  /// No description provided for @medicationOneDay.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get medicationOneDay;

  /// No description provided for @medicationZeroDays.
  ///
  /// In en, this message translates to:
  /// **'Less than a day'**
  String get medicationZeroDays;

  /// No description provided for @medicationStock.
  ///
  /// In en, this message translates to:
  /// **'{quantity} {unit} in stock, {dose} a day'**
  String medicationStock(String quantity, String unit, String dose);

  /// No description provided for @medicationWithoutDoseTitle.
  ///
  /// In en, this message translates to:
  /// **'Without a daily amount'**
  String get medicationWithoutDoseTitle;

  /// No description provided for @medicationWithoutDoseWhy.
  ///
  /// In en, this message translates to:
  /// **'These are in the stores but not counted. They are named here instead of being quietly skipped — otherwise the figure above would read as covering the whole cabinet.'**
  String get medicationWithoutDoseWhy;

  /// No description provided for @medicationSource.
  ///
  /// In en, this message translates to:
  /// **'FEMA and the CDC both advise keeping a supply of prescription medication and knowing how long it lasts. How large that supply may be is a matter for the practice — the app only counts what is there.'**
  String get medicationSource;

  /// No description provided for @possessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Household inventory'**
  String get possessionsTitle;

  /// No description provided for @possessionsEntryHint.
  ///
  /// In en, this message translates to:
  /// **'What the household owns — for the insurer.'**
  String get possessionsEntryHint;

  /// No description provided for @possessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing entered yet'**
  String get possessionsEmpty;

  /// No description provided for @possessionsWhy.
  ///
  /// In en, this message translates to:
  /// **'After a fire, a flood or a break-in the insurer asks what was there. Nobody answers that from memory. This list is not the supply store — it is what would have to be replaced.'**
  String get possessionsWhy;

  /// No description provided for @possessionsNoRoom.
  ///
  /// In en, this message translates to:
  /// **'No room given'**
  String get possessionsNoRoom;

  /// No description provided for @possessionsTotal.
  ///
  /// In en, this message translates to:
  /// **'Total: {amount}'**
  String possessionsTotal(String amount);

  /// No description provided for @possessionsWithoutPrice.
  ///
  /// In en, this message translates to:
  /// **'{count} entries without a price are not in the total.'**
  String possessionsWithoutPrice(int count);

  /// No description provided for @possessionsExport.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get possessionsExport;

  /// No description provided for @possessionsPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Household inventory'**
  String get possessionsPdfTitle;

  /// No description provided for @possessionsKeepElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This list does not belong only in the home it describes. Print it and keep it elsewhere, or mail it to yourself. The photos are not in this file — they are only on the device that took them.'**
  String get possessionsKeepElsewhere;

  /// No description provided for @possessionAdd.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get possessionAdd;

  /// No description provided for @possessionAddTitle.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get possessionAddTitle;

  /// No description provided for @possessionEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get possessionEditTitle;

  /// No description provided for @possessionNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get possessionNameLabel;

  /// No description provided for @possessionNameNeeded.
  ///
  /// In en, this message translates to:
  /// **'A name, or the row will say nothing later.'**
  String get possessionNameNeeded;

  /// No description provided for @possessionRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room'**
  String get possessionRoomLabel;

  /// No description provided for @possessionRoomHelper.
  ///
  /// In en, this message translates to:
  /// **'Living room, cellar, garage — however you walk through it.'**
  String get possessionRoomHelper;

  /// No description provided for @possessionSerialLabel.
  ///
  /// In en, this message translates to:
  /// **'Serial number'**
  String get possessionSerialLabel;

  /// No description provided for @possessionSerialHelper.
  ///
  /// In en, this message translates to:
  /// **'The one field that cannot be reconstructed afterwards. Usually on the back or underneath.'**
  String get possessionSerialHelper;

  /// No description provided for @possessionPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Purchase price'**
  String get possessionPriceLabel;

  /// No description provided for @possessionCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get possessionCurrencyLabel;

  /// No description provided for @possessionAcquiredLabel.
  ///
  /// In en, this message translates to:
  /// **'Bought on'**
  String get possessionAcquiredLabel;

  /// No description provided for @possessionAcquiredNone.
  ///
  /// In en, this message translates to:
  /// **'No date'**
  String get possessionAcquiredNone;

  /// No description provided for @possessionPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get possessionPhotoTitle;

  /// No description provided for @possessionPhotoWhy.
  ///
  /// In en, this message translates to:
  /// **'A picture convinces an insurer more than any description. It stays on this device and does not go into the shared folder.'**
  String get possessionPhotoWhy;

  /// No description provided for @possessionPhotoCamera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get possessionPhotoCamera;

  /// No description provided for @possessionPhotoGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get possessionPhotoGallery;

  /// No description provided for @possessionPhotoRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get possessionPhotoRemove;

  /// No description provided for @possessionRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get possessionRemoveTitle;

  /// No description provided for @possessionRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'“{name}” will be removed on every device in the household.'**
  String possessionRemoveBody(String name);

  /// No description provided for @possessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String possessionsCount(int count);

  /// No description provided for @firstAidTitle.
  ///
  /// In en, this message translates to:
  /// **'First aid'**
  String get firstAidTitle;

  /// No description provided for @firstAidEntryHint.
  ///
  /// In en, this message translates to:
  /// **'Instructions, drawings and a pacer for chest compressions. No network, no download.'**
  String get firstAidEntryHint;

  /// No description provided for @firstAidSearchHint.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get firstAidSearchHint;

  /// No description provided for @firstAidSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no guide here for that.'**
  String get firstAidSearchEmpty;

  /// No description provided for @firstAidDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'These guides replace neither a first aid course nor an emergency call. In doubt: call 112 and stay on the line — the dispatcher will talk you through it.'**
  String get firstAidDisclaimer;

  /// No description provided for @firstAidGroupBasics.
  ///
  /// In en, this message translates to:
  /// **'First of all'**
  String get firstAidGroupBasics;

  /// No description provided for @firstAidGroupLifeThreatening.
  ///
  /// In en, this message translates to:
  /// **'Life-threatening'**
  String get firstAidGroupLifeThreatening;

  /// No description provided for @firstAidGroupInjury.
  ///
  /// In en, this message translates to:
  /// **'Injuries'**
  String get firstAidGroupInjury;

  /// No description provided for @firstAidGroupIllness.
  ///
  /// In en, this message translates to:
  /// **'Sudden illness'**
  String get firstAidGroupIllness;

  /// No description provided for @firstAidGroupEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Cold, heat, poison'**
  String get firstAidGroupEnvironment;

  /// No description provided for @firstAidCallNow.
  ///
  /// In en, this message translates to:
  /// **'Call 112'**
  String get firstAidCallNow;

  /// No description provided for @firstAidCallFirst.
  ///
  /// In en, this message translates to:
  /// **'Here you call first and help second.'**
  String get firstAidCallFirst;

  /// No description provided for @firstAidSteps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get firstAidSteps;

  /// No description provided for @firstAidCautions.
  ///
  /// In en, this message translates to:
  /// **'Do not'**
  String get firstAidCautions;

  /// No description provided for @firstAidSource.
  ///
  /// In en, this message translates to:
  /// **'Source: {source}'**
  String firstAidSource(String source);

  /// No description provided for @firstAidOpenPacer.
  ///
  /// In en, this message translates to:
  /// **'Start the pacer'**
  String get firstAidOpenPacer;

  /// No description provided for @firstAidVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get firstAidVideos;

  /// No description provided for @firstAidVideosNone.
  ///
  /// In en, this message translates to:
  /// **'No video is installed for this guide.'**
  String get firstAidVideosNone;

  /// No description provided for @firstAidVideoManage.
  ///
  /// In en, this message translates to:
  /// **'Manage the video pack'**
  String get firstAidVideoManage;

  /// No description provided for @firstAidVideoMissing.
  ///
  /// In en, this message translates to:
  /// **'The video file is gone. Fetch the pack again.'**
  String get firstAidVideoMissing;

  /// No description provided for @firstAidVideoRestart.
  ///
  /// In en, this message translates to:
  /// **'From the start'**
  String get firstAidVideoRestart;

  /// No description provided for @firstAidVideoSystemPlayer.
  ///
  /// In en, this message translates to:
  /// **'This system cannot play video inside the app. The button below opens the file in the computer\'s own player.'**
  String get firstAidVideoSystemPlayer;

  /// No description provided for @firstAidVideoOpenExternal.
  ///
  /// In en, this message translates to:
  /// **'Open in the system player'**
  String get firstAidVideoOpenExternal;

  /// No description provided for @firstAidVideoNotACourse.
  ///
  /// In en, this message translates to:
  /// **'A video is not a course. The movements only stick once you have done them yourself.'**
  String get firstAidVideoNotACourse;

  /// No description provided for @firstAidVideoPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Video pack'**
  String get firstAidVideoPackTitle;

  /// No description provided for @firstAidVideoPackWhy.
  ///
  /// In en, this message translates to:
  /// **'The guides need no video: the text, the figures and the drawings are complete and always there. Videos are an extra for the evening you sit down to learn the movements properly — and they are a separate download, because ten films weigh more than the whole app.'**
  String get firstAidVideoPackWhy;

  /// No description provided for @firstAidVideoPackFromNetwork.
  ///
  /// In en, this message translates to:
  /// **'Over the network'**
  String get firstAidVideoPackFromNetwork;

  /// No description provided for @firstAidVideoPackUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Address of the pack description'**
  String get firstAidVideoPackUrlLabel;

  /// No description provided for @firstAidVideoPackUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'The address of a paket.json. This app ships none — enter the address where you published your pack.'**
  String get firstAidVideoPackUrlHelper;

  /// No description provided for @firstAidVideoPackFetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch the description'**
  String get firstAidVideoPackFetch;

  /// No description provided for @firstAidVideoPackFromFile.
  ///
  /// In en, this message translates to:
  /// **'From a file'**
  String get firstAidVideoPackFromFile;

  /// No description provided for @firstAidVideoPackFromFileWhy.
  ///
  /// In en, this message translates to:
  /// **'A pack as a zip, from a memory stick or from the shared folder. This is the way that works without a network — that is, in the situation this app is built for.'**
  String get firstAidVideoPackFromFileWhy;

  /// No description provided for @firstAidVideoPackImport.
  ///
  /// In en, this message translates to:
  /// **'Choose a pack file'**
  String get firstAidVideoPackImport;

  /// No description provided for @firstAidVideoPackNone.
  ///
  /// In en, this message translates to:
  /// **'No video pack installed yet.'**
  String get firstAidVideoPackNone;

  /// No description provided for @firstAidVideoPackInstalled.
  ///
  /// In en, this message translates to:
  /// **'{present} of {total} videos present, {size} on disk'**
  String firstAidVideoPackInstalled(int present, int total, String size);

  /// No description provided for @firstAidVideoPackRemove.
  ///
  /// In en, this message translates to:
  /// **'Delete the video pack'**
  String get firstAidVideoPackRemove;

  /// No description provided for @firstAidVideoPackRemoveBody.
  ///
  /// In en, this message translates to:
  /// **'The video files and the pack description are removed from the device. The guides themselves are untouched.'**
  String get firstAidVideoPackRemoveBody;

  /// No description provided for @firstAidVideoPackOffer.
  ///
  /// In en, this message translates to:
  /// **'{count} videos, {size} in all'**
  String firstAidVideoPackOffer(int count, String size);

  /// No description provided for @firstAidVideoPackStart.
  ///
  /// In en, this message translates to:
  /// **'Fetch them all'**
  String get firstAidVideoPackStart;

  /// No description provided for @firstAidVideoPackProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String firstAidVideoPackProgress(int done, int total);

  /// No description provided for @firstAidVideoPackDone.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} videos fetched'**
  String firstAidVideoPackDone(int done, int total);

  /// No description provided for @firstAidVideoPackLicenceNote.
  ///
  /// In en, this message translates to:
  /// **'Every video names its author and its licence. Only fetch packs whose films may be passed on.'**
  String get firstAidVideoPackLicenceNote;

  /// No description provided for @firstAidVideoPackBadUrl.
  ///
  /// In en, this message translates to:
  /// **'That is not a complete address.'**
  String get firstAidVideoPackBadUrl;

  /// No description provided for @firstAidVideoPackClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get firstAidVideoPackClose;

  /// No description provided for @pacerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pacer'**
  String get pacerTitle;

  /// No description provided for @pacerStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get pacerStart;

  /// No description provided for @pacerStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get pacerStop;

  /// No description provided for @pacerIdle.
  ///
  /// In en, this message translates to:
  /// **'Sets the beat for chest compressions — as a tone, as a flash and, on a phone, as a vibration. The screen stays on while it runs.'**
  String get pacerIdle;

  /// No description provided for @pacerElapsed.
  ///
  /// In en, this message translates to:
  /// **'Running {time}'**
  String pacerElapsed(String time);

  /// No description provided for @pacerDepth.
  ///
  /// In en, this message translates to:
  /// **'5–6 cm deep · vertically from above · let the chest come all the way back up'**
  String get pacerDepth;

  /// No description provided for @pacerNoSound.
  ///
  /// In en, this message translates to:
  /// **'No sound on this device. The beat keeps flashing.'**
  String get pacerNoSound;

  /// No description provided for @pacerPerMinute.
  ///
  /// In en, this message translates to:
  /// **'{rate}/min'**
  String pacerPerMinute(int rate);

  /// No description provided for @pacerOfCycle.
  ///
  /// In en, this message translates to:
  /// **'of {total} · round {cycle}'**
  String pacerOfCycle(int total, int cycle);

  /// No description provided for @pacerBreathe.
  ///
  /// In en, this message translates to:
  /// **'Now 2 breaths'**
  String get pacerBreathe;

  /// No description provided for @pacerSwapNow.
  ///
  /// In en, this message translates to:
  /// **'Swap over if there are two of you'**
  String get pacerSwapNow;

  /// No description provided for @pacerPushOnly.
  ///
  /// In en, this message translates to:
  /// **'Push without stopping'**
  String get pacerPushOnly;

  /// No description provided for @pacerPushOnlyShort.
  ///
  /// In en, this message translates to:
  /// **'Push only'**
  String get pacerPushOnlyShort;

  /// No description provided for @warningSituationMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Warning situation map'**
  String get warningSituationMapTitle;

  /// No description provided for @warningSituationMapEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no active warnings for this selection.'**
  String get warningSituationMapEmpty;

  /// No description provided for @warningSituationMapNoGeometry.
  ///
  /// In en, this message translates to:
  /// **'The active warnings do not include map areas. Their complete guidance remains available offline in the warning list.'**
  String get warningSituationMapNoGeometry;

  /// No description provided for @warningSituationMapFailed.
  ///
  /// In en, this message translates to:
  /// **'The stored warning situation could not be read.'**
  String get warningSituationMapFailed;

  /// No description provided for @warningSituationMapTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the map to see what applies at a spot.'**
  String get warningSituationMapTapHint;

  /// No description provided for @warningSituationMapAtPoint.
  ///
  /// In en, this message translates to:
  /// **'At this spot'**
  String get warningSituationMapAtPoint;

  /// No description provided for @warningSituationMapNothingHere.
  ///
  /// In en, this message translates to:
  /// **'None of the areas shown covers this spot.'**
  String get warningSituationMapNothingHere;

  /// No description provided for @knowledgeApolloPackagesTitle.
  ///
  /// In en, this message translates to:
  /// **'APOLLO package status'**
  String get knowledgeApolloPackagesTitle;

  /// No description provided for @knowledgeApolloPackageSummary.
  ///
  /// In en, this message translates to:
  /// **'{installed} of {total} recommended sources available'**
  String knowledgeApolloPackageSummary(int installed, int total);

  /// No description provided for @knowledgeApolloPackageInstalled.
  ///
  /// In en, this message translates to:
  /// **'Downloaded and registered in the library'**
  String get knowledgeApolloPackageInstalled;

  /// No description provided for @knowledgeApolloPackageMissing.
  ///
  /// In en, this message translates to:
  /// **'Not yet in the library'**
  String get knowledgeApolloPackageMissing;

  /// No description provided for @readinessEquipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment and batteries checked'**
  String get readinessEquipment;

  /// No description provided for @readinessEquipmentOff.
  ///
  /// In en, this message translates to:
  /// **'The check routine is switched off'**
  String get readinessEquipmentOff;

  /// No description provided for @readinessEquipmentNotChecked.
  ///
  /// In en, this message translates to:
  /// **'No check has been confirmed yet'**
  String get readinessEquipmentNotChecked;

  /// No description provided for @readinessEquipmentDue.
  ///
  /// In en, this message translates to:
  /// **'A check is due'**
  String get readinessEquipmentDue;

  /// No description provided for @readinessEquipmentChecked.
  ///
  /// In en, this message translates to:
  /// **'A check was confirmed within the chosen interval'**
  String get readinessEquipmentChecked;

  /// No description provided for @transferNearbyTitle.
  ///
  /// In en, this message translates to:
  /// **'Devices on the local network'**
  String get transferNearbyTitle;

  /// No description provided for @transferNearbyHint.
  ///
  /// In en, this message translates to:
  /// **'Only random, short-lived availability signals are searched for. Select a device, then scan its visible QR code; nothing is transferred without that code.'**
  String get transferNearbyHint;

  /// No description provided for @transferNearbyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transfer-ready PreppSuite device has been found on this network yet.'**
  String get transferNearbyEmpty;

  /// No description provided for @transferNearbyUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Device discovery is not available on this network right now. You can still scan the QR code directly.'**
  String get transferNearbyUnavailable;

  /// No description provided for @transferNearbyDevice.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite device ready'**
  String get transferNearbyDevice;

  /// No description provided for @transferNearbyScanHint.
  ///
  /// In en, this message translates to:
  /// **'Scan this device\'s QR code for the secure handover'**
  String get transferNearbyScanHint;

  /// No description provided for @settingsRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get settingsRegionLabel;

  /// No description provided for @settingsRegionLabelHelper.
  ///
  /// In en, this message translates to:
  /// **'For example home, work or a relative.'**
  String get settingsRegionLabelHelper;

  /// No description provided for @knowledgeCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your knowledge'**
  String get knowledgeCheckTitle;

  /// No description provided for @knowledgeCheckIntro.
  ///
  /// In en, this message translates to:
  /// **'First aid goes quiet without telling you. A few questions show what still holds — and what does not.'**
  String get knowledgeCheckIntro;

  /// No description provided for @knowledgeCheckProgress.
  ///
  /// In en, this message translates to:
  /// **'Question {number} of {total}'**
  String knowledgeCheckProgress(int number, int total);

  /// No description provided for @knowledgeCheckRight.
  ///
  /// In en, this message translates to:
  /// **'Right.'**
  String get knowledgeCheckRight;

  /// No description provided for @knowledgeCheckWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite.'**
  String get knowledgeCheckWrong;

  /// No description provided for @knowledgeCheckReadGuide.
  ///
  /// In en, this message translates to:
  /// **'Read the guide'**
  String get knowledgeCheckReadGuide;

  /// No description provided for @knowledgeCheckNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get knowledgeCheckNext;

  /// No description provided for @knowledgeCheckFinish.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get knowledgeCheckFinish;

  /// No description provided for @knowledgeCheckResult.
  ///
  /// In en, this message translates to:
  /// **'{right} of {total} right.'**
  String knowledgeCheckResult(int right, int total);

  /// No description provided for @knowledgeCheckHeld.
  ///
  /// In en, this message translates to:
  /// **'{held} of {total} questions hold.'**
  String knowledgeCheckHeld(int held, int total);

  /// No description provided for @knowledgeCheckComeBack.
  ///
  /// In en, this message translates to:
  /// **'Come back in a few months. Not tomorrow — that is not what this is for.'**
  String get knowledgeCheckComeBack;

  /// No description provided for @knowledgeCheckReview.
  ///
  /// In en, this message translates to:
  /// **'Worth reading again'**
  String get knowledgeCheckReview;

  /// No description provided for @knowledgeCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Another round'**
  String get knowledgeCheckAgain;

  /// No description provided for @mapPlacesImport.
  ///
  /// In en, this message translates to:
  /// **'Read places in'**
  String get mapPlacesImport;

  /// No description provided for @mapPlacesExport.
  ///
  /// In en, this message translates to:
  /// **'Hand places over'**
  String get mapPlacesExport;

  /// No description provided for @mapPlacesExportGpx.
  ///
  /// In en, this message translates to:
  /// **'Hand over as GPX'**
  String get mapPlacesExportGpx;

  /// No description provided for @mapPlacesExportKml.
  ///
  /// In en, this message translates to:
  /// **'Hand over as KML'**
  String get mapPlacesExportKml;

  /// No description provided for @mapPlacesExportFailed.
  ///
  /// In en, this message translates to:
  /// **'The file could not be written.'**
  String get mapPlacesExportFailed;

  /// No description provided for @mapPlacesImportNothing.
  ///
  /// In en, this message translates to:
  /// **'There is no place in this file that the app can read.'**
  String get mapPlacesImportNothing;

  /// No description provided for @mapPlacesImported.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Every place was already here.} =1{One place was added.} other{{count} places were added.}}'**
  String mapPlacesImported(int count);

  /// No description provided for @mapPlacesTitle.
  ///
  /// In en, this message translates to:
  /// **'My places'**
  String get mapPlacesTitle;

  /// No description provided for @mapPlacesIntro.
  ///
  /// In en, this message translates to:
  /// **'Personal places appear as markers on the map. They stay on this device only.'**
  String get mapPlacesIntro;

  /// No description provided for @mapPlacesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No personal places yet. Save meeting points, distribution points, or important supplies.'**
  String get mapPlacesEmpty;

  /// No description provided for @mapPlaceAdd.
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get mapPlaceAdd;

  /// No description provided for @mapPlaceEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get mapPlaceEdit;

  /// No description provided for @mapPlacePrivacy.
  ///
  /// In en, this message translates to:
  /// **'These location details stay local to this device and are not shared with the household.'**
  String get mapPlacePrivacy;

  /// No description provided for @mapPlaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get mapPlaceLabel;

  /// No description provided for @mapPlaceLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get mapPlaceLatitude;

  /// No description provided for @mapPlaceLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get mapPlaceLongitude;

  /// No description provided for @mapPlaceNote.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get mapPlaceNote;

  /// No description provided for @mapPlaceNoteHint.
  ///
  /// In en, this message translates to:
  /// **'For example access, supplies, or meeting time'**
  String get mapPlaceNoteHint;

  /// No description provided for @mapPlaceCoordinatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a label and valid coordinates.'**
  String get mapPlaceCoordinatesInvalid;

  /// No description provided for @mapPlaceDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove “{label}”?'**
  String mapPlaceDeleteConfirm(Object label);

  /// No description provided for @drillsLastCompleted.
  ///
  /// In en, this message translates to:
  /// **'last completed: {date}'**
  String drillsLastCompleted(String date);

  /// No description provided for @hubTitle.
  ///
  /// In en, this message translates to:
  /// **'Crisis organisation'**
  String get hubTitle;

  /// No description provided for @hubPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Everything here stays on this device. If you export an incident log, you decide who receives it.'**
  String get hubPrivacyNote;

  /// No description provided for @hubNotCheckedYet.
  ///
  /// In en, this message translates to:
  /// **'not checked yet'**
  String get hubNotCheckedYet;

  /// No description provided for @hubAutonomyTitle.
  ///
  /// In en, this message translates to:
  /// **'Self-sufficiency'**
  String get hubAutonomyTitle;

  /// No description provided for @hubAutonomyHint.
  ///
  /// In en, this message translates to:
  /// **'Range in days, worked out from your stock and your energy plan. The lowest figure is the next bottleneck.'**
  String get hubAutonomyHint;

  /// No description provided for @hubAutonomyIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Self-sufficiency not yet complete. Open: {resources}.'**
  String hubAutonomyIncomplete(String resources);

  /// No description provided for @hubAutonomyKnownSoFar.
  ///
  /// In en, this message translates to:
  /// **'Of what is known: {days} days, bottleneck {resource}.'**
  String hubAutonomyKnownSoFar(int days, String resource);

  /// No description provided for @hubAutonomyRange.
  ///
  /// In en, this message translates to:
  /// **'{days} days on your own – bottleneck: {resource}'**
  String hubAutonomyRange(int days, String resource);

  /// No description provided for @hubAutonomyOpen.
  ///
  /// In en, this message translates to:
  /// **'open'**
  String get hubAutonomyOpen;

  /// No description provided for @hubAutonomyDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String hubAutonomyDays(int days);

  /// No description provided for @hubAutonomyAddByHand.
  ///
  /// In en, this message translates to:
  /// **'Fill in by hand'**
  String get hubAutonomyAddByHand;

  /// No description provided for @hubAutonomyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Range in days'**
  String get hubAutonomyDialogTitle;

  /// No description provided for @hubAutonomyDialogHint.
  ///
  /// In en, this message translates to:
  /// **'What the app can work out from your stock and energy plan is already on the screen. This is only for what it cannot divide.'**
  String get hubAutonomyDialogHint;

  /// No description provided for @hubAutonomyDaysField.
  ///
  /// In en, this message translates to:
  /// **'{label} – days'**
  String hubAutonomyDaysField(String label);

  /// No description provided for @hubAutonomyFromStock.
  ///
  /// In en, this message translates to:
  /// **'Worked out from your stock'**
  String get hubAutonomyFromStock;

  /// No description provided for @hubAutonomyByHandWith.
  ///
  /// In en, this message translates to:
  /// **'Entered by hand – {reason}'**
  String hubAutonomyByHandWith(String reason);

  /// No description provided for @hubAutonomyNotCounted.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{One entry not counted: {reason}}other{{count} entries not counted: {reason}}}'**
  String hubAutonomyNotCounted(int count, String reason);

  /// No description provided for @hubResourceWater.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get hubResourceWater;

  /// No description provided for @hubResourceFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get hubResourceFood;

  /// No description provided for @hubResourceMedicine.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get hubResourceMedicine;

  /// No description provided for @hubResourceEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get hubResourceEnergy;

  /// No description provided for @hubResourceHygiene.
  ///
  /// In en, this message translates to:
  /// **'Hygiene'**
  String get hubResourceHygiene;

  /// No description provided for @hubGapOnlyByHand.
  ///
  /// In en, this message translates to:
  /// **'the app does not count this'**
  String get hubGapOnlyByHand;

  /// No description provided for @hubGapNoEnergyPlan.
  ///
  /// In en, this message translates to:
  /// **'no energy plan yet'**
  String get hubGapNoEnergyPlan;

  /// No description provided for @hubGapNothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'nothing recorded in your stock yet'**
  String get hubGapNothingRecorded;

  /// No description provided for @hubGapNoLiters.
  ///
  /// In en, this message translates to:
  /// **'not recorded in litres'**
  String get hubGapNoLiters;

  /// No description provided for @hubGapNoCalories.
  ///
  /// In en, this message translates to:
  /// **'without a calorie figure'**
  String get hubGapNoCalories;

  /// No description provided for @hubGapNoDose.
  ///
  /// In en, this message translates to:
  /// **'without a daily dose'**
  String get hubGapNoDose;

  /// No description provided for @hubGapNoDraw.
  ///
  /// In en, this message translates to:
  /// **'nothing draws on it'**
  String get hubGapNoDraw;

  /// No description provided for @hubWaterHygieneTitle.
  ///
  /// In en, this message translates to:
  /// **'Water and hygiene'**
  String get hubWaterHygieneTitle;

  /// No description provided for @hubWaterHygieneHint.
  ///
  /// In en, this message translates to:
  /// **'Plan drinking water, service water, treatment, canister rotation, toilet and waste separately.'**
  String get hubWaterHygieneHint;

  /// No description provided for @hubWaterHygieneLabel.
  ///
  /// In en, this message translates to:
  /// **'Water and hygiene plan'**
  String get hubWaterHygieneLabel;

  /// No description provided for @hubWaterHygieneTemplate.
  ///
  /// In en, this message translates to:
  /// **'Drinking water: …\nService water: …\nSources and treatment: …\nCanister rotation: …\nToilet, waste and cleaning supplies: …'**
  String get hubWaterHygieneTemplate;

  /// No description provided for @hubPowerOutageTitle.
  ///
  /// In en, this message translates to:
  /// **'Power cut plan'**
  String get hubPowerOutageTitle;

  /// No description provided for @hubPowerOutageHint.
  ///
  /// In en, this message translates to:
  /// **'Prepare the start time, the cold chain, charging priorities, light, information and safe warmth.'**
  String get hubPowerOutageHint;

  /// No description provided for @hubPowerOutageTemplate.
  ///
  /// In en, this message translates to:
  /// **'Note the start time. Keep fridge and freezer shut. Write down charging priorities, radio, light, safe warmth and who to contact.'**
  String get hubPowerOutageTemplate;

  /// No description provided for @hubCookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking from stock'**
  String get hubCookingTitle;

  /// No description provided for @hubCookingHint.
  ///
  /// In en, this message translates to:
  /// **'Plan meals around the stock, the water and the fuel they need.'**
  String get hubCookingHint;

  /// No description provided for @hubCookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Cooking-from-stock plan'**
  String get hubCookingLabel;

  /// No description provided for @hubCookingTemplate.
  ///
  /// In en, this message translates to:
  /// **'Dish: …\nIngredients from stock: …\nWater: …\nFuel and cooking time: …\nSafe place to cook: …'**
  String get hubCookingTemplate;

  /// No description provided for @hubCookingRecipes.
  ///
  /// In en, this message translates to:
  /// **'Open offline recipes'**
  String get hubCookingRecipes;

  /// No description provided for @hubRedundancyTitle.
  ///
  /// In en, this message translates to:
  /// **'Second ways'**
  String get hubRedundancyTitle;

  /// No description provided for @hubRedundancyHint.
  ///
  /// In en, this message translates to:
  /// **'Write down a second way to get water, light, cooking, information and communication.'**
  String get hubRedundancyHint;

  /// No description provided for @hubRedundancyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Water: main way / fallback\nLight: main way / fallback\nCooking: main way / fallback\nInformation and communication: main way / fallback'**
  String get hubRedundancyTemplate;

  /// No description provided for @hubClimateRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Room for cold and heat'**
  String get hubClimateRoomTitle;

  /// No description provided for @hubClimateRoomHint.
  ///
  /// In en, this message translates to:
  /// **'Decide in advance which room to use, what to wear, how to ventilate and how to warm or cool it safely.'**
  String get hubClimateRoomHint;

  /// No description provided for @hubClimateRoomLabel.
  ///
  /// In en, this message translates to:
  /// **'Room for cold and heat'**
  String get hubClimateRoomLabel;

  /// No description provided for @hubClimateRoomTemplate.
  ///
  /// In en, this message translates to:
  /// **'Room: …\nWarmth/cooling: …\nBlankets and clothing: …\nVentilation: …\nCO alarm and safe appliances: …'**
  String get hubClimateRoomTemplate;

  /// No description provided for @hubRadioTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio reception plan'**
  String get hubRadioTitle;

  /// No description provided for @hubRadioHint.
  ///
  /// In en, this message translates to:
  /// **'Write down local FM and DAB stations, the receivers and how they are powered.'**
  String get hubRadioHint;

  /// No description provided for @hubRadioAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a station'**
  String get hubRadioAdd;

  /// No description provided for @hubRadioDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add radio reception'**
  String get hubRadioDialogTitle;

  /// No description provided for @hubRadioStation.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get hubRadioStation;

  /// No description provided for @hubRadioBand.
  ///
  /// In en, this message translates to:
  /// **'Band'**
  String get hubRadioBand;

  /// No description provided for @hubRadioFrequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency or channel'**
  String get hubRadioFrequency;

  /// No description provided for @hubRadioReceiver.
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get hubRadioReceiver;

  /// No description provided for @hubRadioPower.
  ///
  /// In en, this message translates to:
  /// **'Power supply'**
  String get hubRadioPower;

  /// No description provided for @hubRadioDetails.
  ///
  /// In en, this message translates to:
  /// **'{band} · {frequency}\n{receiver} · {power}\nTested: {checked}'**
  String hubRadioDetails(
    String band,
    String frequency,
    String receiver,
    String power,
    String checked,
  );

  /// No description provided for @hubFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency folder'**
  String get hubFolderTitle;

  /// No description provided for @hubFolderHint.
  ///
  /// In en, this message translates to:
  /// **'Keep track of the folder itself — no contents and no personal details.'**
  String get hubFolderHint;

  /// No description provided for @hubFolderLocation.
  ///
  /// In en, this message translates to:
  /// **'Where it is kept'**
  String get hubFolderLocation;

  /// No description provided for @hubFolderLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. a lockable cupboard'**
  String get hubFolderLocationHint;

  /// No description provided for @hubFolderNotSet.
  ///
  /// In en, this message translates to:
  /// **'not set'**
  String get hubFolderNotSet;

  /// No description provided for @hubFolderCopies.
  ///
  /// In en, this message translates to:
  /// **'Copies of important papers are ready'**
  String get hubFolderCopies;

  /// No description provided for @hubFolderTakeAlong.
  ///
  /// In en, this message translates to:
  /// **'Take it when evacuating'**
  String get hubFolderTakeAlong;

  /// No description provided for @hubFolderCheckedToday.
  ///
  /// In en, this message translates to:
  /// **'Checked today'**
  String get hubFolderCheckedToday;

  /// No description provided for @hubCommunicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication plan'**
  String get hubCommunicationTitle;

  /// No description provided for @hubCommunicationHint.
  ///
  /// In en, this message translates to:
  /// **'Who is contacted in what order, who coordinates from outside, and short status messages for overloaded networks.'**
  String get hubCommunicationHint;

  /// No description provided for @hubCommunicationTemplate.
  ///
  /// In en, this message translates to:
  /// **'Who is contacted, and in what order? Who coordinates from outside?\n\nTemplate: We are safe. Next contact at …'**
  String get hubCommunicationTemplate;

  /// No description provided for @hubStatusSafe.
  ///
  /// In en, this message translates to:
  /// **'We are safe. Next contact at …'**
  String get hubStatusSafe;

  /// No description provided for @hubStatusHelp.
  ///
  /// In en, this message translates to:
  /// **'We need help with … Meeting point: …'**
  String get hubStatusHelp;

  /// No description provided for @hubSupportTitle.
  ///
  /// In en, this message translates to:
  /// **'Support plan'**
  String get hubSupportTitle;

  /// No description provided for @hubSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Personal support, medicines, aids and transport during an evacuation.'**
  String get hubSupportHint;

  /// No description provided for @hubSupportTemplate.
  ///
  /// In en, this message translates to:
  /// **'Only what is needed: the help required, medicines, aids, reliable support and transport.'**
  String get hubSupportTemplate;

  /// No description provided for @hubPetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pet emergency plan'**
  String get hubPetsTitle;

  /// No description provided for @hubPetsHint.
  ///
  /// In en, this message translates to:
  /// **'Prepare transport, food, medicines, care and somewhere else to stay for the animals.'**
  String get hubPetsHint;

  /// No description provided for @hubPetsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Carrier, supplies, vet, care, pet-friendly accommodation and copies of the papers.'**
  String get hubPetsTemplate;

  /// No description provided for @hubMobilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle and getting about'**
  String get hubMobilityTitle;

  /// No description provided for @hubMobilityHint.
  ///
  /// In en, this message translates to:
  /// **'A kit in the vehicle, a fuel or charge reserve, other ways to travel, and who collects whom.'**
  String get hubMobilityHint;

  /// No description provided for @hubMobilityLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobility plan'**
  String get hubMobilityLabel;

  /// No description provided for @hubMobilityTemplate.
  ///
  /// In en, this message translates to:
  /// **'Vehicle, charge or fuel target, kit, alternative route, public transport and collection.'**
  String get hubMobilityTemplate;

  /// No description provided for @hubUtilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Utilities cut off'**
  String get hubUtilitiesTitle;

  /// No description provided for @hubUtilitiesHint.
  ///
  /// In en, this message translates to:
  /// **'Where the shut-offs are, and manual alternatives for power, water, gas, heating and telephony.'**
  String get hubUtilitiesHint;

  /// No description provided for @hubUtilitiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Utilities plan'**
  String get hubUtilitiesLabel;

  /// No description provided for @hubUtilitiesTemplate.
  ///
  /// In en, this message translates to:
  /// **'Shut-off points, who to call, backup power, where to draw water, heating and ways to communicate without contact.'**
  String get hubUtilitiesTemplate;

  /// No description provided for @hubMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get hubMaintenanceTitle;

  /// No description provided for @hubMaintenanceHint.
  ///
  /// In en, this message translates to:
  /// **'Check regularly, so the equipment that matters works when it is needed.'**
  String get hubMaintenanceHint;

  /// No description provided for @hubMaintenanceLastChecked.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {date}'**
  String hubMaintenanceLastChecked(String date);

  /// No description provided for @hubEvacuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation cards'**
  String get hubEvacuationTitle;

  /// No description provided for @hubEvacuationHint.
  ///
  /// In en, this message translates to:
  /// **'Meeting points and safe routes, written down so they can be read offline.'**
  String get hubEvacuationHint;

  /// No description provided for @hubEvacuationAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a card'**
  String get hubEvacuationAdd;

  /// No description provided for @hubEvacuationRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove card'**
  String get hubEvacuationRemove;

  /// No description provided for @hubEvacuationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation card'**
  String get hubEvacuationDialogTitle;

  /// No description provided for @hubEvacuationLabel.
  ///
  /// In en, this message translates to:
  /// **'Name, e.g. Home'**
  String get hubEvacuationLabel;

  /// No description provided for @hubEvacuationStart.
  ///
  /// In en, this message translates to:
  /// **'Starting point'**
  String get hubEvacuationStart;

  /// No description provided for @hubEvacuationDestination.
  ///
  /// In en, this message translates to:
  /// **'Meeting point or destination'**
  String get hubEvacuationDestination;

  /// No description provided for @hubEvacuationRoute.
  ///
  /// In en, this message translates to:
  /// **'Route and alternatives'**
  String get hubEvacuationRoute;

  /// No description provided for @hubEvacuationPlaces.
  ///
  /// In en, this message translates to:
  /// **'Important places on the way'**
  String get hubEvacuationPlaces;

  /// No description provided for @hubEvacuationStartOpen.
  ///
  /// In en, this message translates to:
  /// **'Start not set'**
  String get hubEvacuationStartOpen;

  /// No description provided for @hubEvacuationDestinationOpen.
  ///
  /// In en, this message translates to:
  /// **'Destination not set'**
  String get hubEvacuationDestinationOpen;

  /// No description provided for @hubEvacuationSummary.
  ///
  /// In en, this message translates to:
  /// **'{start} → {destination}\nChecked: {checked}'**
  String hubEvacuationSummary(String start, String destination, String checked);

  /// No description provided for @hubEvacuationStartLine.
  ///
  /// In en, this message translates to:
  /// **'Start: {value}'**
  String hubEvacuationStartLine(String value);

  /// No description provided for @hubEvacuationDestinationLine.
  ///
  /// In en, this message translates to:
  /// **'Destination: {value}'**
  String hubEvacuationDestinationLine(String value);

  /// No description provided for @hubEvacuationPlacesLine.
  ///
  /// In en, this message translates to:
  /// **'Important places'**
  String get hubEvacuationPlacesLine;

  /// No description provided for @hubEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Incident log'**
  String get hubEventsTitle;

  /// No description provided for @hubEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Record observations and what was done, with the time, and export them as a PDF if needed.'**
  String get hubEventsHint;

  /// No description provided for @hubEventsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add an entry'**
  String get hubEventsAdd;

  /// No description provided for @hubEventsExport.
  ///
  /// In en, this message translates to:
  /// **'Export as PDF'**
  String get hubEventsExport;

  /// No description provided for @hubEventsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Record an incident'**
  String get hubEventsDialogTitle;

  /// No description provided for @hubEventsKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get hubEventsKind;

  /// No description provided for @hubEventsKindHint.
  ///
  /// In en, this message translates to:
  /// **'Incident'**
  String get hubEventsKindHint;

  /// No description provided for @hubEventsNote.
  ///
  /// In en, this message translates to:
  /// **'Observation or damage'**
  String get hubEventsNote;

  /// No description provided for @hubEventsAction.
  ///
  /// In en, this message translates to:
  /// **'What was done'**
  String get hubEventsAction;

  /// No description provided for @hubEventsObservationLine.
  ///
  /// In en, this message translates to:
  /// **'Observation: {text}'**
  String hubEventsObservationLine(String text);

  /// No description provided for @hubEventsActionLine.
  ///
  /// In en, this message translates to:
  /// **'Action: {text}'**
  String hubEventsActionLine(String text);

  /// No description provided for @hubEventsPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite – incident log'**
  String get hubEventsPdfTitle;

  /// No description provided for @hubEventsPdfFile.
  ///
  /// In en, this message translates to:
  /// **'preppsuite-incident-log.pdf'**
  String get hubEventsPdfFile;

  /// No description provided for @hubActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'What to do, and when'**
  String get hubActionsTitle;

  /// No description provided for @hubActionsHint.
  ///
  /// In en, this message translates to:
  /// **'Preparation by how much warning there is: right now, within 48 hours, and several days ahead.'**
  String get hubActionsHint;

  /// No description provided for @hubActionNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Right now'**
  String get hubActionNowTitle;

  /// No description provided for @hubActionNowBody.
  ///
  /// In en, this message translates to:
  /// **'Read the official message, keep out of danger, switch the radio on and tell your family briefly.'**
  String get hubActionNowBody;

  /// No description provided for @hubActionTwoDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Within 24–48 hours'**
  String get hubActionTwoDaysTitle;

  /// No description provided for @hubActionTwoDaysBody.
  ///
  /// In en, this message translates to:
  /// **'Check water, stock, medicines, batteries and the vehicle. Get the house and the kit ready.'**
  String get hubActionTwoDaysBody;

  /// No description provided for @hubActionDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Several days ahead'**
  String get hubActionDaysTitle;

  /// No description provided for @hubActionDaysBody.
  ///
  /// In en, this message translates to:
  /// **'Go over the evacuation card, arrange support, check the pet and utilities plans.'**
  String get hubActionDaysBody;

  /// No description provided for @hubActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done: {date}'**
  String hubActionDone(String date);

  /// No description provided for @hubCrisisTitle.
  ///
  /// In en, this message translates to:
  /// **'Crisis mode and briefing'**
  String get hubCrisisTitle;

  /// No description provided for @hubCrisisHint.
  ///
  /// In en, this message translates to:
  /// **'A larger display for this page, and a printable briefing for the household or the kit.'**
  String get hubCrisisHint;

  /// No description provided for @hubCrisisSwitch.
  ///
  /// In en, this message translates to:
  /// **'Simplified, larger display'**
  String get hubCrisisSwitch;

  /// No description provided for @hubCrisisSwitchHint.
  ///
  /// In en, this message translates to:
  /// **'Makes the text and controls in the crisis organisation larger.'**
  String get hubCrisisSwitchHint;

  /// No description provided for @hubBriefingButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency briefing as PDF'**
  String get hubBriefingButton;

  /// No description provided for @hubBriefingPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite – emergency briefing'**
  String get hubBriefingPdfTitle;

  /// No description provided for @hubBriefingCreated.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String hubBriefingCreated(String date);

  /// No description provided for @hubBriefingRadio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get hubBriefingRadio;

  /// No description provided for @hubBriefingRadioLine.
  ///
  /// In en, this message translates to:
  /// **'{station}: {band} {frequency} · {receiver}'**
  String hubBriefingRadioLine(
    String station,
    String band,
    String frequency,
    String receiver,
  );

  /// No description provided for @hubBriefingEvacuation.
  ///
  /// In en, this message translates to:
  /// **'Evacuation'**
  String get hubBriefingEvacuation;

  /// No description provided for @hubBriefingEvacuationLine.
  ///
  /// In en, this message translates to:
  /// **'{label}: {start} -> {destination}'**
  String hubBriefingEvacuationLine(
    String label,
    String start,
    String destination,
  );

  /// No description provided for @hubBriefingPdfFile.
  ///
  /// In en, this message translates to:
  /// **'preppsuite-emergency-briefing.pdf'**
  String get hubBriefingPdfFile;

  /// No description provided for @hubAnalogTitle.
  ///
  /// In en, this message translates to:
  /// **'On paper'**
  String get hubAnalogTitle;

  /// No description provided for @hubAnalogHint.
  ///
  /// In en, this message translates to:
  /// **'Keep printouts, maps, notes and spare keys available without a battery or a network.'**
  String get hubAnalogHint;

  /// No description provided for @hubAnalogTemplate.
  ///
  /// In en, this message translates to:
  /// **'Printed maps, a phone list, instructions, cash, spare keys and where they are kept.'**
  String get hubAnalogTemplate;

  /// No description provided for @hubMutualAidTitle.
  ///
  /// In en, this message translates to:
  /// **'Helping each other'**
  String get hubMutualAidTitle;

  /// No description provided for @hubMutualAidHint.
  ///
  /// In en, this message translates to:
  /// **'Plan skills, equipment and safe ways to get in touch locally. Nothing is published.'**
  String get hubMutualAidHint;

  /// No description provided for @hubMutualAidLabel.
  ///
  /// In en, this message translates to:
  /// **'Help and exchange card'**
  String get hubMutualAidLabel;

  /// No description provided for @hubMutualAidTemplate.
  ///
  /// In en, this message translates to:
  /// **'Your own skills and equipment, the support you need, people you trust, and where to hand things over.'**
  String get hubMutualAidTemplate;

  /// No description provided for @hubPracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice and upkeep'**
  String get hubPracticeTitle;

  /// No description provided for @hubPracticeHint.
  ///
  /// In en, this message translates to:
  /// **'Regularly practise with the water filter, cooking, the radio, the kit and the paper routines.'**
  String get hubPracticeHint;

  /// No description provided for @hubPracticeLabel.
  ///
  /// In en, this message translates to:
  /// **'Practice and upkeep plan'**
  String get hubPracticeLabel;

  /// No description provided for @hubPracticeTemplate.
  ///
  /// In en, this message translates to:
  /// **'Next practice: …\nTest the water filter: …\nCook without power: …\nCheck the radio and the kit: …'**
  String get hubPracticeTemplate;

  /// No description provided for @hubNoteEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not written down yet.'**
  String get hubNoteEmpty;

  /// No description provided for @hubNoteUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String hubNoteUpdated(String date);

  /// No description provided for @hubNoteCreate.
  ///
  /// In en, this message translates to:
  /// **'Write a plan'**
  String get hubNoteCreate;

  /// No description provided for @hubNoteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get hubNoteEdit;

  /// No description provided for @hubNoteCopyTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy template'**
  String get hubNoteCopyTemplate;

  /// No description provided for @hubEntryRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove entry'**
  String get hubEntryRemove;

  /// No description provided for @hubClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get hubClose;

  /// No description provided for @hubCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get hubCancel;

  /// No description provided for @hubSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get hubSave;

  /// No description provided for @hubDateTime.
  ///
  /// In en, this message translates to:
  /// **'{date} · {time}'**
  String hubDateTime(String date, String time);

  /// No description provided for @hubTaskBatteriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Batteries and power banks'**
  String get hubTaskBatteriesTitle;

  /// No description provided for @hubTaskBatteriesHint.
  ///
  /// In en, this message translates to:
  /// **'Check the charge and the spares'**
  String get hubTaskBatteriesHint;

  /// No description provided for @hubTaskRadioTitle.
  ///
  /// In en, this message translates to:
  /// **'Radio and reception plan'**
  String get hubTaskRadioTitle;

  /// No description provided for @hubTaskRadioHint.
  ///
  /// In en, this message translates to:
  /// **'Test the stations, the aerial and the power supply'**
  String get hubTaskRadioHint;

  /// No description provided for @hubTaskWaterFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Water filter and canisters'**
  String get hubTaskWaterFilterTitle;

  /// No description provided for @hubTaskWaterFilterHint.
  ///
  /// In en, this message translates to:
  /// **'Check the filter, the seals and the stock'**
  String get hubTaskWaterFilterHint;

  /// No description provided for @hubTaskKitTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency kit'**
  String get hubTaskKitTitle;

  /// No description provided for @hubTaskKitHint.
  ///
  /// In en, this message translates to:
  /// **'Check clothing, light and personal needs'**
  String get hubTaskKitHint;

  /// No description provided for @hubTaskMedicineTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine cabinet'**
  String get hubTaskMedicineTitle;

  /// No description provided for @hubTaskMedicineHint.
  ///
  /// In en, this message translates to:
  /// **'Check expiry dates and personal medicines'**
  String get hubTaskMedicineHint;

  /// No description provided for @hubTaskExtinguisherTitle.
  ///
  /// In en, this message translates to:
  /// **'Extinguisher and smoke alarms'**
  String get hubTaskExtinguisherTitle;

  /// No description provided for @hubTaskExtinguisherHint.
  ///
  /// In en, this message translates to:
  /// **'Check the service date and the batteries'**
  String get hubTaskExtinguisherHint;

  /// No description provided for @hubTaskVehicleTitle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle and getting about'**
  String get hubTaskVehicleTitle;

  /// No description provided for @hubTaskVehicleHint.
  ///
  /// In en, this message translates to:
  /// **'Check fuel, tyres and alternative routes'**
  String get hubTaskVehicleHint;

  /// No description provided for @hubFolderCheckedTodayWith.
  ///
  /// In en, this message translates to:
  /// **'Checked today · last {date}'**
  String hubFolderCheckedTodayWith(String date);

  /// No description provided for @hubBriefingCommunication.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get hubBriefingCommunication;

  /// No description provided for @hubBriefingSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get hubBriefingSupport;

  /// No description provided for @hubBriefingPets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get hubBriefingPets;

  /// No description provided for @hubBriefingMobility.
  ///
  /// In en, this message translates to:
  /// **'Getting about'**
  String get hubBriefingMobility;

  /// No description provided for @hubBriefingUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get hubBriefingUtilities;

  /// No description provided for @hubBriefingPowerOutage.
  ///
  /// In en, this message translates to:
  /// **'Power cut'**
  String get hubBriefingPowerOutage;

  /// No description provided for @hubBriefingRedundancy.
  ///
  /// In en, this message translates to:
  /// **'Second ways'**
  String get hubBriefingRedundancy;

  /// No description provided for @hubBriefingClimate.
  ///
  /// In en, this message translates to:
  /// **'Cold and heat'**
  String get hubBriefingClimate;

  /// No description provided for @hubRadioPowerExample.
  ///
  /// In en, this message translates to:
  /// **'Batteries'**
  String get hubRadioPowerExample;

  /// No description provided for @hubEventsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Observation'**
  String get hubEventsNoteHint;

  /// No description provided for @hubEventSummary.
  ///
  /// In en, this message translates to:
  /// **'{when}\n{text}'**
  String hubEventSummary(String when, String text);

  /// No description provided for @hubSituationTitle.
  ///
  /// In en, this message translates to:
  /// **'Something is happening'**
  String get hubSituationTitle;

  /// No description provided for @hubSituationOutage.
  ///
  /// In en, this message translates to:
  /// **'{hours,plural,=0{Power cut, just started}=1{Power cut for an hour}other{Power cut for {hours} hours}}'**
  String hubSituationOutage(int hours);

  /// No description provided for @hubSituationMoreWarnings.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{And one more warning}other{And {count} more warnings}}'**
  String hubSituationMoreWarnings(int count);

  /// No description provided for @hubSituationCrisisMode.
  ///
  /// In en, this message translates to:
  /// **'Switch to the larger display'**
  String get hubSituationCrisisMode;

  /// No description provided for @hubSituationLog.
  ///
  /// In en, this message translates to:
  /// **'Record it in the log'**
  String get hubSituationLog;

  /// No description provided for @hubSituationOutageKind.
  ///
  /// In en, this message translates to:
  /// **'Power cut'**
  String get hubSituationOutageKind;

  /// No description provided for @hubFolderReportButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency folder as PDF'**
  String get hubFolderReportButton;

  /// No description provided for @hubFolderReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency folder'**
  String get hubFolderReportTitle;

  /// No description provided for @hubFolderReportIntro.
  ///
  /// In en, this message translates to:
  /// **'Print this and keep it away from the home: with relatives, in the vehicle or in the kit. It does not replace the original documents.'**
  String get hubFolderReportIntro;

  /// No description provided for @hubFolderReportFile.
  ///
  /// In en, this message translates to:
  /// **'preppsuite-emergency-folder.pdf'**
  String get hubFolderReportFile;

  /// No description provided for @hubFolderReportRoute.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get hubFolderReportRoute;

  /// No description provided for @hubFolderReportPlaces.
  ///
  /// In en, this message translates to:
  /// **'Important places'**
  String get hubFolderReportPlaces;

  /// No description provided for @hubFolderReportAutonomy.
  ///
  /// In en, this message translates to:
  /// **'Self-sufficiency'**
  String get hubFolderReportAutonomy;

  /// No description provided for @mapWaterTitle.
  ///
  /// In en, this message translates to:
  /// **'Drinking water affected'**
  String get mapWaterTitle;

  /// No description provided for @mapWaterStock.
  ///
  /// In en, this message translates to:
  /// **'Your own drinking water: {value}'**
  String mapWaterStock(String value);

  /// No description provided for @mapWaterStockUnknown.
  ///
  /// In en, this message translates to:
  /// **'How far your own supply reaches is still open: {reason}.'**
  String mapWaterStockUnknown(String reason);

  /// No description provided for @mapWaterNearby.
  ///
  /// In en, this message translates to:
  /// **'Drinking water nearby'**
  String get mapWaterNearby;

  /// No description provided for @mapWaterAdviceNote.
  ///
  /// In en, this message translates to:
  /// **'What to do with the water is in the warning itself. This app publishes no figures of its own on that.'**
  String get mapWaterAdviceNote;

  /// No description provided for @setupChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Set up a household'**
  String get setupChoiceTitle;

  /// No description provided for @setupChoiceIntro.
  ///
  /// In en, this message translates to:
  /// **'Does this household already exist on another device? Then bring it over instead of starting a new one — otherwise you end up with two households side by side that never merge.'**
  String get setupChoiceIntro;

  /// No description provided for @setupChoiceNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Start a new household'**
  String get setupChoiceNewTitle;

  /// No description provided for @setupChoiceNewBody.
  ///
  /// In en, this message translates to:
  /// **'The first device. Everything else can be handed over from here later.'**
  String get setupChoiceNewBody;

  /// No description provided for @setupChoiceFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a shared folder'**
  String get setupChoiceFolderTitle;

  /// No description provided for @setupChoiceFolderBody.
  ///
  /// In en, this message translates to:
  /// **'If the household lives in a folder both devices can see — iCloud, Nextcloud, a stick, or a folder some sync app keeps in step — this device joins it and stays up to date by itself.'**
  String get setupChoiceFolderBody;

  /// No description provided for @setupChoiceScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Take it from another device'**
  String get setupChoiceScanTitle;

  /// No description provided for @setupChoiceScanBody.
  ///
  /// In en, this message translates to:
  /// **'The other device shows a QR code and this one reads it. Over the local network the whole household goes across in one go; with no network, as a sequence of images.'**
  String get setupChoiceScanBody;

  /// No description provided for @setupChoiceSafeNote.
  ///
  /// In en, this message translates to:
  /// **'Now is the safest moment for this: this device has no data of its own yet that would have to be re-stamped.'**
  String get setupChoiceSafeNote;

  /// No description provided for @setupFolderSearching.
  ///
  /// In en, this message translates to:
  /// **'Reading the folder …'**
  String get setupFolderSearching;

  /// No description provided for @setupFolderFound.
  ///
  /// In en, this message translates to:
  /// **'Household found: {name}'**
  String setupFolderFound(String name);

  /// No description provided for @setupFolderFoundBody.
  ///
  /// In en, this message translates to:
  /// **'This device will join it. Name and country come from the folder; region and household size stay with this device.'**
  String get setupFolderFoundBody;

  /// No description provided for @setupFolderEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no household in this folder yet. A new one will be created and written into it.'**
  String get setupFolderEmpty;

  /// No description provided for @setupScanHint.
  ///
  /// In en, this message translates to:
  /// **'First fill in what belongs to this device. Then read the other device\'s QR code, and the household is taken over.'**
  String get setupScanHint;

  /// No description provided for @setupScanContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue to the scan'**
  String get setupScanContinue;

  /// No description provided for @setupJoinFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not join: {reason}'**
  String setupJoinFailed(String reason);

  /// No description provided for @setupDoneFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder connected. The household keeps itself in step from now on.'**
  String get setupDoneFolder;

  /// No description provided for @setupDoneScan.
  ///
  /// In en, this message translates to:
  /// **'Household taken over. {rows, plural, =0{Nothing new was in it.} =1{One entry arrived.} other{{rows} entries arrived.}}'**
  String setupDoneScan(int rows);

  /// No description provided for @setupScanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled — no household was taken over.'**
  String get setupScanCancelled;

  /// No description provided for @setupAdopted.
  ///
  /// In en, this message translates to:
  /// **'Household “{name}” taken over.'**
  String setupAdopted(String name);

  /// No description provided for @transferAdoptHousehold.
  ///
  /// In en, this message translates to:
  /// **'Take over this code\'s household'**
  String get transferAdoptHousehold;

  /// No description provided for @transferConflictTitle.
  ///
  /// In en, this message translates to:
  /// **'Two different households'**
  String get transferConflictTitle;

  /// No description provided for @transferConflictBody.
  ///
  /// In en, this message translates to:
  /// **'This device belongs to “{mine}”, the code belongs to a different household. What happens next cannot be undone: two merged sets of data cannot be separated again.'**
  String transferConflictBody(String mine);

  /// No description provided for @transferConflictMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge them'**
  String get transferConflictMerge;

  /// No description provided for @transferConflictMergeBody.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=0{This device has nothing to bring and simply joins the other household.}=1{The one entry of its own moves into the other household, and that household\'s data comes here. Nothing is lost.}other{The {count} entries of its own move into the other household, and that household\'s data comes here. Nothing is lost.}}'**
  String transferConflictMergeBody(int count);

  /// No description provided for @transferConflictReplace.
  ///
  /// In en, this message translates to:
  /// **'Discard this device\'s data'**
  String get transferConflictReplace;

  /// No description provided for @transferConflictReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'{count,plural,=1{The one entry of its own is deleted.}other{The {count} entries of its own are deleted.}} Only the other household remains here afterwards.'**
  String transferConflictReplaceBody(int count);

  /// No description provided for @transferConflictKeep.
  ///
  /// In en, this message translates to:
  /// **'Change nothing'**
  String get transferConflictKeep;

  /// No description provided for @transferConflictKeepBody.
  ///
  /// In en, this message translates to:
  /// **'Nothing is taken over. If the other device should join this one instead, show the code there and read it there.'**
  String get transferConflictKeepBody;

  /// No description provided for @transferConflictCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled. Nothing was changed.'**
  String get transferConflictCancelled;

  /// No description provided for @transferConflictReplaced.
  ///
  /// In en, this message translates to:
  /// **'This device\'s data discarded, the other household taken over.'**
  String get transferConflictReplaced;

  /// No description provided for @backupShare.
  ///
  /// In en, this message translates to:
  /// **'Share the backup'**
  String get backupShare;

  /// No description provided for @backupShareHint.
  ///
  /// In en, this message translates to:
  /// **'Hand it to another app — a cloud the file picker cannot reach, for instance. The file is encrypted with your passphrase; whoever gets it without that passphrase can do nothing with it.'**
  String get backupShareHint;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'PreppSuite backup'**
  String get backupShareSubject;

  /// No description provided for @toolsHubTitle.
  ///
  /// In en, this message translates to:
  /// **'Crisis organisation'**
  String get toolsHubTitle;

  /// No description provided for @toolsHubBody.
  ///
  /// In en, this message translates to:
  /// **'Radio, emergency folder, upkeep, evacuation cards and incident log'**
  String get toolsHubBody;

  /// No description provided for @toolsLearnTitle.
  ///
  /// In en, this message translates to:
  /// **'A quick round'**
  String get toolsLearnTitle;

  /// No description provided for @toolsLearnBody.
  ///
  /// In en, this message translates to:
  /// **'Short offline refreshers, alongside the drills and the knowledge archive.'**
  String get toolsLearnBody;

  /// No description provided for @toolsAnswerRight.
  ///
  /// In en, this message translates to:
  /// **'Correct. {explanation}'**
  String toolsAnswerRight(String explanation);

  /// No description provided for @toolsAnswerWrong.
  ///
  /// In en, this message translates to:
  /// **'Have another look: {explanation}'**
  String toolsAnswerWrong(String explanation);

  /// No description provided for @toolsDrillDuration.
  ///
  /// In en, this message translates to:
  /// **'Preparation: {minutes} minutes'**
  String toolsDrillDuration(int minutes);

  /// No description provided for @toolsDrillMeta.
  ///
  /// In en, this message translates to:
  /// **'{duration} · {completed}'**
  String toolsDrillMeta(String duration, String completed);

  /// No description provided for @toolsLessonCommunicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication'**
  String get toolsLessonCommunicationTitle;

  /// No description provided for @toolsLessonCommunicationSummary.
  ///
  /// In en, this message translates to:
  /// **'Take load off the networks and coordinate contacts.'**
  String get toolsLessonCommunicationSummary;

  /// No description provided for @toolsLessonCommunicationQuestion.
  ///
  /// In en, this message translates to:
  /// **'Which way usually works best when the mobile network is overloaded?'**
  String get toolsLessonCommunicationQuestion;

  /// No description provided for @toolsLessonCommunicationAnswerA.
  ///
  /// In en, this message translates to:
  /// **'A long call'**
  String get toolsLessonCommunicationAnswerA;

  /// No description provided for @toolsLessonCommunicationAnswerB.
  ///
  /// In en, this message translates to:
  /// **'A short message naming a time to reply'**
  String get toolsLessonCommunicationAnswerB;

  /// No description provided for @toolsLessonCommunicationAnswerC.
  ///
  /// In en, this message translates to:
  /// **'Redialling over and over'**
  String get toolsLessonCommunicationAnswerC;

  /// No description provided for @toolsLessonCommunicationExplanation.
  ///
  /// In en, this message translates to:
  /// **'Short messages need less network capacity and spare the battery.'**
  String get toolsLessonCommunicationExplanation;

  /// No description provided for @toolsLessonEvacuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation'**
  String get toolsLessonEvacuationTitle;

  /// No description provided for @toolsLessonEvacuationSummary.
  ///
  /// In en, this message translates to:
  /// **'Keep the plan, the kit and the meeting point ready.'**
  String get toolsLessonEvacuationSummary;

  /// No description provided for @toolsLessonEvacuationQuestion.
  ///
  /// In en, this message translates to:
  /// **'What should be checked before an evacuation?'**
  String get toolsLessonEvacuationQuestion;

  /// No description provided for @toolsLessonEvacuationAnswerA.
  ///
  /// In en, this message translates to:
  /// **'Meeting point, route and the support anyone needs'**
  String get toolsLessonEvacuationAnswerA;

  /// No description provided for @toolsLessonEvacuationAnswerB.
  ///
  /// In en, this message translates to:
  /// **'Only the weather app'**
  String get toolsLessonEvacuationAnswerB;

  /// No description provided for @toolsLessonEvacuationAnswerC.
  ///
  /// In en, this message translates to:
  /// **'Only the fuel gauge'**
  String get toolsLessonEvacuationAnswerC;

  /// No description provided for @toolsLessonEvacuationExplanation.
  ///
  /// In en, this message translates to:
  /// **'A clear meeting point, the route and individual needs prevent stress and bad decisions.'**
  String get toolsLessonEvacuationExplanation;

  /// No description provided for @toolsLessonPowerTitle.
  ///
  /// In en, this message translates to:
  /// **'Power cut'**
  String get toolsLessonPowerTitle;

  /// No description provided for @toolsLessonPowerSummary.
  ///
  /// In en, this message translates to:
  /// **'Secure light, information and energy.'**
  String get toolsLessonPowerSummary;

  /// No description provided for @toolsLessonPowerQuestion.
  ///
  /// In en, this message translates to:
  /// **'What is the battery or wind-up radio for?'**
  String get toolsLessonPowerQuestion;

  /// No description provided for @toolsLessonPowerAnswerA.
  ///
  /// In en, this message translates to:
  /// **'As a replacement for official warnings'**
  String get toolsLessonPowerAnswerA;

  /// No description provided for @toolsLessonPowerAnswerB.
  ///
  /// In en, this message translates to:
  /// **'As an additional channel for information'**
  String get toolsLessonPowerAnswerB;

  /// No description provided for @toolsLessonPowerAnswerC.
  ///
  /// In en, this message translates to:
  /// **'Only for listening to music'**
  String get toolsLessonPowerAnswerC;

  /// No description provided for @toolsLessonPowerExplanation.
  ///
  /// In en, this message translates to:
  /// **'Radio adds to the system\'s warnings and works when the internet does not.'**
  String get toolsLessonPowerExplanation;

  /// No description provided for @toolsDrillPowerTitle.
  ///
  /// In en, this message translates to:
  /// **'72 hours without power'**
  String get toolsDrillPowerTitle;

  /// No description provided for @toolsDrillPowerStepA.
  ///
  /// In en, this message translates to:
  /// **'Put out light, radio and a power bank'**
  String get toolsDrillPowerStepA;

  /// No description provided for @toolsDrillPowerStepB.
  ///
  /// In en, this message translates to:
  /// **'Check water, stove and supplies'**
  String get toolsDrillPowerStepB;

  /// No description provided for @toolsDrillPowerStepC.
  ///
  /// In en, this message translates to:
  /// **'Keep fridge and freezer shut'**
  String get toolsDrillPowerStepC;

  /// No description provided for @toolsDrillEvacuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Evacuation in 15 minutes'**
  String get toolsDrillEvacuationTitle;

  /// No description provided for @toolsDrillEvacuationStepA.
  ///
  /// In en, this message translates to:
  /// **'Pack documents and medicines'**
  String get toolsDrillEvacuationStepA;

  /// No description provided for @toolsDrillEvacuationStepB.
  ///
  /// In en, this message translates to:
  /// **'Check the meeting point and route on the offline map'**
  String get toolsDrillEvacuationStepB;

  /// No description provided for @toolsDrillEvacuationStepC.
  ///
  /// In en, this message translates to:
  /// **'Go over who is in the household and how to reach them'**
  String get toolsDrillEvacuationStepC;

  /// No description provided for @toolsDrillCommunicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Communication is down'**
  String get toolsDrillCommunicationTitle;

  /// No description provided for @toolsDrillCommunicationStepA.
  ///
  /// In en, this message translates to:
  /// **'Check local radio and the warnings'**
  String get toolsDrillCommunicationStepA;

  /// No description provided for @toolsDrillCommunicationStepB.
  ///
  /// In en, this message translates to:
  /// **'Keep nearby contacts and the meeting point at hand'**
  String get toolsDrillCommunicationStepB;

  /// No description provided for @toolsDrillCommunicationStepC.
  ///
  /// In en, this message translates to:
  /// **'Use a radio only on a service you are allowed to use'**
  String get toolsDrillCommunicationStepC;

  /// No description provided for @recipeOnlyInGerman.
  ///
  /// In en, this message translates to:
  /// **'Only available in German'**
  String get recipeOnlyInGerman;

  /// No description provided for @recipeOnlyInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Only available in English'**
  String get recipeOnlyInEnglish;

  /// No description provided for @emergencyMapReady.
  ///
  /// In en, this message translates to:
  /// **'Opened and ready to use'**
  String get emergencyMapReady;

  /// No description provided for @emergencyMapMissing.
  ///
  /// In en, this message translates to:
  /// **'No checked map package yet'**
  String get emergencyMapMissing;

  /// No description provided for @emergencyKnowledgeReady.
  ///
  /// In en, this message translates to:
  /// **'Archive opened and ready to use'**
  String get emergencyKnowledgeReady;

  /// No description provided for @emergencyKnowledgeMissing.
  ///
  /// In en, this message translates to:
  /// **'No checked knowledge archive yet'**
  String get emergencyKnowledgeMissing;

  /// No description provided for @knowledgeNoBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet. Open an article and tap the bookmark symbol.'**
  String get knowledgeNoBookmarks;

  /// No description provided for @knowledgeInOpenArchive.
  ///
  /// In en, this message translates to:
  /// **'In the archive that is open'**
  String get knowledgeInOpenArchive;

  /// No description provided for @knowledgeOpenArchiveFirst.
  ///
  /// In en, this message translates to:
  /// **'Open the archive in the library first'**
  String get knowledgeOpenArchiveFirst;

  /// No description provided for @radioCbCallingChannel.
  ///
  /// In en, this message translates to:
  /// **'The usual calling and distress channel on CB radio.'**
  String get radioCbCallingChannel;

  /// No description provided for @radioCbRoadChannel.
  ///
  /// In en, this message translates to:
  /// **'A channel widely used on the road and by lorry drivers.'**
  String get radioCbRoadChannel;

  /// No description provided for @caloriesPer100Label.
  ///
  /// In en, this message translates to:
  /// **'Calories per {basis} (kcal, optional)'**
  String caloriesPer100Label(String basis);

  /// No description provided for @unitMeasureHelper.
  ///
  /// In en, this message translates to:
  /// **'For food and water: g, kg, ml or l. Nutrition is printed per 100 g, and a tin has no weight until somebody reads it.'**
  String get unitMeasureHelper;

  /// No description provided for @unitMeasureRequired.
  ///
  /// In en, this message translates to:
  /// **'This needs a measure: g, kg, ml or l.'**
  String get unitMeasureRequired;

  /// No description provided for @nutritionPer100Label.
  ///
  /// In en, this message translates to:
  /// **'{nutrient} per {basis}'**
  String nutritionPer100Label(String nutrient, String basis);

  /// No description provided for @foodWithoutMeasureTitle.
  ///
  /// In en, this message translates to:
  /// **'Not counted: a unit with no measure'**
  String get foodWithoutMeasureTitle;

  /// No description provided for @foodWithoutMeasureBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{One food is} other{{count} foods are}} counted in a unit no label can be applied to — a tin, a jar. {count, plural, =1{It does} other{They do}} not count towards the supply calculator until the unit is g, kg, ml or l.'**
  String foodWithoutMeasureBody(int count);

  /// No description provided for @transferInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The connection was made but the transfer did not finish. Keep both devices awake and try again — with a lot of photos it takes a moment.'**
  String get transferInterrupted;

  /// No description provided for @transferLastSeen.
  ///
  /// In en, this message translates to:
  /// **'Last read: frame {frame}'**
  String transferLastSeen(int frame);

  /// No description provided for @transferLastSeenMixed.
  ///
  /// In en, this message translates to:
  /// **'Last read: frame {frame} · {discarded} frames belonged to a different transfer'**
  String transferLastSeenMixed(int frame, int discarded);
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
