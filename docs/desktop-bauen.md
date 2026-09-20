# Desktop bauen

macOS baut hier direkt. Linux und Windows sind die beiden, die unbemerkt
kaputtgehen, weil hier niemand auf ihnen entwickelt — und beide brauchen
etwas, das nicht mitkommt.

## Windows

Die C++-Laufzeit wird seit `556df7f` mit ins Paket gelegt
(`windows/CMakeLists.txt`). Ohne sie startet die App auf einem Rechner,
der sie nicht schon hat, gar nicht — und zwar lautlos.

Den Startnachweis führt `tool/windows-startcheck/` in einem Windows
Sandbox, also in einem Windows, auf dem nichts installiert ist. Auf dem
Baurechner zu starten beweist nichts. Einzelheiten in
[`tool/windows-startcheck/LIESMICH.md`](../tool/windows-startcheck/LIESMICH.md).

## Linux

```bash
sudo apt install clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libwebkit2gtk-4.1-dev libsoup-3.0-dev \
  zlib1g-dev uuid-dev \
  libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
  libsecret-1-dev
```

Diese Liste ist am 20.09.2026 gegen ein frisches Ubuntu 26.04 geprüft
worden, und die letzten drei Zeilen fehlten darin. CMake meldet jedes
fehlende Modul **einzeln und erst beim Bau**, also kostet jede Lücke einen
weiteren Durchlauf. Was welches Paket verlangt:

| Modul | Paket | wofür |
|---|---|---|
| `gstreamer-1.0`, `-app-`, `-audio-` | `libgstreamer1.0-dev`, `libgstreamer-plugins-base1.0-dev` | `audioplayers_linux`, der Ton des Erste-Hilfe-Taktgebers |
| `libsecret-1` | `libsecret-1-dev` | `flutter_secure_storage_linux`, der Schlüssel der Ordner-Verschlüsselung |
| `webkit2gtk-4.1`, `libsoup-3.0` | `libwebkit2gtk-4.1-dev`, `libsoup-3.0-dev` | das Artikelfenster |

`webkit2gtk-4.0` und `libsoup-2.4` fehlen auf so einem System ebenfalls,
und das ist in Ordnung: das Plugin probiert erst 4.1 und meldet nur das
zweite — siehe unten.

Die letzten beiden sind für das Artikelfenster. Ohne sie bricht CMake ab —
mit einer irreführenden Meldung: das Plugin probiert erst `webkit2gtk-4.1`
und fällt dann auf `webkit2gtk-4.0` zurück, beschwert sich aber nur über
das zweite.

**Auf einem KDE-Desktop ist WebKitGTK nicht selbstverständlich.** Ein
frisch aufgesetztes Kubuntu 26.04 hatte weder 4.1 noch 4.0 und weder
libsoup-3.0 noch 2.4 — KDE benutzt Qt und braucht es nirgends. Unter GNOME
liegt es meist ohnehin da. Das betrifft nicht nur den Bau: zum **Lesen**
von Artikeln braucht die fertige App `libwebkit2gtk-4.1-0` auf dem
Zielrechner.

**Der Ton des Erste-Hilfe-Taktgebers läuft über GStreamer.** Zum Bauen
braucht es die Entwicklungspakete oben — hier stand einmal das Gegenteil.
Ohne sie bricht CMake in `audioplayers_linux` ab:

```
A required package was not found
  - gstreamer-1.0
```

Zum Abspielen auf dem Zielrechner braucht es dann noch
`gstreamer1.0-plugins-base` und `gstreamer1.0-plugins-good`, die ein
Desktop meist schon hat. Fehlen sie, läuft der Taktgeber weiter und sagt
auf dem Bildschirm, dass kein Ton kommt — er blinkt dann nur.

`zlib1g-dev` und `uuid-dev` sind für die Volltextsuche im Archiv da —
das ist, woran xapian-core hängt. Die Bibliothek dafür entsteht vor dem
Bau der App:

```bash
preppsuite_flutter/native/zim_xapian/build_linux.sh
```

Das baut `libzim_xapian.so`; CMake legt sie dann nach `bundle/lib/`. Ohne
sie läuft alles weiter, nur sucht die App im selbst gebauten Index statt
im Index des Archivs — siehe
[Volltextsuche über den Index im Archiv](volltextsuche-xapian.md).

Ohne Linux-Maschine geht es auch im Container, siehe
[`tool/docker/`](../tool/docker/). Auf Apple-Silicon kommt dabei arm64
heraus.

## Windows

Visual Studio Build Tools 2022 mit „Desktopentwicklung mit C++" **und
zusätzlich der ATL-Komponente**:

```
Microsoft.VisualStudio.Component.VC.ATL
```

Die ist in der Standardauswahl nicht dabei. Ohne sie bricht der Bau ab mit

```
plugin.cpp(5,10): error C1083: "atlbase.h": No such file or directory
```

und zwar in `flutter_local_notifications_windows` — dem Plugin für die
Ablauferinnerungen. Alles andere, das Artikelfenster eingeschlossen, ist
zu diesem Zeitpunkt schon übersetzt.

Nachrüsten ohne die Oberfläche:

```
"C:\Program Files (x86)\Microsoft Visual Studio\Installer\vs_installer.exe" ^
  modify --installPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" ^
  --add Microsoft.VisualStudio.Component.VC.ATL --quiet --norestart
```

Die Xapian-Bibliothek entsteht dagegen **nicht** hier, sondern auf einer
Linux-Maschine — xapian-core 1.4 bringt keine MSVC-Projektdateien mehr
mit:

```bash
sudo apt install mingw-w64 libz-mingw-w64-dev
preppsuite_flutter/native/zim_xapian/build_windows.sh
```

Die entstandene `zim_xapian.dll` gehört vor dem Bau nach
`preppsuite_flutter/native/zim_xapian/build/`; CMake legt sie dann neben
die `.exe`.

## Stand

| | baut | gestartet |
|---|---|---|
| macOS | ja | ja |
| Linux | ja, x64 auf echter Maschine | ja |
| Windows | ja, x64 auf echter Maschine | nein |

Auf Linux gebaut und gestartet: die Rail-Navigation steht, das Warnbanner
läuft mit echten BBK-Meldungen. Auf Windows liegen im Release-Ordner
`desktop_webview_window_plugin.dll` samt `Webview2Loader.dll`,
`zstandard_windows.dll`, `sqlite3.dll`, `geolocator`, `file_selector`,
`printing` und `pdfium` — also alles, worauf Karte, Wissen und Ordner
stehen. 44,6 MB, gegen 41 MB unter Linux.

## Was das Ausführen gefunden hat

Zwei Dinge, die kein Test gezeigt hätte:

1. `FlutterLocalNotificationsPlugin.initialize` bekam nie Linux- oder
   Windows-Einstellungen und warf.
2. Dahinter: **Linux kann gar keine geplanten Benachrichtigungen.** Der
   Desktop-Standard kennt nur sofortige, also implementiert das Plugin
   weder `zonedSchedule` noch `pendingNotificationRequests`.
   Ablauferinnerungen gibt es dort nicht; Warnmeldungen schon, die werden
   gezeigt und nicht geplant.
