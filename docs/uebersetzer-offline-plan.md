# Freier Übersetzer ohne Netz — ein Plan

Noch nichts davon ist gebaut (#182). Dieses Dokument hält fest, wie es
aussehen müsste, was vorher zu klären und zu messen ist und was
ausdrücklich nicht gebaut wird.

## Was es werden soll

Beliebigen Text übersetzen, ohne Netz, auf Mac, Linux, Windows und
Android: eine Warnung in einer Fremdsprache lesen, einer Helferin aus der
Ukraine einen Satz schreiben, den der [Sprachführer](../README.md) nicht
hat.

Der Sprachführer (#181) bleibt daneben bestehen. Feste Sätze sind
vorhersagbar und lassen sich einmal durchlesen; eine Maschine übersetzt
jedes Mal neu und manchmal falsch. Für „Ich habe Schmerzen in der Brust“
ist der feste Satz der bessere, für alles andere der Übersetzer.

## Der Weg, der zur App passt: Bergamot

Firefox übersetzt seit Version 118 ohne Netz, mit der Bergamot-Technik
(Marian-Übersetzungsmodelle, in C++). Jedes Modell übersetzt in **eine
Richtung**, und wo es kein direktes Paar gibt, geht Firefox über
Englisch: Deutsch → Englisch → Arabisch.

Das passt zur Bauweise der App:

- **Ein natives Modul wie die Volltextsuche.** `native/zim_xapian` zeigt,
  wie eine C++-Bibliothek für alle Plattformen gebaut, per FFI
  angesprochen und auf einem eigenen Isolate gehalten wird; Windows wird
  dort mit mingw-w64 auf TestKubuntu quergebaut.
- **Die Modelle werden geladen wie Karten und Archive.** Je Sprachpaar
  ein Download über `features/downloads/`, mit Fortsetzen, Prüfsumme und
  einem Speicherort, den die App wiederfindet. Danach ohne Netz.
- **Nichts verlässt das Gerät.** Kein Dienst, kein Konto.

## Stufe 0: klären und messen, bevor etwas gebaut wird

Vier Fragen, deren Antwort den Plan kippen kann. Stand 17.10.2026 sind
sie **offen**:

1. **Lizenz der Modelle.** Bergamot selbst steht unter MPL 2.0. Die
   Lizenz der trainierten Modelle ist nicht geklärt; das alte Repository
   `mozilla/firefox-translations-models` ist seit Dezember 2025
   archiviert, die Modelle liegen jetzt bei `mozilla/translations` und in
   Googles Cloud-Speicher. Ohne eine Lizenz, die Weitergabe und Download
   aus einer Drittanwendung erlaubt, wird nichts eingebaut.
2. **Welche Paare es wirklich gibt.** Gebraucht werden mindestens
   Deutsch, Englisch und Spanisch mit Ukrainisch, Russisch, Arabisch,
   Türkisch, Polnisch, Persisch und Französisch. Persisch und Ukrainisch
   standen zuletzt noch im Entwicklungsstand; Arabisch ist zu prüfen.
3. **Größe und Geschwindigkeit.** Wie groß ist ein Paar wirklich (Modell,
   Wortschatz, Lexikon), wie viel Speicher braucht eine Übersetzung, und
   wie lange dauert ein Absatz auf einem älteren Android-Telefon?
4. **Bauen für alle vier Plattformen.** Marian braucht je nach Prozessor
   eigene Rechenkerne (intgemm auf x86, ruy auf ARM). Geht der
   Windows-Build mit mingw-w64 wie bei Xapian, oder braucht er MSVC?

Gemessen wird auf dem Mac mit einem kleinen Kommandozeilenprogramm, bevor
eine Zeile Dart dazukommt. Ergebnis ist ein Abschnitt in diesem Dokument
mit Zahlen.

## Danach, wenn Stufe 0 trägt

1. Natives Modul für macOS, dann Linux und Windows, Android zuletzt.
2. Ein Bildschirm „Übersetzer“: Sprachen wählen, Text hinein, Text heraus,
   kopieren; ohne heruntergeladenes Paar steht dort, welches fehlt und wie
   groß es ist.
3. Paare verwalten unter „Offline und Speicher“, wie Karten und Archive.
4. Aus dem Sprachführer heraus: ein Satz, der fehlt, geht an den
   Übersetzer.
5. Auf dem Bildschirm stets der Hinweis, dass maschinell übersetzt wurde.

## Was nicht gebaut wird

- **Kein Dienst im Netz** (DeepL, Google, ein eigener Server). Die App
  arbeitet ohne Netz, und ein Text an einen Übersetzungsdienst ist ein
  Text, der das Gerät verlässt.
- **Kein ML Kit.** Googles Übersetzung auf dem Gerät gibt es nur für
  Android und iOS, und sie bringt die Google-Datenübertragung mit, die
  schon beim Strichcode-Scanner (#158) Thema war.
- **Kein Sprachmodell.** Ein allgemeines Sprachmodell auf dem Gerät ist
  Gigabytes groß und übersetzt nicht verlässlicher als ein dafür
  trainiertes Modell.
- **Keine Übersetzung der Erste-Hilfe-Anleitungen.** Die bleiben, wie
  `ARCHITEKTUR.md` sagt, fachlich geprüfte Texte; eine Maschine ersetzt
  diese Prüfung nicht.
