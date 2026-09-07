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
  String overviewSupplyCalories(Object current, Object target) {
    return '$current von $target kcal';
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
}
