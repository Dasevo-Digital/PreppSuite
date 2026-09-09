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
  String get errorNoConnection =>
      'Keine Verbindung. Prüfe das Netz und versuch es noch einmal.';

  @override
  String get errorArchiveUnreadable =>
      'Das Archiv ließ sich nicht lesen. Vielleicht wurde die Datei verschoben, oder der Datenträger ist nicht angeschlossen.';

  @override
  String get errorFileUnreadable => 'Auf die Datei war kein Zugriff möglich.';

  @override
  String get errorDownloadFailed =>
      'Der Download ist abgebrochen. Ein neuer Versuch setzt dort fort, wo er stehen geblieben ist.';

  @override
  String get errorServiceUnavailable =>
      'Der Dienst hat nicht geantwortet. Das liegt nicht an dir – später noch einmal versuchen.';

  @override
  String get errorDatabase =>
      'Die Datenbank der App hat einen Fehler gemeldet. Ein Neustart hilft meistens.';

  @override
  String get errorPlatformRefused =>
      'Das System hat das abgelehnt. Sieh in den Einstellungen nach, ob PreppSuite die Berechtigung dafür hat.';

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
  String get settingsKreisSchluesselHelper =>
      'Fünf Ziffern, z. B. 03241 für die Region Hannover.';

  @override
  String get settingsBundeslandLabel => 'Bundesland';

  @override
  String get settingsBundeslandRequired => 'Bitte ein Bundesland auswählen.';

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
  String get shelterListHeading => 'Gefundene Schutzräume';

  @override
  String get shelterListEmpty =>
      'In diesem Umkreis nichts gefunden. Versuch einen größeren Umkreis oder einen anderen Ort.';

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
  String get shelterDirectionNorth => 'nördlich';

  @override
  String get shelterDirectionNorthEast => 'nordöstlich';

  @override
  String get shelterDirectionEast => 'östlich';

  @override
  String get shelterDirectionSouthEast => 'südöstlich';

  @override
  String get shelterDirectionSouth => 'südlich';

  @override
  String get shelterDirectionSouthWest => 'südwestlich';

  @override
  String get shelterDirectionWest => 'westlich';

  @override
  String get shelterDirectionNorthWest => 'nordwestlich';

  @override
  String shelterShowOnMap(String name) {
    return '$name auf der Karte zeigen';
  }

  @override
  String shelterMarkerTooltip(String name, String confidence, String source) {
    return '$name · $confidence · $source';
  }

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
  String get settingsExpiryRemindersUnsupported =>
      'Unter Linux gibt es keine geplanten Benachrichtigungen – der Desktop-Standard kennt nur sofortige. Warnmeldungen kommen trotzdem an.';

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
  String get settingsScheduledRemindersUnsupported =>
      'Unter Linux gibt es keine geplanten Benachrichtigungen.';

  @override
  String get settingsChargeReminderTitle => 'Akkus und Geräte prüfen';

  @override
  String get settingsChargeReminderHint =>
      'Erinnert daran, Powerbanks, Akkus, Taschenlampen und Notfunkgeräte aufzuladen und zu testen.';

  @override
  String get settingsChargeReminderDisabledHint =>
      'Schalte oben die Benachrichtigungen ein, damit die Auflade-Erinnerung geplant wird.';

  @override
  String get settingsChargeReminderNoneHint =>
      'Keine Auflade-Erinnerung geplant.';

  @override
  String get settingsChargeReminderOff => 'Aus';

  @override
  String chargeReminderInterval(int days) {
    return 'alle $days Tage';
  }

  @override
  String get chargeReminderTitle => 'Akkus und Geräte prüfen';

  @override
  String get chargeReminderBody =>
      'Powerbanks, Akkus, Taschenlampen und Notfunkgeräte aufladen und testen.';

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

  @override
  String get profileSetupTitle => 'Haushalt einrichten';

  @override
  String get profileSetupIntro =>
      'PreppSuite läuft vollständig auf diesem Gerät. Es gibt kein Konto und keinen Server – nur diese Angaben, damit Warnungen und Bedarfsrechnung zu dir passen.';

  @override
  String get profileSetupSubmit => 'Los geht\'s';

  @override
  String stepperDecrease(String label) {
    return 'Einer weniger: $label';
  }

  @override
  String stepperIncrease(String label) {
    return 'Einer mehr: $label';
  }

  @override
  String stepperValue(String label, int value) {
    return '$label: $value';
  }

  @override
  String deleteItemAction(String item) {
    return '„$item“ löschen';
  }

  @override
  String get mapDownloadSearchAction => 'Diesen Ort suchen';

  @override
  String warningBannerSeverity(String severity, String headline) {
    return '$severity: $headline';
  }

  @override
  String get shoppingListTitle => 'Einkaufsliste';

  @override
  String shoppingListTargetHeading(int days) {
    return 'Gegen das Ziel für $days Tage';
  }

  @override
  String shoppingListTargetMet(int days) {
    return 'Wasser und Energie sind für $days Tage gedeckt.';
  }

  @override
  String shoppingListWaterGap(String liters) {
    return '$liters l Wasser fehlen noch';
  }

  @override
  String shoppingListEnergyGap(String kcal) {
    return '$kcal kcal an Lebensmitteln fehlen noch';
  }

  @override
  String shoppingListDaysCovered(int covered, int days) {
    return 'Der Vorrat reicht derzeit $covered von $days Tagen.';
  }

  @override
  String get shoppingListDaysUnknown =>
      'Im Haushalt lebt niemand, also gibt es nichts zu rechnen.';

  @override
  String get shoppingListItemsHeading => 'Unter der Mindestmenge';

  @override
  String get shoppingListItemsEmpty =>
      'Nichts liegt unter seiner Mindestmenge.';

  @override
  String get shoppingListNoMinimums =>
      'Hier steht nur, wofür du eine Mindestmenge angegeben hast. Trag an einem Artikel eine ein, dann wird er überwacht.';

  @override
  String shoppingListShortfall(String amount, String unit, String minimum) {
    return '$amount $unit fehlen auf $minimum';
  }

  @override
  String get shoppingListCopy => 'Liste kopieren';

  @override
  String get shoppingListCopied => 'Einkaufsliste kopiert.';

  @override
  String get shoppingListEmpty =>
      'Nichts einzukaufen: das Ziel ist erreicht und jeder Artikel liegt über seiner Mindestmenge.';

  @override
  String get rotationTitle => 'Als Nächstes verbrauchen';

  @override
  String get rotationExpiredHeading => 'Über dem Datum';

  @override
  String get rotationSoonHeading => 'Bald verbrauchen';

  @override
  String get rotationLaterHeading => 'Hält noch';

  @override
  String rotationExpiredSince(int days) {
    return 'seit $days Tagen';
  }

  @override
  String get rotationExpiresToday => 'heute';

  @override
  String rotationDaysLeft(int days) {
    return 'noch $days Tage';
  }

  @override
  String get rotationEmpty =>
      'Hier ist nichts zu drehen. Aufgeführt wird nur, was ein Datum trägt und wovon noch etwas da ist.';

  @override
  String get rotationHint =>
      'Salz und Ähnliches tragen kein Datum und bleiben bewusst draußen – sie würden die Zeilen zudecken, die eines haben.';

  @override
  String get consumeScanAction => 'Verbrauch scannen';

  @override
  String consumeScanNotFound(String barcode) {
    return 'Kein Artikel mit dem Barcode $barcode in diesem Haushalt.';
  }

  @override
  String get sharingErrorLocked =>
      'Dieser Ordner ist verschlüsselt und dieses Gerät hat das Kennwort nicht. Es wird nichts gelesen und nichts geschrieben, bis du es eingibst.';

  @override
  String get folderEncryptionTitle => 'Gemeinsamen Ordner verschlüsseln';

  @override
  String get folderEncryptionOff =>
      'Aus. Alles im Ordner ist für jeden lesbar, der ihn sehen kann – auch für deinen Anbieter.';

  @override
  String get folderEncryptionOn =>
      'An. Im Ordner liegen nur versiegelte Dateien.';

  @override
  String get folderEncryptionEnable => 'Verschlüsselung einschalten';

  @override
  String get folderEncryptionUnlock => 'Kennwort eingeben';

  @override
  String get folderEncryptionPassphrase => 'Kennwort';

  @override
  String get folderEncryptionRepeat => 'Kennwort wiederholen';

  @override
  String get folderEncryptionMismatch =>
      'Die beiden Eingaben sind nicht gleich.';

  @override
  String folderEncryptionTooShort(int count) {
    return 'Mindestens $count Zeichen. Das ist das Einzige, was zwischen dem Ordner und jedem steht, der ihn lesen kann.';
  }

  @override
  String get folderEncryptionWrong =>
      'Mit diesem Kennwort lässt sich der Ordner nicht öffnen.';

  @override
  String get folderEncryptionNoRecovery =>
      'Ohne das Kennwort gibt es keinen Weg zurück. PreppSuite kann es nicht zurücksetzen und sonst auch niemand – schreib es an einen sicheren Ort, bevor du weitermachst.';

  @override
  String get folderEncryptionOtherDevices =>
      'Jedes andere Gerät dieses Haushalts muss aktualisiert werden und dasselbe Kennwort bekommen. Bis dahin sieht es keine neuen Zeilen mehr.';

  @override
  String get folderEncryptionEnabled =>
      'Der gemeinsame Ordner ist jetzt verschlüsselt.';

  @override
  String get folderEncryptionUnlocked => 'Ordner entsperrt.';

  @override
  String get folderEncryptionWorking =>
      'Der Schlüssel wird abgeleitet. Das dauert absichtlich einen Moment.';

  @override
  String get householdPlanTitle => 'Notfallplan';

  @override
  String get householdPlanIntro =>
      'Vereinbart, bevor es nötig ist. Jeder im Haushalt sollte das auswendig können – schreib also nur auf, was du auch laut sagen würdest.';

  @override
  String get householdPlanEmpty => 'Noch nichts vereinbart.';

  @override
  String get householdPlanMeetingNear => 'Treffpunkt in der Nähe';

  @override
  String get householdPlanMeetingNearHint =>
      'Zu Fuß erreichbar, ohne Absprache – die Ecke, die Einfahrt der Nachbarn.';

  @override
  String get householdPlanMeetingFar => 'Treffpunkt weiter weg';

  @override
  String get householdPlanMeetingFarHint =>
      'Für den Fall, dass die Gegend geräumt wird und der nahe Punkt nicht erreichbar ist.';

  @override
  String get householdPlanContactName => 'Auswärtiger Kontakt';

  @override
  String get householdPlanContactNameHint =>
      'Jemand außerhalb der Region, den alle anrufen. Die Leitungen vor Ort sind als Erstes überlastet; ein Anruf in den Nachbarkreis kommt oft durch, wenn einer über die Straße es nicht tut.';

  @override
  String get householdPlanContactPhone => 'Dessen Nummer';

  @override
  String get householdPlanKitLocation => 'Wo das Notgepäck liegt';

  @override
  String get householdPlanKitLocationHint =>
      'Damit im Dunkeln niemand danach sucht.';

  @override
  String get householdPlanShutoff =>
      'Wo Wasser, Gas und Strom abgestellt werden';

  @override
  String get householdPlanNotes => 'Sonstiges';

  @override
  String get householdPlanSaved => 'Plan gespeichert.';

  @override
  String get householdPlanCleared => 'Plan entfernt.';

  @override
  String get householdPlanClear => 'Plan entfernen';

  @override
  String get householdPlanClearConfirm =>
      'Den Plan für alle Geräte dieses Haushalts entfernen?';

  @override
  String get householdPlanShared =>
      'Dieser Plan erreicht über den gemeinsamen Ordner jedes Gerät des Haushalts.';

  @override
  String get householdPlanNothingEntered =>
      'Schreib mindestens eine Sache auf, bevor du speicherst.';

  @override
  String get emergencyCardsTitle => 'Notfallkarten';

  @override
  String get emergencyCardsIntro =>
      'Was ein Rettungsdienst wissen will, für jede Person im Haushalt. Nötig ist nur der Name – eine Karte, auf der nichts steht außer einem Namen und einer Allergie, ist es wert.';

  @override
  String get emergencyCardsEmpty => 'Noch keine Karten.';

  @override
  String emergencyCardsCount(int count) {
    return '$count Personen';
  }

  @override
  String get emergencyCardAdd => 'Person hinzufügen';

  @override
  String get emergencyCardEdit => 'Karte bearbeiten';

  @override
  String get emergencyCardName => 'Name';

  @override
  String get emergencyCardBirthYear => 'Geburtsjahr';

  @override
  String get emergencyCardBirthYearHint =>
      'Nur das Jahr. Der Rettungsdienst muss ungefähr wissen, wen er vor sich hat, nicht wann Geburtstag ist.';

  @override
  String get emergencyCardBloodType => 'Blutgruppe';

  @override
  String get emergencyCardAllergies => 'Allergien';

  @override
  String get emergencyCardMedication => 'Dauermedikation';

  @override
  String get emergencyCardMedicationHint =>
      'Das, was in den Vorrat gehört, und das, was niemand raten sollte.';

  @override
  String get emergencyCardConditions => 'Vorerkrankungen';

  @override
  String get emergencyCardInsurance => 'Krankenversicherung';

  @override
  String get emergencyCardDoctor => 'Ärztin oder Arzt';

  @override
  String get emergencyCardContact => 'Wen man wegen dieser Person anruft';

  @override
  String get emergencyCardNotes => 'Sonstiges';

  @override
  String get emergencyCardNameRequired => 'Eine Karte braucht einen Namen.';

  @override
  String get emergencyCardSaved => 'Karte gespeichert.';

  @override
  String get emergencyCardRemoved => 'Karte entfernt.';

  @override
  String get emergencyCardRemove => 'Karte entfernen';

  @override
  String emergencyCardRemoveConfirm(String name) {
    return 'Die Karte von $name auf allen Geräten dieses Haushalts entfernen?';
  }

  @override
  String get emergencyCardsHealthWarning =>
      'Das sind Gesundheitsdaten, und sie wandern über den gemeinsamen Ordner auf jedes Gerät. Verschlüssele den Ordner, bevor du sie hineinschreibst.';

  @override
  String get emergencyCardsHealthEncrypted =>
      'Das sind Gesundheitsdaten. Der gemeinsame Ordner, über den sie wandern, ist verschlüsselt.';

  @override
  String get emergencyCardsGoToEncryption => 'Ordner-Einstellungen';

  @override
  String get emergencyCardBirthYearInvalid => 'Das ist kein Jahr.';

  @override
  String get personCountLabel => 'Personen im Haushalt';

  @override
  String get settingsSharingTitle => 'Gemeinsamer Ordner';

  @override
  String get sharingIntro =>
      'Vorräte, Checklisten und Ausgaben liegen in einem Ordner, den mehrere Geräte sehen — etwa in Nextcloud, Syncthing, iCloud Drive oder Dropbox. PreppSuite schreibt dort nur Dateien. Wer sie transportiert, entscheidest du.';

  @override
  String get sharingInactive =>
      'Dieses Gerät teilt nichts. Alle Daten bleiben hier.';

  @override
  String sharingActiveFolder(String path) {
    return 'Ordner: $path';
  }

  @override
  String get sharingChooseFolderAction => 'Ordner wählen';

  @override
  String get sharingChangeFolderAction => 'Anderen Ordner wählen';

  @override
  String get sharingLeaveAction => 'Nicht mehr teilen';

  @override
  String get sharingSyncNowAction => 'Jetzt abgleichen';

  @override
  String get sharingSyncing => 'Wird abgeglichen …';

  @override
  String get sharingNeverSynced => 'Noch nie abgeglichen.';

  @override
  String sharingLastSynced(String age) {
    return 'Zuletzt abgeglichen vor $age.';
  }

  @override
  String sharingDeviceCount(int count) {
    return '$count Geräte teilen diesen Ordner.';
  }

  @override
  String get sharingDeviceCountOne =>
      'Bisher nutzt nur dieses Gerät den Ordner.';

  @override
  String sharingReceived(int count) {
    return '$count Einträge von anderen Geräten übernommen.';
  }

  @override
  String get sharingUpToDate => 'Alles auf dem Stand.';

  @override
  String get sharingErrorUnwritable =>
      'In diesen Ordner lässt sich nicht schreiben. Unter Android geht die Freigabe bei einer Neuinstallation verloren und lässt sich in den Systemeinstellungen entziehen – wähle den Ordner dann einfach erneut. Sonst prüfe, ob er noch da und beschreibbar ist.';

  @override
  String get sharingErrorUnreadable =>
      'Im Ordner liegt bereits ein Haushalt, der sich nicht lesen lässt. Vermutlich stammt er aus einer neueren Version von PreppSuite.';

  @override
  String get sharingErrorVersion =>
      'Die Dateien im Ordner stammen aus einer neueren Version. Es wurde nichts verändert.';

  @override
  String get sharingErrorFailed =>
      'Der Abgleich ist fehlgeschlagen. Der nächste Versuch läuft von allein.';

  @override
  String sharingJoinedOther(String name) {
    return 'Dieses Gerät gehört jetzt zum Haushalt „$name“. Die bisherigen Einträge wurden mitgenommen.';
  }

  @override
  String get sharingLeaveDialogTitle => 'Nicht mehr teilen?';

  @override
  String get sharingLeaveDialogBody =>
      'Dieses Gerät gleicht dann nicht mehr ab. Gelöscht wird nichts — weder hier noch im Ordner.';

  @override
  String get sharingLeaveDialogConfirm => 'Beenden';

  @override
  String get sharingErrorDifferentHousehold =>
      'Der Ordner gehört zu einem anderen Haushalt. Es wurde nichts zusammengeführt — zwei fremde Datenbestände lassen sich nicht wieder trennen.';

  @override
  String get mapAttributionOffline =>
      '© OpenStreetMap contributors · © OpenMapTiles';

  @override
  String get settingsOfflineMapTitle => 'Karte offline';

  @override
  String get offlineMapIntro =>
      'Ohne eigene Karte holt die App ihre Kacheln von OpenStreetMap – also nur mit Verbindung. Eine PMTiles-Datei auf dem Gerät ersetzt das vollständig.';

  @override
  String get offlineMapInactive =>
      'Keine Karte gewählt. Die Karte kommt aus dem Netz.';

  @override
  String offlineMapActive(String name) {
    return '$name';
  }

  @override
  String offlineMapZoomRange(int min, int max) {
    return 'Zoomstufen $min bis $max.';
  }

  @override
  String get offlineMapChooseAction => 'Karte wählen';

  @override
  String get offlineMapChangeAction => 'Andere Karte wählen';

  @override
  String get offlineMapForgetAction => 'Wieder online';

  @override
  String get offlineMapErrorUnreadable =>
      'Die Datei lässt sich nicht lesen. Erwartet wird ein PMTiles-Archiv der Version 3.';

  @override
  String get offlineMapErrorNotVector =>
      'Das Archiv enthält fertige Bildkacheln statt Vektordaten. PreppSuite zeichnet die Karte selbst und braucht Vektorkacheln.';

  @override
  String get offlineMapErrorSchema =>
      'Das Archiv benutzt ein anderes Schema als das mitgelieferte Kartenbild. Gebraucht wird ein Archiv im OpenMapTiles-Schema – siehe docs/karte-offline.md.';

  @override
  String get offlineMapHelp => 'Woher bekomme ich so eine Datei?';

  @override
  String get navKnowledge => 'Wissen';

  @override
  String get knowledgeTitle => 'Wissen';

  @override
  String get knowledgeEmptyTitle => 'Noch keine Wissensdatei';

  @override
  String get knowledgeEmptyBody =>
      'Eine ZIM-Datei auf dem Gerät – etwa die deutsche Wikipedia von Kiwix – macht das Nachschlagen unabhängig vom Netz. Wo man sie bekommt, steht in docs/wissen-offline.md.';

  @override
  String get knowledgeChooseAction => 'Datei wählen';

  @override
  String get knowledgeChangeAction => 'Andere Datei wählen';

  @override
  String get knowledgeForgetAction => 'Datei entfernen';

  @override
  String get articleLinkLeavesArchive =>
      'Dieser Verweis führt aus dem Archiv heraus. PreppSuite zeigt nur, was in der Datei steht.';

  @override
  String get knowledgeSearchHint => 'Nach Titel suchen';

  @override
  String get knowledgeSearchNote =>
      'Gesucht wird in den Titeln, nicht im Text der Artikel.';

  @override
  String knowledgeNoResults(String query) {
    return 'Kein Titel beginnt mit „$query“.';
  }

  @override
  String get knowledgeSearchPrompt => 'Tippe einen Anfang ein, um zu suchen.';

  @override
  String get knowledgeSuggestionsTitle => 'Womit anfangen';

  @override
  String get knowledgeSuggestionsBody =>
      'Du kannst mehrere Archive nebeneinander behalten und mit einem Tipp wechseln. Die Dateien bleiben, wo sie sind.';

  @override
  String get knowledgeSuggestionWikibooks =>
      'Lehrbücher, darunter ein vollständiger Mathematikkurs bis zum Abitur.';

  @override
  String get knowledgeSuggestionKlexikon =>
      'Ein Lexikon, geschrieben für Grundschulkinder.';

  @override
  String get knowledgeSuggestionPhet =>
      'Interaktive Versuche für Physik, Chemie und Mathematik.';

  @override
  String get knowledgeSuggestionWikiversity => 'Kurs- und Unterrichtsmaterial.';

  @override
  String get knowledgeSuggestionWikipedia =>
      'Alles Übrige. Mit Abstand das größte hier.';

  @override
  String get knowledgeSuggestionMedicine =>
      'Nur die medizinischen Artikel der Wikipedia, für einen Bruchteil des Platzes.';

  @override
  String get knowledgeSuggestionIfixit =>
      'Reparaturanleitungen für Geräte und Elektronik, mit Bildern.';

  @override
  String get knowledgeSuggestionKhan =>
      'Der Schulstoff von vorn bis hinten — nur auf Englisch, ein deutsches Archiv gibt es nicht.';

  @override
  String get knowledgeAddAction => 'Weiteres Archiv hinzufügen';

  @override
  String get knowledgeRemoveAction => 'Dieses Archiv entfernen';

  @override
  String get knowledgeLibraryLabel => 'Archive auf diesem Gerät';

  @override
  String knowledgeSwitchFailed(String name) {
    return '$name lässt sich nicht öffnen. Vielleicht ist die Datei verschoben worden.';
  }

  @override
  String get knowledgeErrorUnreadable =>
      'Die Datei lässt sich nicht lesen. Erwartet wird ein ZIM-Archiv, wie Kiwix es ausliefert.';

  @override
  String get knowledgeArticleUnsupported =>
      'Artikel lassen sich auf dieser Plattform nicht anzeigen – dafür fehlt die Browser-Komponente. Suchen funktioniert, Lesen nicht.';

  @override
  String get knowledgeArticleNoEngine =>
      'Zum Lesen fehlt die Browser-Komponente des Systems. Unter Linux ist das WebKitGTK (Paket libwebkit2gtk-4.1), unter Windows die WebView2-Laufzeit.';

  @override
  String knowledgeSource(String name) {
    return 'Aus $name';
  }

  @override
  String get knowledgeModeTitles => 'Titel';

  @override
  String get knowledgeModeFullText => 'Volltext';

  @override
  String get knowledgeFullTextNote => 'Gesucht wird im Text der Artikel.';

  @override
  String get knowledgeIndexMissingTitle => 'Kein Volltext-Index';

  @override
  String get knowledgeIndexMissingBody =>
      'Die Suche im Text braucht einen Index. Den baut die App einmal auf – danach antwortet sie sofort.';

  @override
  String get knowledgeIndexCountAction => 'Artikel zählen';

  @override
  String get knowledgeIndexBuildAction => 'Index aufbauen';

  @override
  String get knowledgeIndexContinueAction => 'Weiter aufbauen';

  @override
  String get knowledgeIndexCancelAction => 'Anhalten';

  @override
  String get knowledgeIndexDiscardAction => 'Index verwerfen';

  @override
  String knowledgeIndexArticles(int count) {
    return '$count Artikel in dieser Datei.';
  }

  @override
  String get knowledgeIndexLargeWarning =>
      'Das sind viele. Rechne mit einer Stunde oder mehr und mit mehreren Gigabyte auf der Platte. Anhalten geht jederzeit, das Angefangene bleibt.';

  @override
  String knowledgeIndexScanning(int done, int total) {
    return 'Artikel werden gezählt: $done von $total.';
  }

  @override
  String knowledgeIndexIndexing(int done, int total) {
    return '$done von $total Artikeln.';
  }

  @override
  String knowledgeIndexPartial(int done, int total) {
    return 'Angehalten bei $done von $total Artikeln. Gesucht wird in dem, was schon drin ist.';
  }

  @override
  String knowledgeIndexReady(int count) {
    return '$count Artikel im Index.';
  }

  @override
  String get knowledgeIndexBuiltInTitle => 'Eigener Index im Archiv';

  @override
  String knowledgeIndexBuiltIn(int count) {
    return '$count Artikel, sofort durchsuchbar. Das Archiv bringt seinen Volltextindex mit – es ist nichts aufzubauen.';
  }

  @override
  String get knowledgeIndexBuiltInStemming =>
      'Gesucht wird nach Wortstämmen: „Notvorräte“ findet auch „Notvorrat“.';

  @override
  String get downloadFolderTitle => 'Ordner für Downloads';

  @override
  String get downloadFolderChange => 'Ordner wählen';

  @override
  String get downloadFolderReset => 'Zurücksetzen';

  @override
  String downloadRunningLabel(String name) {
    return 'Lädt $name';
  }

  @override
  String get downloadCancelAction => 'Abbrechen';

  @override
  String downloadFailedLabel(String error) {
    return 'Download abgebrochen: $error';
  }

  @override
  String downloadFinishedLabel(String name) {
    return '$name ist fertig geladen.';
  }

  @override
  String downloadNotOpenedLabel(String name, String reason) {
    return '$name ist geladen, lässt sich aber nicht öffnen: $reason';
  }

  @override
  String get downloadRetryAction => 'Erneut versuchen';

  @override
  String get downloadDismissAction => 'Ausblenden';

  @override
  String downloadOfSize(String done, String total) {
    return '$done von $total';
  }

  @override
  String progressPercent(int percent) {
    return '$percent %';
  }

  @override
  String get downloadBusyMessage =>
      'Es läuft schon ein Download. Es geht immer nur einer auf einmal.';

  @override
  String get downloadStartAction => 'Herunterladen';

  @override
  String get downloadConfirmTitle => 'Herunterladen?';

  @override
  String downloadConfirmBody(String name, String size, String folder) {
    return '$name ist $size groß und wird nach $folder geladen. Das Laden geht weiter, solange die App offen bleibt, und lässt sich später fortsetzen.';
  }

  @override
  String get knowledgeDownloadAction => 'Archiv herunterladen';

  @override
  String get kiwixTitle => 'Kiwix-Bibliothek';

  @override
  String get kiwixIntro =>
      'Wikipedia und andere Sammlungen als ZIM-Datei, frei und ohne Konto. Wähle eine Sprache und lade herunter, was du offline haben willst.';

  @override
  String get kiwixLanguageLabel => 'Sprache';

  @override
  String get kiwixSearchHint => 'Sammlung suchen';

  @override
  String get kiwixNoResults =>
      'Nichts gefunden. Andere Sprache oder anderer Suchbegriff?';

  @override
  String kiwixLoadError(String error) {
    return 'Die Bibliothek war nicht erreichbar: $error';
  }

  @override
  String kiwixArticleCount(String count) {
    return '$count Artikel';
  }

  @override
  String get kiwixFullTextTag => 'Volltextindex';

  @override
  String get kiwixFlavourMaxi => 'vollständig';

  @override
  String get kiwixFlavourMini => 'nur Einleitungen';

  @override
  String get kiwixFlavourNopic => 'ohne Bilder';

  @override
  String kiwixResultCount(String shown, String total) {
    return '$shown von $total';
  }

  @override
  String get kiwixLoadMore => 'Mehr laden';

  @override
  String get mapDownloadAction => 'Karte herunterladen';

  @override
  String get mapDownloadTitle => 'Kartenausschnitt laden';

  @override
  String get mapDownloadIntro =>
      'Verschiebe die Karte auf das Gebiet, das du offline brauchst. Geladen wird genau der sichtbare Ausschnitt.';

  @override
  String get mapDownloadZoomLabel => 'Detailstufe';

  @override
  String get mapDownloadZoomHint =>
      'Stufe 12 zeigt Ortschaften und Hauptstraßen, Stufe 14 einzelne Straßen und Gebäude.';

  @override
  String mapDownloadTileCount(String count, String size) {
    return '$count Kacheln, ungefähr $size';
  }

  @override
  String mapDownloadTooLarge(String count) {
    return '$count Kacheln sind zu viel. Verkleinere das Gebiet oder die Detailstufe.';
  }

  @override
  String mapDownloadRunning(String done, String total, String size) {
    return '$done von $total Kacheln, $size geladen';
  }

  @override
  String get mapDownloadFinished =>
      'Die Karte ist fertig und wird jetzt verwendet.';

  @override
  String mapDownloadFailed(String error) {
    return 'Der Download ist gescheitert: $error';
  }

  @override
  String get mapDownloadSourceLabel => 'Kartenquelle';

  @override
  String get mapDownloadSourceOpenFreeMap =>
      'OpenFreeMap (frei, ohne Schlüssel)';

  @override
  String get mapDownloadSourceMapTiler =>
      'MapTiler (Konto und Schlüssel nötig)';

  @override
  String get mapDownloadApiKeyLabel => 'API-Schlüssel';

  @override
  String get mapDownloadApiKeyHint =>
      'Aus deinem MapTiler-Konto. Bleibt auf dem Gerät.';

  @override
  String get mapDownloadApiKeyMissing =>
      'Für diese Quelle fehlt der Schlüssel.';

  @override
  String get mapDownloadPolite =>
      'Die Kacheln kommen von einem öffentlichen Server, den andere mitbenutzen. Nimm nicht mehr, als du brauchst.';

  @override
  String mapDownloadLabel(String zoom) {
    return 'Eigener Ausschnitt, Stufe $zoom';
  }

  @override
  String get mapDownloadSearchHint => 'Ort, Kreis, Bundesland oder Land';

  @override
  String get mapDownloadSearchNoResults => 'Nichts gefunden. Anderer Name?';

  @override
  String mapDownloadSearchFailed(String error) {
    return 'Die Ortssuche war nicht erreichbar: $error';
  }

  @override
  String get mapDownloadAreaViewport => 'Sichtbarer Ausschnitt';

  @override
  String mapDownloadAreaPlace(String name, String kind) {
    return '$name · $kind';
  }

  @override
  String get mapDownloadDetailAuto =>
      'Höchste Stufe, die für dieses Gebiet noch geht.';

  @override
  String mapDownloadPlaceTooLarge(String name) {
    return '$name ist auch auf der gröbsten Stufe zu groß. Wähle einen kleineren Ort.';
  }

  @override
  String mapDownloadDeepestPossible(String count, String level) {
    return 'Auf Stufe 14 wären es $count Kacheln — zu viel. Stufe $level ist das Tiefste, was für dieses Gebiet geht.';
  }

  @override
  String get mapDownloadScopeLabel => 'Umfang';

  @override
  String get mapDownloadScopePlace => 'Nur der Ort';

  @override
  String get mapDownloadScopeRegion => 'Mit Bundesland';

  @override
  String get mapDownloadScopeCountry => 'Ganzes Land';

  @override
  String get mapDownloadWorldBase => 'Welt';

  @override
  String get mapDownloadScopeContinent => 'Ganzer Kontinent';

  @override
  String get mapContinentEurope => 'Europa';

  @override
  String get mapContinentAfrica => 'Afrika';

  @override
  String get mapContinentAsia => 'Asien';

  @override
  String get mapContinentNorthAmerica => 'Nordamerika';

  @override
  String get mapContinentSouthAmerica => 'Südamerika';

  @override
  String get mapContinentOceania => 'Ozeanien';

  @override
  String get mapDownloadStaggered =>
      'Gestaffelt: außen gröber, in der Mitte voll.';

  @override
  String mapDownloadStep(String label, String from, String to, String count) {
    return '$label: Stufe $from bis $to, $count Kacheln';
  }

  @override
  String get mapDownloadNoPlan =>
      'Auch gestaffelt passt das nicht. Wähle einen kleineren Ort.';

  @override
  String mapDownloadEstimatedTime(String minutes) {
    return 'Dauert etwa $minutes Minuten.';
  }

  @override
  String get mapDownloadResolving => 'Umgebung wird ermittelt …';

  @override
  String get mapDownloadUnfinishedTitle => 'Unterbrochener Download';

  @override
  String mapDownloadUnfinishedBody(String label, String done, String total) {
    return '$label — $done von $total Kacheln sind schon da.';
  }

  @override
  String get mapDownloadResumeAction => 'Fortsetzen';

  @override
  String get mapDownloadDiscardAction => 'Verwerfen';

  @override
  String get settingsLocationServicesOff =>
      'Die Ortungsdienste sind ausgeschaltet. Schalte sie in den Systemeinstellungen ein.';

  @override
  String get settingsLocationDeniedForever =>
      'Der Zugriff auf den Standort ist für PreppSuite abgelehnt. Das System fragt nicht noch einmal — erlaube ihn in den Systemeinstellungen.';

  @override
  String get settingsLocationDenied =>
      'Ohne Zugriff auf den Standort geht es nicht. Wähle das Bundesland stattdessen aus der Liste.';

  @override
  String settingsLocationUnavailable(String detail) {
    return 'Der Standort ist auf diesem Gerät nicht zu haben: $detail';
  }

  @override
  String get navMap => 'Karte';

  @override
  String get mapMyLocationAction => 'Mein Standort';

  @override
  String get mapSourceOffline => 'Offline';

  @override
  String get mapSourceOnline => 'Online';

  @override
  String mapSourceOfflineDetail(String name, int min, int max) {
    return 'Gezeichnet aus $name, Stufe $min bis $max.';
  }

  @override
  String get mapSourceOnlineDetail =>
      'Die Kacheln kommen von OpenStreetMap. Dafür braucht es eine Verbindung.';

  @override
  String get mapSourceNoArchive =>
      'Noch keine Karte auf dem Gerät. Bis eine geladen ist, kommen die Kacheln von OpenStreetMap und brauchen eine Verbindung.';

  @override
  String get mapZoomIn => 'Hineinzoomen';

  @override
  String get mapZoomOut => 'Herauszoomen';

  @override
  String supplyCalculatorHouseholdLine(String who) {
    return '$who — laut Haushalt';
  }

  @override
  String get supplyCalculatorEditHousehold => 'Im Haushalt ändern';

  @override
  String supplyCalculatorAdults(String count) {
    return '$count Erwachsene';
  }

  @override
  String supplyCalculatorChildren(String count) {
    return '$count Kinder';
  }

  @override
  String supplyCalculatorDogs(String count) {
    return '$count Hunde';
  }

  @override
  String supplyCalculatorCats(String count) {
    return '$count Katzen';
  }

  @override
  String get supplyCalculatorPetFoodNote =>
      'Tierfutter zählt nicht in die Kalorien — Hunde und Katzen brauchen ihren eigenen Vorrat. Ihr Trinkwasser ist eingerechnet.';

  @override
  String get supplyCalculatorSourceTitle => 'Woher die Zahlen kommen';

  @override
  String get supplyCalculatorSourceBody =>
      'Für Erwachsene nennt das BBK 1,5 Liter Flüssigkeit am Tag plus 0,5 Liter zum Kochen und rund 2200 kcal. Für Kinder nennt das BBK selbst keine Zahl, verweist aber auf die Bundesanstalt für Landwirtschaft und Ernährung, und deren Vorratstabelle sagt es in einer Fußnote: Kinder bis 12 Jahre (keine Säuglinge) brauchen im Schnitt 1 Liter am Tag, nach DGE und Max-Rubner-Institut. Die App rechnet damit — 1 Liter plus die 0,5 Liter zum Kochen. Ab 65 Jahren empfiehlt dieselbe Fußnote 2 Liter am Tag; das Alter steht nicht im Haushaltsprofil, deshalb steht dazu nur ein Hinweis auf dem Vorratsbildschirm. Die 1400 kcal für Kinder sind weiterhin die eigene, vorsichtige Schätzung dieser App — dafür gibt es keine amtliche Zahl. Für Hunde und Katzen wird nur Wasser gerechnet, nach der tierärztlichen Faustregel von etwa 60 ml je Kilogramm — 1,2 Liter für einen Hund von 20 kg, 0,25 Liter für eine Katze von 4 kg. Wer es genau braucht: der Vorratskalkulator des BMEL.';

  @override
  String get householdChildrenLabel => 'Kinder';

  @override
  String get householdDogsLabel => 'Hunde';

  @override
  String get householdCatsLabel => 'Katzen';

  @override
  String get householdAdultsLabel => 'Erwachsene';

  @override
  String get storageTipsTitle => 'Tipps zum Einlagern';

  @override
  String get storageTipsIntro =>
      'Das BBK empfiehlt einen Vorrat für zehn Tage und verweist für die Mengen auf die Vorratstabellen der Bundesanstalt für Landwirtschaft und Ernährung. Die stehen hier — umgerechnet auf deinen Haushalt.';

  @override
  String storagePeopleLine(Object count) {
    return 'Für $count Personen — laut Haushalt';
  }

  @override
  String storageDaysLabel(Object days) {
    return '$days Tage';
  }

  @override
  String get storageFewerDays => 'Ein Tag weniger';

  @override
  String get storageMoreDays => 'Ein Tag mehr';

  @override
  String get storageScaledNote =>
      'Gedruckt ist die Tabelle für eine Person und zehn Tage. Alle Mengen hier sind umgerechnet.';

  @override
  String get storageDietMixed => 'Mischkost';

  @override
  String get storageDietVegetarian => 'Vegetarisch';

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
    return '$count Stück';
  }

  @override
  String storageKcal(Object kcal) {
    return '$kcal kcal';
  }

  @override
  String storageVariantLine(Object kcal, Object name) {
    return 'oder $name: $kcal kcal';
  }

  @override
  String get storageAddToInventory => 'In den Vorrat übernehmen';

  @override
  String get storageFromTableNote =>
      'Aus der Vorratstabelle des BLE übernommen.';

  @override
  String get storageUnitGram => 'g';

  @override
  String get storageUnitLiter => 'l';

  @override
  String get storageUnitPiece => 'Stück';

  @override
  String get storageNutrientProtein => 'Eiweiß';

  @override
  String get storageNutrientFiber => 'Ballaststoffe';

  @override
  String get storageNutrientIron => 'Eisen';

  @override
  String get storageNutrientVitaminB12 => 'Vitamin B12';

  @override
  String get storageNutrientHealthyFats => 'Gesunde Fette';

  @override
  String get storageNutrientFluid => 'Flüssigkeit';

  @override
  String get storageNutrientLegendTitle => 'Was die Marker bedeuten';

  @override
  String get storageNutrientLegendBody =>
      'Die Marker an den Lebensmitteln stehen nicht in der amtlichen Tabelle — sie sind die Einordnung dieser App. Sie zeigen, wofür ein Lebensmittel im Vorrat vor allem da ist, damit du siehst, was mit einer weggelassenen Gruppe verschwindet. Eine Orientierung, keine Ernährungsberatung.';

  @override
  String get storageTipsGeneralTitle => 'Allgemeine Tipps';

  @override
  String get storageTipRotate =>
      'Rollierend bevorraten: immer das Älteste zuerst verbrauchen und wieder auffüllen. So ist nichts abgelaufen und nichts umsonst gekauft.';

  @override
  String get storageTipCoolDryDark =>
      'Kühl, trocken und dunkel lagern, am besten in dicht schließenden Behältern.';

  @override
  String get storageTipEatWhatYouStore =>
      'Nur einlagern, was ihr wirklich esst. Ein Vorrat, den niemand mag, wird nicht verbraucht und irgendwann weggeworfen.';

  @override
  String get storageTipNoPower =>
      'Mit Stromausfall rechnen: nichts einplanen, was gekühlt oder tiefgefroren werden muss.';

  @override
  String get storageTipReadyToEat =>
      'Einen Teil so wählen, dass er ohne Kochen essbar ist — falls auch Gas oder Herd ausfallen.';

  @override
  String get storageTipCanOpener =>
      'An einen Dosenöffner denken, der ohne Strom funktioniert.';

  @override
  String get storageTipSpecialNeeds =>
      'Kleinkinder, Haustiere, Medikamente und besondere Ernährungsformen gehören mit auf die Liste. Die Tabelle deckt sie nicht ab.';

  @override
  String get storageVeganTitle => 'Vegan?';

  @override
  String get storageVeganBody =>
      'Eine vegane Vorratstabelle gibt es amtlich nicht — das BLE veröffentlicht nur diese beiden, und die App erfindet keine dritte. Wer vegan lebt, ersetzt in der vegetarischen Tabelle zwei Zeilen: 2,5 kg Milch und Milcherzeugnisse sowie die fünf Eier. Angereicherte Pflanzendrinks und Sojaprodukte decken Eiweiß und Kalzium ab. Auf Vitamin B12, Jod, Eisen und Omega-3-Fettsäuren weist die DGE bei veganer Ernährung ausdrücklich hin — B12 ist nur über ein Präparat sicher zu decken, und das gehört dann in den Vorrat wie alles andere auch.';

  @override
  String get storageSourceTitle => 'Woher die Zahlen kommen';

  @override
  String get storageSourceBody =>
      'Das BBK nennt auf seiner Seite „Bevorraten“ zehn Tage und 1,5 Liter Flüssigkeit plus 0,5 Liter zum Kochen am Tag; für die Mengen verweist es auf die Vorratstabellen der Bundesanstalt für Landwirtschaft und Ernährung (BLE, 2024, ernaehrungsvorsorge.de). Von dort stammt jede Zeile hier: Grundnahrungsmittelvorrat für eine Person und zehn Tage bei durchschnittlich 2.200 kcal am Tag, einmal als Mischkost und einmal ovo-lacto-vegetarisch. Die Energiewerte kommen aus dem Bundeslebensmittelschlüssel 3.02 des Max-Rubner-Instituts, die Mengen lehnen sich an die Referenzwerte von DGE, ÖGE und SGE an. Umgerechnet wird linear auf Personenzahl und Tage. Die Marker an den Lebensmitteln sind die Zutat dieser App und stehen so in keiner amtlichen Tabelle.';

  @override
  String get nutritionSectionTitle => 'Nährwerte';

  @override
  String get nutritionSectionHint =>
      'Jeweils für die ganze Menge, nicht je 100 g. Beim Scannen trägt die App ein, was auf dem Etikett steht.';

  @override
  String get proteinLabel => 'Eiweiß';

  @override
  String get carbohydrateLabel => 'Kohlenhydrate';

  @override
  String get fatLabel => 'Fett';

  @override
  String get fiberLabel => 'Ballaststoffe';

  @override
  String get supplyCalculatorSeniorNote =>
      'Ab 65 Jahren empfiehlt die DGE 2 Liter Trinken am Tag statt 1,5 — für ältere Menschen im Haushalt also einen halben Liter je Person und Tag mehr einplanen.';

  @override
  String get warningFilterSearchHint => 'Ort, Region oder Stichwort';

  @override
  String get warningFilterSearchClear => 'Suche löschen';

  @override
  String get warningFilterActive => 'Akut';

  @override
  String get warningFilterExpired => 'Abgelaufen';

  @override
  String get warningFilterMyRegions => 'Meine Regionen';

  @override
  String get warningFilterSevere => 'Ab schwer';

  @override
  String warningFilterResultCount(Object shown, Object total) {
    return '$shown von $total Warnungen';
  }

  @override
  String get warningFilterClear => 'Filter zurücksetzen';

  @override
  String warningsEmptyFiltered(Object total) {
    return 'Keine der $total Warnungen passt zum Filter.';
  }

  @override
  String get checklistCategoryInformation => 'Informiert bleiben';

  @override
  String get checklistCategoryEvacuation => 'Notgepäck';

  @override
  String get checklistCategorySafety => 'Sicherheit im Haus';

  @override
  String get checklistCategoryHazards => 'Naturgefahren';

  @override
  String get checklistCategoryWellbeing => 'Ängste und Sorgen';

  @override
  String get checklistCategoryPets => 'Haustiere';

  @override
  String get navOverview => 'Übersicht';

  @override
  String get navWarnings => 'Warnungen';

  @override
  String get navMore => 'Mehr';

  @override
  String overviewSupplyTitle(Object days) {
    return 'Versorgung für $days Tage';
  }

  @override
  String overviewSupplyWater(Object current, Object target) {
    return '$current von $target L';
  }

  @override
  String overviewSupplyCalories(int current, int target) {
    final intl.NumberFormat currentNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String currentString = currentNumberFormat.format(current);
    final intl.NumberFormat targetNumberFormat =
        intl.NumberFormat.decimalPattern(localeName);
    final String targetString = targetNumberFormat.format(target);

    return '$currentString von $targetString kcal';
  }

  @override
  String get overviewAttentionTitle => 'Braucht Aufmerksamkeit';

  @override
  String get overviewNothingStored => 'Im Vorrat ist noch nichts eingetragen.';

  @override
  String get overviewExpired => 'abgelaufen';

  @override
  String get overviewLowStock => 'unter Mindestmenge';

  @override
  String get overviewExpiringSoon => 'läuft in 30 Tagen ab';

  @override
  String get overviewNoWarnings => 'Zurzeit keine Warnung für deine Regionen.';

  @override
  String overviewChecklistLists(Object complete, Object total) {
    return '$complete von $total Listen vollständig';
  }

  @override
  String get overviewResourcesTitle => 'Ressourcen';

  @override
  String overviewItemCount(Object count) {
    return '$count Einträge';
  }

  @override
  String get photoEditTitle => 'Foto zuschneiden';

  @override
  String get photoEditHint =>
      'Ziehe den Rahmen auf den Ausschnitt, den du behalten willst.';

  @override
  String get photoEditRotateLeft => 'Nach links drehen';

  @override
  String get photoEditRotateRight => 'Nach rechts drehen';

  @override
  String get photoEditReset => 'Ganzes Bild';

  @override
  String get photoEditFailed =>
      'Dieses Bild lässt sich nicht bearbeiten. Es bleibt unverändert.';

  @override
  String get editPhotoButton => 'Foto zuschneiden';

  @override
  String get sharingErrorEncryptionChanged =>
      'Der Abgleich wurde gestoppt: Die Verschlüsselungsdaten fehlen oder wurden zurückgesetzt. Stelle die verschlüsselte household.json aus einer Sicherung wieder her. Es wurden keine unverschlüsselten Haushaltsdaten geschrieben.';

  @override
  String get searchUnavailable =>
      'Die Suche ist gerade nicht erreichbar. Bitte versuche es erneut.';

  @override
  String get inventoryFilters => 'Filtern und sortieren';

  @override
  String get inventoryFilterCategory => 'Kategorie';

  @override
  String get inventoryFilterLocation => 'Lagerort';

  @override
  String get inventoryFilterStatus => 'Bestandsstatus';

  @override
  String get inventoryFilterAll => 'Alle';

  @override
  String get inventoryNoLocation => 'Ohne Lagerort';

  @override
  String get inventoryExpiringSoon => 'Läuft in den nächsten 7 Tagen ab';

  @override
  String get inventorySortLabel => 'Sortieren nach';

  @override
  String get inventorySortName => 'Name';

  @override
  String get inventorySortExpiry => 'Ablaufdatum';

  @override
  String get inventorySortAttention => 'Handlungsbedarf';

  @override
  String get inventoryApplyFilters => 'Anwenden';

  @override
  String get inventoryResetFilters => 'Filter zurücksetzen';

  @override
  String get inventoryFiltersActive => 'Filter aktiv';

  @override
  String get inventorySearchHint => 'Vorräte durchsuchen';

  @override
  String get inventoryClearSearch => 'Suche leeren';

  @override
  String get inventoryNoMatches =>
      'Keine passenden Vorräte. Passe die Suche oder die Filter an.';

  @override
  String get unsavedChangesTitle => 'Änderungen verwerfen?';

  @override
  String get unsavedChangesMessage =>
      'Deine Änderungen sind noch nicht gespeichert.';

  @override
  String get keepEditing => 'Weiter bearbeiten';

  @override
  String get discardChanges => 'Verwerfen';

  @override
  String get inventoryItemDeleted => 'Vorrat gelöscht';

  @override
  String get undoAction => 'Rückgängig';

  @override
  String get overviewStartTitle => 'Dein erster Schritt zur Vorsorge';

  @override
  String get overviewStartHint =>
      'Trage Wasser oder Lebensmittel ein. So siehst du, wie lange dein Haushalt versorgt ist.';

  @override
  String get overviewAddFirst => 'Ersten Vorrat anlegen';

  @override
  String get overviewOpen => 'Öffnen';

  @override
  String get warningMoreInformation =>
      'Weitere Informationen bei der Warnquelle';

  @override
  String get moreActions => 'Weitere Aktionen';

  @override
  String get checklistLinkStockAction => 'Mit Vorrat verknüpfen';

  @override
  String get checklistLinkStockTitle => 'Vorrat auswählen';

  @override
  String get checklistUnlinkStockAction => 'Verknüpfung entfernen';

  @override
  String get checklistNoStockToLink =>
      'Noch kein Vorrat zum Verknüpfen vorhanden.';

  @override
  String checklistLinkedStock(String name, num quantity, String unit) {
    return '$name: $quantity $unit vorhanden';
  }

  @override
  String get navEmergency => 'Notfall';

  @override
  String get emergencyTitle => 'Notfall & Bereitschaft';

  @override
  String get emergencyCall112 => 'Notruf 112';

  @override
  String get emergencyCall110 => 'Polizei 110';

  @override
  String get emergencyCurrentWarnings => 'Aktuelle Warnungen';

  @override
  String get emergencyNoWarnings => 'Keine relevanten aktiven Warnungen';

  @override
  String get readinessTitle => 'Offline-Bereitschaft';

  @override
  String get readinessReady => 'bereit';

  @override
  String get readinessNeedsWork => 'offen';

  @override
  String get readinessInventory => 'Vorrat angelegt';

  @override
  String get readinessChecklists => 'Checklisten begonnen';

  @override
  String get readinessPlan => 'Notfallplan ausgefüllt';

  @override
  String get readinessCards => 'Notfallkarten angelegt';

  @override
  String get readinessMap => 'Offline-Karte verfügbar';

  @override
  String get readinessKnowledge => 'Offline-Wissen verfügbar';

  @override
  String get emergencyPlanMissing => 'Notfallplan noch nicht ausgefüllt';

  @override
  String get emergencyPlanHeading => 'Wichtige Angaben';

  @override
  String get knowledgeManageArchives => 'Archive verwalten';

  @override
  String knowledgeArchiveCount(int count) {
    return '$count Archive auf diesem Gerät';
  }

  @override
  String get knowledgeArchiveSelected => 'Aktuell geöffnet';

  @override
  String get backupTitle => 'Sicherung & Wiederherstellung';

  @override
  String get backupCreate => 'Datensicherung erstellen';

  @override
  String get backupRestore => 'Datensicherung wiederherstellen';

  @override
  String get backupHint =>
      'Vorräte, Checklisten, Notfallplan und Notfallkarten. Die Datei enthält persönliche Daten und sollte geschützt aufbewahrt werden.';

  @override
  String get backupCreated => 'Datensicherung gespeichert.';

  @override
  String backupRestored(int count) {
    return 'Datensicherung wiederhergestellt: $count neuere Einträge übernommen.';
  }

  @override
  String get backupInvalid =>
      'Diese Sicherung gehört nicht zu diesem Haushalt oder ist beschädigt.';

  @override
  String get backupFailed =>
      'Die Datensicherung konnte nicht verarbeitet werden.';

  @override
  String get backupPassphraseTitle => 'Sicherung verschlüsseln';

  @override
  String get backupPassphrase => 'Passwort';

  @override
  String get backupPassphraseRepeat => 'Passwort wiederholen';

  @override
  String get backupPassphraseInvalid =>
      'Mindestens 8 Zeichen eingeben; beide Eingaben müssen übereinstimmen.';

  @override
  String get warningInstructionsTitle => 'Handlungsempfehlungen';

  @override
  String get warningAreaTitle => 'Betroffenes Gebiet';

  @override
  String get warningContactTitle => 'Herausgeber und Kontakt';

  @override
  String get warningShowMap => 'Gebiet auf Karte zeigen';

  @override
  String warningDetailsPeriod(String start, String end) {
    return 'Meldung vom: $start – $end';
  }

  @override
  String get warningDetailsUntilFurtherNotice => 'bis auf Weiteres';

  @override
  String warningDetailsLevel(String severity) {
    return 'Warnstufe: $severity';
  }

  @override
  String get warningDetailsAffectedRegions => 'Betroffene Region(en)';

  @override
  String get warningDetailsNoInstructions =>
      'Für diese Warnung liegen keine Handlungsempfehlungen vor.';

  @override
  String get warningDetailsNoArea =>
      'Das betroffene Gebiet wurde von der Warnquelle nicht näher angegeben.';

  @override
  String get warningDetailsSource => 'Warnquelle und Veröffentlichung';

  @override
  String warningDetailsPublished(String time) {
    return 'Veröffentlicht: $time';
  }

  @override
  String get warningDetailsOfflineHint =>
      'Karte, Gebiet und Handlungsempfehlungen wurden mit der Warnung gespeichert und sind auch offline lesbar.';

  @override
  String get knowledgeBrowseTitle => 'Archiv durchblättern';

  @override
  String get knowledgeBrowseBody =>
      'Öffne die Startseite, wähle einen Anfangsbuchstaben oder entdecke einen zufälligen Artikel.';

  @override
  String get knowledgeMainPageAction => 'Startseite';

  @override
  String get knowledgeRandomAction => 'Zufälliger Artikel';

  @override
  String knowledgeArchiveStats(int articles, String size) {
    return '$articles Einträge · ungefähr $size';
  }

  @override
  String knowledgeTotalSize(String size) {
    return 'Gesamtgröße: ungefähr $size';
  }

  @override
  String get knowledgeDocumentsTitle => 'Eigene Dokumente';

  @override
  String get knowledgeDocumentsIntro =>
      'PDF-, EPUB- und Markdown-Dateien bleiben an ihrem Speicherort und werden nicht dupliziert.';

  @override
  String get knowledgeDocumentAdd => 'Dokument hinzufügen';

  @override
  String get knowledgeDocumentsEmpty =>
      'Noch keine eigenen Dokumente hinzugefügt.';

  @override
  String get knowledgeDocumentOpen => 'Öffnen';

  @override
  String get knowledgeDocumentRemove => 'Aus Bibliothek entfernen';

  @override
  String get knowledgeDocumentOpenFailed =>
      'Das Dokument konnte nicht geöffnet werden.';

  @override
  String get emergencyDirectoryTitle => 'Notruf, Kontakte & Funk';

  @override
  String get emergencyMedicalService => 'Ärztlicher Bereitschaftsdienst 116117';

  @override
  String get emergencyPoisonTitle => 'Giftnotrufzentralen';

  @override
  String get emergencyPoisonHint =>
      'Bei lebensbedrohlichen Symptomen zuerst 112 anrufen. Die zuständige Giftnotrufzentrale berät bei Vergiftungsverdacht.';

  @override
  String get emergencyRadioTitle => 'Radio- und Funkbereiche';

  @override
  String get emergencyRadioHint =>
      'Lokale Senderfrequenzen ändern sich. Im Ereignisfall Sendersuchlauf nutzen und amtliche Durchsagen beachten. Senden ist nur im jeweils erlaubten Funkdienst zulässig.';

  @override
  String get emergencyContactsTitle => 'Nahe Notfallkontakte';

  @override
  String get emergencyContactsEmpty => 'Noch keine nahen Kontakte gespeichert.';

  @override
  String get emergencyContactAdd => 'Kontakt hinzufügen';

  @override
  String get emergencyContactName => 'Name';

  @override
  String get emergencyContactPhone => 'Telefonnummer';

  @override
  String get emergencyContactAddress => 'Adresse';

  @override
  String get emergencyContactCoordinates => 'Koordinaten (Breite, Länge)';

  @override
  String get emergencyContactDelete => 'Kontakt löschen';

  @override
  String get emergencyCallAction => 'Anrufen';

  @override
  String get emergencyOpenMapAction => 'Auf Karte öffnen';

  @override
  String get prepperRecipesTitle => 'Notfallrezepte';

  @override
  String get prepperRecipesIntro =>
      'Einfache Gerichte aus haltbaren Vorräten, mit wenig Wasser und Energie. Mengen an den Haushalt anpassen.';

  @override
  String get preservationTitle => 'Lebensmittel haltbar machen';

  @override
  String get preservationIntro =>
      'Bewährte Verfahren für vorhandene Lebensmittel. Sauber arbeiten, sichere Einkochzeiten beachten und aufgeblähte oder verdächtige Gläser entsorgen.';

  @override
  String get storageOfficialCalculator =>
      'Offiziellen Vorratskalkulator öffnen';

  @override
  String get storageOfficialTips => 'Weitere Tipps der Ernährungsvorsorge';

  @override
  String get resetTitle => 'Zurücksetzen';

  @override
  String get resetSettings => 'App-Einstellungen zurücksetzen';

  @override
  String get resetSettingsHint =>
      'Sprache, Darstellung, Benachrichtigungen, Erinnerungen und Kartenanbieter auf Standardwerte setzen. Daten und Downloads bleiben erhalten.';

  @override
  String get resetHousehold => 'Haushalt und lokale Daten löschen';

  @override
  String get resetHouseholdHint =>
      'Vorräte, Checklisten, Notfallplan und Notfallkarten dieses Haushalts dauerhaft von diesem Gerät löschen.';

  @override
  String get resetConfirmTitle => 'Wirklich zurücksetzen?';

  @override
  String get resetConfirmHousehold =>
      'Die lokalen Haushaltsdaten werden dauerhaft gelöscht. Eine Sicherung sollte vorher erstellt werden.';

  @override
  String get resetDone => 'Zurücksetzen abgeschlossen.';

  @override
  String get knowledgeDocumentIndexTitle => 'Offline-Suche';

  @override
  String get knowledgeDocumentIndexOption =>
      'Dieses Dokument durchsuchbar machen';

  @override
  String get knowledgeDocumentIndexPrivacy =>
      'Der Textindex bleibt ausschließlich auf diesem Gerät. Die Originaldatei wird nicht kopiert.';

  @override
  String get knowledgeDocumentIndexed => 'Für die Offline-Suche bereit';

  @override
  String get knowledgeDocumentIndexing => 'Index wird erstellt …';

  @override
  String get knowledgeDocumentNotIndexed => 'Nicht in der Suche';

  @override
  String get knowledgeDocumentNoText =>
      'Kein auslesbarer Text (möglicherweise ein Scan)';

  @override
  String get knowledgeDocumentTooLarge =>
      'Für den Index zu groß (maximal 48 MB)';

  @override
  String get knowledgeDocumentIndexFailed =>
      'Index konnte nicht erstellt werden';

  @override
  String get knowledgeDocumentReindex => 'Suchindex erneuern';

  @override
  String get knowledgeDocumentClearIndex => 'Suchindex löschen';

  @override
  String get knowledgeDocumentClearIndexBody =>
      'Die Suchdaten aller eigenen Dokumente werden gelöscht. Die Originaldateien bleiben erhalten.';

  @override
  String knowledgeDocumentIndexSummary(int indexed, int total) {
    return '$indexed von $total Dokumenten durchsuchbar';
  }

  @override
  String get knowledgePersonalResults => 'Eigene Dokumente';

  @override
  String get knowledgePersonalResultHint =>
      'Treffer aus dem lokalen Dokumentenindex';

  @override
  String get radioEmergencyTitle => 'Funk-Notfallfrequenzen';

  @override
  String get radioEmergencyEntryHint =>
      'CB- und Amateurfunk: Frequenzen, Regeln und Hinweise';

  @override
  String get radioEmergencyIntro =>
      '112 bleibt der erste Weg für Notrufe. Funkfrequenzen sind ein möglicher Rückfallweg, wenn ein zugelassenes Gerät verfügbar ist; sie werden nicht dauerhaft überwacht.';

  @override
  String get radioCbTitle => 'CB-Funk: Anruf- und Hilfekanäle';

  @override
  String get radioCbHintsTitle => 'Hinweise zum CB-Funk';

  @override
  String get radioCbRule =>
      'CB-Funk ist in Deutschland allgemein zugeteilt. Nutze nur zugelassene Geräte und halte Leistung, Betriebsart und Antennenvorgaben ein.';

  @override
  String get radioAmateurTitle => 'Amateurfunk: IARU-Notfunk-Schwerpunkte';

  @override
  String get radioLegalTitle => 'Rechtlicher Hinweis';

  @override
  String get radioAmateurLegal =>
      'Amateurfunk darf in Deutschland nur mit gültiger Amateurfunkzulassung betrieben werden. Die Frequenzen sind Informations- und Aktivitätsschwerpunkte, keine garantierten Notrufstellen.';

  @override
  String get radioNoGuaranteedMonitoring =>
      'Nicht auf eine Antwort warten: Wenn 112 erreichbar ist, immer zuerst 112 wählen.';

  @override
  String get radioListenFirst =>
      'Vor dem Senden länger zuhören. Laufenden Notfunkverkehr nicht stören.';

  @override
  String get radioEmergencyCall =>
      'Nur bei einer echten Notlage rufen. Nenne zuerst Ort, Art der Gefahr und benötigte Hilfe; bleibe kurz und klar.';

  @override
  String get radioUseHintsTitle => 'Hinweise zur Nutzung';

  @override
  String get radioBriefMessage =>
      'Sendeleistung so niedrig wie möglich halten, Empfang bestätigen und bei knapper Energie feste Meldezeiten vereinbaren.';

  @override
  String get radioOfficialRules => 'Regeln der Bundesnetzagentur öffnen';

  @override
  String get radioIaruSource => 'DARC / IARU-Notfunkfrequenzen öffnen';

  @override
  String get knowledgeApolloTitle => 'APOLLO-Wissensbasis';

  @override
  String get knowledgeApolloMissionTitle => 'Wissen für den Ausnahmefall';

  @override
  String get knowledgeApolloMissionBody =>
      'Baue eine lokale Bibliothek für praktisches Handeln, Grundlagenwissen und Lernen zu Hause auf. Die Archive bleiben auf deinem Gerät und sind ohne Internet lesbar.';

  @override
  String get knowledgeApolloReady => 'Offline-Bibliothek geöffnet und bereit';

  @override
  String get knowledgeApolloNotReady => 'Noch kein Archiv geöffnet';

  @override
  String knowledgeApolloStatus(int count, String size) {
    return '$count Archive registriert · bekannte Größe: $size';
  }

  @override
  String get knowledgeApolloStatusHint =>
      'Der Balken ist eine Orientierung für acht empfohlene Grundarchive; Größe und Auswahl bestimmst du selbst.';

  @override
  String get knowledgeApolloDownloadedTitle => 'Heruntergeladene Inhalte';

  @override
  String get knowledgeApolloDownloaded => 'Heruntergeladen';

  @override
  String get knowledgeApolloOpened => 'Geöffnet';

  @override
  String get knowledgeApolloStartTitle => 'Praktisches Wissen zuerst';

  @override
  String get knowledgeApolloStartBody =>
      'Lade zunächst Themen, die im Ausfall unmittelbar helfen. Ergänze anschließend Schule und Grundlagen.';

  @override
  String get knowledgeApolloMedicalTitle => 'Medizin & Erste Hilfe';

  @override
  String get knowledgeApolloMedicalBody =>
      'Mit WikiMed medizinische Grundlagen und Erste Hilfe gezielt nachschlagen. Es ersetzt keine Notruf- oder ärztliche Hilfe.';

  @override
  String get knowledgeApolloSurvivalTitle =>
      'Überleben, Bushcraft & Selbstversorgung';

  @override
  String get knowledgeApolloSurvivalBody =>
      'Wikibooks und iFixit für Wasser, Unterkunft, Feuer, Orientierung, Nahrung, Hygiene und Reparaturen als nachvollziehbare Grundlagen.';

  @override
  String get knowledgeApolloRepairTitle => 'Handwerk, Energie & Reparatur';

  @override
  String get knowledgeApolloRepairBody =>
      'Werkzeuge, Reparaturen, einfache Technik und Alltagshandwerk: Wissen, das Geräte und Versorgung länger nutzbar hält.';

  @override
  String get knowledgeApolloFoundationsTitle => 'Grundlagen & Bildung';

  @override
  String get knowledgeApolloBasicsTitle => 'Natur, Gesellschaft & Grundwissen';

  @override
  String get knowledgeApolloBasicsBody =>
      'Mathematik, Sprache, Naturwissenschaften, Geschichte und verlässliche Hintergrundartikel zum Nachschlagen.';

  @override
  String get knowledgeApolloSchoolTitle => 'Lernen zu Hause';

  @override
  String get knowledgeApolloSchoolBody =>
      'Kindgerechte Erklärungen, Bücher, Übungen und Simulationen für einen strukturierten Unterricht ohne Netz.';

  @override
  String get knowledgeApolloAdvancedTitle => 'Vertiefung & Lehrplan';

  @override
  String get knowledgeApolloAdvancedBody =>
      'Umfangreichere Kurse für weiterführende Themen. Englischsprachige Angebote sind als Ergänzung gekennzeichnet.';

  @override
  String get knowledgeApolloPersonalTitle => 'Eigene Unterlagen ergänzen';

  @override
  String get knowledgeApolloPersonalBody =>
      'Füge lokale PDFs, EPUBs und Markdown-Dateien hinzu und mache auslesbaren Text für die Offline-Volltextsuche verfügbar.';

  @override
  String get knowledgeApolloDownloadHint =>
      'Öffnet die Kiwix-Bibliothek mit einer passenden Suche. Prüfe dort Sprache, Ausgabe und Speicherbedarf vor dem Download.';

  @override
  String get settingsVersionInfoTitle => 'Versionsinfo';

  @override
  String get settingsVersionInfoApp => 'PreppSuite-App';

  @override
  String settingsVersionInfoAppValue(String version, String build) {
    return '$version · Build $build';
  }

  @override
  String get settingsVersionInfoDatabase => 'Haushaltsdatenbank';

  @override
  String get settingsVersionInfoKnowledgeIndex => 'Wissensarchiv-Volltextindex';

  @override
  String get settingsVersionInfoDocumentsIndex => 'Dokument-Volltextindex';

  @override
  String settingsVersionInfoSchema(int version) {
    return 'Schema $version';
  }

  @override
  String get settingsVersionInfoOfflineMap => 'Offline-Kartenformat';

  @override
  String get settingsVersionInfoPmtiles => 'PMTiles v3';

  @override
  String get settingsVersionInfoUnavailable => 'Nicht verfügbar';

  @override
  String get readinessOpenDashboard => 'Einsatzbereitschaft prüfen';

  @override
  String get readinessDashboardHint =>
      'Offline-Pakete und Aktualität der Warnungsdaten';

  @override
  String readinessSummary(int ready, int total) {
    return '$ready von $total Bereichen bereit';
  }

  @override
  String get readinessSummaryHint =>
      'Prüfe fehlende Punkte vor einem Ereignis und wiederhole die Kontrolle nach Änderungen am Gerät.';

  @override
  String get readinessOfflinePackages => 'Offline-Pakete';

  @override
  String get readinessPackageReady => 'Geöffnet und lesbar';

  @override
  String get readinessPackageMissing => 'Nicht eingerichtet oder nicht lesbar';

  @override
  String readinessArchivesReady(int count) {
    return '$count Archive registriert; ausgewähltes Archiv geöffnet';
  }

  @override
  String get readinessWarningData => 'Amtliche Warnungsdaten';

  @override
  String get readinessWarningNeverUpdated =>
      'Noch keine vollständige Aktualisierung auf diesem Gerät';

  @override
  String readinessWarningUpdated(String age) {
    return 'Zuletzt vollständig aktualisiert: $age';
  }

  @override
  String get readinessJustNow => 'gerade eben';

  @override
  String readinessMinutesAgo(int minutes) {
    return 'vor $minutes Minuten';
  }

  @override
  String readinessHoursAgo(int hours) {
    return 'vor $hours Stunden';
  }

  @override
  String readinessDaysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get emergencyPlanExport => 'Notfallplan als PDF';

  @override
  String get emergencyPlanPdfTitle => 'Persönlicher Notfallplan';

  @override
  String get emergencyPlanPdfMeetingPoints => 'Treffpunkte';

  @override
  String get emergencyPlanPdfContact => 'Kontakt außerhalb der Region';

  @override
  String get emergencyPlanPdfEquipment => 'Notgepäck und Abschaltpunkte';

  @override
  String get emergencyPlanPdfEmpty => 'Nicht eingetragen';
}
