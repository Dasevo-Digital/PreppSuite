# PreppSuite

Vorrats- und Notfallplanung für den eigenen Haushalt – vollständig auf dem
eigenen Gerät.

Kein Konto, kein Server, keine Anmeldung. Die App speichert alles lokal und
holt sich nur das, was ohnehin öffentlich ist: amtliche Warnungen vom BBK und
von MeteoAlarm, Produktdaten von Open Food Facts, Karten und Schutzräume von
OpenStreetMap. Sie ist offline vollständig benutzbar.

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
einstellbare Zahl an Tagen und Personen. Die Kalorien kommen beim
Barcode-Scan aus den Nährwerten von Open Food Facts, hochgerechnet auf die
Packungsgrösse.

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

Der Abruf läuft in der App selbst, nicht über einen Server – beide Quellen
sind öffentlich und ohne Schlüssel. Auf Android und iOS läuft er zusätzlich
im Hintergrund weiter, sodass Warnungen auch bei geschlossener App
ankommen. Android hält dabei ein Mindestintervall von 15 Minuten ein; auf
iOS entscheidet das System selbst, wann es den Abruf zulässt, was auch
Stunden dauern kann.

Bewusst ein Überblick, kein Alarm: NINA vom BBK stellt dieselben Meldungen
in rund 30 Sekunden zu. Wer sofort gewarnt werden will, nutzt dafür NINA –
die App sagt das an Ort und Stelle auch selbst.

**Schutzräume.** Karte mit Schutzräumen und Bunkern aus OpenStreetMap und
der WWBOTA-Datenbank, nach Entfernung und nach Belastbarkeit der Angabe
filterbar.

**Haushalt.** Mehrere Personen teilen sich Bestände, Listen und Budget.
Beitritt über einen achtstelligen Einladungscode, dessen Zeichenvorrat
verwechselbare Zeichen auslässt. Wer den Haushalt angelegt hat, kann den
Code erneuern und Mitglieder entfernen.

Oberfläche auf Deutsch und Englisch, helles und dunkles Erscheinungsbild.

## Installieren

Fertige macOS-Fassungen liegen unter *Releases*. Sie sind nicht mit einem
gekauften Zertifikat signiert; Gatekeeper meldet sich beim ersten Start, über
**Rechtsklick → Öffnen** startet die App trotzdem.

Selbst bauen:

```bash
flutter pub get
cd preppsuite_flutter
flutter build macos --release      # oder apk, ios, ...
```

### Android weitergeben

Die Release-APK wird mit dem Debug-Schlüssel signiert, solange kein eigener
vorliegt. Zum Ausprobieren reicht das; zum Weitergeben nicht, denn das
Passwort dieses Schlüssels ist der öffentlich bekannte Wert `android` – jeder
könnte damit eine gefälschte Aktualisierung signieren.

Einen eigenen Schlüssel erzeugen (einmalig, außerhalb des Repositorys):

```bash
keytool -genkeypair -v -keystore ~/.android-keystores/preppsuite-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias preppsuite
```

Dazu `preppsuite_flutter/android/key.properties` mit `storeFile`,
`storePassword`, `keyPassword` und `keyAlias` anlegen – die Datei ist
ignoriert und bleibt lokal. Danach signiert `flutter build apk --release` von
selbst richtig; fehlt sie, warnt der Build und fällt auf den Debug-Schlüssel
zurück.

**Der Schlüssel ist unersetzlich.** Geht er verloren, lässt sich für alle, die
die App installiert haben, nie wieder eine Aktualisierung veröffentlichen.
Keystore und Passwörter gehören an zwei getrennte gesicherte Orte.

Für die Weitergabe über *Releases* lohnt sich `--split-per-abi`: getrennte
Pakete je Prozessorarchitektur, jedes rund ein Drittel der Größe.

Die App trägt die Kennung `de.status403.preppsuite`. Wer eine eigene Fassung
über den App Store verteilen will, braucht eine eigene unter einer Domain, die
er selbst kontrolliert.

## Aufbau

| Verzeichnis | Inhalt |
| --- | --- |
| `preppsuite_server` | Serverpod-Backend: Endpunkte, Dienste, Datenmodelle, Warnfeed-Abruf |
| `preppsuite_client` | Erzeugter Client. Wird nicht von Hand bearbeitet |
| `preppsuite_flutter` | Die App |
| `scripts` | `generate-env.sh` für den ersten Start |
| `docs` | Warnquellen und Push-Benachrichtigungen im Detail |

Die Anwendung liest ausschliesslich aus einer lokalen Datenbank auf dem
Gerät; der Abgleich mit dem Server läuft daneben und schreibt in dieselbe
Datenbank. Änderungen bekommen auf dem Gerät eine Kennung, werden als
offen markiert und beim nächsten Abgleich übertragen; gelöscht wird nur
als Merker, damit die Löschung auch auf den anderen Geräten ankommt. Bei
gleichzeitiger Änderung gewinnt die jüngere.

Im Wurzelverzeichnis liegt `docker-compose.yml` für den Betrieb — Server,
Datenbank und Redis zusammen. Nicht zu verwechseln mit
`preppsuite_server/docker-compose.yaml`, das nur PostgreSQL und Redis für
die Entwicklung startet.

Die Annahmen, die dahinterstehen, sind in [`CLAUDE.md`](CLAUDE.md)
aufgeschrieben, die Warnquellen in
[`docs/warning-feeds.md`](docs/warning-feeds.md) und der Push-Weg in
[`docs/push-notifications.md`](docs/push-notifications.md).

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

- **Teilen zwischen mehreren Personen fehlt derzeit.** Mit dem Server ist es
  weggefallen; der Ersatz über einen gemeinsamen Cloud-Ordner ist noch nicht
  gebaut. Der Datenbestand trägt die dafür nötigen Merkmale bereits (stabile
  Kennungen je Zeile, Änderungsmerker, Löschmarken statt echtem Löschen).
- MeteoAlarm-Warnungen lassen sich nicht nach Region filtern – ihre
  Gebietsangabe ist freier Text ohne Schlüssel. Sie gelten deshalb für jeden
  Haushalt des Landes. BBK-Warnungen werden bis auf Kreisebene gefiltert;
  genauer gibt die Quelle nichts her.
- Keine Quelle liefert ein Ablaufdatum. Warnungen werden beendet, wenn sie aus
  einem vollständigen Abruf verschwinden – solange kein Abruf gelingt, bleiben
  sie stehen. Einzelheiten in [`docs/warning-feeds.md`](docs/warning-feeds.md).
- Der Hintergrundabruf ist auf Android verlässlich (15 Minuten Mindestabstand,
  eine Vorgabe der Plattform) und auf iOS nur gelegentlich – dort entscheidet
  das System. Für sofortige Warnungen ist NINA vom BBK die richtige Antwort,
  die App sagt das auch selbst.
- Karten und Wikipedia sind noch nicht offline verfügbar. Beides ist geplant:
  Vektorkarten als PMTiles, Wikipedia als ZIM-Datei.
- Fotos zu Vorratsartikeln bleiben auf dem Gerät, auf dem sie aufgenommen
  wurden.
- Veröffentlicht wird bisher nur eine macOS-Fassung. Android baut durch und
  wurde am fertigen Paket geprüft; die Release-APK ist noch mit dem
  Debug-Schlüssel signiert. Für iOS ist geprüft, dass die App durchbaut;
  ausgeliefert wird sie nicht. Linux und Windows sind angelegt, aber nie
  gebaut. Web bräuchte Umbau: der Foto-Teil verwendet `dart:io`.
