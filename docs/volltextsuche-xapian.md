# Volltextsuche ohne den Index im Archiv

Stand 2.5.8 (#186, #194). Ein Kiwix-Archiv bringt seinen eigenen
Volltextindex mit: eine [Xapian](https://xapian.org)-Datenbank, die
unkomprimiert als Block im Archiv liegt. Von 0.15.0 bis 2.5.7 haben die
Desktop-Pakete ihn gelesen. Seit 2.5.8 tun sie es nicht mehr; die App baut
überall ihren eigenen Index.

## Warum

Xapian steht unter der **GPL-2.0-or-later**. Wer ein Programm verbreitet,
das mit GPL-Code ein Gesamtwerk bildet, muss das Ganze unter GPL-Bedingungen
weitergeben, also mit dem Recht, es zu ändern und weiterzugeben. Die App
steht seit 2.3.5 unter der PolyForm Strict, die genau das verbietet. Unsere
Schicht `native/zim_xapian` band xapian-core statisch ein; die beiden
Lizenzen ließen sich nicht zugleich einhalten.

Eine Fassung von Xapian unter anderer Lizenz gibt es nicht. Das Projekt
will seit Jahren weg von der GPL, kann aber alten Code ohne Zustimmung der
damaligen Rechteinhaber nicht umlizenzieren; die Fassung, die es künftig
umlizenzieren könnte, enthält das Glass-Format nicht, in dem die Indizes in
Kiwix-Archiven liegen ([Licensing](https://trac.xapian.org/wiki/Licensing),
Stand März 2026). Eine andere Bibliothek, die dieses Format liest, gibt es
auch nicht; libzim, die Referenz für ZIM-Archive, steht selbst unter der
GPL.

## Was es kostet

Gemessen wurde 0.15.0 an der vollständigen deutschen Wikipedia (50 GB,
3,2 Millionen Artikel): Der eingebaute Index öffnete in 4 ms, eine Suche
dauerte 0 bis 4 ms.

Der eigene Index dagegen braucht einen **Indexlauf je Archiv**: Minuten für
eine Themensammlung mit einigen zehntausend Artikeln, eher eine Stunde und
mehrere Gigabyte für die vollständige Wikipedia. Der Lauf lässt sich
anhalten und fortsetzen, und was schon drin ist, ist durchsuchbar.

Die Suchqualität bleibt: Der eigene Index stemmt deutsche, englische,
spanische und französische Archive mit den Snowball-Algorithmen, in Dart
übertragen und an Snowballs eigenen Testlisten geprüft (`stemmers.dart`,
`tool/snowball_stems.sh`). Der deutsche liefert dieselben Stämme, die
Xapian 1.4 geliefert hat; geprüft an 356 006 Wörtern.

## Was es wieder schneller machen würde

Ein eigener Leser für das Glass-Format, ohne Xapian-Code. Ein Dateiformat
ist urheberrechtlich nicht geschützt, solange kein Code übernommen wird.
Der Aufwand wäre groß (das Format ist kaum dokumentiert), und stellt Kiwix
eines Tages auf ein neueres Format um, bräche der Leser. Bisher ist das
nicht geplant.
