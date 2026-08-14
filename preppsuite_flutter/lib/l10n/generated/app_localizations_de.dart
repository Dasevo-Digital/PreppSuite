// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'PreppSuite';

  @override
  String get signOutButton => 'Abmelden';

  @override
  String get onboardingChooseTitle => 'Willkommen bei PreppSuite';

  @override
  String get onboardingChooseSubtitle =>
      'Erstelle einen neuen Haushalt oder tritt einem bestehenden bei.';

  @override
  String get createHouseholdButton => 'Haushalt erstellen';

  @override
  String get joinHouseholdButton => 'Haushalt beitreten';

  @override
  String get createHouseholdTitle => 'Haushalt erstellen';

  @override
  String get householdNameLabel => 'Name des Haushalts';

  @override
  String get countryLabel => 'Land';

  @override
  String get regionKeyLabel => 'Amtlicher Regionalschlüssel (optional)';

  @override
  String get regionKeyHelper =>
      'Nur für Deutschland, für genauere Warnmeldungen';

  @override
  String get displayNameLabel => 'Dein Anzeigename';

  @override
  String get createButton => 'Erstellen';

  @override
  String get joinHouseholdTitle => 'Haushalt beitreten';

  @override
  String get inviteCodeLabel => 'Einladungscode';

  @override
  String get joinButton => 'Beitreten';

  @override
  String get householdOverviewTitle => 'Mein Haushalt';

  @override
  String get inviteCodeSectionTitle => 'Einladungscode';

  @override
  String get rotateInviteCodeButton => 'Neuen Code erzeugen';

  @override
  String get membersSectionTitle => 'Mitglieder';

  @override
  String get roleOwner => 'Besitzer';

  @override
  String get roleMember => 'Mitglied';

  @override
  String get loadingHousehold => 'Haushalt wird geladen…';

  @override
  String get fieldRequired => 'Dieses Feld darf nicht leer sein.';

  @override
  String errorGeneric(String error) {
    return 'Es ist ein Fehler aufgetreten: $error';
  }

  @override
  String get errorInvalidInviteCode => 'Dieser Einladungscode ist ungültig.';

  @override
  String get errorAlreadyInHousehold => 'Du gehörst bereits einem Haushalt an.';

  @override
  String get errorNotOwner => 'Nur der Besitzer kann diese Aktion ausführen.';

  @override
  String get errorNotAMember => 'Du bist kein Mitglied dieses Haushalts.';

  @override
  String get navInventory => 'Vorrat';

  @override
  String get navHousehold => 'Haushalt';

  @override
  String get inventoryTitle => 'Vorrat';

  @override
  String get inventoryEmpty =>
      'Noch keine Vorräte erfasst. Tippe auf +, um den ersten Eintrag anzulegen.';

  @override
  String get addItemButton => 'Eintrag hinzufügen';

  @override
  String get editItemTitle => 'Eintrag bearbeiten';

  @override
  String get addItemTitle => 'Eintrag hinzufügen';

  @override
  String get itemNameLabel => 'Name';

  @override
  String get categoryLabel => 'Kategorie';

  @override
  String get categoryWater => 'Wasser';

  @override
  String get categoryFood => 'Essen';

  @override
  String get categoryMedical => 'Medizin';

  @override
  String get categoryTools => 'Werkzeug';

  @override
  String get categoryDocuments => 'Dokumente';

  @override
  String get categoryEnergy => 'Energie';

  @override
  String get categoryHygiene => 'Hygiene';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get quantityLabel => 'Menge';

  @override
  String get unitLabel => 'Einheit';

  @override
  String get storageLocationLabel => 'Lagerort';

  @override
  String get expirationDateLabel => 'Ablaufdatum (optional)';

  @override
  String get minQuantityLabel => 'Mindestbestand (optional)';

  @override
  String get notesLabel => 'Notizen (optional)';

  @override
  String get saveButton => 'Speichern';

  @override
  String get deleteButton => 'Löschen';

  @override
  String get lowStockBadge => 'Niedriger Bestand';

  @override
  String get expiredBadge => 'Abgelaufen';

  @override
  String get invalidNumber => 'Bitte eine gültige Zahl eingeben.';

  @override
  String get clearDateButton => 'Datum entfernen';

  @override
  String get scanBarcodeButton => 'Barcode scannen';

  @override
  String scannedBarcodeLabel(String barcode) {
    return 'Barcode: $barcode';
  }

  @override
  String get productNotFound =>
      'Produkt nicht gefunden — bitte manuell ausfüllen.';

  @override
  String get navChecklists => 'Checklisten';

  @override
  String get navBudget => 'Budget';

  @override
  String get checklistsTitle => 'Checklisten';

  @override
  String get checklistsEmpty =>
      'Noch keine Checklisten. Tippe auf +, um die erste zu erstellen.';

  @override
  String get createTemplateButton => 'Neue Checkliste';

  @override
  String get createTemplateTitle => 'Neue Checkliste';

  @override
  String get templateTitleLabel => 'Name der Checkliste';

  @override
  String get checklistCategoryFirstAid => 'Erste Hilfe';

  @override
  String get checklistCategoryCustom => 'Eigene';

  @override
  String get builtInBadge => 'Vorlage';

  @override
  String get duplicateTemplateAction => 'Duplizieren';

  @override
  String get deleteTemplateAction => 'Checkliste löschen';

  @override
  String get checklistItemTitleLabel => 'Eintrag';

  @override
  String get addChecklistItemHint => 'Eintrag hinzufügen…';

  @override
  String get addButton => 'Hinzufügen';

  @override
  String checklistProgress(int checked, int total) {
    return '$checked von $total';
  }

  @override
  String get budgetTitle => 'Budget';

  @override
  String get budgetEmpty =>
      'Noch keine Ausgaben erfasst. Tippe auf +, um den ersten Eintrag anzulegen.';

  @override
  String get addBudgetEntryButton => 'Eintrag hinzufügen';

  @override
  String get addBudgetEntryTitle => 'Eintrag hinzufügen';

  @override
  String get editBudgetEntryTitle => 'Eintrag bearbeiten';

  @override
  String get budgetLabelLabel => 'Bezeichnung';

  @override
  String get amountLabel => 'Betrag';

  @override
  String get currencyLabel => 'Währung';

  @override
  String get purchaseDateLabel => 'Kaufdatum (optional)';

  @override
  String get budgetTotalLabel => 'Gesamt';

  @override
  String get warningsTitle => 'Warnungen';

  @override
  String get warningsEmpty => 'Aktuell keine Warnungen für deine Region.';

  @override
  String get warningSeverityMinor => 'Gering';

  @override
  String get warningSeverityModerate => 'Mäßig';

  @override
  String get warningSeveritySevere => 'Schwer';

  @override
  String get warningSeverityExtreme => 'Extrem';

  @override
  String warningBannerMore(int count) {
    return '+$count weitere';
  }

  @override
  String get viewAllWarningsAction => 'Alle anzeigen';

  @override
  String get warningExpiredLabel => 'Abgelaufen';

  @override
  String get warningSourceBbk => 'Bundesamt für Bevölkerungsschutz (BBK)';

  @override
  String get warningSourceMeteoalarm => 'MeteoAlarm';

  @override
  String get exportPdfButton => 'Fehlende Ausrüstung exportieren';

  @override
  String get pdfReportTitle => 'Bericht: Fehlende Ausrüstung';

  @override
  String pdfGeneratedOn(String date) {
    return 'Erstellt am $date';
  }

  @override
  String get pdfChecklistSectionTitle => 'Offene Checklisten-Punkte';

  @override
  String get pdfNoMissingChecklistItems =>
      'Nichts offen — alle Checklisten sind vollständig.';

  @override
  String get pdfInventorySectionTitle => 'Vorräte unter Mindestbestand';

  @override
  String get pdfNoLowStockItems => 'Nichts unter dem Mindestbestand.';

  @override
  String get pdfColumnItem => 'Artikel';

  @override
  String get pdfColumnQuantity => 'Menge';

  @override
  String get pdfColumnMinQuantity => 'Mindestbestand';

  @override
  String get pdfColumnUnit => 'Einheit';

  @override
  String get settingsSectionTitle => 'Einstellungen';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageGermanOption => 'Deutsch';

  @override
  String get languageEnglishOption => 'English';

  @override
  String get serverAddressLabel => 'Server-Adresse';

  @override
  String inventoryAttentionTooltip(int count) {
    return '$count Artikel mit niedrigem Bestand oder abgelaufen';
  }
}
