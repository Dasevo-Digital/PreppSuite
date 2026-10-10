# Erste-Hilfe-Anleitungen

Hier steht der Text der Erste-Hilfe-Anleitungen, eine Datei je Sprache:
`de.md` und `en.md`. Wer die Anleitungen fachlich prüft oder übersetzt,
braucht nur diese Dateien, keinen Programmcode.

Die App liest die Dateien nicht selbst. `tool/first_aid/generate.dart`
erzeugt daraus die Dart-Dateien, die in die App einkompiliert werden.
Erste Hilfe muss auch dann aufgehen, wenn sonst nichts geht, und ein
Einlesen beim Start wäre ein neuer Weg, auf dem das scheitern könnte.

## Ablauf

1. Text in `de.md` oder `en.md` ändern.
2. Im Ordner `preppsuite_flutter/` ausführen:

   ```
   dart run tool/first_aid/generate.dart
   ```

3. `flutter test test/features/first_aid` ausführen.

Der Test schlägt fehl, solange Markdown und erzeugter Code nicht
übereinstimmen, und ebenso, wenn eine Sprache eine Anleitung oder einen
Schritt weniger hat als die deutsche Fassung.

## Aufbau

Kommentare stehen zwischen `<!--` und `-->`. Dort steht, warum etwas so
dasteht, etwa nach welcher Leitlinie oder warum etwas bewusst fehlt. Die
App zeigt sie nicht an.

Jede Anleitung beginnt mit `## ` und ihrer Kennung. Die Kennung ist in
allen Sprachen gleich und ändert sich nie: heruntergeladene Videos
verweisen darauf. Die Reihenfolge der Anleitungen ist die Reihenfolge auf
dem Bildschirm, nach Dringlichkeit.

```markdown
## emergency-call
- group: basics
- title: Notruf absetzen
- when: Immer zuerst, sobald jemand ernsthaft in Gefahr ist.
- callFirst: true
- drawing: compressionPoint
- pacer: true
- source: Bundesamt für Bevölkerungsschutz und Katastrophenhilfe

### steps
1. Wo ist es passiert?
   Ort, Straße, Hausnummer, Stockwerk.
2. Wie viele Verletzte?

### cautions
- Nicht auflegen, bevor die Leitstelle es sagt.

### facts
- Polizei: 110
```

| Feld | Bedeutung |
|---|---|
| `group` | Abschnitt der Liste: `basics`, `lifeThreatening`, `injury`, `illness`, `environment`, `mentalDistress`. |
| `title` | Name der Anleitung. |
| `when` | Eine Zeile, woran man erkennt, dass dies die richtige Anleitung ist. |
| `callFirst` | `true`, wenn 112 vor den Schritten kommt. Sonst weglassen. |
| `drawing` | Eine der Zeichnungen der App: `compressionPoint`, `recoveryPosition`, `choking`, `bleeding`, `face`. Sonst weglassen. |
| `pacer` | `true`, wenn die Anleitung den Takt für die Herzdruckmassage anbietet. Sonst weglassen. |
| `source` | Quelle, wird auf dem Bildschirm genannt. Pflicht. |

- **`### steps`**: nummerierte Schritte, lückenlos ab 1. Eine eingerückte
  Zeile (drei Leerzeichen) direkt darunter ist die Erläuterung zum Schritt:
  Zahl, Tiefe, Anzahl.
- **`### cautions`**: was es schlimmer macht, je Zeile mit `- `.
- **`### facts`**: Werte, die man beim Helfen vor sich haben will, als
  `- Bezeichnung: Wert`. `- {poisonCentres}` steht allein für die Liste der
  Giftnotrufe aus `poison_centres.dart`, die für alle Sprachen gleich ist.

Jeder Text steht auf genau einer Zeile. Eine Zeile, die der Generator
nicht kennt, ist ein Fehler mit Zeilennummer und wird nie übergangen: ein
übergangener Warnhinweis wäre einer, den niemand sieht.
