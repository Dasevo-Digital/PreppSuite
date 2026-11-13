# Datenschutzinformationen für PreppSuite

Stand: 30. September 2026 · PreppSuite 2.3.4

## Kurzfassung

PreppSuite benötigt kein Konto und keinen zentralen Server des Projekts.
Haushalt, Vorräte, Dokumente, Notfallkarten, persönliche Orte und Einstellungen
liegen lokal auf dem Gerät. Das Projekt betreibt keine Werbung, Telemetrie,
Nutzungsmessung oder automatische Absturzübermittlung.

Mehrere Funktionen rufen jedoch öffentliche oder selbst gewählte Dienste im
Internet auf. Dabei erhält der jeweilige Anbieter mindestens IP-Adresse,
Zeitpunkt und die angefragten Parameter. Ortsbezogene Parameter können den
Wohn-, Reise- oder Suchbereich erkennen lassen.

## Lokale Daten und Sicherungen

Die lokale Datenbank kann sensible Haushalts-, Inventar-, Finanz-, Dokument-
und Gesundheitsangaben enthalten. Neue Installationen verschlüsseln sie von
Anfang an; ältere stellen nach einer Sicherung in den Einstellungen um. Mit
einem davon abgeleiteten Schlüssel werden auch die Fotos von Vorräten und
Besitz sowie die privaten Einstellungen (Haushaltsprofil, Schlüssel des
gemeinsamen Ordners, Notfallkontakte) verschlüsselt; Fotos aus älteren
Versionen werden beim nächsten Start nachträglich verschlüsselt. Das schützt
die Dateien im Ruhezustand, nicht vor Zugriff auf ein bereits entsperrtes
Gerät.

Ohne Schlüssel bleiben Datenbank, Fotos und private Einstellungen
unverschlüsselt: in der mitgeführten Fassung auf einem USB-Stick (der
Schlüssel liegt im Schlüsselbund des jeweiligen Rechners und reist nicht
mit), auf Geräten ohne nutzbaren Schlüsselspeicher und solange eine
Installation auf ihre Wiederherstellung wartet.

**Das gilt derzeit für jede Mac-Installation.** Die macOS-Pakete sind noch
nicht mit einem Entwicklerzertifikat signiert, und ohne Signatur verweigert
der Schlüsselbund von macOS das Ablegen eines Schlüssels. Die lokalen Daten
liegen dort im Klartext im Container der App, geschützt nur durch die
Benutzerrechte und – falls eingeschaltet – durch FileVault. Die Karte
„Lokale Verschlüsselung" in den Einstellungen weist darauf hin. Mit der
Signierung der Pakete entfällt diese Einschränkung.

Beim Teilen über einen gemeinsamen Ordner schreibt PreppSuite verschlüsselte
Gerätedateien in den gewählten Ordner. Ist der Ordner verschlüsselt, legt es
dort auch die Fotos aus Vorrat und Hausratverzeichnis ab, jedes versiegelt
und unter einem Namen, der nicht verrät, welches Bild es ist; in einen
offenen Ordner kommen keine Fotos (#376). Nextcloud, Syncthing, iCloud Drive,
Dropbox oder ein anderer Transportdienst wird nicht von PreppSuite betrieben
und kann Verbindungsdaten sowie verschlüsselte Dateien speichern; an Zahl und
Größe der Fotodateien lässt sich ungefähr ablesen, wie viele Fotos ein
Haushalt hat. Die Passphrase muss allen beteiligten Geräten auf einem
getrennten, sicheren Weg mitgeteilt werden.

Android-Cloud-Backup ist für App-Daten deaktiviert. Große heruntergeladene
Dateien werden unter iOS vom Geräte-Backup ausgeschlossen. Einzelheiten stehen
in [`gemeinsamer-ordner.md`](gemeinsamer-ordner.md).

## Netzwerkverbindungen

**Warnungen und Messwerte.** Die App fragt – teilweise regelmäßig und auf
Mobilgeräten auch im Hintergrund – BBK/warnung.bund.de, MeteoAlarm, DWD,
PEGELONLINE, das BfS-ODL-Messnetz, das Umweltbundesamt und die Autobahn GmbH
ab. Übertragen werden IP-Adresse sowie gewählte Region, Station oder Strecke.

**Karten und Ortssuche.** Ohne Offline-Archiv werden Kartenkacheln von
OpenStreetMap geladen. Orts- und Rückwärtssuche verwendet Nominatim;
Schutzräume, Defibrillatoren und Notfallpunkte (Notbrunnen, Hilfspunkte,
Sirenen) kommen über Overpass (overpass-api.de, overpass.private.coffee,
overpass.kumi.systems), Schutzräume außerdem über WWBOTA. Antwortet der
erste Overpass-Server nicht, fragt die Suche nach Defibrillatoren und
Notfallpunkten als Nächstes QLever an der Universität Freiburg
(qlever.dev) mit demselben Suchgebiet, danach die beiden anderen
Overpass-Server. Übertragen werden IP-Adresse, Suchtext, Koordinaten oder
Kartenausschnitt. Der eigene Standort geht dabei nur gerundet hinaus: für
die Bestimmung des Bundeslands auf zwei Nachkommastellen (etwa ein
Kilometer), für die Suche nach Schutzräumen, Defibrillatoren und
Notfallpunkten als Suchgebiet um einen Rasterpunkt im selben Abstand statt
um die genaue Position. Offline-Karte und lokale Umgebungssuche kommen nach
dem Download ohne diese Abrufe aus. Die Suche nach Defibrillatoren und
Notfallpunkten fragt auch mit Offline-Karte im Netz nach dem aktuellen
Stand; die mit der Karte gespeicherten Punkte (siehe unten) zeigt sie,
solange keine Antwort da ist.

**Punkte zur Offline-Karte.** Wird eine Offline-Karte übernommen, lädt die
App einmal alle Defibrillatoren und Notfallpunkte ihres Gebiets, danach alle
60 Tage neu. Dafür geht der Rahmen der Karte an QLever, ersatzweise an
Overpass, also das Kartengebiet und nicht der eigene Standort. Die Punkte
liegen unverschlüsselt im Datenordner der App, weil es öffentliche Daten
für ein Gebiet sind, das die Kartendatei selbst schon nennt. Sie werden
gelöscht, wenn keine Offline-Karte mehr gewählt ist oder eine andere Karte
an ihre Stelle tritt.

**Kartendownload.** Kartenarchive werden von OpenFreeMap oder – nach eigener
Konfiguration – MapTiler geladen. Der Anbieter erhält IP-Adresse und das
gewählte Downloadgebiet. MapTiler erhält außerdem den selbst eingetragenen
Zugangsschlüssel.

**Produktabfrage.** Eine Barcode-Suche überträgt den Barcode an Open Food
Facts. Persönliche Vorratsmengen oder Haushaltsdaten werden dabei nicht
gesendet.

**Offline-Wissen.** Der Kiwix-Katalog wird von `library.kiwix.org` geladen.
Beim Herunterladen eines ZIM-Archivs erhält dessen Downloadanbieter
IP-Adresse und die gewählte Archivdatei. Gelesene Artikel werden danach lokal
über einen ausschließlich an `127.0.0.1` gebundenen Hilfsserver angezeigt;
externe Inhalte und Skripte aus Archiven werden nicht nachgeladen. Unter
Linux öffnet sich der Artikel in einem eigenen Fenster, dessen Bibliothek
einen Seitenwechsel nur melden, nicht verhindern kann; führt ein Link oder
ein Skript aus dem Archiv hinaus, bricht die App das Laden sofort ab, die
erste Anfrage kann den Rechner dabei aber schon verlassen haben.

**Links im Browser.** Einige Quellenhinweise öffnen auf ausdrücklichen Klick
eine externe Webseite. Ab diesem Zeitpunkt gelten die Datenschutzbedingungen
des Browser- und Webseitenbetreibers.

## Geräteübertragung

„Ohne Netz übertragen“ verbindet zwei Geräte im selben lokalen Netz. Der
angezeigte Code dient als Zugriffsschlüssel. Der Haushalt wird direkt zwischen
den Geräten übertragen; das PreppSuite-Projekt erhält keine Kopie. In einem
fremden oder gemeinsam genutzten Netz sollte der Code vor Einsicht geschützt
und die Verbindung nach dem Transfer beendet werden.

## Löschen und Auskunft

Da das Projekt keinen zentralen Dienst betreibt, besitzt es keine Kopie der
lokalen Daten und kann darüber weder Auskunft erteilen noch sie löschen. Die
nutzende Person löscht Daten in der App, entfernt die App-Daten des
Betriebssystems und beseitigt gegebenenfalls Kopien aus gemeinsamen Ordnern,
Sicherungen und Cloud-Verläufen selbst.

Fragen und Datenschutzmeldungen können ohne Veröffentlichung persönlicher
Kontaktdaten über das Issue-System des offiziellen Projekt-Repositorys gestellt
werden. Wer PreppSuite als Store-Angebot oder unter eigener Organisation
verteilt, muss vor der Veröffentlichung seine eigene ladungsfähige
Kontaktangabe und gegebenenfalls weitere Pflichtinformationen ergänzen.
