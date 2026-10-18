# Hinweise zu Komponenten, Daten und Diensten Dritter

Der PreppSuite-Projektcode steht unter der PolyForm Strict License 1.0.0;
siehe [LICENSE](LICENSE).
Bibliotheken, Schriften, Datenquellen und heruntergeladene Inhalte behalten
ihre jeweils eigenen Bedingungen.

## Mitgelieferte Komponenten

- Noto Sans — OFL-1.1; vollständiger Text:
  `preppsuite_flutter/assets/fonts/OFL.txt`
- Angepasste Kopie von `flutter_tts` — MIT; vollständiger Text:
  `third_party/flutter_tts/LICENSE`
- Angepasste Kopien von `zstandard_ios` und `zstandard_macos` — BSD;
  vollständiger Text: `third_party/zstandard_ios/LICENSE` und
  `third_party/zstandard_macos/LICENSE`
- Angepasste Kopie von `mobile_scanner` 7.4.2 — BSD-3-Clause;
  vollständiger Text: `third_party/mobile_scanner/LICENSE`
- zxing-cpp für Android 2.3.0 (nur Android, Strichcodes und QR-Codes) —
  Apache-2.0; Quelle `github.com/zxing-cpp/zxing-cpp`
- Tesseract4Android mit Tesseract 5.5.1, Leptonica 1.85.0, libjpeg und
  libpng (nur Android) — Apache-2.0 bzw. die Lizenzen der enthaltenen
  Bibliotheken; Quelle `github.com/adaptech-cz/Tesseract4Android`
- Tesseract-Sprachdaten `tessdata_fast` Deutsch und Englisch (nur
  Android) — Apache-2.0; vollständiger Text:
  `third_party/tessdata_fast/LICENSE`
- PDFium aus `bblanchon/pdfium-binaries` (über `pdfrx`/`pdfium_dart`, in
  allen Paketen) — BSD-3-Clause und Apache-2.0 bzw. die Lizenzen der
  enthaltenen Bibliotheken; Herkunft geprüft gegen
  `tool/pdfium_provenance.txt`
- Übersetzungs-Engine aus `mozilla/translations` (Verzeichnis `inference/`,
  in den Paketen für macOS, Linux, Windows und Android arm64) — MPL-2.0;
  Quelle `github.com/mozilla/translations`, Commit und die sechs
  geänderten Stellen in
  `preppsuite_flutter/native/translate/translate_source.sh`. Statisch
  enthalten: Marian (MIT), intgemm (MIT), SentencePiece (Apache-2.0), Ruy
  (Apache-2.0) mit cpuinfo (BSD-2-Clause), simd_utils (BSD-2-Clause),
  ssplit-cpp (Apache-2.0), PCRE2 10.39 (BSD-3-Clause), yaml-cpp (MIT),
  zlib 1.2.11 (zlib) und Teile von faiss (MIT)
- Testdaten der Stemmer (nur im Quellcode, nicht in den Paketen):
  Auszüge aus Snowballs Testvokabular und erwarteter Ausgabe,
  `preppsuite_flutter/test/fixtures/stems/*_stems.csv` — BSD-3-Clause,
  Copyright (c) 2001 Dr Martin Porter, (c) 2004, 2005 Richard Boulton;
  Quelle `github.com/snowballstem/snowball-data`. Die Stemmer selbst sind
  eigene Übertragungen der Snowball-Algorithmen.
- Weitere Flutter- und Dart-Abhängigkeiten — jeweilige Paketlizenz; Anzeige
  über Flutters Lizenzübersicht im erzeugten Programm

## Karten und Datenbanken

- OpenStreetMap-Daten, Nominatim und Schutzraumdaten — ODbL-1.0;
  Namensnennung in der App
- OpenMapTiles-Kartenstil — CC-BY-4.0, abgeleitet von OSM Liberty
- OpenFreeMap und optional MapTiler — Bedingungen des jeweiligen Anbieters
- Open Food Facts — ODbL-1.0
- BfS-ODL-Messnetz — Datenlizenz Deutschland – Namensnennung – Version 2.0
- BBK, MeteoAlarm, DWD, Umweltbundesamt, PEGELONLINE, Autobahn GmbH und
  WWBOTA — Bedingungen und Quellenhinweise des jeweiligen Herausgebers

## Heruntergeladene Inhalte

Kiwix-/ZIM-Archive, selbst zusammengestellte Erste-Hilfe-Pakete und die
Übersetzungsmodelle werden nicht als Teil des Projektcodes lizenziert. Die
Übersetzungsmodelle sind die von Firefox, MPL-2.0, und werden aus Mozillas
Remote Settings geladen. Jedes Archiv beziehungsweise jede
Mediendatei behält ihre eigene Lizenz. Urheber, Quelle und Lizenz eines
Erste-Hilfe-Videos müssen im Paketmanifest einzeln angegeben werden.

## Frühere Fassungen

Die Desktop-Pakete bis einschließlich 2.5.7 enthielten zusätzlich
xapian-core 1.4.32 (GPL-2.0-or-later), statisch gebunden in der
Volltext-Schicht `native/zim_xapian`. Seit 2.5.8 ist sie entfernt (#186).
