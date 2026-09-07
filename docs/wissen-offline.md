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

**Ein Archiv zur Zeit.** PreppSuite hält genau ein ZIM offen; wechseln
geht jederzeit, gleichzeitig geht nicht.

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

**Volltext.** Braucht einen Index, den die App einmal selbst aufbaut.

Warum selbst: im Archiv liegt bereits ein Volltextindex, eine
Xapian-Datenbank. Sie zu benutzen hieße `libxapian` auf jede Plattform zu
tragen – eine C++-Bibliothek, deren Bau für Android, macOS, Linux und
Windows eine dauerhafte Last wäre. Stattdessen baut die App einen eigenen
Index mit SQLite FTS5.

Dass der andere Weg trotzdem geht, ist inzwischen gezeigt – samt dem, was
er besser kann, nämlich deutsche Wortstämme: siehe
[Volltextsuche über den Index im Archiv](volltextsuche-xapian.md). In der
App steckt er noch nicht.

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
