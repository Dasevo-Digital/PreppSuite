# Einkaufsliste als Datei

Die Einkaufsliste (Vorräte → Einkaufsliste) lässt sich als JSON-Datei
exportieren, damit eine Einkaufs-App die fehlenden Artikel einzeln
übernehmen kann. „Liste kopieren“ bleibt daneben bestehen: Das ist Text
für Menschen, die Datei ist für Programme.

- **iPhone und Android:** über das Teilen-Menü, mit „In Dateien sichern“
  und jeder App, die JSON-Dateien annimmt.
- **Mac, Windows, Linux:** über einen Speichern-Dialog.

Der Knopf erscheint nur, wenn mindestens ein Artikel unter seiner
Mindestmenge liegt. Eine leere Datei sähe in der empfangenden App aus wie
eine Liste, die ohne Inhalt angekommen ist.

Erzeugt wird sie in
`preppsuite_flutter/lib/features/inventory/application/shopping_list_export.dart`.

## Dateiname

```
preppsuite-einkaufsliste-JJJJ-MM-TT.json
```

Das Datum ist der Tag des Exports. Zwei Exporte überschreiben sich so nicht
gegenseitig, und der ältere bleibt erkennbar.

## Aufbau, Version 1

```json
{
  "format": "preppsuite-einkaufsliste",
  "version": 1,
  "created": "2026-10-10T09:30:00.000Z",
  "language": "de",
  "items": [
    {
      "name": "Reis",
      "quantity": "1,5 kg",
      "amount": 1.5,
      "unit": "kg",
      "minimum": 2,
      "supplyCategory": "food"
    }
  ],
  "target": {
    "days": 10,
    "met": false,
    "waterLiters": 34,
    "kcal": 12000
  }
}
```

| Feld | Bedeutung |
|---|---|
| `format` | Immer `preppsuite-einkaufsliste`. Ein Leser prüft das zuerst, bevor er irgendein anderes Feld glaubt. |
| `version` | Steigt nur bei einer Änderung, die ein Leser von Version 1 falsch verstehen würde. Neue Felder kommen ohne neue Version dazu; ein Leser übergeht, was er nicht kennt. |
| `created` | Zeitpunkt des Exports, UTC, ISO 8601. |
| `language` | Sprache der App beim Export (`de`, `en`, `es`). In ihr sind `quantity` und die Artikelnamen geschrieben. |
| `items` | Die Artikel unter ihrer Mindestmenge, der knappste Anteil zuerst, so wie die App sie zeigt. |
| `items[].name` | Name des Artikels, wie im Vorrat eingetragen. |
| `items[].quantity` | Fehlende Menge mit Einheit, fertig formatiert in `language`, etwa `1,5 kg`. Für ein freies Mengenfeld gedacht. Ohne Einheit steht nur die Zahl da. |
| `items[].amount` | Fehlende Menge als Zahl. Ganze Zahlen als Ganzzahl, sonst auf zwei Stellen gerundet. |
| `items[].unit` | Einheit, wie im Vorrat eingetragen (`kg`, `l`, `Stück` …). Kann leer sein. |
| `items[].minimum` | Die Mindestmenge, gegen die gerechnet wurde. |
| `items[].supplyCategory` | Vorratskategorie in PreppSuite: `water`, `food`, `medical`, `tools`, `documents`, `energy`, `hygiene`, `other`. Das ist **kein** Gang im Supermarkt; den schlägt die empfangende App selbst vor. |
| `target` | Das Haushaltsziel für `days` Tage. Steht absichtlich **neben** den Artikeln, nicht unter ihnen (siehe unten). |
| `target.met` | Ob Wasser und Kalorien für `days` Tage gedeckt sind. |
| `target.waterLiters` | Liter Trinkwasser, die zum Ziel noch fehlen; 0, wenn gedeckt. |
| `target.kcal` | Kilokalorien, die zum Ziel noch fehlen; 0, wenn gedeckt. |

## Warum das Haushaltsziel keine Zeile ist

„34 l Wasser fehlen noch“ gilt für den Haushalt, nicht für einen Artikel.
Ein Wasser-Artikel unter seiner Mindestmenge zählt schon auf dieses Ziel
ein. Stünden beide als Zeilen auf der Einkaufsliste, würde dasselbe Wasser
zweimal gekauft. Eine empfangende App kann das Ziel als Hinweis zeigen oder
selbst eine Zeile daraus machen, wenn sie die Doppelung bedenkt.

## Was nicht mitkommt

Lagerort, Ablaufdaten, Notizen und Fotos. Sie gehören zum Vorrat, nicht auf
einen Einkaufszettel. Wer den ganzen Vorrat braucht, nimmt den CSV-Export
unter Vorräte → Menü.
