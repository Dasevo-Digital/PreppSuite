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

Da keine Quelle ein Ablaufdatum liefert, beendet der Poller Warnungen
selbst: Was in einem Durchlauf, in dem **alle** Quellen geantwortet haben,
nicht mehr auftaucht, bekommt `expires` auf den Zeitpunkt der Feststellung.
Die Unterscheidung zwischen „Quelle sagt: nichts aktiv" und „Quelle war
nicht erreichbar" ist dafür entscheidend — deshalb liefert
`BbkClient.fetchAll` ein `complete`-Kennzeichen, und bei einem einzigen
fehlgeschlagenen Abruf unterbleibt das Beenden. Sonst würde eine einzelne
schlechte Antwort sämtliche aktiven Warnungen stillschweigend zurückziehen.

## Bekannte Einschränkungen

- **MeteoAlarm-Warnungen werden nicht nach Region gefiltert.** Ihr
  `regionKey` ist freier `areaDesc`-Text ohne Schlüssel, der sich mit
  einem Kreis- oder Bundeslandschlüssel vergleichen liesse. Sie gelten
  daher für jeden Haushalt des Landes als relevant.
- **Kein Ablaufdatum aus der Quelle.** Weder `mapData.json` noch
  `dashboard/{ARS}.json` liefert eines — das `valid`-Feld des Dashboards
  ist ein Boolescher Wert, kein Zeitpunkt. Ersatzweise beendet der Poller
  Warnungen, die aus einem vollständigen Abruf verschwunden sind (siehe
  oben). Eine Warnung, die die Quelle stillschweigend zurückzieht, ohne
  dass ein Abruf gelingt, bleibt bis zum nächsten vollständigen Durchlauf
  aktiv.
- **Genauer als Kreisebene geht nicht.** Die API liefert für die letzten
  sieben ARS-Stellen immer Nullen; ein Gemeindeschlüssel brächte kein
  feineres Ergebnis.
