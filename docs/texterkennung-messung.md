# Texterkennung: die Messung vor dem Bau

Ein gescanntes PDF ist für den Suchindex ein leeres Dokument. Die App
sagt das auch so — „Kein auslesbarer Text (möglicherweise ein Scan)" —,
und die naheliegende Frage ist, ob sie den Text nicht selbst erkennen
sollte, wie es Paperless-ngx tut.

Paperless-ngx tut es auf einem Server. Hier gibt es keinen, es gibt fünf
Plattformen, und es gibt die Regel, dass nichts das Gerät verlässt. Bevor
daraus ein Projekt wird, steht deshalb eine Messung: **was kostet eine
Texterkennung auf dem Gerät, und wie viel einer gescannten Seite liest
sie überhaupt?** Erst danach lässt sich entscheiden.

Gemessen am 25. September 2026 auf einem Apple M5 Pro, 24 GB, macOS 27.0.

## Womit gemessen wurde

Drei kleine Swift-Programme unter `tool/ocr_probe/`, keines davon Teil
der App:

* **`ocr_probe`** rendert eine PDF-Seite so, wie es PDFium in der App
  täte, und gibt das Bild an Apples Vision-Framework — dasselbe, was ein
  macOS- oder iOS-Build benutzen würde. Heraus kommen Zeiten, der
  erkannte Text und die Zuversicht, die Vision selbst angibt.
* **`make_page`** setzt einen bekannten Text als PDF. Ohne eine
  Grundwahrheit lässt sich über Qualität nichts sagen, und eine
  Grundwahrheit muss man herstellen, nicht suchen.
* **`make_scan`** macht aus dieser Seite das, was ein Scanner geliefert
  hätte: ein Bild, durch JPEG gedreht, ohne jede Textebene.

`tool/ocr_probe/run.sh --self-test` läuft die ganze Kette in einem Zug
und vergleicht am Ende das Erkannte mit dem Original.

## Was herauskam

**Geschwindigkeit.** Rund **0,2 Sekunden je Seite**, unabhängig davon, ob
mit 100 oder 300 dpi gerendert wird. Die BBK-Broschüre „Für den Notfall
vorgesorgt", 26 gescannte Seiten, war in **3,0 Sekunden** gelesen; ein
gescanntes Handbuch mit 210 Seiten in **69 Sekunden**. Das Rendern ist
dabei der kleinere Teil.

**Qualität.** Gegen eine Seite mit bekanntem Wortlaut, als Scan
aufbereitet:

| Auflösung | JPEG | erkannt | Übereinstimmung |
|---|---|---|---|
| 300 dpi | 0,8 | 1413 von 1413 | 0,998 |
| 200 dpi | 0,5 | 1413 von 1413 | 0,999 |
| 150 dpi | 0,5 | 1413 von 1413 | 0,998 |
| 100 dpi | 0,5 | 1412 von 1413 | 0,995 |

Deutsche Umlaute, „ß" und lange Komposita kommen richtig heraus. Auf der
echten BBK-Broschüre lesen sich Wörter wie „Hilfeleistungssystem" und
„Bevölkerungsschutz" fehlerfrei. **Mehr als 150 dpi bringt nichts** —
eine brauchbare Nachricht, denn die Auflösung bestimmt den Speicher.

**Speicher.** Und hier liegt die eigentliche Grenze. Der Messprozess
brauchte **rund 600 MB, bevor die erste Seite fertig war**, und danach
etwa 3 MB je weiterer Seite:

| Seiten | Spitzenspeicher |
|---|---|
| 10 | 624 MB |
| 50 | 797 MB |
| 120 | 981 MB |
| 210 | 1044 MB |

Die 600 MB sind das Modell, nicht das Dokument. Auf einem Rechner ist das
zu verkraften, auf einem Telefon ist es die Zahl, an der die Entscheidung
hängt — und sie käme zum Speicherbedarf der App noch hinzu.

## Drei Dinge, die ohne die Messung Fehler geworden wären

**Gedrehte Seiten.** Jede Seite der BBK-Broschüre trägt ein `/Rotate 90`.
`bounds(for:)` meldet den Kasten *vor* dieser Drehung, ein daraus
berechnetes Bitmap ist also hochkant, während der Inhalt quer liegt — ein
Drittel jeder Zeile fällt rechts heraus. Nichts daran sieht kaputt aus:
der Text, der erkannt wird, ist tadellos. Nur fehlt ein Drittel.

**Der Autorelease-Pool.** Dieselben 210 Seiten ohne einen eigenen Pool je
Seite: **2,39 GB** statt 1,04 GB, bei identischem Ergebnis. Jedes
Seitenbild und jede Erkennung bleibt sonst bis zum Prozessende am Leben.
Auf dem Telefon ist das der Unterschied zwischen einer Funktion und einem
Prozess, den das System abräumt.

**Die Zuversicht lügt nicht, aber sie sagt auch nichts.** Auf einer Seite
in Schreibmaschinenschrift mit engem Zeilenabstand ließ die genaue
Erkennung ganze Absätze aus — 814 von 1413 Zeichen — und meldete dabei
eine Zuversicht von 1,000. Dieselbe Seite in Helvetica: 1413 von 1413.
Die Zuversicht beschreibt, wie sicher Vision beim *Gelesenen* ist, nicht
wie viel es gelesen hat. Ein Dokument könnte also zu 40 % im Index fehlen,
ohne dass irgendetwas es meldet. Wer das baut, muss dafür eine Antwort
haben — und sei es der Satz auf dem Schirm, dass eine Erkennung
unvollständig sein kann.

Nebenbei: der allererste Aufruf von Vision auf diesem Rechner dauerte
**25,6 Sekunden**, jeder folgende 0,2. Das Modell wird einmal geladen,
danach nie wieder. Auf einem frischen Gerät fällt das einmal an.

## Was für die anderen Plattformen bliebe

Gemessen ist macOS. Der Rest steht weiter da, wo er vorher stand:

| | womit | offline | deutsch |
|---|---|---|---|
| macOS, iOS | Apple Vision, im System | ja | **gemessen: sehr gut** |
| Windows | `Windows.Media.Ocr`, im System | ja | nur mit installiertem Sprachpaket |
| Android | ML Kit, Modell mitliefern (**~11 MB je ABI**) | ja | lateinische Schrift |
| Linux | Tesseract | **liegt nicht bei** | ~15 MB `deu.traineddata` nötig |

Vier der fünf Plattformen könnten es ohne fremden Dienst und ohne Netz.
Linux bliebe außen vor, solange Tesseract nicht mitgeliefert wird — und
das wäre eine eigene Entscheidung über Paketgröße und Herkunft.

## Android: das Gerüst steht, das Gerät fehlt

Unter `tool/ocr_probe/android/` liegt das Gegenstück zur macOS-Messung:
ein eigenständiges Gradle-Projekt mit einer einzigen Activity, die eine
PDF-Seite mit Androids eigenem `PdfRenderer` rendert und an ML Kit gibt —
mit **mitgeliefertem** Modell, also ohne Netz und ohne Play-Dienste.
Gemessen werden dieselben Größen wie auf macOS: Zeit je Seite, erkannte
Zeichen und der Speicher (`Debug.getPss()`) vor der ersten und nach jeder
Seite.

```
tool/ocr_probe/android/run.sh <datei.pdf> [Seiten] [dpi]
```

Das Skript baut, spielt auf, schiebt die Datei hinüber, startet die
Messung und holt die Zeilen wieder ab. Gebraucht wird ein angeschlossenes
Gerät mit eingeschaltetem USB-Debugging; einen Emulator gibt es auf
diesem Rechner nicht, und für die Frage nach dem Speicher wäre er auch
die falsche Antwort.

**Eine Zahl steht schon fest, ohne Gerät:** das mitgelieferte Modell
kostet Platz im Paket. Die Messungs-APK enthält
`libmlkit_google_ocr_pipeline.so` mit **10,8 MB für arm64-v8a** und
6,6 MB für armeabi-v7a, dazu rund 1 MB Modelldateien. Für PreppSuite
hieße das etwa **+11 MB je APK** — auf heute 47 MB. Das ist keine
Kleinigkeit und gehört mit auf die Waage.

## Was die Messung nicht beantwortet

* **Nichts davon ist auf einem Telefon gemessen.** Die 600 MB sind die
  Zahl, die dort zählt, und sie stammen von einem Rechner mit 24 GB. Das
  Werkzeug für Android steht bereit, es fehlt das Gerät.
* Gemessen wurden zwei echte Scans und eine selbst gebaute Seite. Ein
  schiefer, fleckiger Scan einer alten Broschüre ist etwas anderes als
  ein sauberer Prospekt.
* Handschrift war nicht dabei und ist auch nicht das Ziel.
* Ob die Erkennung im Hintergrund laufen darf, während die App etwas
  anderes tut, ist offen — auf dem Telefon vermutlich nicht.

## Fazit

Die Erkennung selbst ist kein Hindernis: schnell genug, auf Deutsch gut
genug, und bei 150 dpi bereits am Ende dessen, was mehr Auflösung bringt.
Das Hindernis ist der Speicher auf dem Telefon und der Umstand, dass eine
unvollständige Erkennung sich nicht von einer vollständigen unterscheidet.

Der nächste Schritt ist deshalb nicht der Einbau, sondern dieselbe
Messung auf einem Telefon. Fällt sie dort ähnlich aus, ist die Funktion
eine überschaubare Arbeit; fällt sie schlecht aus, ist sie eine Funktion
für den Rechner — so wie der Ordner-Import es schon ist.
