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
Länder. Abgefragt wird alle 15 Minuten; BBK-Warnungen werden bis auf
Kreisebene gefiltert, sodass ein Haushalt nicht die Meldungen des halben
Landes sieht.

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

**Karte offline.** Wer eine PMTiles-Datei auf dem Gerät hinterlegt, braucht
für die Karte kein Netz mehr – die App zeichnet sie selbst aus
Vektorkacheln. Ohne eigene Datei kommen die Kacheln wie bisher von
OpenStreetMap. Was für eine Datei das sein muss und wie man sie herstellt,
steht in [`docs/karte-offline.md`](docs/karte-offline.md).

**Wissen offline.** Eine ZIM-Datei – Wikipedia von Kiwix, eine
Themensammlung oder eigene Lernmaterialien – macht das Nachschlagen
unabhängig vom Netz. Gesucht wird nach Titeln oder im Text der Artikel;
gelesen wird mit Bildern und Formatierung. Einzelheiten in
[`docs/wissen-offline.md`](docs/wissen-offline.md).

**Teilen.** Mehrere Geräte teilen sich Bestände, Listen und Budget über
einen Ordner, den sie alle sehen – Nextcloud, Syncthing, iCloud Drive,
Dropbox. PreppSuite legt dort nur Dateien ab; wer sie transportiert,
entscheidest du. Kein Konto, kein Einladungscode, kein Dienst dazwischen.

Jedes Gerät schreibt genau eine Datei und liest alle anderen, sodass zwei
Personen nie dieselbe Datei beschreiben. Bei gleichzeitiger Änderung
derselben Zeile gewinnt die jüngere. Einzelheiten samt Grenzen in
[`docs/gemeinsamer-ordner.md`](docs/gemeinsamer-ordner.md).

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

Ein einziges Paket, `preppsuite_flutter`. Darin liegt der Code nach
Funktion getrennt: `lib/local_db` die Datenbank, `lib/model` die einfachen
Typen, `lib/features/<name>/application` die Logik und `presentation` die
Oberfläche.

Die Anwendung liest ausschliesslich aus einer lokalen Datenbank auf dem
Gerät. Änderungen bekommen dort eine Kennung und werden als offen
markiert; gelöscht wird nur als Merker, damit die Löschung auch auf den
anderen Geräten ankommt. Der Abgleich über den gemeinsamen Ordner läuft
daneben und schreibt in dieselbe Datenbank.

Die Annahmen, die dahinterstehen, sind in [`CLAUDE.md`](CLAUDE.md)
aufgeschrieben, die Warnquellen in
[`docs/warning-feeds.md`](docs/warning-feeds.md), das Ordnerformat in
[`docs/gemeinsamer-ordner.md`](docs/gemeinsamer-ordner.md), die
Offline-Karte in [`docs/karte-offline.md`](docs/karte-offline.md) und die
Wissensdatei in [`docs/wissen-offline.md`](docs/wissen-offline.md).

## Entwicklung

```bash
flutter pub get                                   # im Wurzelverzeichnis
flutter analyze
dart format --output=none --set-exit-if-changed .

cd preppsuite_flutter && flutter test
```

Nach jeder Änderung an einer Tabelle:

```bash
cd preppsuite_flutter && dart run build_runner build
```

## Lizenz

Der Projektcode steht unter der Lizenz in [LICENSE](LICENSE).

Die Daten stammen aus fremden Quellen und stehen unter deren eigenen
Bedingungen: Kartenkacheln und Schutzraum-Einträge von OpenStreetMap
(ODbL, Namensnennung in der Karte), Produktdaten von Open Food Facts
(ODbL), Warnungen vom BBK und von MeteoAlarm, Ortssuche über Nominatim.
Das Kartenbild der Offline-Karte stammt von OpenMapTiles (CC-BY 4.0),
abgeleitet von OSM Liberty.
Die mitgelieferte Schrift Noto Sans steht unter der SIL Open Font License
(`preppsuite_flutter/assets/fonts/OFL.txt`).

## Stand

Die App ist im Alltag benutzbar, einige Kanten sind aber bekannt:

- Auf Android geht die Freigabe eines Ordners bei einer Neuinstallation
  verloren und lässt sich in den Systemeinstellungen entziehen. Die App
  merkt das beim nächsten Abgleich und sagt es; der Ordner wird dann
  einmal neu gewählt.
- Der Abgleich ist kein Echtzeit-Abgleich: alle zwei Minuten, beim Start und
  beim Zurückkehren in die App – dazu die Laufzeit des Dienstes, der die
  Dateien transportiert.
- PreppSuite verschlüsselt den Ordner nicht. Wer ihn lesen kann, liest den
  Haushalt.
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
- Die Offline-Karte kennt ein Kartenbild, hell, ohne Piktogramme an Punkten
  und ohne Höhenrelief. Sie braucht ein Archiv im OpenMapTiles-Schema; die
  fertigen `.pmtiles` aus dem Netz sind meist Protomaps-Schema und werden
  beim Auswählen abgelehnt. Einzelheiten in
  [`docs/karte-offline.md`](docs/karte-offline.md).
- Die Volltextsuche braucht einen Index, den die App einmal selbst
  aufbaut – der fertige im Archiv liegt in einem Xapian-Format ohne
  Dart-Anbindung. Für eine Themensammlung sind das Minuten, für die
  vollständige Wikipedia eher eine Stunde und mehrere Gigabyte. Anhalten
  geht jederzeit; das Angefangene bleibt durchsuchbar.
- Der Index kennt keinen deutschen Wortstamm: „Notvorräte" findet nicht
  „Notvorrat".
- Artikel öffnen unter Linux und Windows ein eigenes Fenster statt eines
  Bereichs in der App, und brauchen dort die Browser-Komponente des
  Systems: WebView2 unter Windows, `libwebkit2gtk-4.1-0` unter Linux.
  Fehlt sie, sagt die App das beim Öffnen.
- Fotos zu Vorratsartikeln bleiben auf dem Gerät, auf dem sie aufgenommen
  wurden – im Ordner liegen nur die Daten, nicht die Bilder.
- Veröffentlicht wird bisher nur eine macOS-Fassung. Android baut durch und
  wurde am fertigen Paket geprüft; die Release-APK ist noch mit dem
  Debug-Schlüssel signiert. Für iOS ist geprüft, dass die App durchbaut;
  ausgeliefert wird sie nicht, aber sie läuft auf dem Simulator. iOS
  verlangt mindestens iOS 14 – `workmanager` bringt die Grenze mit.
  Linux baut durch, geprüft im Container (`tool/docker/`); ausprobiert auf
  einem echten Linux-Rechner ist sie nicht. Windows ist nie gebaut worden
  – dafür steht ein CI-Auftrag bereit, gelaufen ist er noch nicht. Web bräuchte Umbau: der Foto-Teil verwendet `dart:io`.
