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
