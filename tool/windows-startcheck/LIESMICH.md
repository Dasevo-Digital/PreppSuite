# Startnachweis für die Windows-Pakete

Ein Windows-Paket wird vor der Auslieferung gestartet, nicht nur gebaut.
Diese Dateien tun das in einem **Windows Sandbox**: einem frischen
Windows, das diese App nie gesehen hat — kein Visual Studio, kein
Flutter, keine Laufzeit, die jemand für sie installiert hat.

Das ist der Rechner, den ein Nutzer hat. Auf dem Baurechner zu starten
beweist nichts: dort liegt alles schon da.

## Warum nicht auf dem Baurechner

Ein Entwicklungsrechner hat alles installiert. Genau deshalb blieb lange
unbemerkt, dass die Pakete die Visual-C++-Laufzeit brauchten und nicht
mitbrachten — auf TestWindows lag sie, wie auf jedem Rechner mit Visual
Studio. Der Sandkasten hat es in einem Lauf gezeigt.

## Was der Sandkasten nicht löst: Smart App Control

**Er umgeht es nicht.** Der Sandkasten erbt den Zustand des Wirts: auf
TestWindows steht
`HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy\VerifiedAndReputablePolicyState`
auf `1`, und im Sandkasten steht er ebenfalls auf `1`. Unsignierte
Programme werden dort genauso abgewiesen — mit `0xC0E90002` und den
CodeIntegrity-Ereignissen 3077 und 3118.

Am 15.09.2026 liefen die Messungen dort noch durch, am 16.09. nicht mehr;
dazwischen lag eine Richtlinien-Aktualisierung („Code Integrity policy
refresh finished for 6 policies"). Es blockiert auch eine Datei, die nie
heruntergeladen wurde — direkt aus dem Bauordner gestartet, ohne Mark of
the Web, derselbe Code.

Solange das so ist, läuft dieser Startnachweis auf dieser Maschine gar
nicht. Es hilft nur eines von beidem:

- **Smart App Control auf TestWindows abschalten** (Windows-Sicherheit →
  App- und Browsersteuerung). Einbahnstraße: wieder einschalten geht nur
  durch eine Neuinstallation von Windows.
- **Die Programme signieren**, mit einem Zertifikat einer anerkannten
  Zertifizierungsstelle. Das löst es zugleich für die Nutzer.

## Ablauf

```powershell
# auf TestWindows, mit den .zip-Dateien in C:\sbtest\
powershell -ExecutionPolicy Bypass -File C:\sbtest\hostrun.ps1
```

`hostrun.ps1` läuft auf dem Wirt: es räumt einen noch offenen Sandkasten
ab, startet über eine geplante Aufgabe einen neuen und wartet auf dessen
Urteil. `start.wsb` reicht `C:\sbtest` als `C:\shared` hinein und ruft
`start.cmd`, das `start.ps1` startet.

`start.ps1` entpackt jede `.zip` aus `C:\shared`, startet die
`PreppSuite.exe` darin und schreibt das Ergebnis nach
`C:\shared\start-result.txt` — dazu ein Bildschirmfoto je Paket.

## Woran ein Start erkannt wird

**Nicht daran, dass der Prozess noch existiert.** Eine Flutter-App, der
eine DLL fehlt, hinterlässt einen Prozess, der bei fünf Megabyte sitzt und
nichts tut. Kein Absturz, keine Meldung, kein Ereignisprotokoll-Eintrag.

Gewertet wird dreierlei zusammen:

| | tot | lebendig |
|---|---|---|
| Threads | 4 | 30–40 |
| Arbeitsspeicher | 5 MB | ~100 MB |
| Fenster | Handle 0 | Handle ≠ 0, Titel „PreppSuite" |
| Datenbank | keine | `%APPDATA%\…\preppsuite.sqlite` |

Die Datenbank ist der eigentliche Beweis: sie entsteht erst, wenn die
Dart-Seite gelaufen ist.

## Eine Kontrolle gehört dazu

Ein Fehlschlag allein sagt nicht, ob das Paket schuld ist oder die
Umgebung. Deshalb immer ein zweites Paket mitlaufen lassen, von dem man
weiß, wie es sich verhält — etwa die vorige Fassung von Gitea. Verhalten
sich beide gleich, liegt es nicht an der neuen.

## Fallstricke

- **Windows lässt nur einen Sandkasten zugleich zu.** `start.ps1` fährt
  ihn am Ende selbst herunter; wird er von außen abgeschossen, bleibt ein
  `vmmemWindowsSandbox` eine Weile stehen. `hostrun.ps1` wartet darauf,
  dass der *Server*-Prozess weg ist, nicht der vmmem — der räumt sich
  selbst ab.
- **Der Sandkasten braucht eine angemeldete Sitzung.** Über ssh gestartet
  läuft `WindowsSandbox.exe` in der falschen Sitzung; deshalb der Umweg
  über `schtasks /ru <benutzer> /it`.
- **`tar` von macOS packt Ressourcen-Dateien mit ein.** `._app_de.arb`
  neben `app_de.arb` bringt `flutter gen-l10n` mit einem UTF-8-Fehler zum
  Absturz. Das Quellpaket deshalb mit `COPYFILE_DISABLE=1 tar …` bauen.
