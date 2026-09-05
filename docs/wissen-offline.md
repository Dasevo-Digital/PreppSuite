# Wissen offline

Nachschlagen ohne Netz: eine ZIM-Datei auf dem Gerät, gelesen von der App
selbst.

ZIM ist das Format, in das [Kiwix](https://kiwix.org) Wikipedia und
Ähnliches packt – eine einzige Datei mit einem Verzeichnis vorn und
komprimierten Blöcken dahinter.

## Woher die Datei kommt

Die Sammlung steht auf <https://library.kiwix.org> und im
[Download-Verzeichnis](https://download.kiwix.org/zim/). Für den Zweck
dieser App sind vor allem interessant:

- **Wikipedia komplett**, `wikipedia_de_all_maxi` – mehrere zehn Gigabyte,
  mit Bildern.
- **Wikipedia ohne Bilder**, `wikipedia_de_all_nopic` – ein Bruchteil davon
  und für Nachschlagen im Ernstfall meist genug.
- **Themensammlungen**, etwa `wikipedia_de_medicine` oder die
  Anleitungssammlungen von WikiHow und Appropedia. Deutlich kleiner, und
  näher an dem, wofür man diese App öffnet.

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

Der Server hört nur auf 127.0.0.1 und läuft nur, solange eine Datei
gewählt ist. Andere Programme auf demselben Gerät könnten ihn in dieser
Zeit erreichen; zu finden wäre dort die öffentliche Enzyklopädie, die die
Nutzerin heruntergeladen hat.

## Grenzen

**Gesucht wird in Titeln, nicht im Text.** Die Volltextsuche eines
ZIM-Archivs liegt in einem Xapian-Index – eine C++-Bibliothek ohne
Dart-Anbindung. „Trinkwasseraufbereitung" findet die App über den Namen;
den Artikel, der das Wort nur erwähnt, findet sie nicht. Der Suchschlitz
sagt das.

**Artikel lesen geht auf Android, iOS und macOS.** Auf Linux und Windows
fehlt die Browser-Komponente; suchen lässt sich dort, lesen nicht.

**zstd und xz.** Kiwix komprimiert seit 2020 mit zstd, davor mit xz. Beides
liest die App. Die älteren Verfahren zlib und bzip2, die das Format noch
kennt, benutzt seit Jahren niemand mehr und die App lehnt sie mit Ansage
ab.

## Lizenzen

Die Inhalte stehen unter den Bedingungen ihrer Quelle – Wikipedia unter
CC BY-SA. Sie werden mit der Datei ausgeliefert und stehen in ihr.
