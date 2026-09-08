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
