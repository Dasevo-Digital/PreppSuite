# Wissen offline

Nachschlagen ohne Netz: eine ZIM-Datei auf dem Gerät, gelesen von der App
selbst.

ZIM ist das Format, in das [Kiwix](https://kiwix.org) Wikipedia und
Ähnliches packt – eine einzige Datei mit einem Verzeichnis vorn und
komprimierten Blöcken dahinter.

## Woher die Datei kommt

Am einfachsten aus der App selbst: **Wissen → Archiv herunterladen** zeigt
den Katalog von <https://library.kiwix.org>, gefiltert nach Sprache und
durchsuchbar. Zu jedem Eintrag stehen Größe, Artikelzahl und ob Bilder
enthalten sind – die drei Zahlen, die entscheiden, ob eine Datei auf das
Gerät passt. Was fertig geladen ist, wird sofort als Archiv übernommen.

Der Download läuft weiter, solange die App offen bleibt, und lässt sich
fortsetzen: was angekommen ist, liegt als `.part`-Datei daneben und wird
beim nächsten Versuch weitergeführt statt neu begonnen. Wohin geladen
wird, steht in den Einstellungen unter „Ordner für Downloads"; auf dem
Rechner lässt es sich dort ändern, auf dem Telefon entscheidet die
Plattform.

Eine Eigenheit des Katalogs, die man kennen sollte, wenn man die Zahlen
vergleicht: **Kiwix rundet die angegebene Dateigröße auf.** Für eine Datei
von 6 940 898 Byte nennt der Katalog 6 941 696. Die App prüft deshalb
gegen die Länge, die der Server beim Abruf selbst nennt, und behandelt die
Katalogzahl nur als Anzeige.

Von Hand geht es weiterhin: die Sammlung steht auf
<https://library.kiwix.org> und im
[Download-Verzeichnis](https://download.kiwix.org/zim/). Für den Zweck
dieser App sind vor allem interessant:

- **Wikipedia komplett**, `wikipedia_de_all_maxi` – mehrere zehn Gigabyte,
  mit Bildern.
- **Wikipedia ohne Bilder**, `wikipedia_de_all_nopic` – ein Bruchteil davon
  und für Nachschlagen im Ernstfall meist genug.
- **Themensammlungen**, etwa `wikipedia_de_medicine` oder die
  Anleitungssammlungen von WikiHow und Appropedia. Deutlich kleiner, und
  näher an dem, wofür man diese App öffnet.

### Schule, wenn längere Zeit keine ist

Setzt das öffentliche Leben für eine Saison aus, fehlt einem Haushalt nach
Essen und Wärme als Nächstes ein Ort, an dem die Kinder weiterlernen. Die
naheliegende Antwort — Khan Academy — gibt es bei Kiwix nur auf Englisch,
Spanisch und Französisch; ein deutsches Archiv existiert nicht. Auf
Deutsch gibt es dafür:

- **`wikibooks_de_all_maxi`** – Lehrbücher, darunter *Mathe für
  Nicht-Freaks*, ein vollständiger Kurs von der Mittelstufe bis ins
  Grundstudium. Etwa 3,5 GB.
- **`klexikon_de_all`** – das Kinderlexikon, geschrieben für die
  Grundschule und ohne Hilfe lesbar.
- **`phet_de_all`** – interaktive Versuche für Physik, Chemie und
  Mathematik. Sie laufen im Archiv selbst, ohne Netz.
- **`wikiversity_de_all`** – Kurs- und Unterrichtsmaterial.
- **`ifixit_de_all`** – Reparaturanleitungen mit Bildern; keine Schule,
  aber dieselbe Lage.

Diese Liste steht auch in der App, auf der leeren Wissen-Seite: jeder
Eintrag öffnet die Bibliothek auf der passenden Suche, weil die
Dateinamen ein Datum tragen und sich alle paar Monate ändern.

### Mehrere Archive nebeneinander

Die Archive bleiben alle eingetragen. Über der Suche steht eine Reihe von
Schaltern, einer je Archiv; ein Tipp wechselt. Geöffnet ist immer genau
eines — ein ZIM offenzuhalten kostet einen Dateigriff und einen Port, und
die Bibliothek soll wachsen dürfen. Das Umschalten selbst ist ein Moment:
gelesen werden dabei nur Kopf und Mime-Liste.

Der Volltextindex, den die App selbst baut, gehört jeweils zu einem
Archiv und liegt in einer eigenen Datei, `preppsuite_knowledge_<id>`.
Umschalten wirft ihn also nicht mehr weg. Nimmt man ein Archiv aus der
Bibliothek, wird seine Indexdatei gelöscht — sie ist das Größte, was die
App überhaupt schreibt.

Das Archiv aus der Zeit vor der Bibliothek behält seinen Index unter dem
alten Namen `preppsuite_knowledge`: über einer ganzen Enzyklopädie neu zu
indizieren sind Stunden.

**Gesucht wird im geöffneten Archiv**, nicht über alle hinweg.

Es muss nicht Wikipedia sein. Jede ZIM-Datei geht, auch selbst gebaute:
[`zimwriterfs`](https://github.com/openzim/zim-tools) macht aus einem
Ordner mit HTML-Dateien eine – der Weg, eigene Lernmaterialien
mitzunehmen.

## Wie die App sie liest

Die Datei bleibt, wo sie ist, und wird nie kopiert. Gelesen wird in Stücken
von wenigen Kilobyte, und die App hält nie mehr als einen entpackten Block
im Speicher.

Unter Android geht das über die Storage Access Framework, wie beim
gemeinsamen Ordner und bei der Karte: die Freigabe wird dauerhaft genommen
und überlebt den Neustart.

Artikel werden von der Browser-Komponente des Systems gezeichnet. Dafür
stellt die App einen kleinen Server auf die Loopback-Adresse, der die
Datei ausliefert – das ist der Grund, warum Verweise zwischen Artikeln,
Bilder und Stilangaben ohne weiteres Zutun funktionieren: sie landen alle
wieder bei derselben Datei.

Auf Android, iOS, iPadOS und macOS steckt diese Komponente in der App.
Auf **Linux und Windows** gibt es dafür keine Einbettung, deshalb öffnet
der Artikel dort ein **eigenes Fenster** – gezeichnet von WebKitGTK
beziehungsweise WebView2, also von der Maschinerie, die auf dem Rechner
ohnehin liegt. Der Alternativweg wäre, einen ganzen Chromium mitzuliefern:
ein paar hundert Megabyte gegen eine Desktop-Fassung, die insgesamt siebzig
wiegt.

Der Server hört nur auf 127.0.0.1 und läuft nur, solange eine Datei
gewählt ist. Andere Programme auf demselben Gerät könnten ihn in dieser
Zeit erreichen; zu finden wäre dort die öffentliche Enzyklopädie, die die
Nutzerin heruntergeladen hat.

## Suchen

Zwei Arten, und die Umschaltung steht über der Trefferliste.

**Titel.** Nutzt die Titelreihenfolge, die im Archiv schon liegt. Sofort da,
nichts vorzubereiten. Findet „Trinkwasseraufbereitung" über den Namen und
nicht den Artikel, der das Wort nur erwähnt.

**Volltext.** Zwei Wege, und welcher greift, entscheidet das Archiv.

Ein Kiwix-Archiv bringt seinen eigenen Volltextindex mit, eine
Xapian-Datenbank, die unkomprimiert im Archiv liegt. Seit 0.15.0 nutzt die
App sie, wo sie kann: nichts aufzubauen, keine Wartezeit, und gesucht wird
nach Wortstämmen – „Notvorräte" findet „Notvorrat". An der vollständigen
deutschen Wikipedia gemessen: 3,2 Millionen Artikel, der Index öffnet in
vier Millisekunden, eine Suche dauert null bis vier.

Das geht auf macOS, Linux und Windows. Dahinter steckt `libxapian`, eine
C++-Bibliothek, die je Plattform gebaut und mitgeliefert werden muss –
unter Android fehlt sie noch; Einzelheiten in
[Volltextsuche über den Index im Archiv](volltextsuche-xapian.md).

Wo dieser Weg nicht offen steht – unter Android, und bei Archiven ohne
eigenen Index, etwa selbst gebauten – baut die App wie bisher einen
eigenen Index mit SQLite FTS5 auf.

**Auch der kennt seit 0.15.0 deutsche Wortstämme.** Nicht über eine
Bibliothek, sondern über denselben Algorithmus in Dart: gestemmt wird
beim Aufbau und bei der Suche, und „Notvorräte" findet damit auch dort
„Notvorrat". Geprüft ist er gegen Xapians eigenen Stemmer über ein ganzes
deutsches Wörterbuch, 356 006 Wörter, ohne eine einzige Abweichung.

Welcher Stemmer benutzt wurde, steht **im Index selbst**. Das ist keine
Umständlichkeit: eine Anfrage, die anders gestemmt wird als der Text,
findet nichts – und das liest sich genau wie ein Artikel, den es nicht
gibt. Ein Index von vor 0.15.0 sagt „keiner" und wird weiter ungestemmt
durchsucht, statt stillschweigend weggeworfen zu werden; für eine ganze
Wikipedia wäre das eine Stunde Neuaufbau.

Gestemmt wird nur, wenn das Archiv sich selbst als deutsch ausweist. Ein
deutscher Stemmer auf englischem Text zerlegt Wörter nach Regeln, die
für sie nicht gelten.

Der Aufbau läuft einmal, mit Fortschrittsanzeige, und lässt sich jederzeit
anhalten – was schon drin ist, bleibt durchsuchbar, und beim nächsten Mal
geht es dort weiter. Gelesen wird dabei in Block-Reihenfolge, nicht in
Artikel-Reihenfolge: sonst würde derselbe Block für jeden Artikel darin
noch einmal entpackt.

Der Index ist **contentless** – FTS5 speichert die Begriffe, nicht den
Text. Der steht ja weiter im Archiv. Zurück kommt die Nummer des Eintrags.

Größenordnungen: eine Themensammlung mit einigen zehntausend Artikeln ist
in Minuten fertig. Die vollständige deutsche Wikipedia ist eher eine Stunde
und mehrere Gigabyte; ab fünfzigtausend Artikeln sagt die App das vorher,
statt einfach loszulaufen.

**Was der Index nicht kann:** SQLite bringt keinen deutschen Stemmer mit.
„Notvorräte" findet „Notvorräte", aber nicht „Notvorrat". Umlaute sind
egal – `remove_diacritics` sorgt dafür, dass „Notvorrate" von einer
Telefontastatur auch trifft.

## Eigene Dokumente

Neben den Archiven nimmt die App Dateien auf, die dir selbst gehören: PDF,
EPUB, Markdown. Sie werden **nicht kopiert** — die Bibliothek merkt sich,
wo sie liegen, und liest sie von dort. Auf Wunsch wird ihr Text in einen
eigenen Volltextindex gelegt, der wie alles andere auf dem Gerät bleibt.

**Ganze Ordner.** Ein Ordner lässt sich auf einmal übernehmen: Was direkt
darin liegt und lesbar ist, kommt in die Bibliothek, höchstens
zweihundert Dateien auf einmal. Unterordner bleiben außen vor — ein
Dokumentenarchiv ist oft tief und breit, und aus einem Klick sollen nicht
tausende Einträge werden.

Das geht **am Computer**, nicht am Telefon. Unter Linux und Windows gibt
der Ordnerdialog einen gewöhnlichen Pfad heraus, unter macOS ein
Sicherheits-Lesezeichen, hinter dem sich der Ordner öffnen lässt und für
jede gefundene Datei ein eigenes Lesezeichen entsteht. Android und iOS
geben dagegen einen Baum heraus, den die App nur über die Plattformbrücke
erreicht, und für ein einzelnes Kind darin gibt es bisher keine Form, die
sich speichern ließe. Statt eines Knopfes, der dort nicht funktionieren
kann, steht auf diesen Geräten ein Satz, der das sagt.

**Aus dem Download-Ordner.** Am Computer schlägt die Bibliothek vor, was
direkt im Download-Ordner liegt und lesbar ist, aber noch nicht in der
Bibliothek steht: die zwölf neuesten Dateien, zuerst die jüngste (#33).
Dafür liest sie nur die Dateinamen. „Aufnehmen“ nimmt eine Datei auf und
baut gleich ihren Index, „Nicht mehr vorschlagen“ blendet sie dauerhaft
aus. Am Telefon gibt es das nicht: Android und iOS lassen eine App ihren
Download-Ordner nur über den Dateidialog sehen, und der öffnet sich
ohnehin dort.

**Wie groß.** Am Computer bis 512 MB je Datei und bis 16 Millionen
Zeichen Text je Dokument, am Telefon und Tablet bis 128 MB und 4
Millionen (#64). Die Datei wird im Ganzen gelesen; die Grenze ist also
auch der Speicher, den das Lesen höchstens braucht.

**Gescannte PDFs.** Ein PDF ohne Textebene ist für den Index ein leeres
Dokument; die App meldet das als „Kein auslesbarer Text (möglicherweise
ein Scan)". Seit #66 bietet sie dann **„Text erkennen“** an: Jede Seite
wird von PDFium mit 150 dpi gezeichnet und von der Texterkennung des
Systems gelesen, Seite für Seite, auf dem Gerät.

| | womit | Stand |
|---|---|---|
| macOS, iOS | Apple Vision, im System | iPhone-Simulator geprüft |
| Windows | `Windows.Media.Ocr`, im System, für installierte Sprachpakete | geprüft |
| Linux | Tesseract, falls installiert (`tesseract-ocr`, `tesseract-ocr-deu`) | geprüft |
| Android | noch keine | siehe unten |

Vorher sagt ein Dialog, was das heißt: Es dauert (gemessen rund eine
Sekunde je Seite auf einem Mittelklasse-Telefon), es bleibt auf dem Gerät,
und **erkannter Text kann Lücken haben, ohne dass etwas sie meldet** – die
Messung fand eine Seite, auf der Vision ganze Absätze ausließ und dabei
volle Zuversicht meldete. Ein so gelesenes Dokument steht in der Liste mit
„Text per Texterkennung, kann Lücken haben“. Während des Lesens bleibt der
Bildschirm an, weil Android die Arbeit sonst mit dem dunklen Bildschirm
anhält.

Android hat noch keine Texterkennung. Gemessen war ML Kit mit
mitgeliefertem Modell, und das liest gut – aber nach Googles eigenen
Bedingungen sendet ML Kit Leistungs- und Nutzungsdaten an Google, ohne
Möglichkeit, das abzuschalten. Die Bilder blieben auf dem Gerät, die App
würde aber Daten an Google schicken, und das tut sie sonst nirgends. Wie
es dort weitergeht, ist offen.

Die Messung dazu steht in `texterkennung-messung.md`.

## Grenzen

**Unter Linux und Windows muss die Browser-Komponente da sein.** Unter
Windows 11 ist WebView2 dabei, unter Windows 10 nicht immer; unter Linux
braucht es WebKitGTK, auf Debian und Ubuntu das Paket
`libwebkit2gtk-4.1-0`. Fehlt sie, sagt die App das beim Öffnen – suchen
geht weiter, lesen nicht.

**zstd und xz.** Kiwix komprimiert seit 2020 mit zstd, davor mit xz. Beides
liest die App. Die älteren Verfahren zlib und bzip2, die das Format noch
kennt, benutzt seit Jahren niemand mehr und die App lehnt sie mit Ansage
ab.

## Lizenzen

Die Inhalte stehen unter den Bedingungen ihrer Quelle – Wikipedia unter
CC BY-SA. Sie werden mit der Datei ausgeliefert und stehen in ihr.

## Lesen ohne Browser-Komponente des Systems

Artikel gehen in die Browser-Komponente des Systems, wo es eine gibt:
unter macOS, iOS und Android ist sie Teil des Betriebssystems, unter Linux
ist es WebKitGTK und unter Windows die WebView2-Laufzeit. Die beiden
letzten **liegen der App nicht bei**, und auf einem Rechner ohne sie und
ohne Netz war das Wissensarchiv bis jetzt eine Suche, die Artikel findet,
die niemand lesen kann — also genau in der Lage, für die diese App da ist.

Deshalb zeichnet die App den Artikel notfalls selbst.
`article_document.dart` zerlegt die Seite in Blöcke und Textläufe,
`article_reader_screen.dart` macht Flutter-Widgets daraus. Das Zerlegen
übernimmt das `html`-Paket des Dart-Teams: echtes Markup steckt voller
nicht geschlossener Tags, und ein nachsichtiger Parser ist nichts, was man
nebenbei richtig hinbekommt. Gezeichnet wird selbst, weil das der Teil
ist, der zu dieser App passen muss.

Die einfache Ansicht sagt oben, was sie ist: **kein Browser.** Keine
Skripte, kein Formelsatz, keine nach rechts gesetzten Infoboxen. Text,
Überschriften, Listen, Tabellen, Links und Bilder. Dafür gilt die
Schriftgröße und das Farbschema der App auch im Artikel, was in der
Browser-Komponente nie der Fall war.

### Wählbar unter Linux und Windows

Beide Wege sind unter Einstellungen → **Artikel anzeigen** auswählbar.
Voreingestellt bleibt das eigene Fenster, weil es mehr vom Artikel zeigt:
Skripte, Formelsatz, das Layout der Seite. Die einfache Ansicht bleibt
damit das, wofür sie gebaut wurde — ein Rückfall — und wird nur dann zur
Vorgabe, wenn jemand das sagt.

Gründe, sie trotzdem zu wählen: kein zweites Fenster in der Leiste, die
Schriftgröße und das Farbschema der App gelten auch im Artikel, und es
wird nichts vom System gebraucht.

**Fehlt die Komponente des Systems, zeichnet die App den Artikel ohnehin
selbst.** Die Auswahl ändert nur, was zuerst versucht wird. Auf den
übrigen Plattformen taucht die Einstellung nicht auf: Dort ist die
eingebettete Ansicht sowohl die bessere als auch die einzige, und eine
Auswahl zwischen einer Sache ist keine.

### Warum die Bibliothek nicht einfach mitgeliefert wird

Gemessen an `libwebkit2gtk-4.1.so.0` (2.52.6):

- Die Hilfsprozesse, ohne die WebKit nichts rendert, werden über einen
  **einkompilierten absoluten Pfad** gesucht
  (`/usr/lib/x86_64-linux-gnu/webkit2gtk-4.1/WebKitWebProcess`).
- `WEBKIT_EXEC_PATH` kommt in der Bibliothek **nicht vor** — nur
  `WEBKIT_INJECTED_BUNDLE_PATH`, und das ist etwas anderes.
- Weder `dladdr` noch `dl_iterate_phdr` noch `/proc/self/*` werden benutzt,
  um den Pfad zur Laufzeit auszurechnen.

Eine kopierte `.so` sucht ihre Hilfsprozesse also an der Systemstelle und
findet nichts. Dazu kämen rund **170 MB** (WebKit 92,7 + JavaScriptCore
30,9 + ICU 37,8 + GStreamer) und die Programme `bwrap` und
`xdg-dbus-proxy`. Machbar wäre es nur mit einem selbst gebauten WebKitGTK
auf festem Präfix — und das ist installieren, nicht mitführen.

Chromium über CEF wurde ebenfalls verworfen: Die Minimalauslieferung ist
**300 MB gepackt**, gegen eine App von 31 MB.

