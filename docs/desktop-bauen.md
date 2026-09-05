# Desktop bauen

macOS baut hier direkt. Linux und Windows sind die beiden, die unbemerkt
kaputtgehen, weil hier niemand auf ihnen entwickelt — und beide brauchen
etwas, das nicht mitkommt.

## Linux

```bash
sudo apt install clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev \
  libwebkit2gtk-4.1-dev libsoup-3.0-dev
```

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

## Stand

| | baut | ausprobiert |
|---|---|---|
| macOS | ja | ja |
| Linux | ja, im Container | nein |
| Windows | alles außer den Benachrichtigungen | nein |

Auf der Windows-Testmaschine waren zum Zeitpunkt der Prüfung gebaut:
`desktop_webview_window_plugin.dll`, `zstandard_windows.dll`,
`geolocator_windows_plugin.dll`, `file_selector_windows_plugin.dll`,
`printing_plugin.dll` und `pdfium.dll` — also alles, worauf die Karte, das
Wissen und der Ordner stehen.
