# Mitgeführter Fremdcode

Was hier liegt, gehört nicht diesem Projekt. Es liegt hier, weil die
veröffentlichte Fassung einen Fehler hat, den wir nicht umgehen können, und
weil es keine neuere gibt.

## flutter_tts 4.2.5

MIT, Copyright (c) 2018 Daniel Lutton. Die Lizenz liegt unverändert bei.

**Warum.** Das Plugin verhinderte den Start der Windows-App. Sein
Konstruktor aktiviert `SpeechSynthesizer` und `MediaPlayer`, und beide
können eine `winrt::hresult_error` werfen — aus `RegisterPlugins` heraus,
wo nichts fängt. Eine unbehandelte C++-Ausnahme dort beendet den Prozess,
bevor ein Fenster entsteht: keine Meldung, keine Ausgabe, kein
Absturzeintrag im Ereignisprotokoll, nur ein Ausstieg mit `0xC0E90002`.

Gemessen statt vermutet, auf derselben Maschine und mit derselben
Startmethode:

| | startet |
|---|---|
| 2.0.1 (ohne das Plugin) | ja |
| 2.1.0 (mit dem Plugin) | nein |
| 2.1.0, Baum ohne das Plugin | ja |

Der Rechner hatte dabei zwei SAPI-Stimmen, darunter eine deutsche — eine
fehlende Stimme war es also nicht.

**Was geändert wurde.** Vier Stellen, alle im WinRT-Zweig von
`windows/flutter_tts_plugin.cpp` und alle mit `PreppSuite patch`
gekennzeichnet:

1. `SpeechSynthesizer synth` und `MediaPlayer mPlayer` werden als
   `{ nullptr }` angelegt. Ein projizierter WinRT-Typ aktiviert seine
   Laufzeitklasse sonst schon bei der Mitgliedsinitialisierung, also noch
   vor dem Rumpf des Konstruktors, wo kein `try` steht.
2. Der Konstruktor fängt die Aktivierung ab und merkt sich in `ready`, ob
   sie gelungen ist.
3. `HandleMethodCall` antwortet ohne Sprachausgabe mit `Success(0)` und
   kehrt zurück. Eine Wache am einzigen Eingang statt zwanzig weiter unten;
   auf `isLanguageAvailable` liest die Dart-Seite das als „dieses Gerät
   kann nicht sprechen", und die Vorlese-Schaltfläche bleibt weg.
4. `RegisterWithRegistrar` fängt zusätzlich um die Erzeugung herum. Der
   Konstruktor fängt bereits selbst; dies ist die zweite Naht.

Der `#else`-Zweig derselben Datei — die SAPI-Umsetzung für Nicht-Desktop —
ist **nicht** angefasst. Er wird auf einem gewöhnlichen Windows nicht
übersetzt. Er hat denselben Fehler in anderer Form: ein `throw` aus dem
Konstruktor, wenn `CoInitializeEx` oder `CoCreateInstance` scheitert.

**Beim Nachziehen.** Gibt es eine neuere Fassung, gehören diese vier
Stellen erneut angebracht — oder, falls upstream sie übernimmt, gehört die
`dependency_overrides` in der Wurzel-`pubspec.yaml` ersatzlos gestrichen.

## mobile_scanner 7.4.2

BSD-3-Clause, Copyright (c) 2022 Julian Steenbakker. Die Lizenz liegt
unverändert bei.

**Warum.** Unter Android liest das Plugin Strichcodes und QR-Codes mit
Googles ML Kit, und ML Kit meldet bei jeder Nutzung Gerät (Hersteller,
Modell, Systemversion), App und Version, eine Installationskennung,
Leistungswerte und Nutzungsereignisse an Google, „für Diagnose und
Nutzungsanalyse“ (Googles eigene Angabe unter
`developers.google.com/ml-kit/android-data-disclosure`). Abschalten lässt
sich das nicht. Die „unbundled“-Variante des Plugins ist ebenfalls ML Kit.
Das betraf den Strichcode im Vorrat, die QR-Übertragung zwischen Geräten
und die Angebote der Nachbarschaft (#158). Für die Texterkennung war ML
Kit aus demselben Grund schon ausgeschieden.

**Was geändert wurde.** Nur der Android-Teil, alle Stellen mit
`PreppSuite patch` gekennzeichnet:

1. `android/build.gradle.kts`: `com.google.mlkit:barcode-scanning` raus,
   `io.github.zxing-cpp:android:2.3.0` rein; die Robolectric-Tests des
   Plugins und ihre Abhängigkeiten sind nicht mitkopiert.
2. `BarcodeDecoder.kt` ist neu: liest Kamerabilder und Fotos mit
   zxing-cpp und gibt sie in der Form zurück, die die Dart-Seite von ML
   Kit kannte — dieselben Formatnummern, Rohwert, Bytes, vier Ecken.
   zxing-cpp kennt einige Formate mehr (DataBar, MaxiCode, Micro-QR); die
   bleiben aus, damit der Scanner findet, was er vorher fand.
3. `MobileScanner.kt`: Kamerabilder und Fotos gehen an den Decoder statt
   an ML Kit. zxing-cpp liest synchron auf dem Analyse-Thread, ML Kit
   lieferte eine Task; die Logik danach ist die des Plugins.
4. `MobileScannerHandler.kt`: Die Formatliste geht direkt an den Decoder.
   Auto-Zoom war ML Kits Zoomvorschlag und entfällt; die App nutzt ihn
   nicht.
5. `objects/BarcodeFormats.kt`: ML Kits Formatkonstanten als Zahlen
   ausgeschrieben, `MobileScannerUtilities.kt` ohne die Umwandlung von ML
   Kits `Barcode`.
6. `android/proguard-rules.pro`: hält `zxingcpp.**`, dessen Klassen der
   native Teil über ihre Namen erzeugt; die ML-Kit-Regeln sind weg.

Was ML Kit zusätzlich auslas — Kontaktkarten, WLAN-Daten, Termine —, wird
nicht mehr gefüllt. iOS und macOS lesen weiter mit Apples Vision und sind
unverändert, ebenso die ganze Dart-Seite. Beispiel-App, Tests und
`analysis_options.yaml` des Plugins sind nicht mitkopiert (letztere bindet
`very_good_analysis` ein, das hier niemand auflösen kann), und die
Dart-Dateien sind mit `dart format` umgebrochen, weil der Pre-Push-Hook das
ganze Repository prüft.

**Geprüft.** `integration_test/native_barcode_test.dart` zeichnet einen
QR-Code mit Umlaut und Gedankenstrich und einen EAN-13 und lässt beide
über den Foto-Weg des Plugins zurücklesen. Im iOS-Simulator bietet das
Plugin diesen Weg nicht an; dort wird der Test übersprungen.

**Beim Nachziehen.** Eine neuere Fassung von `mobile_scanner` hierher
kopieren und die sechs Stellen erneut anbringen. Bietet das Plugin
irgendwann unter Android einen Weg ohne ML Kit, gehört diese Kopie samt
dem Eintrag in `dependency_overrides` der Wurzel-`pubspec.yaml`
gestrichen.

## zstandard_ios und zstandard_macos 1.5.0

BSD, Copyright Meta Platforms (zstd) und die Autoren des Plugins
(github.com/vypdev/zstandard). Die Lizenz liegt jeweils unverändert bei.

**Warum.** Beide Plugins kopieren beim Bauen die zstd-Quellen aus
`zstandard_native` nach `Classes/zstd` (Phase „Sync zstd“) und löschen sie
am Ende desselben Builds wieder (Phase „Remove synced zstd“). Xcode hat sich
die Dateien aber als Eingaben gemerkt. Der nächste inkrementelle Build
findet sie nicht und bricht mit „Build input file cannot be found“ ab, genau
jeder zweite.

Gemessen am 3. Oktober 2026: Der Gerätetest baut viermal hintereinander, und
die Dateien eins und drei scheiterten, zwei und vier liefen. Der erste
Release-Build für das iPhone nach einem Gerätetest scheiterte ebenso. Mit
den Kopien liefen drei iOS- und zwei macOS-Builds hintereinander durch, und
der Gerätetest brauchte keinen zweiten Versuch mehr.

**Was geändert wurde.** Je eine Stelle im Podspec, mit `PreppSuite patch`
gekennzeichnet: Die Phase „Remove synced zstd“ ist entfernt. Die
synchronisierten Quellen bleiben liegen. Die Sync-Phase überschreibt sie
ohnehin bei jedem Build, und `.gitignore` hält sie aus dem Repository.
Beispiel, Bilder und Tests des Plugins sind nicht mitkopiert, und die
zwei Dart-Dateien sind mit `dart format` umgebrochen, weil der Pre-Push-Hook
das ganze Repository prüft. Am Code ändert das nichts.

**Beim Nachziehen.** Bei einer neueren Fassung prüfen, ob die Lösch-Phase
noch drin ist. Wenn ja, die Kopien erneuern und die Zeile wieder entfernen.
Wenn nein, die beiden Einträge in `dependency_overrides` der
Wurzel-`pubspec.yaml` streichen.

