# Abgleich mit den US-Behörden

Diese App folgt dem BBK, dem BLE und den deutschen Fachbehörden. Im
September 2026 wurde einmal geprüft, was **FEMA (ready.gov)**, das
**US-Landwirtschaftsministerium (USDA/FSIS)** und die **CDC** darüber
hinaus aufführen — und was davon hier fehlte.

Der Zweck des Dokuments ist, dass diese Recherche nicht noch einmal
geführt werden muss. Es steht also auch drin, was schon abgedeckt war
und was absichtlich nicht übernommen wurde.

## Was schon da war

Die amerikanische Grundausstattungsliste deckt sich fast vollständig mit
dem, was die achtzehn eingebauten Checklisten ohnehin enthalten:

Wasser und Vorrat, Kurbelradio, Taschenlampe, Ersatzbatterien,
Verbandskasten, Trillerpfeife, Staubmaske, Werkzeug, Dosenöffner, Karten
auf Papier, Powerbank, Hygieneartikel, Medikamente, Säuglingsbedarf,
Tierfutter, **Bargeld in kleinen Scheinen**, Dokumentenmappe, Schlafsack,
feste Schuhe, Feuerlöscher, Streichhölzer.

Auch der Notfallplan entspricht dem, was Ready.gov unter *Make a Plan*
verlangt: Treffpunkt in der Nähe und außerhalb, ein Kontakt außerhalb der
Region, der Ort des Notgepäcks, die Absperrhähne, die Anlaufstelle der
Gemeinde. Die Übungen gibt es als eigenen Bildschirm, das Verhalten bei
Gefahrstoffaustritt (*shelter in place*) steht in „Schutz suchen", der
Kohlenmonoxidmelder in „Sicherheit im Haus".

## Was übernommen wurde

### Die Kühlschrank-Uhr

**Einstellungen → Notfall → Stromausfall.**

Die USDA und FEMA veröffentlichen Stundenzahlen, die keine deutsche
Behörde nennt:

| | |
|---|---|
| Kühlschrank, Tür zu | etwa **4 Stunden** |
| Gefriergerät, voll | etwa **48 Stunden** |
| Gefriergerät, halb voll | etwa **24 Stunden** |
| Schwelle | 40 °F, also **4 °C** |
| Verderbliches darüber | nach **2 Stunden** entsorgen |

Dazu: nie probieren, um über die Sicherheit zu entscheiden; wieder
einfrieren ist erlaubt, solange Eiskristalle da sind.

**Das ist die erste Stelle, an der diese App eine ausländische Behörde
zitiert**, und der Bildschirm sagt das ausdrücklich. Gesucht wurde vorher
bei BZfE, BfR, BMEL und Verbraucherzentrale — alle beschreiben das
Prinzip, keine nennt Stunden. Die Alternative wäre gewesen, selbst eine
Zahl zu erfinden, und das ist die eine Sache, die diese App nicht tut.
Eine Kühlkette ist keine nationale Größe.

Die Uhr läuft über Neustarts hinweg weiter und wird **nicht** mit anderen
Geräten abgeglichen: zwei Telefone in derselben dunklen Wohnung würden
sich sonst gegenseitig die Startzeit überschreiben, und ein Gerät, das
woanders war, importierte einen Stromausfall, den es hier nie gab.

### Medikamentenreichweite

**Vorräte → Menü → Medikamente.**

FEMA und die CDC empfehlen beide, einen Vorrat verschreibungspflichtiger
Medikamente zu halten und zu wissen, wie lange er reicht. Die
Notfallkarte nennt das Medikament, sie beantwortet aber nicht, ob noch
drei Tage oder drei Monate da sind.

Ein Vorratsartikel der Kategorie „Medizin" bekommt dafür ein Feld
**Verbrauch am Tag**, in derselben Einheit wie der Bestand. Daraus wird
geteilt — mehr nicht. Die Dosis kommt von der Packung und aus der Praxis,
nie von der App. Medikamente ohne Tagesverbrauch werden **genannt statt
übergangen**, sonst läse sich die Zahl, als gälte sie für den ganzen
Schrank.

### Hausratverzeichnis

**Haushalt → Hausratverzeichnis.**

Ready.gov sagt es deutlicher, als es hier üblich ist: *document and
insure your property now*. Nach einem Brand, einem Wasserschaden oder
einem Einbruch fragt die Versicherung, was da war, und aus dem Kopf
beantwortet das niemand.

Erfasst werden Gegenstand, Raum, Seriennummer, Kaufdatum, Kaufpreis,
Notiz und ein Foto. Nur der Name ist Pflicht. Gruppiert wird nach Raum,
weil so eine Wohnung begangen wird. Summen werden **je Währung** gebildet
und nie über Währungen hinweg addiert; wie viele Einträge keinen Preis
haben, steht dabei.

Die Liste ist bewusst **nicht** der Vorrat: der beantwortet, wie lange
etwas reicht, dieser beantwortet, was ersetzt werden müsste. Eine
Waschmaschine im Kalorienziel wäre das Ergebnis einer Vermischung.

Die PDF-Ausgabe ist der eigentliche Zweck. Eine Liste dessen, was
verbrannt ist, die nur in der verbrannten Wohnung liegt, ist keine Liste.
**Die Fotos sind nicht im PDF** — sie liegen nur auf dem Gerät, das sie
aufgenommen hat, und würden aus zwei Seiten vierzig Megabyte machen, die
dann niemand verschickt.

### Die Checkliste „Wenn der Strom ausfällt"

Die bestehende Liste „Strom- und Heizungsausfall" sagt, was man haben
soll. Diese sagt, was man tut, solange er weg ist — und dort sind die
Amerikaner konkreter:

- Aggregat und Brennstoff nur im Freien, **mindestens 6 Meter** von
  Fenstern, Türen und angebauter Garage (20 Fuß bei Ready.gov)
- Geräte vom Netz nehmen, weil der Strom als **Spannungsspitze**
  zurückkommt
- für strombetriebene Medizingeräte und gekühlte Medikamente vorher einen
  Plan mit der Arztpraxis

Sie ist eine **eigene Vorlage** und nicht ein paar Zeilen mehr in der
alten, weil der Seeder eine Vorlage überspringt, die er schon findet —
neue Zeilen in einer alten Liste erreichten nur frische Installationen.

## Was nicht übernommen wurde

- **FEMA National Risk Index** — 18 Gefahren je US-County. Per
  Konstruktion nicht übertragbar.
- **NOAA-Wetterradio mit Tonalarm** — die Entsprechung ist hier die
  BBK-Kette, die die App ohnehin abfragt.
- **Wasseraufbereitung und Abkochzeiten** — schon 2026-09-11 verworfen,
  und die US-Quellen ändern daran nichts: CDC, WHO und das UBA nennen
  unterschiedliche Zeiten. Eine davon auszuwählen wäre genau die
  erfundene Skala, die diese App nicht ausliefert.
- **Emergency Financial First Aid Kit (EFFAK)** — die Sammlung der
  Papiere steckt bereits in der Checkliste „Wichtige Dokumente", die
  Suche darin in den eigenen Dokumenten unter Wissen. Das einzig Fehlende
  daraus war der Hausrat, und der ist jetzt da.
- **Getrennte Sets für Wohnung, Arbeit und Auto** — die Ausrüstungsfrage
  ist über das Notgepäck abgedeckt; drei parallele Listen für dieselben
  Gegenstände wären mehr Pflege als Nutzen.

## Die Regel, die dabei gilt

Unverändert die aus `ARCHITEKTUR.md`: **wo eine Behörde die Deutung
veröffentlicht, nimmt die App ihre — und wo keine es tut, liefert die App
keine Skala aus.** Die Kühlschrank-Uhr erweitert das nur um einen Satz:
wenn die Deutung von einer ausländischen Behörde kommt, steht das auf dem
Bildschirm.
