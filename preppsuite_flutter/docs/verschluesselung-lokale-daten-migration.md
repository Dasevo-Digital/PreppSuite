# Migration: Verschlüsselung lokaler Bestandsdaten

## Stand der Umsetzung

Gebaut (Code in `lib/core/local_database_encryption.dart`,
`lib/core/local_data_gate.dart`,
`lib/features/settings/presentation/local_encryption_card.dart`):

- Schlüsselerzeugung, sicherer Speicher, Start-Koordinator mit den Zuständen
  `plaintext`, `migrating`, `encrypted` und `recoveryRequired`.
- Verschlüsselte Drift-Executoren für alle drei Datenbanken. Die Entscheidung
  fällt **pro Datei** beim Öffnen: ein `PRAGMA key` auf eine Klartextdatei
  macht sie unlesbar, also bekommt sie keinen. Damit ist eine abgebrochene
  Migration lesbar statt halb verloren.
- Atomarer Wechsel mit Wiederherstellung nach Abbruch an jedem Punkt,
  nachgestellt in `test/core/local_database_encryption_test.dart`.
- Die Migration läuft in einem eigenen Isolate und ist wiederaufnehmbar; ein
  zweiter Lauf überspringt Fertiges und behält den ersten Schlüssel.
- Einstellungskarte „Lokale Verschlüsselung" mit Zustand, Sicherungstest und
  dem ausdrücklichen Start. Ohne einen Sicherungstest der letzten 24 Stunden
  ist der Start nicht anwählbar.
- `BackupService.verify` liest eine Sicherung zurück, ohne etwas zu ändern.
- Bildschirm für `recoveryRequired` vor der App-Sperre, mit „Neu einrichten",
  das die unlesbaren Dateien umbenennt statt löscht.

Offen:

- Der verschlüsselte Container für private Einstellungen; die Klassen unten
  beschreiben ihn, gebaut ist er nicht. `SharedPreferences` ist noch
  unverschlüsselt.
- Sicherungsformat 2 mit getrenntem Einstellungsblock.
- Der Plattformprototyp auf Android, iOS und Windows. Nachgewiesen ist
  bisher: macOS (Testlauf, `cipherAvailable` wahr) und Linux
  (`libsqlite3mc.so` liegt im Paket).
- Während der Migration können die Wissens- und Dokumentindizes von anderer
  Stelle geöffnet sein. Die Karte schließt nur die Haushaltsdatenbank und
  verlangt danach einen Neustart.

## Ziel und Schutzmodell

PreppSuite speichert Haushalts-, Gesundheits-, Kontakt- und Planungsdaten lokal. Nach der Migration sind die Datenbanken und privaten Einstellungen auf dem Dateisystem verschlüsselt. Die Anwendung bleibt ohne Konto und ohne Server nutzbar.

Das schützt vor einer kopierten Datenbank, einem verlorenen Datenträger und lokalem Dateizugriff außerhalb der laufenden App. Es schützt nicht vor einem bereits entsperrten Gerät. Die Gerätesperre bleibt deshalb erforderlich.

Die bestehende App-Sperre ist kein Datenverschlüsselungs-Schlüssel. Ihre Zurücksetzung darf nicht zum Verlust eines Haushalts führen.

## Architekturentscheidung

Die Datenverschlüsselung verwendet einen zufälligen, pro Installation erzeugten 256-Bit-Datenschlüssel (DEK). Der DEK liegt ausschließlich im plattformgebundenen sicheren Speicher. Die Datenbanken erhalten den DEK beim Öffnen; die App-Passphrase schützt weiterhin die Oberfläche.

Damit können Android-Hintergrundwarnungen die Datenbank öffnen, wenn das Betriebssystem den sicheren Speicher bereitstellt. Eine allein aus der App-Passphrase abgeleitete Datenbank wäre dafür ungeeignet, weil nach einem App-Neustart keine Passphrase im Hintergrund vorliegt.

Für die Drift-Datenbanken wird der von Drift dokumentierte native, plattformübergreifende Verschlüsselungsweg mit SQLite3MultipleCiphers evaluiert. Vor der Produktmigration ist ein Prototyp auf Android, iOS, macOS, Windows und Linux Pflicht. Quelle: https://drift.simonbinder.eu/platforms/encryption/

## Speicherklassen

| Klasse | Ziel nach Migration | Bemerkung |
| --- | --- | --- |
| `preppsuite`-Datenbank | verschlüsselt | Haushaltsdaten, Warnungen, Kontakte, Inventar und Synchronisationszustand |
| Wissens- und persönlicher Dokumentindex | verschlüsselt | Der persönliche Index kann vollständigen Dokumenttext enthalten |
| Private Einstellungen | AES-GCM-Container unter DEK | Profil, Warnorte, persönliche Kontakte, Pläne, Lesezeichen und ähnliche private Werte |
| Technische Einstellungen | weiter unverschlüsselt | Sprache, Theme und reine Bedienungspräferenzen dürfen vor dem Entsperren lesbar sein |
| Original-PDFs, ZIM, PMTiles und Fotos | nicht automatisch ändern | Sie können außerhalb der App liegen oder mehrere Gigabyte groß sein |
| Exportierte PDFs, CSVs und Bilder | bewusste Exporte | Vor dem Teilen wird klar auf unverschlüsselte Inhalte hingewiesen |

Die Sicherung wird auf Formatversion 2 erweitert. Sie enthält den bestehenden verschlüsselten Haushaltsschnappschuss und einen getrennten, ebenfalls verschlüsselten Block für private Einstellungen. Formatversion 1 bleibt lesbar.

## Migrationsablauf

1. **Inventar und Prototyp.** Jede Nutzung von `SharedPreferences` wird als technisch oder privat klassifiziert. Der Prototyp öffnet eine neue und eine vorhandene Drift-Datenbank mit dem gewählten nativen Executor auf allen Zielplattformen.
2. **Startkoordinator.** Vor dem ersten `AppDatabase`-Zugriff prüft ein kleiner, nicht geheimer Migrationsstatus: `plaintext`, `migrating`, `encrypted` oder `recoveryRequired`. Der Status enthält keine Haushaltsdaten und ist absturzfest geschrieben.
3. **Verifizierte Sicherung.** Bei einer bestehenden Klartextinstallation fordert die App vor der Umstellung eine passwortgeschützte Sicherung an. Sie entschlüsselt diese unmittelbar im Speicher und prüft Haushalt-ID, Datensatzanzahl und Planblock. Ohne erfolgreiche Sicherung keine Umstellung.
4. **Ruhezustand herstellen.** Hintergrund-Synchronisierung, Warnabfrage und Schreibzugriffe werden angehalten; Drift wird geschlossen und das SQLite-Journal vollständig übernommen.
5. **Neu verschlüsseln.** Die Datenbank wird mit dem vom gewählten Backend unterstützten Export-/Attach-Verfahren in eine neue Datei geschrieben. Ein Kopieren der Klartextdatei ist keine Migration. Der DEK wird nur einmal erzeugt und zuerst im sicheren Speicher abgelegt.
6. **Prüfen und Umschalten.** Die neue Datenbank wird mit dem DEK geöffnet, Schema und kritische Tabellen werden geprüft, anschließend wird die Datei atomar zur aktiven Datenbank. Die privaten Einstellungen werden erst dann in den verschlüsselten Container übernommen.
7. **Wiederanlauf.** App und Hintergrunddienst öffnen die verschlüsselten Speicher erneut; ein neuer Haushalts-Schnappschuss bestätigt Lesbarkeit und Schreibbarkeit.
8. **Aufräumen.** Die frühere Klartextkopie bleibt nur bis zum bestätigten Neustart als lokale Rückfallkopie erhalten und wird danach entfernt. Die App verspricht keine sichere Löschung auf SSDs oder Dateisystemen; Gerätevollverschlüsselung und die geprüfte Sicherung bleiben notwendig.

Jeder Schritt ist wiederholbar. Ein Absturz vor dem atomaren Umschalten lässt die ursprüngliche Datenbank unverändert; ein Absturz danach öffnet entweder die validierte verschlüsselte Datenbank oder führt in die Wiederherstellung.

## Wiederherstellung und Gerätewechsel

Ein zurückgesetzter Keystore oder Keychain bedeutet `recoveryRequired`, nicht einen leeren Haushalt. Die App erklärt den Zustand ohne Dateninhalt anzuzeigen und stellt aus einer passwortgeschützten Sicherung in eine neue, verschlüsselte lokale Datenbank wieder her.

Ein portabler Datenordner kann den installationsgebundenen DEK nicht sinnvoll mitnehmen. Für einen Gerätewechsel bleiben die verschlüsselte Sicherung, der verschlüsselte gemeinsame Ordner und die lokale Übergabe die vorgesehenen Wege. Ein späterer portabler Tresor wäre ein separates, passphrase-basiertes Format und darf nicht stillschweigend aus dem Installationsschlüssel abgeleitet werden.

## Nutzeroberfläche

Unter „Daten und Sicherheit“ kommt eine Karte „Lokale Verschlüsselung“ mit Status, letztem erfolgreichen Sicherungstest und den Aktionen:

- „Lokale Daten jetzt verschlüsseln“ für bestehende Installationen.
- „Sicherung testen“ ohne Daten zu verändern.
- „Aus Sicherung wiederherstellen“ bei fehlendem Geräteschlüssel.
- Klarer Hinweis auf nicht geschützte Originaldateien und bewusste Exporte.

Die Migration beginnt nicht beim bloßen App-Update. Sie wird erst nach dem erfolgreichen Sicherungstest und einer verständlichen Zusammenfassung der betroffenen Daten gestartet.

## Test- und Freigabekriterien

- Neue Installation: alle Datenbanken und private Einstellungen sind ab dem ersten Start verschlüsselt.
- Upgrade mit und ohne App-Sperre: identische Datensätze, Fotos, Volltextsuche, Warnhistorie und Planinformationen vor und nach Migration.
- Absturzsimulation nach jedem Migrationsstatus sowie bei vollem Datenträger und fehlender Berechtigung.
- Falsches Sicherungspasswort, veränderte Sicherung und verlorener Keystore/Keychain führen zu keiner Datenanzeige und keinem Überschreiben.
- Android-Hintergrundwarnungen, macOS- und Desktop-Start sowie portable Datenordner funktionieren mit klaren, getesteten Grenzen.
- Release-Builds für Android, iOS, macOS, Windows und Linux enthalten die erforderliche native Kryptobibliothek und öffnen keine Klartextdatenbank.
- Eine unabhängige Code- und Migrationsprüfung bestätigt Schlüsselhandling, atomaren Wechsel und Rückfallpfade vor Aktivierung für Bestandsnutzer.

## Reihenfolge der Umsetzung

1. Plattformprototyp und Build-Matrix.
2. `StorageKeyProvider`, Migrationsstatus und verschlüsselter Einstellungencontainer.
3. Verschlüsselte Drift-Executoren für alle drei Datenbanken.
4. Sicherungsformat 2 und Wiederherstellung ohne Geräteschlüssel.
5. Atomare Migration mit Absturztests.
6. Einstellungsoberfläche, telemetrie-freie Diagnose und Dokumentation.
7. Opt-in-Testrelease, anschließend reguläre Migration nach geprüftem Sicherungstest.
