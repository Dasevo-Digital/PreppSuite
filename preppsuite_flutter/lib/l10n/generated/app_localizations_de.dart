// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get airQualityEntryHint =>
      'Feinstaub, Ozon und Stickstoffdioxid an einer Messstation in deiner Nähe.';

  @override
  String get airQualityTitle => 'Luftqualität';

  @override
  String get airQualityNoneChosen => 'Noch keine Messstation gewählt';

  @override
  String get airQualityChoose => 'Messstation wählen';

  @override
  String get airQualityChange => 'Andere Messstation';

  @override
  String get airQualityRefresh => 'Neu laden';

  @override
  String get airQualitySearchHint => 'Ort, Station oder Bundesland';

  @override
  String get airQualitySearchEmpty => 'Keine Station gefunden.';

  @override
  String get airQualityLoadFailed =>
      'Die Messwerte sind gerade nicht zu erreichen.';

  @override
  String get airQualityOffline =>
      'Zuletzt gespeicherter Wert – der Abruf ist gerade fehlgeschlagen.';

  @override
  String get airQualityStale =>
      'Diese Messung ist über drei Stunden alt. Die Station meldet zurzeit nichts Neues.';

  @override
  String get airQualityIncomplete =>
      'Nicht alle Schadstoffe dieser Station haben in dieser Stunde gemeldet. Die Einstufung gilt für das, was gemeldet wurde.';

  @override
  String get airQualityComponents => 'Einzelne Schadstoffe';

  @override
  String airQualityLeading(String code, String value, String unit) {
    return 'Ausschlaggebend: $code mit $value $unit';
  }

  @override
  String airQualitySpan(String min, String max) {
    return '$min bis $max';
  }

  @override
  String airQualityMeasuredAt(String when) {
    return 'Gemessen am $when';
  }

  @override
  String get airQualityVeryGood => 'Sehr gut';

  @override
  String get airQualityGood => 'Gut';

  @override
  String get airQualityModerate => 'Mäßig';

  @override
  String get airQualityPoor => 'Schlecht';

  @override
  String get airQualityVeryPoor => 'Sehr schlecht';

  @override
  String get airQualityUnknown => 'Keine Einstufung';

  @override
  String get airQualityNoWarning =>
      'Das ist ein Messwert, keine Warnung. Wird tatsächlich vor etwas gewarnt, kommt die Warnung über die Warnmeldungen dieser App.';

  @override
  String get airQualityAdvice =>
      'Was das UBA bei welcher Stufe empfiehlt, steht beim UBA selbst. Diese App gibt keine eigenen Gesundheitshinweise.';

  @override
  String get airQualitySource =>
      'Quelle: Umweltbundesamt, Luftqualitätsindex. Einstufung und Schwellenwerte stammen vom UBA.';

  @override
  String get roadClosureTitle => 'Autobahnsperrungen';

  @override
  String get roadClosureEntryHint =>
      'Was auf den Autobahnen gesperrt ist, die du beobachtest.';

  @override
  String get roadClosureNoneChosen => 'Noch keine Autobahn gewählt';

  @override
  String get roadClosureWhy =>
      'Wenn eine Gegend verlassen werden muss, ist „welcher Weg ist offen“ die konkretere Frage als jede Checkliste. Die Auskunft gibt es nur je Autobahn – deshalb einmal auswählen, welche zählen.';

  @override
  String get roadClosureChoose => 'Autobahnen wählen';

  @override
  String get roadClosureChange => 'Auswahl ändern';

  @override
  String get roadClosureDone => 'Fertig';

  @override
  String get roadClosureRefresh => 'Neu laden';

  @override
  String get roadClosureLoadFailed =>
      'Die Verkehrsmeldungen sind gerade nicht zu erreichen.';

  @override
  String get roadClosureNow => 'Jetzt';

  @override
  String get roadClosureNothingNow =>
      'Zurzeit keine Sperrung und keine Warnung.';

  @override
  String get roadClosureLater => 'Angekündigt';

  @override
  String get roadClosureBlocked => 'Gesperrt';

  @override
  String roadClosureFrom(String when) {
    return 'Ab $when';
  }

  @override
  String get roadClosureSource =>
      'Quelle: Autobahn GmbH des Bundes, offene Verkehrsdaten. Baustellen ohne Sperrung sind nicht aufgeführt.';

  @override
  String get appTitle => 'PreppSuite';

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
  String get createButton => 'Erstellen';

  @override
  String get fieldRequired => 'Dieses Feld darf nicht leer sein.';

  @override
  String get errorGeneric =>
      'Es ist ein unerwarteter Fehler aufgetreten. Versuch es noch einmal.';

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
  String get errorDiskFull =>
      'Auf dem Datenträger ist kein Platz mehr. Schaffe Platz und versuche es erneut.';

  @override
  String get errorLocalDataLocked =>
      'Die lokalen Daten sind gesperrt. Die App neu starten und den Hinweis auf dem Startbildschirm lesen.';

  @override
  String get errorLocalDataBusy =>
      'Die Datenbanken werden gerade verschlüsselt. Bitte warten, bis das fertig ist.';

  @override
  String get errorPlatformRefused =>
      'Das System hat das abgelehnt. Sieh in den Einstellungen nach, ob PreppSuite die Berechtigung dafür hat.';

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
  String caloriesTotalHint(Object total) {
    return 'Macht $total kcal im Bestand.';
  }

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
  String get cameraDeniedTitle => 'Kamera nicht freigegeben';

  @override
  String get cameraDeniedBody =>
      'PreppSuite darf die Kamera nicht benutzen. Erlaube sie in den Systemeinstellungen und öffne diesen Bildschirm danach noch einmal.';

  @override
  String get cameraUnsupportedTitle => 'Keine Kamera';

  @override
  String get cameraUnsupportedBody =>
      'Dieses Gerät kann nicht mit der Kamera scannen.';

  @override
  String get cameraFailedTitle => 'Die Kamera kam nicht';

  @override
  String get cameraFailedBody => 'Der Bildsucher ließ sich nicht starten.';

  @override
  String get cameraAlternativeBarcode =>
      'Ohne Kamera geht es von Hand: zurück, und Name, Menge und Einheit selbst eintragen.';

  @override
  String get cameraAlternativeTransfer =>
      'Ohne Kamera geht die Übergabe über den gemeinsamen Ordner oder über eine Datei.';

  @override
  String get hazardReleaseTitle => 'Gefahrstoff in der Luft';

  @override
  String get hazardReleaseEntryHint =>
      'Was zu tun ist, wenn etwas freigesetzt wurde — im Haus, draußen, im Auto.';

  @override
  String get hazardReleaseIntro =>
      'Wenn eine Warnung meldet, dass Gefahrstoffe freigesetzt wurden, entscheiden die ersten Minuten. Was hier steht, ist die Handlungsanweisung des Bundesamtes für Bevölkerungsschutz und Katastrophenhilfe, wiedergegeben und nicht ausgelegt.';

  @override
  String get hazardReleaseHomeTitle => 'Wenn du zu Hause bist';

  @override
  String get hazardReleaseHomeStay =>
      'Im Gebäude bleiben. Gefährdete Passanten vorübergehend aufnehmen und andere Hausbewohner informieren.';

  @override
  String get hazardReleaseHomeWindows => 'Fenster und Türen schließen.';

  @override
  String get hazardReleaseHomeVent =>
      'Ventilatoren und Klimaanlagen ausschalten, die Lüftungsschlitze der Fensterrahmen schließen.';

  @override
  String get hazardReleaseHomeRoom =>
      'Einen geschützten Innenraum aufsuchen, möglichst einen ohne Außenfenster.';

  @override
  String get hazardReleaseHomeCandles =>
      'Keine Kerzen und nichts Ähnliches — das verbraucht unnötig Sauerstoff.';

  @override
  String get hazardReleaseHomeRadio =>
      'Radio einschalten, UKW und Regionalsender, oder den Fernseher. Durchsagen von Behörden und Einsatzkräften beachten.';

  @override
  String get hazardReleaseHomePhone => 'Nur in Notfällen telefonieren.';

  @override
  String get hazardReleaseHomeMask =>
      'Dringen Gefahrstoffe ein: vorhandenen Atemschutz benutzen, notfalls einen improvisierten Mundschutz.';

  @override
  String get hazardReleaseHomeWait =>
      'Auf die Entwarnung warten, bevor du das Gebäude verlässt oder ein Fenster öffnest.';

  @override
  String get hazardReleaseOutsideTitle => 'Wenn du draußen bist';

  @override
  String get hazardReleaseOutsideCross =>
      'Quer zur Windrichtung gehen, nicht mit ihm und nicht gegen ihn. Durch einen Atemschutz atmen, zur Not durch ein Taschentuch.';

  @override
  String get hazardReleaseOutsideBuilding =>
      'Das nächste geschlossene Gebäude aufsuchen und um Einlass bitten.';

  @override
  String get hazardReleaseOutsideClothes =>
      'Nach Kontakt beim Betreten Oberbekleidung und Schuhe wechseln, in Plastikbeutel packen und außerhalb des Wohnbereichs lassen, möglichst vor dem Gebäude.';

  @override
  String get hazardReleaseOutsideWash =>
      'Waschen in dieser Reihenfolge: zuerst gründlich die Hände, dann Gesicht und Haare, dann Nase und Ohren — mit Wasser und Seife.';

  @override
  String get hazardReleaseOutsideBio =>
      'Bei biologischen Stoffen zusätzlich die Hände desinfizieren.';

  @override
  String get hazardReleaseCarTitle => 'Wenn du im Auto bist';

  @override
  String get hazardReleaseCarVent =>
      'Belüftung ausschalten und die Fenster schließen.';

  @override
  String get hazardReleaseCarRadio =>
      'Radio hören, UKW und Regionalsender, und den Anweisungen folgen.';

  @override
  String get hazardReleaseCarBuilding =>
      'Das nächste geschlossene Gebäude aufsuchen, sofern Behörden und Einsatzkräfte nichts anderes anweisen.';

  @override
  String get hazardReleaseCellarTitle =>
      'Keller oder oberes Stockwerk? Das kommt auf den Stoff an';

  @override
  String get hazardReleaseCellarChemical =>
      'Bei Chemikalien den Keller meiden. Die meisten Gase und Dämpfe sind schwerer als Luft und sammeln sich in Senken und Kellerräumen.';

  @override
  String get hazardReleaseCellarRadio =>
      'Bei radioaktiven Stoffen umgekehrt: vorzugsweise einen Kellerraum aufsuchen. Ionisierende Strahlung wird beim Durchdringen von Materie abgeschwächt, und im Keller ist die Abschwächung durch die Erdschicht ringsum und die Stockwerke darüber besonders groß.';

  @override
  String get hazardReleaseCellarNote =>
      'Das ist kein Widerspruch, sondern zweimal dieselbe Überlegung: Gas sinkt, Strahlung wird von Masse gebremst. Welcher Fall vorliegt, sagt die Warnung.';

  @override
  String get hazardReleaseIodineLink =>
      'Radioaktives Jod: was Jodtabletten leisten';

  @override
  String get hazardReleaseSource =>
      'Quelle: Bundesamt für Bevölkerungsschutz und Katastrophenhilfe (BBK), „Handeln bei Gefahrstoff-Freisetzung\".';

  @override
  String get iodineTitle => 'Jodtabletten';

  @override
  String get iodineEntryHint =>
      'Wer sie nimmt, wann — und warum nur auf Aufforderung.';

  @override
  String get iodineIntro =>
      'Bei einem nuklearen Unfall kann radioaktives Jod frei werden. Es reichert sich in der Schilddrüse an und kann dort später Krebs auslösen. Eine hochdosierte Jodtablette sättigt die Schilddrüse vorher mit nicht-radioaktivem Jod, so dass sie das radioaktive nicht mehr aufnimmt. Das nennt sich Jodblockade.';

  @override
  String get iodineOnlyOnOrderTitle => 'Nur nach ausdrücklicher Aufforderung';

  @override
  String get iodineOnlyOnOrderBody =>
      'Hochdosierte Jodtabletten sollen nur eingenommen werden, wenn die Katastrophenschutzbehörden ausdrücklich dazu auffordern — und nur in der von ihnen genannten Dosis. Vom Einnehmen auf eigene Faust rät das BfS dringend ab, weil die Nebenwirkungen bis zum akuten Herz-Kreislauf-Versagen reichen können.';

  @override
  String get iodineOnlyThyroidTitle => 'Sie schützen nur die Schilddrüse';

  @override
  String get iodineOnlyThyroidBody =>
      'Und nur vor radioaktivem Jod. Gegen alle anderen radioaktiven Stoffe wirken sie nicht. Wer sie genommen hat, ist nicht geschützt und muss sich weiter an die Anweisungen halten.';

  @override
  String get iodineWhoTitle => 'Wer';

  @override
  String get iodineWhoUnder45 =>
      'Alle bis 45 Jahre, in den betroffenen Gebieten. Die Dosis hängt vom Alter ab und wird von den Behörden genannt.';

  @override
  String get iodineWhoChildren =>
      'Für Kinder und Jugendliche bis 18 besonders wichtig — ihre Schilddrüse ist besonders empfindlich.';

  @override
  String get iodineWhoPregnant =>
      'Auch Schwangere, dort vor allem zum Schutz des ungeborenen Kindes.';

  @override
  String get iodineWhoOver45 =>
      'Über 45 wird davon abgeraten. Das Risiko der Nebenwirkungen wiegt dort schwerer als der vermiedene Schilddrüsenkrebs.';

  @override
  String get iodineWhoThyroid =>
      'Wer eine Schilddrüsenerkrankung hat, nimmt sie erst nach Rücksprache mit dem behandelnden Arzt.';

  @override
  String get iodineWhenTitle => 'Wann';

  @override
  String get iodineWhenBody =>
      'Der Zeitpunkt entscheidet über die Wirkung. Ideal ist etwa eine Stunde vor dem Kontakt mit den Luftmassen, die das radioaktive Jod tragen. Zu früh eingenommen ist das Jod schon wieder abgebaut, zu spät hat die Schilddrüse das radioaktive bereits aufgenommen. Wann es so weit ist, geben die Katastrophenschutzbehörden über die Medien bekannt.';

  @override
  String get iodineHowOftenTitle => 'Wie oft';

  @override
  String get iodineHowOftenBody =>
      'Einmal reicht grundsätzlich. Eine weitere Tablette nur, wenn die Behörde das empfiehlt.';

  @override
  String get iodineWhereTitle => 'Woher';

  @override
  String get iodineWhereBody =>
      'Zuständig sind die Bundesländer. In der Umgebung von Kernkraftwerken sind die Tabletten je nach Land an die Haushalte vorverteilt oder liegen örtlich bereit, etwa in Rathäusern und Feuerwehrhäusern. Darüber hinaus lagern bundesweit mehr als 180 Millionen Tabletten; im Ereignisfall werden sie an Feuerwehrwachen, Rathäusern, Apotheken oder bekannten Wahllokalen ausgegeben, nach einem Aufruf in den Medien.';

  @override
  String get iodineRangeTitle => 'Wie weit';

  @override
  String get iodineRangeBody =>
      'Bei einem Unfall mit erheblicher Freisetzung kann die Einnahme für Erwachsene bis in 100 Kilometer Entfernung empfohlen werden — und für Kinder in ganz Deutschland.';

  @override
  String get iodineHazardLink =>
      'Was sonst zu tun ist: Gefahrstoff in der Luft';

  @override
  String get iodineSource =>
      'Quelle: Bundesamt für Strahlenschutz (BfS), „Einnahme und Wirkung von Jodtabletten\".';

  @override
  String get burglaryTitle => 'Einbruch';

  @override
  String get burglaryEntryHint =>
      'Auf frischer Tat, danach, und wie man vorbeugt.';

  @override
  String get burglaryRuleTitle => 'Die wichtigste Regel';

  @override
  String get burglaryRuleBody =>
      'Sich und andere nicht in Gefahr bringen. Vermeide nach Möglichkeit jede Konfrontation und stelle dich dem Einbrecher keinesfalls in den Weg.';

  @override
  String get burglaryCaughtTitle =>
      'Wenn du jemanden auf frischer Tat ertappst';

  @override
  String get burglaryCaughtLeave =>
      'Versuche, die Wohnung oder das Haus zu verlassen, und informiere die Nachbarn.';

  @override
  String get burglaryCaughtWindow =>
      'Kommst du nicht heraus: wenn möglich ein Fenster öffnen und um Hilfe rufen.';

  @override
  String get burglaryCaughtCall => 'Sofort 110.';

  @override
  String get burglaryCaughtDescribe =>
      'Der Polizei eine möglichst gute Beschreibung geben: die Person, ein etwaiges Fluchtfahrzeug und die Fluchtrichtung.';

  @override
  String get burglaryAfterTitle => 'Danach';

  @override
  String get burglaryAfterThreat => 'Bei akuter Bedrohung 110.';

  @override
  String get burglaryAfterReport =>
      'Anzeige erstatten – bei jeder Polizeidienststelle. Auch dann, wenn der Versuch gescheitert ist oder nichts gestohlen wurde.';

  @override
  String get burglaryAfterNoTidy =>
      'Nicht aufräumen. Alles so lassen, wie du es vorgefunden hast, und möglichst nichts anfassen, bis die Spuren gesichert sind.';

  @override
  String get burglaryAfterList =>
      'Eine Liste des Gestohlenen zusammenstellen, so genau wie möglich. Kaufbelege und Gerätenummern helfen, wenn etwas wieder auftaucht.';

  @override
  String get burglaryAfterKeys =>
      'Sind Schlüssel weg: die Schließzylinder vorsichtshalber austauschen lassen.';

  @override
  String get burglaryAfterPhone =>
      'Gestohlene Karten und Telefone sperren lassen, über den Sperrnotruf 116 116.';

  @override
  String get burglaryPossessionsLink =>
      'Die Wertgegenstandsliste, die die Polizei hier meint, hast du schon';

  @override
  String get burglaryPossessionsHint =>
      'Das Hausratverzeichnis dieser App ist genau das – ausgefüllt, bevor etwas passiert, ist es nach einem Einbruch die Liste, nach der gefragt wird.';

  @override
  String get burglaryPreventTitle => 'Vorbeugen';

  @override
  String get burglaryPreventWho =>
      'Die Mehrzahl der Einbrüche geht nicht auf Profis zurück, sondern auf Gelegenheitstäter, die mit einfachem Hebelwerkzeug an Fenster und Türen gehen. Eingebrochen wird meist über leicht erreichbare Fenster und Fenster- oder Wohnungstüren.';

  @override
  String get burglaryPreventDay =>
      'Entgegen der landläufigen Meinung wird häufig am Tag eingebrochen – zur Schul-, Arbeits- und Einkaufszeit, am frühen Abend und an Wochenenden. Über ein Drittel aller Wohnungseinbrüche sind Tageswohnungseinbrüche.';

  @override
  String get burglaryPreventMechanical =>
      'Die Polizei empfiehlt die mechanische Sicherung aller Fenster und Türen. Technik hält nicht ab, wenn sie nicht hineinlässt.';

  @override
  String get burglaryPreventNew =>
      'Bei Neu- und Umbauten: geprüfte einbruchhemmende Fenster und Türen nach DIN EN 1627 ff., ab Widerstandsklasse RC 2. Dort ist sichergestellt, dass Türblatt, Zarge, Schloss und Beschlag zusammen keinen Schwachpunkt haben.';

  @override
  String get burglaryPreventRetro =>
      'Zum Nachrüsten: Systeme nach DIN 18104 Teil 1 und 2. Die Teile müssen in ihrer Wirkung aufeinander abgestimmt sein.';

  @override
  String get burglaryPreventSide =>
      'Nebeneingangstüren lassen sich mit massiven Schubriegeln, starken Vorlegestangen oder einem Querriegelschloss nachrüsten.';

  @override
  String get burglaryPreventFit =>
      'Eingebaute Sicherungen wirken nur bei fachgerechter Montage. Und Technik ersetzt nicht das Zweite, was die Polizei nennt: sicherheitsbewusstes Verhalten und eine aufmerksame Nachbarschaft.';

  @override
  String get burglarySource =>
      'Quelle: Polizeiliche Kriminalprävention der Länder und des Bundes (polizei-beratung.de) und die Initiative K-EINBRUCH. Zahlen aus der Polizeilichen Kriminalstatistik 2025.';

  @override
  String get supplyGroupsTitle => 'Vorratsgruppen';

  @override
  String get supplyGroupsEntryHint =>
      'Deckt der Vorrat alle Gruppen ab, nicht nur die Kalorien?';

  @override
  String get supplyGroupsIntro =>
      'Zehn Tage Kalorien können zehn Tage Nudeln sein. Die Bundesanstalt für Landwirtschaft und Ernährung nennt in ihrem Vorratskalkulator für jede Lebensmittelgruppe eine Menge je Person und Tag. Das hier ist dein Bestand daneben.';

  @override
  String get supplyGroupsPersonsNote =>
      'Gerechnet wird je Person und Tag, ohne nach Alter zu unterscheiden — so macht es die BLE-Tabelle. Beim Trinkwasser ist das anders, da nennt ihre Fußnote Kinder gesondert; der Vorratsrechner folgt dort der Fußnote.';

  @override
  String get supplyGroupGrain => 'Getreideprodukte, Brot, Kartoffeln';

  @override
  String get supplyGroupVegetables => 'Gemüse, Pilze';

  @override
  String get supplyGroupFruit => 'Obst';

  @override
  String get supplyGroupDrinks => 'Getränke';

  @override
  String get supplyGroupDairy => 'Milch, Milcherzeugnisse';

  @override
  String get supplyGroupProtein => 'Eier, Fleisch, Wurst und Fisch';

  @override
  String get supplyGroupFats => 'Fette, Öl';

  @override
  String get supplyGroupNone => 'Keiner Gruppe zugeordnet';

  @override
  String get supplyGroupLabel => 'Vorratsgruppe';

  @override
  String get supplyGroupHelper =>
      'Nur für Lebensmittel und Wasser. Ohne Angabe zählt der Artikel in keiner Gruppe mit.';

  @override
  String get supplyGroupsUnassignedTitle => 'Ohne Gruppe';

  @override
  String get supplyGroupsUnassignedBody =>
      'Diese Artikel zählen oben nirgends mit. Die App ordnet sie nicht selbst zu — „Nudeln‑Auflauf‑Gewürz\" ist kein Getreide, und Raten wäre hier einmal zu oft falsch.';

  @override
  String get supplyGroupsUnmeasuredTitle => 'Gruppe ja, Menge nein';

  @override
  String get supplyGroupsUnmeasuredBody =>
      'Diese Artikel haben eine Gruppe, aber ihre Einheit lässt sich nicht in Gramm oder Milliliter umrechnen — oder sie passt nicht zur Gruppe. Auch sie fehlen in den Zahlen oben.';

  @override
  String get supplyGroupsAllAssigned =>
      'Jeder Lebensmittel- und Wasserartikel ist einer Gruppe zugeordnet.';

  @override
  String get supplyGroupsSource =>
      'Quelle: Vorratskalkulator der Bundesanstalt für Landwirtschaft und Ernährung (BLE), Mengen je Person und Tag bei 2200 kcal.';

  @override
  String supplyGroupsShare(String have, String target) {
    return '$have von $target';
  }

  @override
  String get cancelButton => 'Abbrechen';

  @override
  String get navChecklists => 'Checklisten';

  @override
  String get checklistsTitle => 'Checklisten';

  @override
  String get checklistKindPreparation => 'Vorsorge';

  @override
  String get checklistKindResponse => 'Im Ereignis';

  @override
  String get checklistKindPreparationIntro =>
      'Was da sein muss, bevor etwas passiert.';

  @override
  String get checklistKindResponseIntro =>
      'Was zu tun ist, während es passiert.';

  @override
  String get checklistKindLabel => 'Art der Liste';

  @override
  String get checklistKindEmpty => 'In diesem Teil ist noch keine Liste.';

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
  String get warningDayToday => 'Heute ist bundesweiter Warntag';

  @override
  String warningDayIn(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: 'einem Tag',
    );
    return 'Bundesweiter Warntag in $_temp0';
  }

  @override
  String get warningDayBody =>
      'Probewarnung um 11:00, Entwarnung um 11:45. Sirenen, Cell Broadcast, Radio und Warn-Apps werden zusammen getestet. Es ist der einzige Tag im Jahr, an dem sich prüfen lässt, ob dich wirklich erreicht, was dich erreichen soll – eine Warnung, die nicht ankommt, fällt sonst niemandem auf.';

  @override
  String get warningDayNotificationTitle => 'Heute ist bundesweiter Warntag';

  @override
  String get warningDayNotificationBody =>
      'Um 11:00 geht die Probewarnung raus, um 11:45 die Entwarnung. Gute Gelegenheit zu prüfen, ob Sirene, Cell Broadcast und Warn-Apps bei dir ankommen.';

  @override
  String get pegelTitle => 'Pegelstände';

  @override
  String get pegelEntryHint =>
      'Wasserstand am eigenen Fluss, mit den Vergleichswerten des Pegels';

  @override
  String get pegelNoneChosen => 'Noch kein Pegel gewählt.';

  @override
  String get pegelUpstreamHint =>
      'Wähle den Pegel flussaufwärts von dir. Der nächstgelegene hilft nicht, wenn er flussabwärts liegt – er zeigt, was schon vorbei ist, nicht was kommt.';

  @override
  String get pegelChoose => 'Pegel wählen';

  @override
  String get pegelChange => 'Anderen Pegel wählen';

  @override
  String get pegelSearchHint => 'Pegel oder Gewässer suchen';

  @override
  String get pegelSearchEmpty => 'Kein Pegel gefunden.';

  @override
  String get pegelLoadFailed =>
      'Die Pegelliste ließ sich nicht laden. Sie braucht einmal eine Verbindung.';

  @override
  String get pegelOffline =>
      'Keine Verbindung – das ist der letzte abgerufene Wert.';

  @override
  String get pegelStale =>
      'Älter als eine Stunde. Binnenpegel melden alle 15 Minuten, hier fehlt also die Verbindung und nicht das Wasser.';

  @override
  String pegelMeasuredAt(String time) {
    return 'Gemessen $time';
  }

  @override
  String get pegelRefresh => 'Aktualisieren';

  @override
  String pegelKilometre(String km) {
    return 'Flusskilometer $km';
  }

  @override
  String get pegelReferences => 'Vergleichswerte dieses Pegels';

  @override
  String get pegelNoReferences =>
      'Für diesen Pegel sind keine Vergleichswerte veröffentlicht. Die Zahl steht damit ohne Maßstab da.';

  @override
  String get pegelNoMeldestufe =>
      'Keine Warnstufe: Meldestufen legen die Länder fest und stehen nicht in diesen Daten. Amtliche Hochwasserwarnungen stehen in der Warnungsliste.';

  @override
  String get pegelSource =>
      'Quelle: PEGELONLINE der Wasserstraßen- und Schifffahrtsverwaltung. Nur Bundeswasserstraßen – der Bach, der ein Dorf überflutet, ist hier nicht dabei.';

  @override
  String get pegelBandRecordLow => 'Niedriger als je gemessen';

  @override
  String get pegelBandLow => 'Niedrigwasser';

  @override
  String get pegelBandOrdinary => 'Im gewöhnlichen Bereich';

  @override
  String get pegelBandElevated => 'Über dem Mittelwert';

  @override
  String get pegelBandFlood => 'Hochwasser';

  @override
  String get pegelBandRecordHigh => 'Höher als je gemessen';

  @override
  String get pegelBandUnknown => 'Nicht einzuordnen';

  @override
  String pegelTrendRising(String change) {
    return 'Steigend, $change cm in 24 Stunden';
  }

  @override
  String pegelTrendFalling(String change) {
    return 'Fallend, $change cm in 24 Stunden';
  }

  @override
  String get pegelTrendSteady => 'Kaum verändert in 24 Stunden';

  @override
  String get pegelTrendUnknown => 'Verlauf nicht verfügbar';

  @override
  String get pegelRefMean => 'Mittelwasser';

  @override
  String get pegelRefMeanFlood => 'Mittleres Hochwasser';

  @override
  String get pegelRefHighest => 'Höchster gemessener Stand';

  @override
  String get pegelRefMeanLow => 'Mittleres Niedrigwasser';

  @override
  String get pegelRefLowest => 'Niedrigster gemessener Stand';

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
  String get languageLabel => 'Sprache';

  @override
  String get languageSystemOption => 'System';

  @override
  String get languageGermanOption => 'Deutsch';

  @override
  String get languageEnglishOption => 'English';

  @override
  String inventoryAttentionTooltip(int count) {
    return '$count Artikel mit niedrigem Bestand oder abgelaufen';
  }

  @override
  String get settingsCategoryWarnings => 'Warnungen und Orte';

  @override
  String get settingsCategoryWarningsBody =>
      'Benachrichtigungen, Warnorte und Aktualisierungsstatus';

  @override
  String get settingsCategoryReminders => 'Erinnerungen';

  @override
  String get settingsCategoryRemindersBody => 'Akkus, Geräte und Ablaufdaten';

  @override
  String get settingsCategoryAppearance => 'Darstellung und Sprache';

  @override
  String get settingsCategoryAppearanceBody => 'Farbschema und App-Sprache';

  @override
  String get settingsCategoryData => 'Daten und Sicherheit';

  @override
  String get settingsCategoryDataBody =>
      'Sperre, Freigabe, Sicherung und Zurücksetzen';

  @override
  String get settingsCategoryOffline => 'Offline und Speicher';

  @override
  String get settingsCategoryOfflineBody => 'Karten, Archive und Speicherorte';

  @override
  String get settingsCategoryAbout => 'Über PreppSuite';

  @override
  String get settingsCategoryAboutBody =>
      'Versionen der App und lokaler Module';

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
  String get settingsWarningReadinessTitle => 'Warnbereitschaft';

  @override
  String get settingsWarningReadinessBody =>
      'Prüft die lokale Einrichtung. Hintergrundaktualisierungen werden vom Betriebssystem geplant und sind nicht garantiert.';

  @override
  String get settingsWarningReadinessNotifications => 'Warnbenachrichtigungen';

  @override
  String get settingsWarningReadinessRegions => 'Beobachtete Regionen';

  @override
  String get settingsWarningReadinessRefresh =>
      'Letzte vollständige Aktualisierung';

  @override
  String get settingsWarningReadinessEnabled => 'Aktiviert';

  @override
  String get settingsWarningReadinessDisabled => 'Nicht aktiviert';

  @override
  String settingsWarningReadinessRegionsSet(int count) {
    return 'Hauptort und $count weitere Regionen';
  }

  @override
  String get settingsWarningReadinessRegionsMissing =>
      'Noch kein Hauptort festgelegt';

  @override
  String get settingsWarningReadinessNeverUpdated =>
      'Noch keine vollständige Aktualisierung';

  @override
  String get settingsWarningReadinessJustNow => 'Gerade eben aktualisiert';

  @override
  String settingsWarningReadinessMinutesAgo(int minutes) {
    return 'Vor $minutes Minuten aktualisiert';
  }

  @override
  String settingsWarningReadinessHoursAgo(int hours) {
    return 'Vor $hours Stunden aktualisiert';
  }

  @override
  String settingsWarningReadinessDaysAgo(int days) {
    return 'Vor $days Tagen aktualisiert';
  }

  @override
  String get settingsWarningReadinessBlockedTitle =>
      'Hintergrundabruf ausgesetzt';

  @override
  String get settingsWarningReadinessBlockedBody =>
      'Der letzte geplante Abruf konnte die lokalen Daten nicht öffnen. Nach dem Entsperren des Geräts die App einmal öffnen.';

  @override
  String get settingsLocalEncryptionTitle => 'Lokale Verschlüsselung';

  @override
  String get settingsLocalEncryptionStateEncrypted => 'Verschlüsselt';

  @override
  String get settingsLocalEncryptionStatePlain => 'Nicht verschlüsselt';

  @override
  String settingsLocalEncryptionStatePartial(int count) {
    return 'Noch $count Datenbanken unverschlüsselt';
  }

  @override
  String get settingsLocalEncryptionStateRecovery =>
      'Schlüssel nicht verfügbar';

  @override
  String get settingsLocalEncryptionUnsupported =>
      'Diese Fassung enthält keine Verschlüsselungsbibliothek.';

  @override
  String get settingsLocalEncryptionPortable =>
      'Ein mitgeführter Datenordner wird nicht verschlüsselt: der Schlüssel bliebe auf diesem Rechner und der Ordner ließe sich nirgendwo sonst öffnen.';

  @override
  String get settingsLocalEncryptionNoKeyStore =>
      'Dieses Gerät gibt keinen Schlüsselspeicher frei. Unter macOS braucht die App dafür eine Signatur; ohne sie bleiben die lokalen Daten unverschlüsselt.';

  @override
  String get settingsLocalEncryptionScope =>
      'Nicht betroffen: PDFs, Karten, ZIM-Archive, Fotos und alles, was du exportierst.';

  @override
  String get settingsLocalEncryptionTestBackup => 'Sicherung prüfen';

  @override
  String get settingsLocalEncryptionTestBackupHint =>
      'Liest eine Sicherungsdatei zurück. Es wird nichts verändert.';

  @override
  String settingsLocalEncryptionBackupVerified(int rows) {
    return 'Sicherung gelesen: $rows Datensätze.';
  }

  @override
  String get settingsLocalEncryptionBackupUnreadable =>
      'Diese Datei liess sich nicht als Sicherung dieses Haushalts lesen.';

  @override
  String get settingsLocalEncryptionBackupNever =>
      'Noch keine Sicherung geprüft.';

  @override
  String get settingsLocalEncryptionBackupStale =>
      'Die letzte Prüfung ist über einen Tag her.';

  @override
  String get settingsLocalEncryptionStart => 'Lokale Daten jetzt verschlüsseln';

  @override
  String get settingsLocalEncryptionConfirmTitle => 'Jetzt verschlüsseln?';

  @override
  String get settingsLocalEncryptionConfirmBody =>
      'Alle lokalen Datenbanken werden neu geschrieben. Vorübergehend wird so viel freier Platz gebraucht, wie die größte davon belegt. Das Gerät sollte am Strom sein und die App nicht geschlossen werden. Danach muss PreppSuite neu gestartet werden.';

  @override
  String get settingsLocalEncryptionRunning =>
      'Die Datenbanken werden verschlüsselt. Bitte die App nicht schliessen.';

  @override
  String get settingsLocalEncryptionDoneTitle =>
      'Verschlüsselung abgeschlossen';

  @override
  String get settingsLocalEncryptionDoneBody =>
      'PreppSuite jetzt schliessen und neu öffnen.';

  @override
  String get settingsLocalEncryptionFailed =>
      'Die Verschlüsselung wurde abgebrochen. Die Daten sind unverändert lesbar.';

  @override
  String get localDataRecoveryTitle => 'Lokale Daten gesperrt';

  @override
  String get localDataRecoveryBody =>
      'Dieses Gerät findet den Schlüssel für die lokalen Datenbanken nicht mehr. Die Dateien sind noch da, ohne den Schlüssel aber nicht lesbar. Der Weg zurück führt über eine Sicherung.';

  @override
  String get localDataRecoveryRetry => 'Erneut versuchen';

  @override
  String get localDataRecoveryStartOver => 'Neu einrichten';

  @override
  String get localDataRecoveryStartOverBody =>
      'Die unlesbaren Dateien werden nicht gelöscht, sondern umbenannt und bleiben liegen. Danach fragt PreppSuite von vorne — dort steht „Aus einer Sicherung wiederherstellen“, und der Haushalt kommt mit seiner bisherigen Kennung zurück.';

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
  String get shelterMapTitle => 'Schutzräume';

  @override
  String shelterInfoLine(int radius) {
    return 'OpenStreetMap und WWBOTA/DLBOTA im Umkreis von $radius km geladen.';
  }

  @override
  String get shelterLegendTitle => 'Einordnung der Markierungen';

  @override
  String shelterLegendSummary(int green, int yellow, int red) {
    return 'Grün $green · Gelb $yellow · Rot $red';
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
  String get settingsChargeReminderHint =>
      'Erinnert daran, Powerbanks, Akkus, Taschenlampen und Notfunkgeräte aufzuladen und zu testen.';

  @override
  String get settingsChargeReminderDisabledHint =>
      'Schalte oben die Benachrichtigungen ein, damit die Auflade-Erinnerung geplant wird.';

  @override
  String get settingsChargeReminderNoneHint =>
      'Keine Auflade-Erinnerung geplant.';

  @override
  String get settingsChargeReminderCustom => 'Eigener Abstand…';

  @override
  String get settingsChargeReminderCustomTitle => 'Eigener Abstand';

  @override
  String get settingsChargeReminderCustomLabel => 'Tage zwischen den Prüfungen';

  @override
  String settingsChargeReminderCustomInvalid(int min, int max) {
    return 'Eine ganze Zahl zwischen $min und $max eingeben.';
  }

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
  String get itemExpiryRemindersLabel => 'Erinnerungen für diesen Artikel';

  @override
  String get itemExpiryRemindersTitle => 'Vorlaufzeit für diesen Artikel';

  @override
  String get itemExpiryRemindersHint =>
      'Gilt nur für diesen Eintrag. Ohne eigene Angabe zählt, was unter Einstellungen für den ganzen Haushalt eingestellt ist.';

  @override
  String get itemExpiryRemindersDefault => 'Wie im Haushalt eingestellt';

  @override
  String get itemExpiryRemindersOwn => 'Eigene Vorlaufzeit';

  @override
  String get itemExpiryRemindersNever => 'Für diesen Artikel nie erinnern';

  @override
  String get itemExpiryRemindersNone => 'Keine';

  @override
  String get itemExpiryRemindersDefaultNone =>
      'Wie im Haushalt: keine Erinnerung';

  @override
  String itemExpiryRemindersDefaultWith(String days) {
    return 'Wie im Haushalt: $days';
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
  String get householdPlanContactPoint => 'Anlaufstelle der Gemeinde';

  @override
  String get householdPlanContactPointHint =>
      'Das Gebäude mit Notstrom, das bei langem Stromausfall aufmacht – dort gibt es Auskunft, und von dort geht ein Notruf raus, wenn kein Telefon mehr geht. Es heißt je nach Land Katastrophenschutz-Leuchtturm, Notfalltreffpunkt oder Notfallinfopunkt; die Gemeinde weiß, wo das nächste ist. Kein Treffpunkt – dorthin geht man um Hilfe, nicht um sich zu finden.';

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
  String get drillsEmergencyMode => 'Notfallmodus';

  @override
  String get drillsCallEmergency => '112 anrufen';

  @override
  String get drillsHarmless =>
      'Die Übung verändert keine Vorräte und verschickt keine Nachrichten.';

  @override
  String get drillsReset => 'Von vorn beginnen';

  @override
  String get drillsTitle => 'Notfallmodus und Übungen';

  @override
  String get drillsSubtitle => 'Ablaufkarte und realistische Haushaltsübungen';

  @override
  String get drillsImmediateDanger =>
      'Bei unmittelbarer Gefahr zuerst 112 wählen. Danach amtliche Warnungen prüfen, Angehörige nach dem Haushaltsplan informieren und Strom sparen.';

  @override
  String get drillsSectionTitle => 'Übungsmodus';

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
  String get emergencyCardDoctors => 'Ärztinnen und Ärzte';

  @override
  String get emergencyCardDoctorAdd => 'Ärztin oder Arzt hinzufügen';

  @override
  String get emergencyCardSpecialty => 'Fachrichtung';

  @override
  String get emergencyCardSpecialtyHint => 'z. B. Hausärztin, Kardiologe';

  @override
  String get emergencyCardContacts => 'Wen man wegen dieser Person anruft';

  @override
  String get emergencyCardContactAdd => 'Kontakt hinzufügen';

  @override
  String get emergencyCardRelation => 'Verhältnis';

  @override
  String get emergencyCardRelationHint => 'z. B. Partnerin, Sohn, Nachbarin';

  @override
  String get emergencyCardPhone => 'Rufnummer';

  @override
  String get emergencyCardPersonRemove => 'Eintrag entfernen';

  @override
  String get emergencyCardNotes => 'Sonstiges';

  @override
  String get emergencyCardNameRequired => 'Eine Karte braucht einen Namen.';

  @override
  String get emergencyCardRemoved => 'Karte entfernt.';

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
  String get emergencyCardBirthYearInvalid => 'Das ist kein Jahr.';

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
  String knowledgeIndexStorage(String size) {
    return 'Suchindex: $size';
  }

  @override
  String get knowledgeIndexCompactHint =>
      'Dieser Index stammt aus einem älteren Format. Ein kompakter Neuaufbau spart Speicherplatz, ohne die normale Volltextsuche zu verändern.';

  @override
  String get knowledgeIndexCompactAction => 'Kompakt neu aufbauen';

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
  String get downloadResumingLabel =>
      'Verbindung unterbrochen – wird fortgesetzt …';

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
  String mapDownloadDeepestPossible(String count, String level) {
    return 'Auf Stufe 14 wären es $count Kacheln — zu viel. Stufe $level ist das Tiefste, was für dieses Gebiet geht.';
  }

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
  String get distressTitle => 'Notsignal';

  @override
  String get distressIntro =>
      'Wenn kein Netz mehr da ist, dich aber jemand sehen könnte. Der Bildschirm blinkt in einem Rhythmus, den Rettungskräfte kennen — halte ihn hoch, zum Hang oder zum Tal.';

  @override
  String get distressBattery =>
      'Das kostet Helligkeit und damit Akku. Schalte es ein, wenn jemand da sein könnte, nicht auf Verdacht.';

  @override
  String get distressStart => 'Signal starten';

  @override
  String get distressStop => 'Anhalten';

  @override
  String get distressPause => 'Pause — hier kommt die Antwort hinein';

  @override
  String distressFlash(int number, int total) {
    return 'Zeichen $number von $total';
  }

  @override
  String get distressSos => 'SOS';

  @override
  String get distressSosHint =>
      'Dreimal kurz, dreimal lang, dreimal kurz — als ein Zeichen, nicht als drei Buchstaben.';

  @override
  String get distressAlpine => 'Alpines Notsignal';

  @override
  String get distressAlpineHint =>
      'Sechs Zeichen in einer Minute, dann eine Minute nichts, dann wieder. Die Pause gehört dazu: sie unterscheidet das Signal von jemandem, der mit einer Lampe herumläuft.';

  @override
  String get distressAlpineAnswer => 'Antwort auf ein Notsignal';

  @override
  String get distressAlpineAnswerHint =>
      'Drei Zeichen in einer Minute, in die Pause des anderen hinein: „Ich habe dich gesehen.“';

  @override
  String get myPositionAction => 'Standort weitergeben';

  @override
  String get myPositionTitle => 'Mein Standort';

  @override
  String get myPositionIntro =>
      'Lies vor, wonach gefragt wird. Eine Leitstelle verlangt meist Grad und Minuten und liest sie zurück.';

  @override
  String get myPositionOffline =>
      'Die App rechnet das selbst aus. Es braucht kein Netz — genau dann ist es gefragt.';

  @override
  String get myPositionMeasure => 'Neu messen';

  @override
  String get myPositionCopied => 'Kopiert.';

  @override
  String myPositionAccuracy(int metres) {
    return 'Der Empfänger meldet ±$metres m.';
  }

  @override
  String get myPositionAccuracyPoor =>
      'Das reicht nicht bis zur Hausnummer. Unter freiem Himmel noch einmal messen, und der Leitstelle die Ungenauigkeit mitsagen.';

  @override
  String myPositionStale(int minutes) {
    return 'Diese Messung ist $minutes Minuten alt. Das Gerät hat gerade keine frische bekommen – unter freiem Himmel noch einmal messen, bevor du sie durchgibst.';
  }

  @override
  String nearbyStale(int minutes) {
    return 'Gerechnet mit der letzten bekannten Position, $minutes Minuten alt.';
  }

  @override
  String get myPositionDms => 'Grad, Minuten, Sekunden';

  @override
  String get myPositionDmsHint =>
      'Was eine Leitstelle am Telefon verlangt — und was sich vorlesen und mitschreiben lässt.';

  @override
  String get myPositionUtm => 'UTM';

  @override
  String get myPositionUtmHint =>
      'Meter auf dem Gitter. Damit rechnen Rettungsdienst, Feuerwehr und THW.';

  @override
  String get myPositionMgrs => 'MGRS';

  @override
  String get myPositionMgrsHint =>
      'Dasselbe Gitter als kurze Kennung, wie sie auf gegitterten Karten am Rand steht.';

  @override
  String get myPositionPlusCode => 'Plus Code';

  @override
  String get myPositionPlusCodeHint =>
      'Zehn Zeichen ohne jede Karte, zum Weitergeben an jemanden, der sie eintippt.';

  @override
  String get myPositionDecimal => 'Dezimalgrad';

  @override
  String get myPositionDecimalHint => 'Was in eine Karten-App hineingeht.';

  @override
  String get mapMyLocationAction => 'Mein Standort';

  @override
  String get mapCoverageMissing =>
      'Die Offlinekarte reicht nicht bis hierher. Für diesen Ausschnitt wurde nie etwas heruntergeladen.';

  @override
  String mapCoverageIncomplete(int present, int total) {
    return 'Die Offlinekarte deckt diesen Ausschnitt nur teilweise ab – etwa $present von $total Kacheln. Der Rest bleibt leer, weil er nie heruntergeladen wurde.';
  }

  @override
  String get mapCoverageUseOnline => 'Online-Karte verwenden';

  @override
  String get mapCoverageUseOffline => 'Offlinekarte verwenden';

  @override
  String get mapTilesUnavailable =>
      'Kacheln vom Kartenserver kamen nicht an. Was fehlt, liegt an der Verbindung, nicht an der App.';

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
      'Für Erwachsene nennt das BBK 1,5 Liter Flüssigkeit am Tag plus 0,5 Liter zum Kochen und rund 2200 kcal. Für Kinder nennt das BBK selbst keine Zahl, verweist aber auf die Bundesanstalt für Landwirtschaft und Ernährung, und deren Vorratstabelle sagt es in einer Fußnote: Kinder bis 12 Jahre (keine Säuglinge) brauchen im Schnitt 1 Liter am Tag, nach DGE und Max-Rubner-Institut. Die App rechnet damit — 1 Liter plus die 0,5 Liter zum Kochen. Ab 65 Jahren empfiehlt dieselbe Fußnote 2 Liter am Tag; das Alter steht nicht im Haushaltsprofil, deshalb steht dazu nur ein Hinweis auf dem Vorratsbildschirm. Die 1400 kcal für Kinder sind weiterhin die eigene, vorsichtige Schätzung dieser App — dafür gibt es keine amtliche Zahl. Für Säuglinge nennt niemand eine Menge: die Fußnote schließt sie ausdrücklich aus („Kinder (nicht Säuglinge)“), und die App erfindet dafür keine Zahl. Das BZfE nennt nur die Art des Vorrats — Pre- oder Säuglingsnahrung, Brei, sauberes Wasser zum Zubereiten, dazu Windeln und Pflegemittel. Trag das als eigene Artikel ein und richte die Menge nach dem, was dein Kind am Tag tatsächlich braucht. Für Hunde und Katzen wird nur Wasser gerechnet, nach der tierärztlichen Faustregel von etwa 60 ml je Kilogramm — 1,2 Liter für einen Hund von 20 kg, 0,25 Liter für eine Katze von 4 kg. Wer es genau braucht: der Vorratskalkulator des BMEL.';

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
  String get waterTreatmentTitle => 'Wasser trinkbar machen';

  @override
  String get waterTreatmentIntro =>
      'Der Vorrat ist das eine. Wenn er zu Ende geht oder das Leitungswasser nicht mehr sicher ist, zählt, was sich damit machen lässt — und was nicht.';

  @override
  String get waterTreatmentChemistryTitle =>
      'Kein Verfahren hilft gegen Chemie';

  @override
  String get waterTreatmentChemistryBody =>
      'Treibstoff, Chemikalien und radioaktives Material bekommt keines dieser Verfahren aus dem Wasser. Wasser von einer überfluteten Straße oder aus der Nähe eines aufgeschwommenen Heizöltanks wird durch Abkochen nicht trinkbar. Solches Wasser bleibt stehen.';

  @override
  String get waterTreatmentBoilTitle => 'Abkochen';

  @override
  String get waterTreatmentBoilCloudy =>
      'Trübes Wasser zuerst durch ein sauberes Tuch, Küchenpapier oder einen Kaffeefilter geben — oder absetzen lassen und das klare Wasser abgießen.';

  @override
  String get waterTreatmentBoilStep =>
      'Klares Wasser sprudelnd aufkochen. Die WHO hält das sprudelnde Aufkochen für ausreichend, um Bakterien, Viren und Parasiten abzutöten; die CDC empfiehlt, eine Minute sprudelnd zu kochen, in großer Höhe über rund 2000 Metern drei Minuten.';

  @override
  String get waterTreatmentBoilStore =>
      'Abkühlen lassen und in sauberen, dicht verschließbaren Behältern aufbewahren.';

  @override
  String get waterTreatmentChlorineTitle => 'Entkeimungsmittel';

  @override
  String get waterTreatmentChlorineStep =>
      'Nach Aufschrift dosieren, gut umrühren und mindestens 30 Minuten stehen lassen, bevor getrunken wird.';

  @override
  String get waterTreatmentChlorineLimit =>
      'Wirkt gegen Bakterien und Viren, gegen die Parasiten Cryptosporidium und Giardia aber schlechter als Abkochen — Chlor- und Jodtabletten töten Cryptosporidium nicht. Wo gekocht werden kann, wird gekocht.';

  @override
  String get waterTreatmentFilterTitle => 'Filtern';

  @override
  String get waterTreatmentFilterBody =>
      'Ein Filter nimmt die Trübung und, je nach Filter, auch Keime. Was er leistet, steht auf ihm — nicht jeder hält Viren zurück. Das Abkochen ersetzt er nur, wenn er ausdrücklich dafür ausgewiesen ist.';

  @override
  String get waterTreatmentSources =>
      'Quellen: WHO-Leitlinien für Trinkwasserqualität und „Boil water“; CDC, Wasser im Notfall sicher machen.';

  @override
  String get waterTreatmentOpen => 'Wasser trinkbar machen';

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
      'Jeweils je 100 g – oder je 100 ml bei Getränken –, genau wie auf dem Etikett. Beim Scannen trägt die App ein, was dort steht; hochgerechnet wird selbst.';

  @override
  String get proteinLabel => 'Eiweiß';

  @override
  String get carbohydrateLabel => 'Kohlenhydrate';

  @override
  String get fatLabel => 'Fett';

  @override
  String get fiberLabel => 'Ballaststoffe';

  @override
  String get supplyCalculatorInfantNote =>
      'Säuglinge sind hier nicht eingerechnet — was für sie zu bevorraten ist, steht unter „Woher die Zahlen kommen“.';

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
  String get overviewChargeDue => 'Akkugeräte prüfen';

  @override
  String overviewChargeOverdue(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: 'einem Tag',
    );
    return 'Seit $_temp0 überfällig';
  }

  @override
  String get overviewChargeDueToday => 'Heute fällig';

  @override
  String overviewChargeNext(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days Tagen',
      one: 'einem Tag',
    );
    return 'Nächste Prüfung in $_temp0';
  }

  @override
  String get overviewChargeNeverChecked => 'Noch nicht bestätigt';

  @override
  String get overviewChargeDone => 'Geprüft';

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
  String get budgetEntryDeleted => 'Ausgabe gelöscht';

  @override
  String emergencyRadioChannels(int count) {
    return '$count Kanäle';
  }

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
  String get warningWhatToDoNow => 'Was jetzt zu tun ist';

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
  String get knowledgeLibraryTitle => 'Deine Archive';

  @override
  String get knowledgeLibraryEmpty => 'Kein Archiv mehr in der Bibliothek.';

  @override
  String get knowledgeManageArchives => 'Archive verwalten';

  @override
  String knowledgeArchiveCount(int count) {
    return '$count Archive auf diesem Gerät';
  }

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
  String get backupPassphraseWarning =>
      'Ohne dieses Passwort lässt sich die Datei nicht mehr öffnen – auch von dir nicht. Es gibt keinen Weg zurück und keine Hintertür. Schreib es dorthin, wo auch die Ausweise liegen, und nicht auf das Gerät, das die Sicherung ersetzen soll.';

  @override
  String backupPassphraseInvalid(int count) {
    return 'Mindestens $count Zeichen eingeben; beide Eingaben müssen übereinstimmen.';
  }

  @override
  String get warningInstructionsTitle => 'Handlungsempfehlungen';

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
  String get knowledgeDocumentRemove => 'Aus Bibliothek entfernen';

  @override
  String get knowledgeDocumentOpenFailed =>
      'Das Dokument konnte nicht geöffnet werden.';

  @override
  String get knowledgeDocumentOpenExternal => 'Extern öffnen';

  @override
  String get knowledgeDocumentContinue => 'Weiterlesen';

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
  String get emergencySirenTitle => 'Sirenensignale';

  @override
  String get emergencySirenHint =>
      'Bundesweit empfohlen, aber nicht überall gleich geregelt – im Zweifel gilt, was die eigene Gemeinde bekanntgegeben hat. Auf jede Warnung folgt dasselbe: hinein, Fenster zu, Radio an.';

  @override
  String get emergencySirenWarning =>
      'Auf- und abschwellender Heulton, eine Minute';

  @override
  String get emergencySirenWarningMeaning =>
      'Warnung. Gefahr in der Nähe. Gebäude aufsuchen, Fenster und Türen schließen, Radio einschalten und auf Ansagen warten.';

  @override
  String get emergencySirenAllClear => 'Durchgehender Dauerton, eine Minute';

  @override
  String get emergencySirenAllClearMeaning =>
      'Entwarnung. Die Gefahr ist vorbei. Sie kommt über denselben Weg wie die Warnung.';

  @override
  String get emergencySirenFire => 'Zweimal unterbrochener Ton, eine Minute';

  @override
  String get emergencySirenFireMeaning =>
      'Feuerwehralarm. Er ruft die Einsatzkräfte und gilt nicht der Bevölkerung – kein Anlass, etwas zu tun.';

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
  String get emergencyContactEdit => 'Kontakt bearbeiten';

  @override
  String get emergencyContactDelete => 'Kontakt löschen';

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
      'Für den Index zu groß (maximal 256 MB)';

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
      'PMR446, Freenet, CB- und Amateurfunk: Frequenzen, Regeln und Hinweise';

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
  String get statusSupplyTitle => 'Vorrat';

  @override
  String statusSupplyCovered(int days) {
    return 'Reicht $days Tage';
  }

  @override
  String statusSupplyShort(int days, int target) {
    return 'Reicht $days von $target Tagen';
  }

  @override
  String get statusSupplyUnknown => 'Noch nichts eingetragen';

  @override
  String statusSupplyBasis(int target) {
    return 'Gegen die Empfehlung des BBK: $target Tage, 2 l und 2200 kcal je Person und Tag.';
  }

  @override
  String statusSupplyUncounted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Posten sind nicht mitgerechnet',
      one: 'Ein Posten ist nicht mitgerechnet',
    );
    return '$_temp0 – die Einheit nennt kein Maß.';
  }

  @override
  String get statusSituationTitle => 'Lage';

  @override
  String get statusSituationQuiet => 'Keine amtliche Warnung';

  @override
  String get statusSituationQuietHint =>
      'Behörden veröffentlichen Warnungen, keine Entwarnungen. Dass keine vorliegt, heißt nicht, dass nichts ist.';

  @override
  String statusSituationActive(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Warnungen',
      one: 'Eine Warnung',
    );
    return '$_temp0 für euren Bereich';
  }

  @override
  String get searchTitle => 'Suchen';

  @override
  String get searchHint => 'Bildschirm, Vorrat, Checklistenpunkt …';

  @override
  String get searchStartHint =>
      'Tippe, um die ganze App zu durchsuchen: Bildschirme, Vorräte, Checklistenpunkte und den Hausrat.';

  @override
  String searchNothingFound(String query) {
    return 'Nichts gefunden für „$query“.';
  }

  @override
  String get searchAction => 'Suchen';

  @override
  String get searchGroupScreens => 'Bildschirme';

  @override
  String get searchGroupInventory => 'Vorrat';

  @override
  String get searchGroupChecklists => 'Checklisten';

  @override
  String get searchGroupPossessions => 'Hausrat';

  @override
  String get settingsVersionInfoFirstAid => 'Erste-Hilfe-Inhalte';

  @override
  String get settingsVersionInfoFirstAidValue =>
      'Quellenstand ERC 2025 (GRC-Fassung)';

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
  String get emergencyPlanPdfCards => 'Notfallkarten';

  @override
  String get emergencyPlanPdfCardsWarning =>
      'Auf diesem Blatt stehen Gesundheitsdaten: Blutgruppe, Allergien, Medikation und Vorerkrankungen. Wer es in die Hand bekommt, kann sie lesen, und ein Blatt Papier schützt kein Kennwort. Bewahre es bei den Dokumenten auf, nimm es mit statt es liegen zu lassen, und schreddere es statt es wegzuwerfen.';

  @override
  String get emergencyPlanCardsAskTitle => 'Notfallkarten mitdrucken?';

  @override
  String emergencyPlanCardsAskBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Personen',
      one: 'einer Person',
    );
    return 'Auf Papier funktionieren die Karten, wenn das Telefon leer oder weg ist — genau dafür sind sie da. Es heißt aber auch: ein loses Blatt mit Blutgruppe, Allergien, Medikation und Vorerkrankungen von $_temp0. Was auf Papier steht, lässt sich nicht zurückziehen, nicht aus der Ferne löschen und nicht mit einem Kennwort schützen.';
  }

  @override
  String get emergencyPlanCardsAskWithout => 'Nur den Plan';

  @override
  String get emergencyPlanCardsAskWith => 'Mit Notfallkarten';

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

  @override
  String get settingsRegionUnknownKey => 'Unbekannter Schlüssel — bitte prüfen';

  @override
  String get settingsRegionKeyInvalid =>
      'Bitte fünf oder zwölf Ziffern eingeben (z. B. 03101).';

  @override
  String get shelterOverpassBusyMessage =>
      'OpenStreetMap/Overpass ist gerade ausgelastet (Anfragelimit). In einigen Sekunden erneut versuchen.';

  @override
  String shelterSourceFailureReason(String reason) {
    return 'Grund: $reason';
  }

  @override
  String shelterCachedAt(Object date, Object time) {
    return 'Zwischengespeicherte Schutzraumdaten vom $date, $time. Sie werden angezeigt, weil mindestens eine Quelle gerade nicht erreichbar ist.';
  }

  @override
  String get appLockTitle => 'App-Sperre';

  @override
  String get appLockDisabledHint =>
      'Schützt die App nach dem Verlassen mit einer eigenen Passphrase.';

  @override
  String get appLockEnabledHint =>
      'Beim Zurückkehren in die App wird die Passphrase verlangt.';

  @override
  String get appLockSetTitle => 'App-Sperre einrichten';

  @override
  String get appLockDisableTitle => 'App-Sperre ausschalten';

  @override
  String get appLockDialogHint =>
      'Die Passphrase wird nicht gespeichert. Sie schützt den Zugriff auf die geöffnete App.';

  @override
  String get appLockPassphraseLabel => 'Passphrase';

  @override
  String get appLockConfirmLabel => 'Passphrase wiederholen';

  @override
  String get appLockPassphraseTooShort =>
      'Die Passphrase muss mindestens 12 Zeichen haben.';

  @override
  String get appLockPassphraseMismatch =>
      'Die Passphrasen stimmen nicht überein.';

  @override
  String get appLockEnableButton => 'Sperre einschalten';

  @override
  String get appLockDisableButton => 'Sperre ausschalten';

  @override
  String get appLockUnlockTitle => 'PreppSuite entsperren';

  @override
  String get appLockUnlockButton => 'Entsperren';

  @override
  String get appLockIncorrectPassphrase => 'Die Passphrase ist nicht korrekt.';

  @override
  String get appLockEnabled => 'Die App-Sperre ist aktiv.';

  @override
  String get appLockDisabled => 'Die App-Sperre ist ausgeschaltet.';

  @override
  String get appLockStatusUnavailableTitle => 'Sperrstatus nicht verfügbar';

  @override
  String get appLockStatusUnavailableBody =>
      'Der Sperrstatus kann gerade nicht sicher gelesen werden. Die App bleibt geschlossen, bis der Status wieder verfügbar ist.';

  @override
  String get appLockSettingsUnavailable =>
      'Der Sperrstatus kann gerade nicht sicher gelesen werden.';

  @override
  String get appLockRetry => 'Erneut versuchen';

  @override
  String get kiwixLanguageSearchHint => 'Sprache suchen';

  @override
  String kiwixLanguageCount(int count) {
    return '$count Sprachen';
  }

  @override
  String get kiwixLanguageNoMatch => 'Keine Sprache gefunden.';

  @override
  String kiwixLanguageArchives(int count) {
    return '$count Archive';
  }

  @override
  String downloadRemainingHours(int hours, int minutes) {
    return 'noch $hours h $minutes min';
  }

  @override
  String downloadRemainingMinutes(int minutes) {
    return 'noch $minutes min';
  }

  @override
  String downloadRemainingSeconds(int seconds) {
    return 'noch $seconds s';
  }

  @override
  String get articleLoadFailed => 'Die Seite konnte nicht geladen werden.';

  @override
  String articleHttpStatus(String status) {
    return 'Das Archiv antwortete mit $status.';
  }

  @override
  String get articleReload => 'Erneut laden';

  @override
  String get knowledgeArchiveNoCover => 'Kein Titelbild im Archiv';

  @override
  String get radiationTitle => 'Gammastrahlung';

  @override
  String get radiationEntryHint =>
      'Ortsdosisleistung an einer Messstelle des BfS';

  @override
  String get radiationNoneChosen => 'Noch keine Messstelle gewählt';

  @override
  String get radiationChoose => 'Messstelle wählen';

  @override
  String get radiationChange => 'Andere Messstelle';

  @override
  String get radiationRefresh => 'Aktualisieren';

  @override
  String get radiationSearchHint => 'Ort oder Postleitzahl';

  @override
  String get radiationSearchEmpty => 'Keine Messstelle gefunden.';

  @override
  String get radiationLoadFailed =>
      'Die Messwerte konnten nicht geladen werden.';

  @override
  String get radiationOffline =>
      'Letzter bekannter Wert. Die Verbindung zum BfS kam nicht zustande.';

  @override
  String get radiationStale =>
      'Älter als zwei Stunden. Das Netz meldet stündlich, hier fehlt also die Verbindung und nicht der Messwert.';

  @override
  String get radiationUnvalidated =>
      'Ungeprüfter Rohwert. Das BfS veröffentlicht Stundenwerte zunächst ungeprüft; technische Störungen sehen darin wie Messwerte aus.';

  @override
  String radiationMeasuredAt(String time) {
    return 'Gemessen bis $time';
  }

  @override
  String radiationHeight(String metres) {
    return '$metres m über dem Meer';
  }

  @override
  String radiationPostalCode(String code) {
    return 'PLZ $code';
  }

  @override
  String radiationBaseline(String value) {
    return 'Üblich an dieser Messstelle: $value µSv/h';
  }

  @override
  String radiationNoBaseline(String floor, String ceiling) {
    return 'Für diese Messstelle liegt noch kein eigener Vergleichswert vor. Eingeordnet wird darum gegen den bundesweiten natürlichen Bereich von $floor bis $ceiling µSv/h, was gröber ist — im Schwarzwald sind 0,16 µSv/h völlig gewöhnlich.';
  }

  @override
  String radiationSplit(String terrestrial, String cosmic) {
    return 'Davon $terrestrial µSv/h aus dem Boden und $cosmic µSv/h aus dem Weltall';
  }

  @override
  String get radiationBandOrdinary => 'Gewöhnlich für diese Messstelle';

  @override
  String get radiationBandWeather =>
      'Erhöht — das ist nach Regen der Normalfall';

  @override
  String get radiationBandUnusual => 'Über dem, was Wetter erklärt';

  @override
  String get radiationBandUnknown =>
      'Über dem natürlichen Bereich, ohne eigenen Vergleichswert';

  @override
  String get radiationWeatherExplained =>
      'Regen wäscht Radon-Zerfallsprodukte aus der Luft und hebt den Wert für wenige Stunden um bis zum Dreifachen. Das ist harmlos und geht von selbst zurück; die Halbwertszeit liegt bei etwa 30 Minuten. Frischer Schnee wirkt genauso, liegender Schnee schirmt den Boden ab und senkt den Wert.';

  @override
  String get radiationUnusualExplained =>
      'Laut BfS kommt ein radiologisches Ereignis erst in Frage, wenn ein deutlich erhöhter Wert einen Tag oder länger anhält oder über das Dreifache hinausgeht — oder wenn die Sonde technisch stört. Ein einzelner Wert ist keine Warnung: eine amtliche Warnung käme über die Warnungen dieser App.';

  @override
  String get radiationNoWarning =>
      'Das ist der Messwert und seine Einordnung, keine Warnung. Amtliche Warnungen kommen über die Warnungen dieser App.';

  @override
  String get radiationSource =>
      'Quelle: Bundesamt für Strahlenschutz (BfS), ODL-Messnetz. Datenlizenz Deutschland – Namensnennung 2.0.';

  @override
  String get fireDangerTitle => 'Waldbrandgefahr';

  @override
  String get fireDangerEntryHint =>
      'Waldbrandgefahrenindex des DWD für eine Station';

  @override
  String get fireDangerNoneChosen => 'Noch keine Station gewählt';

  @override
  String get fireDangerChoose => 'Station wählen';

  @override
  String get fireDangerChange => 'Andere Station';

  @override
  String get fireDangerRefresh => 'Aktualisieren';

  @override
  String get fireDangerSearchHint => 'Ort oder Bundesland';

  @override
  String get fireDangerSearchEmpty => 'Keine Station gefunden.';

  @override
  String get fireDangerLoadFailed =>
      'Der Waldbrandgefahrenindex konnte nicht geladen werden.';

  @override
  String get fireDangerOffline =>
      'Letzter bekannter Stand. Die Verbindung zum DWD kam nicht zustande.';

  @override
  String fireDangerStale(String date) {
    return 'Dieser Stand ist vom $date und nicht von heute. Der DWD gibt den Index nur in der Waldbrandsaison heraus, etwa März bis Oktober — außerhalb kommt nichts Neues nach.';
  }

  @override
  String fireDangerStep(int step) {
    return 'Stufe $step von 5';
  }

  @override
  String fireDangerIssuedFor(String date) {
    return 'Gilt für $date';
  }

  @override
  String get fireDangerLevel1 => 'Sehr geringe Gefahr';

  @override
  String get fireDangerLevel2 => 'Geringe Gefahr';

  @override
  String get fireDangerLevel3 => 'Mittlere Gefahr';

  @override
  String get fireDangerLevel4 => 'Hohe Gefahr';

  @override
  String get fireDangerLevel5 => 'Sehr hohe Gefahr';

  @override
  String get fireDangerAhead => 'Die nächsten Tage';

  @override
  String fireDangerPeak(int step, int days) {
    return 'Steigt auf Stufe $step in $days Tagen';
  }

  @override
  String fireDangerPeakTomorrow(int step) {
    return 'Steigt morgen auf Stufe $step';
  }

  @override
  String get fireDangerToday => 'Heute';

  @override
  String fireDangerInDays(int days) {
    return 'In $days Tagen';
  }

  @override
  String get fireDangerTomorrow => 'Morgen';

  @override
  String get fireDangerNoWarning =>
      'Der Index beschreibt das Wetterpotenzial für Waldbrand, er ist keine Warnung und kein Betretungsverbot. Verbote sprechen die Länder aus; amtliche Warnungen kommen über die Warnungen dieser App.';

  @override
  String get fireDangerSource =>
      'Quelle: Deutscher Wetterdienst (DWD), Waldbrandgefahrenindex WBI.';

  @override
  String fireDangerState(String state) {
    return 'Bundesland $state';
  }

  @override
  String get nearbyTitle => 'In der Nähe';

  @override
  String get nearbyEntryHint =>
      'Apotheke, Wasser, Tankstelle – aus der heruntergeladenen Karte, ohne Netz.';

  @override
  String nearbySearchFrom(String place) {
    return 'Suche um $place';
  }

  @override
  String get nearbyMapCentre => 'Kartenmitte';

  @override
  String get nearbyMyPosition => 'deinen Standort';

  @override
  String get nearbyUseMyLocation => 'Meinen Standort verwenden';

  @override
  String get nearbyNoCentre => 'Noch kein Punkt gewählt';

  @override
  String get nearbyNoCentreWhy =>
      'Diese Suche braucht einen Ausgangspunkt. Nimm deinen Standort – oder öffne die Karte, schiebe sie auf die Gegend und starte die Suche von dort.';

  @override
  String get nearbyOpenMap => 'Karte öffnen';

  @override
  String get nearbyRadius => 'Umkreis';

  @override
  String nearbyRadiusKm(int km) {
    return '$km km';
  }

  @override
  String nearbySearching(int done, int total) {
    return '$done von $total Kacheln gelesen';
  }

  @override
  String get nearbyNothingFound => 'Nichts gefunden.';

  @override
  String get nearbyNothingFoundWhy =>
      'In diesem Umkreis führt die Karte keinen dieser Punkte. Ein größerer Umkreis kann helfen – oder die Gegend wurde nur grob heruntergeladen.';

  @override
  String get nearbyNoArchive => 'Keine Karte heruntergeladen';

  @override
  String get nearbyNoArchiveWhy =>
      'Diese Suche liest die Karte, die auf diesem Gerät liegt. Ohne heruntergeladene Karte gibt es nichts zu durchsuchen.';

  @override
  String get nearbyDownloadMap => 'Karte herunterladen';

  @override
  String get nearbyTooShallow => 'Die Karte reicht nicht tief genug';

  @override
  String get nearbyTooShallowWhy =>
      'Einzelne Punkte stehen erst ab Zoomstufe 14 in der Karte. Dieses Archiv hört vorher auf: Es zeichnet eine gute Karte und enthält keine einzige Apotheke. Lade die Gegend noch einmal mit größerer Detailstufe.';

  @override
  String get nearbyOutsideArchive => 'Außerhalb der heruntergeladenen Gegend';

  @override
  String get nearbyOutsideArchiveWhy =>
      'Dieser Punkt liegt nicht in dem Bereich, der heruntergeladen wurde. Die Karte weiß hier nichts – auch nicht, dass etwas fehlt.';

  @override
  String get nearbyCaveats =>
      'Gefunden wird nur, was heruntergeladen wurde und was in OpenStreetMap eingetragen ist. Dass ein Punkt auf der Karte steht, heißt nicht, dass dort geöffnet, geliefert oder besetzt ist.';

  @override
  String get nearbyShelterNote =>
      '„Unterstand“ steht in OpenStreetMap fast immer für ein Buswartehäuschen oder eine Schutzhütte – nicht für einen Schutzraum. Deshalb ist diese Art hier nicht aufgeführt.';

  @override
  String get nearbyKindWater => 'Wasser';

  @override
  String get nearbyKindHealth => 'Gesundheit';

  @override
  String get nearbyKindFood => 'Lebensmittel';

  @override
  String get nearbyKindFuel => 'Kraftstoff und Strom';

  @override
  String get nearbyKindHardware => 'Werkzeug und Baustoff';

  @override
  String get nearbyKindHelp => 'Hilfe und Behörde';

  @override
  String get poiDrinkingWater => 'Trinkwasser';

  @override
  String get poiPharmacy => 'Apotheke';

  @override
  String get poiHospital => 'Krankenhaus';

  @override
  String get poiClinic => 'Klinik';

  @override
  String get poiDoctors => 'Arztpraxis';

  @override
  String get poiSupermarket => 'Supermarkt';

  @override
  String get poiConvenience => 'Kiosk';

  @override
  String get poiBakery => 'Bäckerei';

  @override
  String get poiButcher => 'Metzgerei';

  @override
  String get poiGreengrocer => 'Obst und Gemüse';

  @override
  String get poiMarketplace => 'Marktplatz';

  @override
  String get poiDeli => 'Feinkost';

  @override
  String get poiFuel => 'Tankstelle';

  @override
  String get poiChargingStation => 'Ladesäule';

  @override
  String get poiDoityourself => 'Baumarkt';

  @override
  String get poiHardware => 'Eisenwarenhandel';

  @override
  String get poiFireStation => 'Feuerwehr';

  @override
  String get poiPolice => 'Polizei';

  @override
  String get poiTownhall => 'Rathaus';

  @override
  String get poiCommunityCentre => 'Gemeindezentrum';

  @override
  String get daylightTitle => 'Tageslicht und Mond';

  @override
  String get daylightEntryHint =>
      'Sonne, Dämmerung und Mond – auf dem Gerät gerechnet, ohne Netz.';

  @override
  String get daylightNoPlace => 'Noch kein Ort gesetzt';

  @override
  String get daylightNoPlaceWhy =>
      'Sonnenstand und Mond hängen davon ab, wo du stehst. Setze den Ort einmal – er bleibt gespeichert und wird danach nie wieder gebraucht.';

  @override
  String get daylightSetPlace => 'Ort setzen';

  @override
  String get daylightChangePlace => 'Ort ändern';

  @override
  String get daylightCoordinates => 'Koordinaten';

  @override
  String get daylightCoordinatesHint => '52.2689, 10.5268';

  @override
  String get daylightCoordinatesBad =>
      'Zwei Zahlen, Breite und Länge – zum Beispiel 52.2689, 10.5268.';

  @override
  String get daylightPlaceName => 'Name (frei)';

  @override
  String get daylightToday => 'Heute';

  @override
  String get daylightTomorrow => 'Morgen';

  @override
  String get daylightSunrise => 'Sonnenaufgang';

  @override
  String get daylightSunset => 'Sonnenuntergang';

  @override
  String get daylightSolarNoon => 'Höchststand';

  @override
  String get daylightCivilDawn => 'Erste Helligkeit';

  @override
  String get daylightCivilDusk => 'Letzte Helligkeit';

  @override
  String get daylightNauticalDawn => 'Dämmerungsbeginn';

  @override
  String get daylightNauticalDusk => 'Dämmerungsende';

  @override
  String daylightDayLength(String duration) {
    return 'Tageslänge $duration';
  }

  @override
  String daylightEveningTwilight(String duration) {
    return 'Danach noch $duration nutzbares Licht';
  }

  @override
  String get daylightAlwaysUp => 'Die Sonne geht heute nicht unter.';

  @override
  String get daylightAlwaysDown => 'Die Sonne geht heute nicht auf.';

  @override
  String get daylightMoon => 'Mond';

  @override
  String get daylightMoonrise => 'Mondaufgang';

  @override
  String get daylightMoonset => 'Monduntergang';

  @override
  String daylightMoonIllumination(int percent) {
    return '$percent % beleuchtet';
  }

  @override
  String get daylightMoonUpAllDay =>
      'Der Mond steht heute durchgehend über dem Horizont.';

  @override
  String get daylightMoonDownAllDay =>
      'Der Mond kommt heute nicht über den Horizont.';

  @override
  String get daylightMoonNoRise =>
      'Heute kein Aufgang – der Mond geht jeden Tag rund 50 Minuten später auf.';

  @override
  String get daylightMoonNoSet => 'Heute kein Untergang.';

  @override
  String get daylightWhy =>
      'Ohne Lichtschalter ist die Sonne der Arbeitstag, und ob der Mond scheint, entscheidet über Bewegung bei Nacht. Beides sind Fragen mit genauen Antworten – und beide lassen sich ohne Netz nicht mehr nachschlagen, wenn die Antwort nicht schon im Gerät steht.';

  @override
  String get daylightAccuracy =>
      'Alles hier wird auf dem Gerät gerechnet, nichts abgefragt. Geprüft gegen die Tabellen der US Naval Observatory: Sonne und Mond liegen bei 112 verglichenen Zeiten höchstens eine Minute daneben. Die Zeiten gelten für freie Sicht zum Horizont – Berge, Wald und Häuser verschieben sie.';

  @override
  String get moonPhaseNew => 'Neumond';

  @override
  String get moonPhaseWaxingCrescent => 'Zunehmende Sichel';

  @override
  String get moonPhaseFirstQuarter => 'Erstes Viertel';

  @override
  String get moonPhaseWaxingGibbous => 'Zunehmender Dreiviertelmond';

  @override
  String get moonPhaseFull => 'Vollmond';

  @override
  String get moonPhaseWaningGibbous => 'Abnehmender Dreiviertelmond';

  @override
  String get moonPhaseLastQuarter => 'Letztes Viertel';

  @override
  String get moonPhaseWaningCrescent => 'Abnehmende Sichel';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get radioEverydayTitle => 'Jedermannfunk: PMR446 und Freenet';

  @override
  String get radioEverydayIntro =>
      'Die beiden Bänder, die viele Haushalte tatsächlich im Schrank haben. Sie brauchen keine Anmeldung und keine Prüfung – und keine Infrastruktur: Gerät zu Gerät, ein bis wenige Kilometer. Genau deshalb stehen sie hier neben CB- und Amateurfunk.';

  @override
  String get radioPmrTitle => 'PMR446';

  @override
  String get radioPmrRange => '446,0–446,2 MHz';

  @override
  String get radioPmrChannels => '16 Kanäle analog, Raster 12,5 kHz';

  @override
  String get radioPmrPower => 'Höchstens 0,5 W ERP';

  @override
  String get radioPmrAntenna => 'Nur fest eingebaute Antennen';

  @override
  String get radioPmrPeerToPeer =>
      'Nur direkt von Gerät zu Gerät. Keine ortsfeste Station, kein Repeater, keine Einbindung in ein Netz.';

  @override
  String get radioPmrSource =>
      'Bundesnetzagentur, Vfg. 91/2025 (Sammelzuteilung für Geräte geringer Reichweite), Band 83. Löst die Vfg. 46/2020 ab, befristet bis 31.12.2035. Die Kanalaufteilung selbst steht in der harmonisierten Norm, nicht in der Verfügung.';

  @override
  String get radioFreenetTitle => 'Freenet Deutschland';

  @override
  String get radioFreenetRange => '149,01875–149,11875 MHz';

  @override
  String get radioFreenetAnalogue =>
      '6 Kanäle mit 12,5 kHz, analog oder digital';

  @override
  String get radioFreenetDigital =>
      'Dazu 12 Kanäle mit 6,25 kHz, ausschließlich digital';

  @override
  String get radioFreenetPower =>
      'Höchstens 1 W ERP. Innerhalb von 10 km zur belgischen und polnischen Grenze nur 0,5 W.';

  @override
  String get radioFreenetHandheld =>
      'Nur Handsprechfunkgeräte mit eigener Stromversorgung, in einer Hand bedienbar. Ortsfeste Funkstellen sind nicht zugelassen.';

  @override
  String get radioFreenetAntenna =>
      'Nur die eingebaute Antenne oder eine Wechselantenne am Gerät. Eine Antenne über Koaxialkabel oder an einem Mast ist nicht erlaubt.';

  @override
  String get radioFreenetPeerToPeer =>
      'Nur direkt von Gerät zu Gerät. Kein Repeater, kein Relais, kein Gateway ins Internet.';

  @override
  String get radioFreenetDuration =>
      'Keine Daueraussendungen. Die Norm schaltet nach 180 Sekunden ab; auch darunter gilt: nur so lange senden wie nötig.';

  @override
  String get radioFreenetGermanyOnly =>
      'Diese Zuteilung gilt nur in Deutschland.';

  @override
  String get radioFreenetExtras =>
      'VOX und CTCSS sind ausdrücklich zugelassen.';

  @override
  String get radioFreenetSource =>
      'Bundesnetzagentur, Vfg. 45/2025, korrigiert durch Mitt. 193/2025. Gilt seit 1. Oktober 2025, befristet bis 30. September 2035; löst die Vfg. 60/2019 ab.';

  @override
  String get radioCallingChannelTitle => 'Es gibt keinen amtlichen Anrufkanal';

  @override
  String get radioCallingChannelNone =>
      'Weder für PMR446 noch für Freenet ist ein Not- oder Anrufkanal behördlich festgelegt. Was es gibt, sind Absprachen unter Funkern – und die sind nicht einheitlich.';

  @override
  String get radioCallingChannelThree =>
      'Am weitesten verbreitet ist die private Initiative „Kanal 3“: PMR446 446,03125 MHz, Freenet 149,0500 MHz, CB-Funk 26,985 MHz. Eine Zahl für alle drei Bänder. Daneben wird mancherorts Kanal 1 verwendet.';

  @override
  String get radioCallingChannelNoListener =>
      'Verlass dich nicht darauf, dass jemand mithört. Niemand ist verpflichtet, einen dieser Kanäle zu überwachen.';

  @override
  String get energyTitle => 'Energie und Brennstoff';

  @override
  String get energyEntryHint =>
      'Wie lange Strom, Gas, Brennstoff und Licht reichen.';

  @override
  String get energyIntro =>
      'Die App rechnet aus, wie lange Essen und Wasser reichen. Das hier ist dieselbe Rechnung für das, womit gekocht, geheizt und geleuchtet wird.';

  @override
  String get energyNothingYet => 'Noch nichts eingetragen';

  @override
  String get energyNothingYetWhy =>
      'Trage ein, was du hast – und was es verbraucht. Beide Zahlen stehen auf dem Gerät und auf der Packung: „160 g/h“ auf dem Kocher, „230 g“ auf der Kartusche. Geschätzt wird hier nichts.';

  @override
  String get energyReserves => 'Vorrat';

  @override
  String get energyDraws => 'Verbraucher';

  @override
  String get energyAddReserve => 'Vorrat hinzufügen';

  @override
  String get energyAddDraw => 'Verbraucher hinzufügen';

  @override
  String get energyEditReserve => 'Vorrat ändern';

  @override
  String get energyEditDraw => 'Verbraucher ändern';

  @override
  String get energyDelete => 'Löschen';

  @override
  String get energyLabel => 'Bezeichnung';

  @override
  String get energyKind => 'Art';

  @override
  String get energyAmount => 'Menge';

  @override
  String get energyPerHour => 'Verbrauch je Stunde';

  @override
  String get energyHoursPerDay => 'Stunden am Tag';

  @override
  String get energyNumberNeeded => 'Eine Zahl größer als null.';

  @override
  String get energyLabelNeeded =>
      'Eine Bezeichnung, damit die Zeile später noch etwas sagt.';

  @override
  String energyDays(int days) {
    return '$days Tage';
  }

  @override
  String get energyOneDay => '1 Tag';

  @override
  String get energyZeroDays => 'Reicht keinen Tag';

  @override
  String energyPerDayIs(String amount, String unit, String stored) {
    return '$amount $unit am Tag von $stored $unit';
  }

  @override
  String get energyUnused =>
      'Eingelagert, aber nichts verbraucht es. Trage den Verbraucher ein, sonst rechnet hier nichts.';

  @override
  String get energyEmpty => 'Wird verbraucht, ist aber nicht eingelagert.';

  @override
  String energyShortest(String kind, String days) {
    return 'Zuerst leer: $kind – $days';
  }

  @override
  String get energyShortestWhy =>
      'Das ist die Reichweite des Haushalts. Vier Vorräte mit jeweils beruhigenden Zahlen sind keine vier Antworten – der kleinste zählt.';

  @override
  String get energyNoAnswer =>
      'Noch keine Reichweite: Zu jedem Vorrat gehört ein Verbraucher, sonst gibt es nichts zu teilen.';

  @override
  String get energySources =>
      'Alle Zahlen hier sind deine eigenen. Diese App schätzt keinen Verbrauch – was ein Kocher zieht, steht auf dem Kocher, und was ein Gerät zieht, steht auf dem Netzteil. Gerechnet wird nur.';

  @override
  String get energyKindElectricity => 'Strom';

  @override
  String get energyKindGas => 'Gas';

  @override
  String get energyKindLiquidFuel => 'Flüssiger Brennstoff';

  @override
  String get energyKindSolidFuel => 'Fester Brennstoff';

  @override
  String get energyKindCandles => 'Kerzenlicht';

  @override
  String get energyKindElectricityHint =>
      'Powerbank, Batterien, Solarertrag – in Wattstunden.';

  @override
  String get energyKindGasHint =>
      'Kartuschen und Flaschen – in Gramm, so wie der Kocher seinen Verbrauch angibt.';

  @override
  String get energyKindLiquidFuelHint =>
      'Benzin, Diesel, Petroleum, Lampenöl, Spiritus – in Litern.';

  @override
  String get energyKindSolidFuelHint =>
      'Brennholz, Briketts, Kohle, Pellets – in Kilogramm.';

  @override
  String get energyKindCandlesHint =>
      'In Brennstunden: Stückzahl mal Brenndauer je Stück von der Packung.';

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
  String get energyHelperTitle => 'Umrechnen';

  @override
  String get energyHelperGasBottle =>
      'Gasflasche in Kilogramm? Mal 1000 ergibt Gramm – 5 kg sind 5000 g.';

  @override
  String get energyHelperCandles =>
      'Kerzen? Stückzahl mal Brenndauer je Stück. 40 Teelichter zu 4 Stunden sind 160 Stunden.';

  @override
  String get energyHelperPowerbank =>
      'Powerbank in mAh? Mal 3,7 V, geteilt durch 1000, ergibt Wattstunden: 20000 mAh sind 74 Wh. Achtung – das ist die Zelle, nicht die Steckdose. Beim Hochsetzen auf 5 V geht etwas verloren; wie viel, hängt vom Gerät ab, deshalb steht hier keine Prozentzahl.';

  @override
  String get transferTitle => 'Ohne Netz übertragen';

  @override
  String get transferIntro =>
      'Ein Gerät zeigt eine Folge von Bildern, das andere filmt sie ab. Ohne Netz, ohne gemeinsamen Ordner, ohne Kopplung – die beiden Geräte müssen nur nebeneinander liegen.';

  @override
  String get transferSend => 'Haushalt zeigen';

  @override
  String get transferReceive => 'Haushalt abfilmen';

  @override
  String get transferSendTitle => 'Haushalt zeigen';

  @override
  String get transferSendHint =>
      'Halte die Kamera des anderen Geräts auf den Bildschirm. Die Bilder laufen in einer Schleife – ein verpasstes kommt von allein wieder.';

  @override
  String transferFrameOf(int index, int total) {
    return 'Bild $index von $total';
  }

  @override
  String get transferSendNothing =>
      'Dieser Haushalt enthält noch nichts, was sich übertragen ließe.';

  @override
  String get transferSlower => 'Langsamer';

  @override
  String get transferFaster => 'Schneller';

  @override
  String get transferReceiveTitle => 'Haushalt abfilmen';

  @override
  String get transferReceiveHint =>
      'Auf den Bildschirm des anderen Geräts halten und liegen lassen, bis es voll ist.';

  @override
  String transferProgress(int received, int total) {
    return '$received von $total Bildern';
  }

  @override
  String get transferWaiting => 'Noch kein Bild erkannt.';

  @override
  String transferDone(int rows) {
    return 'Vollständig. $rows Zeilen übernommen.';
  }

  @override
  String get transferNothingNew => 'Vollständig. Alles war schon bekannt.';

  @override
  String get transferBroken =>
      'Die Bilder passen nicht zusammen. Noch einmal abfilmen.';

  @override
  String get transferWrongHousehold =>
      'Das ist ein anderer Haushalt. Übernommen wird nur, was zu diesem hier gehört.';

  @override
  String get transferCameraNeeded =>
      'Für das Abfilmen wird die Kamera gebraucht.';

  @override
  String get transferSendOverNetwork => 'Über das Netz (schnell)';

  @override
  String get transferSendOverNetworkHint =>
      'Beide Geräte hängen im selben Netz – WLAN zu Hause, ein Hotspot, ein Campingplatz. Der Code hier ist der Schlüssel: Nur wer ihn abfilmt, kommt herein. Der ganze Haushalt geht in einem Zug hinüber, in beide Richtungen.';

  @override
  String get transferSendWaiting => 'Warte auf das andere Gerät …';

  @override
  String get transferSendNoNetwork =>
      'Dieses Gerät hängt in keinem Netz. Es bleibt der Weg über die Bilderfolge.';

  @override
  String get transferUseChain => 'Stattdessen ohne Netz zeigen';

  @override
  String get transferUseNetwork => 'Stattdessen über das Netz';

  @override
  String get transferSendChainHint =>
      'Ohne Netz: Halte die Kamera des anderen Geräts auf den Bildschirm. Die Bilder laufen in einer Schleife – ein verpasstes kommt von allein wieder.';

  @override
  String transferHandoverDone(int rows) {
    return 'Abgeglichen. $rows Zeilen übernommen.';
  }

  @override
  String transferHandoverPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Bilder sind mitgekommen.',
      one: 'Ein Bild ist mitgekommen.',
    );
    return '$_temp0';
  }

  @override
  String get transferHandoverNothing =>
      'Abgeglichen. Beide Geräte waren schon auf demselben Stand.';

  @override
  String get transferUnreachable =>
      'Das andere Gerät ist nicht erreichbar. Hängen beide im selben Netz?';

  @override
  String get portableTitle => 'Datenordner';

  @override
  String get portableInstalled => 'Auf diesem Rechner';

  @override
  String get portableInstalledHint =>
      'Haushalt, Vorräte, Fotos und Einstellungen liegen dort, wo dieses Betriebssystem sie für Programme vorsieht.';

  @override
  String get portableCarried => 'Auf einem mitgeführten Datenträger';

  @override
  String portableSourceBeside(String folder) {
    return 'Gefunden als Ordner „$folder“ neben dem Programm.';
  }

  @override
  String get portableSourceChosen => 'Einmal ausgewählt und gemerkt.';

  @override
  String portableSourceEnvironment(String variable) {
    return 'Von der Umgebungsvariable $variable vorgegeben.';
  }

  @override
  String portableExplain(String folder) {
    return 'Lege neben dem Programm einen Ordner namens „$folder“ an, und der nächste Start benutzt ihn. Nichts wird von allein angelegt: Eine installierte Fassung verhält sich genau wie bisher.';
  }

  @override
  String get portableExplainMac =>
      'Unter macOS läuft die App in der Sandbox – absichtlich, denn nur so fragt das System nach einer Aktualisierung nicht erneut nach Ordner-Zugriff. Eine Sandbox darf keinen Ordner neben dem Programm lesen. Deshalb wird der Ordner hier einmal je Mac ausgewählt statt von allein gefunden.';

  @override
  String get portableChoose => 'Ordner auswählen';

  @override
  String get portableForget => 'Wieder auf diesem Rechner';

  @override
  String get portableRestartNeeded => 'Wirkt beim nächsten Start.';

  @override
  String get portableTakeover =>
      'Beim ersten Start mit einem neuen Ordner übernimmt die App einmalig, was auf diesem Rechner liegt – kopiert, nicht verschoben. Die Installation hier bleibt unberührt.';

  @override
  String get portableRelativeNote =>
      'Karten, Archive und Dokumente, die auf demselben Datenträger liegen, werden relativ gemerkt. Sie werden also auch dann wiedergefunden, wenn der Datenträger am nächsten Rechner unter einem anderen Buchstaben erscheint.';

  @override
  String get portableFolderUnusable =>
      'Dieser Ordner lässt sich nicht beschreiben.';

  @override
  String get portableChoiceMissingTitle => 'Der gewählte Datenordner fehlt';

  @override
  String get portableChoiceMissingBody =>
      'Du hast einmal einen Datenordner ausgewählt, er ist gerade nicht erreichbar. Bis er wieder da ist, arbeitet die App mit den Daten auf diesem Rechner – das ist ein anderer Haushalt. Was du jetzt einträgst, liegt nicht im ausgewählten Ordner.';

  @override
  String portableChoiceMissingWhere(String path) {
    return 'Ausgewählt war: $path';
  }

  @override
  String get portableChoiceMissingHint =>
      'Meistens ist der Datenträger nicht angeschlossen. Anschließen und die App neu starten.';

  @override
  String get portableUnsupported =>
      'Ein mitgeführter Datenordner ist nur auf Rechnern möglich, nicht auf Telefonen: Dort bestimmt das System, wo die Daten einer App liegen.';

  @override
  String get articleReaderSimple => 'Einfache Ansicht';

  @override
  String get articleReaderWhy =>
      'Diese Seite wird ohne Browser-Komponente des Systems dargestellt: Text, Überschriften, Listen, Links und Bilder. Skripte, Formelsatz und Feinheiten der Gestaltung fehlen.';

  @override
  String get articleReaderLoading => 'Wird geladen …';

  @override
  String get articleReaderFailed => 'Der Artikel konnte nicht gelesen werden.';

  @override
  String get articleReaderEmpty => 'Diese Seite enthält keinen lesbaren Text.';

  @override
  String get articleReaderImageMissing => 'Bild nicht verfügbar';

  @override
  String get articleReaderExternal =>
      'Führt aus dem Archiv hinaus und wurde nicht geöffnet.';

  @override
  String get articleReaderOpenInBrowser => 'Im Browser öffnen';

  @override
  String get articleViewerChoiceTitle => 'Artikel anzeigen';

  @override
  String get articleViewerChoiceWhy =>
      'Unter Linux und Windows hat diese App keine eingebaute Browser-Komponente zur Verfügung. Der Artikel geht deshalb entweder in ein eigenes Fenster des Systems – oder die App zeichnet ihn selbst.';

  @override
  String get articleViewerChoiceWindow => 'Eigenes Fenster';

  @override
  String get articleViewerChoiceWindowWhy =>
      'Zeigt den Artikel vollständig: Skripte, Formelsatz, das Layout der Seite. Braucht die Browser-Komponente des Systems – unter Linux WebKitGTK, unter Windows die WebView2-Laufzeit.';

  @override
  String get articleViewerChoiceBuiltIn => 'In der App';

  @override
  String get articleViewerChoiceBuiltInWhy =>
      'Braucht gar nichts vom System und bleibt im selben Fenster. Schriftgröße und Farben der App gelten auch im Artikel. Ohne Skripte, ohne Formelsatz, ohne seitliche Infoboxen.';

  @override
  String get articleViewerChoiceFallbackNote =>
      'Fehlt die Komponente des Systems, zeichnet die App den Artikel ohnehin selbst – die Auswahl hier ändert nur, was zuerst versucht wird.';

  @override
  String get outageTitle => 'Stromausfall';

  @override
  String get outageEntryHint =>
      'Wie lange Kühlschrank und Gefriergerät noch halten.';

  @override
  String get outageIntro =>
      'Solange der Strom weg ist, läuft die Kälte ab. Tippe an, wenn es losgeht – die App zählt mit, auch wenn du sie schließt.';

  @override
  String get outageStart => 'Der Strom ist jetzt weg';

  @override
  String get outageEnded => 'Der Strom ist wieder da';

  @override
  String outageRunningSince(String time) {
    return 'Läuft seit $time';
  }

  @override
  String get outageChangeStart => 'Anderer Zeitpunkt';

  @override
  String get outageStoreRefrigerator => 'Kühlschrank';

  @override
  String get outageStoreFreezer => 'Gefriergerät';

  @override
  String outageRemaining(String left) {
    return 'Noch $left';
  }

  @override
  String outageRemainingHours(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String outageRemainingMinutes(int minutes) {
    return '$minutes Min.';
  }

  @override
  String outageUntil(String time) {
    return 'Bis $time';
  }

  @override
  String outageGrace(String left) {
    return 'Abgelaufen – entsorgen in $left';
  }

  @override
  String get outageSpoilt => 'Verderbliches entsorgen';

  @override
  String get outageFreezerFill => 'Gefriergerät';

  @override
  String get outageFreezerFull => 'Gut gefüllt';

  @override
  String get outageFreezerHalf => 'Halb voll oder weniger';

  @override
  String get outageFreezerWhy =>
      'Ein volles Gefriergerät hält etwa 48 Stunden, ein halb volles etwa 24. Die Kälte steckt im Gefriergut selbst, nicht im Gerät.';

  @override
  String get outageRulesTitle => 'Regeln';

  @override
  String get outageRuleClosed =>
      'Tür zu lassen. Jedes Öffnen kostet Stunden, und die Zahlen hier gelten nur bei geschlossener Tür.';

  @override
  String outageRuleTwoHours(int degrees) {
    return 'Was zwei Stunden über $degrees °C lag, kommt weg – Fleisch, Fisch, Eier, Milchprodukte, Gekochtes.';
  }

  @override
  String get outageRuleTaste =>
      'Niemals probieren, um zu entscheiden. Man schmeckt es nicht.';

  @override
  String get outageRuleRefreeze =>
      'Wieder einfrieren ist erlaubt, solange noch Eiskristalle da sind. Die Güte leidet, die Sicherheit nicht.';

  @override
  String get outageRuleGenerator =>
      'Notstromaggregat nur im Freien, mindestens 6 Meter von Fenstern, Türen und angebauter Garage entfernt.';

  @override
  String get outageRuleUnplug =>
      'Geräte vom Netz nehmen: der Strom kommt als Spannungsspitze zurück.';

  @override
  String get outageSource =>
      'Die Stundenangaben stammen von FEMA (ready.gov) und dem US-Landwirtschaftsministerium (FSIS). Eine deutsche Behörde veröffentlicht dazu keine Zahlen – deshalb steht hier, woher sie kommen.';

  @override
  String get dailyDoseLabel => 'Verbrauch am Tag';

  @override
  String get dailyDoseHelper =>
      'In derselben Einheit wie der Bestand: bei 60 Tabletten und 2 am Tag steht hier „2\". Leer lassen, wenn es nicht täglich genommen wird.';

  @override
  String get medicationTitle => 'Medikamente';

  @override
  String get medicationEntryHint => 'Wie lange die Medikamente reichen.';

  @override
  String get medicationIntro =>
      'Dieselbe Rechnung wie bei Vorräten und Brennstoff, nur für die Hausapotheke: Bestand geteilt durch Tagesverbrauch. Beide Zahlen sind deine eigenen – die App schätzt keine Dosis.';

  @override
  String get medicationNothingYet => 'Noch keine Medikamente eingetragen';

  @override
  String get medicationNothingYetWhy =>
      'Trage ein Medikament als Vorrat mit der Kategorie „Medizin“ ein und gib den Tagesverbrauch an. Erst dann lässt sich etwas ausrechnen.';

  @override
  String get medicationNoAnswer =>
      'Zu keinem Medikament ist ein Tagesverbrauch eingetragen – ohne den gibt es nichts zu teilen.';

  @override
  String medicationShortest(String name, String days) {
    return 'Zuerst leer: $name – $days';
  }

  @override
  String get medicationShortestWhy =>
      'Das ist die Reichweite der Hausapotheke. Ein Nachschub braucht Praxis und Apotheke – beides ist im Ernstfall nicht sofort zu haben.';

  @override
  String medicationRunsOut(String date) {
    return 'Aufgebraucht am $date';
  }

  @override
  String medicationDays(int days) {
    return '$days Tage';
  }

  @override
  String get medicationOneDay => '1 Tag';

  @override
  String get medicationZeroDays => 'Reicht keinen Tag';

  @override
  String medicationStock(String quantity, String unit, String dose) {
    return 'Bestand $quantity $unit, $dose am Tag';
  }

  @override
  String get medicationWithoutDoseTitle => 'Ohne Tagesverbrauch';

  @override
  String get medicationWithoutDoseWhy =>
      'Diese stehen im Vorrat, sind aber nicht mitgerechnet. Sie werden hier genannt statt stillschweigend übergangen – sonst läse sich die Zahl oben, als gälte sie für den ganzen Schrank.';

  @override
  String get medicationSource =>
      'FEMA und die US-Gesundheitsbehörde CDC empfehlen beide, einen Vorrat verschreibungspflichtiger Medikamente zu halten und zu wissen, wie lange er reicht. Wie groß der Vorrat sein darf, entscheidet die Praxis – die App rechnet nur, was da ist.';

  @override
  String get possessionsTitle => 'Hausratverzeichnis';

  @override
  String get possessionsEntryHint =>
      'Was der Haushalt besitzt – für die Versicherung.';

  @override
  String get possessionsEmpty => 'Noch nichts eingetragen';

  @override
  String get possessionsWhy =>
      'Nach einem Brand, einem Wasserschaden oder einem Einbruch fragt die Versicherung, was da war. Aus dem Kopf beantwortet das niemand. Diese Liste ist nicht der Vorrat – hier steht, was ersetzt werden müsste.';

  @override
  String get possessionsNoRoom => 'Ohne Raum';

  @override
  String possessionsTotal(String amount) {
    return 'Summe: $amount';
  }

  @override
  String possessionsWithoutPrice(int count) {
    return '$count Einträge ohne Preis sind nicht in der Summe.';
  }

  @override
  String get possessionsExport => 'Als PDF ausgeben';

  @override
  String get possessionsPdfTitle => 'Hausratverzeichnis';

  @override
  String get possessionsKeepElsewhere =>
      'Diese Liste gehört nicht nur in die Wohnung, um die es geht. Ausdrucken und woanders hinlegen, oder an sich selbst mailen. Die Fotos sind nicht in dieser Datei – sie liegen nur auf dem Gerät, das sie aufgenommen hat.';

  @override
  String get possessionAdd => 'Eintrag';

  @override
  String get possessionAddTitle => 'Neuer Eintrag';

  @override
  String get possessionEditTitle => 'Eintrag ändern';

  @override
  String get possessionNameLabel => 'Gegenstand';

  @override
  String get possessionNameNeeded =>
      'Ein Name, sonst sagt die Zeile später nichts.';

  @override
  String get possessionRoomLabel => 'Raum';

  @override
  String get possessionRoomHelper =>
      'Wohnzimmer, Keller, Garage – wie du selbst gehst.';

  @override
  String get possessionSerialLabel => 'Seriennummer';

  @override
  String get possessionSerialHelper =>
      'Das einzige Feld, das sich hinterher nicht mehr rekonstruieren lässt. Steht meist auf der Rückseite oder unter dem Gerät.';

  @override
  String get possessionPriceLabel => 'Kaufpreis';

  @override
  String get possessionCurrencyLabel => 'Währung';

  @override
  String get possessionAcquiredLabel => 'Gekauft am';

  @override
  String get possessionAcquiredNone => 'Kein Datum';

  @override
  String get possessionPhotoTitle => 'Foto';

  @override
  String get possessionPhotoWhy =>
      'Ein Bild überzeugt eine Versicherung mehr als jede Beschreibung. Es bleibt auf diesem Gerät und geht nicht in den geteilten Ordner.';

  @override
  String get possessionPhotoCamera => 'Aufnehmen';

  @override
  String get possessionPhotoGallery => 'Auswählen';

  @override
  String get possessionPhotoRemove => 'Foto entfernen';

  @override
  String get possessionRemoveTitle => 'Eintrag löschen?';

  @override
  String possessionRemoveBody(String name) {
    return '„$name“ wird auf allen Geräten des Haushalts entfernt.';
  }

  @override
  String possessionsCount(int count) {
    return '$count Gegenstände';
  }

  @override
  String get firstAidTitle => 'Erste Hilfe';

  @override
  String get firstAidContentVersionTitle => 'Woher diese Anleitungen stammen';

  @override
  String get firstAidContentVersionBody =>
      'Inhalt nach den Leitlinien 2025 des European Resuscitation Council, deutsche Fassung des German Resuscitation Council. Die Seiten unter „Seelische Not\" folgen den International first aid, resuscitation and education guidelines 2025 der IFRC. Was in einem Erste-Hilfe-Kurs gelehrt wird, stimmen die Hilfsorganisationen gemeinsam ab; im Kurs gilt, was dort gesagt wird.';

  @override
  String get firstAidEntryHint =>
      'Anleitungen, Zeichnungen und ein Taktgeber für die Herzdruckmassage. Ohne Netz, ohne Download.';

  @override
  String get firstAidSearchHint => 'Wonach suchst du?';

  @override
  String get firstAidSearchEmpty => 'Dazu gibt es hier keine Anleitung.';

  @override
  String get firstAidDisclaimer =>
      'Diese Anleitungen ersetzen keinen Erste-Hilfe-Kurs und keinen Notruf. Im Zweifel: 112 anrufen und am Telefon bleiben – die Leitstelle leitet dich an.';

  @override
  String get firstAidGroupBasics => 'Zuerst';

  @override
  String get firstAidGroupLifeThreatening => 'Lebensgefahr';

  @override
  String get firstAidGroupInjury => 'Verletzungen';

  @override
  String get firstAidGroupIllness => 'Plötzliche Erkrankung';

  @override
  String get firstAidGroupEnvironment => 'Kälte, Hitze, Gift';

  @override
  String get firstAidGroupMental => 'Seelische Not';

  @override
  String get firstAidCallNow => 'Notruf 112 wählen';

  @override
  String get firstAidCallFirst => 'Hier wird zuerst angerufen, dann geholfen.';

  @override
  String get firstAidSteps => 'Schritte';

  @override
  String get firstAidReadAloud => 'Schritte vorlesen';

  @override
  String get firstAidStopReading => 'Vorlesen beenden';

  @override
  String get firstAidCautions => 'Nicht tun';

  @override
  String firstAidSource(String source) {
    return 'Quelle: $source';
  }

  @override
  String get firstAidOpenPacer => 'Taktgeber starten';

  @override
  String get firstAidVideos => 'Videos';

  @override
  String get firstAidVideosNone =>
      'Zu dieser Anleitung ist kein Video installiert.';

  @override
  String get firstAidVideoManage => 'Videopaket verwalten';

  @override
  String get firstAidVideoMissing =>
      'Die Videodatei ist nicht mehr da. Lade das Paket noch einmal.';

  @override
  String get firstAidVideoRestart => 'Von vorn';

  @override
  String get firstAidVideoSystemPlayer =>
      'Auf diesem System spielt die App keine Videos selbst ab. Der Knopf unten öffnet die Datei im Abspielprogramm des Rechners.';

  @override
  String get firstAidVideoOpenExternal => 'Mit dem Abspielprogramm öffnen';

  @override
  String get firstAidVideoNotACourse =>
      'Ein Video ist kein Kurs. Die Handgriffe sitzen erst, wenn man sie einmal gemacht hat.';

  @override
  String get firstAidVideoPackTitle => 'Videopaket';

  @override
  String get firstAidVideoPackWhy =>
      'Die Anleitungen brauchen kein Video: Text, Zahlen und Zeichnungen sind vollständig und immer da. Videos sind ein Zusatz für den Abend, an dem man sich die Handgriffe in Ruhe ansieht – und sie sind ein eigener Download, weil zehn Filme mehr wiegen als die ganze App.';

  @override
  String get firstAidVideoPackWhereTitle => 'Woher nehmen?';

  @override
  String get firstAidVideoPackWhereBody =>
      'Fertige Pakete gibt es nicht, und diese App verweist auf keines. Jedes brauchbare deutsche Erste-Hilfe-Video ist urheberrechtlich geschützt – das Material der Hilfsorganisationen vollständig. Frei lizenziert liegt vor allem auf Wikimedia Commons etwas, aber wenig: In „Videos of cardiopulmonary resuscitation\" standen am 22.09.2026 acht Dateien, überwiegend nicht auf Deutsch, eine davon zeigt die Reanimation eines Hundes. Jede Lizenz steht auf der Dateiseite und ist einzeln zu prüfen.';

  @override
  String get firstAidVideoPackWhereHow =>
      'Ein eigenes Paket bauen: siehe docs/erste-hilfe.md im Quelltext. Credit und Lizenz jedes Films stehen später unter dem Video.';

  @override
  String get firstAidVideoPackFromNetwork => 'Über das Netz';

  @override
  String get firstAidVideoPackUrlLabel => 'Adresse der Paketbeschreibung';

  @override
  String get firstAidVideoPackUrlHelper =>
      'Die Adresse einer paket.json. Diese App bringt keine mit – trag die Adresse ein, unter der du dein Paket veröffentlicht hast.';

  @override
  String get firstAidVideoPackFetch => 'Beschreibung abrufen';

  @override
  String get firstAidVideoPackFromFile => 'Aus einer Datei';

  @override
  String get firstAidVideoPackFromFileWhy =>
      'Ein Paket als ZIP, vom Stick oder aus dem gemeinsamen Ordner. Das ist der Weg, der ohne Netz funktioniert – also in der Lage, für die diese App gebaut ist.';

  @override
  String get firstAidVideoPackImport => 'Paketdatei wählen';

  @override
  String get firstAidVideoPackNone => 'Noch kein Videopaket installiert.';

  @override
  String firstAidVideoPackInstalled(int present, int total, String size) {
    return '$present von $total Videos vorhanden, $size auf der Festplatte';
  }

  @override
  String get firstAidVideoPackRemove => 'Videopaket löschen';

  @override
  String get firstAidVideoPackRemoveBody =>
      'Die Videodateien und die Paketbeschreibung werden vom Gerät entfernt. Die Anleitungen selbst bleiben unverändert.';

  @override
  String firstAidVideoPackOffer(int count, String size) {
    return '$count Videos, zusammen $size';
  }

  @override
  String get firstAidVideoPackStart => 'Alle laden';

  @override
  String firstAidVideoPackProgress(int done, int total) {
    return '$done von $total fertig';
  }

  @override
  String firstAidVideoPackDone(int done, int total) {
    return '$done von $total Videos geladen';
  }

  @override
  String get firstAidVideoPackLicenceNote =>
      'Bei jedem Video stehen der Urheber und die Lizenz. Lade nur Pakete, deren Filme weitergegeben werden dürfen.';

  @override
  String get firstAidVideoPackBadUrl => 'Das ist keine vollständige Adresse.';

  @override
  String get firstAidVideoPackClose => 'Schließen';

  @override
  String get pacerTitle => 'Taktgeber';

  @override
  String get pacerStart => 'Start';

  @override
  String get pacerStop => 'Stopp';

  @override
  String get pacerIdle =>
      'Gibt den Takt für die Herzdruckmassage vor – als Ton, als Blinken und, auf dem Telefon, als Vibration. Bildschirm bleibt an, solange er läuft.';

  @override
  String pacerElapsed(String time) {
    return 'Laufzeit $time';
  }

  @override
  String get pacerDepth =>
      '5–6 cm tief · senkrecht von oben · nach jedem Druck vollständig entlasten';

  @override
  String get pacerNoSound =>
      'Auf diesem Gerät kommt kein Ton. Der Takt blinkt weiter.';

  @override
  String pacerPerMinute(int rate) {
    return '$rate/min';
  }

  @override
  String pacerOfCycle(int total, int cycle) {
    return 'von $total · Durchgang $cycle';
  }

  @override
  String get pacerBreathe => 'Jetzt 2× beatmen';

  @override
  String get pacerSwapNow => 'Wechseln, wenn ihr zu zweit seid';

  @override
  String get pacerPushOnly => 'Ohne Unterbrechung drücken';

  @override
  String get pacerPushOnlyShort => 'Nur drücken';

  @override
  String get warningSituationMapTitle => 'Warnlagekarte';

  @override
  String get warningSituationMapEmpty =>
      'Für diese Auswahl liegen keine aktiven Warnungen vor.';

  @override
  String get warningSituationMapNoGeometry =>
      'Zu den aktiven Warnungen sind keine Kartenflächen verfügbar. Die vollständigen Hinweise bleiben in der Warnungsliste offline lesbar.';

  @override
  String get warningSituationMapFailed =>
      'Die gespeicherte Warnlage konnte nicht gelesen werden.';

  @override
  String get warningSituationMapTapHint =>
      'Tippe in die Karte, um zu sehen, was an einer Stelle gilt.';

  @override
  String get warningSituationMapAtPoint => 'An dieser Stelle';

  @override
  String get warningSituationMapNothingHere =>
      'Hier liegt keine der angezeigten Warnflächen.';

  @override
  String get knowledgeApolloPackagesTitle => 'APOLLO-Paketstand';

  @override
  String knowledgeApolloPackageSummary(int installed, int total) {
    return '$installed von $total empfohlenen Quellen verfügbar';
  }

  @override
  String get knowledgeApolloPackageInstalled =>
      'Heruntergeladen und in der Bibliothek registriert';

  @override
  String get knowledgeApolloPackageMissing => 'Noch nicht in der Bibliothek';

  @override
  String get readinessEquipment => 'Ausrüstung und Akkus geprüft';

  @override
  String get readinessEquipmentOff => 'Prüfroutine ist ausgeschaltet';

  @override
  String get readinessEquipmentNotChecked => 'Noch keine Prüfung bestätigt';

  @override
  String get readinessEquipmentDue => 'Prüfung ist fällig';

  @override
  String get readinessEquipmentChecked =>
      'Prüfung innerhalb des gewählten Intervalls bestätigt';

  @override
  String get transferNearbyTitle => 'Geräte im lokalen Netz';

  @override
  String get transferNearbyHint =>
      'Es werden nur zufällige, kurzlebige Bereitschaftssignale gesucht. Wähle ein Gerät und scanne anschließend dessen sichtbaren QR-Code; ohne diesen Code wird nichts übertragen.';

  @override
  String get transferNearbyEmpty =>
      'Noch kein sendebereites PreppSuite-Gerät im gleichen Netz gefunden.';

  @override
  String get transferNearbyUnavailable =>
      'Die Gerätesuche ist auf diesem Netz gerade nicht verfügbar. Du kannst den QR-Code weiterhin direkt scannen.';

  @override
  String get transferNearbyDevice => 'PreppSuite-Gerät bereit';

  @override
  String get transferNearbyScanHint =>
      'Für die sichere Übergabe QR-Code dieses Geräts scannen';

  @override
  String get settingsRegionLabel => 'Bezeichnung (optional)';

  @override
  String get settingsRegionLabelHelper =>
      'Zum Beispiel Zuhause, Arbeit oder Angehörige.';

  @override
  String get knowledgeCheckTitle => 'Wissen prüfen';

  @override
  String get knowledgeCheckIntro =>
      'Erste Hilfe verlernt sich still. Ein paar Fragen zeigen, was noch sitzt — und was nicht.';

  @override
  String knowledgeCheckProgress(int number, int total) {
    return 'Frage $number von $total';
  }

  @override
  String get knowledgeCheckRight => 'Richtig.';

  @override
  String get knowledgeCheckWrong => 'Nicht ganz.';

  @override
  String get knowledgeCheckReadGuide => 'Anleitung lesen';

  @override
  String get knowledgeCheckNext => 'Weiter';

  @override
  String get knowledgeCheckFinish => 'Fertig';

  @override
  String knowledgeCheckResult(int right, int total) {
    return '$right von $total richtig.';
  }

  @override
  String knowledgeCheckHeld(int held, int total) {
    return '$held von $total Fragen sitzen.';
  }

  @override
  String get knowledgeCheckComeBack =>
      'Komm in ein paar Monaten wieder. Nicht morgen — darum geht es hier nicht.';

  @override
  String get knowledgeCheckReview => 'Das würde ich noch einmal nachlesen';

  @override
  String get knowledgeCheckAgain => 'Noch eine Runde';

  @override
  String get mapPlacesImport => 'Orte einlesen';

  @override
  String get mapPlacesExport => 'Orte abgeben';

  @override
  String get mapPlacesExportGpx => 'Als GPX abgeben';

  @override
  String get mapPlacesExportKml => 'Als KML abgeben';

  @override
  String get mapPlacesExportFailed => 'Die Datei liess sich nicht schreiben.';

  @override
  String get mapPlacesImportNothing =>
      'In dieser Datei steht kein Ort, den die App lesen kann.';

  @override
  String mapPlacesImported(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Orte sind dazugekommen.',
      one: 'Ein Ort ist dazugekommen.',
      zero: 'Alle Orte waren schon da.',
    );
    return '$_temp0';
  }

  @override
  String get mapPlacesTitle => 'Meine Orte';

  @override
  String get mapPlacesIntro =>
      'Persönliche Orte erscheinen als Markierungen auf der Karte. Sie bleiben nur auf diesem Gerät.';

  @override
  String get mapPlacesEmpty =>
      'Noch keine persönlichen Orte. Speichere zum Beispiel Treffpunkte, Ausgabestellen oder wichtige Versorgungspunkte.';

  @override
  String get mapPlaceAdd => 'Ort hinzufügen';

  @override
  String get mapPlaceEdit => 'Ort bearbeiten';

  @override
  String get mapPlacePrivacy =>
      'Diese Ortsdaten bleiben lokal auf diesem Gerät und werden nicht mit dem Haushalt geteilt.';

  @override
  String get mapPlaceLabel => 'Bezeichnung';

  @override
  String get mapPlaceLatitude => 'Breitengrad';

  @override
  String get mapPlaceLongitude => 'Längengrad';

  @override
  String get mapPlaceNote => 'Notiz (optional)';

  @override
  String get mapPlaceNoteHint => 'Zum Beispiel Zugang, Material oder Treffzeit';

  @override
  String get mapPlaceCoordinatesInvalid =>
      'Bitte Bezeichnung sowie gültige Koordinaten eingeben.';

  @override
  String mapPlaceDeleteConfirm(Object label) {
    return '„$label“ wirklich entfernen?';
  }

  @override
  String drillsLastCompleted(String date) {
    return 'zuletzt durchgeführt: $date';
  }

  @override
  String get hubTitle => 'Krisenorganisation';

  @override
  String get hubPrivacyNote =>
      'Alle Angaben bleiben auf diesem Gerät. Exportierst du ein Ereignisprotokoll, entscheidest du selbst über den Empfänger.';

  @override
  String get hubNotCheckedYet => 'noch nicht geprüft';

  @override
  String get hubAutonomyTitle => 'Autarkie-Status';

  @override
  String get hubAutonomyHint =>
      'Reichweite in Tagen, aus Bestand und Energieplan gerechnet. Der niedrigste Wert zeigt den nächsten Engpass.';

  @override
  String hubAutonomyIncomplete(String resources) {
    return 'Autarkie noch unvollständig. Offen: $resources.';
  }

  @override
  String hubAutonomyKnownSoFar(int days, String resource) {
    return 'Von dem, was bekannt ist: $days Tage, Engpass $resource.';
  }

  @override
  String hubAutonomyRange(int days, String resource) {
    return '$days Tage autark – Engpass: $resource';
  }

  @override
  String get hubAutonomyOpen => 'offen';

  @override
  String hubAutonomyDays(int days) {
    return '$days Tage';
  }

  @override
  String get hubAutonomyAddByHand => 'Von Hand ergänzen';

  @override
  String get hubAutonomyDialogTitle => 'Autarkie-Reichweite';

  @override
  String get hubAutonomyDialogHint =>
      'Was die App aus Bestand und Energieplan ableiten kann, steht schon auf dem Bildschirm. Hier nur, was sie nicht teilen kann.';

  @override
  String hubAutonomyDaysField(String label) {
    return '$label – Tage';
  }

  @override
  String get hubAutonomyFromStock => 'Aus dem Bestand gerechnet';

  @override
  String hubAutonomyByHandWith(String reason) {
    return 'Selbst eingetragen – $reason';
  }

  @override
  String hubAutonomyNotCounted(int count, String reason) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge nicht mitgerechnet: $reason',
      one: 'Ein Eintrag nicht mitgerechnet: $reason',
    );
    return '$_temp0';
  }

  @override
  String get hubResourceWater => 'Wasser';

  @override
  String get hubResourceFood => 'Lebensmittel';

  @override
  String get hubResourceMedicine => 'Medikamente';

  @override
  String get hubResourceEnergy => 'Energie';

  @override
  String get hubResourceHygiene => 'Hygiene';

  @override
  String get hubGapOnlyByHand => 'zählt die App nicht mit';

  @override
  String get hubGapNoEnergyPlan => 'noch kein Energieplan angelegt';

  @override
  String get hubGapNothingRecorded => 'noch nichts im Bestand erfasst';

  @override
  String get hubGapNoLiters => 'nicht in Litern erfasst';

  @override
  String get hubGapNoCalories => 'ohne Kalorienangabe';

  @override
  String get hubGapNoDose => 'ohne Tagesdosis';

  @override
  String get hubGapNoDraw => 'nichts verbraucht davon';

  @override
  String get hubWaterHygieneTitle => 'Wasser und Hygiene';

  @override
  String get hubWaterHygieneHint =>
      'Trink- und Brauchwasser, Aufbereitung, Kanisterrotation, Toilette und Abfall getrennt planen.';

  @override
  String get hubWaterHygieneLabel => 'Wasser- und Hygieneplan';

  @override
  String get hubWaterHygieneTemplate =>
      'Trinkwasser: …\nBrauchwasser: …\nQuellen und Aufbereitung: …\nKanisterrotation: …\nToilette, Abfall und Reinigungsmittel: …';

  @override
  String get hubPowerOutageTitle => 'Stromausfall-Plan';

  @override
  String get hubPowerOutageHint =>
      'Startzeit, Kühlkette, Ladeprioritäten, Licht, Information und sichere Wärme vorbereiten.';

  @override
  String get hubPowerOutageTemplate =>
      'Startzeit notieren. Kühl- und Gefriergeräte geschlossen halten. Ladeprioritäten, Radio, Licht, sichere Wärme und Ansprechpartner festhalten.';

  @override
  String get hubCookingTitle => 'Vorratsküche';

  @override
  String get hubCookingHint =>
      'Mahlzeiten nach Vorrat, Wasser- und Brennstoffbedarf planen.';

  @override
  String get hubCookingLabel => 'Vorratsküchenplan';

  @override
  String get hubCookingTemplate =>
      'Gericht: …\nZutaten aus dem Vorrat: …\nWasser: …\nBrennstoff und Kochzeit: …\nSichere Kochstelle: …';

  @override
  String get hubCookingRecipes => 'Offline-Rezepte öffnen';

  @override
  String get hubRedundancyTitle => 'Redundanz-Check';

  @override
  String get hubRedundancyHint =>
      'Zweite Wege für Wasser, Licht, Kochen, Information und Kommunikation festhalten.';

  @override
  String get hubRedundancyTemplate =>
      'Wasser: Hauptweg / Ersatzweg\nLicht: Hauptweg / Ersatzweg\nKochen: Hauptweg / Ersatzweg\nInformation und Kommunikation: Hauptweg / Ersatzweg';

  @override
  String get hubClimateRoomTitle => 'Kälte- und Hitze-Schutzraum';

  @override
  String get hubClimateRoomHint =>
      'Geeigneten Aufenthaltsraum, Kleidung, Lüftung und sichere Wärme oder Kühlung vorab bestimmen.';

  @override
  String get hubClimateRoomLabel => 'Schutzraum für Kälte und Hitze';

  @override
  String get hubClimateRoomTemplate =>
      'Raum: …\nWärme/Kühlung: …\nDecken und Kleidung: …\nLüftung: …\nCO-Melder und sichere Geräte: …';

  @override
  String get hubRadioTitle => 'Radio-Empfangsplan';

  @override
  String get hubRadioHint =>
      'Lokale UKW- und DAB-Stationen, Geräte und Stromversorgung festhalten.';

  @override
  String get hubRadioAdd => 'Empfang hinzufügen';

  @override
  String get hubRadioDialogTitle => 'Radio-Empfang hinzufügen';

  @override
  String get hubRadioStation => 'Sender';

  @override
  String get hubRadioBand => 'Band';

  @override
  String get hubRadioFrequency => 'Frequenz oder Kanal';

  @override
  String get hubRadioReceiver => 'Empfänger';

  @override
  String get hubRadioPower => 'Stromversorgung';

  @override
  String hubRadioDetails(
    String band,
    String frequency,
    String receiver,
    String power,
    String checked,
  ) {
    return '$band · $frequency\n$receiver · $power\nGetestet: $checked';
  }

  @override
  String get hubFolderTitle => 'Notfallmappe';

  @override
  String get hubFolderHint =>
      'Dokumentenmappe ohne Inhalte oder Personenangaben verwalten.';

  @override
  String get hubFolderLocation => 'Aufbewahrungsort';

  @override
  String get hubFolderLocationHint => 'z. B. abschließbarer Schrank';

  @override
  String get hubFolderNotSet => 'nicht hinterlegt';

  @override
  String get hubFolderCopies => 'Kopien wichtiger Unterlagen vorhanden';

  @override
  String get hubFolderTakeAlong => 'Bei Evakuierung mitnehmen';

  @override
  String get hubFolderCheckedToday => 'Heute geprüft';

  @override
  String get hubCommunicationTitle => 'Kommunikationsplan';

  @override
  String get hubCommunicationHint =>
      'Kontakt-Reihenfolge, externe Kontaktperson und kurze Statusmeldungen für überlastete Netze.';

  @override
  String get hubCommunicationTemplate =>
      'Wer wird in welcher Reihenfolge kontaktiert? Welche externe Kontaktperson koordiniert?\n\nVorlage: Wir sind sicher. Nächster Kontakt um …';

  @override
  String get hubStatusSafe => 'Wir sind sicher. Nächster Kontakt um …';

  @override
  String get hubStatusHelp => 'Wir brauchen Unterstützung bei … Treffpunkt: …';

  @override
  String get hubSupportTitle => 'Unterstützungsplan';

  @override
  String get hubSupportHint =>
      'Persönliche Unterstützung, Medikamente, Hilfsmittel und Transport bei einer Evakuierung.';

  @override
  String get hubSupportTemplate =>
      'Nur notwendige Angaben: benötigte Hilfe, Medikamente, Hilfsmittel, verlässliche Unterstützung und Transport.';

  @override
  String get hubPetsTitle => 'Haustier-Notfallplan';

  @override
  String get hubPetsHint =>
      'Transport, Futter, Medikamente, Betreuung und Ausweichunterkunft für Tiere vorbereiten.';

  @override
  String get hubPetsTemplate =>
      'Transportbox, Vorräte, Tierarzt, Betreuung, tierfreundliche Unterkunft und Dokumentenkopien.';

  @override
  String get hubMobilityTitle => 'Fahrzeug und Mobilität';

  @override
  String get hubMobilityHint =>
      'Fahrzeug-Notgepäck, Energie- oder Tankreserve, alternative Verkehrsmittel und Abholung.';

  @override
  String get hubMobilityLabel => 'Mobilitätsplan';

  @override
  String get hubMobilityTemplate =>
      'Fahrzeug, Lade- oder Tankziel, Notgepäck, alternative Route, ÖPNV und Abholung.';

  @override
  String get hubUtilitiesTitle => 'Versorgungs-Unterbrechung';

  @override
  String get hubUtilitiesHint =>
      'Absperrorte und manuelle Alternativen für Strom, Wasser, Gas, Heizung und Telekommunikation.';

  @override
  String get hubUtilitiesLabel => 'Versorgungsplan';

  @override
  String get hubUtilitiesTemplate =>
      'Absperrorte, Ansprechpartner, Ersatzstrom, Wasserentnahme, Heizung und kontaktlose Kommunikationswege.';

  @override
  String get hubMaintenanceTitle => 'Wartungszentrale';

  @override
  String get hubMaintenanceHint =>
      'Regelmäßig prüfen, damit wichtige Ausrüstung im Notfall einsatzbereit ist.';

  @override
  String hubMaintenanceLastChecked(String date) {
    return 'Zuletzt geprüft: $date';
  }

  @override
  String get hubEvacuationTitle => 'Evakuierungs-Karten';

  @override
  String get hubEvacuationHint =>
      'Treffpunkte und sichere Wege als offline lesbare Karten notieren.';

  @override
  String get hubEvacuationAdd => 'Karte hinzufügen';

  @override
  String get hubEvacuationRemove => 'Karte entfernen';

  @override
  String get hubEvacuationDialogTitle => 'Evakuierungs-Karte';

  @override
  String get hubEvacuationLabel => 'Bezeichnung, z. B. Zuhause';

  @override
  String get hubEvacuationStart => 'Startpunkt';

  @override
  String get hubEvacuationDestination => 'Treffpunkt oder Ziel';

  @override
  String get hubEvacuationRoute => 'Weg und Alternativen';

  @override
  String get hubEvacuationPlaces => 'Wichtige Orte unterwegs';

  @override
  String get hubEvacuationStartOpen => 'Start offen';

  @override
  String get hubEvacuationDestinationOpen => 'Ziel offen';

  @override
  String hubEvacuationSummary(
    String start,
    String destination,
    String checked,
  ) {
    return '$start → $destination\nGeprüft: $checked';
  }

  @override
  String hubEvacuationStartLine(String value) {
    return 'Start: $value';
  }

  @override
  String hubEvacuationDestinationLine(String value) {
    return 'Ziel: $value';
  }

  @override
  String get hubEvacuationPlacesLine => 'Wichtige Orte';

  @override
  String get hubEventsTitle => 'Ereignisprotokoll';

  @override
  String get hubEventsHint =>
      'Beobachtungen und Maßnahmen mit Uhrzeit dokumentieren und bei Bedarf als PDF exportieren.';

  @override
  String get hubEventsAdd => 'Eintrag hinzufügen';

  @override
  String get hubEventsExport => 'PDF exportieren';

  @override
  String get hubEventsDialogTitle => 'Ereignis dokumentieren';

  @override
  String get hubEventsKind => 'Art';

  @override
  String get hubEventsKindHint => 'Ereignis';

  @override
  String get hubEventsNote => 'Beobachtung oder Schaden';

  @override
  String get hubEventsAction => 'Getroffene Maßnahme';

  @override
  String hubEventsObservationLine(String text) {
    return 'Beobachtung: $text';
  }

  @override
  String hubEventsActionLine(String text) {
    return 'Maßnahme: $text';
  }

  @override
  String get hubEventsPdfTitle => 'PreppSuite – Ereignisprotokoll';

  @override
  String get hubEventsPdfFile => 'preppsuite-ereignisprotokoll.pdf';

  @override
  String get hubActionsTitle => 'Handlungskarten';

  @override
  String get hubActionsHint =>
      'Vorbereitung nach Vorwarnzeit: sofort, innerhalb von 48 Stunden und mehrere Tage vorher.';

  @override
  String get hubActionNowTitle => 'Jetzt';

  @override
  String get hubActionNowBody =>
      'Amtliche Meldung lesen, Gefahr vermeiden, Radio einschalten und Angehörige kurz informieren.';

  @override
  String get hubActionTwoDaysTitle => 'Innerhalb von 24–48 Stunden';

  @override
  String get hubActionTwoDaysBody =>
      'Wasser, Vorrat, Medikamente, Akkus und Fahrzeug prüfen. Haus und Notgepäck vorbereiten.';

  @override
  String get hubActionDaysTitle => 'Mehrere Tage vorher';

  @override
  String get hubActionDaysBody =>
      'Evakuierungs-Karte abgleichen, Unterstützung organisieren, Haustier- und Versorgungsplan prüfen.';

  @override
  String hubActionDone(String date) {
    return 'Erledigt: $date';
  }

  @override
  String get hubCrisisTitle => 'Krisenmodus und Briefing';

  @override
  String get hubCrisisHint =>
      'Größere Darstellung für diese Seite und ein druckbares Briefing für Haushalt oder Notgepäck.';

  @override
  String get hubCrisisSwitch => 'Vereinfachte, größere Darstellung';

  @override
  String get hubCrisisSwitchHint =>
      'Vergrößert Text und Bedienelemente in der Krisenorganisation.';

  @override
  String get hubBriefingButton => 'Notfallbriefing als PDF';

  @override
  String get hubBriefingPdfTitle => 'PreppSuite – Notfallbriefing';

  @override
  String hubBriefingCreated(String date) {
    return 'Erstellt: $date';
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
  String get hubBriefingEvacuation => 'Evakuierung';

  @override
  String hubBriefingEvacuationLine(
    String label,
    String start,
    String destination,
  ) {
    return '$label: $start -> $destination';
  }

  @override
  String get hubBriefingPdfFile => 'preppsuite-notfallbriefing.pdf';

  @override
  String get hubAnalogTitle => 'Analoger Fallback';

  @override
  String get hubAnalogHint =>
      'Ausdrucke, Karten, Notizen und Ersatzschlüssel ohne Akku oder Netz verfügbar halten.';

  @override
  String get hubAnalogTemplate =>
      'Gedruckte Karten, Telefonliste, Anleitungen, Bargeld, Ersatzschlüssel und Aufbewahrungsort.';

  @override
  String get hubMutualAidTitle => 'Nachbarschaftshilfe';

  @override
  String get hubMutualAidHint =>
      'Fähigkeiten, Hilfsmittel und sichere Kontaktwege lokal planen; keine Daten werden veröffentlicht.';

  @override
  String get hubMutualAidLabel => 'Hilfe- und Tauschkarte';

  @override
  String get hubMutualAidTemplate =>
      'Eigene Fähigkeiten und Hilfsmittel, benötigte Unterstützung, vertrauenswürdige Kontakte und Übergabeort.';

  @override
  String get hubPracticeTitle => 'Praxis und Wartung';

  @override
  String get hubPracticeHint =>
      'Regelmäßig Wasserfilter, Kochen, Radio, Notgepäck und analoge Abläufe praktisch üben.';

  @override
  String get hubPracticeLabel => 'Praxis-Wartungsplan';

  @override
  String get hubPracticeTemplate =>
      'Nächste Übung: …\nWasserfilter testen: …\nOhne Strom kochen: …\nRadio und Notgepäck prüfen: …';

  @override
  String get hubNoteEmpty => 'Noch nicht hinterlegt.';

  @override
  String hubNoteUpdated(String date) {
    return 'Zuletzt aktualisiert: $date';
  }

  @override
  String get hubNoteCreate => 'Plan anlegen';

  @override
  String get hubNoteEdit => 'Bearbeiten';

  @override
  String get hubNoteCopyTemplate => 'Vorlage kopieren';

  @override
  String get hubEntryRemove => 'Eintrag entfernen';

  @override
  String get hubClose => 'Schließen';

  @override
  String get hubCancel => 'Abbrechen';

  @override
  String get hubSave => 'Speichern';

  @override
  String hubDateTime(String date, String time) {
    return '$date · $time';
  }

  @override
  String get hubTaskBatteriesTitle => 'Akkus, Batterien und Powerbanks';

  @override
  String get hubTaskBatteriesHint => 'Ladezustand und Ersatzbatterien prüfen';

  @override
  String get hubTaskRadioTitle => 'Radio und Empfangsplan';

  @override
  String get hubTaskRadioHint => 'Sender, Antenne und Stromversorgung testen';

  @override
  String get hubTaskWaterFilterTitle => 'Wasserfilter und Kanister';

  @override
  String get hubTaskWaterFilterHint =>
      'Filterzustand, Dichtungen und Vorrat prüfen';

  @override
  String get hubTaskKitTitle => 'Notgepäck';

  @override
  String get hubTaskKitHint => 'Kleidung, Licht und persönliche Bedarfe prüfen';

  @override
  String get hubTaskMedicineTitle => 'Hausapotheke';

  @override
  String get hubTaskMedicineHint =>
      'Haltbarkeit und persönliche Medikamente prüfen';

  @override
  String get hubTaskExtinguisherTitle => 'Feuerlöscher und Rauchmelder';

  @override
  String get hubTaskExtinguisherHint => 'Prüftermin und Batterien prüfen';

  @override
  String get hubTaskVehicleTitle => 'Fahrzeug und Mobilität';

  @override
  String get hubTaskVehicleHint =>
      'Kraftstoff, Reifen und alternative Wege prüfen';

  @override
  String hubFolderCheckedTodayWith(String date) {
    return 'Heute geprüft · zuletzt $date';
  }

  @override
  String get hubBriefingCommunication => 'Kommunikation';

  @override
  String get hubBriefingSupport => 'Unterstützung';

  @override
  String get hubBriefingPets => 'Haustiere';

  @override
  String get hubBriefingMobility => 'Mobilität';

  @override
  String get hubBriefingUtilities => 'Versorgung';

  @override
  String get hubBriefingPowerOutage => 'Stromausfall';

  @override
  String get hubBriefingRedundancy => 'Redundanz';

  @override
  String get hubBriefingClimate => 'Kälte und Hitze';

  @override
  String get hubRadioPowerExample => 'Batterien';

  @override
  String get hubEventsNoteHint => 'Beobachtung';

  @override
  String hubEventSummary(String when, String text) {
    return '$when\n$text';
  }

  @override
  String get hubSituationTitle => 'Es läuft gerade etwas';

  @override
  String hubSituationOutage(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: 'Stromausfall seit $hours Stunden',
      one: 'Stromausfall seit einer Stunde',
      zero: 'Stromausfall, gerade begonnen',
    );
    return '$_temp0';
  }

  @override
  String hubSituationMoreWarnings(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Und $count weitere Warnungen',
      one: 'Und eine weitere Warnung',
    );
    return '$_temp0';
  }

  @override
  String get hubSituationCrisisMode => 'Größere Darstellung einschalten';

  @override
  String get hubSituationLog => 'Im Protokoll festhalten';

  @override
  String get hubSituationOutageKind => 'Stromausfall';

  @override
  String get hubFolderReportButton => 'Notfallordner als PDF';

  @override
  String get hubFolderReportTitle => 'Notfallordner';

  @override
  String get hubFolderReportIntro =>
      'Zum Ausdrucken und außerhalb der Wohnung aufbewahren: bei Verwandten, im Fahrzeug oder im Notgepäck. Ersetzt keine Originaldokumente.';

  @override
  String get hubFolderReportFile => 'preppsuite-notfallordner.pdf';

  @override
  String get hubFolderReportRoute => 'Weg';

  @override
  String get hubFolderReportPlaces => 'Wichtige Orte';

  @override
  String get hubFolderReportAutonomy => 'Autarkie';

  @override
  String get mapWaterTitle => 'Trinkwasser betroffen';

  @override
  String mapWaterStock(String value) {
    return 'Eigener Trinkwasservorrat: $value';
  }

  @override
  String mapWaterStockUnknown(String reason) {
    return 'Wie weit der eigene Vorrat reicht, ist noch offen: $reason.';
  }

  @override
  String get mapWaterNearby => 'Trinkwasser in der Nähe';

  @override
  String get mapWaterAdviceNote =>
      'Was mit dem Wasser zu tun ist, steht in der Warnung selbst. Diese App gibt dazu keine eigenen Zahlen aus.';

  @override
  String get setupChoiceTitle => 'Haushalt einrichten';

  @override
  String get setupChoiceIntro =>
      'Gibt es diesen Haushalt schon auf einem anderen Gerät? Dann hol ihn dir hierher, statt ihn neu anzulegen — sonst stehen am Ende zwei Haushalte nebeneinander, die sich nie wieder vereinigen.';

  @override
  String get setupChoiceNewTitle => 'Neuen Haushalt anlegen';

  @override
  String get setupChoiceNewBody =>
      'Das erste Gerät. Alles Weitere lässt sich später von hier aus übertragen.';

  @override
  String get setupChoiceFolderTitle => 'Gemeinsamen Ordner wählen';

  @override
  String get setupChoiceFolderBody =>
      'Liegt der Haushalt in einem Ordner, den beide Geräte sehen — iCloud, Nextcloud, ein Stick oder ein Ordner, den eine Sync-App abgleicht —, tritt dieses Gerät ihm bei und bleibt danach von allein auf demselben Stand.';

  @override
  String get setupChoiceScanTitle => 'Von einem anderen Gerät übernehmen';

  @override
  String get setupChoiceScanBody =>
      'Das andere Gerät zeigt einen QR-Code, dieses filmt ihn ab. Über das örtliche Netz geht der ganze Haushalt in einem Zug hinüber; ohne Netz als Bilderfolge.';

  @override
  String get setupChoiceSafeNote =>
      'Jetzt ist der ungefährlichste Zeitpunkt dafür: dieses Gerät hat noch keine eigenen Daten, die dabei umgestempelt werden müssten.';

  @override
  String get setupChoiceRestoreTitle => 'Aus einer Sicherung wiederherstellen';

  @override
  String get setupChoiceRestoreBody =>
      'Eine passwortgeschützte Sicherungsdatei einlesen. Der Haushalt kommt mit seiner bisherigen Kennung zurück.';

  @override
  String setupRestoreDone(int count) {
    return '$count Datensätze wiederhergestellt.';
  }

  @override
  String get setupRestoreFailed =>
      'Diese Datei liess sich nicht lesen. Passwort falsch oder keine PreppSuite-Sicherung.';

  @override
  String get setupRestoreDefaultName => 'Wiederhergestellter Haushalt';

  @override
  String get setupFolderSearching => 'Ordner wird gelesen …';

  @override
  String setupFolderFound(String name) {
    return 'Haushalt gefunden: $name';
  }

  @override
  String get setupFolderFoundBody =>
      'Dieses Gerät tritt ihm bei. Name und Land kommen aus dem Ordner; Region und Personenzahl gehören weiter diesem Gerät.';

  @override
  String get setupFolderEmpty =>
      'In diesem Ordner liegt noch kein Haushalt. Es wird ein neuer angelegt und hineingeschrieben.';

  @override
  String get setupScanHint =>
      'Fülle zuerst aus, was diesem Gerät gehört. Danach filmst du den QR-Code des anderen Geräts ab, und der Haushalt wird übernommen.';

  @override
  String get setupScanContinue => 'Weiter zum Abfilmen';

  @override
  String setupJoinFailed(String reason) {
    return 'Beitreten nicht möglich: $reason';
  }

  @override
  String get setupDoneFolder =>
      'Ordner verbunden. Der Haushalt gleicht sich ab jetzt von allein ab.';

  @override
  String setupDoneScan(int rows) {
    String _temp0 = intl.Intl.pluralLogic(
      rows,
      locale: localeName,
      other: '$rows Einträge sind angekommen.',
      one: 'Ein Eintrag ist angekommen.',
      zero: 'Neues war nichts dabei.',
    );
    return 'Haushalt übernommen. $_temp0';
  }

  @override
  String get setupScanCancelled =>
      'Abgebrochen — es wurde kein Haushalt übernommen.';

  @override
  String setupAdopted(String name) {
    return 'Haushalt „$name“ übernommen.';
  }

  @override
  String get transferAdoptHousehold => 'Haushalt dieses Codes übernehmen';

  @override
  String get transferConflictTitle => 'Zwei verschiedene Haushalte';

  @override
  String transferConflictBody(String mine) {
    return 'Dieses Gerät gehört zu „$mine“, der Code zu einem anderen Haushalt. Was jetzt passiert, lässt sich nicht rückgängig machen: zwei zusammengeführte Datenbestände sind nicht wieder zu trennen.';
  }

  @override
  String get transferConflictMerge => 'Zusammenführen';

  @override
  String transferConflictMergeBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Die $count eigenen Einträge wandern mit in den anderen Haushalt, und dessen Daten kommen hierher. Nichts geht verloren.',
      one:
          'Der eine eigene Eintrag wandert mit in den anderen Haushalt, und dessen Daten kommen hierher. Nichts geht verloren.',
      zero:
          'Dieses Gerät hat nichts einzubringen und übernimmt den anderen Haushalt.',
    );
    return '$_temp0';
  }

  @override
  String get transferConflictReplace => 'Eigene Daten verwerfen';

  @override
  String transferConflictReplaceBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Die $count eigenen Einträge werden gelöscht.',
      one: 'Der eine eigene Eintrag wird gelöscht.',
    );
    return '$_temp0 Danach gilt hier nur noch der andere Haushalt.';
  }

  @override
  String get transferConflictKeep => 'Nichts ändern';

  @override
  String get transferConflictKeepBody =>
      'Nichts wird übernommen. Soll stattdessen das andere Gerät diesem beitreten, zeige dort den Code und filme ihn dort ab.';

  @override
  String get transferConflictCancelled =>
      'Abgebrochen. Es wurde nichts geändert.';

  @override
  String get transferConflictReplaced =>
      'Eigene Daten verworfen, anderer Haushalt übernommen.';

  @override
  String get backupShare => 'Datensicherung teilen';

  @override
  String get backupShareHint =>
      'An eine andere App übergeben — etwa in eine Wolke, die sich im Dateiwähler nicht auswählen lässt. Die Datei ist mit deiner Passphrase verschlüsselt; wer sie ohne die Passphrase bekommt, kann nichts damit anfangen.';

  @override
  String get backupShareSubject => 'PreppSuite-Datensicherung';

  @override
  String get toolsHubTitle => 'Krisenorganisation';

  @override
  String get toolsHubBody =>
      'Radio, Notfallmappe, Wartung, Evakuierungs-Karten und Ereignisprotokoll';

  @override
  String get toolsLearnTitle => 'Kurz lernen';

  @override
  String get toolsLearnBody =>
      'Kurze Offline-Wiederholungen ergänzen Übungen und Wissensarchiv.';

  @override
  String toolsAnswerRight(String explanation) {
    return 'Richtig. $explanation';
  }

  @override
  String toolsAnswerWrong(String explanation) {
    return 'Noch einmal nachsehen: $explanation';
  }

  @override
  String toolsDrillDuration(int minutes) {
    return 'Vorbereitung: $minutes Minuten';
  }

  @override
  String toolsDrillMeta(String duration, String completed) {
    return '$duration · $completed';
  }

  @override
  String get toolsLessonCommunicationTitle => 'Kommunikation';

  @override
  String get toolsLessonCommunicationSummary =>
      'Netze entlasten und Kontakte koordinieren.';

  @override
  String get toolsLessonCommunicationQuestion =>
      'Welcher Weg ist bei überlastetem Mobilfunk meist sinnvoll?';

  @override
  String get toolsLessonCommunicationAnswerA => 'Langer Anruf';

  @override
  String get toolsLessonCommunicationAnswerB =>
      'Kurze Nachricht mit Rückmeldezeit';

  @override
  String get toolsLessonCommunicationAnswerC => 'Fortlaufend neu wählen';

  @override
  String get toolsLessonCommunicationExplanation =>
      'Kurze Nachrichten benötigen weniger Netzkapazität und schonen den Akku.';

  @override
  String get toolsLessonEvacuationTitle => 'Evakuierung';

  @override
  String get toolsLessonEvacuationSummary =>
      'Plan, Notgepäck und Treffpunkt bereithalten.';

  @override
  String get toolsLessonEvacuationQuestion =>
      'Was sollte vor einer Evakuierung geprüft werden?';

  @override
  String get toolsLessonEvacuationAnswerA =>
      'Treffpunkt, Weg und benötigte Unterstützung';

  @override
  String get toolsLessonEvacuationAnswerB => 'Nur die Wetter-App';

  @override
  String get toolsLessonEvacuationAnswerC => 'Nur der Tankstand';

  @override
  String get toolsLessonEvacuationExplanation =>
      'Ein klarer Treffpunkt, der Weg und individuelle Bedarfe verhindern Stress und Fehlentscheidungen.';

  @override
  String get toolsLessonPowerTitle => 'Stromausfall';

  @override
  String get toolsLessonPowerSummary =>
      'Licht, Information und Energie sichern.';

  @override
  String get toolsLessonPowerQuestion =>
      'Wofür dient das batteriebetriebene oder Kurbelradio?';

  @override
  String get toolsLessonPowerAnswerA => 'Als Ersatz für amtliche Warnungen';

  @override
  String get toolsLessonPowerAnswerB => 'Als zusätzlicher Informationskanal';

  @override
  String get toolsLessonPowerAnswerC => 'Nur zum Musikhören';

  @override
  String get toolsLessonPowerExplanation =>
      'Radio ergänzt Systemwarnungen und funktioniert auch bei ausgefallenem Internet.';

  @override
  String get toolsDrillPowerTitle => '72 Stunden ohne Strom';

  @override
  String get toolsDrillPowerStepA => 'Licht, Radio und Powerbank bereitlegen';

  @override
  String get toolsDrillPowerStepB => 'Wasser, Kocher und Vorräte prüfen';

  @override
  String get toolsDrillPowerStepC => 'Kühlgeräte geschlossen halten';

  @override
  String get toolsDrillEvacuationTitle => 'Evakuierung in 15 Minuten';

  @override
  String get toolsDrillEvacuationStepA => 'Dokumente und Medikamente einpacken';

  @override
  String get toolsDrillEvacuationStepB =>
      'Treffpunkt und Weg auf Offlinekarte prüfen';

  @override
  String get toolsDrillEvacuationStepC =>
      'Haushaltsmitglieder und Kontaktweg abgleichen';

  @override
  String get toolsDrillCommunicationTitle => 'Kommunikation ausgefallen';

  @override
  String get toolsDrillCommunicationStepA =>
      'Lokales Radio und Warnungen prüfen';

  @override
  String get toolsDrillCommunicationStepB =>
      'Nahe Kontakte und Treffpunkt bereithalten';

  @override
  String get toolsDrillCommunicationStepC =>
      'Funkgerät nur im erlaubten Funkdienst einsetzen';

  @override
  String get recipeOnlyInGerman => 'Nur auf Deutsch verfügbar';

  @override
  String get recipeOnlyInEnglish => 'Nur auf Englisch verfügbar';

  @override
  String get emergencyMapReady => 'Geöffnet und für die Nutzung bereit';

  @override
  String get emergencyMapMissing => 'Noch kein geprüftes Kartenpaket';

  @override
  String get emergencyKnowledgeReady =>
      'Archiv geöffnet und für die Nutzung bereit';

  @override
  String get emergencyKnowledgeMissing => 'Noch kein geprüftes Wissensarchiv';

  @override
  String get knowledgeNoBookmarks =>
      'Noch keine Lesezeichen. Öffne einen Artikel und tippe auf das Lesezeichen-Symbol.';

  @override
  String get knowledgeInOpenArchive => 'Im geöffneten Archiv';

  @override
  String get knowledgeOpenArchiveFirst =>
      'Archiv zuerst in der Bibliothek öffnen';

  @override
  String get radioCbCallingChannel =>
      'Üblicher Anruf- und Hilfekanal im CB-Funk.';

  @override
  String get radioCbRoadChannel =>
      'Häufig genutzter Straßen- und Fernfahrkanal.';

  @override
  String caloriesPer100Label(String basis) {
    return 'Kalorien je $basis (kcal, optional)';
  }

  @override
  String get unitInfoAction => 'Warum ein Maß?';

  @override
  String get unitInfoTitle => 'Warum g, kg, ml oder l?';

  @override
  String get unitInfoWhy =>
      'Nährwerte stehen auf jeder Packung je 100 g oder je 100 ml. Aus einem Vorrat wird erst dann eine Tagesration, wenn sich die Menge auch in Gramm sagen lässt – und was sechs Dosen wiegen, steht auf der Dose und nicht in dieser App.';

  @override
  String get unitInfoAccepted =>
      'Diese hier mit einem Tipp, ausgeschrieben geht ebenso: Gramm, Kilo, Milliliter, Liter.';

  @override
  String get unitInfoExempt =>
      'Das gilt nur für Lebensmittel und Wasser. Medikamente werden weiter in Tabletten gezählt, sonst stimmt die Reichweite je Tagesdosis nicht mehr; Werkzeug wird in Stück gezählt.';

  @override
  String get unitInfoKept =>
      'Ein Vorrat in „Dose\" oder „Glas\" bleibt stehen, wie er ist. Er zählt nur so lange nicht im Vorrats-Rechner mit, bis die Einheit ein Maß nennt.';

  @override
  String get unitMeasureRequired =>
      'Hier braucht es ein Maß: g, kg, ml oder l.';

  @override
  String nutritionPer100Label(String nutrient, String basis) {
    return '$nutrient je $basis';
  }

  @override
  String get foodWithoutMeasureTitle => 'Nicht mitgerechnet: Einheit ohne Maß';

  @override
  String foodWithoutMeasureBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Lebensmittel werden',
      one: 'Ein Lebensmittel wird',
    );
    String _temp1 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sie zählen',
      one: 'Es zählt',
    );
    return '$_temp0 in einer Einheit gezählt, auf die sich kein Etikett anwenden lässt – etwa „Dose\" oder „Glas\". $_temp1 nicht in den Vorrats-Rechner, bis die Einheit in g, kg, ml oder l steht.';
  }

  @override
  String get transferInterrupted =>
      'Die Verbindung stand, die Übertragung ist aber nicht fertig geworden. Beide Geräte wach lassen und noch einmal versuchen – bei vielen Fotos dauert es etwas.';

  @override
  String transferLastSeen(int frame) {
    return 'Zuletzt gelesen: Bild $frame';
  }

  @override
  String transferLastSeenMixed(int frame, int discarded) {
    return 'Zuletzt gelesen: Bild $frame · $discarded Bilder gehörten zu einer anderen Übertragung';
  }

  @override
  String get operationsTitle => 'Lage jetzt';

  @override
  String get operationsWarning => 'Aktive Warnung für deine Orte';

  @override
  String get operationsQuiet => 'Lage für deine Orte ruhig';

  @override
  String get operationsOpenWarnings => 'Warnungen prüfen';

  @override
  String get operationsOpenReadiness => 'Bereitschaft öffnen';

  @override
  String operationsNextTask(String task) {
    return 'Als Nächstes: $task';
  }

  @override
  String get operationsChargeDue => 'Akkus und Ausrüstung prüfen';

  @override
  String get operationsInventoryMissing => 'Vorrat anlegen';

  @override
  String get operationsReady =>
      'Grundlagen angelegt – Details bei Bedarf prüfen';

  @override
  String get followedPlacesTitle => 'Meine Warnorte';

  @override
  String get followedPlacesIntro =>
      'Warnungen für Zuhause und weitere wichtige Regionen. Bezeichnungen für weitere Orte bleiben auf diesem Gerät.';

  @override
  String get followedPlacesPrimary => 'Hauptort';

  @override
  String get followedPlacesAdditional => 'Weitere Orte';

  @override
  String get followedPlacesOpen => 'Warnorte verwalten';

  @override
  String get householdPlanShareSafety => 'Sicherheitsmeldung teilen';

  @override
  String householdPlanSafetyMessage(String meetingPoint) {
    return 'Wir sind sicher.\\nTreffpunkt: $meetingPoint\\nNächste Rückmeldung: …';
  }

  @override
  String get toolsDrillEquipmentTitle => 'Akkus und Ausrüstung prüfen';

  @override
  String get toolsDrillEquipmentStepA =>
      'Powerbanks, Lampen und Ersatzakkus aufladen und beschriften';

  @override
  String get toolsDrillEquipmentStepB =>
      'Radio, Ladegeräte und Kabel mit einer Steckdose oder Powerbank testen';

  @override
  String get toolsDrillEquipmentStepC =>
      'Fälligkeit für die nächste Prüfung festlegen';

  @override
  String get toolsDrillRadioTitle => 'Funk- und Informationsprobe';

  @override
  String get toolsDrillRadioStepA =>
      'Batterien, Antenne und Empfang am Radio prüfen';

  @override
  String get toolsDrillRadioStepB =>
      'Lokale Sender, Warnkanäle und vereinbarte Frequenzen notieren';

  @override
  String get toolsDrillRadioStepC =>
      'Nur im jeweils erlaubten Funkdienst senden und einen kurzen Empfangstest dokumentieren';

  @override
  String get operationsWarningDetail =>
      'Details, betroffene Gebiete und Handlungsempfehlungen öffnen';

  @override
  String get navGroupNow => 'Jetzt';

  @override
  String get navGroupPrepare => 'Vorsorge';

  @override
  String get navGroupOffline => 'Offline';

  @override
  String get navGroupProfile => 'Profil und Einstellungen';

  @override
  String get emergencyCardCareTitle => 'Unterstützung und Abhängigkeiten';

  @override
  String get emergencyCardCareHint =>
      'Bei Strombedarf, Hilfsmitteln, Betreuung oder Transport: hier kurz und konkret notieren, zum Beispiel „Rollstuhl – Ersatzakku im Flur; Fahrdienst: …“. Diese Angaben sind sensibel.';

  @override
  String get shareFailed => 'Teilen konnte nicht geöffnet werden.';

  @override
  String get householdPlanSafetyHint =>
      'Passe die Nachricht und den Zeitpunkt der nächsten Rückmeldung vor dem Teilen an.';

  @override
  String get hubResilienceTitle => 'Warnwege und Netzwerk';

  @override
  String get hubResilienceHint =>
      'Warnkanäle, persönliche Unterstützung, Quellen, Lernen und Hilfe im Umfeld lokal vorbereiten.';

  @override
  String get resilienceWarningTitle => 'Warnwege prüfen';

  @override
  String get resilienceWarningHint =>
      'Nur als erfolgreich markieren, wenn der Weg auf diesem Gerät oder im Haushalt wirklich getestet wurde.';

  @override
  String get resilienceWarningNina => 'Warn-App NINA eingerichtet und getestet';

  @override
  String get resilienceWarningCell => 'Cell Broadcast am Gerät geprüft';

  @override
  String get resilienceWarningSiren => 'Sirene oder kommunalen Warnweg geklärt';

  @override
  String get resilienceWarningRadio => 'Radio und lokalen Warnsender getestet';

  @override
  String get resilienceSupportTitle => 'Persönliche Unterstützung';

  @override
  String get resilienceSupportHint =>
      'Optionaler Plan für Abhängigkeiten bei Stromausfall oder Evakuierung. Keine medizinische Diagnose speichern.';

  @override
  String get resilienceSupportPower =>
      'Stromabhängige Hilfsmittel und Ersatzenergie geprüft';

  @override
  String get resilienceSupportEvacuation =>
      'Hilfe beim Verlassen der Wohnung geklärt';

  @override
  String get resilienceSupportTransport => 'Transport oder Abholung vereinbart';

  @override
  String get resilienceSupportMedicine => 'Medikamentenplan und Vorrat geprüft';

  @override
  String get resilienceSupportAssistance =>
      'Betreuung, Assistenz oder Tierbedarf geklärt';

  @override
  String get resilienceSupportNote => 'Kurzer persönlicher Plan';

  @override
  String get resilienceSourcesTitle => 'Quellen-Kompass';

  @override
  String get resilienceSourcesHint =>
      'Nur Stellen eintragen, deren Informationen du selbst prüfst. Ergänze stets einen Weg ohne Internet.';

  @override
  String get resilienceSourcesEmpty => 'Noch keine lokale Quelle hinterlegt.';

  @override
  String get resilienceSourceAdd => 'Quelle hinzufügen';

  @override
  String get resilienceSourceLabel => 'Stelle oder Thema';

  @override
  String get resilienceSourceChannel => 'Abrufweg';

  @override
  String get resilienceSourceFallback => 'Offline-Alternative';

  @override
  String get resilienceLearningTitle => 'APOLLO-Lernpfade';

  @override
  String get resilienceLearningHint =>
      'Markiere einen Pfad erst nach dem Herunterladen und einem kurzen Offline-Test.';

  @override
  String get resilienceLearningOpen => 'APOLLO öffnen';

  @override
  String get resilienceLearningMedical => 'Erste Hilfe und Medizin-Grundlagen';

  @override
  String get resilienceLearningWater => 'Wasser, Hygiene und Kochen';

  @override
  String get resilienceLearningRepair => 'Reparatur und Energie';

  @override
  String get resilienceLearningNavigation =>
      'Orientierung, Funk und Kommunikation';

  @override
  String get resilienceLearningSchool => 'Grundlagen und Lernen mit Kindern';

  @override
  String get resilienceNeighborhoodTitle => 'Nachbarschaftshilfe';

  @override
  String get resilienceNeighborhoodHint =>
      'Freiwillige Fähigkeiten und sichere Kontaktwege. Ein Alias genügt; echte Namen sind nicht nötig.';

  @override
  String get resilienceNeighborhoodEmpty =>
      'Noch keine Fähigkeit im Umfeld hinterlegt.';

  @override
  String get resilienceNeighborhoodAdd => 'Fähigkeit hinzufügen';

  @override
  String get resilienceNeighborAlias => 'Alias oder Rolle';

  @override
  String get resilienceNeighborSkill => 'Fähigkeit oder Ausrüstung';

  @override
  String get resilienceNeighborContact => 'Vereinbarter Kontaktweg';

  @override
  String get resilienceNeighborMeeting => 'Treffpunkt';

  @override
  String get resilienceMaintenanceSchedule => 'Prüfrhythmus';

  @override
  String get resilienceMaintenanceOff => 'Nicht geplant';

  @override
  String get resilienceMaintenanceDue => 'Prüfung fällig';

  @override
  String resilienceMaintenanceEveryDays(int days) {
    return 'Alle $days Tage';
  }

  @override
  String get statusSupplyLimitWater => 'Begrenzender Faktor: Trinkwasser.';

  @override
  String get statusSupplyLimitCalories =>
      'Begrenzender Faktor: verfügbare Kalorien.';

  @override
  String get statusSupplyLimitBoth =>
      'Begrenzende Faktoren: Trinkwasser und verfügbare Kalorien.';
}
