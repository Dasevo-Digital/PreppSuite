# iPhone und iPad über TestFlight

Bisher kam jede Fassung per Kabel auf die eigenen iPhones und iPads, aus
einem Bau, der nur für die eingetragenen Geräte signiert war. Mit
TestFlight holen sich die Geräte jede neue Fassung selbst, auch unterwegs,
und ein neues Gerät braucht keinen neuen Bau (#379).

Verteilt wird nur an **interne Tester**: Mitglieder des eigenen Teams in
App Store Connect, bis zu 100 Personen. Dafür prüft Apple die App nicht.
Ein Bau läuft 90 Tage.

## Einmal einrichten

Diese Schritte erledigt selbst, wer das Entwicklerkonto führt. Nichts
davon steht im Repository.

1. **App-Eintrag.** In App Store Connect unter *Apps* eine neue App
   anlegen: Plattform iOS, Name „PreppSuite“, Bundle-ID
   `de.dasevo.preppsuite`, SKU frei wählbar. Der Name ist damit im App
   Store reserviert, die App erscheint dort aber nicht.
2. **API-Schlüssel.** Unter *Benutzer und Zugriff → Integrationen → App
   Store Connect API* einen Team-Schlüssel anlegen. Beim ersten Mal muss,
   wer das Konto führt, dort zuerst den Zugang zur API beantragen. Mit
   der Rolle *Admin* kann `xcodebuild` das Verteilungszertifikat und die
   Profile selbst anlegen. Die `.p8`-Datei lässt sich nur einmal
   herunterladen. Schlüssel-ID und Aussteller-ID stehen auf derselben
   Seite.
3. **Schlüsselbund.** Die vier Werte kommen in den Anmelde-Schlüsselbund
   des Macs, der die Releases baut, der Schlüssel selbst base64-kodiert:

   ```bash
   security add-generic-password -a preppsuite -s de.dasevo.preppsuite.team-id -w TEAM-ID
   security add-generic-password -a preppsuite -s de.dasevo.preppsuite.asc-key-id -w SCHLUESSEL-ID
   security add-generic-password -a preppsuite -s de.dasevo.preppsuite.asc-issuer -w AUSSTELLER-ID
   security add-generic-password -a preppsuite -s de.dasevo.preppsuite.asc-key -w "$(base64 -i AuthKey_SCHLUESSEL-ID.p8)"
   ```

   Base64, weil `security` einen Eintrag mit Zeilenumbrüchen, wie ihn
   jede `.p8`-Datei hat, nur als Hex-Folge wieder herausgibt. Das Skript
   kommt mit beidem zurecht und prüft, dass ein privater Schlüssel
   herauskommt. Danach die `.p8`-Datei an einem sicheren Ort ablegen oder
   löschen.
4. **Verschlüsselung.** App Store Connect fragt zu jedem Bau nach der
   Exportkontrolle. Bis die Frage beantwortet ist, steht der Bau auf
   „Fehlende Compliance“ und lässt sich auch intern nicht installieren.
   PreppSuite verschlüsselt die Datenbank, die Datensicherung und den
   gemeinsamen Ordner mit üblichen Verfahren. Die Antwort gibt, wer das
   Konto führt. Steht sie fest, kann sie in die `Info.plist`: Mit
   `ITSAppUsesNonExemptEncryption` = NO, wenn die Verschlüsselung
   ausgenommen ist, fragt App Store Connect nicht mehr. Mit YES braucht es
   zusätzlich den Code aus der Exportgenehmigung
   (`ITSEncryptionExportComplianceCode`).
5. **Tester.** Wer testen soll, wird unter *Benutzer und Zugriff* ins
   Team eingeladen und in TestFlight einer internen Gruppe zugeordnet.
   Ist bei der Gruppe die automatische Verteilung eingeschaltet, bekommt
   sie jeden neuen Bau ohne weiteren Klick. Auf dem Gerät die App
   *TestFlight* installieren und die Einladung annehmen.

## Je Release

Nach dem Release, vom Tag:

```bash
tool/ios_testflight.sh 3.0.1 --upload
```

Das Skript baut aus dem Tag in einem eigenen Worktree den Übersetzer
für Geräte und ein App-Store-Archiv. Version und Build-Nummer nimmt es wie
`release.sh` aus der `pubspec.yaml` des Tags. Danach prüft es:

- Version und Build-Nummer im Archiv
- den Übersetzer
- das Widget
- die Privacy-Manifeste von App und Widget
- die Berechtigung für zeitkritische Mitteilungen

Erst dann lädt es hoch. Ohne `--upload` baut und prüft es nur. Mit
`TESTFLIGHT_REF=<commit>` lässt sich ein anderer Stand zur Probe bauen;
hochgeladen wird so ein Stand nie.

Nach Apples Verarbeitung erscheint der Bau in TestFlight, und die Geräte
der Gruppe bekommen ihn angeboten.

## Daten beim Umstieg

Die TestFlight-Fassung hat dieselbe Bundle-ID und dasselbe Team wie die
per Kabel eingespielte. Nach Apples Regeln behält iOS deshalb beim
Ersetzen den Datenordner, den Schlüsselbund und die App-Gruppe. Geprüft
wird das beim ersten Umstieg auf einem eigenen Gerät; vorher trotzdem eine
Datensicherung anlegen.
