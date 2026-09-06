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

  /// No description provided for @signOutButton.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOutButton;

  /// No description provided for @onboardingChooseTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PreppSuite'**
  String get onboardingChooseTitle;

  /// No description provided for @onboardingChooseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new household or join an existing one.'**
  String get onboardingChooseSubtitle;

  /// No description provided for @createHouseholdButton.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get createHouseholdButton;

  /// No description provided for @joinHouseholdButton.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get joinHouseholdButton;

  /// No description provided for @createHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Create household'**
  String get createHouseholdTitle;

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

  /// No description provided for @regionKeyExplanationTooltip.
  ///
  /// In en, this message translates to:
  /// **'What is this?'**
  String get regionKeyExplanationTooltip;

  /// No description provided for @regionKeyExplanationTitle.
  ///
  /// In en, this message translates to:
  /// **'Official Regional Key (ARS)'**
  String get regionKeyExplanationTitle;

  /// No description provided for @regionKeyExplanationBody.
  ///
  /// In en, this message translates to:
  /// **'The \"amtlicher Regionalschlüssel\" (ARS) is a 12-digit code that German authorities use to uniquely identify every municipality, down to the district and locality level. It\'s issued by the national statistics office (Destatis) and used, among other things, to precisely scope official warnings (BBK/NINA) to your area instead of your entire federal state.\n\nWithout it, warnings are only filtered by country. With it, you get warnings specific to your municipality.\n\nYou can look up your municipality\'s ARS via the Federal Statistical Office\'s municipality directory (\"Gemeindeverzeichnis\") or your local BBK warning app. Leave this field empty if you don\'t know it — you can add it later in household settings.'**
  String get regionKeyExplanationBody;

  /// No description provided for @regionKeyExplanationClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get regionKeyExplanationClose;

  /// No description provided for @displayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your display name'**
  String get displayNameLabel;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @joinHouseholdTitle.
  ///
  /// In en, this message translates to:
  /// **'Join household'**
  String get joinHouseholdTitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeLabel;

  /// No description provided for @joinButton.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get joinButton;

  /// No description provided for @householdOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'My household'**
  String get householdOverviewTitle;

  /// No description provided for @inviteCodeSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCodeSectionTitle;

  /// No description provided for @rotateInviteCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get rotateInviteCodeButton;

  /// No description provided for @membersSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get membersSectionTitle;

  /// No description provided for @roleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get roleOwner;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @loadingHousehold.
  ///
  /// In en, this message translates to:
  /// **'Loading household…'**
  String get loadingHousehold;

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

  /// No description provided for @errorInvalidInviteCode.
  ///
  /// In en, this message translates to:
  /// **'This invite code is not valid.'**
  String get errorInvalidInviteCode;

  /// No description provided for @errorAlreadyInHousehold.
  ///
  /// In en, this message translates to:
  /// **'You already belong to a household.'**
  String get errorAlreadyInHousehold;

  /// No description provided for @errorNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the household\'s owner can do this.'**
  String get errorNotOwner;

  /// No description provided for @errorNotAMember.
  ///
  /// In en, this message translates to:
  /// **'You are not a member of this household.'**
  String get errorNotAMember;

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

  /// No description provided for @supplyCalculatorPersonCountLabel.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get supplyCalculatorPersonCountLabel;

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

  /// No description provided for @csvImportRowsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Rows'**
  String get csvImportRowsSectionTitle;

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

  /// No description provided for @navBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get navBudget;

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

  /// No description provided for @checklistItemTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get checklistItemTitleLabel;

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

  /// No description provided for @viewAllWarningsAction.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAllWarningsAction;

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

  /// No description provided for @settingsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSectionTitle;

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

  /// No description provided for @serverAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get serverAddressLabel;

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

  /// No description provided for @settingsRegionLabelLabel.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get settingsRegionLabelLabel;

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

  /// No description provided for @settingsLocationSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'{state} added as an additional region.'**
  String settingsLocationSuccessMessage(String state);

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

  /// No description provided for @syncRetryButton.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get syncRetryButton;

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

  /// No description provided for @personCountLabel.
  ///
  /// In en, this message translates to:
  /// **'People in the household'**
  String get personCountLabel;

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

  /// No description provided for @offlineMapHelp.
  ///
  /// In en, this message translates to:
  /// **'Where do I get such a file?'**
  String get offlineMapHelp;

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

  /// No description provided for @knowledgeForgetAction.
  ///
  /// In en, this message translates to:
  /// **'Remove file'**
  String get knowledgeForgetAction;

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

  /// No description provided for @knowledgeSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Type a beginning to search.'**
  String get knowledgeSearchPrompt;

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

  /// No description provided for @mapDownloadIntro.
  ///
  /// In en, this message translates to:
  /// **'Move the map to the area you need offline. Exactly what you can see is what gets downloaded.'**
  String get mapDownloadIntro;

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

  /// No description provided for @mapDownloadApiKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'This source needs a key.'**
  String get mapDownloadApiKeyMissing;

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

  /// No description provided for @mapDownloadPlaceTooLarge.
  ///
  /// In en, this message translates to:
  /// **'{name} is too large even at the coarsest level. Choose somewhere smaller.'**
  String mapDownloadPlaceTooLarge(String name);

  /// No description provided for @mapDownloadDeepestPossible.
  ///
  /// In en, this message translates to:
  /// **'At level 14 that would be {count} tiles — too many. Level {level} is the deepest this area goes.'**
  String mapDownloadDeepestPossible(String count, String level);

  /// No description provided for @mapDownloadScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get mapDownloadScopeLabel;

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

  /// No description provided for @supplyCalculatorEditHousehold.
  ///
  /// In en, this message translates to:
  /// **'Change in the household'**
  String get supplyCalculatorEditHousehold;

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
  String overviewSupplyCalories(Object current, Object target);

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
