# Warnfeed-Integration

Referenzdokumentation für die beiden externen Warnquellen, die
`WarningPollFutureCall` alle 15 Minuten abfragt. Felder unten sind gegen die
echten, live abgerufenen APIs verifiziert (Stand 2026-08-14) — Beispieldaten
liegen unter `preppsuite_server/test/fixtures/`.

## BBK (warnung.bund.de)

Öffentlich, kein API-Key nötig. v1 fragt `mowas` (Modulares Warnsystem,
Bund) und `dwd` (Wetter) ab; `katwarn`/`biwapp`/`lhp`/`police` folgen
demselben Schema und können ohne Parser-Änderungen ergänzt werden.

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
- `id` kodiert das Bundesland (`DE-HE-...` → Hessen), das wird best-effort
  als `regionKey` extrahiert, aber nicht für die Pull-Filterung genutzt.

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

## Bekannte Einschränkungen (v1)

- **Keine präzise Regionsfilterung**: `mapData.json` liefert ganz
  Deutschland auf einmal, ohne Filterparameter. `Household.regionKey` wird
  aktuell nur informativ gespeichert, nicht zur Filterung genutzt — jeder
  Haushalt mit `countryCode = DE` sieht alle deutschen BBK-Warnungen. Eine
  präzisere Lösung bräuchte den `dashboard/{ARS}.json`-Endpunkt (erfordert
  eine gültige 12-stellige Amtliche-Regionalschlüssel-Zuordnung je Haushalt
  — als spätere Verfeinerung vorgemerkt, nicht Teil von v1).
- **Kein `expires` für BBK-Warnungen** — das Banner/die Historie zeigen sie
  daher dauerhaft als "aktiv", bis der Poller sie nicht mehr in der
  Quelle findet (kein automatisches Ablaufen).
- Nur `mowas` + `dwd` aktiv; `katwarn`/`biwapp`/`lhp`/`police` sind
  vorbereitet, aber nicht eingebunden.
