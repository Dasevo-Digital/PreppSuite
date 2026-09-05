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

## Selbst betreiben

Zwei Befehle, wenn Docker läuft:

```bash
./scripts/generate-env.sh   # erzeugt .env mit zufälligen Geheimnissen
docker compose up -d
```

Das startet Server, PostgreSQL und Redis. Migrationen werden beim Start
angewendet, auch bei späteren Aktualisierungen. Der Server hört danach auf
Port 8080.

Es muss keine Konfigurationsdatei bearbeitet werden: der Server nimmt
seine gesamte Einstellung aus Umgebungsvariablen, die in `.env` stehen.
`config/passwords.yaml` wird für diesen Weg nicht gebraucht — sie steht zu
Recht nicht im Repository, ein frischer Clone hätte also keine.

Für den Betrieb hinter einem Reverse Proxy mit TLS in `.env` setzen:

```bash
PREPPSUITE_HOST=preppsuite.example.com
PREPPSUITE_SCHEME=https
PREPPSUITE_PUBLIC_PORT=443
```

Zum Entwickeln startet `preppsuite_server/docker-compose.yaml` nur
PostgreSQL und Redis, damit `dart bin/main.dart` und `dart test` lokal
gegen echte Dienste laufen.

Die Adresse des Servers wird in der App eingetragen – auf dem
Anmeldebildschirm und später unter Einstellungen. Kurzformen genügen:
`192.168.1.5:8080` oder `preppsuite.example.com`. Fehlt das Schema, wird
`https` angenommen, bei IP-Adressen und `localhost` dagegen `http`.

Wer eine Fassung weitergibt, die von vornherein auf den eigenen Server
zeigt, baut sie mit der Adresse – der eingetragene Wert übersteuert sie
später trotzdem:

```bash
cd preppsuite_flutter
flutter build macos --release --dart-define=SERVER_URL=https://preppsuite.example.com/
```

Push-Benachrichtigungen sind optional und standardmäßig aus; der Server
läuft ohne sie normal. Was dafür nötig ist und warum es sich für eine
selbst betriebene Installation kaum lohnt, steht in
[`docs/push-notifications.md`](docs/push-notifications.md).

### Android weitergeben

Die Release-APK wird mit dem Debug-Schlüssel signiert, solange kein eigener
vorliegt. Zum Ausprobieren reicht das; zum Weitergeben nicht, denn das
Passwort dieses Schlüssels ist der öffentlich bekannte Wert `android` —
jeder könnte damit eine gefälschte Aktualisierung signieren, die Android
als echt annimmt.

Einen eigenen Schlüssel erzeugen (einmalig, außerhalb des Repositorys):

```bash
keytool -genkeypair -v -keystore ~/.android-keystores/preppsuite-release.jks \
  -keyalg RSA -keysize 4096 -validity 10000 -alias preppsuite
```

Dazu `preppsuite_flutter/android/key.properties` anlegen — die Datei ist
ignoriert und bleibt lokal:

```properties
storeFile=/Users/DEIN_NAME/.android-keystores/preppsuite-release.jks
storePassword=…
keyPassword=…
keyAlias=preppsuite
```

Danach signiert `flutter build apk --release` von selbst richtig. Fehlt die
Datei, warnt der Build und fällt auf den Debug-Schlüssel zurück.

**Der Schlüssel ist unersetzlich.** Geht er verloren, lässt sich für alle,
die die App installiert haben, nie wieder eine Aktualisierung
veröffentlichen — sie müssten deinstallieren und dabei ihre lokalen Daten
aufgeben. Keystore und Passwörter gehören deshalb an zwei getrennte,
gesicherte Orte, nicht nur auf den Rechner, auf dem gebaut wird.

Für die Weitergabe über *Releases* statt über den Play Store lohnt sich

```bash
flutter build apk --release --split-per-abi
```

Das ergibt getrennte Pakete je Prozessorarchitektur, jedes rund ein Drittel
der Größe der gemeinsamen APK.

Fertige macOS-Fassungen liegen unter *Releases*. Sie sind nicht mit einem
gekauften Zertifikat signiert; Gatekeeper meldet sich beim ersten Start,
über **Rechtsklick → Öffnen** startet die App trotzdem.

Die App trägt die Kennung `de.status403.preppsuite`. Wer sie nur für sich
baut, kann sie behalten. Wer eine eigene Fassung über den App Store oder
TestFlight verteilen will, braucht eine eigene unter einer Domain, die er
selbst kontrolliert — zwei Apps mit derselben Kennung kann Apple nicht
auseinanderhalten. Sie steht an drei Stellen:
`macos/Runner/Configs/AppInfo.xcconfig` sowie in den Xcode-Projekten unter
`ios/` und `macos/`.

Zu beachten: die Kennung bestimmt auch, wo die lokale Datenbank liegt. Wird
sie an einer bestehenden Installation geändert, startet die App mit einer
leeren Datenbank — die alte liegt dann unter der vorherigen Kennung in
`~/Library/Containers/`.

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

- MeteoAlarm-Warnungen lassen sich nicht nach Region filtern – ihre
  Gebietsangabe ist freier Text ohne Schlüssel. Sie gelten deshalb für
  jeden Haushalt des Landes. BBK-Warnungen werden dagegen bis auf
  Kreisebene gefiltert; genauer gibt die Quelle nichts her.
- Keine Quelle liefert ein Ablaufdatum. Warnungen werden beendet, wenn sie
  aus einem vollständigen Abruf verschwinden – solange kein Abruf gelingt,
  bleiben sie stehen. Einzelheiten in `docs/warning-feeds.md`.
- Warnmeldungen erscheinen nur, solange die App läuft. Serverseitig gibt es
  einen Push-Weg über FCM, er ist aber standardmäßig aus und lohnt sich für
  eine selbst betriebene Installation kaum: der Abruf läuft alle 15 Minuten,
  während NINA vom BBK dieselben Meldungen in rund 30 Sekunden zustellt.
  Gründe und Einrichtung in [`docs/push-notifications.md`](docs/push-notifications.md).
  Ablauf-Erinnerungen für Vorräte werden dagegen lokal im Voraus eingeplant
  und erreichen das Gerät auch bei geschlossener App – ohne Server und ohne
  Drittanbieter.
- Fotos zu Vorratsartikeln bleiben auf dem Gerät, auf dem sie aufgenommen
  wurden. Der Abgleich überträgt Text, keine Dateien.
- Veröffentlicht wird bisher nur eine macOS-Fassung. Android baut inzwischen
  durch und wurde am fertigen Paket geprüft (Kennung, Mindest-API,
  Berechtigungen); die Release-APK ist allerdings noch mit dem
  Debug-Schlüssel signiert, für eine Weitergabe bräuchte es einen eigenen
  Keystore. Für iOS ist geprüft, dass die App durchbaut
  (`flutter build ios --no-codesign`); ausgeliefert wird sie nicht, das
  bräuchte ein Apple-Entwicklerkonto. Linux und Windows sind angelegt, aber
  nie gebaut. Web bräuchte Umbau: der Foto-Teil verwendet `dart:io`, das im
  Browser nicht zur Verfügung steht.
