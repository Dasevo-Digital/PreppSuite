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
  String get regionKeyExplanationTooltip => 'Was ist das?';

  @override
  String get regionKeyExplanationTitle => 'Amtlicher Regionalschlüssel (ARS)';

  @override
  String get regionKeyExplanationBody =>
      'Der amtliche Regionalschlüssel (ARS) ist ein 12-stelliger Code, mit dem deutsche Behörden jede Gemeinde eindeutig identifizieren – bis hinunter zur Kreis- und Gemeindeteil-Ebene. Er wird vom Statistischen Bundesamt (Destatis) vergeben und unter anderem genutzt, um amtliche Warnmeldungen (BBK/NINA) präzise auf deinen Ort statt auf dein ganzes Bundesland einzugrenzen.\n\nOhne ARS werden Warnungen nur nach Land gefiltert. Mit ARS erhältst du Warnungen speziell für deine Gemeinde.\n\nDu findest den ARS deiner Gemeinde im Gemeindeverzeichnis des Statistischen Bundesamts oder in der BBK-Warn-App (NINA). Lass das Feld leer, wenn du ihn nicht kennst – du kannst ihn später in den Haushaltseinstellungen nachtragen.';

  @override
  String get regionKeyExplanationClose => 'Verstanden';

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
  String get navSettings => 'Einstellungen';

  @override
  String get navShelters => 'Schutzräume';

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
  String get caloriesLabel => 'Kalorien, gesamt in kcal (optional)';

  @override
  String get supplyCalculatorPersonCountLabel => 'Personen';

  @override
  String supplyCalculatorDaysLabel(int days) {
    return 'Vorräte für $days Tage';
  }

  @override
  String get supplyCalculatorWaterLabel => 'Trinkwasser';

  @override
  String get supplyCalculatorCaloriesLabel => 'Kalorien';

  @override
  String supplyCalculatorProgress(String current, String target, String unit) {
    return '$current / $target $unit';
  }

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
  String get itemPhotoLabel => 'Foto';

  @override
  String get addPhotoButton => 'Foto hinzufügen';

  @override
  String get takePhotoButton => 'Foto aufnehmen';

  @override
  String get chooseFromGalleryButton => 'Aus Galerie wählen';

  @override
  String get removePhotoButton => 'Foto entfernen';

  @override
  String get csvImportButton => 'CSV importieren';

  @override
  String get csvImportTitle => 'CSV importieren';

  @override
  String get csvImportInstructionsTitle => 'Erwartetes Format';

  @override
  String get csvImportInstructionsBody =>
      'Die erste Zeile muss eine Kopfzeile sein. Pflichtspalten: Name, Kategorie, Menge, Einheit, Lagerort. Optionale Spalten: Ablaufdatum, Mindestbestand, Notizen. Englische Spaltennamen funktionieren ebenfalls (name, category, quantity, unit, storageLocation, expirationDate, minQuantity, notes).\n\nKategorie: Wasser, Essen/Lebensmittel, Medizin, Werkzeug, Dokumente, Energie, Hygiene oder Sonstiges (englische Begriffe funktionieren auch, z. B. water, food).\nDatum: JJJJ-MM-TT oder TT.MM.JJJJ.\nZahlen: „.“ oder „,“ als Dezimaltrennzeichen.\nTrennzeichen: „,“ oder „;“, wird automatisch erkannt.';

  @override
  String get csvImportPickFileButton => 'CSV-Datei auswählen…';

  @override
  String get csvImportChangeFileButton => 'Andere Datei auswählen…';

  @override
  String get csvImportParsing => 'Datei wird gelesen…';

  @override
  String csvImportSummary(int valid, int total) {
    return '$valid von $total Zeilen können importiert werden.';
  }

  @override
  String csvImportRowError(int row, String reason) {
    return 'Zeile $row: $reason';
  }

  @override
  String get csvImportReasonMissingColumns =>
      'Pflichtspalten fehlen (Name, Kategorie, Menge, Einheit, Lagerort).';

  @override
  String get csvImportReasonNameMissing => 'Name fehlt.';

  @override
  String csvImportReasonUnknownCategory(String value) {
    return 'Unbekannte Kategorie „$value“.';
  }

  @override
  String csvImportReasonInvalidQuantity(String value) {
    return 'Ungültige Menge „$value“.';
  }

  @override
  String get csvImportReasonUnitMissing => 'Einheit fehlt.';

  @override
  String get csvImportReasonStorageLocationMissing => 'Lagerort fehlt.';

  @override
  String csvImportReasonInvalidDate(String value) {
    return 'Ungültiges Datum „$value“.';
  }

  @override
  String csvImportReasonInvalidMinQuantity(String value) {
    return 'Ungültiger Mindestbestand „$value“.';
  }

  @override
  String csvImportImportButton(int count) {
    return '$count Zeilen importieren';
  }

  @override
  String csvImportSuccessMessage(int count) {
    return '$count Artikel importiert.';
  }

  @override
  String get csvImportNoValidRows =>
      'In dieser Datei wurden keine gültigen Zeilen gefunden.';

  @override
  String csvImportFileReadError(String error) {
    return 'Datei konnte nicht gelesen werden: $error';
  }

  @override
  String get csvImportRowsSectionTitle => 'Zeilen';

  @override
  String csvImportRowLabel(int row) {
    return 'Zeile $row';
  }

  @override
  String get csvImportEditRowTooltip => 'Bearbeiten';

  @override
  String get csvImportRemoveRowTooltip => 'Aus Import entfernen';

  @override
  String get csvImportEditRowTitle => 'Eintrag bearbeiten';

  @override
  String get cancelButton => 'Abbrechen';

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
  String get warningsNinaHintTitle => 'Warnungen bei geschlossener App';

  @override
  String get warningsNinaHintBody =>
      'PreppSuite ruft die amtlichen Warnungen alle 15 Minuten ab und zeigt sie als Überblick. Wer sofort und auch bei geschlossener App gewarnt werden möchte, nutzt dafür NINA vom Bundesamt für Bevölkerungsschutz — dieselbe amtliche Quelle, in Sekunden statt Minuten.';

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

  @override
  String get settingsAppearanceTitle => 'Erscheinungsbild';

  @override
  String get themeSystemOption => 'System';

  @override
  String get themeLightOption => 'Hell';

  @override
  String get themeDarkOption => 'Dunkel';

  @override
  String get settingsMyRegionTitle => 'Meine Region';

  @override
  String get settingsNoRegionSet => 'Keine Region festgelegt';

  @override
  String get settingsAdditionalRegionsTitle => 'Weitere Regionen';

  @override
  String get settingsNoAdditionalRegions =>
      'Noch keine weiteren Regionen hinzugefügt.';

  @override
  String get settingsAddRegionButton => 'Region hinzufügen';

  @override
  String get settingsAddRegionDialogTitle => 'Region hinzufügen';

  @override
  String get settingsRegionTypeKreis => 'Kreis';

  @override
  String get settingsRegionTypeBundesland => 'Bundesland';

  @override
  String get settingsKreisSchluesselLabel => 'Kreisschlüssel (5-stellig)';

  @override
  String get settingsKreisSchluesselInvalid =>
      'Bitte einen 5-stelligen Kreisschlüssel eingeben.';

  @override
  String get settingsRegionLabelLabel => 'Bezeichnung';

  @override
  String get settingsNotificationsTitle => 'Benachrichtigungen';

  @override
  String get settingsNotificationsToggleLabel =>
      'Bei neuen Warnungen benachrichtigen';

  @override
  String get settingsNotificationsToggleHint =>
      'Nur lokale Benachrichtigungen, solange die App läuft — kein Push-Server.';

  @override
  String get settingsUseLocationButton => 'Bundesland per Standort ermitteln';

  @override
  String settingsLocationErrorMessage(String error) {
    return 'Standort konnte nicht ermittelt werden: $error';
  }

  @override
  String get settingsLocationNoMatchMessage =>
      'Aus deinem Standort konnte kein Bundesland ermittelt werden.';

  @override
  String settingsLocationSuccessMessage(String state) {
    return '$state als weitere Region hinzugefügt.';
  }

  @override
  String get shelterMapTitle => 'Schutzräume';

  @override
  String shelterInfoLine(int radius) {
    return 'OpenStreetMap und WWBOTA/DLBOTA im Umkreis von $radius km geladen.';
  }

  @override
  String get shelterLegendGreenLabel => 'Grün';

  @override
  String get shelterLegendGreenDescription =>
      'offiziell als nutzbarer Schutzraum bestätigt';

  @override
  String get shelterLegendYellowLabel => 'Gelb';

  @override
  String get shelterLegendYellowDescription =>
      'möglicher Schutzort, Zugang/Nutzung nicht bestätigt';

  @override
  String get shelterLegendRedLabel => 'Rot';

  @override
  String get shelterLegendRedDescription =>
      'nicht freigegeben, historisch oder nur Infozweck';

  @override
  String get shelterDisclaimer =>
      'Diese Karte ersetzt keine behördliche Warnung, Evakuierung oder Einsatzanweisung.';

  @override
  String get shelterNoConfirmedShelters =>
      'Zurzeit sind in Deutschland keine aktuell freigegebenen öffentlichen Schutzräume in den geladenen offiziellen Daten bekannt. Wenn sich die Datenlage ändert, erscheinen sie hier grün.';

  @override
  String shelterFilterAll(int count) {
    return 'Alle $count';
  }

  @override
  String shelterFilterCount(String label, int count) {
    return '$label $count';
  }

  @override
  String get shelterSearchHint => 'PLZ oder Ort';

  @override
  String get shelterSearchButton => 'Suchen';

  @override
  String get shelterSearchNoResult => 'Kein Ergebnis gefunden.';

  @override
  String get shelterUseLocationButton => 'Standort direkt untersuchen';

  @override
  String get shelterRefreshButton => 'Aktualisieren';

  @override
  String get shelterWwbotaErrorMessage =>
      'WWBOTA/DLBOTA konnte nicht geladen werden.';

  @override
  String get shelterOverpassErrorMessage =>
      'OpenStreetMap/Overpass konnte nicht geladen werden.';

  @override
  String get shelterEmptyPrompt =>
      'Noch keine Standortdaten geladen. Nutze den Standort- oder die Ortssuche.';

  @override
  String get shelterAttribution => '© OpenStreetMap contributors';

  @override
  String get expiryReminderTitle => 'Vorrat läuft bald ab';

  @override
  String expiryReminderBody(String name, int days) {
    return '$name läuft in $days Tagen ab.';
  }

  @override
  String expiryReminderBodyTomorrow(String name) {
    return '$name läuft morgen ab.';
  }

  @override
  String get settingsExpiryRemindersTitle => 'Ablauf-Erinnerungen';

  @override
  String get settingsExpiryRemindersHint =>
      'Erinnerung, bevor ein Vorrat abläuft. Wähle, wie viele Tage vorher.';

  @override
  String get settingsExpiryRemindersDisabledHint =>
      'Schalte oben die Benachrichtigungen ein, damit Erinnerungen geplant werden.';

  @override
  String get settingsExpiryRemindersNoneHint =>
      'Keine Vorlaufzeit gewählt — es werden keine Erinnerungen geplant.';

  @override
  String expiryLeadDaysLabel(int days) {
    return '$days Tage';
  }

  @override
  String get expiryLeadDayOneLabel => '1 Tag';

  @override
  String get consumeAction => 'Verbrauchen';

  @override
  String consumeDialogTitle(String name) {
    return '$name verbrauchen';
  }

  @override
  String get consumeDialogAmountLabel => 'Menge';

  @override
  String consumeDialogRemaining(String quantity, String unit) {
    return 'Bestand: $quantity $unit';
  }

  @override
  String get consumeDialogConfirm => 'Abbuchen';

  @override
  String get consumeDialogAll => 'Alles verbraucht';

  @override
  String get consumeInvalidAmount =>
      'Menge muss grösser als 0 und höchstens der Bestand sein.';

  @override
  String get syncStaleTitle => 'Änderungen sind noch nicht geteilt';

  @override
  String get syncStaleNever =>
      'Diese App hat den Server noch nie erreicht. Prüfe die Serveradresse in den Einstellungen.';

  @override
  String syncStaleSince(String age) {
    return 'Zuletzt erfolgreich abgeglichen vor $age. Bis dahin bleiben Änderungen nur auf diesem Gerät.';
  }

  @override
  String get syncRetryButton => 'Erneut versuchen';

  @override
  String syncAgeMinutes(int count) {
    return '$count Minuten';
  }

  @override
  String syncAgeHours(int count) {
    return '$count Stunden';
  }

  @override
  String syncAgeDays(int count) {
    return '$count Tagen';
  }

  @override
  String get serverAddressHint =>
      'Adresse des Servers, mit dem sich diese App abgleicht.';

  @override
  String get serverAddressInvalid =>
      'Das ist keine gültige Adresse. Beispiel: preppsuite.example.com oder 192.168.1.5:8080';

  @override
  String get serverAddressSignOutHint =>
      'Nach einer Änderung musst du dich neu anmelden — ein Konto gilt nur auf seinem Server.';

  @override
  String get serverAddressChangeAction => 'Serveradresse ändern';

  @override
  String get csvExportButton => 'Als CSV ausgeben';

  @override
  String get csvExportDialogTitle => 'Vorräte als CSV sichern';

  @override
  String csvExportSuccessMessage(int count) {
    return '$count Artikel ausgegeben';
  }

  @override
  String get csvExportEmptyMessage =>
      'Es gibt noch keine Artikel zum Ausgeben.';

  @override
  String get csvExportErrorMessage =>
      'Die Datei konnte nicht geschrieben werden.';
}
