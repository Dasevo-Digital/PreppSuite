# Die App von einem Datenträger aus betreiben

PreppSuite kann ihre Daten in einem Ordner neben dem Programm halten
statt dort, wo das Betriebssystem sie sonst ablegt. Damit läuft dieselbe
Installation von einer externen Platte oder einem Stick — auch an einem
fremden Rechner.

Für eine App, deren ganze Begründung „wenn nichts mehr geht" lautet, ist
das kein Komfortmerkmal: Ein Haushalt, der seine Vorräte, seine
Notfallkarten, seine Karte und seine Wikipedia mitnehmen kann, hat sie
auch dann noch, wenn der eigene Rechner nicht mehr angeht.

## Einschalten

**Windows und Linux.** Einen Ordner namens `PreppSuite-Daten` neben das
Programm legen. Der nächste Start benutzt ihn. Mehr ist es nicht.

Gesucht wird bis zu vier Ebenen oberhalb der ausführbaren Datei, weil
„neben dem Programm" nicht eine Stelle ist: Das Linux-Paket entpackt nach
`PreppSuite-x64/bundle/PreppSuite`, der Ordner gehört also neben das, was
man entpackt hat, und nicht neben die Datei, die man startet.

**macOS.** Dort wird der Ordner **einmal je Mac ausgewählt** —
Einstellungen → Datenordner → „Ordner auswählen". Der Grund ist die
Sandbox, und die ist mit Absicht an: Nur so fragt das System nach einer
Aktualisierung nicht erneut nach Ordner-Zugriff (siehe
`macos/Runner/Release.entitlements`). Eine App in der Sandbox darf einen
Ordner neben ihrem eigenen Bündel aber gar nicht erst lesen. Ausgewählt
wird er über dasselbe Lesezeichen-Verfahren wie der gemeinsame Ordner;
danach verhält sich alles gleich.

**Überall.** Die Umgebungsvariable `PREPPSUITE_DATA` überstimmt beides.

**Nichts wird von allein angelegt.** Eine installierte Fassung verhält
sich genau wie bisher. Ein portabler Modus, der sich selbst einschaltet,
ist einer, der eines Tages ungefragt den Haushalt von jemandem verschiebt.

## Was in den Ordner wandert

Alles, was die App für sich selbst schreibt:

| | |
|---|---|
| `preppsuite.sqlite` | Haushalt, Vorräte, Checkliste, Budget, Notfallkarten |
| `preppsuite-*.sqlite` | je Archiv ein Volltext-Index |
| `einstellungen.json` | die Einstellungen |
| `inventory_photos/` | Produktfotos |
| `Archive/` | heruntergeladene Karten und Wissensarchive |
| `webview2/` | Arbeitsdateien des Artikelfensters (nur Windows) |

Die Einstellungen sind eine eigene Ablage und keine des Betriebssystems.
Das musste so sein: Unter macOS liegen Einstellungen in `NSUserDefaults`,
und das ist keine Datei in einem Ordner, sondern eine Datenbank des
Systems — sie lässt sich nirgendwohin umbiegen. Eine Umsetzung, die sich
auf allen drei Systemen gleich verhält, ist mehr wert als drei, die es
beinahe tun. Die Datei ist absichtlich lesbares JSON.

## Übernahme beim ersten Start

Beim ersten Start mit einem neuen Ordner übernimmt die App einmalig, was
auf diesem Rechner liegt: Datenbanken und Fotos. **Kopiert, nicht
verschoben** — die Installation auf dem Rechner ist weiterhin die von
jemandem und wird weiter gestartet. Ein Ordner, der schon einmal benutzt
wurde, wird nie überschrieben.

## Pfade, die sich ändern

Das ist der Teil, ohne den das Ganze nicht trägt.

Ein gemerkter Pfad ist absolut, und auf einem mitgeführten Datenträger
ist ein absoluter Pfad eine Behauptung über einen bestimmten Rechner: Der
Stick ist heute `E:` und morgen `F:`, auf einem Mac `/Volumes/PREPP` und
unter Linux `/media/marco/PREPP`. Kartenarchiv, Wissensarchive,
persönliche Dokumente, Fotos und der Download-Ordner wären nach dem
ersten Umstecken allesamt „nicht gefunden" — ein portables Programm mit
kaputter Bibliothek, und das ist schlechter als gar keins.

Deshalb wird alles, was **innerhalb** des Datenordners liegt, relativ
gemerkt, mit dem Präfix `daten:` und immer mit Schrägstrichen, damit ein
unter Windows geschriebener Eintrag unter Linux lesbar ist. Alles
außerhalb behält seinen absoluten Pfad — eine Datei auf der Platte des
Rechners ist genauso auffindbar wie eh und je.

Fotos haben zusätzlich einen Rückfall: Wird ein Haushalt übernommen,
kamen die Bilder mit, aber ihre gespeicherten Pfade nennen noch den alten
Rechner. Gibt es die Datei dort nicht, wird derselbe Dateiname im
Fotoordner dieser Fassung gesucht — dorthin hat die Übernahme sie gelegt.

## Was auf einem fremden Rechner trotzdem klemmt

**Linux: `libwebkit2gtk-4.1-0`.** Artikel brauchen die Browser-Komponente
des Systems, und die liegt nicht bei. Auf einem Rechner, auf dem sie
fehlt, lässt sie sich ohne Netz nicht nachinstallieren — also genau in
dem Fall, für den diese App gebaut ist. Die Suche im Archiv und alles
andere laufen weiter; nur der Artikeltext bleibt zu. Die App sagt das
mit dem Paketnamen, statt einfach nichts zu tun.

**macOS: Gatekeeper.** Die Bauten sind nicht signiert. Beim ersten Start
auf einem fremden Mac einmal Rechtsklick auf `PreppSuite.app` → „Öffnen"
und im Dialog bestätigen.

**Windows: SmartScreen.** „Weitere Informationen" → „Trotzdem ausführen".

## Dateisystem

**exFAT**, wenn der Datenträger zwischen Windows, macOS und Linux
wandern soll. Die 4-GB-Grenze je Datei gehört zu FAT32, nicht zu exFAT —
ein Wikipedia-Archiv von elf Gigabyte passt.

Drei Bauten nebeneinander sind rund 100 MB. Gegen eine Karte von zwei
Gigabyte fällt das nicht ins Gewicht.

## Beim Abziehen

Die Einstellungen werden daneben geschrieben und dann darübergelegt, nie
in die Datei selbst. Wird der Datenträger mitten im Schreiben abgezogen
— und so wird ein Stick üblicherweise abgezogen —, bleiben die vorherigen
Einstellungen stehen statt einer halben Datei.

Für die Datenbanken gilt das nicht in derselben Schärfe: SQLite ist
robust gegen einen Absturz, aber nicht gegen einen Datenträger, der
mitten im Schreiben verschwindet. Vor dem Abziehen die App schließen.
