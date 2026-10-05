# Installationshinweise zu PrepSuite 2.4.2

Die Release-Pakete für macOS und Windows sind derzeit nicht mit einem
kommerziellen Entwicklerzertifikat signiert und nicht notarisiert. Die
Schutzmechanismen der Betriebssysteme können deshalb beim ersten Start eine
Warnung anzeigen. Das ist bei diesem Release erwartetes Verhalten, kein
automatischer Hinweis auf Schadsoftware.

Installiere ein Paket nur, wenn es direkt aus dem offiziellen PrepSuite-Release
bezogen wurde, und vergleiche vorher seine SHA-256-Prüfsumme mit
`SHA256SUMS.txt` im selben Release.

## macOS: Gatekeeper

Gatekeeper kann melden, dass der Entwickler nicht verifiziert werden kann. Nach
erfolgreicher Prüfsummenprüfung lässt sich die App gezielt über Finder öffnen:
`ctrl`-Klick auf die App, **Öffnen**, dann die Nachfrage bestätigen. Die
globale Gatekeeper-Einstellung muss dafür nicht verändert werden.

## macOS: keine Verschlüsselung der lokalen Daten

Ohne Signatur nimmt der Schlüsselbund von macOS keinen Schlüssel an. Auf dem
Mac bleiben deshalb Datenbank, persönliche Einstellungen und Fotos
unverschlüsselt im Container der App. Auf den anderen Plattformen hängt der
Schlüsselspeicher nicht an dieser Signatur; dort betrifft es nur Geräte ohne
nutzbaren Schlüsselspeicher, unter Linux etwa ohne `libsecret`. Die Karte „Lokale
Verschlüsselung" in den Einstellungen zeigt den Zustand. Wer den Mac nicht
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
