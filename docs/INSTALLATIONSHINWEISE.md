# Installationshinweise

Das macOS-Paket ist seit 3.0.3 mit einem Developer-ID-Zertifikat signiert und
von Apple notarisiert. Das Windows-Paket ist weiterhin nicht signiert; Windows
kann deshalb beim ersten Start eine Warnung anzeigen. Das ist bei diesem
Release erwartetes Verhalten, kein automatischer Hinweis auf Schadsoftware.

Installiere ein Paket nur, wenn es direkt aus dem offiziellen PreppSuite-Release
bezogen wurde, und vergleiche vorher seine SHA-256-Prüfsumme mit
`SHA256SUMS.txt` im selben Release.

## macOS: Gatekeeper

Das notarisierte Paket öffnet sich wie jede andere geprüfte App, ohne
Umweg über `ctrl`-Klick. Nur Pakete bis 3.0.2 sind ad hoc signiert; bei
ihnen meldet Gatekeeper, dass der Entwickler nicht verifiziert werden kann.
Nach erfolgreicher Prüfsummenprüfung lassen sie sich über Finder öffnen:
`ctrl`-Klick auf die App, **Öffnen**, dann die Nachfrage bestätigen.

## macOS: Verschlüsselung der lokalen Daten

Ab 3.0.3 nimmt der Schlüsselbund von macOS den Datenschlüssel der App an.
Ein neu angelegter Haushalt ist damit von Anfang an verschlüsselt. Ein
Haushalt, der mit einer älteren Fassung unverschlüsselt angelegt wurde,
bleibt es, bis die Umstellung in den Einstellungen auf der Karte „Lokale
Verschlüsselung“ gestartet wird. Vorher eine Datensicherung anlegen.

Beim ersten Start der signierten Fassung über einer älteren meldet macOS,
die App unterscheide sich von früher geöffneten Versionen. Nach dem
Bestätigen öffnet sie ihre bisherigen Daten wie gewohnt. Danach fragt macOS
einmal neu nach Ordnern, Kamera und Standort; diese Freigaben bleiben dann
über Updates erhalten.

Auf den anderen Plattformen hängt der Schlüsselspeicher nicht an der Signatur;
dort betrifft fehlende Verschlüsselung nur Geräte ohne nutzbaren
Schlüsselspeicher, unter Linux etwa ohne `libsecret`. Die Karte „Lokale
Verschlüsselung“ in den Einstellungen zeigt den Zustand. Wer den Mac nicht
allein benutzt, sollte FileVault eingeschaltet haben.

## Windows: Smart App Control und SmartScreen

Windows Smart App Control oder SmartScreen kann eine nicht signierte Anwendung
blockieren oder als unbekannt kennzeichnen. Das Paket ist für private
Testinstallationen vorgesehen. Auf verwalteten Geräten und in Organisationen
entscheidet die IT-Richtlinie; bitte die Schutzfunktion nicht global
deaktivieren.

Bei einer blockierenden Meldung: Downloadquelle und SHA-256-Prüfsumme erneut
prüfen, dann die Freigabe ausschließlich gemäß der lokalen Sicherheitsrichtlinie
vornehmen.
