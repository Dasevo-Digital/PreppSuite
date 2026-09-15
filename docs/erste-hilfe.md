# Erste Hilfe

Anleitungen, Zeichnungen und ein Taktgeber für die Herzdruckmassage.
Alles davon ist beim ersten Start da, ohne Netz, ohne Download und ohne
eine einzige Einstellung.

Videos sind ein eigener, nachladbarer Zusatz. Warum, steht weiter unten.

## Warum das nicht im Wissen-Bereich liegt

Der Wissen-Bereich ist eine Enzyklopädie hinter einem Archiv von mehreren
Gigabyte. Wer das nicht heruntergeladen hat, findet dort nichts – und wer
neben einem Verletzten kniet, hat es nicht heruntergeladen.

Erste Hilfe ist der eine Bereich, der ohne Voraussetzung funktionieren
muss. Deshalb ist er ein eigener Bereich und nicht eine Ecke eines
anderen.

Zu finden unter **Notfall → Erste Hilfe**, als erster Eintrag. Über jeder
dieser Seiten steht ein Streifen, der 112 wählt; wer drei Bildschirme tief
beim allergischen Schock liest, muss zum Anrufen nicht zurückfinden.

## Woher die Inhalte kommen

Die Anleitungen folgen den **Reanimationsleitlinien 2021 des European
Resuscitation Council** in der deutschen Fassung des German Resuscitation
Council und deren Erste-Hilfe-Kapitel. Die Vergiftungsseite nennt die
Giftinformationszentren der Länder, die Hitzeseite zusätzlich die BZgA.

Jede Anleitung nennt ihre Quelle auf dem Bildschirm. Das ist dieselbe
Regel wie bei den Kältestunden im Stromausfall: Diese App stellt keine
eigenen medizinischen Aussagen auf, und wo sie fremde wiedergibt, sagt
sie wessen.

Was bewusst fehlt: alles, was ohne Ausbildung nicht sicher anzuwenden
ist, und jede Dosierung eines Medikaments, das nicht dem Verletzten
selbst verordnet wurde.

## Wo die Texte liegen

Nicht in der Datenbank und nicht in den ARB-Dateien.

Nicht in der Datenbank, weil das keine Haushaltsdaten sind: niemand
bearbeitet sie, nichts gleicht sie ab, und eine Anleitung, die per
Abgleich von einem Gerät mit einer älteren Fassung ankommt, wäre
schlimmer als keine.

Nicht in den ARB-Dateien, weil medizinischer Text als Fließtext prüfbar
sein muss. Siebzehn Anleitungen sind rund zweihundert Zeichenketten;
verteilt über tausendvierhundert Zeilen Oberflächentext könnte sie
niemand am Stück gegen die Leitlinie lesen.

Sie liegen in

- `lib/features/first_aid/application/first_aid_guides_de.dart`
- `lib/features/first_aid/application/first_aid_guides_en.dart`

je eine Datei pro Sprache, jede an einem Stück lesbar.
`test/features/first_aid/first_aid_guides_test.dart` hält beide auf
dieselben Kennungen, dieselbe Reihenfolge und dieselbe Zahl an Schritten,
Warnungen und Kennzahlen fest. Eine Übersetzung, die stillschweigend einen
Schritt verliert, verliert einen Schritt einer Wiederbelebung.

Die Kennung einer Anleitung (`cpr-adult`, `recovery-position`, …) ist über
Fassungen und Sprachen hinweg stabil. Ein Video aus einem Paket nennt sie,
um zu sagen, wozu es gehört – wer eine umbenennt, verwaist jedes Video,
das darauf zeigte.

## Der Taktgeber

Das ist das eine, was eine App während einer Wiederbelebung kann und eine
gedruckte Karte nicht. Wer drückt, kann nicht gleichzeitig bis
hundertzehn und bis dreißig zählen, auf einen Brustkorb sehen und mit der
Leitstelle sprechen; sich selbst überlassen, driften die meisten deutlich
unter den Leitlinienwert.

Drei Kanäle, weil jeder einzelne irgendwo ausfällt: der Ton geht im Lärm
unter und fehlt auf einem Linux-Rechner ohne GStreamer, die Vibration gibt
es auf dem Schreibtisch nicht, und das Blinken hilft nicht, wenn niemand
hinsieht. Zusammen kommen sie an.

Der Bildschirm bleibt an, solange er läuft – ohne das schliefe er nach
einer halben Minute ein und nähme Takt und Zählung mit.

Die Zahl ist eine reine Funktion der verstrichenen Zeit
(`compression_pacer.dart`), kein Zähler, den ein Timer hochzählt. 110 in
der Minute sind 545.454,54… Mikrosekunden; ein zählender Taktgeber wäre
nach zwei Minuten mehrere Schläge daneben, und dann käme die Aufforderung
zu beatmen an der falschen Stelle.

Der Ton ist eine selbst erzeugte WAV-Datei von 2,5 kB
(`assets/sounds/metronome_click.wav`, erzeugt wie in der Versionsgeschichte
beschrieben) – keine Lizenzfrage, kein Download.

## Die Zeichnungen

Strichzeichnungen im Code, keine Bilddateien, und Piktogramme, keine
Illustrationen (`presentation/first_aid_drawings.dart`).

Ein Piktogramm wird schneller gelesen als ein Foto. Gezeigt wird immer
genau eine Beziehung – die Hände zum Brustbein, das Knie zum Boden – und
ein Bild, das nur diese enthält, ist auf Armlänge, auf einem Fußboden, bei
schlechtem Licht lesbar. Genau dort wird es benutzt.

Außerdem stimmt es in beiden Erscheinungsbildern: eine eingescannte
Zeichnung auf weißem Papier ist um drei Uhr nachts ein weißes Rechteck.
Und es kostet ein paar hundert Byte statt zehn Kilobyte mal jede
Bildschirmdichte.

## Videos

### Warum sie nicht mitgeliefert werden

Drei Gründe, in dieser Reihenfolge:

**Größe.** Zehn Clips von zwei Minuten in ansehbarer Auflösung sind 200
bis 300 MB, gegen eine App von 36 MB. Alle würden sie tragen, auch wer sie
nie öffnet.

**Recht.** Das Material der Hilfsorganisationen ist durchweg „alle Rechte
vorbehalten". Frei lizenzierte deutsche Erste-Hilfe-Videos gibt es kaum.

**Nutzen im Ernstfall.** Video ist dort das falsche Medium: eine Hand ist
belegt, spulen geht nicht, zurückgehen auch nicht. Was hilft, ist große
Schrift und Ton. Ein Video ist etwas für den Abend, an dem man sich die
Handgriffe in Ruhe ansieht.

Deshalb: ein eigenes Paket, zwei Wege hinein, und keine Anleitung hängt
davon ab.

### Das Paketformat

Ein Paket ist eine Beschreibung namens `paket.json` und die Dateien, die
sie nennt.

```json
{
  "format": 1,
  "name": "Erste Hilfe – Videopaket",
  "language": "de",
  "baseUrl": "https://example.org/eh/",
  "videos": [
    {
      "id": "hdm",
      "guide": "cpr-adult",
      "title": "Herzdruckmassage",
      "file": "hdm.mp4",
      "credit": "Jane Doe",
      "licence": "CC BY-SA 4.0",
      "url": "hdm.mp4",
      "seconds": 95,
      "bytes": 12345678,
      "sha256": "…"
    }
  ]
}
```

| Feld | Bedeutung |
|---|---|
| `format` | 1. Ein höherer Wert wird mit einem Satz abgelehnt, nicht halb gelesen. |
| `guide` | Die Kennung der Anleitung. `tool/erste_hilfe_paket.sh --ids` listet sie. |
| `file` | Ein reiner Dateiname. Ein Name mit Pfadanteil wird verworfen – eine Beschreibung kommt aus dem Netz, und eine, die `../../` nennen dürfte, wäre ein Weg, irgendwohin zu schreiben. |
| `url` | Absolut oder relativ zu `baseUrl`. Fehlt sie, ist das Paket nur als Datei zu bekommen. |
| `bytes`, `sha256` | Werden nach dem Laden geprüft. Passt etwas nicht, wird die Datei gelöscht statt behalten. |
| `credit`, `licence` | Stehen unter dem Video. Die meisten freien Lizenzen verlangen das, und der Zuschauer beurteilt danach, was er da sieht. |

### Ein Paket bauen

```bash
tool/erste_hilfe_paket.sh --ids          # welche Anleitungen es gibt
tool/erste_hilfe_paket.sh <ordner> [basis-url] [paketname]
```

Der Ordner enthält die Videodateien und eine `videos.tsv` mit einer Zeile
je Clip:

```
datei	anleitung	titel	urheber	lizenz	sekunden
hdm.mp4	cpr-adult	Herzdruckmassage	Jane Doe	CC BY-SA 4.0	95
```

Heraus kommen `paket.json` – mit Bytezahl und Prüfsumme jeder Datei – und
`ErsteHilfe-Videopaket.zip`.

### Zwei Wege hinein

**Über das Netz.** Die Adresse der `paket.json` unter **Erste Hilfe →
Videopaket** eintragen. Die App zeigt erst, was im Paket steckt und wie
groß es zusammen ist, und lädt dann auf Zuruf – einen Clip nach dem
anderen, jeden wieder aufnehmbar, jeden gegen Größe und Prüfsumme
geprüft. Was fehlschlägt, wird namentlich genannt; der Rest wird trotzdem
installiert.

Die App bringt **keine** Adresse mit. Eine fest eingebaute Adresse, unter
der noch nichts veröffentlicht ist, wäre ein 404 vor jedem Haushalt und
ließe eine funktionierende Sache kaputt aussehen.

**Aus einer Datei.** Die Zip auswählen. Sie wird als Strom gelesen und
Eintrag für Eintrag herausgeschrieben – ein Paket von einigen hundert
Megabyte im Speicher zu entpacken ist, wie eine App auf einem Telefon vom
System abgeräumt wird. Geschrieben wird nur, was die Beschreibung selbst
nennt.

Das ist der Weg, der ohne Netz funktioniert, also in der Lage, für die
diese App gebaut ist.

### Wo die Dateien liegen

Im gewöhnlichen Download-Ordner, Unterordner `ErsteHilfe` – aus demselben
Grund wie die Archive: groß, von Hand auf das nächste Gerät kopierbar,
ohne die App löschbar.

### Wiedergabe

In der App auf Android, iOS und macOS. Unter Linux und Windows gibt es
keine Umsetzung von `video_player`; dort wird die Datei an das
Abspielprogramm des Systems übergeben – dieselbe Teilung wie beim
Artikel-Leser, aus demselben Grund.
