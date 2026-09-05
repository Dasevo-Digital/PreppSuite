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

## Eine Datei herstellen

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
