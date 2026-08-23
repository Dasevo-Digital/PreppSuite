# PreppSuite

Vorrats- und Notfallplanung für den eigenen Haushalt – selbst betrieben,
ohne fremden Dienst dazwischen.

PreppSuite hält fest, was an Vorräten da ist, was fehlt und was demnächst
abläuft, und stellt das neben die amtlichen Warnungen für die eigene
Region. Alle Daten liegen auf dem eigenen Server; es gibt keinen zentralen
Anbieter, bei dem ein Konto nötig wäre.

Die App arbeitet vollständig offline. Was auf dem Gerät eingetragen wird,
steht sofort dort und wird abgeglichen, sobald der Server erreichbar ist –
nicht umgekehrt. Ein Ausfall der Verbindung, gerade in der Lage, für die
man vorsorgt, macht die eigenen Bestände also nicht unlesbar.

## Was sie kann

**Vorräte.** Artikel mit Menge, Einheit, Lagerort, Mindestbestand und
Ablaufdatum. Erfassung per Barcode über Open Food Facts, wahlweise mit
Foto. Bestehende Listen lassen sich als CSV einlesen, samt Behandlung
fehlerhafter Zeilen. Kategorien: Wasser, Lebensmittel, Medizin, Werkzeug,
Dokumente, Energie, Hygiene, Sonstiges. Vor dem Ablaufdatum erinnert die
App mit einstellbarem Vorlauf; Verbrauchtes lässt sich direkt aus der
Liste abbuchen.

**Vorrats-Rechner.** Rechnet den Bestand gegen die Empfehlung des BBK –
2 Liter Trinkwasser und 2200 kcal pro Person und Tag – für eine
einstellbare Zahl an Tagen und Personen.

**Checklisten.** Drei mitgelieferte Listen – Wasser, Lebensmittel und
Erste Hilfe, angelehnt an die amtlichen Empfehlungen – dazu beliebig viele
eigene. Einzelne Punkte lassen sich mit einem Vorratsartikel verknüpfen.

**Budget.** Was die Vorsorge gekostet hat, nach Kategorie. Dazu ein
PDF-Bericht der fehlenden Ausrüstung – der Bestände also, die unter ihrem
Mindestbestand liegen.

**Warnungen.** Amtliche Meldungen für die eigene Region, im Banner über
allen Ansichten und als Verlauf. Quellen sind das BBK über
warnung.bund.de – alle sechs Kanäle, von MoWaS und DWD über Katwarn und
Biwapp bis Hochwasser und Polizei – sowie MeteoAlarm für 18 europäische
Länder. Der Server fragt alle 15 Minuten ab und filtert BBK-Warnungen bis
auf Kreisebene, sodass ein Haushalt nicht die Meldungen des halben Landes
sieht.

**Schutzräume.** Karte mit Schutzräumen und Bunkern aus OpenStreetMap und
der WWBOTA-Datenbank, nach Entfernung und nach Belastbarkeit der Angabe
filterbar.

**Haushalt.** Mehrere Personen teilen sich Bestände, Listen und Budget.
Beitritt über einen achtstelligen Einladungscode, dessen Zeichenvorrat
verwechselbare Zeichen auslässt. Wer den Haushalt angelegt hat, kann den
Code erneuern und Mitglieder entfernen.

Oberfläche auf Deutsch und Englisch, helles und dunkles Erscheinungsbild.

## Selbst betreiben

Der Server braucht PostgreSQL und Redis. Für die Entwicklung liegt beides
als Container bei:

```bash
cd preppsuite_server
docker compose up -d
dart bin/main.dart --apply-migrations
```

Er lauscht dann auf Port 8080. Für den Dauerbetrieb liegt ein
`Dockerfile` bereit; die Zugangsdaten gehören in
`config/passwords.yaml` beziehungsweise in die Umgebung.

Die App zeigt ab Werk auf `http://localhost:8080`. Für eine andere Adresse
wird sie mit dieser gebaut – die Adresse steckt fest in der fertigen
Fassung:

```bash
cd preppsuite_flutter
flutter build macos --release --dart-define=SERVER_URL=https://preppsuite.example.com/
```

Fertige macOS-Fassungen liegen unter *Releases*. Sie sind nicht mit einem
gekauften Zertifikat signiert; Gatekeeper meldet sich beim ersten Start,
über **Rechtsklick → Öffnen** startet die App trotzdem.

## Aufbau

| Verzeichnis | Inhalt |
| --- | --- |
| `preppsuite_server` | Serverpod-Backend: Endpunkte, Dienste, Datenmodelle, Warnfeed-Abruf |
| `preppsuite_client` | Erzeugter Client. Wird nicht von Hand bearbeitet |
| `preppsuite_flutter` | Die App |

Die Anwendung liest ausschliesslich aus einer lokalen Datenbank auf dem
Gerät; der Abgleich mit dem Server läuft daneben und schreibt in dieselbe
Datenbank. Änderungen bekommen auf dem Gerät eine Kennung, werden als
offen markiert und beim nächsten Abgleich übertragen; gelöscht wird nur
als Merker, damit die Löschung auch auf den anderen Geräten ankommt. Bei
gleichzeitiger Änderung gewinnt die jüngere.

Die Annahmen, die dahinterstehen, sind in [`CLAUDE.md`](CLAUDE.md)
aufgeschrieben, die Warnquellen in
[`docs/warning-feeds.md`](docs/warning-feeds.md).

## Entwicklung

```bash
flutter pub get                                   # im Wurzelverzeichnis
flutter analyze                                   # alle drei Pakete
dart format --output=none --set-exit-if-changed .

cd preppsuite_flutter && flutter test             # App, ohne Server
cd preppsuite_server && docker compose up -d && dart test
```

Nach jeder Änderung an einer Modellbeschreibung (`*.spy.yaml`):

```bash
cd preppsuite_server && serverpod generate
```

## Lizenz

Der Projektcode steht unter der Lizenz in [LICENSE](LICENSE).

Die Daten stammen aus fremden Quellen und stehen unter deren eigenen
Bedingungen: Kartenkacheln und Schutzraum-Einträge von OpenStreetMap
(ODbL, Namensnennung in der Karte), Produktdaten von Open Food Facts
(ODbL), Warnungen vom BBK und von MeteoAlarm, Ortssuche über Nominatim.
Die mitgelieferte Schrift Noto Sans steht unter der SIL Open Font License
(`preppsuite_flutter/assets/fonts/OFL.txt`).

## Stand

Die App ist im Alltag benutzbar, einige Kanten sind aber bekannt:

- MeteoAlarm-Warnungen lassen sich nicht nach Region filtern – ihre
  Gebietsangabe ist freier Text ohne Schlüssel. Sie gelten deshalb für
  jeden Haushalt des Landes. BBK-Warnungen werden dagegen bis auf
  Kreisebene gefiltert; genauer gibt die Quelle nichts her.
- Keine Quelle liefert ein Ablaufdatum. Warnungen werden beendet, wenn sie
  aus einem vollständigen Abruf verschwinden – solange kein Abruf gelingt,
  bleiben sie stehen. Einzelheiten in `docs/warning-feeds.md`.
- Warnmeldungen erscheinen nur, solange die App läuft – es gibt keinen
  Push-Dienst im Hintergrund. Ablauf-Erinnerungen für Vorräte werden
  dagegen im Voraus eingeplant und erreichen das Gerät auch bei
  geschlossener App.
- Fotos zu Vorratsartikeln bleiben auf dem Gerät, auf dem sie aufgenommen
  wurden. Der Abgleich überträgt Text, keine Dateien.
- Veröffentlicht wird bisher nur eine macOS-Fassung. Die übrigen
  Plattformen sind angelegt, aber nicht regelmässig gebaut.
