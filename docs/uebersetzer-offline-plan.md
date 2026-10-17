# Freier Übersetzer ohne Netz

Stand 17.10.2026 (#182, #184, #185): **gebaut für macOS, Linux, Windows
und Android** (Android nur 64-Bit-ARM ab Android 9). Dieses Dokument war
der Plan und hält jetzt fest, was Stufe 0 ergeben hat, wie der Übersetzer
gebaut ist und was noch offen ist.

## Was es ist

Beliebigen Text übersetzen, ohne Netz: eine Warnung in einer
Fremdsprache lesen, einer Helferin aus der Ukraine einen Satz schreiben,
den der [Sprachführer](../README.md) nicht hat.

Der Sprachführer (#181) bleibt daneben bestehen. Feste Sätze sind
vorhersagbar und lassen sich einmal durchlesen; eine Maschine übersetzt
jedes Mal neu und manchmal falsch. Für „Ich habe Schmerzen in der Brust“
ist der feste Satz der bessere, für alles andere der Übersetzer. Der
Sprachführer verweist am Ende seiner Liste auf den Übersetzer, und unter
jeder Übersetzung steht, dass sie maschinell ist.

## Stufe 0: Ergebnis

Gemessen am 17.10.2026 auf dem Mac (Apple Silicon), mit einem kleinen
Kommandozeilenprogramm (`native/translate/selftest.c`), bevor Dart
dazukam.

1. **Lizenz der Modelle: MPL 2.0.** Mozilla veröffentlicht die Modelle,
   mit denen Firefox übersetzt, unter der Mozilla Public License 2.0 über
   seine Remote Settings: eine öffentliche Liste ohne Schlüssel
   (`translations-models`), jede Datei mit Größe und SHA-256. Die Engine
   ist `inference/` aus `mozilla/translations`, ebenfalls MPL 2.0; das
   ältere `browsermt/bergamot-translator` ruht seit 2024.
2. **Alle gebrauchten Paare gibt es.** Jedes Modell übersetzt in eine
   Richtung von oder nach Englisch; 18 Richtungen decken die zehn
   Sprachen des Sprachführers ab. Deutsch → Arabisch geht über Englisch,
   wie in Firefox.
3. **Größe und Geschwindigkeit:**

   | Richtung | Größe | Richtung | Größe |
   |---|---|---|---|
   | de → en | 37,3 MB | en → de | 36,7 MB |
   | es → en | 37,0 MB | en → es | 36,6 MB |
   | fr → en | 37,2 MB | en → fr | 36,7 MB |
   | pl → en | 37,3 MB | en → pl | 35,9 MB |
   | tr → en | 22,6 MB | en → tr | 21,2 MB |
   | ru → en | 36,9 MB | en → ru | 46,7 MB (Android 35,2 MB) |
   | uk → en | 21,9 MB | en → uk | 35,5 MB |
   | ar → en | 37,0 MB | en → ar | 35,6 MB |
   | fa → en | 21,9 MB | en → fa | 21,6 MB |

   Ein Modell öffnen: 0,04 s. Zwei Sätze Deutsch → Englisch: 0,04 s beim
   ersten Mal, 0,015 s danach (arm64); unter Rosetta (x86_64) 0,10 und
   0,035 s. Speicher während der Übersetzung: rund 210 MB. Ergebnis:
   „Please call an ambulance. We no longer have drinking water and the
   house is without electricity.“ Ein älteres Android-Telefon ist noch
   nicht gemessen.
4. **Bauen:** für alle vier Plattformen gelöst, siehe unten. Gemessen
   mit zwei Sätzen Deutsch → Englisch, zweiter Durchlauf:

   | Plattform | Bibliothek | Übersetzen | Speicher |
   |---|---|---|---|
   | macOS arm64 | 20 MB (universal) | 0,015 s | 210 MB |
   | macOS x86_64 (Rosetta) | ebenda | 0,035 s | 210 MB |
   | Linux x86_64 (TestKubuntu) | 8,4 MB | 0,019 s | 185 MB |
   | Windows x64 (TestWindows) | 11,4 MB | 0,029 s | – |
   | Android arm64 (Emulator, API 34) | 8,3 MB | 0,077 s | – |

   Alle übersetzen gleich: „Please call an ambulance. We no longer have
   drinking water and the house is without electricity.“ Auf einem
   echten älteren Telefon ist noch nicht gemessen.

## Wie es gebaut ist

**Nativ.** `native/translate/` ist eine kleine C-Schnittstelle
(`translate.h`: Modell öffnen, übersetzen mit optionalem zweiten Modell
für den Weg über Englisch, freigeben) über der Engine. Sie wird mit der
Engine statisch zu einer Bibliothek gebunden, die nur vom System abhängt,
und exportiert nur ihre sechs Funktionen.

- `translate_source.sh` holt die Engine bei einem festen Commit als
  schmalen Checkout mit nur den Submodulen, die ein CPU-Build liest, und
  ändert sechs Stellen, die neuere Compiler, SDKs oder mingw ablehnen
  (im Skript begründet; jede nur, solange sie noch fällig ist, damit ein
  zweiter Lauf nichts neu baut). PCRE2 für die Satztrennung kommt als
  Tarball mit festgelegter Prüfsumme dazu; die Engine selbst würde es
  ungeprüft beim Bauen herunterladen.
- `build_macos.sh` baut arm64 (Ruy und Accelerate) und x86_64 (intgemm,
  Grundlinie x86-64-v2) getrennt und fügt sie mit `lipo` zusammen. Ein
  zweiter Lauf baut nur, was sich geändert hat.
- `build_linux.sh` baut auf dem Linux-Rechner; Fließkomma über Ruy,
  weil eine BLAS-Bibliothek dort nicht vorausgesetzt werden kann, int8
  über intgemm. Die Bibliothek hängt nur von libc, libm, libstdc++ und
  libgcc ab.
- `build_windows.sh` baut die DLL ebenfalls auf dem Linux-Rechner, mit
  mingw-w64 (posix-Threads) wie die Xapian-Schicht, alles statisch
  gebunden; sie hängt nur von Windows-eigenen DLLs ab. Marian ist für
  MSVC geschrieben: drei Header in Großschreibung bekommen Weiterleitungen,
  die Windows-Definitionen von MSVC werden gesetzt, und PCRE2 wird als
  statisch markiert (alles in `CMakeLists.txt`, nur für mingw).
- `build_android.sh` baut mit dem NDK nur für arm64-v8a und für API 28
  (Android 9): Marians Pfadbibliothek braucht `iconv`, `nl_langinfo` und
  `glob`, die Bionic erst dann hat, und seine ARM-Rechenkerne nutzen
  Befehle, die es nur auf 64-Bit-ARM gibt. Auf Android 7 und 8 und im
  armeabi-v7a-Paket lädt die Bibliothek nicht, und der Bildschirm sagt,
  dass der Übersetzer fehlt. Gradle nimmt `build/android-jni/` auf, wenn
  es da ist.
- Die Xcode-Phase „Embed Translator“ kopiert die Bibliothek nach
  `Contents/Frameworks` und signiert sie; die CMake-Dateien für Linux und
  Windows legen sie ins Paket. Fehlt sie, warnen alle nur. Deshalb baut
  `tool/release.sh` (bzw. `tool/linux_release.sh`) sie vor jedem Paket und
  bricht ab, wenn sie danach nicht im Paket liegt; der Starttest
  verlangt sie unter Linux und Windows.

**Dart.** `lib/features/translator/`:

- `translator_catalogue.dart` liest Mozillas Liste: nur Richtungen
  zwischen den Sprachen des Sprachführers und Englisch, je die neueste
  Version mit allen drei Dateien, die ein veröffentlichtes Firefox auf
  derselben Art Gerät bekäme. Die Filterausdrücke der Liste werden dafür
  gelesen, aber nur in der einen Form, die sie bisher haben; was anders
  aussieht, wird übergangen. Englisch → Russisch ist der Grund: es hat
  keinen Eintrag für alle, sondern 2.0 für den Desktop und 2.1 für
  Android.
- `translator_store.dart` legt je Richtung einen Ordner im
  Anwendungsverzeichnis an, lädt mit dem Downloader der Karten
  (fortsetzbar), prüft jede Datei gegen ihre SHA-256 und schreibt das
  Manifest zuletzt. Ein Ordner ohne Manifest ist kein Paket.
- `translator_engine.dart` übersetzt auf einem eigenen Isolate und öffnet
  die Modelle für jeden Aufruf neu: 0,04 s sind billiger, als zwei
  Modelle und den Arbeitsspeicher der Engine für einen selten geöffneten
  Bildschirm im Speicher zu halten.
- `translator_screen.dart`: Sprachen wählen (getauscht wird mit der
  Übersetzung als neuem Text, so liest man eine Antwort zurück), Text
  hinein, Text heraus, kopieren. Fehlt ein Paket, steht dort, welches und
  wie groß, mit einem Knopf zum Laden; geladene Pakete lassen sich
  entfernen. Die Liste wird nur abgefragt, wenn ein Paket fehlt.
- `translator_packs_card.dart`: dieselben Pakete unter Einstellungen →
  „Offline und Speicher“, neben der Karte, mit Größe und Entfernen (#192).

**Tests.** `test/features/translator/` prüft Liste und Speicher gegen
einen Ausschnitt der echten Liste, `test/widget/translator_screen_test.dart`
den Bildschirm. `test/live/translator_live_test.dart` fragt Mozilla
(`PREPPSUITE_TEST_NETWORK=1`) und übersetzt mit der echten Engine, wenn
`PREPPSUITE_TRANSLATOR_MODELS` auf einen Ordner mit `deen/` und `ende/`
zeigt.

## Was noch offen ist

1. Android: Messung auf einem echten älteren Telefon. Die Modelle
   brauchen zusammen mit der Engine rund 200 MB Arbeitsspeicher.
2. iPhone und iPad: erst mit der Developer-Lizenz; gebaut wird dafür
   noch nichts.

Wo der Übersetzer fehlt (iPhone, Android vor Version 9, 32-Bit-Android),
sagt der Bildschirm, dass er in dieser Ausgabe nicht enthalten ist; der
Sprachführer funktioniert überall.

## Was nicht gebaut wird

- **Kein Dienst im Netz** (DeepL, Google, ein eigener Server). Die App
  arbeitet ohne Netz, und ein Text an einen Übersetzungsdienst ist ein
  Text, der das Gerät verlässt. Geladen werden nur die Modelle, von
  Mozilla; der Text selbst bleibt auf dem Gerät.
- **Kein ML Kit.** Googles Übersetzung auf dem Gerät gibt es nur für
  Android und iOS, und sie bringt die Google-Datenübertragung mit, die
  schon beim Strichcode-Scanner (#158) Thema war.
- **Kein Sprachmodell.** Ein allgemeines Sprachmodell auf dem Gerät ist
  Gigabytes groß und übersetzt nicht verlässlicher als ein dafür
  trainiertes Modell.
- **Keine Übersetzung der Erste-Hilfe-Anleitungen.** Die bleiben, wie
  `ARCHITEKTUR.md` sagt, fachlich geprüfte Texte; eine Maschine ersetzt
  diese Prüfung nicht.
