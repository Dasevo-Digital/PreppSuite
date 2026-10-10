# Texterkennung: die Messung vor dem Bau

Ein gescanntes PDF ist für den Suchindex ein leeres Dokument. Die App
sagt das auch so — „Kein auslesbarer Text (möglicherweise ein Scan)" —,
und die naheliegende Frage ist, ob sie den Text nicht selbst erkennen
sollte, wie es Paperless-ngx tut.

Paperless-ngx tut es auf einem Server. Hier gibt es keinen, es gibt fünf
Plattformen, und es gibt die Regel, dass nichts das Gerät verlässt. Bevor
daraus ein Projekt wird, steht deshalb eine Messung: **was kostet eine
Texterkennung auf dem Gerät, und wie viel einer gescannten Seite liest
sie überhaupt?**

Gemessen am 25. September 2026 auf zwei Geräten:

* **Apple M5 Pro**, 24 GB, macOS 27.0 — Apples Vision-Framework.
* **OnePlus Nord (AC2003)**, Snapdragon 765G, 7,2 GB, Android 12 —
  ML Kit mit **mitgeliefertem** Modell, also ohne Netz und ohne
  Play-Dienste.

Dasselbe Dokument auf beiden: die BBK-Broschüre „Für den Notfall
vorgesorgt", 26 gescannte Seiten ohne jede Textebene.

## Womit gemessen wurde

Unter `tool/ocr_probe/` liegen vier Programme, keines davon Teil der App:

* **`ocr_probe.swift`** rendert eine PDF-Seite und gibt sie an Vision.
* **`make_page.swift`** setzt einen Text mit bekanntem Wortlaut als PDF.
  Ohne Grundwahrheit lässt sich über Qualität nichts sagen, und eine
  Grundwahrheit muss man herstellen, nicht suchen.
* **`make_scan.swift`** macht daraus, was ein Scanner geliefert hätte.
* **`android/`** ist das Gegenstück: ein eigenständiges Gradle-Projekt,
  das mit Androids `PdfRenderer` rendert und ML Kit fragt.

`tool/ocr_probe/run.sh --self-test` läuft die macOS-Kette in einem Zug,
`tool/ocr_probe/android/run.sh <datei.pdf>` misst auf einem
angeschlossenen Telefon.

## Was herauskam

Dieselben 26 Seiten, 200 dpi, auf beiden Geräten:

| | macOS / Vision | Android / ML Kit |
|---|---|---|
| Rendern, gesamt | 0,17 s | 2,97 s |
| Erkennen, gesamt | **3,04 s** | **25,5 s** |
| je Seite | 0,12 s | 0,98 s |
| erkannte Zeichen | 52 693 | 52 622 |
| Speicher, Spitze | 192 MB | 159 MB |

**Beide lesen dasselbe.** Die Übereinstimmung der beiden Ergebnisse liegt
je Seite im Mittel bei 0,93, und wo sie auseinandergehen, geht es um
Zeilenumbrüche und Bildunterschriften, nicht um Inhalt. Deutsche
Umlaute, „ß" und lange Komposita kommen auf beiden Geräten richtig heraus
— „Hilfeleistungssystem", „Bevölkerungsschutz".

Das Telefon ist rund **achtmal langsamer**, was für einen Mittelklasse-
Chip von 2020 gegen einen M5 Pro zu erwarten war. Eine Broschüre dieser
Größe ist damit in einer halben Minute gelesen.

**Der Speicher ist nicht das Hindernis, das er zu sein schien.** Auf dem
Telefon lag der Prozess vor der ersten Seite bei 20 MB und stieg auf
159 MB — für ein Gerät mit 7 GB unauffällig.

Auf die Auflösung kommt es kaum an. Gegen eine Seite mit bekanntem
Wortlaut, als Scan aufbereitet:

| Auflösung | JPEG | erkannt | Übereinstimmung |
|---|---|---|---|
| 300 dpi | 0,8 | 1413 von 1413 | 0,998 |
| 200 dpi | 0,5 | 1413 von 1413 | 0,999 |
| 150 dpi | 0,5 | 1413 von 1413 | 0,998 |
| 100 dpi | 0,5 | 1412 von 1413 | 0,995 |

**Mehr als 150 dpi bringt nichts** — eine brauchbare Nachricht, denn die
Auflösung bestimmt den Speicher.

## Eine Korrektur an dieser Datei

Eine frühere Fassung dieses Textes nannte für macOS „rund 600 MB, bevor
die erste Seite fertig ist" und 37 226 erkannte Zeichen für die
BBK-Broschüre. **Beides war falsch, und zwar wegen des Messwerkzeugs,
nicht wegen Vision.**

Der erste Renderer ging über PDFKit: Bitmap aus `bounds(for:)`, dann
`draw(with:to:)`. Auf jeder Seite dieser Broschüre — sie tragen alle ein
`/Rotate 90` — hat er ein Drittel des Inhalts abgeschnitten. Aufgefallen
ist es erst im Vergleich mit Android, das dieselben Seiten vollständig
las: 52 622 gegen 37 226 Zeichen. Nichts daran sah kaputt aus. Der Text,
der ankam, war tadellos; es fehlte nur eine Spalte.

Der Weg, der stimmt, führt über Core Graphics: `getDrawingTransform`
setzt die Seite samt Drehung in ein Rechteck. Die Vergrößerung auf die
Zielauflösung gehört dabei **in den Kontext** und nicht in das Rechteck —
gibt man dem Transform das Pixelrechteck, landet die Seite bei 200 dpi
auf halber Größe in einer Ecke, was der zweite Fehlversuch war. Mit dem
richtigen Weg liest macOS 52 693 Zeichen, also dasselbe wie das Telefon,
und die Spitze für denselben Lauf liegt bei 192 statt 544 MB.

Der Speicher hängt an der Seitengröße, nicht an einer festen Grundlast:
ein Handbuch mit 210 sehr großen Scanseiten (rund 5500 × 4300 Pixel bei
200 dpi) brauchte auf demselben Rechner bis zu 723 MB.

Dasselbe Handbuch auf dem Telefon, über 23 Seiten verfolgt, bevor der
Lauf am Doze-Zustand hängenblieb: **1,4 Sekunden Rendern und 2,4
Sekunden Erkennen je Seite im Median, Spitze 299 MB.** Auch hier hängt
alles an der Seitengröße — eine viermal so große Seite kostet ungefähr
viermal so viel. Die Ausreißer dieses Laufs (bis zu neun Minuten für eine
Seite) sind kein Messwert, sondern der schlafende Bildschirm.

## Vier Dinge, die ohne die Messung Fehler geworden wären

**Gedrehte Seiten** — siehe oben. Der teuerste der vier, weil er sich als
Qualitätsproblem der Erkennung tarnt.

**Der Autorelease-Pool.** 210 Seiten ohne einen eigenen Pool je Seite:
2,39 GB statt 1,04 GB, bei identischem Ergebnis. Jedes Seitenbild bleibt
sonst bis zum Prozessende am Leben.

**Die Zuversicht sagt nichts über Vollständigkeit.** Auf einer Seite in
Schreibmaschinenschrift mit engem Zeilenabstand ließ Vision ganze Absätze
aus — 814 von 1413 Zeichen — und meldete dabei eine Zuversicht von
1,000. Dieselbe Seite in Helvetica: 1413 von 1413. Das bleibt auch mit
dem berichtigten Renderer so. Die Zuversicht beschreibt, wie sicher
Vision beim *Gelesenen* ist, nicht wie viel es gelesen hat. Ein Dokument
könnte also zu 40 % im Index fehlen, ohne dass irgendetwas es meldet.

**Android hört auf, wenn der Bildschirm ausgeht.** Ein Lauf blieb bei
Seite 17 stehen, der Prozess lebte weiter, das Gerät stand auf `Dozing`.
Eine Stapelverarbeitung über ein langes Dokument bräuchte also einen
Vordergrunddienst — oder sie muss damit rechnen, mittendrin angehalten
zu werden.

Nebenbei: der allererste Aufruf von Vision auf diesem Rechner dauerte
**25,6 Sekunden**, jeder folgende 0,2. Das Modell wird einmal geladen,
danach nie wieder.

## Was es kosten würde

**Android: rund 11 MB je ABI.** Die Messungs-APK enthält
`libmlkit_google_ocr_pipeline.so` mit 10,8 MB für arm64-v8a und 6,6 MB
für armeabi-v7a, dazu etwa 1 MB Modelldateien. Für PreppSuite hieße das
gut **+11 MB je APK**, auf heute 47 MB.

**macOS und iOS: nichts.** Vision liegt im System.

| | womit | offline | deutsch |
|---|---|---|---|
| macOS | Apple Vision, im System | ja | **gemessen: sehr gut** |
| Android | ML Kit, Modell mitliefern (~11 MB je ABI) | ja | **gemessen: sehr gut** |
| iOS | Apple Vision, im System | ja | dasselbe Framework wie macOS |
| Windows | `Windows.Media.Ocr`, im System | ja | nur mit installiertem Sprachpaket |
| Linux | Tesseract | **liegt nicht bei** | ~15 MB `deu.traineddata` nötig |

## Was die Messung nicht beantwortet

* Gemessen wurden zwei echte Scans und eine selbst gebaute Seite. Ein
  schiefer, fleckiger Scan einer alten Broschüre ist etwas anderes als
  ein sauberer Prospekt.
* iOS ist nicht gemessen, nur baugleich mit macOS.
* Windows und Linux sind gar nicht gemessen.
* Handschrift war nicht dabei und ist auch nicht das Ziel.
* Wie sich die Erkennung neben einer laufenden App verhält — Speicher,
  Wärme, Akku —, ist offen. Gemessen wurde ein Prozess, der nichts
  anderes tat.

## Fazit

Die Erkennung ist kein Hindernis. Auf beiden gemessenen Geräten liest sie
deutschen Text aus echten Scans praktisch vollständig, auf dem Telefon in
einer Sekunde je Seite und mit einem Speicherbedarf, der ein Telefon
nicht überfordert. Die Auflösung darf niedrig bleiben.

Was zu klären bleibt, ist nicht mehr das Ob, sondern das Wie: ein
Vordergrunddienst für lange Dokumente unter Android, +11 MB Paketgröße
dort, und eine ehrliche Antwort darauf, dass eine unvollständige
Erkennung sich von einer vollständigen nicht unterscheiden lässt.

## Umsetzung (#66)

Gebaut für macOS und iOS (Vision), Windows (`Windows.Media.Ocr`) und
Linux (Tesseract über die Kommandozeile, falls installiert). Die Seiten
zeichnet PDFium, das die App ohnehin mitbringt, mit 150 dpi und höchstens
4000 Pixeln an der langen Seite, eine Seite nach der anderen; die Engines
bekommen dieselben BGRA-Pixel. `integration_test/native_text_recognition_test.dart`
legt einen bekannten Satz als Bild in ein PDF ohne Textebene und liest ihn
zurück; bestanden im iPhone-Simulator, unter Windows und unter Linux.

**Android: zurückgestellt.** Laut den
[ML-Kit-Bedingungen](https://developers.google.com/ml-kit/terms) bleiben
die Bilder zwar auf dem Gerät, ML Kit schickt aber Kennzahlen zu Leistung
und Nutzung an Google und fragt von Zeit zu Zeit nach Updates; eine
Abschaltung nennen die Bedingungen nicht. Das war in der Messung nicht
bedacht.
