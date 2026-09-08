# Volltextsuche über den Index im Archiv

Ein Kiwix-Archiv bringt seinen eigenen Volltextindex mit. Er ist eine
[Xapian](https://xapian.org)-Datenbank, die als Block im Archiv liegt –
unkomprimiert, damit man sie dort lesen kann, wo sie liegt.

Das ist ein anderer Weg als der, den die App bisher geht: `KnowledgeIndexer`
baut sich einen eigenen SQLite-FTS5-Index. Beide bleiben. Welcher greift,
entscheidet das Archiv.

**Stand seit 0.15.0: in der App, unter macOS und Linux.** Wo die
Bibliothek mitgeliefert wird und das Archiv einen Index trägt, sucht die
App darin. Sonst fällt sie auf ihren eigenen zurück, ohne dass jemand
etwas umstellen muss. Was für die übrigen Plattformen noch fehlt, steht
unten.

An der vollständigen deutschen Wikipedia gemessen, 50 GB:

| | |
|---|---|
| Index im Archiv | 2914 MB ab Byte 47 677 531 029 |
| Dokumente | 3 205 145 |
| Öffnen | 4 ms |
| `Trinkwasser` | 5961 Treffer, 4 ms |
| `Notvorrat` | 43 Treffer, 0 ms |
| `Notvorräte` | 43 Treffer, erster ist `Notvorrat` |

Der eigene Index über dieselbe Datei wäre eine Stunde Rechnen und
mehrere Gigabyte gewesen.

## Warum überhaupt

Zwei Dinge, die der eigene Index nicht kann.

**Wortstämme.** FTS5 sucht nach Präfix. „Notvorräte“ findet damit nie
„Notvorrat“, und „giftig“ nie „Gift“. Xapian stemmt in der Sprache, die im
Archiv steht – gegen `wikipedia_de_chemistry` gemessen:

| Suche | Treffer |
|---|---|
| `Element` | 434 |
| `Elementen` | 434 |
| `giftig` | 44, erster ist `Gift` |

**Kein Indexlauf.** Der eigene Index über die vollständige deutsche
Wikipedia bedeutet Stunden Rechnen und Gigabyte Platz. Der eingebaute ist
schon da.

## Wie es funktioniert

```
ZimArchive.fullTextIndexEntry()   X/fulltext/xapian, sonst Z//fulltextIndex/xapian
ZimArchive.directAccessInfo()     Blockanfang + 1 Infobyte + Blob-Offset
        ↓
zx_open_path / zx_open_fd         lseek auf den Offset, Xapian::Database(fd)
        ↓
zx_search("trinkwasser")          Pfade wie "C/Trinkwasser"
        ↓
ZimArchive.findByUrl("C", ...)    der Eintrag, den die App ohnehin anzeigt
```

`Xapian::Database(int fd)` liest eine Einzeldatei-Datenbank ab der Stelle,
an der der Deskriptor gerade steht. Genau das macht den Trick möglich: aus
einem dreißig Gigabyte großen Archiv wird nichts ausgepackt.

`directAccessInfo` antwortet nur, wenn der Block **unkomprimiert** ist.
Komprimierte Bytes gibt es erst nach dem Auspacken und haben keine Stelle in
der Datei, auf die man zeigen könnte. Kiwix schreibt den Index deshalb
unkomprimiert; ein von Hand gebautes Archiv muss das nicht tun.

## Was im Archiv steht, und was nicht

Die Metadaten der Indexdatenbank, gelesen aus `wikipedia_de_chemistry_mini`:

```
data      = fullPath        Dokumentdaten sind "C/Kryokonit", mit Namensraum
kind      = fulltext
language  = deu             daraus der Stemmer
valuesmap = title:0;wordcount:1;geo.position:2
```

Zwei Fallen darin:

- Der Schlüssel heißt **`data`**, nicht `dbDataType` – letzteres ist nur
  libzims Name für den Wert.
- Slot `title` ist **kein Anzeigetitel**, sondern ein kleingeschriebener
  Sortierschlüssel (`kryokonit`). Deshalb gibt der Shim keinen Titel
  heraus; der richtige steht im ZIM-Eintrag, den der Pfad auflöst.

Ein **Textausschnitt** steht in diesen Archiven nicht drin: `valuesmap`
kennt keinen `snippet`-Slot. Der muss also weiter aus dem Artikel selbst
kommen. Ältere Archive haben ihn, deshalb wird er trotzdem ausgelesen.

## Die Schnittstelle

`native/zim_xapian/` ist reines C nach außen – Dart FFI kann nichts
anderes rufen. Kein Xapian-Typ überquert die Grenze, kein Rückruf geht
zurück, und jede Zeichenkette gehört dem Sucher. Die Dart-Seite hat damit
nur eine einzige Sache freizugeben: den Sucher selbst.

`zx_open_*` gibt **nie** null zurück. Ein Fehlschlag kommt als Handle, dessen
`zx_error` gesetzt ist, damit es genau einen Aufräumpfad gibt.

Der Deskriptor geht in Xapians Besitz über und wird von dort geschlossen,
auch wenn das Öffnen scheitert. Auf Android muss das also ein **eigener**
Deskriptor sein – nicht der, mit dem der Rest des Readers arbeitet.

## In der App

```
builtInIndexProvider          sucht den Index, öffnet ihn, sonst null
        ↓
knowledgeFullTextProvider     fragt ihn zuerst, sonst KnowledgeIndexDatabase
        ↓
KnowledgeIndexStatus.builtIn  die Oberfläche fragt nicht nach einem Aufbau
```

`null` heißt jedes Mal dasselbe: der eigene Index übernimmt. Vier
gewöhnliche Gründe dafür – keine Bibliothek im Programm, kein Index im
Archiv, ein komprimierter Indexblock, oder eine Datei ohne Pfad, was
Android ist.

Gerufen wird über `XapianSearcher`, der `XapianIndex` auf einem eigenen
Isolate hält. Die Bindung blockiert, und eine Xapian-Datenbank verträgt
genau einen Nutzer gleichzeitig: die Nachrichtenschlange ist die Sperre.
Beides ist geprüft – dass gleichzeitig gestellte Fragen jede ihre eigene
Antwort bekommen, und dass ein geschlossener oder gar nicht geöffneter
Index einen Fehler liefert statt zu hängen. Ein Aufrufer, der ewig
wartet, wäre der schlimmere Ausgang: das ist der Ladekreis, der nie
aufhört.

## Bauen

Ein Skript je Plattform, eine gemeinsame Quelle: `xapian_source.sh` hält
Fassung und Prüfsumme, damit drei Skripte nicht drei verschiedene
Tarballs anheften können. Jedes lädt xapian-core 1.4.32, prüft die
Prüfsumme **vor** dem Auspacken, baut es statisch und bindet die Schicht
dagegen.

```bash
native/zim_xapian/build_macos.sh    # universal, arm64 + x86_64, 3,2 MB
native/zim_xapian/build_linux.sh    # 1,9 MB
native/zim_xapian/build_windows.sh  # von Linux aus, mit mingw-w64
```

Warum 1.4 und nicht das neuere 2.x: 1.4 ist die stabile Reihe und die,
in der Glass geschrieben und gelesen wird.

**macOS.** Braucht kein Homebrew. Heraus kommen 3,2 MB, die nur noch an
`libz`, `libc++` und `libSystem` hängen. Xcode legt die Datei in
`Contents/Frameworks` und signiert sie (Bauphase „Embed Xapian“).

**Linux.** Braucht `zlib1g-dev` und `uuid-dev`; welchen C++-Compiler die
Maschine hat, sucht das Skript sich selbst, weil die Flutter-Kette clang
mitbringt und g++ nicht unbedingt da ist. CMake legt die `.so` nach
`bundle/lib/`. Zwei Linkerschalter sind nicht Kosmetik: `--no-undefined`
macht eine vergessene Bibliothek zum Fehler beim Bauen statt zu einem
Programm, das startet und dann nichts öffnen kann — `-luuid` war einmal
vergessen. Und `--version-script` sorgt dafür, dass nur die elf
`zx_`-Funktionen herausschauen: unter ELF reicht `-fvisibility=hidden`
nicht, weil die Template-Instanzen aus den libstdc++-Kopfdateien schwache
Symbole mit voller Sichtbarkeit sind.

**Windows.** Nicht mit MSVC: xapian-core 1.4 hat sein `win32`-Verzeichnis
verloren, dafür behandelt sein `configure` mingw an einem Dutzend
Stellen. Das Skript läuft deshalb auf einer Linux-Maschine
(`mingw-w64`, `libz-mingw-w64-dev`), und die fertige `zim_xapian.dll`
wird herübergereicht. CMake legt sie neben die `.exe`.

Fehlt die Bibliothek, warnt der Bau und läuft weiter: die App muss auch
ohne sie übersetzen.

### Zwei Fallen unter Windows

Beide sind in der Schicht abgefangen, beide wären still gewesen:

- Eine Datei ohne `O_BINARY` wird im Textmodus gelesen, und der schreibt
  Bytes unterwegs um. Für eine Datenbank tödlich.
- `lseek` nimmt dort einen 32-Bit-Offset. Der Index der vollständigen
  Wikipedia fängt bei Byte 47 677 531 029 an — der Sprung wäre irgendwo
  gelandet, ohne Fehler.

Testen gegen ein echtes Archiv:

```bash
cd preppsuite_flutter
PREPPSUITE_TEST_ZIM=/pfad/zu/wikipedia_de_chemistry_mini.zim flutter test
```

Ohne die Variable überspringen sich `xapian_index_test.dart` (die
Bindung), `xapian_search_test.dart` (das Isolate) und
`test/live/xapian_speed_test.dart` (die Zahlen oben) selbst. Ein
Xapian-Index lässt sich nicht als Testfixture nachbauen – das ist das
Dateiformat einer C++-Bibliothek, und ein Nachbau würde nur beweisen, dass
der Nachbau gelesen wurde.

## Was noch fehlt

1. **Windows ausprobieren.** Das Skript steht, gebaut und gestartet ist
   es noch nicht.
2. **Android**, aufwendiger: je ABI bauen (arm64-v8a, armeabi-v7a,
   x86_64) und über `jniLibs` einbinden, rund 3–6 MB je ABI;
   [kiwix-build](https://github.com/kiwix/kiwix-build) hat ein Rezept.
   Dazu ein **eigener Deskriptor** über
   `ParcelFileDescriptor.detachFd()` im bestehenden Kanal
   `preppsuite/storage` – Xapian schließt ihn, also darf es nicht der
   sein, mit dem der Reader arbeitet.
3. **iOS** ist offen: die Bibliothek ließe sich bauen, aber Archive liegen
   dort im Speicher der App, und ob eine 50-GB-Datei dorthin gehört, ist
   keine Frage an diese Seite.

Für Android ist ein **deutscher Stemmer in Dart** vermutlich der bessere
Handel: er kostet einen Bruchteil und hilft auch jedem Archiv ohne
eigenen Index, auf allen Plattformen. Er nimmt nur die eine Hälfte des
Gewinns mit — den Indexlauf spart er nicht.

## Das Risiko, das bleibt

Native Toolchains sind keine einmalige Arbeit, sondern eine dauerhafte
Last – eine steht, drei stünden noch aus. Deshalb ist der Rückfall keine
Höflichkeit gegenüber alten Archiven, sondern das, was die Suche auf
jeder Plattform am Leben hält, auf der niemand diese Arbeit gemacht hat.

Dazu die Formatversion: Glass ist innerhalb Xapian 1.4 stabil und wird
auch von 2.1 noch gelesen – baut Kiwix eines Tages mit dem neueren
Honey-Backend, öffnet unsere Bibliothek die Datei nicht mehr.
