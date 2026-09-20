# Gemeinsamer Ordner

So teilen mehrere Geräte einen Haushalt, seit es keinen Server mehr gibt.
Die Regeln unten sind kein Vorschlag, sondern das, worauf sich die
Umsetzung verlässt.

## Die Idee in einem Satz

Jedes Gerät schreibt genau eine Datei und liest alle anderen.

Wer diese Dateien transportiert, entscheidet die Nutzerin: Nextcloud,
Syncthing, iCloud Drive, Dropbox, ein USB-Stick. PreppSuite spricht mit
keinem dieser Dienste, es legt nur Dateien in einen Ordner.

## Was im Ordner liegt

```
<gewählter Ordner>/
  preppsuite/
    household.json          # wem der Ordner gehört
    devices/
      <geräte-id>.json      # ein vollständiger Stand je Gerät
```

`preppsuite/` ist ein eigenes Unterverzeichnis, weil der gewählte Ordner
meist noch für anderes benutzt wird.

### `household.json`

```json
{
  "version": 1,
  "householdId": "…",
  "name": "Familie",
  "countryCode": "DE",
  "createdAt": "2026-09-05T10:00:00.000Z"
}
```

Wird beim Einrichten geschrieben, beim Aktivieren der Verschlüsselung
um die Schlüsselableitung ergänzt und bei jedem Abgleich geprüft.

`name` und `countryCode` sind das Angebot an ein beitretendes Gerät, nicht
eine Vorschrift. Nach dem Beitritt gehört beides wieder dem Gerät selbst —
ebenso wie die eigene Region, die Personenzahl und alle
Benachrichtigungseinstellungen. Geteilt werden Vorräte, Checklisten und
Ausgaben; nicht, wofür sich das einzelne Gerät interessiert.

Fehlt die Datei, schreibt das nächste synchronisierende Gerät sie neu.
Ohne sie würde ein später beitretendes Gerät den Ordner für leer halten und
einen zweiten Haushalt darin anfangen, der sich nie mit dem ersten
vereinigt.

### `devices/<id>.json`

Ein vollständiger Abzug dessen, was dieses Gerät weiß — keine Liste von
Änderungen. Das kostet ein paar hundert Kilobyte pro Gerät und bringt
zwei Dinge, die deutlich mehr wert sind:

- Ein Gerät, das einen Monat aus war, muss nichts nachholen.
- Ein Haushalt, dessen erstes Gerät verloren ist, hat trotzdem noch alles,
  weil jedes andere Gerät die Zeilen die ganze Zeit mit veröffentlicht hat.

## Wie zusammengeführt wird

Jede Zeile trägt eine `clientId` und ein `updatedAt`. Die lokale Datenbank
speichert Sekunden. Jede lokale Änderung erhält mindestens die nächste
Sekunde nach der bisher gespeicherten Version, falls die Geräteuhr noch
keinen neueren Wert liefert. Dadurch bleiben schnelle Folgeänderungen und
Änderungen nach einer Uhrkorrektur unterscheidbar. `updatedAt` ist deshalb
eine logische Version und kein sekundengenaues Änderungsprotokoll.

Beim Zusammenführen gewinnt zunächst die höhere Version. Bei Gleichstand
gewinnt eine Löschung gegen einen lebenden Eintrag, danach entscheidet eine
feste Reihenfolge der geteilten Inhalte. Gleiche Dateien erneut einzulesen
ändert nichts; unterschiedliche Lesereihenfolgen führen zum selben Stand.
Fotos und der lokale Offen-Merker nehmen an dieser Entscheidung nicht teil.

**Alle Geräte müssen dieselbe neue Konfliktregel verwenden.** Das Datei-
und Datenbankformat bleibt unverändert, ältere App-Versionen können aber
bei Gleichständen noch ihren eigenen Wert behalten. Ein Gerät mit stark
vorgehender Uhr kann weiterhin noch unbekannte Änderungen anderer Geräte
überstimmen. Nach einer Übernahme lässt sich die Zeile lokal erneut ändern;
ihre Version steigt dann auch bei zurückgestellter Uhr.

Nach erfolgreichem Schreiben werden nur die tatsächlich übertragenen
Zeilenversionen als veröffentlicht markiert. Änderungen während des
Schreibens bleiben für den nächsten Durchlauf offen. Beim ersten Abgleich
nach dem Update wird der lokale Stand einmal vollständig neu veröffentlicht,
auch wenn ältere Versionen ihn irrtümlich schon als übertragen markiert hatten.

## Was nicht mitreist

- **Fotos zu Vorräten.** Der Pfad zeigt in das Dokumentenverzeichnis eines
  bestimmten Geräts, und das Bild selbst liegt nicht im Ordner. Ein Pfad,
  der drüben ins Leere zeigt, wäre schlechter als gar keiner. Die
  Zusammenführung lässt die lokale Spalte deshalb unberührt.
- **Warnungen.** Ein Zwischenspeicher, den jedes Gerät in Minuten selbst
  wieder füllt.
- **Alles, was das Gerät über sich selbst weiß:** Region, Personenzahl,
  Sprache, Benachrichtigungen.

## Beitreten

Wählt ein Gerät einen Ordner, in dem schon ein Haushalt liegt, übernimmt es
dessen `householdId` — und stempelt seine bereits vorhandenen Zeilen auf
sie um. Ohne das wären sie sofort unsichtbar, denn jede lokale Tabelle ist
nach dieser Kennung partitioniert.

Nennt der Ordner später einen *anderen* Haushalt als den, zu dem das Gerät
gehört, wird gar nichts zusammengeführt. Zwei fremde Datenbestände lassen
sich nicht wieder trennen.

### Beitreten bei der Ersteinrichtung

Seit 1.9.1 wird der Beitritt **vor** dem Anlegen angeboten, nicht erst
danach in den Einstellungen. Der erste Bildschirm fragt, ob dieser
Haushalt schon auf einem anderen Gerät existiert, und bietet drei Wege:
neu anlegen, einem gemeinsamen Ordner beitreten, oder ihn von einem
anderen Gerät abfilmen.

Das ist kein reiner Bequemlichkeitsgewinn. Wer auf dem zweiten Gerät das
alte Formular ausfüllte, legte einen **zweiten** Haushalt mit neuer
Kennung an — und weil jede Tabelle nach dieser Kennung partitioniert ist,
lassen sich die beiden danach nie wieder vereinigen. Der Weg zum Beitritt
war da, aber nur hinter einem bereits falsch angelegten Haushalt.

Umgekehrt ist die Ersteinrichtung der **sicherste** Zeitpunkt dafür.
Beitreten heisst, die fremde Haushalts-Kennung zu übernehmen und jede
eigene Zeile darauf umzustempeln; auf einem Gerät ohne eigene Zeilen ist
daran nichts zu verlieren.

Beim Ordner wird die `household.json` gelesen, **bevor** etwas gefragt
wird: liegt dort ein Haushalt, stehen Name und Land schon im Formular,
statt eingetippt und gleich darauf überschrieben zu werden. Scheitert das
Beitreten danach, wird das eben angelegte Profil wieder verworfen — sonst
liesse das Türchen jemanden in einen Haushalt, der mit nichts verbunden
ist.

Beim QR-Weg kommt das Formular zuerst und die Kamera danach. Andersherum
füllte jemand Felder aus, während im Hintergrund die Einladung des
anderen Geräts abläuft.

## Wann geschrieben wird

Gelesen wird beim Start, beim Zurückkehren in die App und alle zwei
Minuten, solange sie offen ist. Geschrieben wird nur, wenn es etwas zu
sagen gibt: eigene Änderungen, neu Gelerntes zum Weiterreichen, oder eine
fehlende eigene Datei. Jedes Schreiben weckt den Sync-Dienst und damit
jedes andere Gerät — ein stiller Durchlauf ist deshalb wirklich still.

Die Datei wird unter einem Zwischennamen geschrieben und dann umbenannt.
Sonst bekämen die Sync-Dienste, die den Ordner beobachten, halbe Dateien zu
verteilen.

## Was seit 0.12 mitreist

Neben Vorrat, Checklisten und Budget liegen zwei weitere Sätze im Ordner:

- **Der Notfallplan** – ein Datensatz je Haushalt. Seine `clientId` ist die
  Haushalts-Kennung, damit alle Geräte denselben Datensatz bearbeiten statt
  je einen eigenen.
- **Die Notfallkarten** – eine Zeile je Person. Das sind **Gesundheitsdaten**;
  der Bildschirm sagt vor der Eingabe, ob der Ordner verschlüsselt ist.

Seit Schema 14 kommt ein dritter dazu:

- **Das Hausratverzeichnis** – eine Zeile je Gegenstand, mit Raum,
  Seriennummer, Kaufdatum und Preis. Das Foto bleibt auf dem Gerät, das es
  aufgenommen hat, wie bei Vorratsartikeln auch.

Eine Datei, die vor Schema 14 geschrieben wurde, hat diesen Satz gar nicht.
Sie bleibt lesbar: ein fehlender Schlüssel wird als leere Liste gelesen,
nicht als Fehler. Ein Gerät auf einer älteren Fassung hält den Ordner
deshalb nicht auf.

## Verschlüsselung

Der Ordner liegt in fremder Hand – Nextcloud, Syncthing, iCloud. Lesen kann
ihn damit der Anbieter, jeder mit Zugang zum Konto und jeder, der das
Verzeichnis auf einer geteilten Platte findet. Genau davor schützt die
Verschlüsselung, und nur davor.

**Sie schützt ausdrücklich nicht vor einem entsperrten Gerät.** Die lokale
Datenbank ist einfaches SQLite, und der abgeleitete Schlüssel liegt daneben
im app-privaten Speicher. Ihn stärker zu bewachen als die Daten, die er
öffnet, wäre Theater.

**Es gab lange eine zweite fremde Hand, über die nie jemand entschieden
hat.** Android sichert app-private Daten standardmäßig zu Google – also
auch die Einstellungsdatei mit dem Ordnerschlüssel und die Datenbank mit
dem Haushalt darin. Seit 0.15.0 ist das ausgeschaltet
(`android:allowBackup="false"` und `data_extraction_rules.xml`). Preis:
ein neues Telefon fängt ohne den gemeinsamen Ordner leer an – und der
Ordner ist genau der Weg, den diese App dafür vorsieht. Die
Geräte-zu-Gerät-Übertragung bleibt erlaubt; das ist ein Kabel zwischen
zwei Telefonen in denselben Händen.

Unter iOS gilt dasselbe für die Archive: sie liegen im Documents-Ordner
der App, den iOS nach iCloud sichert. Jede heruntergeladene Datei wird
deshalb mit `NSURLIsExcludedFromBackupKey` markiert, sonst wanderte eine
fünfzig Gigabyte große Wikipedia in die iCloud des Nutzers.

### Wie es funktioniert

Aus einem Kennwort, das alle Geräte des Haushalts teilen, wird mit
**Argon2id** ein 256-Bit-Schlüssel abgeleitet (64 MB, drei Durchgänge – die
OWASP-Empfehlung). Damit werden die Gerätedateien mit **AES-256-GCM**
versiegelt. Das Kennwort selbst liegt nie im Ordner; dort steht nur, wie
abzuleiten ist:

```json
{
  "version": 2,
  "householdId": "…",
  "vault": { "kdf": "argon2id", "salt": "…", "memory": 65536,
             "iterations": 3, "parallelism": 1 },
  "check": "…"
}
```

Salz und Arbeitsfaktoren sind öffentlich – sie müssen es sein, sonst könnte
ein zweites Gerät denselben Schlüssel nicht ableiten. `check` ist ein
verschlüsseltes Prüfwort. Ohne das wäre die einzige Art, ein Kennwort zu
prüfen, das Öffnen einer Gerätedatei – und die scheitert bei einem falschen
Kennwort genauso wie bei einem halb heruntergeladenen Download. Jemandem zu
sagen, sein Kennwort sei falsch, obwohl die Datei kaputt ist, ist der
schlimmere der beiden Fehler.

### Version 1 bleibt Version 1

Ein unverschlüsselter Ordner wird weiter als `"version": 1` geschrieben, ein
verschlüsselter als `2`. Die Asymmetrie ist Absicht: eine ältere App
verweigert eine unbekannte Version. Bei einem verschlüsselten Ordner ist das
richtig – sie könnte die Dateien ohnehin nicht lesen, und ein lautes „geht
nicht" ist besser als stilles Überspringen. Bei einem einfachen Ordner wäre
es falsch. Würde immer `2` geschrieben, wäre jeder Haushalt an dem Tag
ausgesperrt, an dem ein Mitglied aktualisiert.

### Beim Umschalten

Während umgestellt wird, liegen beide Formen nebeneinander, und beide werden
gelesen. Ein Gerät ohne Schlüssel meldet `locked` und **schreibt nichts** –
eine Klartextdatei in einem verschlüsselten Ordner würde die Verschlüsselung
für alle Zeilen dieses Geräts wieder aufheben.

### Kein Weg zurück

Ist das Kennwort weg, ist der Ordner unlesbar. Es gibt keine Wiederherstellung
und kein Zurücksetzen – dieselbe Lage wie beim Android-Signaturschlüssel.
Vor dem Einschalten aufschreiben.

## Grenzen

**Android** kennt seit Scoped Storage keine frei wählbaren Pfade mehr. Die
Ordnerauswahl liefert einen `content://`-Baum, den nur das Storage Access
Framework lesen kann; `dart:io` kommt gar nicht daran. Die sechs
Operationen laufen dort deshalb über einen eigenen Kanal nach
`MainActivity.kt`. Die Freigabe wird als *persistable* genommen und
überlebt damit den Neustart — der Ordner wird einmal gewählt, nicht bei
jedem Start.

Verloren geht sie trotzdem bei einer Neuinstallation, und die Nutzerin kann
sie in den Systemeinstellungen entziehen. Beides fällt beim nächsten
Abgleich auf (`ensureWritable` prüft die gespeicherte Freigabe, nicht nur
den Ordner) und wird gesagt, statt still nichts zu tun.

Geschrieben wird auf Android direkt in die Zieldatei statt über Umbenennen.
Ein Leser kann also im Prinzip eine halb geschriebene Datei erwischen; das
kostet diese eine Datei für einen Durchlauf, weil sie sich nicht lesen
lässt und übersprungen wird. Die Alternative auf SAF wäre löschen und
umbenennen — ein Fenster, in dem die Datei ganz fehlt, dazu Anzeigenamen,
die der Provider umschreiben darf.

**iOS und iPadOS** geben gar keinen Pfad heraus, der weiterarbeitet. Ein
im Dokumentenwähler gewählter Ordner kommt als *security-scoped* URL
zurück, deren Zugriff mit dem Prozess stirbt — und anders als unter macOS
lässt sich die Sandbox hier nicht abschalten.

Was überlebt, ist ein **Bookmark**: ein Datenblock, der sich beim nächsten
Start wieder in dieselbe URL auflösen lässt. Der Wähler legt einen an und
gibt Dart ein undurchsichtiges `bookmark://<id>` statt eines Pfades. Das
Schema ist zugleich das Erkennungszeichen, an dem die Dart-Seite den
richtigen Leser wählt — derselbe Kniff wie Androids `content://`.

Gelesen und geschrieben wird über `NSFileCoordinator`. Der Ordner ist ja
gerade der Sinn der Sache und liegt praktisch immer in einer Wolke —
iCloud Drive, Nextcloud. Ein unkoordinierter Lesezugriff auf eine Datei,
die ein anderes Gerät eben geschrieben hat, findet sonst einen Platzhalter,
der noch nicht heruntergeladen ist.

Ein Bookmark überlebt eine Neuinstallation nicht und wird ungültig, wenn
der Ordner verschoben oder gelöscht wird. Beides fällt bei `ensureWritable`
auf, genau wie unter Android.

**macOS** läuft mit Sandbox — seit 0.14.0. Vorher lief es ohne, weil die
Freigabe eines gewählten Ordners unter der Sandbox mit dem Prozess stirbt
und sie zu behalten nativen Swift-Code braucht; das einzige Dart-Paket
dafür ist auf Dart 2 stehengeblieben.

Genau dieser Swift-Code existiert seit der iOS-Umsetzung, und der Weg
zurück stand in dieser Datei schon als offen vermerkt. Gegangen wurde er
aus einem Grund, der mit dem gemeinsamen Ordner nur mittelbar zu tun hat:
**ohne Sandbox fragte macOS nach jeder neuen Fassung erneut nach dem
Zugriff auf Dokumente und Downloads.** Erlaubnisse hängen dort an der
Code-Signatur, und eine ad-hoc-Signatur ist bei jedem Bau eine andere. Eine
App in der Sandbox wird nach diesen Ordnern überhaupt nicht gefragt: sie
bekommt, was der Nutzer im Wähler aussucht, und das Bookmark liegt im
Container, der das Ersetzen der App überlebt.

`macos/Runner/StorageBridge.swift` ist deshalb die AppKit-Entsprechung der
iOS-Datei — dieselben Methodennamen, dasselbe `bookmark://`-Schema,
derselbe Dart-Code darüber. Der einzige Teil, der sich nicht übernehmen
ließ, ist der Wähler: **Auswahl und Bookmark müssen in einem einzigen
nativen Aufruf passieren**, weil die Freigabe am `NSURL`-Objekt hängt, das
`NSOpenPanel` zurückgibt, und nicht an dessen Pfad. Ein durch Dart
gereichter Pfad, aus dem später wieder eine URL gebaut wird, hat sie
verloren; `bookmarkData(.withSecurityScope)` scheitert dann. Deshalb geht
das nicht über `file_picker`.

Was der Wechsel einmalig kostet: Ein Archiv oder Ordner, der vor 0.14.0 als
blanker Pfad gespeichert war, liegt außerhalb der Sandbox und muss einmal
neu ausgewählt werden. Betroffen ist nur, was außerhalb von
`~/Downloads` liegt — dieser Ordner ist per Berechtigung weiter erreichbar,
und dort landen die Downloads der App von sich aus.

**Kein Echtzeit-Abgleich.** Zwischen „ich hake etwas ab" und „die andere
Person sieht es" liegen der Zwei-Minuten-Takt und die Laufzeit des
darunterliegenden Dienstes.

**Verschlüsselung ist optional.** Ohne aktivierte Verschlüsselung sind die
Gerätedateien lesbar. Nach dem Einschalten müssen auch die anderen Geräte
entsperrt werden und ihre alten Klartextdateien ersetzen. Cloud-Verläufe
und externe Sicherungskopien werden dadurch nicht gelöscht.

### Schutz vor verlorenen Verschlüsselungsdaten

Sobald dieses Gerät einen verschlüsselten Haushalt kennt, merkt es sich die
Verschlüsselungspflicht für dessen ID. Auch „Schlüssel vergessen“ hebt sie nicht
auf. Fehlt danach die `household.json` oder wurde sie durch unverschlüsselte
Metadaten ersetzt, stoppt der Abgleich. Die verschlüsselte `household.json` muss
aus einer Sicherung wiederhergestellt werden. Die App erstellt für diesen
Haushalt keinen Klartext-Ersatz.

Ein gespeicherter Schlüssel wird außerdem vor dem Lesen und Veröffentlichen
gegen den Prüfwert der aktuellen Ordner-Metadaten geprüft. Ein alter oder falscher
Schlüssel sperrt den Abgleich; vorhandene Gerätedateien bleiben erhalten.
