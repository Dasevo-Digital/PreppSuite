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
→ Karte herunterladen** zeigt eine Karte; verschoben wird sie auf das
Gebiet, das offline gebraucht wird, und geladen wird genau der sichtbare
Ausschnitt. Ein Schieberegler bestimmt, wie tief: Stufe 12 zeigt
Ortschaften und Hauptstraßen, Stufe 14 einzelne Straßen und Gebäude. Die
Kachelzahl steht daneben, bevor irgendetwas passiert.

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

### Grenzen, und warum es sie gibt

Über 60 000 Kacheln lehnt die App ab. Das ist keine technische Grenze,
sondern eine Anstandsgrenze: die Kacheln kommen von einem öffentlichen
Server, den andere mitbenutzen, und ein Download dieser Länge wäre ohnehin
nicht zu Ende gebracht, bevor die App geschlossen wird. Zum Vergleich –
ganz Deutschland bis Stufe 12 sind rund 20 000 Kacheln und geht; bis Stufe
14 wären es über 315 000 und geht nicht. Ein Kreis oder eine Stadt bis
Stufe 14 dagegen ist eine Sache von Minuten.

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
