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
