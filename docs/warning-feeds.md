# Warnfeed-Integration

Referenzdokumentation für die beiden externen Warnquellen, die
`WarningPollFutureCall` alle 15 Minuten abfragt. Felder unten sind gegen die
echten, live abgerufenen APIs verifiziert (Stand 2026-08-14) — Beispieldaten
liegen unter `preppsuite_server/test/fixtures/`.

## BBK (warnung.bund.de)

Öffentlich, kein API-Key nötig. Abgefragt werden alle sechs
veröffentlichten Quellen: `mowas` (Modulares Warnsystem, Bund), `dwd`
(Wetter), `katwarn`, `biwapp`, `lhp` (Hochwasser) und `police`. Alle
antworten mit demselben Array-Schema, ein Parser genügt.

```
GET https://warnung.bund.de/api31/{source}/mapData.json
```

Antwort: flaches JSON-Array, ganz Deutschland, keine Regions-Filterung
serverseitig möglich (siehe „Bekannte Einschränkungen" unten). Beispiel:

```json
{
  "id": "mow.DE-HE-MKK-W220-20260811-001",
  "version": 19,
  "startDate": "2026-08-11T08:30:54+02:00",
  "severity": "Minor",
  "urgency": "Immediate",
  "type": "Alert",
  "i18nTitle": { "de": "Waldbrand im Bereich ...", "en": "Forest fire", ... },
  "transKeys": { "event": "BBK-EVC-077" }
}
```

- `severity` nutzt bereits die CAP-Skala (Minor/Moderate/Severe/Extreme) —
  identisch zu MeteoAlarm, daher nur `.toLowerCase()` nötig.
- Kein `expires`-Feld in `mapData.json` — `Warning.expires` bleibt für
  BBK-Warnungen immer `null`.
- `id` kodiert das Bundesland, in zwei Formen: `mow.DE-HE-...` (mowas,
  dwd) und `lhp.LHP.NW.nw86768` (lhp, police). Beide werden als
  `regionKey` extrahiert, die zweite nur, wenn die zwei Buchstaben ein
  bekanntes Bundeslandkürzel sind — ein falscher `regionKey` würde die
  Warnung vor den betroffenen Haushalten verbergen, ein fehlender zeigt
  sie allen.

## MeteoAlarm (feeds.meteoalarm.org)

Öffentlich, kein API-Key. Deckt die EUMETNET-Mitgliedschaft ab (auch
Nicht-EU-Länder wie Schweiz, Norwegen, UK).

```
GET https://feeds.meteoalarm.org/feeds/meteoalarm-legacy-atom-{country-slug}
```

`{country-slug}` ist der englische Ländername, klein geschrieben, Leerzeichen
durch Bindestriche ersetzt (`germany`, `united-kingdom`, ...). Mapping in
`meteoAlarmCountrySlugs` (server) — von Hand synchron gehalten mit
`warningFeedCountries` (Flutter-App), da beide Listen kurz sind und selten
wachsen.

Atom-Feed mit CAP-1.2-Namespace (`xmlns:cap="urn:oasis:names:tc:emergency:cap:1.2"`),
ein `<entry>` pro Warnung/Gebiet:

```xml
<entry>
  <cap:areaDesc>Stadt Frankfurt am Main</cap:areaDesc>
  <cap:event>strong heat</cap:event>
  <cap:sent>2026-08-14T07:28:00+00:00</cap:sent>
  <cap:expires>2026-08-15T17:00:00+00:00</cap:expires>
  <cap:onset>2026-08-14T09:00:00+00:00</cap:onset>
  <cap:severity>Minor</cap:severity>
  <cap:identifier>2.49.0.0.276.0.DWD.PVW.1786692480000.e1e9....MUL</cap:identifier>
  <title>Yellow High-temperature Warning issued for Germany - Stadt Frankfurt am Main</title>
</entry>
```

- `cap:identifier` → `Warning.externalId` (dedupe-Schlüssel).
- `cap:onset` → `Warning.effective`; `cap:sent`/`cap:expires` direkt übernommen.
- `cap:areaDesc` → sowohl `Warning.regionKey` als auch `Warning.description`.
- Bewusst das **Legacy-Atom-Format**, nicht RSS (seit Anfang 2026 deprecated).

## Normalisierung & Dedupe

`WarningNormalizer` upserted nach `(source, externalId)`. Ein bestehender
Eintrag wird nur überschrieben, wenn das neue `sent` echt neuer ist —
unverändert erneut abgerufene Warnungen verursachen kein `updatedAt`-Update
und lösen daher auch keinen unnötigen Client-Pull-Delta aus.

`rawPayload` wird als JSON-**String** gespeichert (nicht als natives
JSON/`Map`-Feld) — Serverpods Modellsystem unterstützt keinen `dynamic`-Typ
in `.spy.yaml`-Feldern.

## Regionsfilterung und Ablauf

Zusätzlich zum bundesweiten Abruf fragt der Poller `dashboard/{ARS}.json`
für jeden Kreis ab, den ein Haushalt als eigene Region oder als
zusätzliches Abo führt. Warnungen aus diesem Abruf tragen den genauen
fünfstelligen Kreisschlüssel als `regionKey` statt des groben
Bundeslandkürzels. `WarningService.isWarningRelevant` entscheidet damit
je Haushalt, was überhaupt ausgeliefert wird.

Da die BBK-Endpunkte kein Ablaufdatum liefern, beendet der Poller deren
Warnungen selbst: Was in einem vollständigen **BBK-Abruf**
nicht mehr auftaucht, bekommt `expires` auf den Zeitpunkt der Feststellung.
Die Unterscheidung zwischen „Quelle sagt: nichts aktiv" und „Quelle war
nicht erreichbar" ist dafür entscheidend — deshalb liefert
`BbkClient.fetchAll` ein `complete`-Kennzeichen, und bei einem einzigen
fehlgeschlagenen Abruf unterbleibt das Beenden. Sonst würde eine einzelne
schlechte Antwort sämtliche aktiven Warnungen stillschweigend zurückziehen.
MeteoAlarm-Meldungen übernehmen hingegen `cap:expires` aus dem Feed und
laufen anhand dieses Zeitpunkts ab.

## MeteoAlarm-Gebiete auf Kreise abbilden

`areaDesc` nennt Gebiete in Worten — „Kreis Ahrweiler", „Stadt Ulm" —,
ein Haushalt folgt fünfstelligen Kreisschlüsseln. Bis 0.14.0 wanderte der
Text unverändert in `regionKey`. Er konnte dort nur scheitern, und ein
Schlüssel, der nicht passt, liest sich nicht als „woanders", sondern als
„nirgends": `isWarningRelevant` verwarf jede dieser Warnungen.

**Gemessen an einem echten Feed:** 121 Unwetterwarnungen, von denen keine
einzige einen Haushalt erreichte, der eine Region eingestellt hatte.

Die Brücke ist die **Warnzellenliste des DWD**, die dieselben Gebiete
benennt — alle achtzig Namen des Feeds trafen sie exakt — und deren
Zellkennung den Kreisschlüssel trägt: eine Zelle, die mit `1` oder `8`
beginnt, ist `1`/`8`, dann fünf Stellen Kreis, dann drei weitere.
`tool/dwd_warncells.py` erzeugt daraus `assets/dwd_warncells.csv`
(11.728 Gebiete, 365 KB).

`DwdAreas.regionKeyFor` liefert:

1. den **Kreisschlüssel**, wo die Zelle einen trägt,
2. sonst den Basisnamen vor einem `" - "` — der Feed teilt Kreise in
   Abschnitte („Kreis Aurich - Küste"), die selbst keinen Schlüssel
   haben, deren Kreis aber schon,
3. sonst das **Bundesland**,
4. sonst `null`, also „betrifft alle".

Punkt 4 ist kein Fehlschlag, sondern Absicht. See- und Küstengebiete
(„Elbe von Hamburg bis Cuxhaven") haben weder Kreis noch Land; sie zu
verwerfen wäre genau der Fehler, den diese Zuordnung behebt.

Mit dem gemessenen Feed sieht ein Haushalt in Braunschweig **9 von 121**
Warnungen statt keiner — acht davon die nicht zuzuordnenden Seegebiete.

## Warnungen ohne Bundesland in der Kennung

Die meisten Quellen tragen das Land in der Kennung: `mow.DE-HE-KS-…`
ergibt Hessen, `lhp.LHP.NW.…` Nordrhein-Westfalen. **KATWARN nicht** —
dessen Kennungen sehen aus wie
`kat.6aa7f6b0995efd5eae12108e_public_topics` und sagen gar nichts.

Für die wird der Reihe nach versucht:

1. Die **Gebietsbeschreibung**, wenn sie einstimmig ein Land nennt
   („Teile von LKr. Alzey-Worms, LKr. Bad Dürkheim, Rhein-Pfalz-Kreis und
   Umland" → RP).
2. Die **absendende Stelle** aus dem Titel. KATWARN-Titel sind maschinell
   gebaut: `<Absender> meldet: <Warnung>`.

Beide liefern nur ein **Bundesland**, nie einen Kreis. Aus Prosa einen
Kreis abzuleiten hieße, ein falsch gelesenes Wort könnte eine Warnung vor
genau dem Kreis verbergen, um den es geht.

Warum es Schritt 2 überhaupt gibt: Am 14.09.2026 erreichte eine schwere
Trinkwasserwarnung des Vogelsbergkreises einen Haushalt in Braunschweig.
Ihre ganze Ortsangabe lautet „Teile von Lauterbach", und das ist nicht
auflösbar — die Warncell-Tabelle kennt ein Lauterbach in
Baden-Württemberg, eines in Thüringen, und führt das hessische unter
„Stadt Lauterbach (Hessen)". Damit blieb die Warnung unverortet, und
unverortet heißt „betrifft alle". Der Titel dagegen sagt
„Vogelsbergkreis meldet: …", und dieser Name steht genau einmal in der
Tabelle.

Der Absender ist die schwächere Aussage — er sagt, *wer* gewarnt hat,
nicht *wo* — und wird deshalb zuletzt versucht. Ist er keine Ortsangabe
(„Erdbebendienst Südwest meldet: …"), findet die Tabelle nichts und die
Warnung bleibt, wo sie war.

**Eine bereits gespeicherte, unverortete Warnung wird beim nächsten
Abruf nachträglich verortet.** Sonst hülfe eine verbesserte Zuordnung
immer erst der nächsten Warnung, während die auf dem Bildschirm ihre
alte Lesart behielte. Nachträglich verortet wird nur von „gar nichts" zu
„etwas", nie ein schon vorhandener Schlüssel überschrieben, und es löst
keine zweite Benachrichtigung aus.

## Die Lagekarte befragen

Die CAP-Flächen einer Warnung liegen als Text in `polygonsJson` und
werden von `warning_polygon_codec.dart` gelesen — einmal, für alle
Bildschirme. Bis 1.8.8 hatte die Warnungsliste eine wortgleiche private
Kopie dieser Funktion; eine Korrektur an einer der beiden hätte die
andere nicht erreicht.

Derselbe Codec beantwortet inzwischen die zweite Frage an dieselben
Daten: nicht „zeichne diese Fläche", sondern „welche dieser Flächen
liegt über diesem Punkt". `ringContains` zählt dafür, wie oft ein nach
Osten laufender Strahl die Kanten schneidet — eine ungerade Zahl heißt
innerhalb. Längengrad gilt dabei als x, Breitengrad als y. Auf einer
Kugel ist das falsch und auf der Größe eines Landkreises belanglos: der
Fehler bleibt weit unter der Auflösung der Umrisse, die der Feed liefert.

In der Warnlagekarte öffnet ein Tipp deshalb eine Auskunft für genau
diese Stelle, mit der Handlungsanweisung zuerst. Liegt dort keine der
angezeigten Flächen, sagt die Karte das, statt stumm zu bleiben.

**Das ist nicht dieselbe Frage wie „betrifft mich das".** `polygonsCover`
prüft die gezeichnete Fläche; ob eine Warnung für den eigenen Haushalt
gilt, entscheidet `isWarningRelevant` über den Regionsschlüssel. Eine
Warnung ohne Geometrie deckt keinen Punkt ab, auch wenn sie alle angeht.

## Trinkwasser

Für „das Trinkwasser ist betroffen" gibt es **keinen CAP-Code**. Die
Meldungen kommen als KATWARN-Nachrichten über den BBK-Feed, mit maschinell
gebautem Titel `<Absender> meldet: <Warnung>` — oben steht der am Live-Feed
bestätigte Fall „Vogelsbergkreis meldet: Warnung Trinkwasserunfall". Die
Art der Warnung ist Freitext dessen, der sie geschickt hat.

`drinking_water_warning.dart` erkennt sie deshalb an Wörtern, und das ist
eine Schätzung. Sie ist so gebaut, dass sie in die harmlose Richtung
irrt: **sie ergänzt, sie verbirgt nie.** Ein Treffer legt eine zusätzliche
Karte dazu — wie lange der eigene Vorrat reicht und wo die heruntergeladene
Karte Trinkwasser kennt. Ein Fehltreffer kostet eine Karte neben einer
Warnung, die ohnehin vollständig angezeigt wird; ein verpasster Treffer
kostet nur diese Karte. Nichts wird herausgefiltert und keine Warnung
umformuliert.

**Was die App dabei nicht sagt, ist, was mit dem Wasser zu tun ist.**
Abkochzeiten wurden für diese App geprüft und verworfen: CDC, WHO und UBA
nennen unterschiedliche, und eine davon auszuliefern wäre genau die
erfundene Skala, die diese App nicht ausgibt. Auf der Karte steht die
Anweisung der Behörde selbst, und daneben ein Satz, der sagt, dass die App
dazu keine eigenen Zahlen hat.

## Bekannte Einschränkungen

- **MeteoAlarm-Warnungen außerhalb Deutschlands werden nicht nach Region
  gefiltert.** Ihr `areaDesc` ist Freitext ohne Schlüssel. Ihr
  `regionKey` bleibt deshalb `null` — was „betrifft alle" heißt und die
  sichere Lesart ist.

  Für Deutschland gibt es seit 0.15.0 eine Zuordnung, siehe unten.
- **Kein Ablaufdatum aus den BBK-Endpunkten.** Weder `mapData.json` noch
  `dashboard/{ARS}.json` liefert eines — das `valid`-Feld des Dashboards
  ist ein Boolescher Wert, kein Zeitpunkt. Ersatzweise beendet der Poller
  Warnungen, die aus einem vollständigen Abruf verschwunden sind (siehe
  oben). Eine Warnung, die die Quelle stillschweigend zurückzieht, ohne
  dass ein Abruf gelingt, bleibt bis zum nächsten vollständigen Durchlauf
  aktiv.
- **Genauer als Kreisebene geht nicht.** Die API liefert für die letzten
  sieben ARS-Stellen immer Nullen; ein Gemeindeschlüssel brächte kein
  feineres Ergebnis.
