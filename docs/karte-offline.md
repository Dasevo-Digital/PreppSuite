# Karte offline

Ohne eigene Karte holt die App ihre Kacheln von OpenStreetMap – also nur
mit Verbindung. Eine PMTiles-Datei auf dem Gerät ersetzt das vollständig:
kein Netz, kein Kachelserver, kein Schlüssel.

## Was die App braucht

Drei Dinge, und sie prüft alle drei beim Auswählen, statt später eine leere
Karte zu zeigen:

1. **PMTiles, Version 3.** Ein Archivformat für Kacheln – eine einzige
   Datei mit einem Verzeichnis vorn drin.
2. **Vektorkacheln, keine Bilder.** PreppSuite zeichnet die Karte selbst.
   Ein Archiv mit fertigen PNGs wird abgelehnt.
3. **OpenMapTiles-Schema.** Also Ebenen, die `water`, `transportation`,
   `building` und so weiter heißen. Das mitgelieferte Kartenbild liest
   genau diese Namen; ein Archiv im Protomaps-Schema hat dieselben Daten
   unter anderen Namen und käme leer heraus.

Der dritte Punkt ist der, an dem die meisten Downloads scheitern: die
fertigen `.pmtiles`, die man im Netz findet, sind überwiegend
Protomaps-Schema.

## In der App laden

Deshalb baut die App sich die Datei selbst. **Einstellungen → Offline-Karte
→ Karte herunterladen.**

Das Gebiet lässt sich auf zwei Arten bestimmen:

- **Nach Namen suchen** – Ort, Kreis, Bundesland oder Land. Die Suche geht
  an Nominatim, den Geokodierer von OpenStreetMap, und was zurückkommt,
  ist die Umgrenzung des Ortes. „Niedersachsen" ist damit ein Gebiet, das
  man meinen kann, statt eines Rechtecks, das man mit der Hand darum legen
  müsste.
- **Die Karte verschieben** – dann ist das Gebiet der sichtbare
  Ausschnitt. Ein Griff an die Karte schaltet von einem gesuchten Ort
  wieder hierher zurück.

### Wie weit hinaus

Ist ein Ort gesucht, bietet die App Ringe an: **nur der Ort**, **mit
Bundesland**, **ganzes Land**, **ganzer Kontinent**. Sie werden gestaffelt
geladen — der äußerste Ring grob, der innerste in voller Tiefe, mit
lückenlos aneinandergrenzenden Zoomstufen. Für Hannover mit Europa
ergibt das:

| Ring | Stufen | Kacheln |
|---|---|---|
| Welt | 0–4 | 341 |
| Europa | 5–9 | 13.184 |
| Deutschland | 10–12 | 20.132 |
| Niedersachsen | 13–14 | 64.560 |

Bundesland und Land kommen vom Geokodierer. **Der Kontinent nicht** — er
steht als Rechteck in `continents.dart`. „Europa" ist nichts, worauf
Nominatim brauchbar antwortet, und der Umriss eines Erdteils ändert sich
nicht; das Netz nach einer Konstanten zu fragen hieße, einer Funktion, die
gerade ohne Netz arbeiten soll, eine Anfrage einzubauen, die scheitern
kann.

**Die Welt ist immer dabei, Stufe 0 bis 4.** Ohne sie hält ein Archiv nur
die Kacheln, die sein eigener Kasten berührt — und bei Stufe 3 deckt eine
einzige Kachel schon Barcelona bis Warschau ab. Herausgezoomt stand dann
ein Quadrat im leeren Grau, ohne Nachbarn zum Zeichnen. 341 Kacheln
kaufen eine Karte, die überall vollständig aussieht.

Ein Schieberegler bestimmt, wie tief: Stufe 12 zeigt Ortschaften und
Hauptstraßen, Stufe 14 einzelne Straßen und Gebäude. Solange er nicht
angefasst wurde, wählt die App **die tiefste Stufe, die für dieses Gebiet
noch geht** – und sagt, wenn das nicht 14 ist, wie viele Kacheln 14 wären.
Die Kachelzahl steht ohnehin daneben, bevor irgendetwas passiert.

Was die Suche liefert, ist ein umschließendes Rechteck, nicht die
Landesgrenze. Wer Niedersachsen lädt, bekommt die Ecken der Nachbarn mit.
Gegen die echte Kontur zu schneiden hieße, das Polygon mitzuführen und
jede Kachel dagegen zu prüfen – bei einem Rechteck, das dem Land ungefähr
entspricht, für wenig Ersparnis.

Was dabei entsteht, ist ein echtes PMTiles-v3-Archiv, geschrieben von
`pmtiles_writer.dart` – dem Gegenstück zum Leser, und aus demselben Grund
von Hand: das `pmtiles`-Paket braucht eine Protobuf-Fassung, die
`vector_tile_renderer` nicht haben kann. Gleiche Kacheln werden nur einmal
abgelegt, was bei leerem Wasser den Unterschied macht.

### Zwei Quellen

- **OpenFreeMap** – frei, ohne Konto, ohne Schlüssel, im
  OpenMapTiles-Schema aus OpenStreetMap-Daten. Die Voreinstellung.
- **MapTiler** – braucht ein Konto; der Schlüssel wird in den
  Einstellungen eingetragen und bleibt auf dem Gerät. Der Kachelsatz
  `tiles/v3` ist ebenfalls OpenMapTiles-Schema.

Beide beschreiben sich selbst in TileJSON, weshalb es nur einen Client
gibt. Die Kachel-Adresse wird von dort gelesen und nicht einkompiliert:
OpenFreeMap datiert seine Pfade und verschiebt sie mit jedem Planetenbau.

### Gestaffelt: ein ganzes Land

Ein Land flach bis Stufe 14 ist nicht zu haben – aber fast keine dieser
Kacheln sieht je jemand an. Deshalb kennt der Bildschirm drei Umfänge, und
die beiden größeren staffeln:

| Umfang | was geladen wird |
|---|---|
| **Nur der Ort** | der gesuchte Ort, so tief wie er passt |
| **Mit Bundesland** | das Bundesland außen herum, gröber; der Ort voll |
| **Ganzes Land** | das Land außen herum, gröber; darin das Bundesland voll |

Die Ringe teilen sich die Stufen auf: der äußerste Ring deckt Stufe 0 bis
zu einem Schnitt, der nächste von dort bis zum nächsten Schnitt, und der
innerste bis 14. Wo die Schnitte liegen, sucht die App selbst – so tief
wie das Budget hergibt, und von innen nach außen bevorzugt, weil
Detailtiefe dort, wo man steht, mehr wert ist als zwei Bundesländer weiter.

Für „Hannover", Umfang *Ganzes Land*:

| Ring | Stufen | Kacheln |
|---|---|---:|
| Deutschland | 0–12 | 20 503 |
| Niedersachsen | 13–14 | 64 560 |
| **Summe** | | **85 063** |

Das sind rund 3,8 GB statt 14 GB, und der Unterschied ist kein Verlust:
ganz Deutschland ist drin, mit jeder Straße in Niedersachsen. Wer weiter
weg fährt, hat dort Stufe 12 – Ortschaften und Hauptstraßen.

Ein Ring, den sein Nachbar schon vollständig abdeckt, fällt weg. Wer ein
Bundesland und einen Ort darin wählt und genug Budget für das ganze Land
auf Stufe 14 hat, bekommt das ganze Bundesland – und nicht eine Stufe
weniger, damit für den Ort noch eine übrig bleibt.

**Speicherplatz ist dabei nie die Grenze.** Die Grenze ist die Zahl der
Anfragen an einen fremden Server; die Datei darf so groß werden, wie das
Gerät hergibt. Für eine App, die offline funktionieren muss, ist das die
richtige Reihenfolge.

### Fortsetzbar über den Programmstart hinweg

Ein Land sind zehntausende Kacheln und über eine Stunde. So lange lässt
niemand eine App offen – der Normalfall ist deshalb nicht, dass ein
Download fertig wird, sondern dass er unterbrochen wird.

Neben der Arbeitsdatei liegt ein **Journal**: eine Zeile je Kachel mit
`Kachelnummer Offset Länge`. Geschrieben wird sie erst, nachdem die Bytes
auf der Platte sind – nie andersherum, denn eine Journalzeile über Bytes,
die es nicht gibt, ergäbe ein kaputtes Archiv, während der umgekehrte Fall
nur eine Kachel kostet.

Beim nächsten Start bietet der Bildschirm oben an, den Download
fortzusetzen, und sagt dazu, wie viel schon da ist. Dabei passiert
zweierlei:

- Die Arbeitsdatei wird auf das gekürzt, was das Journal kennt. Ein Lauf,
  der mitten in einer Kachel abgebrochen wurde, hinterlässt mehr Bytes,
  als das Journal verantwortet; die überzähligen fliegen raus.
- Eine halb geschriebene letzte Journalzeile wird verworfen. Die Kachel
  wird noch einmal geholt.

Was **nicht** übernommen wird: welche Kacheln gleichen Inhalt hatten. Das
neu aufzubauen hieße, alles bereits Gespeicherte noch einmal zu lesen; der
Preis dafür, es zu lassen, sind ein paar doppelt abgelegte Kacheln – keine
falsche Karte.

Abbrechen ist damit dasselbe wie Pausieren. Weggeworfen wird nur, was man
ausdrücklich verwirft oder was ein neuer Download ersetzt.

### Grenzen, und warum es sie gibt

Über 100 000 Kacheln lehnt die App ab. Das ist keine technische Grenze,
sondern eine Anstandsgrenze: die Kacheln kommen von einem öffentlichen
Server, den andere mitbenutzen.

Die Zahl ist so gewählt, dass **jedes deutsche Bundesland auf der tiefsten
Stufe hineinpasst** und **ein ganzes Land nicht**. Gemessen an den
Umgrenzungen, die Nominatim liefert:

| Gebiet | Kacheln bis Stufe 14 | tiefste mögliche Stufe |
|---|---:|---:|
| Hannover (Stadt) | 264 | 14 |
| Bayern | 68 028 | 14 |
| Niedersachsen | 68 913 | 14 |
| Deutschland | 319 812 | **13** (80 563 Kacheln) |

Ein ganzes Land auf Stufe 14 wären rund vierzehn Gigabyte und ebenso viele
Anfragen wie Kacheln. Das ist nichts, was man einem Kachelserver zumutet,
der für andere Leute läuft – und es wäre auch nicht zu Ende gebracht,
bevor die App geschlossen wird. Gestaffelt (siehe oben) ist ein ganzes
Land dagegen zu haben, und Stufe 13 flach ebenfalls.

Die Größenangabe vorab ist grob geschätzt. Eine Kachel Innenstadt ist ein
Vielfaches einer Kachel Feld, und keine der beiden ist bekannt, bevor sie
geladen ist.

## Eine Datei selbst herstellen

[Planetiler](https://github.com/onthegomap/planetiler) erzeugt aus
OpenStreetMap-Daten ein Archiv im richtigen Schema und schreibt PMTiles
direkt:

```bash
java -Xmx8g -jar planetiler.jar --download --area=germany \
  --output=germany.pmtiles
```

`--area` nimmt jeden Namen, den Geofabrik führt – ein Bundesland oder eine
Region ist deutlich kleiner und für den Zweck meist genug. Ein ganzes Land
liegt bei mehreren Gigabyte.

Wer schon eine `.mbtiles` im OpenMapTiles-Schema hat, wandelt sie mit dem
[PMTiles-Werkzeug](https://github.com/protomaps/PMTiles) um:

```bash
pmtiles convert germany.mbtiles germany.pmtiles
```

## Wohin damit

Die Datei bleibt, wo sie ist. PreppSuite kopiert sie nicht – bei mehreren
Gigabyte wäre eine zweite Kopie auf einem Telefon der Unterschied zwischen
„passt" und „passt nicht". Gemerkt wird nur, wo sie liegt.

Gelesen wird in Stücken von wenigen Kilobyte, eines pro Kachel. Die ganze
Datei wird nie geladen.

Unter Android geht das über die Storage Access Framework, wie beim
gemeinsamen Ordner: die Freigabe wird dauerhaft genommen und überlebt den
Neustart. Verloren geht sie bei einer Neuinstallation; dann wird die Datei
einmal neu gewählt.

## Grenzen

**Ein Kartenbild, hell.** Mitgeliefert wird der OpenMapTiles-Stil des
Renderers (abgeleitet von OSM Liberty). Es gibt keine dunkle Fassung – die
Karte bleibt hell, auch im dunklen Erscheinungsbild der App.

**Keine Symbole.** Der Stil verweist für Piktogramme auf eine Bilddatei im
Netz, die nicht mitgeliefert wird. Beschriftungen werden gezeichnet,
Piktogramme an Punkten nicht.

**Kein Höhenrelief.** Der Stil bringt eine Reliefschicht mit, die von einem
Webserver kommt. Sie ist ausgebaut: eine Karte, die offline funktionieren
soll, hat keine Ebene zu enthalten, die ins Netz greift.

**Nur so weit wie das Archiv reicht.** Außerhalb des heruntergeladenen
Ausschnitts bleibt die Karte leer – die App fragt dort nicht ersatzweise
das Netz. Die Zoomstufen, die ein Archiv hergibt, stehen in den
Einstellungen.

**iOS ist ungeprüft.** Die Dateiauswahl legt dort wie unter Android eine
Kopie an; ob der Weg trägt, ist nicht ausprobiert. Ausgeliefert wird die
App für iOS ohnehin nicht.

## Lizenzen

Die Kartendaten stammen von OpenStreetMap (ODbL). Das Kartenbild stammt von
OpenMapTiles (CC-BY 4.0) über den Renderer. Beide werden auf der Karte
genannt, sobald ein Archiv in Benutzung ist.
