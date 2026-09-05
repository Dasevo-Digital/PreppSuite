# Volltextsuche über den Index im Archiv

Ein Kiwix-Archiv bringt seinen eigenen Volltextindex mit. Er ist eine
[Xapian](https://xapian.org)-Datenbank, die als Block im Archiv liegt –
unkomprimiert, damit man sie dort lesen kann, wo sie liegt.

Das ist ein anderer Weg als der, den die App bisher geht: `KnowledgeIndexer`
baut sich einen eigenen SQLite-FTS5-Index. Beide bleiben. Welcher greift,
entscheidet das Archiv.

**Stand: Machbarkeitsnachweis.** Der Weg ist gebaut und gegen ein echtes
Archiv bewiesen, aber noch nicht in die App verdrahtet und nur auf macOS
gebaut. Was noch fehlt, steht unten.

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

## Bauen

```bash
brew install xapian
preppsuite_flutter/native/zim_xapian/build_macos.sh
```

Das ist der Stand des Nachweises und bewusst nicht mehr: es linkt dynamisch
gegen Homebrews `libxapian.dylib`, die auf keinem anderen Rechner liegt.

Testen gegen ein echtes Archiv:

```bash
cd preppsuite_flutter
PREPPSUITE_TEST_ZIM=/pfad/zu/wikipedia_de_chemistry_mini.zim flutter test
```

Ohne die Variable überspringt `xapian_index_test.dart` sich selbst. Ein
Xapian-Index lässt sich nicht als Testfixture nachbauen – das ist das
Dateiformat einer C++-Bibliothek, und ein Nachbau würde nur beweisen, dass
der Nachbau gelesen wurde.

## Was noch fehlt

1. **xapian-core selbst bauen**, statisch, je Plattform: macOS
   (arm64 + x86_64), Android (arm64-v8a, armeabi-v7a, x86_64), dazu Linux
   und Windows, falls die je ernst werden. Autotools mit `--host=`;
   [kiwix-build](https://github.com/kiwix/kiwix-build) hat für Android ein
   fertiges Rezept. Einzige Abhängigkeit ist zlib.
2. **Einbinden**: Android über `jniLibs` je ABI, macOS als xcframework.
   Rund 3–6 MB je ABI.
3. **Deskriptor unter Android** über `ParcelFileDescriptor.detachFd()` im
   bestehenden Kanal `preppsuite/storage`.
4. **In einem Isolate rufen.** `XapianIndex` blockiert – bewusst, es ist
   eine Bindung und kein Dienst. Weil nur eine Zahl über die Grenze geht,
   ist das Verschieben einfach; eine Datenbank verträgt allerdings nur
   einen Nutzer gleichzeitig.
5. **Rückfall** auf `KnowledgeIndexer`, wenn das Archiv keinen Index trägt.
   Selbst gebaute Archive aus `zimwriterfs` tragen keinen.

## Das Risiko, das bleibt

Vier native Toolchains sind keine einmalige Arbeit, sondern eine dauerhafte
Last. Dazu die Formatversion: Glass ist innerhalb Xapian 1.4 stabil und wird
auch von 2.1 noch gelesen – baut Kiwix eines Tages mit dem neueren
Honey-Backend, öffnet unsere Bibliothek die Datei nicht mehr.
