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

Wird einmal geschrieben, von dem Gerät, das den Ordner einrichtet, und
danach nur noch gelesen. Genau deshalb hat sie keinen Konflikt: es gibt
keinen zweiten Schreiber.

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

Jede Zeile trägt eine `clientId` (einmal vergeben, auf dem Gerät, das sie
angelegt hat) und ein `updatedAt`. Beim Zusammenführen gewinnt die neuere
Zeile, streng größer.

Streng deshalb, weil dieselbe Datei dann beliebig oft eingelesen werden
darf, ohne etwas zu ändern, und weil die Reihenfolge, in der die
Gerätedateien gelesen werden, das Ergebnis nicht beeinflussen kann.

**Damit hängt alles an den Uhren.** Ein Gerät, das eine Stunde vorgeht,
gewinnt Auseinandersetzungen, die es verlieren sollte. Das ist der Preis
dafür, dass niemand schlichtet, und der Grund, warum nichts wirklich
gelöscht wird: jede Löschung ist eine Grabsteinzeile, die ihrerseits
überstimmt werden kann.

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

## Wann geschrieben wird

Gelesen wird beim Start, beim Zurückkehren in die App und alle zwei
Minuten, solange sie offen ist. Geschrieben wird nur, wenn es etwas zu
sagen gibt: eigene Änderungen, neu Gelerntes zum Weiterreichen, oder eine
fehlende eigene Datei. Jedes Schreiben weckt den Sync-Dienst und damit
jedes andere Gerät — ein stiller Durchlauf ist deshalb wirklich still.

Die Datei wird unter einem Zwischennamen geschrieben und dann umbenannt.
Sonst bekämen die Sync-Dienste, die den Ordner beobachten, halbe Dateien zu
verteilen.

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

**macOS** läuft ohne Sandbox. Unter der Sandbox stirbt die Freigabe eines
gewählten Ordners mit dem Prozess; sie zu behalten geht nur über
*security-scoped bookmarks*, was nativen Swift-Code bräuchte, denn das
einzige Dart-Paket dafür ist auf Dart 2 stehengeblieben. Die App wird
ohnehin direkt weitergegeben und nicht über den App Store, wo die Sandbox
Pflicht wäre. Seit es den Swift-Code für iOS gibt, wäre der Weg zurück
offen — nötig ist er bisher nicht. Der Eintrag steht mit Begründung in
`macos/Runner/Release.entitlements`.

**Kein Echtzeit-Abgleich.** Zwischen „ich hake etwas ab" und „die andere
Person sieht es" liegen der Zwei-Minuten-Takt und die Laufzeit des
darunterliegenden Dienstes.

**Keine Verschlüsselung durch PreppSuite.** Wer den Ordner lesen kann,
liest den Haushalt. Das ist Sache des Dienstes, dem der Ordner gehört.
