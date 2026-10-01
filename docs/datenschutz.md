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
und Gesundheitsangaben enthalten. Eine optionale lokale
Datenbankverschlüsselung schützt die Datei im Ruhezustand. Sie schützt nicht
vor Zugriff auf ein bereits entsperrtes Gerät.

Beim Teilen über einen gemeinsamen Ordner schreibt PreppSuite verschlüsselte
Gerätedateien in den gewählten Ordner. Nextcloud, Syncthing, iCloud Drive,
Dropbox oder ein anderer Transportdienst wird nicht von PreppSuite betrieben
und kann Verbindungsdaten sowie verschlüsselte Dateien speichern. Die
Passphrase muss allen beteiligten Geräten auf einem getrennten, sicheren Weg
mitgeteilt werden.

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
Schutzräume kommen über Overpass und WWBOTA. Übertragen werden IP-Adresse,
Suchtext, Koordinaten oder Kartenausschnitt. Der eigene Standort geht dabei
nur gerundet hinaus: für die Bestimmung des Bundeslands auf zwei
Nachkommastellen (etwa ein Kilometer), für die Schutzraumsuche als
Suchgebiet um einen Rasterpunkt im selben Abstand statt um die genaue
Position. Offline-Karte und lokale Umgebungssuche vermeiden diese Abrufe
nach dem Download.

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
